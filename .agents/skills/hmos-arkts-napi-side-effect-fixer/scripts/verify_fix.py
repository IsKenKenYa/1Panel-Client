#!/usr/bin/env python3
"""verify_fix.py — 整改后回归验证：确认整改目标不再命中「NAPI 加载期副作用」。

本脚本属于整改技能（hmos-arkts-napi-side-effect-fixer）的**验证端**，
不做初筛——问题发现由上游扫描技能（hmos-arkts-napi-side-effect-checker，
prescan.py）负责。整改技能的标准流程：

    扫描技能产出（报告/prescan 输出）
      → parse_scan_report.py     解析为整改工作清单（类别1→引擎 E、类别2→引擎 L）
      → apply_lazy_init.py       引擎 L：类别2 惰性访问器改写（dry-run/--apply）
      → apply_init_extraction.py 引擎 E：类别1 业务初始化迁显式 init() 导出
      → verify_fix.py            本脚本：回归验证（见下）

两种用法：

1. 整改后回归验证（主用途）——对整改过的文件/目录复查，输出残留候选；
   全部清零退出码 0，仍有命中退出码 1（可做 CI 门禁）：
       python3 verify_fix.py <整改后的文件或目录>

2. 无扫描报告时的补充定位（备用）——扫描技能 prescan 的 P1 信号存在已知盲区
   （`Type *name` 空格+星号风格不匹配，如 `static ImagePictureNative *g_thisPicture`），
   对此类文件可用本脚本定位目标，再经 --target 补入整改工作清单。

检测目标问题（两个冷启动场景，与扫描技能类别一致）：

  类别2（全局单例即时初始化）：
    C++ 层模块加载（dlopen）即创建全局数据库/网络/业务单例，
    而不是在接口（导出函数）内部首次使用时才创建。
    - 形态A（文件作用域动态初始化器）——so 加载即执行
    - 形态B（注册回调内全局赋值）——注册链内执行

  类别1（注册函数违规业务逻辑）：
    nm_register_func 的 Init 回调内写业务初始化（信号注册/线程创建/
    进程级注册等），so 被 dlopen 即执行；整改后 Init 只做函数映射，
    业务初始化位于显式导出的 init() 接口。验证：对注册回调
    （nm_register_func 目标 / NAPI_MODULE 宏 / __attribute__((constructor))）
    逐语句分类，残留 MOVE（业务动作）即未整改完成。

豁免（不计候选）：
  - 常量初始化（nullptr/0/NULL/false/true/字面量/constexpr/constinit）
  - thread_local 空初始化（每线程首次使用时初始化，加载期不执行）
  - using/typedef/extern 声明行
  - 直接初始化 `Type name(args);`（与函数原型无法机械区分，默认不报；
    加 --direct 以候选形式输出，逐条需人工确认）
  - 类别1 分类中：napi 导出面 API、实参含 exports 的调用、exports 数据流
    局部变量、被调函数体只含 napi 面 API、日志/判空守卫/return、控制流
    语句、全局赋值（归形态B口径）——均不算业务残留

输出（markdown）：类别2 候选表（文件:行、变量、形态、初始化动作、使用点/
写入点/判空点统计、告警、建议策略）＋类别1 残留表（回调、语句、依据）
＋逐条详情＋回归结论；--json 输出机器可读清单。


Usage:
  python3 verify_fix.py <dir-or-file> [--all] [--all-tu] [--direct]
                       [--callback NAME] [--json] [--root ROOT] [--crosscheck]

  <dir-or-file> : 扫描目标（目录或单个 C/C++ 文件）
  --all         : 包含 test/tests/fuzz 目录（默认跳过）
  --all-tu      : 扫描全部编译单元（默认仅扫含 NAPI 注册要素的文件）。
                  形态A 在 so 内任意 TU 都会于加载期执行——用该开关捕获
                  与注册文件同 .so 但自身无注册要素的 TU（归属按目录与
                  BUILD.gn 标注，供人工确认）
  --direct      : 追加「直接初始化」候选（Type name(args); 形态，与函数
                  原型无法机械区分，必须逐条人工确认后才可整改）
  --callback NAME : 类别1 残留扫描附加回调名（跨文件注册：nm_register_func
                  在别的文件、回调定义在本文件时，用该参数点名核查）
  --json        : 输出 JSON 工作清单（供 apply_lazy_init.py 消费）
  --root ROOT   : 仓库根（--crosscheck 的跨文件引用检查范围）
  --crosscheck  : 启用跨文件同名引用检查（较慢）
"""
import argparse
import json
import os
import re
import sys

# 复用引擎 E 的语句分类器（同目录导入；不可用时类别1 残留扫描降级跳过）
try:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import apply_init_extraction as _aie
    CAT1_SCAN_AVAILABLE = True
except Exception:  # noqa: BLE001
    _aie = None
    CAT1_SCAN_AVAILABLE = False

SRC_SUFFIXES = (".cpp", ".cc", ".cxx", ".c")
EXCLUDE_DIRS_DEFAULT = {"out", ".git", "prebuilts", "node_modules"}
EXCLUDE_DIRS_STRICT = EXCLUDE_DIRS_DEFAULT | {"test", "tests", "fuzz", "fuzztest", "benchmark"}

NAPI_ANCHOR_RE = re.compile(
    r'napi_module_register\s*\('
    r'|\.\s*nm_register_func\b'
    r'|\bNAPI_MODULE\w*\s*\('
    r'|\bnapi_module_with_js_register\b'
)

REGISTER_FIELD_RE = re.compile(r'\.\s*nm_register_func\s*=\s*&?\s*([A-Za-z_]\w*)')
REGISTER_MACRO_RE = re.compile(r'\bNAPI_MODULE\w*\s*\(\s*[\w."\']+?\s*,\s*&?\s*([A-Za-z_]\w*)')

# 声明行解析：类型与变量名之间必须有空白或指针/引用符
# （防止 `auto g_asyncContext = ...` 被拆成 type=`g_asyncContex`、name=`t`）
DECL_RE = re.compile(
    r'^(?P<quals>(?:(?:static|inline|extern|thread_local|unsigned|signed|long|short|'
    r'constexpr|constinit|const|volatile)\s+)*)'
    r'(?P<auto>auto\s+)?'
    r'(?P<type>[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*(?:\s*<[^=;()]*?>)?)'
    r'(?P<sep>\s*[\s*&]+\s*|\s*\*+\s*|\s*&+\s*|\s+)'
    r'(?P<name>[A-Za-z_]\w*)\s*'
    r'(?P<rest>=|;|\()'
)

# 动态初始化 RHS（重操作证据）
DYN_RHS_RE = re.compile(
    r'^(?:new\s+[A-Z_~]'
    r'|new\s*\('
    r'|std\s*::\s*make_(?:unique|shared)\s*<'
    r'|(?:std\s*::\s*)?(?:unique_ptr|shared_ptr)\s*<'
    r'|[A-Z]\w*(?:::[A-Z]\w*)*::(?:GetInstance|Create|Instance)\s*\('
    r'|[A-Z]\w*(?:::\w+)*\s*\('
    r')'
)
# 常量初始化 RHS（不计问题）
CONST_RHS_RE = re.compile(
    r'^(?:nullptr|nullptr_t|NULL|__null|true|false|'
    r'[\+\-]?\d[\dxXa-fA-F\'.eE+\-]*|'
    r'"[^"]*"|\'[^\']*\'|'
    r'\{\s*\}|'
    r'[A-Z_][A-Z0-9_]*'
    r')\s*[;,)]?\s*$'
)
EXCLUDE_LINE_START_RE = re.compile(r'^(using|typedef|extern|return|delete|else|\}|\))\b')


def mask_source(src):
    """Blank out comments and string/char literals, preserving offsets/newlines."""
    out = list(src)
    n = len(src)
    i = 0
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ""
        if c == "/" and nxt == "/":
            while i < n and src[i] != "\n":
                out[i] = " "
                i += 1
        elif c == "/" and nxt == "*":
            out[i] = out[i + 1] = " "
            i += 2
            while i < n:
                if src[i] == "*" and i + 1 < n and src[i + 1] == "/":
                    out[i] = out[i + 1] = " "
                    i += 2
                    break
                if src[i] != "\n":
                    out[i] = " "
                i += 1
        elif c == '"' or c == "'":
            q = c
            out[i] = " "
            i += 1
            while i < n and src[i] != q:
                if src[i] == "\\" and i + 1 < n:
                    out[i] = " "
                    if src[i + 1] != "\n":
                        out[i + 1] = " "
                    i += 2
                else:
                    if src[i] != "\n":
                        out[i] = " "
                    i += 1
            if i < n:
                out[i] = " "
                i += 1
        else:
            i += 1
    return "".join(out)


def line_of(s, idx):
    return s.count("\n", 0, idx) + 1


def line_start(s, idx):
    return s.rfind("\n", 0, idx) + 1


def match_balanced(s, open_idx, open_ch="{", close_ch="}"):
    depth = 0
    for k in range(open_idx, len(s)):
        if s[k] == open_ch:
            depth += 1
        elif s[k] == close_ch:
            depth -= 1
            if depth == 0:
                return k
    return -1


def find_function_def(masked, name):
    last = name.rsplit("::", 1)[-1]
    for target in {name, last}:
        for m in re.finditer(r"\b%s\s*\(" % re.escape(target), masked):
            op = m.end() - 1
            cp = match_balanced(masked, op, "(", ")")
            if cp < 0:
                continue
            k = cp + 1
            while k < len(masked) and masked[k] in " \t\r\n":
                k += 1
            w = re.match(r"(const|override|noexcept)", masked[k:k + 10])
            if w:
                k += len(w.group(1))
                while k < len(masked) and masked[k] in " \t\r\n":
                    k += 1
            if k < len(masked) and masked[k] == "{":
                cb = match_balanced(masked, k)
                if cb >= 0:
                    return m.start(), k, cb
    return None


def iter_files(root, all_mode):
    excl = EXCLUDE_DIRS_DEFAULT if all_mode else EXCLUDE_DIRS_STRICT
    if os.path.isfile(root):
        yield root
        return
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in excl and not d.startswith(".")]
        for fn in sorted(filenames):
            if fn.endswith(SRC_SUFFIXES):
                yield os.path.join(dirpath, fn)


def statement_text(lines, start_idx):
    parts = []
    i = start_idx
    while i < len(lines):
        parts.append(lines[i])
        if ";" in lines[i]:
            break
        i += 1
    return " ".join(parts)


def collect_stats(var, masked, decl_lines):
    """Use-site statistics for variable `var` (mask-aware)."""
    var_re = re.compile(r"\b%s\b" % re.escape(var))
    reads, writes, nullchecks, addrs, deletes = [], [], [], [], []
    for m in var_re.finditer(masked):
        ln = line_of(masked, m.start())
        if ln in decl_lines:
            continue
        tail = masked[m.end():m.end() + 3]
        if re.match(r'\s*=(?!=)', tail) or re.match(r'\s*(\+\+|--|\+=|-=)', tail):
            writes.append(ln)
        if re.search(r'\s*(==|!=)\s*(nullptr|NULL|0)\b', tail):
            nullchecks.append(ln)
        # 取变量本身地址（&var 不接 -> 或 . —— &var->member 是成员地址，安全）
        if re.search(r'&\s*%s\s*(?!->|\.)' % re.escape(var),
                     masked[max(0, m.start() - 4):m.end() + 3]) \
                and not re.match(r'\s*(->|\.)', tail):
            addrs.append(ln)
        if re.search(r'\bdelete\s+%s\b' % re.escape(var), masked[max(0, m.start() - 12):m.end()]):
            deletes.append(ln)
        reads.append(ln)
    return {
        "reads": sorted(set(reads)),
        "writes": sorted(set(writes)),
        "nullchecks": sorted(set(nullchecks)),
        "addr_uses": sorted(set(addrs)),
        "deletes": sorted(set(deletes)),
    }


def scan_one_file(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            src = fh.read()
    except OSError:
        return []
    masked = mask_source(src)
    mlines = masked.split("\n")
    candidates = []

    def add(var, ln, form, decl_type, rhs, decl_lines, notes=""):
        stats = collect_stats(var, masked, decl_lines)
        warnings = []
        if stats["writes"]:
            warnings.append("存在其他写入点 L%s（惰性化需人工确认）" % stats["writes"][:6])
        if stats["addr_uses"]:
            warnings.append("存在取变量地址用法 &%s（L%s）" % (var, stats["addr_uses"][:6]))
        if stats["deletes"]:
            warnings.append("存在 delete 用法（L%s）" % stats["deletes"][:6])
        candidates.append({
            "file": path,
            "line": ln,
            "var": var,
            "form": form,
            "type": decl_type,
            "init": rhs,
            "reads": stats["reads"],
            "writes": stats["writes"],
            "nullchecks": stats["nullchecks"],
            "warnings": warnings,
            "notes": notes,
        })

    # ---- 形态A：列首声明的动态初始化 ----
    for idx, line in enumerate(mlines):
        if not line.strip() or line[:1] in (" ", "\t", "#"):
            continue  # 列首锚定（OHOS 风格下命名空间内容同列首）
        if EXCLUDE_LINE_START_RE.match(line):
            continue
        m = DECL_RE.match(line)
        if not m:
            continue
        if "constexpr" in (m.group("quals") or "") or "constinit" in (m.group("quals") or ""):
            continue
        if m.group("rest") != "=":
            continue
        name = m.group("name")
        vtype = m.group("type").strip()
        # RHS 从原文提取（保留字符串内容）
        stmt = statement_text(mlines, idx)
        if "=" not in stmt:
            continue
        src_lines = src.split("\n")
        src_stmt = "\n".join(src_lines[idx: idx + (stmt.count("\n") + 1)])
        rhs = src_stmt.split("=", 1)[1].strip().rstrip(";").strip()
        if CONST_RHS_RE.match(rhs):
            continue  # 常量初始化
        if not DYN_RHS_RE.match(rhs):
            continue
        notes = ""
        if "thread_local" in (m.group("quals") or ""):
            notes = "thread_local 动态初始化——每线程首次使用时才初始化，加载期不执行（确认是否真为问题）"
        add(name, idx + 1, "A", vtype, rhs, {idx + 1}, notes)

    # ---- 形态B：注册回调内全局赋值 ----
    cb_names = {m.group(1) for m in REGISTER_FIELD_RE.finditer(masked)}
    cb_names |= {m.group(1) for m in REGISTER_MACRO_RE.finditer(masked)}
    # so 加载即执行的 constructor 函数同样在注册链上（dlopen → constructor）
    cb_names |= {m.group(1) for m in
                 re.finditer(r'__attribute__\s*\(\(\s*constructor\s*\)\)\s*[^;{]*?\b([A-Za-z_]\w*)\s*\(', masked)}
    for cb in cb_names:
        if cb == "nullptr":
            continue
        fs = find_function_def(masked, cb)
        if not fs:
            continue
        body = masked[fs[1]:fs[2]]
        for am in re.finditer(r"\b(g_\w+|[a-z]\w*_\w+)\s*=", body):
            var = am.group(1)
            rhs = body[am.end():am.end() + 300].split(";")[0].strip()
            if CONST_RHS_RE.match(rhs) or not DYN_RHS_RE.match(rhs):
                continue
            # 确认 var 是同文件文件作用域变量（列首声明）
            decl_line = None
            decl_type = ""
            for idx2, line2 in enumerate(mlines):
                dm = DECL_RE.match(line2)
                if dm and dm.group("name") == var and dm.group("rest") in ("=", ";"):
                    decl_line = idx2 + 1
                    decl_type = dm.group("type").strip()
                    break
            if decl_line is None:
                continue
            ln = line_of(masked, fs[1] + am.start())
            add(var, ln, "B", decl_type, rhs, {decl_line, ln},
                "注册回调 `%s` 内赋值（声明于 L%d）" % (cb, decl_line))
    return candidates


def scan_cat1_residual(path, extra_callback=None):
    """类别1 残留扫描：注册回调内仍有业务初始化语句（MOVE）。

    回调收集：nm_register_func 字段 / NAPI_MODULE 宏 / __attribute__((constructor))
    （均在加载链上——dlopen 即执行）＋ extra_callback（跨文件注册点名核查）。
    分类复用 apply_init_extraction.classify_callback（与引擎 E 同口径：
    导出面 API/exports 实参/exports 数据流/被调体只含 napi API/日志/
    判空守卫/return/控制流/全局赋值 → 不算残留）。
    """
    if not CAT1_SCAN_AVAILABLE:
        return [], "类别1 残留扫描不可用（apply_init_extraction.py 缺失）"
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError:
        return [], None
    masked = mask_source(text)
    cb_names = {m.group(1) for m in REGISTER_FIELD_RE.finditer(masked)}
    cb_names |= {m.group(1) for m in REGISTER_MACRO_RE.finditer(masked)}
    cb_names |= {m.group(1) for m in re.finditer(
        r'__attribute__\s*\(\(\s*constructor\s*\)\)\s*[^;{]*?\b([A-Za-z_]\w*)\s*\(', masked)}
    if extra_callback:
        cb_names.add(extra_callback)
    residuals = []
    for cb in sorted(cb_names):
        if cb == "nullptr":
            continue
        fcb = _aie.parse_callback(text, cb)
        if not fcb:
            continue
        stmts, _stat = _aie.classify_callback(text, fcb)
        for st in stmts:
            if st["cls"] == "MOVE":
                first = next((ln.strip() for ln in st["lines"] if ln.strip()), "")
                residuals.append({
                    "file": path,
                    "line": st["abs"],
                    "callback": cb,
                    "stmt": first[:96],
                    "note": st.get("note", ""),
                    "form": "cat1",
                })
    return residuals, None


def build_flags_context(path):
    d = os.path.dirname(os.path.abspath(path))
    for _ in range(6):
        bg = os.path.join(d, "BUILD.gn")
        if os.path.isfile(bg):
            try:
                with open(bg, encoding="utf-8", errors="replace") as fh:
                    txt = fh.read()
            except OSError:
                return None
            return {
                "build_gn": bg,
                "no_threadsafe_statics": "-fno-threadsafe-statics" in txt,
                "no_exceptions": "-fno-exceptions" in txt,
            }
        nd = os.path.dirname(d)
        if nd == d:
            break
        d = nd
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("target")
    ap.add_argument("--all", action="store_true", help="include test/fuzz dirs")
    ap.add_argument("--all-tu", action="store_true",
                    help="scan ALL translation units (not only self-registering NAPI files)")
    ap.add_argument("--direct", action="store_true",
                    help="also report direct-init `Type name(args);` candidates (manual confirm required)")
    ap.add_argument("--callback", default=None,
                    help="类别1 残留扫描附加回调名（跨文件注册时点名核查，需配合 --all-tu）")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--root", default=None)
    ap.add_argument("--crosscheck", action="store_true", help="cross-file same-name reference scan (slow)")
    args = ap.parse_args()

    if not os.path.exists(args.target):
        print("❌ 路径不存在：%s" % args.target, file=sys.stderr)
        sys.exit(1)

    # 可选：直接初始化候选（默认关——与函数原型无法机械区分）
    all_candidates = []
    cat1_candidates = []
    cat1_unavailable = False
    n_files = 0
    n_napi = 0
    for f in iter_files(args.target, args.all):
        n_files += 1
        try:
            src = open(f, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        if NAPI_ANCHOR_RE.search(src):
            n_napi += 1
        if not args.all_tu and not NAPI_ANCHOR_RE.search(src):
            continue
        all_candidates.extend(scan_one_file(f))
        if NAPI_ANCHOR_RE.search(src) or args.callback:
            cat1_res, cat1_warn = scan_cat1_residual(f, args.callback)
            if cat1_warn:
                cat1_unavailable = True
            cat1_candidates.extend(cat1_res)

    if not args.direct:
        all_candidates = [c for c in all_candidates if c["form"] != "A-direct"]

    # 跨文件引用
    if args.crosscheck and args.root:
        for c in all_candidates:
            var_re = re.compile(r"\b%s\b" % re.escape(c["var"]))
            hits = []
            for f2 in iter_files(args.root, True):
                if os.path.abspath(f2) == os.path.abspath(c["file"]):
                    continue
                try:
                    with open(f2, encoding="utf-8", errors="replace") as fh:
                        s2 = fh.read()
                except OSError:
                    continue
                if var_re.search(s2):
                    hits.append(f2)
            if hits:
                c["warnings"].append("其他文件存在同名引用：%s" % ", ".join(hits[:5]))

    for c in all_candidates:
        ctx = build_flags_context(c["file"])
        c["build_ctx"] = ctx
        if c["form"] == "B":
            c["strategy"] = "call_once"          # 引擎规则：形态B 固定 call_once
        else:
            c["strategy"] = "call_once" if (ctx and ctx["no_threadsafe_statics"]) else "meyers"

    if args.json:
        print(json.dumps(all_candidates + cat1_candidates, ensure_ascii=False, indent=1))
        return

    n_a = sum(1 for c in all_candidates if c["form"] == "A")
    n_b = sum(1 for c in all_candidates if c["form"] == "B")
    print("## 整改回归验证 — 残留候选扫描（目标：清零）")
    print()
    print("- 扫描 C/C++ 文件：%d 个（含 NAPI 注册要素：%d 个）" % (n_files, n_napi))
    print("- 残留候选：%d 个（形态A × %d、形态B × %d、类别1 × %d）"
          % (len(all_candidates) + len(cat1_candidates), n_a, n_b, len(cat1_candidates)))
    if cat1_unavailable:
        print("- ⚠️ 类别1 残留扫描不可用（apply_init_extraction.py 缺失）——仅完成类别2 复验")
    print()
    if not all_candidates and not cat1_candidates:
        print("✅ 回归通过：目标范围内无「NAPI 加载期副作用」残留候选"
              "（类别2 全局单例 + 类别1 注册回调业务初始化）。")
        print()
        print("后续：模块级编译验证（GN ninja 目标 / hvigorw / build.sh）＋运行期验证"
              "（类别1 条目须完成 ArkTS 侧 init() 集成并首用前调用）。")
        return 0
    print("❌ 回归未通过：仍有 %d 个候选命中（见下表）——继续整改后复验。"
          % (len(all_candidates) + len(cat1_candidates)))
    print()
    if cat1_candidates:
        print("### 类别1 残留（注册回调内业务初始化语句 → 引擎 E）")
        print()
        print("| # | 文件 | 行 | 回调 | 语句 | 依据 |")
        print("|---|---|---|---|---|---|")
        for i, c in enumerate(cat1_candidates, 1):
            print("| %d | %s | %d | `%s` | `%s` | %s |"
                  % (i, c["file"], c["line"], c["callback"],
                     c["stmt"].replace("|", "\\|"), c["note"]))
        print()
        print("整改命令：")
        print("  python3 apply_init_extraction.py <文件> --at-line <行>   # dry-run 预览")
        print("  python3 apply_init_extraction.py <文件> --at-line <行> --apply  # 写入")
        print()
    if all_candidates:
        print("### 类别2 残留（全局单例即时初始化 → 引擎 L）")
        print()
    print("| # | 文件 | 行 | 变量 | 形态 | 初始化 | 使用点 | 写入点 | 判空点 | 建议策略 | 告警 |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for i, c in enumerate(all_candidates, 1):
        warn = "⚠️ " + "；".join(c["warnings"]) if c["warnings"] else "—"
        init_short = (c["init"][:56] + "…") if len(c["init"]) > 56 else c["init"]
        print("| %d | %s | %d | `%s` | %s | `%s` | %d | %d | %d | %s | %s |"
              % (i, c["file"], c["line"], c["var"], c["form"], init_short,
                 len(c["reads"]), len(c["writes"]), len(c["nullchecks"]),
                 c["strategy"], warn))
    print()
    print("### 类别2 详情")
    for i, c in enumerate(all_candidates, 1):
        print("\n#### #%d %s:%d — `%s`（形态%s）" % (i, c["file"], c["line"], c["var"], c["form"]))
        if c["notes"]:
            print("- %s" % c["notes"])
        if c["reads"]:
            print("- 使用点行号（前 20）：%s" % ", ".join(map(str, c["reads"][:20])))
        if c["build_ctx"]:
            print("- BUILD.gn：%s（-fno-threadsafe-statics: %s）"
                  % (c["build_ctx"]["build_gn"], c["build_ctx"]["no_threadsafe_statics"]))
    print()
    print("### 下一步（类别2 残留候选逐条整改）")
    print("  python3 apply_lazy_init.py <文件> --var <变量名> [--root <仓库根>]   # dry-run 预览")
    print("  python3 apply_lazy_init.py <文件> --var <变量名> --apply            # 确认后写入")
    print("告警非空的候选：先人工核实告警项（多写入点/取地址/跨文件引用）再决定是否改写。")
    print("整改后重跑本脚本复验，直至清零。")
    return 1


if __name__ == "__main__":
    sys.exit(main() or 0)
