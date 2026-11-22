#!/usr/bin/env python3
"""本地对照：模拟被测短答是否满足 runner 可比对字段（不启子进程）。"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# 按 SKILL 分流表给出的「必过短答」（模拟子进程在「不要读文件」约束下的输出）
GOLDEN = {
    "TRIGGER-001": "触发。本 skill 覆盖画中画。",
    "TRIGGER-002": "触发。本 skill 覆盖闪控窗。",
    "TRIGGER-003": "不触发。主题色与字体无关窗口。",
    "SMOKE-001": "能力=pip",
    "SMOKE-002": "能力=float_view",
    "SMOKE-003": "能力=floating_ball",
    "FUNC-001": "用画中画（PiPWindow）。",
    "FUNC-002": "不算。要等 STARTED。",
    "FUNC-003": "不在本 skill 范围。",
}


def parse_cases(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8")
    chunks = re.split(r"\n---\n", text)
    cases = []
    for chunk in chunks:
        m = re.search(r"### 测试用例：(\S+)", chunk)
        if not m:
            continue
        cid = m.group(1)
        inp = re.search(r"#### 输入\n\n(.+?)\n\n#### 预期输出", chunk, re.S)
        exp = re.search(r"#### 预期输出\n\n(.+)$", chunk, re.S)
        cases.append(
            {
                "id": cid,
                "input": (inp.group(1).strip() if inp else ""),
                "expected": (exp.group(1).strip() if exp else ""),
            }
        )
    return cases


def judge(cid: str, expected: str, actual: str) -> list[str]:
    fails = []
    if "应触发" in expected:
        want = "是" if "**应触发**：是" in expected.replace(" ", "") or "应触发**：是" in expected else "否"
        # tolerate spacing
        if re.search(r"应触发\*\*：\s*是", expected) or re.search(r"\*\*应触发\*\*：是", expected):
            want = "是"
        elif re.search(r"应触发\*\*：\s*否", expected) or re.search(r"\*\*应触发\*\*：否", expected):
            want = "否"
        triggered = ("不触发" not in actual) and (
            "触发" in actual or "画中画" in actual or "闪控" in actual or "skill" in actual.lower()
        )
        if want == "是" and not triggered:
            fails.append("应触发=是但输出未体现能力")
        if want == "否" and ("不触发" not in actual):
            # still ok if clearly refuses
            if "无关" not in actual and "不" not in actual:
                fails.append("应触发=否但未拒绝")
    hit = re.search(r"应命中场景\*\*：\s*(\S+)", expected)
    if not hit:
        hit = re.search(r"\*\*应命中场景\*\*：\s*(\S+)", expected)
    if hit:
        scene = hit.group(1).strip()
        if scene not in actual:
            fails.append(f"未命中场景 {scene}")
    forbid = re.search(r"禁止命中场景\*\*：\s*(.+)", expected)
    if not forbid:
        forbid = re.search(r"\*\*禁止命中场景\*\*：\s*(.+)", expected)
    if forbid:
        for item in [x.strip() for x in forbid.group(1).split(",")]:
            if item and item in actual:
                fails.append(f"出现禁止场景 {item}")
    contain = re.search(r"应包含\*\*：\s*(.+)", expected)
    if not contain:
        contain = re.search(r"\*\*应包含\*\*：\s*(.+)", expected)
    if contain:
        for item in [x.strip() for x in contain.group(1).split(",")]:
            if item and item not in actual:
                fails.append(f"缺少应包含 {item}")
    return fails


def main() -> int:
    files = [ROOT / "trigger.md", ROOT / "smoke.md", ROOT / "functional.md"]
    all_cases = []
    for f in files:
        assert f.exists(), f"missing {f.name}"
        all_cases.extend(parse_cases(f))

    assert len(all_cases) >= 3, "用例总数须 >= 3"
    missing_title = [c["id"] for c in all_cases if not c["input"]]
    assert not missing_title, f"空输入: {missing_title}"

    bad = []
    for c in all_cases:
        actual = GOLDEN.get(c["id"])
        if actual is None:
            bad.append((c["id"], ["无 GOLDEN 短答"]))
            continue
        fails = judge(c["id"], c["expected"], actual)
        if fails:
            bad.append((c["id"], fails))
        print(f"PASS {c['id']}: {actual}" if not fails else f"FAIL {c['id']}: {fails}")

    # format contract
    for f in files:
        text = f.read_text(encoding="utf-8")
        assert "### 测试用例：" in text, f"{f.name} 缺少标准标题"
        assert "#### 输入" in text and "#### 预期输出" in text, f"{f.name} 字段不全"

    if bad:
        print("SELFCHECK FAIL", bad)
        return 1
    print(f"SELFCHECK OK cases={len(all_cases)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
