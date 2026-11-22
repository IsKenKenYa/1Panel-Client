#!/usr/bin/env python3
"""parse_scan_report.py — 解析扫描技能（hmos-arkts-napi-side-effect-checker）的产出，
生成「NAPI 加载期副作用」整改工作清单，并可驱动整改引擎逐条执行。

本脚本是整改技能的输入端：**消费扫描结果，不做扫描**。

覆盖两类问题（与扫描技能 rulebook 术语一致）：

- 类别1：注册函数违规业务逻辑（耗时）→ 引擎 E（apply_init_extraction.py）：
  注册回调内业务动作迁到显式导出 init() 接口（Init 只留函数映射）。
- 类别2：加载期重初始化 → 引擎 L（apply_lazy_init.py）：
  全局单例改惰性访问器（首次使用时创建，不改 JS 侧）。

支持的输入格式（自动识别，可多文件混合）：

1. 扫描技能最终报告（rulebook §3.10 模板，R-01/R-02 格式）：
     【类别1：注册函数违规业务逻辑（耗时）】 / 【类别2：加载期重初始化】
     问题 #n
     📍 <文件路径>:<行号或行号范围>
        <代码片段>
     ⚠️ <判定原因（白话）>
     💡 <整改建议（白话）>
   → 提取问题编号、类别、文件、行号、片段 → 引擎路由

2. 扫描技能 prescan.py 输出（markdown）：
   - 形态A 候选段（类别2）：
       ## 形态A 候选（…）
       ### <文件>
       - L<行> [P1] <原始行文本>
   - 全局赋值候选行（类别2/形态B）：
       - [R2表命中(本文件L38)] <文件>:<行> <片段文本>
   - 信号命中行（类别1，仅 --deep 深析底稿的链节点下）：
       - [进程级回调注册[/exports]] <文件>:<行> <片段文本>

3. 直接目标（无报告时的手工入口，走引擎 L）：
     --target <文件>:<行号>[:<变量名>]（可多次）

分流与路由：
  类别2 条目：片段解析出全局变量名 → AUTO（引擎 L，按变量名重定位）；
             解析不出（典型为形态C：注册链内创建不落全局变量）→ MANUAL。
  类别1 条目：文件存在 → AUTO（引擎 E，--at-line 定位回调，语句级分类自动分流
             KEEP/MOVE/纠缠/形态B）；文件不存在 → MANUAL。
             同文件多条信号命中去重为一条（引擎按回调整体分类处理）。
  执行顺序：先引擎 L（类别2）后引擎 E（类别1）——形态B 守卫块先惰性化，
  其余业务语句再迁 init()（组合规则见 fix-patterns.md §8.6）。

输出：
  默认打印 markdown 工作清单（含扫描问题编号回溯与引擎路由）
  --json           输出 JSON（供脚本消费）
  --fix            对全部 AUTO 条目驱动引擎（dry-run；默认）
  --fix --apply    同上并写入源文件（需用户确认）
  --root ROOT      仓库根（类别2 跨文件引用检查 + 相对路径解析基准）
  --check          传递给引擎做语法检查
  --js-root DIR    传递给引擎 E 定位 ArkTS 调用点（init() 集成指引）

Usage:
  python3 parse_scan_report.py <扫描报告.md> [更多.md...] [--target 文件:行[:变量]]...
      [--json] [--fix [--apply]] [--root ROOT] [--check] [--js-root DIR]
"""
import argparse
import json
import os
import re
import subprocess
import sys

# ---------- 扫描报告（R-02）条目 ----------
R02_HEAD_RE = re.compile(r'^【(类别1|类别2)[:：]([^】]*)】')
R02_PROBLEM_RE = re.compile(r'^问题\s*#(\d+)')
R02_LOC_RE = re.compile(r'^📍\s*(\S+?)\s*:\s*(\d+)(?:-(\d+))?')

# ---------- prescan 输出 ----------
PSC_FORMA_SEC_RE = re.compile(r'^##\s*形态A\s*候选')          # 两个段标题都匹配（候选/候选工作包）
PSC_FILE_RE = re.compile(r'^###\s+(\S+)')
PSC_LINE_RE = re.compile(r'^-\s*L(\d+)\s*\[(P\d\w*)\]\s*(.+)$')
PSC_ASSIGN_RE = re.compile(r'^\s*-\s*\[(R[0-9][^\]]*)\]\s*(\S+?):(\d+)\s*(.*)$')
# 类别1 信号命中行（深析工作包链节点下）：`- [信号类[/exports]] <文件>:<行> <片段>`
PSC_SIGNAL_RE = re.compile(r'^\s*-\s*\[((?!R[0-9])[^\]]+)\]\s*(\S+?):(\d+)\s*(.*)$')

# ---------- 变量名解析（类别2 条目，逐行，先命中先得） ----------
VAR_DECL_RE = re.compile(
    r'\b[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*(?:\s*<[^();=]*?>)?'
    r'[\s*&]+\s*([A-Za-z_]\w*)\s*=\s*'
    r'(?:new\s|std\s*::\s*make_|[A-Za-z_]\w*\s*::\s*(?:GetInstance|Create|Instance)\s*\()'
)
VAR_ASSIGN_RE = re.compile(
    r'(?<![A-Za-z0-9_:.>])([A-Za-z_]\w*)\s*=\s*'
    r'(?:new\s|std\s*::\s*make_|\w+\s*::\s*make_|[A-Za-z_]\w*\s*::\s*(?:GetInstance|Create|Instance)\s*\()'
)
VAR_NULLCHECK_RE = re.compile(r'([A-Za-z_]\w*)\s*==\s*(?:nullptr|NULL)\s*\)')


def parse_r02_report(text, source_name, entries):
    """解析扫描技能最终报告的【类别1】/【类别2】段。"""
    lines = text.split("\n")
    cur_cat = None
    cur = None
    for ln in lines:
        hm = R02_HEAD_RE.match(ln.strip())
        if hm:
            cur_cat = 'cat1' if hm.group(1) == '类别1' else 'cat2'
            if cur:
                entries.append(cur)
                cur = None
            continue
        if cur_cat is None:
            continue
        # 新的问题块
        pm = R02_PROBLEM_RE.match(ln.strip())
        if pm:
            if cur:
                entries.append(cur)
            cur = {"problem_no": int(pm.group(1)), "source": source_name,
                   "source_kind": "report", "category": cur_cat, "lines": []}
            continue
        if cur is None:
            continue
        lm = R02_LOC_RE.match(ln.strip())
        if lm:
            cur["file"] = lm.group(1)
            cur["line"] = int(lm.group(2))
            cur["line_end"] = int(lm.group(3)) if lm.group(3) else None
            continue
        # 代码片段行（📍 后、⚠️/💡/❓ 前的缩进行）
        if ln.startswith("   ") and not ln.strip().startswith(("⚠️", "💡", "❓", "👉", "🔎")):
            cur["lines"].append(ln.strip())
        elif ln.strip().startswith(("⚠️", "💡")):
            cur.setdefault("advice" if ln.strip().startswith("💡") else "reason",
                           ln.strip().lstrip("⚠️💡 ").strip())
        # 段落结束：下一个【…】标题（非类别1/2 段）
        if ln.strip().startswith("【") and not R02_HEAD_RE.match(ln.strip()):
            if cur:
                entries.append(cur)
                cur = None
            cur_cat = None
    if cur:
        entries.append(cur)


def parse_prescan_output(text, source_name, entries):
    """解析 prescan.py 输出（形态A 候选段 + 全局赋值候选行 + 类别1 信号命中行）。"""
    lines = text.split("\n")
    cur_file = None
    in_forma = False
    for ln in lines:
        if ln.startswith("## "):
            in_forma = PSC_FORMA_SEC_RE.match(ln) is not None
            cur_file = None
            continue
        fm = PSC_FILE_RE.match(ln)
        if fm:
            cur_file = fm.group(1)
            continue
        if in_forma and cur_file:
            lm = PSC_LINE_RE.match(ln)
            if lm:
                entries.append({"file": cur_file, "line": int(lm.group(1)),
                                "source": source_name, "source_kind": "prescan-formA",
                                "category": "cat2",
                                "lines": [lm.group(3).strip()], "signal": lm.group(2)})
                continue
        # 全局赋值候选行（类别2/形态B，深析工作包的链节点下）
        am = PSC_ASSIGN_RE.match(ln)
        if am:
            entries.append({"file": am.group(2), "line": int(am.group(3)),
                            "source": source_name, "source_kind": "prescan-formB",
                            "category": "cat2",
                            "lines": [am.group(4).strip()], "signal": am.group(1)})
            continue
        # 类别1 信号命中行（深析工作包链节点下）
        sm = PSC_SIGNAL_RE.match(ln)
        if sm:
            entries.append({"file": sm.group(2), "line": int(sm.group(3)),
                            "source": source_name, "source_kind": "prescan-cat1",
                            "category": "cat1",
                            "lines": [sm.group(4).strip()], "signal": sm.group(1)})


def extract_var(snippet_lines):
    """从片段行序列解析全局变量名。返回 (var, matched_line) 或 (None, None)。"""
    for raw in snippet_lines:
        line = raw.strip()
        m = VAR_ASSIGN_RE.search(line)
        if m:
            return m.group(1), line
        m = VAR_DECL_RE.search(line)
        if m:
            return m.group(1), line
        m = VAR_NULLCHECK_RE.search(line)
        if m:
            return m.group(1), line
    return None, None


def resolve_path(f, e, repo_root):
    """报告相对路径解析：优先 CWD，再 repo_root / 报告所在目录。"""
    if os.path.isfile(f):
        return f
    for base in (repo_root, os.path.dirname(os.path.abspath(e.get("source") or "."))):
        if base:
            cand = os.path.join(base, f)
            if os.path.isfile(cand):
                return cand
    return None


def classify(entries, repo_root=None):
    """分流 AUTO / MANUAL，附引擎路由。"""
    out = []
    seen = set()
    cat1_files = {}
    for e in entries:
        cat = e.get("category", "cat2")
        f = e.get("file")
        if f:
            alt = resolve_path(f, e, repo_root)
            if alt:
                e["file"] = alt
        var, matched = extract_var(e.get("lines", []))
        key = (e.get("file"), var if cat == "cat2" else None, e.get("line"))
        dedup = key in seen
        seen.add(key)
        item = {
            "problem_no": e.get("problem_no"),
            "file": e.get("file"),
            "line": e.get("line"),
            "var": var if cat == "cat2" else None,
            "category": cat,
            "source": e.get("source"),
            "source_kind": e.get("source_kind"),
            "signal": e.get("signal"),
            "snippet": (e.get("lines") or [""])[0][:160],
            "matched_line": matched,
            "dedup": dedup,
        }
        if not f:
            item["mode"] = "MANUAL"
            item["reason"] = "报告条目无文件定位"
            item["engine"] = "—"
        elif not os.path.isfile(e.get("file")):
            item["mode"] = "MANUAL"
            item["reason"] = "文件不存在（路径需人工核对：%s）" % f
            item["engine"] = "—"
        elif cat == "cat1":
            # 同文件去重（引擎按回调整体分类处理，多条信号行合一；
            # 保留全部行号——首行可能落在辅助函数体内，引擎逐个尝试定位回调）
            first = cat1_files.get(e.get("file"))
            if first is not None:
                first.setdefault("at_lines", []).append(e.get("line"))
                item["mode"] = "MERGE"
                item["reason"] = "并入同文件类别1条目（引擎按回调整体处理）"
                item["engine"] = "E"
                out.append(item)
                continue
            cat1_files[e.get("file")] = item
            item["at_lines"] = [e.get("line")]
            item["mode"] = "AUTO"
            item["engine"] = "E"
            item["reason"] = ""
        else:
            if var:
                item["mode"] = "AUTO"
                item["engine"] = "L"
                item["reason"] = ""
            else:
                item["mode"] = "MANUAL"
                item["engine"] = "—"
                item["reason"] = ("片段中解析不出全局变量名——典型为扫描形态C（注册链内创建、"
                                  "不落全局变量，如 Registry::Register(make_shared<X>(…))）→ 人工整改；"
                                  "或属类别1（注册回调业务动作）→ 由类别1条目/引擎 E 处理")
        out.append(item)
    return out


def run_engine(item, args):
    """对单条 AUTO 条目驱动整改引擎。返回 (ok, summary_lines)。"""
    if item["engine"] == "E":
        engine = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                              "apply_init_extraction.py")
        at_lines = [l for l in (item.get("at_lines") or []) if l] or [item.get("line")]
        cmd = [sys.executable, engine, item["file"],
               "--at-line", ",".join(str(l) for l in at_lines)]
        if args.js_root:
            cmd += ["--js-root", args.js_root]
    else:
        engine = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                              "apply_lazy_init.py")
        cmd = [sys.executable, engine, item["file"], "--var", item["var"]]
        if args.root:
            cmd += ["--root", args.root]
    if args.check:
        cmd += ["--check"]
    if args.apply:
        cmd += ["--apply"]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    except Exception as ex:  # noqa: BLE001
        return False, ["引擎执行异常：%s" % ex]
    summary = [l for l in ((r.stdout or "") + "\n" + (r.stderr or "")).splitlines()
               if l.startswith(("✔", "❌", "✅", "⚠️", "策略", "改写形态",
                                "- ✔", "- ❌", "- ⚠️", "已写入", "语句分类",
                                "   ", "框架实现路径拒改"))]
    return r.returncode == 0, summary


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="*",
                    help="扫描技能产出文件（最终报告 / prescan 输出，.md/.txt）")
    ap.add_argument("--target", action="append", default=[],
                    help="直接整改目标 文件:行号[:变量名]（可多次；走引擎 L）")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--fix", action="store_true", help="对 AUTO 条目驱动整改引擎（默认 dry-run）")
    ap.add_argument("--apply", action="store_true", help="配合 --fix：写入源文件")
    ap.add_argument("--root", default=None, help="仓库根（类别2 跨文件检查 + 路径解析基准）")
    ap.add_argument("--check", action="store_true", help="语法检查，传递给引擎")
    ap.add_argument("--js-root", default=None, help="ArkTS 源码根，传递给引擎 E（init() 集成指引）")
    args = ap.parse_args()

    if not args.inputs and not args.target:
        print("❌ 未提供输入：扫描报告文件或 --target", file=sys.stderr)
        sys.exit(1)

    entries = []
    for p in args.inputs:
        if not os.path.isfile(p):
            print("❌ 输入文件不存在：%s" % p, file=sys.stderr)
            sys.exit(1)
        text = open(p, encoding="utf-8", errors="replace").read()
        if R02_HEAD_RE.search(text) or "问题 #" in text:
            parse_r02_report(text, p, entries)
        if "prescan" in text or "形态A" in text or PSC_SIGNAL_RE.search(text):
            parse_prescan_output(text, p, entries)
    for t in args.target:
        parts = t.split(":")
        if len(parts) < 2 or not os.path.isfile(parts[0]):
            print("❌ --target 格式：<存在的文件>:<行号>[:<变量名>]，got %s" % t, file=sys.stderr)
            sys.exit(1)
        entries.append({"file": parts[0], "line": int(parts[1]), "source": "--target",
                        "source_kind": "direct", "category": "cat2",
                        "var_hint": parts[2] if len(parts) > 2 else None, "lines": []})

    work = classify(entries, args.root)
    # --target 显式变量名直通 AUTO（引擎 L）
    for w, e in zip(work, entries):
        if e.get("var_hint"):
            w["var"] = e["var_hint"]
            w["mode"] = "AUTO"
            w["engine"] = "L"
            w["reason"] = ""
    # 去重（同文件同变量/同文件类别1 只保留一条，来源合并）
    deduped = []
    for w in work:
        if w["dedup"] or w.get("mode") == "MERGE":
            continue
        dup = next((d for d in deduped
                    if d["file"] == w["file"] and d["var"] == w["var"]
                    and d["category"] == w["category"]), None)
        if dup and w["mode"] == "AUTO":
            dup["problem_no"] = dup.get("problem_no") or w.get("problem_no")
            continue
        deduped.append(w)

    if args.json:
        print(json.dumps(deduped, ensure_ascii=False, indent=1))
        return

    n_auto = sum(1 for w in deduped if w["mode"] == "AUTO")
    n_manual = sum(1 for w in deduped if w["mode"] == "MANUAL")
    print("## NAPI 加载期副作用整改 — 工作清单（来自扫描技能产出）")
    print()
    print("- 输入：%s" % ("、".join(args.inputs) if args.inputs else "--target 直连"))
    print("- 条目：AUTO（可引擎整改）× %d、MANUAL（人工整改）× %d" % (n_auto, n_manual))
    print("- 引擎路由：L = apply_lazy_init.py（类别2→惰性访问器，不改 JS）｜"
          "E = apply_init_extraction.py（类别1→显式 init() 导出，需 JS 侧集成）")
    print()
    if deduped:
        print("| # | 扫描问题 | 类别 | 文件 | 行 | 变量/动作 | 信号 | 引擎 | 分流 | 说明 |")
        print("|---|---|---|---|---|---|---|---|---|---|")
        for i, w in enumerate(deduped, 1):
            pn = ("#%s" % w["problem_no"]) if w.get("problem_no") else "—"
            cat = "1" if w.get("category") == "cat1" else "2"
            vv = ('`%s`' % w["var"]) if w.get("var") else (w.get("snippet", "")[:36] or "—")
            print("| %d | %s | %s | %s | %s | %s | %s | %s | %s | %s |"
                  % (i, pn, cat, w["file"], w.get("line", "—"), vv,
                     w.get("signal") or "—", w.get("engine") or "—", w["mode"],
                     (w["reason"] or "OK")))
    print()
    if n_manual:
        print("### MANUAL 条目整改指引")
        print("- 类别2 形态C（注册链内创建、不落全局变量）：把创建语句移到首个业务导出"
              "函数内部，用 std::call_once 或双检锁保证幂等与并发首调安全（禁止裸判空），"
              "或改挂到显式 init 导出接口——见 fix-patterns.md §5.1")
        print("- 类别1 纠缠语句（依赖 exports 挂载对象）：见 fix-patterns.md §9 人工指引")
        print("- 其他无定位条目：核对文件路径与报告行号后用 --target 补入")
        print()

    if args.fix:
        engines_ok = {"L": os.path.isfile(os.path.join(
                          os.path.dirname(os.path.abspath(__file__)), "apply_lazy_init.py")),
                      "E": os.path.isfile(os.path.join(
                          os.path.dirname(os.path.abspath(__file__)), "apply_init_extraction.py"))}
        missing = [k for k, v in engines_ok.items() if not v]
        if missing:
            print("❌ 整改引擎不存在：%s" % "、".join(missing), file=sys.stderr)
            sys.exit(1)
        print("## 引擎整改执行（%s；先类别2/L 后类别1/E）"
              % ("--apply 写入" if args.apply else "dry-run 预览"))
        print()
        ok_n = fail_n = 0
        ordered = [w for w in deduped if w["mode"] == "AUTO" and w["engine"] == "L"] + \
                  [w for w in deduped if w["mode"] == "AUTO" and w["engine"] == "E"]
        for w in ordered:
            print("### %s — %s（扫描问题 %s，引擎 %s）"
                  % (w["file"],
                     '`%s`' % w["var"] if w.get("var") else "类别1 业务语句",
                     w.get("problem_no") or "—",
                     "L（惰性访问器）" if w["engine"] == "L" else "E（显式 init 导出）"))
            ok, summary = run_engine(w, args)
            print("\n".join(summary) if summary else "（无摘要输出——查看引擎完整日志）")
            print("结果：%s" % ("✅ 成功" if ok else "❌ 拒绝/失败（见上方闸门输出）"))
            print()
            if ok:
                ok_n += 1
            else:
                fail_n += 1
        print("引擎执行：成功 %d / 拒绝 %d（拒绝项按闸门输出转人工）" % (ok_n, fail_n))
        if args.apply:
            print("已写入的文件保持未暂存、未提交状态；提交由用户执行。")
        print("后续：verify_fix.py 回归验证（确认整改文件不再命中）＋模块级编译验证＋"
              "运行期验证（类别1 条目必须完成 ArkTS 侧 init() 集成）。")


if __name__ == "__main__":
    main()
