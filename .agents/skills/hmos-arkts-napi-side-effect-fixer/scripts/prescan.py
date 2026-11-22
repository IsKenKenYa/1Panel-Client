#!/usr/bin/env python3
"""hmos-arkts-napi-side-effect-checker prescan.

单次调用完成漏斗第 1-2 级 + 注册点解析 + 回调定位 + 函数体提取，
替代「手工 grep 序列 + extract_register_chain.py -R 全仓提取」组合。

Usage:
  python3 prescan.py <path> [--all] [--safety-net] [--no-bodies] [--max-body N]
                      [--deep] [--chain-depth N]

  <path>        : directory or a single C/C++ file (.cpp/.cc/.cxx/.c)
  --all         : also scan test/example/sample directories (excluded by default)
  --safety-net  : include P4 (indented static/inline) safety-net hits (default off,
                  per rulebook §4.3 M-13)
  --no-bodies   : omit constructor/callback bodies (compact worklist only)
  --max-body N  : max chars per extracted body (default 3000)
  --deep        : also emit the deep-analysis work pack — mechanical L1/L2(+
                  --chain-depth) call-chain expansion + category-1 signal scan
                  over all chain code + form-B candidate pre-collection +
                  form-A initializer body location. Clean chains compress to a
                  single line; the agent only semantically reviews the hits
                  (this replaces the per-file read/grep loop of SKILL step 2).
  --chain-depth : callee expansion depth for --deep. Default "auto": expand
                  level by level until the frontier is exhausted (natural
                  saturation) or the auto cap (4) is hit; the run report then
                  states whether depth saturated naturally (✅) or hit the cap
                  with hits still appearing at the deepest level (⚠️ with the
                  hit-class composition — low-priority classes like param
                  reads converge, business classes warrant a deeper rescan).
                  An explicit integer (1-8) sets a hard limit.

What it does (funnel stages 1-2 + mechanical part of deep analysis; semantic
judgement stays with the agent, see SKILL.md and references/rulebook.md):
  1. Path filter: keep .cpp/.cc/.cxx/.c; skip test/tests/example/examples/
     sample/samples directory segments unless --all; skip hidden dirs.
  2. Register-chain elements (incl. variant registration points):
     constructor / napi_module_register / napi_module / nm_register_func /
     NAPI_MODULE macro / napi_module_with_js_register / NativeModuleManager::Register
  3. Form-A dynamic-init signals (v7.1 column-anchored):
     P1 decl `= new/call(...)`  P2 direct-init `Type name(args);`
     P3 out-of-class member def  P4 indented static/inline safety net (--safety-net)
    P1ns/P2ns indented namespace-scope globals (depth-aware ns-region harvest)
     with exclusion pipe (using/typedef/extern | unevaluated ops | void prototypes)
  4. Registration-point parsing: nm_modname / nm_register_func callbacks /
     NAPI_MODULE macro callbacks / constructor names.
  5. Callback resolution: same file -> cross chain file -> UNRESOLVED
     (with bounded body extraction; UNRESOLVED must be handled manually or via
     extract_register_chain.py -R / include-follow, never silently dropped).
  6. Funnel + callback-level counts for the double-invariant progress check.

Output: markdown on stdout. Exit code 0 normally, 1 on bad path.
"""
import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_register_chain import (  # noqa: E402
    mask_source, find_function_def, extract_span, match_balanced,
)

EXCLUDE_DIRS = {"test", "tests", "example", "examples", "sample", "samples"}
SUFFIXES = (".cpp", ".cc", ".cxx", ".c")

# ---- register-chain elements (rulebook §4.2 注册链要素) ----
CHAIN_ELEMENTS = [
    ("constructor", re.compile(r'__attribute__\s*\(\(\s*constructor\s*\)\)')),
    # 注册点要素（三词形，方案A5 2026-10-28 概念合并 M-05~M-07）：同一注册点
    # 的三个症状词形——调用点/结构体/回调字段（可拆分在不同文件或头文件），
    # 检测行为等价于原三条独立正则（alternation 内 register 先于 module，
    # 且 \b 词边界使 napi_module 不会命中 napi_module_register 的前缀）
    ("注册点", re.compile(r'\b(napi_module_register|napi_module|nm_register_func)\b')),
    ("NAPI_MODULE宏", re.compile(r'\bNAPI_MODULE\w*\s*\(')),
    ("napi_module_with_js_register", re.compile(r'\bnapi_module_with_js_register\b')),
    ("NativeModuleManager::Register",
     re.compile(r'\bNativeModuleManager\s*::\s*Register\b')),
]
VARIANT_ELEMENTS = {"napi_module_with_js_register", "NativeModuleManager::Register"}

# ---- form-A dynamic-init signals (v7.1 column-anchored, per-line) ----
_INIT = (r'(new\s+\w+(::\w+)*(\s*<[^();=]*>)?\s*[([]'
         r'|\(?\s*\w+(::\w+)*(\s*<[^();=]*>)?\s*\()')
P1 = re.compile(
    r'^((static|inline|const|volatile)\s+)*\w+(::\w+)*(<[^();=]*>)?'
    r'(\*+\s*|&+\s*|\s+)\w+\s*=\s*' + _INIT)
P2 = re.compile(
    r'^(static\s+)?([A-Za-z_][A-Za-z0-9_:<>]*\s+)*[A-Za-z_][A-Za-z0-9_:<>]*\s+'
    r'[a-z_]\w*\s*\([^;={}]*\)\s*;')
P3 = re.compile(
    r'^[A-Za-z_]\w*(::\w+)*(<[^();=]*>)?(\*+\s*|&+\s*|\s+)\w+::\w+\s*=\s*' + _INIT)
P4 = re.compile(
    r'^\s+(static\s+|inline\s+)+(const\s+|volatile\s+)*\w+(::\w+)*(<[^();=]*>)?'
    r'(\s*[*]+\s*|\s*[&]+\s*|\s+)\w+\s*=\s*' + _INIT)
EXCL = re.compile(
    r'^(using|typedef|extern)\b'
    r'|=\s*(sizeof|alignof|offsetof|decltype|noexcept)\s*\('
    r'|^(static\s+|inline\s+)*void\s+[a-z_]\w*\s*\(')
SIGNALS = [("P1", P1), ("P2", P2), ("P3", P3)]

# ---- P2-proto prototype pre-exclusion (rulebook §4.3 M-25 P2-proto 原型预剔除) ----
# 理论依据：合法 C++ 表达式的单个实参段内不可能出现裸「词 空格 词」（操作数
# 之间必须有运算符）——「类型 空格 名」只能是形参声明形态。保守条件：参数段
# 含 ( )"'}{=<>（嵌套/字面量/默认值/模板逗号切分破坏）、空参/void/单词参数
# （most vexing parse 不可解）、* / & 未贴附一侧（空格双侧 = 乘法与形参同形）
# → 一律不判，保留候选由语义层裁决。
P2_PROTO_SEG_A = re.compile(           # Type name / Type *name / Type &name
    r'^\s*(?:const\s+|volatile\s+)*(?:[A-Za-z_][\w:<>]*\s+)+[*&]*[a-z_]\w*$')
P2_PROTO_SEG_B = re.compile(           # Type* name / Type& name
    r'^\s*(?:const\s+|volatile\s+)*(?:[A-Za-z_][\w:<>]*\s+)*'
    r'[A-Za-z_][\w:<>]*[*&]+\s+[a-z_]\w*$')
P2_ARGS_RE = re.compile(r'\(([^;=()]*)\)\s*;')


def p2_proto_suspect(line):
    """P2 hit whose every arg segment is a named-parameter form -> prototype."""
    m = P2_ARGS_RE.search(line)
    if not m:
        return False
    args = m.group(1).strip()
    if not args or args == 'void':
        return False
    segs = args.split(',')
    if any(ch in s for s in segs for ch in '()"\'{}=<>'):
        return False
    return all(P2_PROTO_SEG_A.match(s) or P2_PROTO_SEG_B.match(s)
               for s in segs)


# ---- form-A ns-region signals（rulebook §4.3 M-26 形态A ns 区域缩进信号，
# ---- 2026-10-29 已知漏检第 7 项修复）：缩进的命名空间作用域全局。匿名
# ---- namespace 内容常缩进（实测 resourceschedule 9 处/8 文件，含与列首
#---- 版同型的 SELF_REGISTER 因缩进从未进报告），列首锚定的 P1/P2 对其
# ---- 不可见；P4 仅兜 static/inline。与 P1/P2 按「是否缩进」分界：顶格
# ---- ns 内容仍由 P1/P2 覆盖（^ 锚定不感知 ns 上下文）——两网不相交、
# ---- 并集完整，增量设计零回归风险。
# ---- 深度语义：①ns 内容层（花括号深度 == 开区深度+1）精确排除 ns 内
# ---- 函数体（缩进局部变量不淹候选）；②行内含花括号排除单行函数体；
# ---- ③宏续行（行尾 \ 的 # 指令延续）对深度记账与收割均不可见（实测：
# ---- app_mgr_service_inner.cpp 的 CHECK_IS_SA_CALL 宏体曾伪命中）。
# ---- 残余漏检（rulebook §4.3 M-26 已知边界同步）：单行 ns 块、同行嵌套
# ---- 开区（namespace a { namespace b {）、带属性 ns。
NS_OPEN_RE = re.compile(
    r'^(?:inline\s+)?namespace(?:\s+([\w:]+))?\s*(\{)?\s*$')
NS_ANY_OPEN = re.compile(                   # 廉价预门：无 ns 开区即整文件跳过
    r'(?:^|\n)[ \t]*(?:inline[ \t]+)?namespace\b')
NS_TYPE = r'[A-Za-z_]\w*(?:::\w+)*(?:\s*<[^;=()]*>)?'
NS_SEP = r'(?:\*+\s*|&+\s*|\s+)'
NS_INIT = r'(?:new\s+\w+|[A-Za-z_]\w*(?:::\w+)*(?:<[^;]*>)?\s*\()'
NS_P1_RE = re.compile(                    # ns 内容层缩进 = new/调用初始化
    r'^\s+(?:(?:const|inline|volatile)\s+)*(?:%s%s)+[A-Za-z_]\w*\s*=\s*%s'
    % (NS_TYPE, NS_SEP, NS_INIT))
NS_P2_RE = re.compile(                    # ns 内容层缩进直接初始化
    r'^\s+(?:(?:const|inline|volatile)\s+)*(?:%s%s)+[A-Za-z_]\w*'
    r'\s*\([^;={}]*\)\s*;' % (NS_TYPE, NS_SEP))
NS_BAD_KW = re.compile(                   # 语句/静态初始化关键词 + void 原型
    r'\b(if|for|while|switch|return|sizeof|constexpr|constinit|using|'
    r'typedef|namespace|class|struct|enum)\b'
    r'|^\s*void\s+[A-Za-z_]\w*\s*\(')


def harvest_ns_globals(mlines, rlines):
    """([(sig, line, text)], [(sig, line, text)]) — P1ns/P2ns 候选与原型
    疑例。mlines 为 mask_source 后的行（注释/字符串中性化，保长保换行），
    rlines 为原文行（候选文本用原文）。"""
    hits, protos = [], []
    depth, ns_stack, pending, in_pp = 0, [], None, False
    for i, mln in enumerate(mlines, 1):
        s = mln.strip()
        if in_pp or s.startswith("#"):    # 宏指令/续行：不可见
            in_pp = mln.rstrip().endswith("\\")
            continue
        in_pp = False
        if not s:
            continue
        if pending is not None:           # 上一行裸 namespace，本行等 '{'
            named = pending
            pending = None
            if s.startswith("{"):
                ns_stack.append([depth, named])   # '{' 由通用记账计数
        m = NS_OPEN_RE.match(s)
        if m:
            if m.group(2):                # 同行 '{'（具名/匿名由 group(1) 定）
                ns_stack.append([depth, bool(m.group(1))])
            elif m.group(1) is not None or s.rstrip().endswith("namespace"):
                pending = bool(m.group(1))  # 跨行 '{'：下行确认
        depth += mln.count("{") - mln.count("}")
        while ns_stack and depth <= ns_stack[-1][0]:
            ns_stack.pop()                # 深度回落 → 闭区
        if not (ns_stack and depth == ns_stack[-1][0] + 1):
            continue
        if mln[:1] not in (" ", "\t") or "{" in mln or "}" in mln:
            continue
        for sig, rex in (("P1ns", NS_P1_RE), ("P2ns", NS_P2_RE)):
            if not rex.match(mln):
                continue
            if NS_BAD_KW.search(mln) or EXCL.search(mln):
                break
            if sig == "P2ns" and p2_proto_suspect(mln):
                protos.append((sig, i, rlines[i - 1].strip()))
            else:
                hits.append((sig, i, rlines[i - 1].strip()))
            break
    return hits, protos


# ---- form-B lexical symbol table（方案A8）：per-file 词法表 + 头文件表。
# ---- 深析期按需构建（仅链节点文件），按路径缓存；共享 ns 状态机的
# ---- pp续行/花括号深度/开区语义（独立遍历——scan_file 的 P1ns/P2ns 信号
# ---- 收割不受影响）。列首行按格式约定视为声明位（与 P1/P2 同精度假设），
#---- 违规列首语句由 R3 在路由期消化。----
_file_table_cache = {}
_hdr_table_cache = {}


def build_symbol_table(src):
    """{name: [(line, tag)]}——本文件词法可见的文件/ns 作用域声明。
    tag ∈ file/ns/member/extern（路由只判命中与否，tag 供定义行展示）。"""
    mlines = mask_source(src).split("\n")
    table = {}

    def add(name, line, tag):
        table.setdefault(name, []).append((line, tag))

    depth, ns_stack, pending, in_pp = 0, [], None, False
    for i, mln in enumerate(mlines, 1):
        s = mln.strip()
        if in_pp or s.startswith("#"):
            in_pp = mln.rstrip().endswith("\\")
            continue
        in_pp = False
        if not s:
            continue
        if pending is not None:
            named = pending
            pending = None
            if s.startswith("{"):
                ns_stack.append([depth, named])
        m = NS_OPEN_RE.match(s)
        if m:
            if m.group(2):
                ns_stack.append([depth, bool(m.group(1))])
            elif m.group(1) is not None or s.endswith("namespace"):
                pending = bool(m.group(1))
        depth += mln.count("{") - mln.count("}")
        while ns_stack and depth <= ns_stack[-1][0]:
            ns_stack.pop()
        in_ns = bool(ns_stack and depth == ns_stack[-1][0] + 1)
        if mln[:1] in (" ", "\t"):
            # ns 内容层缩进声明（顶格 ns 内容由列首 DECL 收——按缩进分界）
            if in_ns and "{" not in mln and "}" not in mln \
                    and not TB_SKIP_RE.match(s):
                m2 = TB_NS_DECL_RE.match(mln)
                if m2:
                    tag = ("extern" if re.search(r'\bextern\b', mln[:m2.start(1)])
                           else "ns")
                    add(m2.group(1), i, tag)
                    rest = mln[m2.end():]
                    if not rest.startswith("("):
                        for mm in TB_MULTI_RE.finditer(rest):
                            add(mm.group(1), i, tag)
            continue
        # 列首行：类外静态成员定义优先，其次普通声明（+多声明符）
        if TB_SKIP_RE.search(s):
            continue
        mq = TB_QUAL_DECL_RE.match(mln)
        if mq:
            add(mq.group(1).rsplit("::", 1)[-1], i, "member")
            continue
        m3 = TB_DECL_RE.match(mln)
        if m3 and m3.group(1) not in ("if", "for", "while", "switch",
                                      "sizeof", "return", "else"):
            pre = mln[:m3.start(1)]
            tag = ("extern" if re.search(r'\bextern\b', pre)
                   else ("ns" if in_ns else "file"))
            add(m3.group(1), i, tag)
            rest = mln[m3.end():]
            if not rest.startswith("("):
                for mm in TB_MULTI_RE.finditer(rest):
                    add(mm.group(1), i, tag)
    return table


def file_table(info):
    t = _file_table_cache.get(info["path"])
    if t is None:
        t = build_symbol_table(info["src"])
        _file_table_cache[info["path"]] = t
    return t


def header_table(hpath):
    t = _hdr_table_cache.get(hpath)
    if t is None:
        try:
            with open(hpath, "r", encoding="utf-8", errors="replace") as fh:
                src = fh.read()
        except OSError:
            src = ""
        t = build_symbol_table(src) if src else {}
        _hdr_table_cache[hpath] = t
    return t


def header_lookup(info, name, hdr_index, cache):
    """R2h：本文件直接 `#include \"...\"` 的头文件表查名（限深 1——间接
    包含的头文件全局落 R4 兜底）。解析顺序同 _follow_header_fields：同目录
    → ../include → ../../include → 全树唯一 basename（歧义即跳过）。"""
    key = (info["path"], name)
    if key in cache:
        return cache[key]
    r = None
    base = os.path.dirname(info["path"])
    for ln in info["src"].split("\n"):
        m = INC_RE.match(ln)
        if not m:
            continue
        inc = m.group(1)
        resolved = None
        for cand in (os.path.join(base, inc),
                     os.path.join(base, os.pardir, "include", inc),
                     os.path.join(base, os.pardir, os.pardir, "include", inc)):
            cand = os.path.normpath(cand)
            if os.path.isfile(cand):
                resolved = cand
                break
        if resolved is None and hdr_index:
            paths = hdr_index.get(os.path.basename(inc), [])
            if len(paths) == 1:
                resolved = paths[0]
        if resolved is None:
            continue
        entries = header_table(resolved).get(name)
        if entries:
            r = (resolved, entries[0][0])
            break
    cache[key] = r
    return r


# ---- deep work-pack (--deep): category-1 signal table, v2 two tiers (see
# ---- rulebook §4.5 M-19「CAT1 信号表」). 两层始终同时生效（合并单表
# ---- 扫描，无按仓门控）——分层为声明性归类。通用层词形跨域成立；OHOS
# ---- 域层为系统仓习语：三方应用仓真阳性预期为零（inner kit 不在 NDK
# ---- sysroot），词形通用成员可误报（语义复核剔除）。hits need SEMANTIC
# ---- review.
# ---- 2026-10-27 规则审查修订（方案A，F-1/F-2）：删 samgr 裸词（域内 0
# ---- 命中死重）；补 SendRequest/MessageParcel 发送型 IPC；SetLeakObserver
# ---- 单仓字面量泛化为注册动词族。
# ---- 2026-10-27 方案A2：通用层补机制原语——连接建立补 socket/getaddrinfo
# ----（connect 仅覆盖已建 fd 的连接动作，缺网络准备阶段）；进程级回调注册
# ---- 补 atexit（POSIX 进程退出钩子，与 signal 同族）；新增环境变量条目
# ---- getenv/setenv/putenv（应用侧配置读取主要词法形态，写 env 亦为进程
# ---- 级状态变更）。bind/listen 不补（std::bind 冲突＋加载期罕见）。----
CAT1_SIGNALS_GENERIC = [
    ("线程创建", re.compile(
        r'\b(pthread_create|std::thread|CreateThread)\b|\bdetach\s*\(')),
    ("动态库加载", re.compile(r'\b(dlopen|dlsym)\b')),
    ("文件IO", re.compile(r'\b(fopen|ifstream|ofstream)\b|\bopen\s*\(')),
    ("环境变量", re.compile(r'\b(getenv|setenv|putenv)\s*\(')),
    ("连接建立", re.compile(
        r'\b(connect|socket|getaddrinfo|sqlite3_open)\s*\(|\bDatabase\s*\(')),
    ("信号处理器", re.compile(r'\b(signal|sigaction)\s*\(|\bSIG[A-Z]{2,}\b')),
    ("事件循环attach", re.compile(
        r'\bEventHandler\b|\bevent_loop\b|attach_\w*handler')),
    ("进程级回调注册", re.compile(
        r'\bnapi_set_promise_rejection_callback\b'
        r'|\b(Register|Set|Add|Subscribe|Attach)\w*'
        r'(Callback|Listener|Observer|Handler)\s*\('
        r'|\batexit\s*\(')),
    ("call_once块", re.compile(r'\bstd::call_once\b')),
]
CAT1_SIGNALS_OHOS = [
    ("外部服务/IPC", re.compile(
        r'\b(SystemAbilityManagerClient|GetSystemAbility|iface_cast'
        r'|SendRequest|MessageParcel)\b')),
    # 服务客户端：域内零收益（ability 2151 文件 0 命中），候选删除（F-3）
    ("服务客户端", re.compile(r'\b(DataShare|BundleMgr|NetConn)\b')),
    # 系统参数读取：链上零命中；参数读取单列已移除（2026-10-29）——命中产出
    # 普通候选（外部符号→待确认）；信号删除候选（F-4）待决
    ("系统参数读取", re.compile(r'\bsystem::Get\w*Parameter\s*\(')),
    ("应用上下文", re.compile(
        r'\bGetApplicationContext\b|\bCreateModuleResourceManager\b')),
]
CAT1_SIGNALS = CAT1_SIGNALS_GENERIC + CAT1_SIGNALS_OHOS
EXPORTS_MARK = re.compile(
    r'\bnapi_(property_descriptor|create_function|define_class|'
    r'set_named_property|wrap|get_cb_info|create_object|define_properties)\b'
    r'|\bDECLARE_NAPI\w*\b')
# free-function-looking call (not obj.method( / p->method(), allow NS::f(
# group(1) = optional qualifier chain incl. trailing "::", group(2) = name
CALLEE_RE = re.compile(r'(?<![.\w>])((?:[A-Za-z_]\w*::)+)?([A-Za-z_]\w*)\s*\(')
# method calls (obj.m( / p->m() — 方案A9 default FULL expansion: the old
# lifecycle-name whitelist (kept below as METHOD_EXPAND_LIFECYCLE for
# --strict-expand) proved near-inert on real data (+6% nodes only — CALLEE_SKIP
# is the real noise gate) while hiding app-repo chains with non-conventional
# names; full expansion ships with same-name disambiguation annotations
# (resolve_callee candidate counts) so guesses are visible, not silent.
METHOD_CALLEE_RE = re.compile(r'(?:\.|->)\s*([A-Za-z_]\w*)\s*\(')
METHOD_EXPAND_LIFECYCLE = re.compile(
    r'^(Load|Init|Create|Start|Setup|Register|Open|Connect|Prepare|Warm|'
    r'Preload|Initialize|Deinit|Shutdown|Attach|Enable|Subscribe)[A-Z_]')
METHOD_EXPAND_RE = re.compile(r'')   # 全匹配；main() 中 --strict-expand 换回白名单
CALLEE_SKIP = re.compile(
    r'^(if|for|while|switch|return|sizeof|alignof|decltype|assert|'
    r'napi_\w+|NAPI_\w+|HILOG\w*|TAG_\w+|DECLARE_\w+|__\w+|std|'
    r'make_shared|make_unique|make_pair|make_tuple|move|forward|bind|'
    r'to_string|stoi|stol|static_cast|dynamic_cast|const_cast|reinterpret_cast|'
    r'begin|end|size|data|empty|c_str|length|at|get|insert|push_back|emplace|'
    r'erase|clear|count|find|swap|exit|abort|printf|sprintf|snprintf|memset|'
    r'memcpy|strlen|strcpy|min|max|abs)$')
# ---- form-B assignment matching（2026-10-29 方案A8：**废弃 [gs]_ 前缀正则
# ---- FORMB_RE**——命名风格是约定非事实，前缀不匹配即静默漏（实测：instance_
# ---- 类静态成员赋值零可见；obj.g_x= 成员赋值反误命中）。链内全局赋值改由
# ---- **词法符号表判定**（route_global_assignments 四路路由）：作用域是语言
# ---- 事实，表查不到降级 R4 低置信候选，失败方向安全。g_/s_ 前缀降为 R4 内
# ---- 排序标注（命名先验），不参与路由。规则全文见 rulebook §4.5 M-24。----
HEAVY_RHS = r'(?:new\s+\w+|[A-Za-z_]\w*(?:::\w+)*(?:<[^;]*>)?\s*\()'
QUAL_ASSIGN_RE = re.compile(     # R1：限定名赋值（语言规则恒真——非函数局部）
    r'\b([A-Za-z_]\w*(?:::\w+)+)\s*(?:\[[^\]]*\])*\s*=(?!=)\s*' + HEAVY_RHS)
SIMPLE_ASSIGN_RE = re.compile(  # 简单名+可选数组下标+重形态 RHS；负向后行
    # 排除 obj.m=/p->m= 成员赋值（FORMB_RE 现存误报）与限定名（R1 已收）
    r'(?<![.\w>:])([A-Za-z_]\w*)\s*(?:\[[^\]]*\])*\s*=(?!=)\s*' + HEAVY_RHS)
# ---- per-file 词法表收割正则（build_symbol_table；类型分隔符 P1 式——FILE*
# ---- 贴星教训）：列首声明（文件作用域+ns 顶格内容）/ ns 内容层缩进声明 /
# ---- 类外静态成员定义 / 多声明符逐段收名。花括号初始化声明不在终结符集
# ---- （表盲区 → R4 兜底，rulebook §4.5 M-24 已知边界）。----
TB_SKIP_RE = re.compile(
    r'^(using|typedef|namespace|class|template|return|delete|throw|goto|else'
    r'|do|try|case|new|sizeof|constexpr)\b|^extern\s*"')
TB_DECL_RE = re.compile(
    r'^(?:(?:static|inline|const|volatile|mutable|thread_local|constexpr'
    r'|constinit|unsigned|signed|long|short|struct|enum|extern)\s+)*'
    r'(?:[A-Za-z_]\w*(?:::\w+)*(?:\s*<[^;=()]*>)?(?:\*+\s*|&+\s*|\s+))+'
    r'([A-Za-z_]\w*)\s*(?=\[|=|;|\()')
TB_QUAL_DECL_RE = re.compile(    # 类外静态成员定义（函数定义/原型经 (?=[=;\[])
    r'^(?:(?:static|const|inline|volatile|constexpr|extern)\s+)*'
    r'[A-Za-z_]\w*(?:::\w+)*(?:\s*<[^;=()]*>)?(?:\*+\s*|&+\s*|\s+)'
    r'([A-Za-z_]\w*(?:::\w+)+)\s*(?=[=;\[])')
TB_NS_DECL_RE = re.compile(
    r'^\s+(?:(?:static|inline|const|volatile|mutable|thread_local|constexpr'
    r'|constinit|unsigned|signed|long|short|struct|enum|extern)\s+)*'
    r'(?:[A-Za-z_]\w*(?:::\w+)*(?:\s*<[^;=()]*>)?(?:\*+\s*|&+\s*|\s+))+'
    r'([A-Za-z_]\w*)\s*(?=\[|=|;|\()')
TB_MULTI_RE = re.compile(r',\s*[*&\s]*([A-Za-z_]\w*)\s*(?==|;|\[|\()')
# ---- R3 局部排除（先于查表——C++ 内层遮蔽外层）：起点锚+语句关键字负向
# ---- 前瞻+限定符+类型形 token+名字+声明终结符。前瞻防 return x; 被解析为
# ---- 声明（实测曾致 instance_ 盲区候选被误排除——强制项②）。----
LOCAL_DECL_HEAD = re.compile(
    r'(?:[(;,{}]\s*|\n)\s*'
    r'(?!(?:return|co_return|throw|delete|goto|break|continue|else|case'
    r'|default|do|new|sizeof|typedef|using)\b)'
    r'(?:const\s+|static\s+|constexpr\s+|auto\s+|typename\s+)*'
    r'(?:[A-Za-z_]\w*(?:::\w+)*(?:\s*<[^;=()]*>)?[*&\s]*\s+)+')

# budgets for --deep expansion: SCAN cap bounds extraction fidelity (signal
# scan + callee extraction run on the FULL body — truncating here loses both);
# RENDER caps only bound what is printed per node level.
DEEP_SCAN_CAP = 8000
DEEP_RENDER_CAPS = (2400, 1600, 1200, 800)  # per level L0..L3 (render only)
DEEP_CALLEE_CAPS = (30, 20, 12)             # per node, per level L1..L3
DEEP_MAX_NODES = 2000                       # total extracted bodies per run
AUTO_DEPTH_CAP = 4                          # --chain-depth auto 时的层数上限

# ---- registration-point parsing ----
RE_MODNAME = re.compile(r'\.nm_modname\s*=\s*"([^"]*)"')
RE_MODNAME_IDENT = re.compile(r'\.nm_modname\s*=\s*([A-Za-z_]\w*)')   # 常量形式（方案A8）
RE_FIELD_CB = re.compile(r'\.nm_register_func\s*=\s*&?\s*([A-Za-z_][\w:]*)')
RE_MACRO_CB = re.compile(
    r'\bNAPI_MODULE\w*\s*\(\s*([\w."\']+?)\s*,\s*&?\s*([A-Za-z_][\w:]*)')
RE_CTOR_NAME = re.compile(
    r'__attribute__\s*\(\(\s*constructor\s*\)\)[^;{}]*?([A-Za-z_]\w*)\s*\(')
RE_NATIVE_NAME = re.compile(r'\.name\s*=\s*"([^"]*)"')   # 变体注册模块名（方案A8）


def collect_files(root, include_all):
    kept, skipped = [], 0
    if os.path.isfile(root):
        if root.endswith(SUFFIXES):
            kept.append(root)
        return kept, skipped
    for dirpath, dirnames, filenames in os.walk(root):
        keep_dirs, drop_dirs = [], []
        for d in sorted(dirnames):
            if d.startswith("."):
                drop_dirs.append(d)
            elif not include_all and d.lower() in EXCLUDE_DIRS:
                drop_dirs.append(d)
            else:
                keep_dirs.append(d)
        for d in drop_dirs:
            if d.lower() in EXCLUDE_DIRS:
                for _dp, _dn, fns in os.walk(os.path.join(dirpath, d)):
                    skipped += sum(1 for f in fns if f.endswith(SUFFIXES))
        dirnames[:] = keep_dirs
        for fn in sorted(filenames):
            if fn.endswith(SUFFIXES):
                kept.append(os.path.join(dirpath, fn))
    return kept, skipped


def mask_quotes(line):
    """M-04（rulebook §4.2 引号内不命中预处理）：把字符串/字符字面量整段
    替换为等长空格——引号内内容不参与要素/信号匹配（idl_tool 代码生成器输出
    "__attribute__((constructor)) ..." 字面量曾误命中 constructor 要素并伪解
    析出 ctor 名）。等长替换保持 P1-P4 的列首锚定；未闭合字面量遮蔽至行尾。"""
    out = list(line)
    i, n = 0, len(line)
    while i < n:
        ch = line[i]
        if ch == '"' or ch == "'":
            j = i + 1
            while j < n:
                if line[j] == '\\':
                    j += 2              # skip escaped char (\" \' \\ ...)
                    continue
                if line[j] == ch:
                    break
                j += 1
            end = j if j < n else n - 1  # unterminated -> mask to EOL
            for k in range(i, end + 1):
                out[k] = ' '
            i = end + 1
        else:
            i += 1
    return ''.join(out)


INC_RE = re.compile(r'^\s*#\s*include\s*"([^"]+)"')


def build_header_index(root):
    """include-follow 兜底索引：扫描树内全部头文件按 basename 建索引（目录
    排除规则同 collect_files）；仅 basename 全树唯一时用于解析（歧义即跳过
    ——保守，防跨组件同名头文件误归因）。单文件输入返回空索引。"""
    index = {}
    if os.path.isfile(root):
        return index
    for dp, dns, fns in os.walk(root):
        dns[:] = [d for d in dns if not d.startswith(".")
                  and d.lower() not in EXCLUDE_DIRS]
        for fn in fns:
            if fn.endswith((".h", ".hpp")):
                index.setdefault(fn, []).append(os.path.join(dp, fn))
    return index


def _follow_header_fields(path, src, info, seen, hdr_index=None):
    """M-17 include-follow（注册点字段，方案A5）：含注册点要素但本文件无
    .nm_register_func 时（napi_module 结构体定义在头文件、.cpp 仅 extern
    声明 + napi_module_register 调用），沿 #include "..." 解析头文件中的
    .nm_register_func / .nm_modname 字段。解析顺序：① 同级目录 / ../include
    / ../../include（OHOS GN include_dirs 惯例）；② 全树唯一 basename 兜底
    （头文件可位于远离 .cpp 的子树，如 interfaces/kits/*/include 而 .cpp 在
    frameworks/src——歧义即跳过）。限深 2；发现归因到包含方（头文件为解析
    对象，不进漏斗统计——M-01/M-17）。"""
    base = os.path.dirname(path)
    queue, visited, found = [], set(), False
    for ln in src.split("\n"):
        m = INC_RE.match(ln)
        if m:
            queue.append(m.group(1))
    for _hop in range(2):                  # include 深度上限 2
        nxt = []
        for inc in queue:
            resolved = None
            for cand in (os.path.join(base, inc),
                         os.path.join(base, os.pardir, "include", inc),
                         os.path.join(base, os.pardir, os.pardir, "include", inc)):
                cand = os.path.normpath(cand)
                if cand not in visited and os.path.isfile(cand):
                    resolved = cand
                    break
            if resolved is None and hdr_index:
                # ② 全树唯一 basename 兜底（歧义/已访问即跳过）
                paths = hdr_index.get(os.path.basename(inc), [])
                if len(paths) == 1 and paths[0] not in visited:
                    resolved = paths[0]
            if resolved is None:
                continue
            visited.add(resolved)
            try:
                with open(resolved, "r", encoding="utf-8",
                          errors="replace") as fh:
                    hsrc = fh.read()
            except OSError:
                continue
            hq = "\n".join(mask_quotes(l) for l in hsrc.split("\n"))
            for name in RE_FIELD_CB.findall(hq):
                if name not in seen and name != "nullptr":
                    seen.add(name)
                    info["cbs"].append(
                        (name, ".nm_register_func 字段(头文件 %s)"
                         % os.path.basename(resolved)))
                    found = True
            for mod in RE_MODNAME.findall(hsrc):
                if mod not in info["modnames"]:
                    info["modnames"].append(mod)
            for ln2 in hsrc.split("\n"):
                m2 = INC_RE.match(ln2)
                if m2:
                    nxt.append(m2.group(1))
        queue = nxt
        if found or not queue:
            break


def scan_file(path, hdr_index=None):
    """One read, all funnel patterns + registration parsing (mask deferred)."""
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        src = fh.read()
    info = {"path": path, "chain": {}, "init": [], "init_proto": [], "safety": [],
            "modnames": [], "cbs": [], "ctors": [], "src": src, "masked": None}

    def _masked():
        if info["masked"] is None:
            info["masked"] = mask_source(src)
        return info["masked"]

    info["_masked"] = _masked
    lines = src.split("\n")
    # M-04「引号内不命中」：要素/信号匹配一律在引号遮蔽行上进行（字面量整段
    # 置等长空格，保持 P1-P4 列首锚定）；报告展示与候选文本仍用原文
    qlines = [mask_quotes(ln) for ln in lines]
    for label, rex in CHAIN_ELEMENTS:
        hits = [i + 1 for i, ln in enumerate(qlines) if rex.search(ln)]
        if hits:
            info["chain"][label] = hits
    for i, ln in enumerate(lines):
        stripped = ln.strip()
        if stripped.startswith("//") or stripped.startswith("/*") \
                or stripped.startswith("*"):
            continue
        qln = qlines[i]
        for sig, rex in SIGNALS:
            if rex.match(qln) and not EXCL.search(qln):
                if sig == "P2" and p2_proto_suspect(qln):
                    # named-parameter form -> function prototype; pre-excluded
                    # from form-A candidates (kept in stats + own section
                    # for audit — never silently dropped)
                    info["init_proto"].append((sig, i + 1, stripped))
                else:
                    info["init"].append((sig, i + 1, stripped))
                break
        if P4.match(qln) and not EXCL.search(qln):
            info["safety"].append((i + 1, stripped))
    # 形态A ns 区域信号（P1ns/P2ns）：缩进的命名空间作用域全局。顶格 ns
    # 内容仍由上方 P1/P2 覆盖（^ 锚定不感知 ns 上下文）——两网按「是否
    # 缩进」分界，不相交、并集完整；P2ns 原型疑例走 init_proto 预剔除。
    # 预门：无 ns 开区的文件（.c / 无 ns 的 .cpp）跳过 mask_source 急切计算。
    if NS_ANY_OPEN.search(src):
        ns_hits, ns_protos = harvest_ns_globals(
            info["_masked"]().split("\n"), lines)
        if ns_hits or ns_protos:
            info["init"].extend(ns_hits)
            info["init_proto"].extend(ns_protos)
            info["init"].sort(key=lambda e: e[1])
            info["init_proto"].sort(key=lambda e: e[1])
    # 引号遮蔽文本用于无需引号的注册解析（防代码生成器字面量伪解析出
    # nm_register_func / ctor 名）；.nm_modname 与 NAPI_MODULE 宏解析需要
    # 引号内名称，仍用原文
    qsrc = "\n".join(qlines)
    info["modnames"] = list(RE_MODNAME.findall(src))
    # 宏/constexpr 常量形式的模块名（如 .nm_modname = HTTP_MODULE_NAME——
    # 方案A8 模块归属需要）：同文件内解析常量定义，未命中则忽略（#define
    # 形式不解析，保守跳过）
    for ident in RE_MODNAME_IDENT.findall(qsrc):
        m2 = re.search(r'\b%s\s*=\s*"([^"]*)"' % re.escape(ident), src)
        if m2 and m2.group(1) not in info["modnames"]:
            info["modnames"].append(m2.group(1))
    seen = set()
    field_cbs = RE_FIELD_CB.findall(qsrc)
    for name in field_cbs:
        if name not in seen and name != "nullptr":
            seen.add(name)
            info["cbs"].append((name, ".nm_register_func 字段"))
    for mod, cb in RE_MACRO_CB.findall(src):
        mod_clean = mod.strip('"')
        if mod_clean and mod_clean not in info["modnames"]:
            info["modnames"].append(mod_clean)
        if cb not in seen and cb != "nullptr":
            seen.add(cb)
            info["cbs"].append((cb, "NAPI_MODULE 宏(模块 %s)" % mod_clean))
    for name in RE_CTOR_NAME.findall(qsrc):
        if name not in info["ctors"]:
            info["ctors"].append(name)
    if "NativeModule" in src:
        # 方案A8：变体注册模块（JS 容器，无 nm_modname）以 NativeModule 的
        # .name 字段视同模块名（模块归属 T1 判定用）。门控用结构体类型名
        # 而非 NativeModuleManager::Register 要素——实际调用是对象形态
        # moduleManager->Register(...)，要素（限定形态）不命中
        for nm in RE_NATIVE_NAME.findall(src):
            if nm not in info["modnames"]:
                info["modnames"].append(nm)
    if not field_cbs and "注册点" in info["chain"]:
        # M-17 include-follow（注册点字段，方案A5）：本文件无 .nm_register_func
        # 而 napi_module 结构体定义在头文件——沿 #include "..." 解析字段，
        # 发现归因到包含方（头文件不进漏斗统计）
        _follow_header_fields(path, src, info, seen, hdr_index)
    return info


def body_of(info, name, max_body):
    d = find_function_def(info["_masked"](), name)
    if d is None:
        return None
    text, _, _ = extract_span(info["src"], info["_masked"](), d[0], d[2], max_body)
    return {"text": text, "info": info, "start": d[0], "end": d[2]}


def build_cb_index(infos, chain_infos):
    """One linear pass over ALL files: callback-tail -> [infos containing it].

    Registration callbacks are usually defined in implementation files that
    contain no register-chain element (module file registers, xxx_manager.cpp
    defines) — restricting the search to chain files loses them (the reason
    extract_register_chain.py needs -R over the whole tree). A single combined
    regex scan over every file keeps this linear instead of quadratic.
    """
    tails = set()
    for i in chain_infos:
        for name, _how in i["cbs"]:
            tails.add(name.rsplit("::", 1)[-1])
    index = {}
    if not tails:
        return index
    combined = re.compile(
        r'\b(%s)\s*\(' % "|".join(re.escape(t) for t in sorted(tails)))
    for i in infos:
        found = set(combined.findall(i["src"]))
        for t in found:
            index.setdefault(t, []).append(i)
    return index


def resolve_callback(cb_name, home_info, cb_index, max_body, cache):
    """same file -> indexed candidate files -> None (UNRESOLVED); cached."""
    key = (home_info["path"], cb_name)
    if key in cache:
        return cache[key]
    r = body_of(home_info, cb_name, max_body)
    if r:
        cache[key] = ("本文件", r)
        return cache[key]
    tail = cb_name.rsplit("::", 1)[-1]
    for other in cb_index.get(tail, []):
        if other is home_info:
            continue
        r = body_of(other, cb_name, max_body)
        if r:
            cache[key] = (other["path"], r)
            return cache[key]
    cache[key] = None
    return None


# ---------------- deep work-pack engine (--deep) ----------------

class DeepIndex:
    """Incremental tail->infos index over ALL scanned files.

    One combined-regex pass per batch of new names (linear in total source
    bytes), instead of per-candidate scans over every file.
    """

    def __init__(self, infos):
        self.infos = infos
        self.index = {}
        self._known = set()

    def extend(self, names):
        new = sorted({n for n in names
                      if n not in self._known and n and len(n) > 2})
        if not new:
            return
        self._known.update(new)
        combined = re.compile(
            r'\b(%s)\s*\(' % "|".join(map(re.escape, new)))
        for i in self.infos:
            for t in set(combined.findall(i["src"])):
                self.index.setdefault(t, []).append(i)


def extract_callees(body):
    """[(name, qualifier)] — qualifier like "LumeRenderConfig::" or ""."""
    out, seen = [], set()
    for m in CALLEE_RE.finditer(body):
        qual = m.group(1) or ""
        n = m.group(2)
        if CALLEE_SKIP.match(n):
            continue
        if n.upper() == n and "_" in n:      # ALL_CAPS macros
            continue
        key = (n, qual)
        if key not in seen:
            seen.add(key)
            out.append((n, qual))
    for m in METHOD_CALLEE_RE.finditer(body):
        n = m.group(1)
        if not METHOD_EXPAND_RE.match(n) or CALLEE_SKIP.match(n):
            continue
        if (n, "") in seen:
            continue
        seen.add((n, ""))
        out.append((n, ""))                  # lifecycle-style method expansion
    return out


def resolve_callee(name, qual, home, dindex, cache, max_body):
    """same file -> indexed candidates (qualifier-aware, path-proximity).
    Returns (info, body, same_name_n)：same_name_n = 跨文件同名候选文件数
    （方案A9 同名消歧标注——>1 表示本条边是"按目录邻近选取的猜测"，节点
    渲染时标注；限定名经全串过滤后剩 1 个候选或本文件定义 → 1，恒信）。"""
    key = (home["path"], name, qual)
    if key in cache:
        return cache[key]
    r = body_of(home, name, max_body)
    if r:
        cache[key] = (home, r, 1)          # 本文件定义：恒信
        return cache[key]
    cands = list(dindex.index.get(name, []))
    if cands and qual:
        full = qual + name                   # require "X::f" verbatim in src
        qualified = [i for i in cands if full in i["src"]]
        if qualified:
            cands = qualified
    if cands:
        nsn = len({i["path"] for i in cands})
        hdir = os.path.dirname(home["path"])
        cands.sort(key=lambda i: (0 if os.path.dirname(i["path"]) == hdir
                                  else 1, i["path"]))
        for other in cands:
            if other is home:
                continue
            r = body_of(other, name, max_body)
            if r:
                cache[key] = (other, r, nsn)
                return cache[key]
    cache[key] = None
    return None


def node_line(info, body_start, off):
    return info["src"].count("\n", 0, body_start + off) + 1


def scan_node_signals(info, text, body_start):
    """[(label, line, snippet, exports_flag)] over one node body."""
    hits = []
    for label, rex in CAT1_SIGNALS:
        for m in rex.finditer(text):
            ln = node_line(info, body_start, m.start())
            snippet = text[max(0, m.start() - 40):m.end() + 40]
            snippet = " ".join(snippet.split())
            hits.append((label, ln, snippet, bool(EXPORTS_MARK.search(
                text[max(0, m.start() - 60):m.end() + 60]))))
    return hits


def _is_local(masked_body, name):
    """R3：函数体/参数表内是否有 name 的声明（起点锚+关键字前瞻+类型形
    token+声明终结符）。失败方向不对称：漏检局部 → 落 R4 多一条候选（安全）；
    误判局部 → 真候选被静默排除（危险）——关键字前瞻清单为此存在。"""
    return bool(re.search(
        LOCAL_DECL_HEAD.pattern + r'\b%s\s*(?==|;|,|\)|\()' % re.escape(name),
        masked_body))


def route_global_assignments(info, body, body_start, hdr_index=None, hcache=None):
    """[(tag, line, snippet, is_exp)]——链内全局赋值候选（四路路由）。
    掩蔽体上匹配（mask_source 保长——行号/原文片段按真实偏移）；候选
    文本取原文（真实字符串可见）。路由顺序即 C++ 名字查找由内向外：
    R1 限定名（恒真，跳过局部检查）→ R3 局部排除 → R2 本文件表 →
    R2h 头文件表 → R4 表外待确认。"""
    out = []
    masked = mask_source(body)

    def _snip(m):
        return " ".join(body[max(0, m.start() - 25):m.end() + 55].split())[:120]

    for m in QUAL_ASSIGN_RE.finditer(masked):
        out.append((
            "R1限定名", node_line(info, body_start, m.start()), _snip(m),
            bool(EXPORTS_MARK.search(body[max(0, m.start() - 60):m.end() + 60]))))
    for m in SIMPLE_ASSIGN_RE.finditer(masked):
        name = m.group(1)
        if _is_local(masked, name):          # R3：先于查表（内层遮蔽外层）
            continue
        ln = node_line(info, body_start, m.start())
        is_exp = bool(EXPORTS_MARK.search(
            body[max(0, m.start() - 60):m.end() + 60]))
        entries = file_table(info).get(name)
        if entries:
            out.append(("R2表命中(本文件L%d)" % entries[0][0], ln, _snip(m), is_exp))
            continue
        hh = header_lookup(info, name, hdr_index, hcache) if hdr_index else None
        if hh:
            out.append(("R2h头文件(%s:L%d)"
                        % (os.path.basename(hh[0]), hh[1]), ln, _snip(m), is_exp))
            continue
        tag = "R4表外待确认"
        if name.startswith(("g_", "s_")):
            tag += "（命名先验g_/s_，优先复核）"
        out.append((tag, ln, _snip(m), is_exp))
    return out


def _bare(n):
    """根节点名去前缀（ctor:/cb:）——与被调解析裸名统一为同一去重键。"""
    return n.split(":", 1)[1] if n.startswith(("ctor:", "cb:")) else n


def expand_packs(packs, dindex, cache, depth, budget):
    """Wave expansion across ALL chain packs at once.

    packs: list of dict(nodes=[], roots=[(label, info, hit)]).
    Per LEVEL: callee names of every frontier node are batched into ONE
    dindex.extend() pass (the per-node version re-scanned the tree per node —
    quadratic). Shared callees: body resolved once (cache), node included in
    every calling pack (per-chain signal coverage), subtree walked once.

    depth: int = hard level limit; None = AUTO — expand level by level until
    the frontier is exhausted (natural saturation) or AUTO_DEPTH_CAP.
    Returns (used, stats) with per-level node counts and saturation flags:
    saturated_at_cap / budget_exhausted tell the caller whether the deepest
    level might still hide hits (boundary effect).
    """
    level_cap = depth if depth is not None else AUTO_DEPTH_CAP
    visited = set()
    frontier = []
    stats = {"levels": {0: 0}, "budget_exhausted": False,
             "frontier_left": False}
    for pi, p in enumerate(packs):
        for label, info, hit in p["roots"]:
            if hit is None:
                continue
            nd = dict(name=label, info=info, text=hit["text"],
                      start=hit["start"], level=0)
            p["nodes"].append(nd)
            stats["levels"][0] = stats["levels"].get(0, 0) + 1
            # 2026-10-29 修正（验证发现 #6）：根节点名带 ctor:/cb: 前缀，与被调
            # 解析的裸名（ctor 自身定义行会被 CALLEE_RE 捕获为自调用）键失配
            # → 同体节点双份（信号×2、函数体×2）。visited/pseen 统一按裸名记账。
            visited.add((info["path"], _bare(label)))
            frontier.append((pi, nd))
    used = len(frontier)
    level = 0
    while frontier and level < level_cap:
        level += 1
        cap = DEEP_CALLEE_CAPS[min(level - 1, len(DEEP_CALLEE_CAPS) - 1)]
        per_node = [(pi, nd, extract_callees(nd["text"])[:cap])
                    for pi, nd in frontier]
        level_names = []
        for _pi, _nd, names in per_node:
            for n, _q in names:
                if n not in level_names:
                    level_names.append(n)
        if not level_names:
            break
        dindex.extend(level_names)          # ONE pass per level
        nxt = []
        added = 0
        for pi, nd, names in per_node:
            pseen = {(x["info"]["path"], _bare(x["name"]))
                     for x in packs[pi]["nodes"]}
            for n, qual in names:
                if used >= budget:
                    stats["budget_exhausted"] = True
                    break
                r = resolve_callee(n, qual, nd["info"], dindex, cache,
                                   DEEP_SCAN_CAP)
                if r is None:
                    continue
                other, hit, nsn = r
                key = (other["path"], n)
                if key in pseen:
                    continue                # per-pack dedup (shared callees)
                shared = key in visited
                if len(hit["text"]) < 80:
                    continue
                newnd = dict(name=n, info=other, text=hit["text"],
                             start=hit["start"], level=level,
                             same_name=nsn)  # 方案A9：同名候选数（>1 = 猜测边）
                packs[pi]["nodes"].append(newnd)
                pseen.add(key)
                used += 1
                added += 1
                if shared:
                    continue                 # subtree already walked once
                visited.add(key)
                if len(hit["text"]) > 120:
                    nxt.append((pi, newnd))
        if added:
            stats["levels"][level] = added
        frontier = nxt
    stats["frontier_left"] = bool(frontier)
    stats["max_level"] = level
    return used, stats


def render_chain_pack(reg_path, modname, nodes, hits_by_node, formb,
                      full_paths=False, formb_nodes=None):
    """One chain section of the work pack; returns markdown lines."""
    def _p(x):
        return os.path.abspath(x) if full_paths else os.path.relpath(x)
    out = []
    clean = not any(hits_by_node.values()) and not formb
    l_counts = {}
    for nd in nodes:
        l_counts[nd["level"]] = l_counts.get(nd["level"], 0) + 1
    depth_str = " + ".join("L%d×%d" % (l, c)
                           for l, c in sorted(l_counts.items()))
    mod = " → 模块 %s" % ", ".join(modname) if modname else ""
    out.append("### 链：%s%s" % (_p(reg_path), mod))
    if clean:
        node_list = "; ".join(
            "%s@%s:L%d%s" % (nd["name"], _p(nd["info"]["path"]),
                             nd["info"]["src"].count("\n", 0, nd["start"]) + 1,
                             "（同名候选%d处）" % nd["same_name"]
                             if nd.get("same_name", 1) > 1 else "")
            for nd in nodes if nd["level"] > 0)[:1500]
        out.append("- ✅ 链干净（%s 已全量信号扫描，0 命中）%s"
                   % (depth_str or "L0", ("；节点: " + node_list) if node_list
                      else ""))
        return out
    out.append("- 链节点: %s" % depth_str)
    # 2026-10-29 修正（验证发现 #6）：跨节点重复命中去重——同一函数体经多通道
    # 入链时（历史双通道已由 expand_packs 根治，此处为呈现层兜底），键＝
    # 路径×信号类×行×片段（同位置同信号唯一；同行不同实参片段保留）。
    uniq, seen = [], set()
    for nd in nodes:
        for label, ln, snippet, is_exp in hits_by_node.get(id(nd), []):
            k = (nd["info"]["path"], label, ln, snippet)
            if k in seen:
                continue
            seen.add(k)
            uniq.append((nd, label, ln, snippet, is_exp))
    out.append("- ⚠️ 信号命中 ×%d（**待语义复核**——S-02/M-19 命中 ≠ 成本定档，须逐条查 "
               "S-07/S-08/S-09；v7 锚点：与构建 exports 无关即"
               "类别1 候选，按 rulebook §2 统一成本定级（轻量不计；不可判定 → "
               "待确认，公开通用 API 按速查表直判）；"
               "标记 /exports 的行按导出面构建排除复核）：" % len(uniq))
    amb_seen = set()                    # 方案A9：同名消歧标注（每节点一次）
    for nd, label, ln, snippet, is_exp in uniq:
        out.append("  - [%s%s] %s:%d %s"
                   % (label, "/exports" if is_exp else "",
                      _p(nd["info"]["path"]), ln, snippet[:120]))
        if nd.get("same_name", 1) > 1 and id(nd) not in amb_seen:
            amb_seen.add(id(nd))
            out.append("    ⚠️ 同名候选 %d 处（接收者类型未知，按目录邻近选取"
                       "——本节点为猜测边，复核需核对接收者）" % nd["same_name"])
    if formb:
        out.append("- 全局赋值候选（词法表路由 R1限定名/R2本文件/R2h头文件/R4表外；"
                   "待宿主确认与成本判定——R2/R2h 附定义行可跳转核对；"
                   "/exports 标记行按导出面构建排除复核）:")
        for path, ln, snippet, tag, is_exp in formb:
            out.append("  - [%s%s] %s:%d %s"
                       % (tag, "/exports" if is_exp else "",
                          _p(path), ln, snippet[:120]))
    hit_nodes = [nd for nd in nodes if hits_by_node.get(id(nd))
                 or (formb_nodes and id(nd) in formb_nodes)]
    out.append("- 命中节点函数体（复核用；全文已用于信号扫描/调用链展开；"
               "含全局赋值候选所在节点）:")
    bseen = set()
    shown = 0
    for nd in hit_nodes:                # 同体（路径×起点）只呈现一份（验证发现 #6）
        bk = (nd["info"]["path"], nd["start"])
        if bk in bseen:
            continue
        bseen.add(bk)
        if shown >= 4:
            break
        shown += 1
        body = nd["text"]
        rc = DEEP_RENDER_CAPS[min(nd["level"], len(DEEP_RENDER_CAPS) - 1)]
        if len(body) > rc:
            body = body[:rc] + "\n…（截断——信号扫描与调用链展开均基于全文）"
        if nd.get("same_name", 1) > 1:      # 方案A9：猜测边体前置标注
            out.append("  ⚠️ 同名候选 %d 处（按目录邻近选取——接收者类型"
                       "未知，复核需核对接收者）" % nd["same_name"])
        out.append("  ```cpp\n  %s\n  ```" % body)
    return out


def _cdepth(a, b, base):
    """两个文件相对 base 的公共目录深度（组件级路径前缀判定用）。"""
    ra = os.path.relpath(a, base).split(os.sep)
    rb = os.path.relpath(b, base).split(os.sep)
    d = 0
    for x, y in zip(ra, rb):
        if x != y:
            break
        d += 1
    return d


def build_module_attribution(infos, chain_files_map, chain_root_files, base):
    """方案A8 模块归属启发式（rulebook §4.6 M-27）：
    T1 定义（自身 nm_modname / 变体 .name，含 A5 头文件解析）＞ T2 链上
    （模块注册链节点文件）＞ T3 同目录（严格同目录，推测）。
    护栏①多链：命中 >3 个模块链 → 不确定（公共层/疑似同名误归，如
    ets_context_utils.cpp 实测挂 39 链）；护栏②跨组件：展开节点与注册
    文件公共路径 <2 级 → 不确定（同名解析污染——level-0 根节点即回调
    定义文件恒信，不受此限）；护栏③同目录多模块 → 不确定；目录无注册
    文件 → 无归属（= 非模块库文件，ffrt/rtg 一类）。
    S-24 联动：T1/T2 → 加载路径归属①（import 路径确认）。"""
    attr = {}
    for i in infos:
        if i["modnames"]:
            attr[i["path"]] = ("定义", list(i["modnames"]), "")
    file2mods = {}
    for root, files in chain_files_map.items():
        mods = attr.get(root, (None, [], ""))[1]
        for f in files:
            if f in attr or not mods:            # T1 优先
                continue
            rec = file2mods.setdefault(f, {"trust": set(), "suspect": set()})
            if f in chain_root_files or _cdepth(f, root, base) >= 2:
                rec["trust"].update(mods)
            else:
                rec["suspect"].update(mods)
    for f, rec in sorted(file2mods.items()):
        trust, susp = rec["trust"], rec["suspect"]
        allmods = trust | susp
        if len(allmods) > 3:
            attr[f] = ("不确定", [],
                       "命中 %d 个模块链（公共层/疑似同名误归）" % len(allmods))
        elif not trust:
            attr[f] = ("不确定", sorted(susp),
                       "链上但跨组件路径（疑似同名误归，需核对调用点）")
        else:
            note = ("另有跨组件链命中: %s（疑似同名误归）"
                    % "、".join(sorted(susp))) if susp else ""
            attr[f] = ("链上", sorted(allmods), note)
    targets = set(chain_files_map)
    for fs in chain_files_map.values():
        targets |= fs
    targets |= chain_root_files
    for i in infos:
        if i["chain"] or i["init"] or i["init_proto"] or i["safety"]:
            targets.add(i["path"])
    t1_by_dir = {}
    for p, (t, mods, _n) in list(attr.items()):
        if t == "定义":
            t1_by_dir.setdefault(os.path.dirname(p), set()).update(mods)
    for p in sorted(targets):
        if p in attr:
            continue
        mods = t1_by_dir.get(os.path.dirname(p))
        if not mods:
            attr[p] = ("无归属", [], "目录内无注册文件")
        elif len(mods) == 1:
            attr[p] = ("同目录(推测)", sorted(mods), "")
        else:
            attr[p] = ("不确定", sorted(mods), "目录内多模块")
    return attr


def render_module_attribution(attr, deep):
    out = ["## 模块归属清单（方案A8·M-27：T1 定义 > T2 链上 > T3 同目录推测；"
           "T1/T2 → S-24 加载路径归属①）%s"
           % ("" if deep else "（--deep 未启用：链上档缺席）")]
    order = {"定义": 0, "链上": 1, "同目录(推测)": 2, "不确定": 3, "无归属": 4}
    cnt = {}
    for p, (t, mods, note) in sorted(attr.items(),
                                     key=lambda kv: (order[kv[1][0]], kv[0])):
        cnt[t] = cnt.get(t, 0) + 1
        m = "、".join(mods) if mods else "—"
        out.append("- %s → %s（%s%s）" % (
            p, m, t, ("；" + note) if note else ""))
    out.append("")
    out.append("统计：定义 %d / 链上 %d / 同目录推测 %d / 不确定 %d / 无归属 %d"
               % (cnt.get("定义", 0), cnt.get("链上", 0),
                  cnt.get("同目录(推测)", 0), cnt.get("不确定", 0),
                  cnt.get("无归属", 0)))
    out.append("")
    return out


def main():
    ap = argparse.ArgumentParser(
        description="hmos-arkts-napi-side-effect-checker prescan (funnel 1-2)")
    ap.add_argument("path", help="directory or single C/C++ file")
    ap.add_argument("--all", action="store_true",
                    help="包含 test/example/sample 目录（默认排除）")
    ap.add_argument("--safety-net", action="store_true",
                    help="包含 P4 缩进 static/inline 安全网命中（v7.1 默认关）")
    ap.add_argument("--no-bodies", action="store_true",
                    help="不输出 constructor/回调函数体（仅工作清单）")
    ap.add_argument("--max-body", type=int, default=3000,
                    help="单个函数体最大字符数（默认 3000）")
    ap.add_argument("--deep", action="store_true",
                    help="输出深析工作包：调用链 L1/LN 机械展开 + 类别1 信号扫描"
                         " + 形态B 候选预收集（替代 SKILL 步骤 2 的逐文件读/grep）")
    ap.add_argument("--chain-depth", default="auto",
                    help="调用链展开深度：auto（默认，逐层展开至前沿枯竭，"
                         "上限 %d 层）或显式整数 1-8（饱和警告可能建议更高值）"
                         % AUTO_DEPTH_CAP)
    ap.add_argument("--split", type=int, default=-1,
                    help="（配合 --deep）命中链与形态A 候选写入 N 个分片文件"
                         "供并行子代理复核。-1（默认）= 自动：命中链 ≥10 时"
                         "自动分片且 stdout 不再内联命中链详情；0 = 强制内联；"
                         "正整数 = 指定片数（上限 10）")
    ap.add_argument("--split-dir", default="./prescan_shards",
                    help="分片输出目录（默认 ./prescan_shards，工作目录而非"
                         "被检仓；用后可删）")
    ap.add_argument("--strict-expand", action="store_true",
                    help="方法调用展开恢复生命周期命名白名单（默认全展开——"
                         "方案A9：白名单实测近惰性（+6%% 节点），CALLEE_SKIP 才是"
                         "噪声闸门；全展开配同名消歧标注）")
    args = ap.parse_args()
    if args.strict_expand:               # 方案A9：回滚开关（换回白名单门控）
        global METHOD_EXPAND_RE
        METHOD_EXPAND_RE = METHOD_EXPAND_LIFECYCLE
    if args.chain_depth == "auto":
        chain_depth = None                   # adaptive, capped
    else:
        chain_depth = max(1, min(int(args.chain_depth), 8))

    if not os.path.exists(args.path):
        print("❌ 路径不存在：%s" % args.path, file=sys.stderr)
        return 1

    files, skipped = collect_files(args.path, args.all)
    if not files:
        print("未发现 C++ 文件（.cpp/.cc/.cxx/.c）")
        if skipped:
            print("（另有 %d 个文件位于默认排除目录）" % skipped)
        return 0

    hdr_index = build_header_index(args.path)
    infos = [scan_file(f, hdr_index) for f in files]
    chain_infos = [i for i in infos if i["chain"]]
    init_infos = [i for i in infos if i["init"]]
    proto_infos = [i for i in infos if i["init_proto"]]
    n_proto = sum(len(i["init_proto"]) for i in infos)
    safety_infos = [i for i in infos if i["safety"]]
    # a file may hit both chain elements and init signals — count each file once
    # (P2-proto pre-excluded hits are not candidates but not "unrelated" —
    #  keep them out of the zero-hit bucket for funnel auditability)
    unrelated = sum(1 for i in infos
                    if not i["chain"] and not i["init"] and not i["init_proto"])
    cache = {}
    cb_index = build_cb_index(infos, chain_infos)

    n_cb = sum(len(i["cbs"]) for i in chain_infos)
    print("# NAPI 副作用初筛结果（hmos prescan，漏斗第 1-2 级 + 注册点解析）%s"
          % ("（全量扫描）" if args.all else ""))
    print()
    print("## 统计")
    print("- 扫描 C++ 文件：%d 个（默认跳过 test/example/sample：%d 个）"
          % (len(files), skipped))
    print("- NAPI 相关文件（注册链要素命中，需深析）：%d 个%s"
          % (len(chain_infos),
             "（含变体注册点标记，需甄别注册方/运行时使用方）"
             if any(any(l in VARIANT_ELEMENTS for l in i["chain"])
                    for i in chain_infos) else ""))
    print("- 形态A 候选文件（P1/P2/P3 列首信号 + P1ns/P2ns ns 区域缩进信号，经排除管道）：%d 个"
          % len(init_infos))
    print("- P2-proto 原型预剔除（参数段均为带名形参形态，不计形态A候选）：%d 条 / %d 个文件"
          % (n_proto, len(proto_infos)))
    if args.safety_net:
        print("- 安全网（P4 缩进 static/inline，须作用域确认）：%d 个文件"
              % len(safety_infos))
    print("- 零命中跳过：%d 个" % unrelated)
    print("- 回调级（双不变量基数）：注册回调 %d 个；下方逐个标注"
          " 本文件/跨文件/UNRESOLVED 解析结果" % n_cb)
    print()

    if chain_infos:
        print("## 注册点解析（深析入口）%s"
              % ("（函数体见下方深析工作包）" if args.deep else ""))
        for i in chain_infos:
            print()
            print("### %s" % i["path"])
            if i["modnames"]:
                print("- nm_modname: %s" % ", ".join(i["modnames"]))
            variants = [l for l in i["chain"] if l in VARIANT_ELEMENTS]
            if variants:
                print("- 变体注册点: %s（NativeModuleManager::Register 需甄别"
                      "注册方/运行时使用方）" % ", ".join(variants))
            if i["ctors"]:
                print("- constructor: %s" % ", ".join(i["ctors"]))
                if not args.no_bodies and not args.deep:
                    for cn in i["ctors"][:1]:
                        hit = body_of(i, cn, args.max_body)
                        if hit:
                            print("```cpp\n%s\n```" % hit["text"])
            if i["cbs"]:
                for name, how in i["cbs"]:
                    r = resolve_callback(name, i, cb_index, args.max_body, cache)
                    if r is None:
                        print("- 注册回调: `%s`（来源: %s）—— **UNRESOLVED**"
                              "（定义不在扫描范围；include-follow 或人工处理，"
                              "禁止静默跳过）" % (name, how))
                        continue
                    where, hit = r
                    m = hit["info"]["_masked"]()
                    print("- 注册回调: `%s`（来源: %s）→ 定义于 %s L%d-L%d"
                          % (name, how, where,
                             m.count("\n", 0, hit["start"]) + 1,
                             m.count("\n", 0, hit["end"]) + 1))
                    if not args.no_bodies and not args.deep:
                        print("```cpp\n%s\n```" % hit["text"])
            elif not i["ctors"] and not variants:
                print("- 未解析到注册回调/constructor——确认是否为自定义宏注册"
                      "（提示用户告知宏名后重扫）")
            hits = "、".join(
                "%s(%s)" % (l, ",".join("L%d" % h for h in v[:5]))
                for l, v in i["chain"].items())
            print("- 要素命中: %s" % hits)
        print()

    if init_infos:
        print("## 形态A 候选（P1/P2/P3 列首 + P1ns/P2ns 命名空间区域缩进，经排除管道；深析做成本判定）")
        for i in init_infos:
            print()
            print("### %s" % i["path"])
            for sig, ln, text in i["init"]:
                print("- L%d [%s] %s" % (ln, sig, text))
        print()

    if proto_infos:
        print("## P2/P2ns-proto 原型预剔除（参数段均为带名形参——函数原型，"
              "不计入形态A候选；审查可抽查）")
        for i in proto_infos:
            print()
            print("### %s" % i["path"])
            for sig, ln, text in i["init_proto"]:
                print("- L%d [%s-proto] %s" % (ln, sig, text))
        print()

    if args.safety_net and safety_infos:
        print("## 安全网命中（P4 缩进 static/inline——必须作用域确认后方可入候选）")
        for i in safety_infos:
            print()
            print("### %s" % i["path"])
            for ln, text in i["safety"]:
                print("- L%d %s" % (ln, text))
        print()

    chain_files_map = {}   # 方案A8：模块归属 T2（链上）——deep 链节点文件集
    chain_root_files = set()   # level-0 根节点文件（ctor/回调定义——恒信归属）
    if args.deep and chain_infos:
        dindex = DeepIndex(infos)
        dcache = {}
        depth_desc = ("auto（上限 L%d）" % AUTO_DEPTH_CAP
                      if chain_depth is None else "L%d" % chain_depth)
        print("## 深析工作包（调用链机械展开 %s + 类别1 信号扫描 + 形态B 候选）"
              % depth_desc)
        print()
        print("> 信号命中 ≠ 问题，更 ≠ 成本定档：S-02/M-19 只是候选线索，成本必须逐条查 "
              "S-07/S-08/S-09（如 sigaction 仅函数指针/POD/系统调用 → 轻量）；"
              "待语义复核（v7 锚点：与构建 exports 无关即类别1 候选，"
              "按 rulebook §2 统一成本定级——轻量不计，不可判定 → 待确认，公开通用 "
              "API 按速查表直判）；"
              "同名函数解析为最近候选——复核时核对定义归属；/exports "
              "标记行按导出面构建排除复核；call_once 不改变宿主归属。")
        print()
        print("- 信号表：通用层 %d 条 + OHOS 域层 %d 条（两层始终同时生效；"
              "域层为系统仓习语，应用仓真阳性预期为零、通用词形误报由语义"
              "复核剔除——见 rulebook §4.5「CAT1 信号表」）"
              % (len(CAT1_SIGNALS_GENERIC), len(CAT1_SIGNALS_OHOS)))
        print()
        n_clean = n_hit = 0
        packed = set()
        packs = []
        for i in chain_infos:
            if not i["cbs"] and not i["ctors"]:
                continue
            roots = []
            if i["ctors"]:
                hit = body_of(i, i["ctors"][0], DEEP_SCAN_CAP)
                if hit:
                    roots.append(("ctor:" + i["ctors"][0], i, hit))
            for name, _how in i["cbs"]:
                r = resolve_callback(name, i, cb_index, args.max_body, cache)
                if r is None:
                    continue
                key = (r[1]["info"]["path"], name)
                if key in packed:
                    continue
                packed.add(key)
                full = body_of(r[1]["info"], name, DEEP_SCAN_CAP)
                if full is None:
                    full = r[1]
                roots.append(("cb:" + name, full["info"],
                              {"text": full["text"], "start": full["start"]}))
            if not roots:
                continue
            packs.append({"reg": i, "roots": roots, "nodes": []})
        _used, xstats = expand_packs(packs, dindex, dcache, chain_depth,
                                     DEEP_MAX_NODES)
        for p in packs:
            # 方案A8：链节点文件集（root 模块名 → 节点文件归属）；无模块名
            # 的链（constructor-only，如 form_render_impl）不参与 T2
            if p["reg"]["modnames"]:
                chain_files_map.setdefault(p["reg"]["path"], set()).update(
                    {p["reg"]["path"]} |
                    {nd["info"]["path"] for nd in p["nodes"]})
                chain_root_files.update(
                    nd["info"]["path"] for nd in p["nodes"]
                    if nd["level"] == 0)
        hits_per_level = {}
        hit_sections = []                    # [(title, lines)] for --split
        clean_sections = []
        sec_files_map = {}   # id(section) → 本段涉及文件集（分片随附归属行用，验证发现 #3）
        gcache = {}                     # R2h 头文件查名缓存（文件×名字）
        for p in packs:
            i = p["reg"]
            hits_by_node, formb, formb_nodes = {}, [], set()
            for nd in p["nodes"]:
                h = scan_node_signals(nd["info"], nd["text"], nd["start"])
                if h:
                    hits_by_node[id(nd)] = h
                    hits_per_level[nd["level"]] = \
                        hits_per_level.get(nd["level"], 0) + len(h)
                fb = route_global_assignments(
                    nd["info"], nd["text"], nd["start"], hdr_index, gcache)
                if fb:
                    formb.extend((nd["info"]["path"], ln, snip, tag, is_exp)
                                 for tag, ln, snip, is_exp in fb)
                    formb_nodes.add(id(nd))
            lines = render_chain_pack(i["path"], i["modnames"], p["nodes"],
                                      hits_by_node, formb, formb_nodes=formb_nodes)
            if len(lines) == 2 and "链干净" in lines[1]:
                n_clean += 1
                clean_sections.append(lines)
            else:
                n_hit += 1
                if args.split:     # shards use absolute paths for subagents
                    lines = render_chain_pack(i["path"], i["modnames"],
                                              p["nodes"], hits_by_node, formb,
                                              full_paths=True,
                                              formb_nodes=formb_nodes)
                sec_files_map[id(lines)] = (
                    {i["path"]} |
                    {nd["info"]["path"] for nd in p["nodes"]})
                hit_sections.append(lines)
        print("- 链统计：干净 %d / 有命中 %d（命中链才需深析，干净链仅抽查）"
              % (n_clean, n_hit))
        lv = " / ".join("L%d:节点%d·命中%d"
                        % (l, xstats["levels"].get(l, 0),
                           hits_per_level.get(l, 0))
                        for l in sorted(xstats["levels"]))
        print("- 各层分布：%s" % lv)
        max_lvl = xstats["max_level"]
        deepest_hit = max(hits_per_level) if hits_per_level else 0
        if xstats["budget_exhausted"]:
            print("- ⚠️ 节点预算（%d）耗尽——展开不完整，深析复核时对长链"
                  "（引擎类）人工补深，或分目录扫描" % DEEP_MAX_NODES)
        if (deepest_hit >= max_lvl and hits_per_level.get(max_lvl)
                and (xstats["frontier_left"] or chain_depth is not None)):
            deep_labels = {}
            for p in packs:
                for nd in p["nodes"]:
                    if nd["level"] == max_lvl:
                        for h in scan_node_signals(nd["info"], nd["text"],
                                                   nd["start"]):
                            deep_labels[h[0]] = deep_labels.get(h[0], 0) + 1
            comp = "、".join("%s×%d" % kv for kv in sorted(
                deep_labels.items(), key=lambda x: -x[1]))
            soft = ""
            if deep_labels and set(deep_labels) <= {"系统参数读取",
                                                     "文件IO"}:
                soft = ("（均为参数读取/文件探测类信号，增量已收敛，"
                        "可接受当前深度）")
            print("- ⚠️ 深度饱和警告：最深层 L%d 仍产生 %d 个命中（%s）%s——"
                  "若含线程/IPC/dlopen/进程级注册类信号，建议 --chain-depth %d "
                  "复扫（每层 ~数秒）"
                  % (max_lvl, hits_per_level[max_lvl], comp, soft,
                     max_lvl + 1))
        elif not xstats["frontier_left"] and chain_depth is None:
            print("- ✅ 深度已自然饱和：前沿在 L%d 枯竭，无截断风险" % max_lvl)
        print()
        # form-A pack: collect per-file sections (share the split/print path)
        forma_sections = []
        if init_infos:
            init_call = re.compile(
                r'=\s*\(?\s*([A-Za-z_]\w*(?:::\w+)*)\s*\(')
            for i in init_infos:
                sec = ["### %s" % i["path"]]
                files = {i["path"]}
                for sig, ln, text in i["init"]:
                    extra = ""
                    impl_body = None
                    m = init_call.search(text)
                    if m and not m.group(1).startswith("new"):
                        callee = m.group(1).rsplit("::", 1)[-1]
                        dindex.extend([callee])
                        r2 = resolve_callee(
                            callee, m.group(1)[:m.group(1).rfind("::") + 1]
                            if "::" in m.group(1) else "",
                            i, dindex, dcache, 1200)
                        if r2 and m.group(1) in r2[0]["src"]:
                            # qualified names must appear verbatim in the
                            # defining file (tail-only matches mis-attribute
                            # external APIs like OHOS::system::GetParameter
                            # to unrelated same-name locals)
                            other, hit, nsn2 = r2
                            ih = scan_node_signals(other, hit["text"],
                                                   hit["start"])
                            extra = "；初始化器 `%s` 实现于 %s:L%d%s%s" % (
                                m.group(1), os.path.relpath(other["path"]),
                                other["src"].count("\n", 0, hit["start"]) + 1,
                                ("（含信号: %s）"
                                 % ",".join(sorted({h[0] for h in ih})))
                                if ih else "（无信号）",
                                ("（同名候选%d处——需核对接收者）" % nsn2)
                                if nsn2 > 1 else "")
                            # 2026-10-29（验证发现 #7）：已定位实现随附函数体
                            # （≤500 字符截断）——"（无信号）"不再缺体，复核闭环
                            impl_body = hit["text"]
                            files.add(other["path"])
                        elif "::" in m.group(1):
                            extra = ("；限定名 `%s` 未在仓内定义——按外部符号"
                                     "处理（成本人工确认）" % m.group(1))
                    sec.append("- L%d [%s] %s%s" % (ln, sig, text[:160], extra))
                    if impl_body is not None:
                        b = impl_body[:500]
                        if len(impl_body) > 500:
                            b += "\n…（截断——全文已用于信号扫描）"
                        sec.append("  ```cpp\n  %s\n  ```" % b)
                forma_sections.append(sec)
                sec_files_map[id(sec)] = files
        # 方案A8（M-27）：分片前计算模块归属——分片随附归属行（验证发现 #3：
        # S-24 门控短路缺数据——定义/链上＝在 import 路径，重档直接判需整改）
        attr = build_module_attribution(
            infos, chain_files_map, chain_root_files,
            args.path if os.path.isdir(args.path)
            else os.path.dirname(args.path))
        # output: AUTO-SPLIT by default — with >=10 hit chains, inline
        # detail (~100KB+) drowns the main context and drives serial
        # per-chain review; shards + parallel subagent review is the fast
        # path, so make it the default. --split 0 disables auto-splitting.
        split_n = args.split
        total_secs = len(hit_sections) + len(forma_sections)
        total_bytes = (sum(len("\n".join(s)) for s in hit_sections)
                       + sum(len("\n".join(s)) for s in forma_sections))
        if split_n < 0:                      # auto (default)
            split_n = 0
            # hit chains carry inline bodies (the real context bulk); form-A
            # sections are one-liners — split on chain count or total bytes
            if len(hit_sections) >= 10 or total_bytes > 40000:
                split_n = max(1, min(8, (total_secs + 7) // 8))
        if split_n and (hit_sections or forma_sections):
            n = max(1, min(split_n, 10))
            chunks = [(("链", s), len("\n".join(s)))
                      for s in hit_sections]
            chunks += [(("形态A", s), len("\n".join(s)))
                       for s in forma_sections]
            chunks.sort(key=lambda c: -c[1])   # greedy bin-packing by size
            shards = [[] for _ in range(n)]    # (size, sections)
            sizes = [0] * n
            for kind, sec in [c[0] for c in chunks]:
                k = sizes.index(min(sizes))
                shards[k].append((kind, sec))
                sizes[k] += len("\n".join(sec)) + 16
            outdir = os.path.abspath(args.split_dir)
            os.makedirs(outdir, exist_ok=True)
            print("## 深析分片（%d 个命中链 + %d 个形态A 文件 → %d 片，"
                  "供并行子代理复核；用后可删）"
                  % (len(hit_sections), len(forma_sections), n))
            for k, shard in enumerate(shards):
                if not shard:
                    continue
                fp = os.path.join(outdir, "shard_%d.md" % (k + 1))
                with open(fp, "w", encoding="utf-8") as fh:
                    fh.write("# 深析复核分片 %d/%d\n\n" % (k + 1, n))
                    fh.write("> 复核规则见 rulebook.md（skill 的 references/rulebook.md）"
                             "§1 判定总览＋§2 S 层：统一成本判定（类别1/类别2 共用"
                             "成本三级，轻量不计问题；公开通用 API 按速查表直判；"
                             "类别1 动作需定位实现定级，定位不到 → 待人工确认；"
                             "成本=重者按随片归属行执行 S-24 门控——定义/链上即"
                             "在 import 路径）；只判定，不改代码。\n\n")
                    # 2026-10-29（验证发现 #3）：随片附本片文件归属档位行
                    files = set()
                    for _kind, sec in shard:
                        files |= sec_files_map.get(id(sec), set())
                    if files:
                        order = {"定义": 0, "链上": 1, "同目录(推测)": 2,
                                 "不确定": 3, "无归属": 4}
                        fh.write("> 本片文件归属（M-27；S-24 门控：定义/链上＝"
                                 "在 import 路径——重档判需整改；同目录(推测)/"
                                 "不确定/无归属＝待核——重档判需确认）：\n")
                        for fpath in sorted(
                                files, key=lambda p: (order.get(
                                    attr.get(p, ("无归属",))[0], 4), p)):
                            t, mods, _note = attr.get(
                                fpath, ("待核", [], "未入归属清单"))
                            mtxt = ("（%s）" % "、".join(mods)) if mods else ""
                            fh.write("> - %s → %s%s\n" % (fpath, t, mtxt))
                        fh.write("\n")
                    for kind, sec in shard:
                        fh.write("\n".join(sec) + "\n\n")
                print("- %s（%d 段，~%d 字符）" % (fp, len(shard), sizes[k]))
            print()
        else:
            for sec in hit_sections:
                print("\n".join(sec))
                print()
            if forma_sections:
                print("## 形态A 候选工作包（初始化器实现定位——成本判定用）")
                for sec in forma_sections:
                    print()
                    print("\n".join(sec))
                print()
            pass  # clean chains already counted; one-liners printed below
        for sec in clean_sections:
            print("\n".join(sec))
            print()

    unresolved = []
    for i in chain_infos:
        for name, _how in i["cbs"]:
            if resolve_callback(name, i, cb_index, args.max_body, cache) is None:
                unresolved.append((i["path"], name))
    if unresolved:
        print("## UNRESOLVED 回调（人工/include-follow/extract -R 处理，禁止静默跳过）")
        for p, n in unresolved:
            print("- %s: %s" % (p, n))
    # 方案A8（M-27）：模块归属清单（T1 定义 > T2 链上 > T3 同目录推测 > 不确定/无归属）
    if not args.deep:      # deep 模式已在分片打包前计算（attr 复用）
        attr = build_module_attribution(
            infos, chain_files_map, chain_root_files,
            args.path if os.path.isdir(args.path)
            else os.path.dirname(args.path))
    for line in render_module_attribution(attr, deep=bool(chain_files_map)):
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
