#!/usr/bin/env python3
"""Read-only ArkUI candidate discovery. Stdlib only; JSON is written to stdout.

This is a lexical aid, not a complete ArkTS parser or a semantic safety verdict.
"""
import argparse
import ast
from bisect import bisect_right
from collections import defaultdict
from dataclasses import dataclass, field
import json
import os
from pathlib import Path
import re
import sys

SKIP_DIRS = {'.git', '.hvigor', '.idea', '.cxx', 'node_modules', 'oh_modules',
             'build', 'dist', 'coverage', '__pycache__', 'test-cases', 'verification-results',
             'ohosTest', 'test', 'tests', 'mock'}
CODE_EXTENSIONS = {'.ets', '.ts'}
NATIVE_EXTENSIONS = {'.cpp', '.cc', '.h', '.hpp'}
OBSERVABLE = {'State', 'StorageLink', 'StorageProp', 'Link', 'Prop', 'Provide', 'Consume',
              'LocalStorageLink', 'LocalStorageProp', 'Local', 'Param', 'Provider', 'Consumer', 'Trace'}
SENSITIVE = re.compile(r'color.?mode|theme|dark|night|appearance|current.?mode', re.I)
ATTRIBUTES = {'fontColor', 'backgroundColor', 'fillColor', 'stroke', 'strokeColor', 'borderColor',
              'foregroundColor', 'color', 'selectedColor', 'unselectedColor', 'font', 'border',
              'shadow', 'linearGradient', 'radialGradient', 'sweepGradient', 'width', 'height',
              'opacity', 'visibility', 'enabled', 'textDecoration', 'background', 'textStyle',
              'placeholderColor', 'caretColor', 'activeColor', 'inactiveColor', 'trackColor',
              'thumbColor', 'backgroundBlurStyle', 'foregroundBlurStyle'}
IDENTIFIER = re.compile(r'[\w$]+', re.UNICODE)
NUMBER = re.compile(r'(?:0[xX][0-9A-Fa-f]+|\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)')


@dataclass
class Token:
    kind: str
    value: str
    start: int
    end: int
    line: int


def tokenize(text):
    tokens, index, line = [], 0, 1
    while index < len(text):
        start, start_line = index, line
        char = text[index]
        if char.isspace():
            line += char == '\n'
            index += 1
            continue
        if text.startswith('//', index):
            end = text.find('\n', index)
            index = len(text) if end < 0 else end
            continue
        if text.startswith('/*', index):
            end = text.find('*/', index + 2)
            if end < 0:
                raise ValueError('unterminated block comment')
            index = end + 2
            line += text[start:index].count('\n')
            continue
        if char in "\"'`":
            index += 1
            while index < len(text):
                if text[index] == '\\':
                    index += 2
                elif text[index] == char:
                    index += 1
                    break
                else:
                    index += 1
            else:
                raise ValueError('unterminated string')
            raw = text[start:index]
            line += raw.count('\n')
            try:
                value = ast.literal_eval(raw) if char != '`' else raw[1:-1]
            except (ValueError, SyntaxError):
                value = raw[1:-1]
            tokens.append(Token('template' if char == '`' else 'string', value, start, index, start_line))
            continue
        match = IDENTIFIER.match(text, index)
        if match and not char.isdigit():
            index += len(match.group())
            tokens.append(Token('id', match.group(), start, index, line))
            continue
        number = NUMBER.match(text, index)
        if number:
            index += len(number.group())
            tokens.append(Token('number', number.group(), start, index, line))
            continue
        operator = next((value for value in ('===', '!==', '=>', '?.', '==', '!=', '&&', '||', '??')
                         if text.startswith(value, index)), char)
        index += len(operator)
        tokens.append(Token('punct', operator, start, index, line))
    return tokens


def matching_pairs(tokens):
    stack, pairs = [], {}
    closing = {')': '(', ']': '[', '}': '{'}
    for index, token in enumerate(tokens):
        if token.kind in {'string', 'template'}:
            continue
        if token.value in ('(', '[', '{'):
            stack.append(index)
        elif token.value in closing:
            if stack and tokens[stack[-1]].value == closing[token.value]:
                start = stack.pop()
                pairs[start] = index
                pairs[index] = start
    return pairs


class ConfigParser:
    """Common JSON5 configuration syntax: comments, quoted/bare keys, trailing commas."""
    def __init__(self, text):
        self.tokens = tokenize(text)
        self.index = 0

    def consume(self, value):
        if self.index >= len(self.tokens) or self.tokens[self.index].value != value:
            raise ValueError('expected ' + value)
        self.index += 1

    def value(self):
        if self.index >= len(self.tokens):
            raise ValueError('unexpected end of configuration')
        token = self.tokens[self.index]
        self.index += 1
        if token.value == '{' and token.kind == 'punct':
            result = {}
            while self.index < len(self.tokens) and self.tokens[self.index].value != '}':
                key = self.tokens[self.index]
                if key.kind not in {'string', 'id', 'number'}:
                    raise ValueError('unsupported object key')
                self.index += 1
                self.consume(':')
                result[str(key.value)] = self.value()
                if self.tokens[self.index].value != '}':
                    self.consume(',')
            self.consume('}')
            return result
        if token.value == '[' and token.kind == 'punct':
            result = []
            while self.index < len(self.tokens) and self.tokens[self.index].value != ']':
                result.append(self.value())
                if self.tokens[self.index].value != ']':
                    self.consume(',')
            self.consume(']')
            return result
        if token.kind == 'string':
            return token.value
        if token.kind == 'number':
            return float(token.value) if re.search(r'[.eE]', token.value) and not token.value.lower().startswith('0x') else int(token.value, 0 if token.value.lower().startswith('0x') else 10)
        if token.value in ('-', '+'):
            number = self.value()
            if isinstance(number, (int, float)):
                return -number if token.value == '-' else number
        if token.kind == 'id' and token.value in ('true', 'false', 'null'):
            return {'true': True, 'false': False, 'null': None}[token.value]
        raise ValueError('unsupported configuration value: ' + str(token.value))

    def parse(self):
        result = self.value()
        if self.index != len(self.tokens):
            raise ValueError('extra configuration tokens')
        return result


@dataclass
class Owner:
    name: str
    kind: str
    observed_v2: bool
    start: int
    end: int
    fields: dict = field(default_factory=dict)


@dataclass
class Method:
    name: str
    source: object
    owner: object
    start: int
    body: int
    end: int
    getter: bool = False


class Source:
    def __init__(self, path, relative, text):
        self.path, self.relative, self.text = path, relative, text
        self.tokens = tokenize(text)
        self.pairs = matching_pairs(self.tokens)
        self.line_starts = [0] + [match.end() for match in re.finditer('\n', text)]
        self.owners, self.methods = [], []
        self.index_declarations()

    def line(self, offset):
        return bisect_right(self.line_starts, offset)

    def index_declarations(self):
        tokens = self.tokens
        for index, token in enumerate(tokens[:-2]):
            if token.kind != 'id' or token.value not in {'class', 'struct'} or tokens[index + 1].kind != 'id':
                continue
            opening = next((i for i in range(index + 2, min(index + 30, len(tokens)))
                            if tokens[i].value in ('{', ';')), None)
            if opening is None or tokens[opening].value != '{' or opening not in self.pairs:
                continue
            prefix = self.text[max(0, token.start - 300):token.start].rsplit('}', 1)[-1]
            kind = ('v2' if '@ComponentV2' in prefix else 'v1') if token.value == 'struct' else 'model'
            self.owners.append(Owner(tokens[index + 1].value, kind, '@ObservedV2' in prefix,
                                     opening, self.pairs[opening]))
        for owner in self.owners:
            cursor = owner.start + 1
            while cursor < owner.end:
                token = tokens[cursor]
                if token.kind == 'id' and cursor + 1 < owner.end and tokens[cursor + 1].value == '(':
                    closing = self.pairs.get(cursor + 1)
                    if closing is not None:
                        body = self.find_body(closing + 1, owner.end)
                        if body is not None:
                            method = Method(token.value, self, owner, cursor, body, self.pairs[body],
                                            cursor > 0 and tokens[cursor - 1].value == 'get')
                            self.methods.append(method)
                            cursor = method.end + 1
                            continue
                if token.value in ('{', '(', '[') and cursor in self.pairs:
                    cursor = self.pairs[cursor] + 1
                else:
                    cursor += 1
            start = tokens[owner.start].end
            end = tokens[owner.end].start
            body_text = list(self.text[start:end])
            for method in self.methods:
                if method.owner is owner:
                    left = tokens[method.start].start - start
                    right = tokens[method.end].end - start
                    for position in range(left, right):
                        if body_text[position] != '\n':
                            body_text[position] = ' '
            # Preserve only actual token text so comments cannot invent declarations.
            field_text = ''.join(body_text)
            field_tokens = tokenize(field_text)
            mask = ['\n' if char == '\n' else ' ' for char in field_text]
            for item in field_tokens:
                if item.kind != 'template':
                    mask[item.start:item.end] = field_text[item.start:item.end]
            pattern = re.compile(r'^\s*((?:@\w+(?:\([^)]*\))?\s*)*)'
                                 r'(?:(?:public|private|protected|static|readonly)\s+)*'
                                 r'([\w$]+)\??\s*:\s*([\w$]+)', re.M)
            for match in pattern.finditer(''.join(mask)):
                decorators = re.findall(r'@(\w+)', match.group(1))
                storage = re.search(r'@(?:StorageLink|StorageProp|LocalStorageLink|LocalStorageProp)\(\s*([\'"])(.*?)\1', match.group(1))
                watch = re.search(r'@Watch\(\s*([\'"])(.*?)\1', match.group(1))
                owner.fields[match.group(2)] = {
                    'name': match.group(2), 'type': match.group(3), 'decorators': decorators,
                    'line': self.line(start + match.start(2)),
                    'storage_key': storage.group(2) if storage else None,
                    'watch': watch.group(2) if watch else None,
                }
        for index, token in enumerate(tokens[:-2]):
            if token.value == 'function' and token.kind == 'id' and tokens[index + 1].kind == 'id' and tokens[index + 2].value == '(':
                close = self.pairs.get(index + 2)
                body = self.find_body(close + 1, len(tokens)) if close is not None else None
                if body is not None:
                    self.methods.append(Method(tokens[index + 1].value, self, None, index + 1, body, self.pairs[body]))

    def find_body(self, start, limit):
        for index in range(start, min(start + 24, limit)):
            value = self.tokens[index].value
            if value in (';', '=', '=>', ')'):
                return None
            if value == '{':
                return index if index in self.pairs else None
        return None


def read_paths(tokens):
    paths = []
    for index, token in enumerate(tokens):
        if token.value != 'this' or index + 2 >= len(tokens) or tokens[index + 1].value not in ('.', '?.'):
            continue
        parts, cursor = [], index + 2
        while cursor < len(tokens) and tokens[cursor].kind == 'id':
            parts.append(tokens[cursor].value)
            if cursor + 1 < len(tokens) and tokens[cursor + 1].value == '(':
                parts.pop()
                break
            if cursor + 2 < len(tokens) and tokens[cursor + 1].value in ('.', '?.'):
                cursor += 2
            else:
                break
        if parts:
            paths.append(parts)
    return paths


def observable_reads(tokens, owner, models):
    result = []
    if owner is None:
        return result
    for parts in read_paths(tokens):
        root = owner.fields.get(parts[0])
        if root is None:
            continue
        observed = bool(set(root['decorators']) & OBSERVABLE) if len(parts) == 1 else False
        if len(parts) == 2 and owner.kind == 'v1' and set(root['decorators']) & OBSERVABLE:
            observed = True
        if len(parts) > 1 and owner.kind in {'v2', 'model'}:
            model = models.get(root['type'])
            observed = model is not None
            for name in parts[1:]:
                child = model.fields.get(name) if model is not None else None
                if not (model and model.observed_v2 and child and 'Trace' in child['decorators']):
                    observed = False
                    break
                model = models.get(child['type'])
        if observed:
            result.append('this.' + '.'.join(parts))
    return sorted(set(result))


def called_names(tokens):
    return {token.value for index, token in enumerate(tokens[:-1])
            if token.kind == 'id' and tokens[index + 1].value == '(' and token.value not in {'if', 'switch', '$r'}}


def analyze_bindings(sources, report):
    models, by_name, model_groups = {}, defaultdict(list), defaultdict(list)
    for source in sources:
        for owner in source.owners:
            model_groups[owner.name].append(owner)
        for method in source.methods:
            by_name[method.name].append(method)
        for owner in source.owners:
            for item in owner.fields.values():
                report['state_fields'].append({'file': source.relative, 'component': owner.name,
                                               'model': owner.kind, **item})
    models = {name: owners[0] for name, owners in model_groups.items() if len(owners) == 1}
    getter_names = {name for name, methods in by_name.items() if any(method.getter for method in methods)}
    for source in sources:
        tokens = source.tokens
        ui_methods = [method for method in source.methods if method.name == 'build' or
                      '@Builder' in source.text[max(0, tokens[method.start].start - 100):tokens[method.start].start].rsplit('}', 1)[-1]]
        for index in range(1, len(tokens) - 1):
            token = tokens[index]
            if token.kind != 'id' or token.value not in ATTRIBUTES or tokens[index - 1].value != '.' or tokens[index + 1].value != '(':
                continue
            ui_method = next((method for method in ui_methods if method.body < index < method.end), None)
            closing = source.pairs.get(index + 1)
            if ui_method is None or closing is None:
                continue
            expression_tokens = tokens[index + 2:closing]
            expression = source.text[tokens[index + 1].end:tokens[closing].start]
            chain, visited = [], set()
            expression_calls = called_names(expression_tokens) | {
                parts[-1] for parts in read_paths(expression_tokens) if parts[-1] in getter_names}
            pending = [(name, 0) for name in sorted(expression_calls)]
            sensitive = any(item.kind == 'id' and (SENSITIVE.search(item.value) or item.value == 'mode') for item in expression_tokens)
            observed = observable_reads(expression_tokens, ui_method.owner, models)
            while pending:
                name, depth = pending.pop()
                if depth > 4 or name in visited:
                    continue
                visited.add(name)
                choices = by_name.get(name, [])
                local = [item for item in choices if item.source is source and item.owner is ui_method.owner]
                if not local:
                    local = [item for item in choices if item.source is source]
                resolved = local[0] if len(local) == 1 else choices[0] if len(choices) == 1 else None
                if resolved is None:
                    continue
                body_tokens = resolved.source.tokens[resolved.body + 1:resolved.end]
                sensitive |= any(item.kind == 'id' and (SENSITIVE.search(item.value) or item.value == 'mode') for item in body_tokens)
                observed += observable_reads(body_tokens, resolved.owner, models)
                chain.append({'file': resolved.source.relative, 'function': resolved.name,
                              'line': resolved.source.tokens[resolved.start].line})
                pending.extend((child, depth + 1) for child in sorted(called_names(body_tokens)) if child not in visited)
            resources = [item.value for item in expression_tokens if item.kind == 'string' and
                         re.match(r'^(?:app|sys|\[[^\[\]\s]+\])\.color\.', str(item.value))]
            direct = any((item.kind == 'string' and re.fullmatch(r'#[0-9A-Fa-f]{3,8}', str(item.value))) or
                         (item.value == 'Color' and item.kind == 'id') for item in expression_tokens)
            if not (resources or direct or sensitive or observed):
                continue
            binding = {'file': source.relative, 'line': token.line, 'attribute': token.value,
                       'component': ui_method.owner.name if ui_method.owner else None,
                       'model': ui_method.owner.kind if ui_method.owner else None,
                       'expression': expression.strip()[:600], 'resources': resources,
                       'observed_references': sorted(set(observed)), 'call_chain': chain}
            report['bindings'].append(binding)
            if sensitive and not observed:
                report['candidates'].append({**binding, 'rule': 'attribute-theme-update',
                    'category': 'compatibility', 'status': 'needs-review',
                    'reason': '核对该主题/模式表达式的变化来源及目标属性的更新触发。'})
            elif direct:
                report['candidates'].append({**binding, 'rule': 'direct-color',
                    'category': 'adaptation-option', 'status': 'needs-review',
                    'reason': '直接色值：核对是否需要随深浅色变化，再选择资源或反色方案。'})


def collect_files(root, scopes, limit, skipped):
    seen, result = set(), []
    for scope in scopes or [root]:
        scope = scope.resolve()
        if not scope.is_relative_to(root):
            raise ValueError('scope is outside project root: ' + str(scope))
        if not scope.exists():
            raise ValueError('scope does not exist: ' + str(scope))
        if scope.is_file():
            groups = [(scope.parent, [], [scope.name])]
        else:
            groups = os.walk(scope, followlinks=False)
        for parent, directories, filenames in groups:
            parent = Path(parent)
            directories[:] = sorted(name for name in directories if name not in SKIP_DIRS and not (parent / name).is_symlink())
            for name in sorted(filenames):
                path = parent / name
                if path.suffix not in CODE_EXTENSIONS | NATIVE_EXTENSIONS and name not in {'build-profile.json5', 'module.json5', 'color.json'}:
                    continue
                if path.is_symlink() or not path.resolve().is_relative_to(root):
                    skipped.append({'file': str(path), 'reason': 'symlink or outside project'})
                    continue
                relative = path.relative_to(root).as_posix()
                if relative in seen:
                    continue
                if len(result) >= limit:
                    skipped.append({'file': relative, 'reason': 'file limit reached'})
                    return result
                seen.add(relative)
                result.append((path, relative))
    return result


def scan(root, scopes=None, max_files=10000, max_bytes=1048576):
    root = root.resolve()
    report = {'schema_version': '1.0', 'root': str(root), 'versions': [], 'performance': [],
              'color_resources': [], 'native_configuration': [], 'state_fields': [],
              'bindings': [], 'candidates': [],
              'coverage': {'analysis': 'candidate-discovery', 'semantic_audit': False,
                           'files_scanned': 0, 'skipped': [], 'errors': [],
                           'limitations': ['动态配置、模板字符串、复杂间接调用与跨文件对象关系需人工核对。']}}
    sources = []
    for path, relative in collect_files(root, scopes, max_files, report['coverage']['skipped']):
        try:
            if path.stat().st_size > max_bytes:
                report['coverage']['skipped'].append({'file': relative, 'reason': 'file too large'})
                continue
            text = path.read_text(encoding='utf-8-sig')
            report['coverage']['files_scanned'] += 1
            if path.name in {'build-profile.json5', 'module.json5', 'color.json'}:
                data = ConfigParser(text).parse()
                if not isinstance(data, dict):
                    raise ValueError('configuration root must be an object')
                if path.name == 'build-profile.json5':
                    app = data.get('app', {})
                    for product in app.get('products', []):
                        if isinstance(product, dict):
                            report['versions'].append({'file': relative, 'product': product.get('name'),
                                **{key: product.get(key, app.get(key)) for key in
                                   ('compileSdkVersion', 'targetSdkVersion', 'compatibleSdkVersion')}})
                elif path.name == 'module.json5':
                    metadata = data.get('module', {}).get('metadata', [])
                    flags = [item for item in metadata if isinstance(item, dict) and
                             item.get('name') == 'configColorModeChangePerformanceInArkUI']
                    report['performance'].append({'file': relative, 'module': data.get('module', {}).get('name'),
                                                 'values': [item.get('value') for item in flags],
                                                 'enabled_by_metadata': any(item.get('value') == 'true' for item in flags)})
                    if len(flags) > 1 or any(not isinstance(item.get('value'), str) for item in flags):
                        token = next((item for item in tokenize(text) if item.value == 'configColorModeChangePerformanceInArkUI'), None)
                        report['candidates'].append({'file': relative, 'line': token.line if token else 1,
                            'rule': 'performance-metadata', 'category': 'configuration', 'status': 'needs-review',
                            'reason': '合并重复开关项，并使用字符串 value。'})
                elif '/resources/' in '/' + relative:
                    qualifier = path.parent.parent.name
                    report['color_resources'].append({'file': relative, 'qualifier': qualifier,
                        'names': [item.get('name') for item in data.get('color', []) if isinstance(item, dict)]})
            elif path.suffix in CODE_EXTENSIONS:
                sources.append(Source(path, relative, text))
            elif path.suffix in NATIVE_EXTENSIONS:
                for token in tokenize(text):
                    if token.kind == 'id' and token.value in {'OH_ArkUI_SetForceDarkConfig', 'OH_ArkUI_QueryModuleInterfaceByName'}:
                        report['native_configuration'].append({'file': relative, 'line': token.line,
                            'api': token.value, 'snippet': text[token.start:token.start + 300].split(';', 1)[0]})
        except (OSError, UnicodeError, ValueError, IndexError, TypeError, AttributeError) as error:
            report['coverage']['errors'].append({'file': relative, 'reason': str(error)})
    analyze_bindings(sources, report)
    report['coverage']['enumeration_complete'] = not report['coverage']['errors'] and not report['coverage']['skipped']
    return report


def main():
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', type=Path, help='application root or one .ets/.ts file')
    parser.add_argument('--scope', action='append', default=[], help='project-relative file/directory; repeatable')
    parser.add_argument('--max-files', type=int, default=10000)
    parser.add_argument('--max-bytes', type=int, default=1048576)
    args = parser.parse_args()
    try:
        if not args.root.exists() or args.max_files < 1 or args.max_bytes < 1:
            raise ValueError('root must exist; limits must be positive')
        root = args.root.resolve().parent if args.root.is_file() else args.root.resolve()
        scopes = [args.root.resolve()] if args.root.is_file() else [root / item for item in args.scope]
        result = scan(root, scopes, args.max_files, args.max_bytes)
    except (OSError, ValueError) as error:
        print(json.dumps({'error': str(error)}, ensure_ascii=False), file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
