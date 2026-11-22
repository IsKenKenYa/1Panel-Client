#!/usr/bin/env python3
"""apply_init_extraction.py — 场景2（扫描技能「类别1：注册函数违规业务逻辑（耗时）」）整改引擎。

整改规范：nm_register_func 的 Init 回调尽量只做函数映射（导出面构建），
业务初始化挪到显式导出的 init() 接口，由 ArkTS 侧在首次使用前调用。

整改形态（与扫描技能术语一致）：

  改写前（注册回调内业务动作——so 被 dlopen 即执行）：
      static napi_value Init(napi_env env, napi_value exports)
      {
          RegisterCustomBrightness();                 // ← 业务初始化（MOVE）
          napi_property_descriptor desc[] = { ... };  //   函数映射（KEEP）
          napi_define_properties(env, exports, ...);  //   函数映射（KEEP）
          return exports;                             //   KEEP
      }

  改写后（Init 只留函数映射；业务初始化进显式 init() 导出）：
      // 业务初始化（原位于注册回调 Init——类别1：注册函数违规业务逻辑）。
      // 由 ArkTS 侧在首次调用本模块其他接口前显式调用一次 init()。
      static napi_value ExplicitInit(napi_env env, napi_callback_info info)
      {
          RegisterCustomBrightness();                 // ← 原样搬迁（verbatim）
          napi_value result = nullptr;
          napi_get_undefined(env, &result);
          return result;
      }
      static napi_value Init(napi_env env, napi_value exports)
      {
          napi_property_descriptor desc[] = {
              ...
              DECLARE_NAPI_FUNCTION("init", ExplicitInit),   // ← 自动挂载
          };
          napi_define_properties(env, exports, ...);
          return exports;
      }

语句分类（对齐扫描技能 rulebook S-02/S-03/M-19/M-23）：
  KEEP（导出面构建，保留）：
    - napi 导出面 API（napi_property_descriptor/napi_define_properties/
      napi_create_function/napi_define_class/napi_set_named_property/napi_wrap/
      napi_create_object/DECLARE_NAPI_*/NAPI_CALL/BindNativeFunction 等）
    - 实参含 exports 的调用（XxxProxy::Init(env, exports) 惯用法）
    - exports 数据流局部变量（被 KEEP 语句引用/挂载的局部对象，如枚举对象）
    - 被调函数体（同文件可解析）只含 napi 面 API、无业务信号（如 Register*JSClass
      内部是 napi_define_class）→ 导出面构建辅助函数
    - 日志（*_LOG*/HILOG/HITRACE 落"未命中"保守保留）、env/exports 判空守卫、return
  MOVE（业务初始化，迁入 init()）：
    - 命中 M-19 信号（进程级回调注册/线程/文件IO/连接/信号处理器/事件循环/IPC 等）
      或业务动词族（Init/Create/Register/Subscribe/Attach/Start/...）且无 KEEP 依赖
  SKIP_FORMB（属类别2/形态B，由 apply_lazy_init.py 处理）：
    - 全局变量赋值语句 / 含全局赋值的守卫块
  未命中（?）：保守保留 + 待复核提示

安全闸门（H1–H7；失败拒绝改写）：
  H1 存在至少一条可迁移语句（否则：回调已是「仅函数映射」，无需整改）
  H2 迁移语句不引用 exports 参数、不引用 KEEP 声明的局部变量（分类阶段已分流为纠缠）
  H3 迁移语句不含 return/break/continue
  H4 init 导出名与 C++ 函数名无冲突
  H5 注册风格可识别（描述符数组 / napi_set_named_property / BindNativeFunction）
  H6 注册回调可定位且函数体可完整提取（--callback / --at-line / nm_register_func）
  H7 改写后自校验：花括号配平、迁移语句零丢失、回调区零残留、init 挂载就位

策略边界（重要）：
  - 应用工程内模块（nm_modname == "entry" / libentry.so）：调用方在同工程，
    策略 E（显式 init）安全，JS 侧同步修改（--js-root 定位调用点）。
  - 系统/公共 kit（@ohos.* 消费者任意）：显式 init() 是 API 兼容性破坏——
    输出兼容性警示，建议改用策略 L（apply_lazy_init.py，不改 API）或版本演进评估。

Usage:
  python3 apply_init_extraction.py <文件> [--callback <名> | --at-line <行>]
      [--init-name init] [--func-name ExplicitInit] [--root <仓库根>]
      [--check] [--list] [--apply] [--js-root <ArkTS目录>]
"""
import argparse
import difflib
import os
import re
import subprocess
import sys

# ---------- 注册回调定位 ----------
CB_FIELD_RE = re.compile(r'nm_register_func\s*=\s*(\w+)')
FUNC_DEF_RE = re.compile(
    r'\b(?:static\s+)?napi_value\s+(\w+)\s*\(\s*napi_env\s+(\w+)\s*,\s*'
    r'napi_value\s+(\w+)')

# ---------- KEEP 判定（导出面构建，rulebook S-03 / M-23）----------
EXPORTS_API_RE = re.compile(
    r'\bnapi_(property_descriptor|define_properties|create_function|define_class|'
    r'set_named_property|wrap|unwrap|get_cb_info|create_object|create_reference|'
    r'delete_reference|create_string_utf8|create_int32|create_uint32|create_double|'
    r'create_int64|create_bigint_int64|create_bigint_uint64|get_undefined|get_null|'
    r'get_boolean|get_element|set_element|create_array|create_array_with_length|'
    r'create_external|create_date|create_error|create_symbol|object_freeze|'
    r'get_named_property)\b'
    r'|\bDECLARE_NAPI\w*\b|\bNAPI_CALL\b|\bBindNativeFunction\b'
    r'|\bGET_CB_INFO_AND_CALL\b|\bNapiUtils::Create\w+\b')
LOG_RE = re.compile(r'\b(TAG_LOG\w*|APP_LOG\w*|HILOG\w*|OH_LOG_Print|LOG_\w+)\s*\(')
RETURN_RE = re.compile(r'^\s*(return\b|//|/\*|\*)')
COMMENT_RE = re.compile(r'^\s*(//|/\*|\*)')
EMPTY_RE = re.compile(r'^\s*$')

# ---------- MOVE 判定（业务动作，rulebook S-02 / M-19）----------
SIGNAL_RE = re.compile(
    r'\b(pthread_create|std::thread|CreateThread|dlopen|dlsym|fopen|ifstream|ofstream|'
    r'getenv|setenv|putenv|connect\s*\(|socket\s*\(|getaddrinfo|sqlite3_open|'
    r'signal\s*\(|sigaction|EventHandler|event_loop|attach_\w*handler|'
    r'napi_set_promise_rejection_callback|atexit|SystemAbilityManagerClient|'
    r'GetSystemAbility|iface_cast|SendRequest|MessageParcel|ffrt::submit\w*|'
    r'std::call_once)\b'
    r'|\b(Register|Set|Add|Subscribe|Attach)\w*(Callback|Listener|Observer|Handler)\s*\('
    r'|\batexit\s*\(')
BIZVERB_RE = re.compile(
    r'^\s*(?:[A-Za-z_][\w:]*::)*\w*'
    r'(Init|Initialize|Create|Register|Subscribe|Attach|Start|Setup|Load|'
    r'Connect|Prepare|Warm|Preload|Enable|Open)\w*\s*\(')
# 形态B：全局赋值（由 apply_lazy_init.py 处理）；=(?!=) 排除 == 比较
GLOBAL_ASSIGN_RE = re.compile(
    r'(?<![A-Za-z0-9_:.>])(g_\w+|[a-zA-Z_]\w*_)'
    r'(?:::\w+)?\s*(\[[^\]]*\])?\s*=(?!=)')
LOCAL_DECL_RE = re.compile(
    r'^\s*(?:static\s+|const\s+|constexpr\s+)*(?:[A-Za-z_][\w:<>]*\s+)+'
    r'[*&\s]*([A-Za-z_]\w*)\s*(\[[^\]]*\])?\s*(=|;)')

KW_WORDS = {'if', 'for', 'while', 'switch', 'return', 'else', 'do', 'napi_env',
            'napi_value', 'static', 'const', 'constexpr', 'auto', 'nullptr',
            'true', 'false', 'sizeof', 'new', 'delete', 'std', 'napi_callback_info'}

# ---------- 框架实现路径黑名单（拒改保护，E-14）----------
# 这些目录的加载期动作属框架自身的生命周期设计（模块管理器/引擎/UI 组件框架），
# 不是业务初始化违规；整改它们属框架演进，须框架负责人评审，本引擎硬拒改。
FRAMEWORK_PATH_BLACKLIST = (
    re.compile(r'(?:^|/)ace_engine/advanced_ui_component/[^/]+/interfaces/'),
    re.compile(r'(?:^|/)arkcompiler/ets_runtime(?:/|$)'),
    re.compile(r'(?:^|/)foundation/arkui/napi/native_engine/'),
    re.compile(r'(?:^|/)foundation/arkui/napi/module_manager/'),
)


def framework_path_refusal(path):
    """路径命中框架黑名单 → 返回命中的模式串；否则 None。"""
    p = os.path.abspath(path).replace('\\', '/')
    for pat in FRAMEWORK_PATH_BLACKLIST:
        if pat.search(p):
            return pat.pattern
    return None


# ---------- 保留信号第三出口（E-15，fix-patterns.md §8.10）----------
# musl 保留段：MUSL_SIGNAL_* = SIGRTMIN+0..+10（third_party/musl/porting/linux/
# user/include/signal.h）；引擎占用实测：ace_engine.cpp:120 sigaction(
# MUSL_SIGNAL_JSHEAP)、watch_dog.cpp:41 `constexpr int32_t SIGNAL_FOR_GC = 60`。
# Linux SIGRTMIN..SIGRTMAX = 34..64，整段视为保留。
SIGCALL_RE = re.compile(r'\b(signal|sigaction)\s*\(\s*([^,()]+?)\s*[,)]')
NAPI_TOUCH_RE = re.compile(r'\bnapi_\w+\b')
STD_SIGNAL_NAMES = {
    'SIGHUP': 1, 'SIGINT': 2, 'SIGQUIT': 3, 'SIGILL': 4, 'SIGTRAP': 5,
    'SIGABRT': 6, 'SIGBUS': 7, 'SIGFPE': 8, 'SIGKILL': 9, 'SIGUSR1': 10,
    'SIGSEGV': 11, 'SIGUSR2': 12, 'SIGPIPE': 13, 'SIGALRM': 14, 'SIGTERM': 15,
}


def resolve_signal_arg(arg, text):
    """解析 signal/sigaction 首参。返回 (kind, desc)：
    kind ∈ reserved（命中保留段）/ plain（可解析且非保留）/ unresolved（不可静态解析）。
    text 为文件全文（用于同文件常量解析，如 SIGNAL_FOR_GC = 60）。"""
    a = arg.strip()
    if re.search(r'\bMUSL_SIGNAL_\w+\b', a):
        return 'reserved', 'musl 保留信号（MUSL_SIGNAL_* = SIGRTMIN+0..+10）'
    if re.fullmatch(r'SIGRTMIN\s*(?:\+\s*\d+\s*)?', a):
        m2 = re.search(r'\+\s*(\d+)', a)
        n = int(m2.group(1)) if m2 else 0
        if n <= 10:
            return 'reserved', 'SIGRTMIN+%d ∈ musl 保留段(+0..+10)' % n
        return 'reserved', 'SIGRTMIN+%d ∈ 实时信号段(SIGRTMIN..SIGRTMAX)' % n
    if re.fullmatch(r'\d+', a):
        n = int(a)
        if n == 60:
            return 'reserved', '字面量 60（watch_dog GC 信号，仓内实测占用）'
        if 34 <= n <= 64:
            return 'reserved', '字面量 %d ∈ 实时信号段 SIGRTMIN(34)..SIGRTMAX(64)' % n
        return 'plain', '字面量 %d ∈ 标准信号段（非 musl/engine 保留）' % n
    if a in STD_SIGNAL_NAMES:
        return 'plain', '%s(%d) 标准信号（可重定向，非保留段）' % (a, STD_SIGNAL_NAMES[a])
    if re.fullmatch(r'[A-Za-z_]\w*', a):
        # 同文件常量解析：constexpr/const X = N；#define X N
        cm = re.search(r'\b(?:const(?:expr)?\s+\w+[^;{}=]*)\b%s\b\s*=\s*(\d+)'
                       % re.escape(a), text)
        if not cm:
            cm = re.search(r'#\s*define\s+%s\s+(\d+)\b' % re.escape(a), text)
        if cm:
            n = int(cm.group(1))
            if 34 <= n <= 64 or n == 60:
                return 'reserved', '%s = %d（同文件解析，实时信号段）' % (a, n)
            return 'plain', '%s = %d（同文件解析，非保留段）' % (a, n)
        return 'unresolved', a
    return 'unresolved', a



# ==================== 回调定位与语句解析 ====================

def find_brace_end(lines, start_idx):
    """start_idx 指向含 '{' 的行。返回闭括号所在行索引（含），失败 -1。"""
    depth = 0
    for i in range(start_idx, len(lines)):
        depth += lines[i].count('{') - lines[i].count('}')
        if depth <= 0 and i >= start_idx:
            return i
    return -1


def _accumulate(lines, i, stmt_start):
    """从行 i 起累积一条语句（到花括号深度归零且行尾 ';' 或 '}'）。"""
    depth = 0
    j = i
    while j < len(lines):
        ln = lines[j]
        depth += ln.count('{') - ln.count('}')
        s = ln.strip()
        if depth <= 0 and (s.endswith(';') or s == '}'):
            break
        j += 1
    seg = lines[stmt_start:j + 1]
    return {'start': stmt_start, 'end': j, 'lines': seg, 'text': '\n'.join(seg)}


def split_statements(lines):
    """把函数体行序列切成顶层语句块（前导注释/空行附着到其后语句）。"""
    stmts = []
    i = 0
    n = len(lines)
    while i < n:
        s = lines[i].strip()
        if not s or COMMENT_RE.match(s) or s == '{' or s == '}':
            i += 1
            continue
        stmt_start = i
        # 回溯收集紧邻前导注释（连续 // 行）
        k = i - 1
        while k >= 0 and lines[k].strip().startswith('//'):
            stmt_start = k
            k -= 1
        stmt = _accumulate(lines, i, stmt_start)
        stmts.append(stmt)
        i = stmt['end'] + 1
    return stmts


def parse_callback(text, cb_name):
    """按名定位 (napi_env, napi_value) 函数。返回 dict 或 None。"""
    lines = text.split('\n')
    for i, ln in enumerate(lines):
        m = FUNC_DEF_RE.search(ln)
        if m and m.group(1) == cb_name:
            env_name, exports_name = m.group(2), m.group(3)
            j = i
            while j < len(lines) and '{' not in lines[j]:
                if lines[j].strip().endswith(';'):      # 原型声明
                    break
                j += 1
            if j >= len(lines) or '{' not in lines[j]:
                continue
            end = find_brace_end(lines, j)
            if end < 0 or end == j:                      # 空函数体 {} 也接受（end==j）
                if end < 0:
                    continue
            return {'name': cb_name, 'def_line': i, 'open_line': j, 'close_line': end,
                    'env': env_name, 'exports': exports_name,
                    'body_lines': lines[j + 1:end],
                    'lines': lines}
    return None


def find_register_callbacks(text):
    """文件中全部 nm_register_func 目标函数名。"""
    return CB_FIELD_RE.findall(text)


def all_env_exports_funcs(text):
    """文件中全部 (napi_env, napi_value) 签名函数（注册回调候选）。"""
    out = []
    for m in FUNC_DEF_RE.finditer(text):
        cb = parse_callback(text, m.group(1))
        if cb:
            out.append(cb)
    return out


def resolve_callback(text, args):
    """回调解析顺序：--callback > --at-line（行所在函数，多行逐个尝试）
    > nm_register_func 首个。"""
    named = find_register_callbacks(text)
    if args.callback:
        cb = parse_callback(text, args.callback)
        if not cb:
            return None, '❌ 回调 %s 定位/提取失败（H6）' % args.callback
        return cb, None
    if args.at_line is not None:
        at_lines = []
        for part in str(args.at_line).split(','):
            part = part.strip()
            if part:
                try:
                    at_lines.append(int(part))
                except ValueError:
                    pass
        warns = []
        for ln in at_lines:
            for name in named:                              # 优先注册回调
                cb = parse_callback(text, name)
                if cb and cb['open_line'] + 1 <= ln <= cb['close_line'] + 1:
                    return cb, None
            for cb in all_env_exports_funcs(text):          # 跨文件注册（模块结构在别处）
                if cb['open_line'] + 1 <= ln <= cb['close_line'] + 1:
                    if cb['name'] in named:
                        return cb, None
                    return cb, ('⚠️ 行 %d 位于函数 `%s`（本文件无 nm_register_func——'
                                '跨文件注册或辅助函数，已按该函数处理，请核对）'
                                % (ln, cb['name']))
            warns.append(ln)
        return None, ('❌ 行 %s 不在任何 (napi_env, napi_value) 函数内（H6）——'
                      '可能位于被调辅助函数体（由回调经调用链触达），转人工'
                      % '、'.join(str(w) for w in warns))
    if named:
        cb = parse_callback(text, named[0])
        if cb:
            return cb, None
        return None, '❌ 回调 %s 定位/提取失败（H6）' % named[0]
    return None, '❌ 未找到 nm_register_func（H6）——用 --callback 显式指定'


# ==================== 语句分类 ====================

def resolve_callee_body(text, stmt_text):
    """对语句中被调函数（同文件定义）定位其函数体文本。返回 [(name, body_text)]。"""
    callees = []
    for m in re.finditer(r'\b([A-Za-z_]\w*(?:::[A-Za-z_]\w+)*)\s*\(', stmt_text):
        name = m.group(1)
        base = name.split('::')[-1]
        if base in ('if', 'for', 'while', 'switch', 'sizeof', 'return'):
            continue
        dm = re.search(r'\b(?:static\s+|inline\s+|void\s+|napi_value\s+|bool\s+|int\s+)?'
                       r'(?:[A-Za-z_][\w:]*\s+)*\b' + re.escape(base) +
                       r'\s*\([^;{]*\)\s*(?:const\s*)?\{', text)
        if dm:
            frag = text[dm.end() - 1:]
            sub = frag.split('\n')
            e = find_brace_end(sub, 0)
            if e > 0:
                callees.append((name, '\n'.join(sub[:e + 1])))
    return callees


def callee_is_exports_helper(callee_bodies):
    """被调函数体只含 napi 面 API 且无业务信号 → 导出面构建辅助。"""
    for _, body in callee_bodies:
        if SIGNAL_RE.search(body):
            return False
        if not EXPORTS_API_RE.search(body):
            return False
    return bool(callee_bodies)


def extract_local_names(stmts):
    """从语句行中提取局部变量名（声明形）。"""
    names = set()
    for st in stmts:
        for ln in st['lines']:
            dm = LOCAL_DECL_RE.match(ln)
            if dm and dm.group(1) not in KW_WORDS:
                names.add(dm.group(1))
    return names


def ident_tokens(text):
    return set(re.findall(r'\b[A-Za-z_]\w*\b', text))


def classify_callback(text, cb):
    """语句级分类。返回 (stmts, stat)。stmts[i] 含 cls/note。"""
    env, exp = cb['env'], cb['exports']
    stmts = split_statements(cb['body_lines'])
    for st in stmts:                                   # 绝对行号（1 基）
        st['abs'] = st['start'] + cb['open_line'] + 2
    exports_arg_re = re.compile(
        r'\(\s*[^()]*\b' + re.escape(exp) + r'\b[^()]*\)')

    # ---- 第一遍：锚定分类 ----
    for st in stmts:
        s = st['text'].strip()
        st['cls'] = '?'
        st['note'] = ''
        if not s or RETURN_RE.match(s):
            st['cls'], st['note'] = 'KEEP', '空行/注释/return'
            continue
        if re.match(r'^\s*if\s*\(\s*(?:' + re.escape(env) + r'|' + re.escape(exp) +
                    r')\s*==\s*(?:nullptr|NULL)', s):
            st['cls'], st['note'] = 'KEEP', 'env/exports 判空守卫'
            continue
        if EXPORTS_API_RE.search(s):
            st['cls'], st['note'] = 'KEEP', 'napi 导出面 API'
            continue
        if LOG_RE.search(s):
            st['cls'], st['note'] = 'KEEP', '日志'
            continue
        if exports_arg_re.search(s):
            st['cls'], st['note'] = 'KEEP', '实参含 %s（导出面构建惯用法）' % exp
            continue
        if GLOBAL_ASSIGN_RE.search(s):
            st['cls'], st['note'] = 'SKIP_FORMB', '全局赋值（类别2/形态B，由 apply_lazy_init.py 处理）'
            continue
        if SIGNAL_RE.search(s):
            st['cls'], st['note'] = 'MOVE?', 'M-19 信号命中'
            continue
        if BIZVERB_RE.match(s):
            st['cls'], st['note'] = 'MOVE?', '业务动词族命中'
            continue
        st['note'] = '未命中锚点（保守保留）'

    # ---- exports 数据流：KEEP 语句引用的局部名 → 引用它的语句也 KEEP ----
    locals_all = extract_local_names(stmts)
    flow = set()
    for st in stmts:
        if st['cls'] == 'KEEP':
            flow |= (ident_tokens(st['text']) & locals_all)
    flow.discard(env)
    flow.discard(exp)
    for st in stmts:
        if st['cls'] in ('KEEP', 'SKIP_FORMB'):
            continue
        prev = st['cls']
        inter = ident_tokens(st['text']) & flow
        if inter:
            st['cls'] = 'KEEP'
            if prev == 'MOVE?' or 'MOVE' in st['note']:
                st['note'] = ('引用导出面数据流局部变量 %s（纠缠）——需人工整改'
                              % ','.join(sorted(inter)))
            else:
                st['note'] = '引用导出面数据流局部变量 %s（挂载对象构建）' % \
                    ','.join(sorted(inter))

    # ---- 被调函数体检查：同文件可解析且只含 napi 面 API → KEEP ----
    for st in stmts:
        if st['cls'] != 'MOVE?':
            continue
        callees = resolve_callee_body(text, st['text'])
        if callees and callee_is_exports_helper(callees):
            st['cls'] = 'KEEP'
            st['note'] = '被调函数 %s（同文件）只含 napi 面 API——导出面构建辅助' % \
                ','.join(n for n, _ in callees)
        elif callees:
            st['cls'] = 'MOVE'
            st['note'] += '；被调体（同文件）无导出面 API/含业务信号'

    # ---- MOVE? → 终判（H3 控制流 / 形态B 路由）----
    for st in stmts:
        if st['cls'] != 'MOVE?':
            continue
        s = st['text']
        if re.search(r'\b(return|break|continue)\b', s):
            st['cls'] = 'KEEP'
            st['note'] = '含控制流关键字（H3）——不迁移'
            continue
        if GLOBAL_ASSIGN_RE.search(s):
            st['cls'] = 'SKIP_FORMB'
            st['note'] = '语句/块含全局赋值（类别2/形态B，由 apply_lazy_init.py 处理）'
            continue
        st['cls'] = 'MOVE'

    # ---- 纠缠簇阻断：MOVE 语句声明的局部变量被回调内其他语句引用 → 降级保留 ----
    # （只迁声明会留下悬空引用——编译失败；整簇迁移含非业务语句风险高，转人工）
    move_local_owner = {}
    for st in stmts:
        if st['cls'] == 'MOVE':
            for name in extract_local_names([st]):
                move_local_owner[name] = st
    if move_local_owner:
        for st in stmts:
            if st['cls'] == 'MOVE':
                continue
            inter = ident_tokens(st['text']) & set(move_local_owner)
            for name in sorted(inter):
                owner = move_local_owner[name]
                if owner['cls'] == 'MOVE':
                    owner['cls'] = 'KEEP'
                    owner['note'] = ('纠缠簇：声明的局部变量 %s 被回调内其他语句'
                                     '（L%d 起）引用——整簇人工迁移' % (name, st['abs']))

    # ---- 保留信号第三出口（E-15）：MOVE 语句注册信号 → 按信号号可解析性分流 ----
    # reserved：命中引擎/musl 保留段 → 不迁移（降级保留），转设计评审；
    # plain：可解析且非保留段 → 保持 MOVE，附轻量提示；
    # unresolved：不可静态解析 → 保持 MOVE，主流程输出显著警示 + ArkTS 冲突核对义务。
    for st in stmts:
        if st['cls'] != 'MOVE':
            continue
        for m in SIGCALL_RE.finditer(st['text']):
            fn, arg = m.group(1), m.group(2)
            kind, desc = resolve_signal_arg(arg, text)
            if kind == 'reserved':
                st['cls'] = 'KEEP'
                st['sig_reserved'] = True
                st['note'] = ('保留信号第三出口：`%s(%s)`（%s）命中引擎/musl 保留信号——'
                              '迁移会改变注册时点并与运行时争用同一信号，不迁移；'
                              '转设计评审「谁有权注册这个信号」（fix-patterns.md §8.10）'
                              % (fn, arg.strip(), desc))
                break
            if kind == 'unresolved':
                st['sig_unresolved'] = True
                st['note'] += ('；含 %s(%s)——信号号不可静态解析，迁移后须人工'
                               '核对信号冲突（fix-patterns.md §8.10）' % (fn, arg.strip()))
            else:
                st['note'] += ('；含 %s(%s)（%s）——迁移改变注册时点，确认无跨组件'
                               '同信号注册' % (fn, arg.strip(), desc))

    stat = {}
    for st in stmts:
        stat[st['cls']] = stat.get(st['cls'], 0) + 1
    return stmts, stat


# ==================== 注册风格与改写 ====================

DESC_ARRAY_RE = re.compile(r'\bnapi_property_descriptor\s+\w+\s*\[\s*\]\s*=')
BIND_RE = re.compile(r'\bBindNativeFunction\s*\(\s*(\w+)\s*,\s*(\w+)\s*,\s*"'
                     r'([^"]+)"\s*,\s*(\w+)\s*,')
SET_NP_RE = re.compile(r'\bnapi_set_named_property\s*\(')


def detect_reg_style(cb):
    """返回 'desc-array' | 'bind' | 'set-named' | None。"""
    t = '\n'.join(cb['body_lines'])
    if DESC_ARRAY_RE.search(t):
        return 'desc-array'
    if BIND_RE.search(t):
        return 'bind'
    if SET_NP_RE.search(t):
        return 'set-named'
    return None


def ensure_mutex_include(new_lines):
    """新函数使用 std::once_flag/std::call_once 时确保 <mutex> 已包含。"""
    body = '\n'.join(new_lines)
    if re.search(r'\bstd::(once_flag|call_once)\b', body) and \
            not re.search(r'#include\s*<mutex>', body):
        last = max(i for i, ln in enumerate(new_lines)
                   if ln.strip().startswith('#include'))
        return new_lines[:last + 1] + ['#include <mutex>'] + new_lines[last + 1:]
    return new_lines


def build_rewrite(lines, cb, stmts, func_name, init_name, comment_lines,
                  wrap_once=True):
    """生成改写。返回 (new_lines, move_stmts, info) 或 (None, [], 失败原因)。"""
    move_stmts = [st for st in stmts if st['cls'] == 'MOVE']
    if not move_stmts:
        return None, [], '无可迁移语句（H1）'

    style = detect_reg_style(cb)
    if style is None:
        return None, [], '注册风格不可识别（H5）——人工挂载 init 导出'

    drop = set()
    for st in move_stmts:
        drop.update(range(st['start'], st['end'] + 1))
    new_cb_body = [ln for i, ln in enumerate(cb['body_lines']) if i not in drop]

    env, exp = cb['env'], cb['exports']
    if style == 'desc-array':
        out, depth, in_arr, inserted = [], 0, False, False
        for ln in new_cb_body:
            if not inserted and DESC_ARRAY_RE.search(ln):
                in_arr = True
            if in_arr and not inserted:
                if ln.strip().endswith('};') and ln.count('{') < ln.count('}'):
                    out.append('        DECLARE_NAPI_FUNCTION("%s", %s),'
                               % (init_name, func_name))
                    inserted = True
                    in_arr = False
                    out.append(ln)
                    continue
                depth += ln.count('{') - ln.count('}')
                out.append(ln)
                continue
            out.append(ln)
        if not inserted:
            return None, [], '描述符数组挂载点未找到（H5）'
        new_cb_body = out
        mount_note = 'DECLARE_NAPI_FUNCTION("%s", %s) 已加入描述符数组' % (init_name, func_name)
    elif style == 'bind':
        m = BIND_RE.search('\n'.join(new_cb_body))
        if not m:
            return None, [], 'BindNativeFunction 挂载点未找到（H5）'
        bind_line = '    BindNativeFunction(%s, %s, "%s", %s, %s);' % (
            m.group(1), m.group(2), init_name, m.group(4), func_name)
        # 插到最后一个 BindNativeFunction 语句的完整结尾（语句可跨行，以 ';' 收尾）
        last_bind = max(i for i, ln in enumerate(new_cb_body)
                        if 'BindNativeFunction' in ln)
        j = last_bind
        while j < len(new_cb_body) and not new_cb_body[j].strip().endswith(';'):
            j += 1
        new_cb_body = (new_cb_body[:j + 1] + [bind_line]
                       + new_cb_body[j + 1:])
        mount_note = 'BindNativeFunction("%s", %s) 已挂载' % (init_name, func_name)
    else:  # set-named
        block = [
            '    napi_value %sFn = nullptr;' % init_name,
            '    napi_create_function(%s, "%s", NAPI_AUTO_LENGTH, %s, nullptr, &%sFn);'
            % (env, init_name, func_name, init_name),
            '    napi_set_named_property(%s, %s, "%s", %sFn);'
            % (env, exp, init_name, init_name),
        ]
        ret_idx = None
        for i, ln in enumerate(new_cb_body):
            if ln.strip().startswith('return'):
                ret_idx = i
                break
        if ret_idx is None:
            return None, [], 'return 挂载点未找到（H5）'
        new_cb_body = new_cb_body[:ret_idx] + block + new_cb_body[ret_idx:]
        mount_note = 'napi_create_function + napi_set_named_property("%s") 已挂载' % init_name

    moved = []
    for st in move_stmts:
        moved.extend(st['lines'])
    new_func = list(comment_lines)
    new_func.append('static napi_value %s(napi_env env, napi_callback_info info)' % func_name)
    new_func.append('{')
    if wrap_once:
        # 原语义：加载期恰好执行一次。迁为显式接口后，用 call_once 保持
        # 「恰好一次」（幂等 + 并发首调安全）。--no-once 可关闭。
        new_func.append('    static std::once_flag onceFlag;')
        new_func.append('    std::call_once(onceFlag, [&] {')
        moved_indented = [('    ' + ln) if ln.strip() else ln for ln in moved]
        new_func.extend(moved_indented)
        new_func.append('    });')
    else:
        new_func.extend(moved)
    new_func.append('')
    new_func.append('    napi_value result = nullptr;')
    new_func.append('    napi_get_undefined(env, &result);')
    new_func.append('    return result;')
    new_func.append('}')
    new_func.append('')

    out = []
    out.extend(lines[:cb['def_line']])
    out.extend(new_func)
    out.extend(lines[cb['def_line']:cb['open_line'] + 1])
    out.extend(new_cb_body)
    out.extend(lines[cb['close_line']:])
    if wrap_once:
        out = ensure_mutex_include(out)
    info = {'style': style, 'mount_note': mount_note, 'new_cb_body': new_cb_body,
            'new_func': new_func, 'func_name': func_name, 'wrap_once': wrap_once}
    return out, move_stmts, info


# ==================== 校验与辅助 ====================

def check_syntax(path, extra_inc=None):
    for cc in ('clang++', 'g++'):
        if subprocess.run(['which', cc], capture_output=True).returncode == 0:
            cmd = [cc, '-fsyntax-only', '-std=c++17', '-x', 'c++', path]
            for inc in (extra_inc or []):
                cmd += ['-I', inc]
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            err = r.stdout + r.stderr
            # 只统计真正的 error: 诊断行（忽略插入符号上下文/note/警告）；
            # 缺系统头文件（OHOS 环境）视为环境限制
            real = [l for l in err.splitlines()
                    if re.match(r'^\S+:\d+:\d+: error:', l)
                    and 'file not found' not in l]
            if r.returncode == 0 and not real:
                return True, '✔ 语法检查通过（%s）' % cc
            if real:
                return False, '❌ 语法错误：\n' + '\n'.join(real[:12])
            if 'file not found' in err or 'fatal error' in err:
                return True, '⚠️ 仅头文件缺失（环境限制），改写局部语法未见错误（%s）' % cc
            return None, '⚠️ 语法检查异常输出（%s）\n%s' % (cc, err[:400])
    return None, '跳过语法检查（无 clang++/g++）'


def find_js_callers(js_root, modname):
    """在 ArkTS 目录中定位模块 import 点（init() 集成指引用）。"""
    hits = []
    lib = 'libentry.so' if modname == 'entry' else None
    for dirpath, _, files in os.walk(js_root):
        if any(x in dirpath for x in ('node_modules', 'oh_modules', '.hvigor')):
            continue
        for f in files:
            if not f.endswith(('.ets', '.ts')):
                continue
            p = os.path.join(dirpath, f)
            try:
                text = open(p, encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            for i, ln in enumerate(text.split('\n'), 1):
                if lib and ("from '%s'" % lib) in ln:
                    hits.append((p, i, ln.strip()))
                elif modname and modname != 'entry' and \
                        ("'@ohos.%s'" % modname.split('.')[0]) in ln:
                    hits.append((p, i, ln.strip()))
    return hits


def _modname(text):
    m = re.search(r'nm_modname\s*=\s*"([^"]+)"', text)
    return m.group(1) if m else None


def _import_var(ln):
    m = re.search(r'import\s+(\w+)\s+from', ln)
    return m.group(1) if m else '<模块对象>'


def _manual_guidance(entangled, formb):
    if entangled:
        print('### 人工整改指引（纠缠/未知语句）')
        for st in entangled:
            first = st['lines'][0].strip() if st['lines'] else ''
            print('- L%d `%s`：%s' % (st.get('abs', st['start']), first[:76], st['note']))
        print('  → 依赖 exports 挂载对象的初始化（如 napi_wrap 对象的成员方法调用）：'
              '把该逻辑移入首个业务导出函数内部，用 std::call_once 或双检锁'
              '（DCLP + std::atomic）惰性创建——禁止裸判空（if (p == nullptr) 无锁，'
              '并发首调会重复创建/竞态）；或移入 init() 实现内以不依赖 exports 的'
              '方式重建——见 fix-patterns.md §9。')
        print()
    if formb:
        print('### 形态B 提示')
        print('- 全局赋值块归 apply_lazy_init.py（策略 L，不改 JS 侧）：'
              '`python3 apply_lazy_init.py <文件> --var <变量名> --apply`')
        print('- 如需整体并入 init()：人工把守卫块整体迁入 init() 实现，'
              '以 std::call_once 保证幂等与并发首调安全（禁止裸判空）。')
        print()


# ==================== 主流程 ====================

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('file')
    ap.add_argument('--callback', default=None,
                    help='注册回调函数名（默认从 nm_register_func 解析）')
    ap.add_argument('--at-line', type=str, default=None,
                    help='按扫描产出行号定位回调（可逗号分隔多个，逐个尝试：'
                         '取包含该行的 (napi_env, napi_value) 函数）')
    ap.add_argument('--init-name', default='init', help='JS 导出名（默认 init）')
    ap.add_argument('--func-name', default=None, help='C++ 函数名（默认自动生成）')
    ap.add_argument('--root', default=None, help='仓库根（保留参数，与引擎 L 对齐）')
    ap.add_argument('--check', action='store_true', help='写入前 -fsyntax-only 检查')
    ap.add_argument('--list', action='store_true', help='仅输出语句分类表')
    ap.add_argument('--apply', action='store_true', help='写入（默认 dry-run）')
    ap.add_argument('--no-once', action='store_true',
                    help='不包 call_once（默认包裹：迁移语句在 init() 内恰好执行一次，'
                         '幂等且并发首调安全）')
    ap.add_argument('--js-root', default=None, help='ArkTS 源码根（定位 init() 调用点）')
    args = ap.parse_args()

    path = args.file
    if not os.path.isfile(path):
        print('❌ 文件不存在：%s' % path, file=sys.stderr)
        sys.exit(1)
    blacklist = framework_path_refusal(path)
    if blacklist:
        print('❌ 框架实现路径拒改（E-14 黑名单命中：%s）' % blacklist, file=sys.stderr)
        print('   该路径属框架自身实现（ArkUI 高级组件接口 / ArkTS 运行时 / NAPI 引擎 /'
              ' 模块管理器）。其加载期动作是框架生命周期设计的一部分（如 ace_engine 的'
              ' JS 堆转储信号注册、模块管理器的 napi_onLoad 时序），按业务整改模型迁移'
              ' 会改变框架行为。', file=sys.stderr)
        print('   目标应为业务模块（applications/** 或各子系统 interfaces/kits、'
              'frameworks 下的 NAPI 模块）；框架路径如需整改，走框架演进评审。',
              file=sys.stderr)
        sys.exit(4)
    text = open(path, encoding='utf-8', errors='replace').read()
    lines = text.split('\n')

    cb, warn = resolve_callback(text, args)
    if warn:
        print(warn)
    if cb is None:
        sys.exit(2)

    stmts, stat = classify_callback(text, cb)
    print('## 场景2（类别1）整改分析 — %s' % os.path.basename(path))
    print()
    print('- 注册回调：`%s`（定义 L%d，体 L%d–L%d；env=%s, exports=%s）'
          % (cb['name'], cb['def_line'] + 1, cb['open_line'] + 1,
             cb['close_line'] + 1, cb['env'], cb['exports']))
    print('- 模块名（nm_modname）：%s' % (_modname(text) or '（本文件未定义——跨文件注册）'))
    print('- 语句分类：MOVE(迁入 init) × %d、KEEP(导出面) × %d、'
          'SKIP_FORMB(归类别2引擎) × %d、未命中保留 × %d'
          % (stat.get('MOVE', 0), stat.get('KEEP', 0),
             stat.get('SKIP_FORMB', 0), stat.get('?', 0)))
    print()
    print('| 行 | 分类 | 语句 | 依据 |')
    print('|---|---|---|---|')
    for st in stmts:
        first = st['lines'][0].strip() if st['lines'] else ''
        print('| L%d | %s | `%s` | %s |' % (st['abs'], st['cls'],
                                            first[:72].replace('|', '\\|'),
                                            st['note']))
    print()

    # ---- 保留信号第三出口 / 未解析信号警示（E-15）----
    sig_reserved = [st for st in stmts if st.get('sig_reserved')]
    sig_unresolved = [st for st in stmts if st.get('sig_unresolved')]
    if sig_reserved or sig_unresolved:
        print('## 保留信号第三出口（signal/sigaction 语句）')
        print()
        for st in sig_reserved:
            first = next((ln.strip() for ln in st['lines'] if ln.strip()), '')
            print('- L%d `%s`：已降级保留（不迁移）——引擎/musl 保留信号段的注册权'
                  '属框架，迁移会改变注册时点并与运行时争用同一信号。'
                  % (st['abs'], first[:70]))
        if sig_reserved:
            print('  → 处置：转设计评审「谁有权注册这个信号」——保留在注册回调、'
                  '改注册时机、还是由框架统一接管，是设计决策而非机械整改'
                  '（fix-patterns.md §8.10，含仓内实测锚点）。')
        for st in sig_unresolved:
            first = next((ln.strip() for ln in st['lines'] if ln.strip()), '')
            print('- ⚠️ L%d `%s`：保持 MOVE，但信号号不可静态解析（变量/宏/系统头'
                  '定义）——无法排除与 musl 保留段（SIGRTMIN+0..+10，Linux 实时信号段'
                  ' 34..64）或框架信号的冲突。' % (st['abs'], first[:70]))
        if sig_unresolved:
            print('  → 义务：① 迁移后该注册时点从 import 变为 %s() 首调；'
                  '② ArkTS 侧确认同进程无系统组件注册同一信号（冲突即静默互相覆盖，'
                  '难排查）——见 fix-patterns.md §8.10。' % args.init_name)
        print()

    if args.list:
        return

    move_stmts = [st for st in stmts if st['cls'] == 'MOVE']
    entangled = [st for st in stmts
                 if '纠缠' in st.get('note', '') or st['cls'] == '?']
    formb = [st for st in stmts if st['cls'] == 'SKIP_FORMB']

    # ---- 闸门 ----
    gates = []
    if move_stmts:
        gates.append(('H1', True, '可迁移语句 × %d' % len(move_stmts)))
    elif sig_reserved:
        gates.append(('H1', False,
                      '无可迁移语句——保留信号语句已降级保留（见「保留信号第三出口」段，'
                      '转设计评审）'))
    else:
        gates.append(('H1', False,
                      '无可迁移语句——回调已是「仅函数映射」或全部纠缠/属类别2'))
    gates.append(('H6', True, '回调定位与函数体提取成功'))
    h2_fail = [st for st in move_stmts if re.search(r'\b' + re.escape(cb['exports']) + r'\b',
                                                    st['text'])]
    if h2_fail:
        gates.append(('H2', False, '迁移语句引用 %s（L%d 等）'
                      % (cb['exports'], h2_fail[0]['abs'])))
    else:
        gates.append(('H2', True, '迁移语句不引用 exports/KEEP 局部（纠缠项已分流保留）'))
    if entangled:
        gates.append(('H2*', None, '纠缠/未知语句 × %d（保留原位，输出人工指引）'
                      % len(entangled)))
    if formb:
        gates.append(('FORMB', None, '形态B 语句/块 × %d → 先由 apply_lazy_init.py 处理'
                      % len(formb)))

    func_name = args.func_name
    if not func_name:
        base = 'ExplicitInit'
        cand, k = base, 1
        while re.search(r'\b' + cand + r'\b', text):
            k += 1
            cand = base + str(k)
        func_name = cand
    conflict = (re.search(r'\b' + re.escape(func_name) + r'\b', text) and
                'C++ 函数名 `%s` 已存在' % func_name) or \
               (re.search(r'"' + re.escape(args.init_name) + r'"', text) and
                '导出名 `"%s"` 已存在' % args.init_name)
    if conflict and not (args.func_name or args.init_name != 'init'):
        alt = [a for a in ('init', 'initModule', 'moduleInit', 'lazyInit')
               if not re.search(r'"' + a + r'"', text)]
        if alt:
            args.init_name = alt[0]
            gates.append(('H4', True, '导出名冲突已自动改用 "%s"' % args.init_name))
            conflict = None
    gates.append(('H4', not conflict, conflict or
                  '导出名 "%s" / 函数名 `%s` 无冲突' % (args.init_name, func_name)))

    style = detect_reg_style(cb)
    gates.append(('H5', style is not None,
                  '注册风格：%s' % (style or '不可识别（人工挂载）')))

    ok_all = all(g[1] for g in gates if g[1] is not None)
    print('## 安全闸门')
    print()
    for gid, ok, msg in gates:
        mark = '✔' if ok else ('⚠️' if ok is None else '❌')
        print('- %s %s %s' % (mark, gid, msg))
    print()

    modname = _modname(text)
    if modname and modname != 'entry' and '.' in modname:
        print('⚠️ API 兼容性警示：模块 `%s` 为系统/公共 kit——显式 init() 属 API 变更，'
              '既有调用方（任意应用）不会调用 init()。建议：改用策略 L'
              '（apply_lazy_init.py，不改 API），或在版本演进中引入 init() 并保留'
              '惰性兜底。本次仍可继续改写（工程内部消费场景）。' % modname)
        print()

    if not ok_all:
        print('❌ 安全闸门未通过——拒绝改写。')
        _manual_guidance(entangled, formb)
        sys.exit(3)

    # ---- 生成改写 ----
    comment_lines = [
        '// 业务初始化（原位于注册回调 %s L%d——类别1：注册函数违规业务逻辑）。'
        % (cb['name'], cb['open_line'] + 1),
        '// 由 ArkTS 侧在首次调用本模块其他接口前显式调用一次 %s()。' % args.init_name,
    ]
    wrap_once = not args.no_once
    new_lines, moved, info = build_rewrite(lines, cb, stmts, func_name,
                                           args.init_name, comment_lines,
                                           wrap_once=wrap_once)
    if new_lines is None:
        print('❌ 改写生成失败：%s' % info)
        _manual_guidance(entangled, formb)
        sys.exit(3)

    # ---- 自校验（H7）----
    bal_before = text.count('{') - text.count('}')
    new_text = '\n'.join(new_lines)
    bal_after = new_text.count('{') - new_text.count('}')
    new_cb_set = set(ln.strip() for ln in info['new_cb_body'] if ln.strip())
    new_func_set = set(ln.strip() for ln in info['new_func'] if ln.strip())

    def _lines_in(st, line_set):
        return all(ln.strip() in line_set for ln in st['lines'] if ln.strip())

    lost = [st['abs'] for st in moved if not _lines_in(st, new_func_set)]
    residue = [st['abs'] for st in moved if _lines_in(st, new_cb_set)]
    checks = [
        ('花括号配平', bal_before == bal_after,
         'before %d / after %d' % (bal_before, bal_after)),
        ('迁移语句零丢失', not lost, '丢失 %d 条' % len(lost)),
        ('回调区零残留', not residue, '残留 %d 条' % len(residue)),
        ('init 挂载就位', ('"%s"' % args.init_name) in '\n'.join(info['new_cb_body']),
         '回调体内导出名引用已存在'),
    ]
    if wrap_once:
        checks.append(('call_once 包装就位',
                       'std::call_once(onceFlag' in '\n'.join(info['new_func']),
                       'once_flag 包装 + <mutex> 包含检查'))
        checks.append(('<mutex> 包含',
                       bool(re.search(r'#include\s*<mutex>', new_text)),
                       'std::call_once 需 <mutex>（自动插入或原已包含）'))
    print('## 改写自校验（H7）')
    print()
    for name, ok, detail in checks:
        print('- %s %s（%s）' % ('✔' if ok else '❌', name, detail))
    print()
    if not all(c[1] for c in checks):
        print('❌ 自校验未通过——拒绝写入。')
        sys.exit(5)

    print('## 改写方案')
    print()
    print('- %s' % info['mount_note'])
    print('- 新函数 `%s`（含迁移语句 × %d）插入于回调 `%s` 之前'
          % (func_name, len(moved), cb['name']))
    for st in moved:
        first = next((ln.strip() for ln in st['lines'] if ln.strip()), '')
        print('  - L%d `%s`' % (st['abs'], first[:80]))
    print()
    print('## diff（dry-run，未写入）')
    print()
    diff = difflib.unified_diff(lines, new_lines,
                                fromfile='a/' + os.path.basename(path),
                                tofile='b/' + os.path.basename(path), lineterm='')
    print('\n'.join(list(diff)[:240]))

    # ---- JS 集成 ----
    print()
    print('## ArkTS 侧集成（必做——否则业务功能不会初始化）')
    print()
    js_hits = []
    if args.js_root and os.path.isdir(args.js_root):
        js_hits = find_js_callers(args.js_root, modname or 'entry')
    if js_hits:
        for p, i, ln in js_hits[:10]:
            print('- %s:%d `%s` → 首次调用其他接口前补 `%s.%s()`'
                  % (p, i, ln, _import_var(ln), args.init_name))
    else:
        print('- 未指定 --js-root 或未找到 import 点：请在调用方 ArkTS 中，'
              '首次使用本模块其他接口前调用一次 `%s()`。' % args.init_name)
        if modname == 'entry':
            print("  （应用工程模块：import 形如 `import xxx from 'libentry.so'`）")
    if sig_unresolved:
        print('- ⚠️ 信号义务（本模块迁移了 signal/sigaction 注册且信号号未解析）：'
              '集成 %s() 后核对同进程无系统组件/框架注册同一信号——'
              '冲突会静默互相覆盖（fix-patterns.md §8.10）。' % args.init_name)
    print()

    if entangled or formb:
        _manual_guidance(entangled, formb)

    if not args.apply:
        print('（dry-run：未写入。确认无误后加 --apply。）')
        return

    tmp = path + '.lazyinit.tmp'
    open(tmp, 'w', encoding='utf-8').write(new_text)
    if args.check:
        ok, msg = check_syntax(tmp)
        print(msg)
        if ok is False:
            os.unlink(tmp)
            print('❌ 语法检查未通过——拒绝写入。')
            sys.exit(5)
    os.replace(tmp, path)
    print('✅ 已写入：%s（类别1 → 显式 %s() 导出，新函数 `%s`）'
          % (path, args.init_name, func_name))
    print('文件保持未暂存、未提交状态；提交由用户执行。')


if __name__ == '__main__':
    main()
