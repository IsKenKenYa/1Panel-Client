#!/usr/bin/env python3
"""
检测 ets 文件及其 import 闭包是否存在 top-level 代码（import 时执行的代码）。
返回三态: false(存在) / true(不存在) / maybe(存疑)。

【per-file 判据 (own)】
  CLEAR YES -> own=FALSE:
    1. 顶层控制流 (if/for/while/do/switch/try/return/throw/break/continue)
    2. 顶层表达式语句 (裸调用、赋值、new)
    3. 顶层 const/let/var 初始化器含 new/调用 (非箭头);
       多行初始化器(括号/花括号跨行未配平)自声明行累积至配平后整体分类
    4. 类 static 字段初始化器含 new/调用
    (模板字面量内含调用已并入 3/2，见 classify_init)
  A3 装饰器 (@Component/@Expose/@Transform/@State/...) -> own=MAYBE
  其余 (import/export/function/class/interface/type/enum/const 无初始化/字面量/static 字面量/实例字段) -> 不计

  已裁定不计入: A1 顶层字面量const / A2 static字面量 / A4 实例字段(含new)

【递归规则】
  - import lazy {...} from '...'      -> 不跟 (lazy 模块在 F import 时不加载)
  - export ... from 'SPEC' / import ... from 'SPEC' / import 'SPEC' (re-export 与普通 import)
      · SPEC 为相对路径 (./ ../ /) -> 解析跟入 (concrete true/false/maybe)
      · SPEC 为系统模块 (@kit/@ohos/@hms/@native 前缀) -> 跳过 (无源码)
      · SPEC 为裸名/scoped包 (module_a, @groupname/...) -> maybe (resolver 未实现)
  - 环: 访问中的文件再次遇到 -> 视为 true (其自身 top-level 已由外层计入)
  - 任意闭包节点 FALSE -> 整体 FALSE；否则有 MAYBE -> maybe；全 true -> true

用法:
  python3 check_toplevel.py <file.ets> [file2.ets ...]   # 递归三态
  python3 check_toplevel.py <file.ets> --per-file         # 仅自身 (不递归)
  python3 check_toplevel.py <file.ets> --max-depth 30
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import resolver as _resolver_mod

# 检测逻辑版本: 判定规则变更时 bump, 使 analyze_report 的磁盘缓存(_version 不匹配)自动失效
DETECTION_VERSION = 2

_RESOLVER = None
_RESOLVER_ROOT = None


def get_resolver(for_file):
    """按输入文件向上查找项目根(同时含 oh-package.json5 与 oh_modules), 缓存单个 Resolver。"""
    global _RESOLVER, _RESOLVER_ROOT
    d = os.path.dirname(os.path.abspath(for_file))
    root = None
    for _ in range(25):
        if os.path.isfile(os.path.join(d, 'oh-package.json5')) and os.path.isdir(os.path.join(d, 'oh_modules')):
            root = d
            break
        nd = os.path.dirname(d)
        if nd == d:
            break
        d = nd
    if root is None:
        root = os.getcwd()
    if root != _RESOLVER_ROOT:
        _RESOLVER = _resolver_mod.Resolver(root)
        _RESOLVER_ROOT = root
    return _RESOLVER


# ───────────────────────── 1. 屏蔽字符串/注释 ─────────────────────────

def mask_source(src, keep_strings=False):
    """屏蔽注释(与可选字符串)为空格，保留换行与长度。
    keep_strings=False: 注释+字符串都屏蔽 (用于括号深度)
    keep_strings=True:  仅屏蔽注释，保留字符串 (用于提取 import 说明符)
    """
    out = []
    i, n = 0, len(src)
    st = 'code'
    while i < n:
        c = src[i]
        nx = src[i + 1] if i + 1 < n else ''
        if st == 'code':
            if c == '/' and nx == '/':
                out.append('  '); i += 2; st = 'line'; continue
            if c == '/' and nx == '*':
                out.append('  '); i += 2; st = 'block'; continue
            if not keep_strings and c == "'":
                out.append(' '); i += 1; st = 'sq'; continue
            if not keep_strings and c == '"':
                out.append(' '); i += 1; st = 'dq'; continue
            if not keep_strings and c == '`':
                out.append(' '); i += 1; st = 'tpl'; continue
            out.append(c); i += 1; continue
        if st == 'line':
            out.append('\n' if c == '\n' else ' '); i += 1
            if c == '\n': st = 'code'
            continue
        if st == 'block':
            if c == '*' and nx == '/':
                out.append('  '); i += 2; st = 'code'; continue
            out.append('\n' if c == '\n' else ' '); i += 1; continue
        if st in ('sq', 'dq'):
            if c == '\\':
                out.append('  '); i += 2; continue
            q = "'" if st == 'sq' else '"'
            if c == q:
                out.append(' '); i += 1; st = 'code'; continue
            out.append('\n' if c == '\n' else ' '); i += 1; continue
        if st == 'tpl':
            if c == '\\':
                out.append('  '); i += 2; continue
            if c == '`':
                out.append(' '); i += 1; st = 'code'; continue
            out.append('\n' if c == '\n' else ' '); i += 1; continue
    return ''.join(out)


def compute_line_depths(masked):
    depths = []
    d = 0
    for ln in masked.split('\n'):
        depths.append(d)
        for ch in ln:
            if ch == '{':
                d += 1
            elif ch == '}':
                d = max(0, d - 1)
    return depths


# ───────────────────────── 2. 分类辅助 ─────────────────────────

CONTROL_KW = ('if', 'for', 'while', 'do', 'switch', 'try', 'return',
              'throw', 'break', 'continue', 'else', 'catch', 'finally')
DECL_KW = ('function', 'class', 'struct', 'interface', 'type', 'enum', 'namespace')

IMPORT_FROM_RE = re.compile(
    r'\bimport\b(\s+lazy\b)?[^\'"]*?\bfrom\b\s*[\'"]([^\'"]+)[\'"]')
SIDE_IMPORT_RE = re.compile(r'\bimport\b\s*[\'"]([^\'"]+)[\'"]')
EXPORT_FROM_RE = re.compile(
    r'\bexport\b[^\'"]*?\bfrom\b\s*[\'"]([^\'"]+)[\'"]')

EQUALS_RE = re.compile(r'(?<![=<>!+\-*/%&|^])=(?![=])')
STATIC_FIELD_RE = re.compile(
    r'^\s*(?:(?:public|private|protected|readonly|abstract|override|static)\s+)*'
    r'static\s+(?:(?:readonly)\s+)?'
    r'\w+\s*(?::[^=]+)?\s*=\s*(.+?)\s*;?\s*$')
METHOD_RE = re.compile(
    r'^\s*(?:(?:public|private|protected|static|abstract|async|get|set)\s+)*\w+\s*\(')


def strip_export_prefix(s):
    return re.sub(r'^\s*export\s+(?:default\s+)?', '', s).strip()


def classify_init(init, is_exported=False, is_static=False):
    """初始化器 -> 'yes' | 'no' | 'lit' | 'arrow' | 'none'。
    Y3 细化(仅顶层 const): new 一个容器且未导出、仅模块内使用 -> 'no'(benign, 不计)。
    static 字段不受细化: new -> 'yes'(类级状态)。
    先屏蔽字符串/注释/正则字面量, 避免其中的 ( 或 => 被误判。
    """
    init = init.strip().rstrip(';').strip()
    if not init:
        return 'none'
    m = mask_source(init, keep_strings=False)               # 屏蔽字符串/注释
    m = re.sub(r'/(?:[^/\\\n]|\\.)+/[gimsuy]*', ' ', m)  # 屏蔽正则字面量
    if '=>' in m:
        return 'arrow'  # 箭头函数值, import 时不执行
    no_new = re.sub(r'\bnew\s+[A-Za-z_$][\w$.]*', ' ', m)
    has_call = bool(re.search(r'[A-Za-z_$][\w$.]*\s*\(', no_new))
    has_new = bool(re.search(r'\bnew\s+', m))
    if has_call:
        return 'yes'  # 非-new 的函数调用 -> 副作用
    if has_new:
        if is_static:
            return 'yes'  # static 字段: 类级状态, 计 (不受 benign 细化)
        return 'yes' if is_exported else 'no'  # 顶层 const: 导出->yes; 未导出容器->no
    return 'lit'


def split_init(line):
    m = EQUALS_RE.search(line)
    return line[m.end():] if m else None


def classify_spec(spec, is_lazy):
    if is_lazy:
        return 'lazy'
    if spec.startswith('./') or spec.startswith('../') or spec.startswith('/'):
        return 'relative'
    if re.match(r'^@(kit|ohos|hms|native)[:./]', spec):
        return 'system'
    return 'bare'


def resolve_relative(spec, base_dir):
    p = os.path.normpath(os.path.join(base_dir, spec))
    for c in (p + '.ets', os.path.join(p, 'Index.ets'), p):
        if os.path.isfile(c):
            return c
    return None


# 装饰器副作用白名单: 求值但无副作用的装饰器不计 maybe (可经 CLI 扩充)
NO_SIDE_EFFECT_DECORATORS = {'@concurrent'}


def decorator_name(line):
    """从装饰器行提取 @name (小写, 含 @)。如 '@State(...)' -> '@state'。"""
    m = re.match(r'^\s*@([A-Za-z_$][\w$]*)', line)
    return ('@' + m.group(1).lower()) if m else None


# ───────────────────────── 3. 单文件分析 ─────────────────────────

def _net_balance(masked_line):
    """一行内 ([{ 与 )]} 的净数量, 用于多行语句累积判定。传入已屏蔽字符串/注释的行。"""
    b = 0
    for ch in masked_line:
        if ch in '([{':
            b += 1
        elif ch in ')]}':
            b -= 1
    return b


def check_file(path):
    """返回: {own, yes_hits, decorator_count, imports, n_lines}"""
    try:
        with open(path, 'r', encoding='utf-8-sig', errors='replace') as f:
            raw = f.read()
    except Exception as e:
        return {'path': path, 'error': str(e)}

    masked = mask_source(raw)
    mlines = masked.split('\n')
    rlines = raw.split('\n')
    depths = compute_line_depths(masked)

    yes_hits = []
    decorator_count = 0
    skip_until = -1  # 多行语句已消费到的行号(含), 其后续行不再单独判定

    for i in range(len(rlines)):
        if i <= skip_until:
            continue  # 已并入上一条多行语句
        ml = mlines[i] if i < len(mlines) else ''
        rl = rlines[i]
        d = depths[i] if i < len(depths) else 0
        if not ml.strip():
            continue  # 纯注释/空行
        rstrip = rl.strip()
        if not rstrip:
            continue

        # 装饰器 (任意深度) -> 白名单内不计, 其余 -> maybe
        if rstrip.startswith('@'):
            dn = decorator_name(rl)
            if dn and dn in NO_SIDE_EFFECT_DECORATORS:
                continue  # 白名单: 无副作用, 不计
            decorator_count += 1
            continue

        if d == 0:
            if re.match(r'^\s*import\b', rl):
                continue
            body = strip_export_prefix(rstrip)
            if not body:
                continue
            first = body.split(None, 1)[0]
            if first.startswith('{') or first.startswith('*'):
                continue  # re-export
            if first in ('const', 'let', 'var'):
                is_exported = bool(re.match(r'^\s*export\b', rl))
                # 多行初始化器: 自声明行累积到括号/花括号配平后整体分类。
                # 修复漏检: const A = [\n { x: f(1) }\n] 首行仅 '[' 判字面量,
                # 续行以 '{' 开头被当 re-export 跳过 (深度不统计 [])
                parts = [rstrip]
                bal = _net_balance(ml)
                j = i
                while bal > 0 and j + 1 < len(rlines):
                    j += 1
                    parts.append(rlines[j].strip())
                    bal += _net_balance(mlines[j] if j < len(mlines) else rlines[j])
                if j > i:
                    skip_until = j
                init = split_init(' '.join(parts))
                if init is not None:
                    kind = classify_init(init, is_exported)
                    if kind == 'yes':
                        yes_hits.append((i + 1, rstrip[:70], '顶层变量初始化含调用/new(导出)'))
                    # 'no'(benign new 未导出) / 'lit' / 'arrow' / 'none' -> 不计
                continue
            if first in DECL_KW:
                continue
            if first in CONTROL_KW:
                yes_hits.append((i + 1, rstrip[:70], f'顶层控制流 {first}'))
                continue
            # 表达式语句：仅明显是 调用/new/赋值/自增自减/await调用 才算 YES（保守，避免空语句/续行误报）
            if (re.match(r'^await\s+[\w$.]+\s*\(', body)
                    or re.match(r'^[\w$.]+\s*\(', body)
                    or re.match(r'^new\s', body)
                    or re.match(r'^[\w$.\[\]]+\s*(\+\+|--|=(?![=>]))', body)):
                yes_hits.append((i + 1, rstrip[:70], '顶层表达式语句'))
            continue

        if d >= 1:
            m = STATIC_FIELD_RE.match(rl)
            if m:
                if classify_init(m.group(1), is_static=True) == 'yes':
                    yes_hits.append((i + 1, rstrip[:70], 'static 字段初始化含 new/调用'))
                continue

    # ---- 提取 imports (用 resolver 分类) ----
    comments_masked = mask_source(raw, keep_strings=True)
    res = get_resolver(path)
    imports = []
    seen_spec = set()
    def add(spec, is_lazy, reexport=False):
        if (spec, is_lazy, reexport) in seen_spec:
            return
        seen_spec.add((spec, is_lazy, reexport))
        if is_lazy:
            imports.append({'spec': spec, 'is_lazy': True, 'kind': 'lazy', 'entry': None})
            return
        r = res.resolve(spec, path)
        imports.append({'spec': spec, 'is_lazy': False, 'reexport': reexport,
                        'kind': r['kind'], 'entry': r.get('entry'),
                        'note': r.get('note')})
    for m in IMPORT_FROM_RE.finditer(comments_masked):
        add(m.group(2), bool(m.group(1)))
    for m in SIDE_IMPORT_RE.finditer(comments_masked):
        add(m.group(1), False)
    for m in EXPORT_FROM_RE.finditer(comments_masked):
        add(m.group(1), False, reexport=True)

    own = 'FALSE' if yes_hits else ('MAYBE' if decorator_count else 'TRUE')
    return {
        'path': path, 'own': own, 'yes_hits': yes_hits,
        'decorator_count': decorator_count, 'imports': imports,
        'n_lines': len(rlines),
    }


# ───────────────────────── 4. 递归 ─────────────────────────

def check_recursive(path, memo, visiting, depth=0, max_depth=50):
    if path in memo:
        return memo[path]
    if path in visiting:
        return 'TRUE'  # 环: 自身 top-level 已由外层计入
    if depth > max_depth:
        return 'MAYBE'

    info = check_file(path)
    if info.get('error'):
        return 'MAYBE'
    own = info['own']
    if own == 'FALSE':
        memo[path] = 'FALSE'
        return 'FALSE'

    visiting.add(path)
    child_results = []
    child_trail = []
    seen_specs = set()
    for imp in info['imports']:
        spec = imp['spec']
        kind = imp['kind']
        entry = imp.get('entry')
        if kind in ('lazy', 'system'):
            continue
        if kind == 'unresolved' or not entry:
            child_results.append('MAYBE')
            child_trail.append((spec, 'MAYBE', imp.get('note', 'unresolved')))
            continue
        # relative / local / ohpm -> 跟入 entry
        if entry in seen_specs:
            continue
        seen_specs.add(entry)
        r = check_recursive(entry, memo, visiting, depth + 1, max_depth)
        child_results.append(r)
        child_trail.append((spec, r, os.path.relpath(entry)))

    if 'FALSE' in child_results:
        verdict = 'FALSE'
    elif own == 'MAYBE' or 'MAYBE' in child_results:
        verdict = 'MAYBE'
    else:
        verdict = 'TRUE'

    memo[path] = verdict
    visiting.discard(path)
    # 保存 trail 供报告
    info['_trail'] = child_trail
    info['_own'] = own
    _trail_cache[path] = info
    return verdict


_trail_cache = {}


# ───────────────────────── 5. 报告 ─────────────────────────

def print_report(path, info, recursive_verdict=None, trail=None):
    print(f"\n{'=' * 78}")
    print(f"FILE: {path}  ({info.get('n_lines', '?')} 行)")
    if info.get('error'):
        print(f"  ERROR: {info['error']}")
        return
    own = info['own']
    if recursive_verdict:
        v = {'TRUE': 'true', 'FALSE': 'false', 'MAYBE': 'maybe'}[recursive_verdict]
        print(f"VERDICT (递归): {v}")
    print(f"  自身 own: {own}" +
          (f"  (装饰器 {info['decorator_count']} -> maybe)" if info['decorator_count'] else ''))
    if info['yes_hits']:
        print(f"  CLEAR YES ({len(info['yes_hits'])}):")
        for ln, s, reason in info['yes_hits'][:10]:
            print(f"    L{ln:>5}  [{reason}]  {s}")
        if len(info['yes_hits']) > 10:
            print(f"    ... 另 {len(info['yes_hits'])-10} 处")
    # imports 汇总
    imps = info['imports']
    n_follow = sum(1 for x in imps if x['kind'] in ('relative', 'local', 'ohpm'))
    n_maybe = sum(1 for x in imps if x['kind'] == 'unresolved')
    n_sys = sum(1 for x in imps if x['kind'] == 'system')
    n_lazy = sum(1 for x in imps if x['kind'] == 'lazy')
    print(f"  imports: 可跟入{ n_follow} maybe{ n_maybe} 系统{ n_sys}(跳过) lazy{ n_lazy}(不跟)  共{ len(imps)}")
    if trail:
        resolved = [t for t in trail if t[2] not in ('bare/unresolved', 'relative 未解析')]
        unresolved = [t for t in trail if t[2] in ('bare/unresolved', 'relative 未解析')]
        if resolved:
            print(f"  跟入 (相对解析, {len(resolved)}):")
            for spec, v, tgt in resolved[:15]:
                print(f"    {spec}  -> {v}  ({tgt})")
            if len(resolved) > 15:
                print(f"    ... 另 {len(resolved)-15} 个")
        if unresolved:
            print(f"  -> maybe 的 import ({len(unresolved)}):")
            for spec, v, why in unresolved[:10]:
                print(f"    {spec}  ({why})")


def main():
    import argparse
    ap = argparse.ArgumentParser(description="检测 ets 文件及 import 闭包的 top-level 代码 (三态)")
    ap.add_argument('files', nargs='+', help='ets 文件路径')
    ap.add_argument('--per-file', action='store_true', help='仅自身, 不递归')
    ap.add_argument('--max-depth', type=int, default=50)
    ap.add_argument('--no-side-effect-decorators', default='',
                    help='扩充装饰器副作用白名单(逗号分隔, 默认已含 @concurrent), 如 @Concurrent,@Builder')
    args = ap.parse_args()
    if args.no_side_effect_decorators:
        for d in args.no_side_effect_decorators.split(','):
            d = d.strip()
            if d:
                NO_SIDE_EFFECT_DECORATORS.add('@' + d.lstrip('@').lower())

    summary = []
    for path in args.files:
        info = check_file(path)
        if args.per_file:
            v = info.get('own', 'MAYBE')
            trail = None
        else:
            memo = {}
            v = check_recursive(path, memo, set(), 0, args.max_depth)
            info = _trail_cache.get(path, info)  # 取带 _trail 的递归 info
            trail = info.get('_trail')
        print_report(path, info, v, trail)
        summary.append((path, v, len(info.get('yes_hits', [])),
                        info.get('decorator_count', 0)))

    print(f"\n{'=' * 78}\n汇总:")
    print(f"  {'verdict':<8} {'YES':>5} {'装饰器':>6}  file")
    for path, v, y, d in summary:
        label = {'TRUE': 'true', 'FALSE': 'false', 'MAYBE': 'maybe'}[v]
        print(f"  {label:<8} {y:>5} {d:>6}  {path}")


if __name__ == '__main__':
    main()
