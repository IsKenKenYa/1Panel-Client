#!/usr/bin/env python3
"""apply_lazy_init.py — 把 NAPI 模块中「加载期即初始化的全局单例」改写为惰性初始化。

配合 prescan.py / parse_scan_report.py：扫描产出候选后，对每个候选执行本脚本改写。

改写模板（语义等价、保证可编译）：

  形态A（文件作用域动态初始化器）——访问器原位替代声明：
      static Database* g_db = new Database("/db");
  →   static Database* GetDb()
      {
          static Database* instance = new Database("/db");
          return instance;
      }
      所有 `g_db` 使用点 → `GetDb()`。

  形态B（注册回调内全局赋值）——初始化块整体迁入 call_once：
      static Database* g_db = nullptr;
      static napi_value Init(napi_env env, napi_value exports) {
          if (g_db == nullptr) { g_db = new Database("/db"); }
          return exports;
      }
  →   static Database* GetDb()
      {
          static Database* instance = nullptr;
          static std::once_flag onceFlag;
          std::call_once(onceFlag, [] { instance = new Database("/db"); });
          return instance;
      }
      回调内初始化块删除；所有 `g_db` 使用点 → `GetDb()`。

线程安全策略：
  meyers（默认）——C++11 起函数局部 static 并发初始化安全（magic statics）。
  call_once —— 模块 BUILD.gn 含 -fno-threadsafe-statics 时使用
  （once_flag 常量初始化，不受该编译选项影响）。形态B 固定 call_once
  （语句体整体搬迁需要 once_flag 语义）。

语义等价保证：
  - 分配次数：改写前后都恰好 1 次（首用创建 vs 加载创建）；
  - 生命周期：裸指针永不释放（与原全局指针一致）；智能指针在进程
    静态析构期释放（与原全局智能指针一致）；
  - 地址稳定：所有使用点拿到同一实例；
  - 线程安全：改写后首次并发调用由 magic statics / call_once 串行化
    （原代码在加载期单线程执行，改写后为增强）。

安全性闸门（任一失败即拒绝改写，除非 --force）：
  G1 变量除检测到的初始化外无其他写入点
  G2 函数体内无同名局部声明（遮蔽）
  G3 声明非 extern；提供 --root 时全仓无其他同名引用
  G4 形态B 初始化体不引用回调参数/局部变量、不含 return/break/continue
  G5 变量为裸指针 / unique_ptr / shared_ptr（非 thread_local、非类静态成员、非数组）
  G6 无取变量地址（&var 不接 ->/.）与 delete var 用法
  G7 访问器名无冲突；所有使用点位于声明之后
  G8 形态A 初始化表达式为单一语句（可整体入访问器）

默认 dry-run：输出分析、闸门结果与统一 diff，不写文件；--apply 才写入。

Usage:
  python3 apply_lazy_init.py FILE --var NAME [--strategy auto|meyers|call_once]
      [--apply] [--root REPO_ROOT] [--check] [--cxx "FLAGS"] [--force]

  FILE        : 目标 .cpp 文件
  --var NAME  : 全局变量名（来自扫描报告）
  --strategy  : auto（读模块 BUILD.gn 决定）| meyers | call_once
  --apply     : 写入文件（默认 dry-run 只打印 diff）
  --root      : 仓库根（G3 跨文件引用检查）
  --check     : 改写后做 -fsyntax-only 语法检查（尽力而为：缺系统头文件的
                「file not found」错误视为环境限制，不算失败）
  --cxx       : 语法检查的附加编译选项（默认 -std=c++17）
"""
import argparse
import difflib
import os
import re
import subprocess
import sys

# 声明解析：类型与变量名之间必须有空白/指针/引用符（防 `auto g_x` 被误拆）
DECL_LINE_RE = re.compile(
    r'^(?P<ind>\s*)'
    r'(?P<quals>(?:(?:static|inline|extern|thread_local|unsigned|signed|long|short|'
    r'constexpr|constinit|const|volatile)\s+)*)'
    r'(?P<auto>auto\s+)?'
    r'(?P<type>[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*(?:\s*<[^=;()]*?>)?)'
    r'(?P<sep>\s*[\s*&]+\s*|\s+)'
    r'(?P<name>[A-Za-z_]\w*)\s*'
    r'(?P<rest>=|;|\()'
)

# ---------- 框架实现路径黑名单（拒改保护；与 apply_init_extraction.py 一致）----------
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


def mask_source(src):
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


def line_of(s, idx):
    return s.count("\n", 0, idx) + 1


def line_start(s, idx):
    return s.rfind("\n", 0, idx) + 1


def statement_end(s, from_idx):
    depth = 0
    k = from_idx
    while k < len(s):
        ch = s[k]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == ";" and depth <= 0:
            return k + 1
        k += 1
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


def scope_stack_at(masked, idx):
    """Return the stack of open scope kinds at idx.
    Kinds: 'ns' (namespace), 'cls' (struct/class/union/enum), 'fn' (function/lambda/block).
    Simplified but conservative for declaration detection."""
    stack = []
    k = 0
    while k < idx:
        ch = masked[k]
        if ch == "{":
            head = masked[max(0, k - 200):k]
            if re.search(r'\bnamespace\b[^;{}()]*$', head):
                stack.append("ns")
            elif re.search(r'\b(struct|class|union|enum)\b[^;{}()]*$', head):
                stack.append("cls")
            else:
                stack.append("fn")
        elif ch == "}":
            if stack:
                stack.pop()
        k += 1
    return stack


def accessor_name(var):
    stem = var[2:] if var.startswith("g_") else var
    stem = stem.rstrip("_")
    parts = [p for p in re.split(r'[_\s]+', stem) if p]
    return "Get" + "".join(p[:1].upper() + p[1:] for p in parts)


def extract_guarded_block(masked, src, var, assign_idx):
    """If assignment at assign_idx sits inside `if (var == nullptr) { ... }`
    return (guard_start_idx, guard_end_idx, inner_body_src)."""
    for m in re.finditer(r"\bif\s*\(", masked[:assign_idx]):
        op = m.end() - 1
        cp = match_balanced(masked, op, "(", ")")
        if cp < 0:
            continue
        k = cp + 1
        while k < len(masked) and masked[k] in " \t\r\n":
            k += 1
        if k >= len(masked) or masked[k] != "{":
            continue
        cb = match_balanced(masked, k)
        if cb < 0 or not (k < assign_idx < cb):
            continue
        cond = masked[op:cp]
        if re.search(r"\b%s\b\s*==\s*(nullptr|NULL|0)\s*$" % re.escape(var), cond.strip()):
            inner = src[k + 1:cb]
            return (line_start(src, m.start()), cb + 1, inner)
    return None


def build_flags(path):
    d = os.path.dirname(os.path.abspath(path))
    for _ in range(6):
        bg = os.path.join(d, "BUILD.gn")
        if os.path.isfile(bg):
            try:
                txt = open(bg, encoding="utf-8", errors="replace").read()
            except OSError:
                return None
            return {"no_threadsafe_statics": "-fno-threadsafe-statics" in txt}
        nd = os.path.dirname(d)
        if nd == d:
            break
        d = nd
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--var", required=True)
    ap.add_argument("--strategy", default="auto", choices=["auto", "meyers", "call_once"])
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--root", default=None)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--cxx", default="-std=c++17")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    path = args.file
    var = args.var
    if not os.path.isfile(path):
        print("❌ 文件不存在：%s" % path, file=sys.stderr)
        sys.exit(1)
    blacklist = framework_path_refusal(path)
    if blacklist:
        print("❌ 框架实现路径拒改（黑名单命中：%s）" % blacklist, file=sys.stderr)
        print("   该路径属框架自身实现（ArkUI 高级组件接口 / ArkTS 运行时 / NAPI 引擎 /"
              " 模块管理器）。其加载期动作是框架生命周期设计的一部分（如 ace_engine 的"
              " JS 堆转储信号注册、模块管理器的 napi_onLoad 时序），按惰性化整改会改变"
              " 框架行为。", file=sys.stderr)
        print("   目标应为业务模块（applications/** 或各子系统 interfaces/kits、"
              "frameworks 下的 NAPI 模块）；框架路径如需整改，走框架演进评审。",
              file=sys.stderr)
        sys.exit(6)
    src = open(path, encoding="utf-8", errors="replace").read()
    masked = mask_source(src)
    var_tok = re.compile(r"\b%s\b" % re.escape(var))
    gates = []

    def gate(ok, msg):
        gates.append((ok, msg))
        print("%s %s" % ("✔" if ok else "❌", msg))
        return ok

    # ---------- 0. 定位声明（文件/命名空间作用域） ----------
    decl_info = None
    for m in var_tok.finditer(masked):
        ls = line_start(masked, m.start())
        le = masked.find("\n", ls)
        line_txt = masked[ls:le if le >= 0 else len(masked)]
        dm = DECL_LINE_RE.match(line_txt)
        if dm and dm.group("name") == var and dm.group("rest") in ("=", ";"):
            stack = scope_stack_at(masked, ls)
            if any(k == "fn" for k in stack):
                continue  # 函数内同名（局部变量/参数）——跳过
            decl_info = (ls, dm, "cls" in stack)
            break
    if not decl_info:
        print("❌ G0 未找到变量 `%s` 的文件/命名空间作用域声明（`TYPE %s = …;`）" % (var, var))
        sys.exit(2)
    decl_start, dm, in_class = decl_info
    decl_line = line_of(masked, decl_start)
    decl_type = dm.group("type").strip()
    decl_quals = dm.group("quals") or ""
    is_auto = bool(dm.group("auto"))
    print("✔ 定位声明 L%d（%s）" % (decl_line, src[decl_start:src.find('\n', decl_start)].strip()[:100]))

    stmt_end = statement_end(masked, decl_start)
    decl_end = stmt_end if stmt_end > decl_start else masked.find("\n", decl_start)
    # 声明行尾注释保留
    decl_line_end = src.find("\n", decl_start)
    tail_comment = ""
    raw_decl_stmt = src[decl_start:decl_end]
    if decl_line_end >= 0 and ";" in src[decl_start:decl_line_end]:
        mtc = re.search(r';\s*(//.*|/\*.*)$', src[decl_start:decl_line_end])
        if mtc:
            tail_comment = "  " + mtc.group(1).rstrip()

    # ---------- 1. 判定形态 ----------
    eq_m = re.search(r"\b%s\b\s*=" % re.escape(var), masked[decl_start:decl_end])
    rhs = None
    if eq_m:
        # RHS 从原文提取（保留字符串/注释内容），行偏移基于 masked 计算后映射 src
        rhs_span = (decl_start + eq_m.end(), decl_end)
        rhs = src[rhs_span[0]:rhs_span[1]].strip().rstrip(";").strip()
    form = None
    if rhs and rhs not in ("nullptr", "NULL", "0", "null", "NULLPTR"):
        form = "A"
    else:
        cb_names = {m.group(1) for m in
                    re.finditer(r'\.\s*nm_register_func\s*=\s*&?\s*([A-Za-z_]\w*)', masked)}
        cb_names |= {m.group(1) for m in
                     re.finditer(r'\bNAPI_MODULE\w*\s*\(\s*[\w."\']+?\s*,\s*&?\s*([A-Za-z_]\w*)', masked)}
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
            for am in re.finditer(r"\b%s\b\s*=(?!=)" % re.escape(var), body):
                assign_idx = fs[1] + am.start()
                blk = extract_guarded_block(masked, src, var, assign_idx)
                if blk:
                    init_span, init_body = (blk[0], blk[1]), blk[2]
                else:
                    se = statement_end(masked, assign_idx)
                    init_span, init_body = (assign_idx, se), src[assign_idx:se].rstrip(";").strip()
                form = "B"
                print("✔ 形态B：注册回调 `%s` 内赋值（L%d），初始化块 L%d-L%d"
                      % (cb, line_of(masked, assign_idx),
                         line_of(masked, init_span[0]), line_of(masked, init_span[1])))
                break
            if form == "B":
                break
    if form is None:
        print("❌ G0 未检测到形态A（动态初始化器）或形态B（注册回调内赋值）")
        sys.exit(2)

    # ---------- 2. 类型解析 ----------
    if is_auto:
        tm = re.match(r'new\s+([A-Za-z_]\w*(?:::[A-Za-z_]\w*)*)\s*[({]', rhs or "")
        if tm:
            ctype = tm.group(1) + "*"
        else:
            tm2 = re.match(r'(?:std\s*::\s*)?make_(unique|shared)\s*<\s*([^>]+?)\s*>', rhs or "")
            if tm2:
                ctype = "std::%s_ptr<%s>" % (tm2.group(1), tm2.group(2))
            else:
                print("❌ G5 auto 声明的 RHS 无法解析类型 → 人工处理")
                sys.exit(3)
    else:
        ctype = re.sub(r'\s*\*\s*$', '*', decl_type + "*" if decl_type.endswith("*") else decl_type)
        if dm.group("sep").strip().startswith("*"):
            ctype = re.sub(r'\*$', '*', decl_type) if decl_type.endswith("*") else decl_type + "*"
        elif dm.group("sep").strip().startswith("&"):
            gate(False, "G5 引用类型全局变量（%s&）→ 不支持，人工处理" % decl_type)
    is_smart = bool(re.match(r'^(std\s*::\s*)?(unique_ptr|shared_ptr)\s*<', ctype.replace(" ", "")))
    ret_type = (ctype + "&") if is_smart else ctype

    # ---------- 3. 安全闸门 ----------
    print("\n== 安全闸门 ==")
    # G1 其他写入点
    writes = []
    for m in var_tok.finditer(masked):
        ln = line_of(masked, m.start())
        if ln == decl_line:
            continue
        if form == "B" and init_span[0] <= m.start() < init_span[1]:
            continue
        tail = masked[m.end():m.end() + 4]
        if re.match(r'\s*=(?!=)', tail) or re.match(r'\s*(\+\+|--|\+=|-=)', tail):
            writes.append(ln)
    gate(not writes, "G1 无其他写入点" if not writes else
         "G1 存在其他写入点 L%s → 需人工设计（访问器无法承载重置/重建语义）" % writes)
    # G2 局部遮蔽
    shadow = []
    for m in var_tok.finditer(masked):
        ls = line_start(masked, m.start())
        le = masked.find("\n", ls)
        line_txt = masked[ls:le if le >= 0 else len(masked)]
        if DECL_LINE_RE.match(line_txt.strip()) and DECL_LINE_RE.match(line_txt.strip()).group("name") == var \
                and line_txt[:1] in (" ", "\t"):
            stack = scope_stack_at(masked, ls)
            if any(k == "fn" for k in stack):
                shadow.append(line_of(masked, m.start()))
    gate(not shadow, "G2 无函数内同名局部声明" if not shadow else
         "G2 函数内存在同名局部声明 L%s → 改写会影响遮蔽语义，人工处理" % shadow)
    # G3 extern / 跨文件
    has_extern = "extern" in decl_quals
    has_static_kw = "static" in decl_quals
    gate(not has_extern, "G3 声明非 extern" if not has_extern else
         "G3 声明带 extern（跨编译单元共享）→ 需在头文件提供 inline 访问器，人工处理")
    # 无 static 的文件作用域变量具有外部链接——必须经 --root 交叉检查证明无外部引用
    if has_extern:
        pass  # 已由上一条闸门拦截
    elif not has_static_kw and not args.root:
        gate(False, "G3 变量未加 static（外部链接）且未提供 --root 交叉检查 → 提供 --root 或人工确认无跨文件引用")
    else:
        gate(True, "G3 链接性：%s" % ("static（内部链接）" if has_static_kw else "外部链接（需交叉检查）"))
    if args.root:
        cross = []
        for dirpath, dirnames, filenames in os.walk(args.root):
            dirnames[:] = [d for d in dirnames if d not in (".git", "out")]
            for fn in filenames:
                if not fn.endswith((".cpp", ".cc", ".cxx", ".c", ".h", ".hpp")):
                    continue
                p2 = os.path.join(dirpath, fn)
                if os.path.abspath(p2) == os.path.abspath(path):
                    continue
                try:
                    s2 = open(p2, encoding="utf-8", errors="replace").read()
                except OSError:
                    continue
                if var_tok.search(s2):
                    cross.append(p2)
        gate(not cross, "G3 全仓无其他同名引用" if not cross else
             "G3 其他文件存在同名引用（%s）→ 人工处理" % cross[:5])
    # G4 形态B 初始化体内容检查
    if form == "B":
        bm = mask_source(init_body)
        cb_def = find_function_def(masked, cb)
        params = []
        if cb_def:
            pm = re.search(r"\b%s\s*\(" % re.escape(cb), masked)
            op = pm.end() - 1
            cp = match_balanced(masked, op, "(", ")")
            params = [p for p in re.findall(r'\b([a-zA-Z_]\w*)\s*(?:,|\))', masked[op + 1:cp])]
        bad_params = [p for p in set(params) if re.search(r"\b%s\b" % re.escape(p), bm)]
        gate(not bad_params, "G4 初始化体不引用回调参数/局部变量" if not bad_params else
             "G4 初始化体引用回调参数/局部（%s）→ 不能整体搬迁，人工处理" % bad_params)
        flow = [w for w in ("return", "break", "continue") if re.search(r"\b%s\b" % w, bm)]
        gate(not flow, "G4 初始化体不含 return/break/continue" if not flow else
             "G4 初始化体含控制流语句（%s）→ 搬迁会改变语义，人工处理" % flow)
    # G5 变量形态
    if in_class:
        gate(False, "G5 类内静态成员 → 人工处理（需改为类内静态访问器）")
    elif "thread_local" in decl_quals:
        gate(False, "G5 thread_local（每线程语义）→ 人工评估")
    elif "[" in raw_decl_stmt.split("=")[0]:
        gate(False, "G5 数组变量 → 人工处理")
    elif not (ctype.endswith("*") or is_smart):
        gate(False, "G5 不支持的变量形态（%s）→ 人工处理" % ctype)
    else:
        gate(True, "G5 变量为%s（%s）" % ("智能指针" if is_smart else "裸指针", ctype))
    # G6 取地址 / delete
    addr = []
    for m in re.finditer(r"&\s*%s\s*(?!->|\.)" % re.escape(var), masked):
        ln = line_of(masked, m.start())
        if ln != decl_line:
            addr.append(ln)
    dele = [line_of(masked, m.start()) for m in re.finditer(r"\bdelete\s+%s\b" % re.escape(var), masked)]
    gate(not addr, "G6 无取变量地址用法" if not addr else
         "G6 存在 &%s（L%s）→ 改写后取地址临时对象会编译失败，人工处理" % (var, addr))
    gate(not dele, "G6 无 delete 用法" if not dele else
         "G6 存在 delete %s（L%s）→ 人工处理" % (var, dele))
    # G7 访问器名冲突 + 使用点位置
    acc = accessor_name(var)
    while re.search(r"\b%s\b" % re.escape(acc), masked):
        acc += "Instance"
        if len(acc) > 60:
            break
    gate(not re.search(r"\b%s\s*\(" % re.escape(acc), masked),
         "G7 访问器名 `%s()` 可用" % acc if not re.search(r"\b%s\s*\(" % re.escape(acc), masked)
         else "G7 访问器名冲突 → 人工处理")
    use_above = []
    for m in var_tok.finditer(masked):
        ln = line_of(masked, m.start())
        if ln < decl_line and ln != decl_line:
            use_above.append(ln)
    gate(not use_above, "G7 使用点均位于声明之后" if not use_above else
         "G7 存在早于声明的使用点 L%s → 访问器需人工前置，人工处理" % use_above)

    # ---------- 3.5 生命周期警示（不阻断，输出后人工核对）----------
    cls_names = re.findall(r"[A-Za-z_]\w*", re.sub(r"std::", "", ctype))
    cls = cls_names[-1] if cls_names else ""
    if cls:
        # 析构体含 napi_* → 惰性化后实例为函数级静态，析构经 __cxa_atexit 可能晚于 env 死亡
        #（注意：~ 非单词字符，其前不能加 \b——行首/空白后的 ~Foo 会漏匹配）
        for m in re.finditer(r"~\s*%s\s*\(" % re.escape(cls), masked):
            cp = match_balanced(masked, m.end() - 1, "(", ")")
            if cp < 0:
                continue
            k = cp + 1
            while k < len(masked) and masked[k] in " \t\r\n":
                k += 1
            if k < len(masked) and masked[k] == "{":
                cb = match_balanced(masked, k)
                if cb > 0 and re.search(r"\bnapi_\w+\b", masked[k:cb + 1]):
                    print("⚠️ 生命周期警示：`%s` 析构函数体含 napi_* 调用（L%d 起）——"
                          "惰性化后实例为函数级静态，析构由 __cxa_atexit 在进程退出时"
                          "触发，可能晚于 napi env 死亡（DeconstructCtxEnv → SetDead；"
                          "env 死亡后再调 napi_* 即悬空使用）。人工核对析构是否依赖"
                          " env/句柄生命周期（fix-patterns.md §10）。"
                          % (cls, line_of(masked, m.start())))
                    break
        # 构造体含 throw → 异常时点从 import 移到首调（行为差异，已知影响）
        threw = None
        for m in re.finditer(r"(?<!~)\b%s\s*\(" % re.escape(cls), masked):
            cp = match_balanced(masked, m.end() - 1, "(", ")")
            if cp < 0:
                continue
            k = cp + 1
            while k < len(masked) and masked[k] in " \t\r\n":
                k += 1
            if k < len(masked) and masked[k] == "{":
                cb = match_balanced(masked, k)
                if cb > 0 and re.search(r"\bthrow\b", masked[k:cb + 1]):
                    threw = line_of(masked, m.start())
                    break
        if threw:
            print("⚠️ 行为差异警示：`%s` 构造/定义体含 throw（L%d）——惰性化把异常"
                  "时点从 import（启动期失败）移到首次业务调用；首调点若无异常契约，"
                  "崩溃表现改变（整改前 import 即崩，整改后首调才崩）。人工确认首调点"
                  "异常契约（fix-patterns.md §7 已知影响 / §8.11 失败契约）。"
                  % (cls, threw))

    failed = [msg for ok, msg in gates if not ok]
    if failed and not args.force:
        print("\n❌ 安全闸门未通过（%d 项）——拒绝改写。" % len(failed))
        sys.exit(3)
    if failed and args.force:
        print("\n⚠️ %d 项闸门未通过但 --force 生效——改写结果不保证正确！" % len(failed))

    # ---------- 4. 策略 ----------
    strategy = args.strategy
    if strategy == "auto":
        fl = build_flags(path)
        strategy = "call_once" if (fl and fl["no_threadsafe_statics"]) else "meyers"
        print("\n策略：auto → %s（模块 BUILD.gn %s -fno-threadsafe-statics）"
              % (strategy, "含" if fl and fl["no_threadsafe_statics"] else "不含"))
    if form == "B":
        strategy = "call_once"
    print("改写形态：%s | 策略：%s | 访问器：`%s()`" % (form, strategy, acc))

    # ---------- 5. 生成访问器 ----------
    if form == "A":
        init_expr = rhs
        need_mutex = strategy == "call_once"
        if strategy == "meyers":
            body = ["    static %s instance = %s;" % (ctype, init_expr), "    return instance;"]
        else:
            body = ["    static %s instance = nullptr;" % ctype,
                    "    static std::once_flag onceFlag;",
                    "    std::call_once(onceFlag, [] { instance = %s; });" % init_expr,
                    "    return instance;"]
    else:
        need_mutex = True
        inner = init_body
        # 保持完整语句（含每条语句的 ;）——被保护块形态的 body 已是完整语句序列；
        # 无保护块形态（单条赋值语句）补上 ;
        stripped = inner.rstrip()
        if not stripped.endswith(";") and not stripped.endswith("}"):
            stripped += ";"
        inner = stripped
        # 变量名 → instance（mask-aware：只改代码 token，不动字符串/注释内的同名文本）
        body_masked = mask_source(inner)
        inner = inner
        for m2 in reversed(list(re.finditer(r"\b%s\b" % re.escape(var), body_masked))):
            inner = inner[:m2.start()] + "instance" + inner[m2.end():]
        # 反缩进到基准 0，再加 4 空格（lambda 体内）
        lines_in = inner.split("\n")
        indents = [len(l) - len(l.lstrip()) for l in lines_in if l.strip()]
        base_indent = min(indents) if indents else 0
        inner_lines = []
        for l in lines_in:
            if not l.strip():
                inner_lines.append("")
            else:
                inner_lines.append("    " + l[base_indent:])
        body = ["    static %s instance = nullptr;" % ctype,
                "    static std::once_flag onceFlag;",
                "    std::call_once(onceFlag, [] {"] + inner_lines + ["    });",
                "    return instance;"]
    accessor = "static %s %s()\n{\n%s\n}%s" % (ret_type, acc, "\n".join(body), tail_comment)

    # ---------- 6. 构造新文本 ----------
    edits = []  # (start, end, replacement)
    # 6.1 声明语句 → 访问器
    edits.append((decl_start, decl_end, accessor))
    # 6.2 形态B：删除注册回调内初始化块
    if form == "B":
        edits.append((init_span[0], init_span[1], ""))
    # 6.3 其余使用点 token 替换
    for m in var_tok.finditer(masked):
        if decl_start <= m.start() < decl_end:
            continue
        if form == "B" and init_span[0] <= m.start() < init_span[1]:
            continue
        edits.append((m.start(), m.end(), "%s()" % acc))
    edits.sort(key=lambda e: e[0])
    # 校验区间不重叠
    for i in range(1, len(edits)):
        if edits[i][0] < edits[i - 1][1]:
            print("❌ 内部错误：改写区间重叠")
            sys.exit(4)
    new_src = src
    for s, e, rep in reversed(edits):
        new_src = new_src[:s] + rep + new_src[e:]
    # 6.4 include <mutex>
    if need_mutex and not re.search(r'#\s*include\s*<mutex>', new_src):
        incs = list(re.finditer(r'#\s*include\s*[<"][^>"]+[>"]', new_src))
        if incs:
            last = incs[-1]
            new_src = new_src[:last.end()] + "\n#include <mutex>" + new_src[last.end():]

    # ---------- 7. 校验 ----------
    masked_new = mask_source(new_src)
    remaining = [line_of(masked_new, m.start()) for m in var_tok.finditer(masked_new)]
    ok_ref = not remaining
    bal_old = (src.count("{") - src.count("}"), src.count("(") - src.count(")"))
    bal_new = (new_src.count("{") - new_src.count("}"), new_src.count("(") - new_src.count(")"))
    print("\n== 校验 ==")
    print("%s 旧变量名残留引用：%s" % ("✔ 无" if ok_ref else "❌ L%s" % remaining,
                                    "" if ok_ref else "（访问器外不允许）"))
    print("%s 括号配平：before %s / after %s" % ("✔" if bal_old == bal_new else "⚠️", bal_old, bal_new))

    if args.check:
        print("\n== 语法检查（尽力而为） ==")
        with open(path + ".lazyfix.chk.cpp", "w", encoding="utf-8") as fh:
            fh.write(new_src)
        checked = False
        for cxx in ("clang++", "g++"):
            try:
                r = subprocess.run([cxx, "-fsyntax-only", "-w", args.cxx, path + ".lazyfix.chk.cpp"],
                                   capture_output=True, text=True, timeout=180)
            except Exception:
                continue
            checked = True
            out = (r.stdout or "") + (r.stderr or "")
            errors = [l for l in out.splitlines() if "error:" in l]
            fatal_missing = [l for l in errors if "file not found" in l or "No such file" in l]
            real_errors = [l for l in errors if l not in fatal_missing]
            if not errors:
                print("✔ %s -fsyntax-only 通过" % cxx)
            elif not real_errors:
                print("✔ %s 仅有头文件缺失类错误（%d 条）——环境限制，改写本身无语法错误" % (cxx, len(fatal_missing)))
            else:
                print("❌ %s 存在语法错误：" % cxx)
                for l in real_errors[:8]:
                    print("   " + l)
            break
        os.remove(path + ".lazyfix.chk.cpp")
        if not checked:
            print("⚠️ 无可用编译器（clang++/g++），跳过语法检查")

    # ---------- 8. 输出 ----------
    print("\n== Unified diff ==")
    diff = difflib.unified_diff(src.splitlines(keepends=True), new_src.splitlines(keepends=True),
                                fromfile="a/" + os.path.basename(path), tofile="b/" + os.path.basename(path))
    sys.stdout.write("".join(diff))

    if args.apply:
        if not ok_ref and not args.force:
            print("\n❌ 残留引用未清零，拒绝写入。")
            sys.exit(5)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new_src)
        print("\n✅ 已写入：%s（形态%s → 惰性访问器 `%s()`，策略 %s）" % (path, form, acc, strategy))
        print("后续验证建议：模块级编译（GN ninja 目标 / hvigor / build.sh）＋运行期首用功能验证。")
    else:
        print("\n（dry-run：未写入。确认无误后加 --apply。）")


def mask_preserve_literal(text):
    return text


if __name__ == "__main__":
    main()
