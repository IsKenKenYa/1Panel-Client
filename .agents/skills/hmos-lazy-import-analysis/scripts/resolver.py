#!/usr/bin/env python3
"""
Resolver: 将 ets import 说明符 (SPEC) 解析为入口 ets 文件。

解析来源:
  - 本地源码模块: 扫描项目内所有 oh-package.json5 (排除 oh_modules/.hvigor/build)，
    按 name -> {dir, main, entry} 建映射 (bare 名如 module_a/module_c/module_b)。
    HAP 型模块 (如 entry) main 常为空且无根级 Index.ets, 此时 entry=None 但 dir 有效，
    供 resolve_report_module 按模块目录定位内部文件 (bare 名解析走后续兜底)
  - 根 oh-package.json5 overrides: name -> value; 其中 file: 值重定向到本地路径
  - oh_modules/<spec>/: ohpm 包 (@groupname/* 等), 取其 main/Index.ets (需有 .ets 源码)

resolve(spec, importing_file) -> {kind, entry, note}
  kind:
    relative  -> 已解析到本地 .ets (相对路径)
    local     -> 已解析到本地源码模块入口 .ets (bare 名 / file: override / file: dep)
    ohpm      -> 已解析到 oh_modules 包入口 .ets
    system    -> 系统模块 (@kit./@ohos:/@hms:/@native: 前缀), 无源码, 跳过
    unresolved-> 无法解析/无 .ets 源码 -> 贡献 maybe

另提供 resolve_report_module(module_name, internal_path) 用于把 Step1 报表路径
(&module_b/src/main/ets/.../X&1.0.0) 定位到磁盘 ets 文件。
"""

import os
import re

# ───────────────────────── json5 容错读取 ─────────────────────────

def _strip_comments(src, keep_strings=True):
    """屏蔽注释为空格, 保留换行与长度; keep_strings=True 时保留字符串内容。"""
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


_SQ_STR_RE = re.compile(r"'([^'\\]*(?:\\.[^'\\]*)*)'")
_UNQUOTED_KEY_RE = re.compile(r'([{,]\s*)([A-Za-z_$][\w$\-]*)(\s*:)')


def load_json5(path):
    """容错读取 json5 文件 (注释/单引号/未引用键/尾逗号) 为 dict。失败返回 None。"""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            src = f.read()
    except Exception:
        return None
    s = _strip_comments(src, keep_strings=True)
    s = _SQ_STR_RE.sub(r'"\1"', s)          # 单引号串 -> 双引号
    s = _UNQUOTED_KEY_RE.sub(r'\1"\2"\3', s)  # 未引用键 -> 引用键
    s = re.sub(r',(\s*[}\]])', r'\1', s)     # 去尾逗号
    try:
        import json
        return json.loads(s)
    except Exception:
        return None


# ───────────────────────── Resolver ─────────────────────────

SYSTEM_PREFIXES = ('@kit.', '@ohos:', '@hms:', '@native:')


class Resolver:
    def __init__(self, root):
        self.root = os.path.abspath(root)
        self.oh_modules = os.path.join(self.root, 'oh_modules')
        self.local_modules = {}   # name -> {dir, main, entry}
        self.overrides = {}       # name -> value (str)
        self._scan()

    # ---- 扫描 ----
    PRUNE_DIRS = ('oh_modules', '.hvigor', 'build', 'node_modules', '.git')

    def _scan(self):
        # 本地源码模块 (剪枝目录直接从 walk 中移除, 不下降)
        for dirpath, dirnames, filenames in os.walk(self.root):
            dirnames[:] = [d for d in dirnames if d not in self.PRUNE_DIRS]
            if 'oh-package.json5' in filenames:
                data = load_json5(os.path.join(dirpath, 'oh-package.json5'))
                if not isinstance(data, dict):
                    continue
                name = data.get('name')
                if not name:
                    continue
                main = data.get('main') or 'Index.ets'
                entry = os.path.normpath(os.path.join(dirpath, main))
                # HAP 型模块 (如 entry) main 常为空且无根级 Index.ets:
                # 仍收录 (entry=None), 供 resolve_report_module 按模块目录定位内部文件;
                # bare 名解析在 resolve() 中对 entry=None 走后续兜底
                self.local_modules[name] = {
                    'dir': dirpath, 'main': main,
                    'entry': entry if os.path.isfile(entry) else None,
                }
        # 根 overrides
        root_pkg = load_json5(os.path.join(self.root, 'oh-package.json5'))
        if isinstance(root_pkg, dict):
            ov = root_pkg.get('overrides')
            if isinstance(ov, dict):
                self.overrides = dict(ov)

    # ---- 入口查找 ----
    @staticmethod
    def _entry_of(pkg_dir):
        """给定包目录, 返回入口 ets 路径 (oh-package main, 否则 Index.ets); 无则 None。"""
        pkg = load_json5(os.path.join(pkg_dir, 'oh-package.json5'))
        main = (pkg or {}).get('main') or 'Index.ets'
        cand = os.path.normpath(os.path.join(pkg_dir, main))
        if os.path.isfile(cand) and cand.endswith('.ets'):
            return cand
        idx = os.path.normpath(os.path.join(pkg_dir, 'Index.ets'))
        if os.path.isfile(idx):
            return idx
        return None

    def _ohpm_resolve(self, spec):
        """ohpm 包解析: oh_modules/<package>[/子路径] 入口 (需 .ets 源码)。"""
        mname, internal = self._split_module_subpath(spec)
        pkg_dirs = [os.path.join(self.oh_modules, mname)]
        for d in pkg_dirs:
            if os.path.isdir(d):
                if internal:
                    for c in (os.path.join(d, internal + '.ets'),
                              os.path.join(d, internal, 'Index.ets'),
                              os.path.join(d, internal)):
                        if os.path.isfile(c):
                            return {'kind': 'ohpm', 'entry': c, 'spec': spec}
                    return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': 'ohpm 子路径无源码'}
                entry = self._entry_of(d)
                if entry:
                    return {'kind': 'ohpm', 'entry': entry, 'spec': spec}
                return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': 'ohpm 无源码/未安装'}
        return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': 'ohpm 未安装'}

    def _split_module_subpath(self, spec):
        """拆分 裸名/@scope:name + 子路径。返回 (module, internal|None)。"""
        if spec.startswith('@'):
            m = re.match(r'^(@[^/]+/[^/]+)(/.*)?$', spec)
            if m:
                return m.group(1), (m.group(2)[1:] if m.group(2) else None)
            return spec, None
        seg = spec.split('/', 1)
        return seg[0], (seg[1] if len(seg) > 1 else None)

    # ---- 主解析 ----
    def resolve(self, spec, importing_file):
        # 跨平台: 归一化路径分隔符
        spec = spec.replace("\\", "/")
        # 1) 相对路径 (相对 importing 文件); 以 / 开头的绝对路径相对项目根
        if spec.startswith(('./', '../')):
            base = os.path.dirname(importing_file)
            p = os.path.normpath(os.path.join(base, spec))
            for c in (p + '.ets', os.path.join(p, 'Index.ets'), p):
                if os.path.isfile(c):
                    return {'kind': 'relative', 'entry': c, 'spec': spec}
            return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': '相对路径未解析'}
        if spec.startswith('/'):
            p = os.path.normpath(os.path.join(self.root, spec.lstrip('/')))
            for c in (p + '.ets', os.path.join(p, 'Index.ets'), p):
                if os.path.isfile(c):
                    return {'kind': 'relative', 'entry': c, 'spec': spec, 'note': '绝对路径(项目根)'}
            return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': '绝对路径未解析(项目根)'}

        # 2) 系统模块
        if spec.startswith(SYSTEM_PREFIXES):
            return {'kind': 'system', 'entry': None, 'spec': spec}

        # 3) overrides 全局覆盖 (优先于模块自身 dependencies)
        if spec in self.overrides:
            ov = self.overrides[spec]
            if isinstance(ov, str) and ov.startswith('file:'):
                p = ov[len('file:'):]
                full = os.path.normpath(os.path.join(self.root, p))
                entry = self._entry_of(full)
                if entry:
                    return {'kind': 'local', 'entry': entry, 'spec': spec, 'note': 'override file:'}
                return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': 'override file: 无入口'}
            # 版本号 override: 全局生效, 走 ohpm, 忽略模块自身 file: 依赖
            return self._ohpm_resolve(spec)

        # 3.5) 裸名/@scope:name + 子路径 (如 'module_b/src/main/ets/.../X')
        mname, internal = self._split_module_subpath(spec)
        if internal and mname in self.local_modules:
            entry = self.resolve_report_module(mname, internal)
            if entry:
                return {'kind': 'local', 'entry': entry, 'spec': spec, 'note': 'module+subpath'}
            # 子路径未命中文件, 不再走 ohpm(同名包不会有该子路径)
            return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': 'module+subpath 无文件'}

        # 4) 本地源码模块 (bare 名, 无子路径)
        if mname in self.local_modules and internal is None:
            entry = self.local_modules[mname]['entry']
            # entry=None (HAP 模块无入口): 不作为 bare 名解析成功, 走后续兜底
            if entry:
                return {'kind': 'local', 'entry': entry, 'spec': spec}

        # 5) file: 依赖 (查 importing 模块的 oh-package deps)
        deps = self._enclosing_deps(importing_file)
        dep_val = deps.get(spec) if deps else None
        if isinstance(dep_val, str) and dep_val.startswith('file:'):
            p = dep_val[len('file:'):]
            base = self._enclosing_module_dir(importing_file)
            full = os.path.normpath(os.path.join(base, p))
            entry = self._entry_of(full)
            if entry:
                return {'kind': 'local', 'entry': entry, 'spec': spec, 'note': 'dep file:'}
            return {'kind': 'unresolved', 'entry': None, 'spec': spec, 'note': 'dep file: 无入口'}

        # 6) ohpm 包 (可能带子路径)
        return self._ohpm_resolve(spec)

    # ---- 辅助: importing 文件所在模块的 oh-package deps ----
    def _enclosing_module_dir(self, importing_file):
        d = os.path.dirname(os.path.abspath(importing_file))
        for _ in range(20):
            if os.path.isfile(os.path.join(d, 'oh-package.json5')):
                return d
            nd = os.path.dirname(d)
            if nd == d:
                break
            d = nd
        return None

    def _enclosing_deps(self, importing_file):
        md = self._enclosing_module_dir(importing_file)
        if not md:
            return None
        pkg = load_json5(os.path.join(md, 'oh-package.json5'))
        deps = (pkg or {}).get('dependencies')
        return deps if isinstance(deps, dict) else {}

    # ---- 报表路径定位 (Step1 应用) ----
    def resolve_report_module(self, module_name, internal_path):
        """module_name (module_b / @groupname/pkg3) + internal_path (src/main/ets/.../X) -> ets 文件。"""
        # 找模块根目录
        if module_name in self.local_modules:
            base = self.local_modules[module_name]['dir']
        else:
            # ohpm
            d = os.path.join(self.oh_modules, module_name)
            base = d if os.path.isdir(d) else None
        if not base:
            return None
        # internal_path 末尾去版本号已由调用方完成; 补 .ets
        for c in (os.path.join(base, internal_path + '.ets'),
                  os.path.join(base, internal_path, 'Index.ets'),
                  os.path.join(base, internal_path)):
            if os.path.isfile(c):
                return c
        return None


if __name__ == '__main__':
    import sys
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    r = Resolver(root)
    print(f"local_modules: {len(r.local_modules)} 个")
    print(f"overrides: {len(r.overrides)} 项 (file: 重定向 {sum(1 for v in r.overrides.values() if isinstance(v,str) and v.startswith('file:'))})")
    print("\n抽样 local_modules:")
    for k in list(r.local_modules)[:8]:
        print(f"  {k} -> {os.path.relpath(r.local_modules[k]['entry'], root)}")

    # —— 动态构造抽样 spec：从扫描结果中实时取样，不硬编码任何项目名 ——
    names = list(r.local_modules)
    imp = r.local_modules[names[0]]['entry'] if names else os.path.join(root, 'Index.ets')
    samples = []  # (类别, spec, importing_file)

    # 1) 本地 bare 名（前 3 个）
    for n in names[:3]:
        samples.append(('local', n, imp))

    # 2) 模块+子路径：从首个本地模块目录挑一个非 Index 的 .ets 构造 name/src/.../X
    if names:
        mdir = r.local_modules[names[0]]['dir']
        for dirpath, _dirnames, filenames in os.walk(mdir):
            ets = [f for f in filenames if f.endswith('.ets') and f != 'Index.ets']
            if ets:
                rel = os.path.relpath(os.path.join(dirpath, ets[0]), mdir)[:-len('.ets')]
                samples.append(('module+subpath', f"{names[0]}/{rel.replace(os.sep, '/')}", imp))
                break
        # 3) 相对路径
        samples.append(('relative', './Index', imp))

    # 4) overrides 中 file: 重定向的 key（前 2 个）
    for k in [k for k, v in r.overrides.items() if isinstance(v, str) and v.startswith('file:')][:2]:
        samples.append(('override', k, imp))

    # 5) ohpm scoped 包：扫 oh_modules/@scope/pkg，取前 3 个有 .ets 入口的
    scanned = []
    if os.path.isdir(r.oh_modules):
        for scope in sorted(os.listdir(r.oh_modules)):
            sdir = os.path.join(r.oh_modules, scope)
            if not scope.startswith('@') or not os.path.isdir(sdir):
                continue
            for pkg in sorted(os.listdir(sdir)):
                if Resolver._entry_of(os.path.join(sdir, pkg)):
                    scanned.append(f"{scope}/{pkg}")
    for spec in scanned[:3]:
        samples.append(('ohpm', spec, imp))

    # 6) 系统模块（固定样例）
    samples.append(('system', '@kit.ArkUI', imp))

    print("\n抽样解析:")
    for tag, spec, ifile in samples:
        res = r.resolve(spec, ifile)
        e = os.path.relpath(res['entry'], root) if res['entry'] else None
        print(f"  [{tag:15}] {spec:40} -> {res['kind']:10} {e or res.get('note', '')}")
