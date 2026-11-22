#!/usr/bin/env python3
"""Deterministic HarmonyOS fault-log type identifier.

DFX scenario-routing primitive, ported 1:1 from the former identify_fault_log
builtin tool. It inspects log content structure (never the filename, never the
user's description) and prints a structured JSON verdict:

  {type, subtype, confidence, completeness, evidence, excluded, candidates,
   memory_corruption_suspect, out_of_scope}

`type` is one of:
  - cpp_crash / js_crash / app_freeze : the three supported fault types
  - sample_stack : freeze enhanced log (freeze-cpuinfo-ext-* sampled stacks).
    Companion evidence for app_freeze analysis, NOT an independent fault log:
    its native frames are periodic snapshots and must never be treated as
    crash evidence. Detected by content markers only, never by filename.
  - unknown

Arbitration: when a complete faultlog (header region present) coexists with
sample-stack markers in the same input, the faultlog type wins and the
sample-stack markers are noted as companion evidence; when sample-stack
markers appear without a complete faultlog, the verdict is sample_stack and
fragment-mode fault detections from its snapshot frames are suppressed.

JSCrash compatibility: jscrash faultlogs embed a HiLog section whose stream
lines can push the hilog-line ratio past the 60% threshold. Before declaring
hilog_stream the identifier therefore checks for JSCrash structural markers
(line-anchored Reason/Error message/Stacktrace fields plus JS frames); inputs
with at least two of them go through to normal fault classification instead of
being excluded as a pure hilog stream.

Contract (SR1 TR-FR-03/04):
  - same input always yields the same structured output (AC-T16)
  - `content` (stdin) and `path` go through the same classify pipeline (AC-19)
  - files larger than 20MB are rejected explicitly, never silently truncated
    (AC-T15); files up to 512KB are read whole, larger files (512KB-20MB) are
    judged via head/tail structural sampling (256KB head + 256KB tail)

Usage:
  python3 identify_fault_log.py --path <faultlog-file>
  python3 identify_fault_log.py --stdin < pasted.log
"""

import argparse
import json
import os
import re
import sys

# Force UTF-8 on stdin/stdout/stderr regardless of the host locale (Windows
# GBK consoles or stripped environments would otherwise garble the Chinese
# evidence strings emitted with ensure_ascii=False below).
for _stream in (sys.stdin, sys.stdout, sys.stderr):
    if hasattr(_stream, "reconfigure"):
        _stream.reconfigure(encoding="utf-8")

MAX_BYTES = 20 * 1024 * 1024
SAMPLE_HEAD = 256 * 1024
SAMPLE_TAIL = 256 * 1024

NATIVE_FRAME = re.compile(r"^\s*#\d+\s+pc\s+[0-9a-fA-F]+\s+\S+")
JS_FRAME = re.compile(r"^\s*at\s+\S+\s*\([^)]*\.(ets|ts|js):\d+:\d+\)")
HEADER_REASON = re.compile(r"(?:^|\n)\s*Reason\s*:([^\n]*)")
HEADER_REGISTERS = re.compile(r"(?:^|\n)\s*Registers\s*:", re.IGNORECASE)
HEADER_TIMESTAMP = re.compile(r"(?:^|\n)\s*Timestamp\s*:", re.IGNORECASE)
HEADER_PID = re.compile(r"(?:^|\n)\s*(?:Pid|Process)\s*:", re.IGNORECASE)
HEADER_FAULT_THREAD = re.compile(r"(?:^|\n)\s*Fault thread info\s*:", re.IGNORECASE)
HEADER_PROCESS_LIFE = re.compile(r"(?:^|\n)\s*Process life time\s*:", re.IGNORECASE)
HEADER_ERROR_MESSAGE = re.compile(r"(?:^|\n)\s*Error message\s*:", re.IGNORECASE)
HEADER_STACKTRACE = re.compile(r"(?:^|\n)\s*Stacktrace\s*:", re.IGNORECASE)
HEADER_MSG = re.compile(r"(?:^|\n)\s*MSG\s*(?::|=)", re.IGNORECASE)
FREEZE_EVENT = re.compile(r"\b(THREAD_BLOCK_6S|APP_INPUT_BLOCK|LIFECYCLE_TIMEOUT)\b")
THREAD_SECTION = re.compile(r"(?:^|\n)\s*(?:Tid|Name)\s*:")
SIGNAL_REASON = re.compile(r"\b(SIGSEGV|SIGABRT|SIGBUS|SIGILL|SIGFPE|SIGPIPE|Signal)\b", re.IGNORECASE)
JS_ERROR_REASON = re.compile(r"\b(TypeError|SyntaxError|RangeError|ReferenceError|EvalError|URIError|BusinessError|Error)\b")
HILOG_LINE = re.compile(r"^\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+\s+")
ANDROID_LOGCAT = re.compile(r"^(-+\s+beginning\s+of\s+\w+\s+-+$|\[\s*\d+-\d+\s+\d+:\d+:\d+\.\d+\s+\d+:\d+\s+\w+/)")

# 采样栈（增强日志，freeze-cpuinfo-ext-*）结构标记。这些段名/字段名只出现在
# 采样栈文件中，三类 faultlog 均不含（faultlog 的栈前导是 Timestamp:，非 SnapshotTime:）。
SAMPLE_STACK_MARKERS = (
    (re.compile(r"#Basic Statistical", re.IGNORECASE), "#Basic Statistical 统计段"),
    (re.compile(r"#CpuFreq Usage", re.IGNORECASE), "#CpuFreq Usage 频点段"),
    (re.compile(r"#ThreadInfos\s+Tid\s*:", re.IGNORECASE), "#ThreadInfos Tid 线程信息头"),
    (re.compile(r"(?:^|\n)\s*SnapshotTime\s*:", re.IGNORECASE), "SnapshotTime 快照时间戳字段"),
    (re.compile(r"SubmitterStacktrace"), "SubmitterStacktrace 提交者栈段"),
    (re.compile(r"(?:^|\n)\s*StaticsDuration\s*:", re.IGNORECASE), "StaticsDuration 统计时长字段"),
)


def normalize_crlf(text):
    return text.replace("\r\n", "\n").replace("\r", "\n")


def strip_bom(text):
    return text[1:] if text.startswith("\ufeff") else text


def match_one(text, pattern):
    m = pattern.search(text)
    return m.group(1).strip() if m and m.group(1) else None


def has_header_region(sample):
    hits = 0
    for pattern in (
        HEADER_REASON,
        HEADER_REGISTERS,
        HEADER_TIMESTAMP,
        HEADER_PID,
        HEADER_FAULT_THREAD,
        HEADER_PROCESS_LIFE,
        HEADER_ERROR_MESSAGE,
        HEADER_STACKTRACE,
        HEADER_MSG,
        FREEZE_EVENT,
    ):
        if pattern.search(sample):
            hits += 1
    return hits >= 2


def collect_native_frames(sample):
    out = []
    for line in sample.split("\n"):
        if NATIVE_FRAME.match(line):
            out.append(line.strip())
        if len(out) >= 3:
            break
    return out


def collect_js_frames(sample):
    out = []
    for line in sample.split("\n"):
        if JS_FRAME.match(line):
            out.append(line.strip())
        if len(out) >= 3:
            break
    return out


def count_thread_sections(sample):
    return len([line for line in sample.split("\n") if THREAD_SECTION.search(line)])


def detect_cpp_crash(sample, full):
    evidence = []
    reason = match_one(sample, HEADER_REASON)
    if reason and SIGNAL_REASON.search(reason):
        evidence.append("Reason 字段为 Signal 形态：%s" % reason)
    if HEADER_REGISTERS.search(sample):
        evidence.append("存在 Registers 段")
    if HEADER_FAULT_THREAD.search(sample):
        evidence.append("存在 Fault thread info 段")
    if HEADER_PROCESS_LIFE.search(sample):
        evidence.append("存在 Process life time 段")
    frames = collect_native_frames(sample)
    if frames:
        evidence.append("Native 栈帧形如 #NN pc <地址> <路径>（命中 %d 帧）" % len(frames))

    if full:
        if reason and SIGNAL_REASON.search(reason) and len(evidence) >= 3:
            return {"type": "cpp_crash", "evidence": evidence}
        return None
    # Fragment mode: only positive signals, missing fields never count against.
    return {"type": "cpp_crash", "evidence": evidence} if frames else None


def detect_js_crash(sample, full):
    evidence = []
    reason = match_one(sample, HEADER_REASON)
    if reason and JS_ERROR_REASON.search(reason):
        evidence.append("Reason 字段为 JS 错误类名：%s" % reason)
    if HEADER_ERROR_MESSAGE.search(sample):
        evidence.append("存在 Error message 字段")
    if HEADER_STACKTRACE.search(sample):
        evidence.append("存在 Stacktrace 字段")
    frames = collect_js_frames(sample)
    if frames:
        evidence.append("JS 栈帧形如 at f(path.ets:行:列)（命中 %d 帧）" % len(frames))

    if full:
        if reason and JS_ERROR_REASON.search(reason) and len(evidence) >= 3:
            return {"type": "js_crash", "evidence": evidence}
        return None
    return {"type": "js_crash", "evidence": evidence} if frames else None


def detect_app_freeze(sample, full):
    evidence = []
    m = FREEZE_EVENT.search(sample)
    if m:
        evidence.append("Reason/事件名为冻屏类型：%s" % m.group(1))
    if HEADER_MSG.search(sample):
        evidence.append("存在 MSG 字段（承载主线程队列）")
    sections = count_thread_sections(sample)
    if sections >= 2:
        evidence.append("多线程分节结构（Tid/Name 分块）")

    if full:
        if m and len(evidence) >= 3:
            return {"type": "app_freeze", "evidence": evidence}
        return None
    return {"type": "app_freeze", "evidence": evidence} if (sections >= 2 or m) else None


def detect_sample_stack(sample):
    """检出采样栈（增强日志）结构标记；命中不足 2 项不判（避免单字段巧合）。"""
    return [label for pattern, label in SAMPLE_STACK_MARKERS if pattern.search(sample)]


def has_js_crash_structure(sample):
    """JSCrash faultlog 的结构特征计数（行首字段 + JS 栈帧，纯 HiLog 流水不会命中）。

    JSCrash faultlog 内嵌 HiLog 段，hilog 行占比可能远超 60%；判 hilog_stream 前先
    用此函数排除该情形。命中不足 2 项不豁免：流水日志打印出的 JS 栈帧等单一特征
    不构成 faultlog 结构，不足以否定 hilog_stream 判定。
    """
    reason = match_one(sample, HEADER_REASON)
    hits = 0
    if reason and JS_ERROR_REASON.search(reason):
        hits += 1
    if HEADER_ERROR_MESSAGE.search(sample):
        hits += 1
    if HEADER_STACKTRACE.search(sample):
        hits += 1
    if collect_js_frames(sample):
        hits += 1
    return hits >= 2


def detect_out_of_scope(sample):
    if sample.strip() == "":
        return {"reason": "empty", "detail": "输入为空文件或无内容"}

    lines = [l for l in sample.split("\n") if l.strip() != ""]
    if not lines:
        return {"reason": "empty", "detail": "输入为空文件或无内容"}

    hilog_hits = len([l for l in lines if HILOG_LINE.match(l)])
    # JSCrash faultlog 内嵌 HiLog 段可致 hilog 占比超阈值，须先排除其结构特征。
    if hilog_hits / len(lines) > 0.6 and not has_js_crash_structure(sample):
        return {"reason": "hilog_stream", "detail": "输入为 HiLog 流水日志，非 FaultLog，无法进行故障类型分诊"}
    if ANDROID_LOGCAT.match(lines[0]):
        return {"reason": "non_harmonyos", "detail": "输入为 Android logcat 等非鸿蒙平台日志"}
    return None


def detect_memory_corruption(sample, fault_type):
    if fault_type != "cpp_crash":
        return None
    evidence = []
    reason = match_one(sample, HEADER_REASON) or ""
    if re.search(r"\bSIGSEGV\b", reason, re.IGNORECASE):
        addr = re.search(r"0x[0-9a-fA-F]+", reason, re.IGNORECASE)
        if addr:
            v = int(addr.group(0), 16)
            if 0 < v < 0x10000:
                evidence.append("崩溃地址 %s 落在低地址区间，疑似踩内存目标" % addr.group(0))
    if re.search(r"0x[a-fA-F0-9]{8}\b", sample, re.IGNORECASE):
        fill = re.search(r"\b0x(61616161|deadbeef|beefbeef|00)+\b", sample, re.IGNORECASE)
        if fill:
            evidence.append("疑似填充模式命中：0x%s" % fill.group(1))
    if re.search(r"SIGABRT", reason, re.IGNORECASE) and re.search(r"stack|overflow|corrupt", sample, re.IGNORECASE):
        evidence.append("SIGABRT 且上下文含 stack/corrupt 关键字")
    if not evidence:
        return {"suspected": False, "confidence": "low", "evidence": ["未命中踩内存正向特征"]}
    confidence = "medium" if len(evidence) >= 2 else "low"
    return {"suspected": True, "confidence": confidence, "evidence": evidence}


def confidence_for(hit, full, arbitrated):
    if not full:
        return "medium" if arbitrated else "low"
    if hit["type"] == "app_freeze":
        return "high" if len(hit["evidence"]) >= 3 else "medium"
    return "high" if len(hit["evidence"]) >= 4 else "medium"


def exclusion_reason(fault_type, sample, full):
    if not full:
        if fault_type == "cpp_crash":
            return "未命中 Native 栈帧正向特征"
        if fault_type == "js_crash":
            return "未命中 JS 栈帧正向特征"
        return "未命中多线程分节或冻屏事件名正向特征"

    reason = match_one(sample, HEADER_REASON)
    if fault_type == "cpp_crash":
        missing = []
        if not (reason and SIGNAL_REASON.search(reason)):
            missing.append("Signal 形态的 Reason")
        if not HEADER_REGISTERS.search(sample):
            missing.append("Registers 段")
        if not collect_native_frames(sample):
            missing.append("Native 栈帧")
    elif fault_type == "js_crash":
        missing = []
        if not (reason and JS_ERROR_REASON.search(reason)):
            missing.append("JS 错误类名的 Reason")
        if not HEADER_ERROR_MESSAGE.search(sample):
            missing.append("Error message 字段")
        if not HEADER_STACKTRACE.search(sample):
            missing.append("Stacktrace 字段")
        if not collect_js_frames(sample):
            missing.append("JS 栈帧")
    else:
        missing = []
        if not FREEZE_EVENT.search(sample):
            missing.append("冻屏事件名")
        if not HEADER_MSG.search(sample):
            missing.append("MSG 字段")
        if count_thread_sections(sample) < 2:
            missing.append("多线程分节")
    return "缺少：%s" % "、".join(missing) if missing else "正向特征未达到完整日志判定阈值"


def build_excluded(hits, full, sample):
    present = set(h["type"] for h in hits)
    return [
        {"type": t, "reason": exclusion_reason(t, sample, full)}
        for t in ("cpp_crash", "js_crash", "app_freeze")
        if t not in present
    ]


def classify(sample):
    out_of_scope = detect_out_of_scope(sample)
    if out_of_scope:
        return {
            "type": "unknown",
            "confidence": "low",
            "completeness": "fragment",
            "evidence": [],
            "excluded": [],
            "candidates": [],
            "out_of_scope": out_of_scope,
        }

    full = has_header_region(sample)
    sample_markers = detect_sample_stack(sample)
    hits = []
    for detect in (detect_cpp_crash, detect_js_crash, detect_app_freeze):
        hit = detect(sample, full)
        if hit:
            hits.append(hit)

    # 完整 faultlog 与采样栈标记共存（两份内容合入同一输入）时，faultlog 类型优先。
    if hits and full:
        result = verdict_from_hits(hits, full, sample)
        if sample_markers:
            result["evidence"] = result["evidence"] + [
                "同时检出采样栈(增强日志)结构标记（%d 项），可作为冻屏分析配套证据" % len(sample_markers)
            ]
        return result

    # 采样栈标记存在而无完整 faultlog：其 native 帧为周期快照采样，不作为崩溃证据，
    # 片段模式的故障命中一律让位于 sample_stack 判定。
    if sample_markers:
        strong = len(sample_markers) >= 3
        return {
            "type": "sample_stack",
            "confidence": "high" if strong else "medium",
            "completeness": "full" if strong else "fragment",
            "evidence": ["采样栈(增强日志)结构标记：%s" % "、".join(sample_markers)],
            "excluded": [
                {"type": "cpp_crash", "reason": "输入为采样栈(增强日志)：native 帧为周期快照，非崩溃 faultlog"},
                {"type": "js_crash", "reason": "输入为采样栈(增强日志)：无 JS 错误 Reason / Stacktrace 结构"},
                {"type": "app_freeze", "reason": "输入为采样栈(增强日志)：无冻屏事件名 / MSG 字段，需配套冻屏 faultlog 定类"},
            ],
            "candidates": [],
        }

    if not hits:
        return {
            "type": "unknown",
            "confidence": "low",
            "completeness": "full" if full else "fragment",
            "evidence": [],
            "excluded": build_excluded(hits, full, sample),
            "candidates": [],
        }

    return verdict_from_hits(hits, full, sample)


def verdict_from_hits(hits, full, sample):
    """由故障检测结果产出最终判定（单命中 / 片段双栈仲裁 / 多候选澄清）。"""
    if len(hits) == 1:
        hit = hits[0]
        result = {
            "type": hit["type"],
            "confidence": confidence_for(hit, full, False),
            "completeness": "full" if full else "fragment",
            "evidence": hit["evidence"],
            "excluded": build_excluded(hits, full, sample),
            "candidates": [],
        }
        if hit["type"] == "cpp_crash":
            result["memory_corruption_suspect"] = detect_memory_corruption(sample, hit["type"])
        if hit["type"] == "app_freeze":
            m = FREEZE_EVENT.search(sample)
            if m:
                result["subtype"] = m.group(1)
        return result

    # Multi-candidate. Fragment dual-stack (native + js) -> deterministic arbitration, prefer cpp_crash.
    types = set(h["type"] for h in hits)
    if "cpp_crash" in types and "js_crash" in types and not full:
        primary = next(h for h in hits if h["type"] == "cpp_crash")
        secondary = next(h for h in hits if h["type"] == "js_crash")
        return {
            "type": "cpp_crash",
            "confidence": "medium",
            "completeness": "fragment",
            "evidence": primary["evidence"],
            "excluded": build_excluded([primary, secondary], full, sample),
            "candidates": [
                {"type": "js_crash", "confidence": "low", "evidence": secondary["evidence"]}
            ],
            "memory_corruption_suspect": detect_memory_corruption(sample, "cpp_crash"),
        }

    # Multi-candidate, no deterministic arbitration rule available -> clarification.
    return {
        "type": "unknown",
        "confidence": "low",
        "completeness": "full" if full else "fragment",
        "evidence": [],
        "excluded": build_excluded(hits, full, sample),
        "candidates": [
            {
                "type": h["type"],
                "confidence": confidence_for(h, full, False),
                "evidence": h["evidence"],
            }
            for h in hits
        ],
    }


def sample_bytes(data, size):
    total = len(data)
    if total <= size:
        text = data.decode("utf-8", errors="replace")
    else:
        half = size // 2
        head = data[: half]
        tail_start = max(0, total - half)
        tail = data[tail_start:]
        text = head.decode("utf-8", errors="replace") + "\n…（中段省略）…\n" + tail.decode("utf-8", errors="replace")
    return strip_bom(normalize_crlf(text))


def run(args):
    if not args.path and not args.stdin:
        print("Error: identify_fault_log requires either --path or --stdin.", file=sys.stderr)
        return 1

    if args.stdin:
        content = sys.stdin.read()
        data = content.encode("utf-8")
        if len(data) > MAX_BYTES:
            print(
                'Error: input oversize. {"reason": "oversize", "limit_mb": %d, "size": %d, "remediation": "head/tail 256KB sampling is built-in for inputs up to 20MB; for larger logs, extract the head and tail sections (header fields + fault thread stack) into a smaller file and retry."}'
                % (MAX_BYTES // 1024 // 1024, len(data)),
                file=sys.stderr,
            )
            return 1
    else:
        filepath = args.path
        if not os.path.isfile(filepath):
            print("Error: Fault log not found or not a regular file: %s" % filepath, file=sys.stderr)
            return 1
        size = os.path.getsize(filepath)
        if size > MAX_BYTES:
            print(
                'Error: input oversize. {"reason": "oversize", "limit_mb": %d, "size": %d, "remediation": "head/tail 256KB sampling is built-in for inputs up to 20MB; for larger logs, extract the head and tail sections (header fields + fault thread stack) into a smaller file and retry."}'
                % (MAX_BYTES // 1024 // 1024, size),
                file=sys.stderr,
            )
            return 1
        with open(filepath, "rb") as f:
            data = f.read()

    result = classify(sample_bytes(data, SAMPLE_HEAD + SAMPLE_TAIL))
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


def main():
    parser = argparse.ArgumentParser(description="Deterministic HarmonyOS fault-log type identifier.")
    parser.add_argument("--path", help="Path to a HarmonyOS faultlog file")
    parser.add_argument("--stdin", action="store_true", help="Read pasted log content from stdin")
    sys.exit(run(parser.parse_args()))


if __name__ == "__main__":
    main()
