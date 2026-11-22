#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ArkUI 通用无障碍快速接入 Skill — 交付件结构/事实一致性自检。

检查项：
  A. 交付件齐备性（SKILL.md + 6 references + 4 templates + test-cases 交付件）
  B. SKILL.md frontmatter 可解析且含 name/description/version
  C. 事实表（api-facts.md）属性/事件与源码注册表白名单一致
  D. templates 中出现的 accessibility* API 均在事实表内
  E. 用例集 B01~B20 齐备且引用的 API 在事实表内
退出码 0 = 全部通过。
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

FAILURES = []
PASSED = 0


def check(name, ok, detail=""):
    global PASSED
    if ok:
        PASSED += 1
        print(f"  [PASS] {name}")
    else:
        FAILURES.append(f"{name}: {detail}")
        print(f"  [FAIL] {name} {detail}")


def read(path):
    full = os.path.join(ROOT, path)
    if not os.path.isfile(full):
        return None
    with open(full, encoding="utf-8") as f:
        return f.read()


def main():
    print("== A. 交付件齐备性 ==")
    required = [
        "SKILL.md",
        "references/api-facts.md",
        "references/decision-matrix.md",
        "references/group-dynamic-announcement.md",
        "references/event-and-focus.md",
        "references/virtual-node.md",
        "references/faq-vod.md",
        "templates/basic_attributes_template.ets",
        "templates/group_announcement_template.ets",
        "templates/event_focus_template.ets",
        "templates/virtual_node_template.ets",
        "test-cases/README.md",
        "test-cases/cases-b01-b20.md",
        "test-cases/report-template.md",
        "test-cases/test-prompts.md",
    ]
    for path in required:
        check(f"存在 {path}", read(path) is not None)

    print("== B. SKILL.md frontmatter ==")
    skill = read("SKILL.md") or ""
    m = re.match(r"^---\n(.*?)\n---\n", skill, re.DOTALL)
    fm = m.group(1) if m else ""
    check("frontmatter 存在", bool(fm))
    check("含 name", re.search(r"^name:\s*\S+", fm, re.M) is not None)
    check("含 description", re.search(r"^description:\s*\S+", fm, re.M) is not None)
    check("含 version", re.search(r"^\s*version:\s*\S+", fm, re.M) is not None)
    for kw in ["D0", "accessibilityGroup", "no-hide-descendants", "build-profile",
               "原文本不再播报", "decision-matrix", "accessibilityPreferred", "通用文本",
               "代码简约性检查"]:
        check(f"SKILL.md 含关键内容 {kw}", kw in skill)

    print("== C. 事实表与源码注册表一致性 ==")
    facts = read("references/api-facts.md") or ""
    # 源码注册表白名单：js_view_abstract.cpp:10422-10487 注册的 accessibility* 入口（本仓核验）
    registered = {
        "accessibilityGroup", "accessibilityText", "accessibilityNextFocusId",
        "accessibilityDescription", "accessibilityImportance", "accessibilityLevel",
        "accessibilityVirtualNode", "accessibilitySelected", "accessibilityChecked",
        "accessibilityRole", "accessibilityDefaultFocus", "accessibilityUseSamePage",
        "accessibilityScrollTriggerable", "accessibilityFocusDrawLevel",
        "accessibilityStateDescription", "accessibilityTextHint",
        "accessibilityActionOptions", "accessibilityCustomActions",
        "onAccessibilityFocus", "onAccessibilityHover",
        "onAccessibilityActionIntercept", "onAccessibilityHoverTransparent",
        "sendAccessibilityEvent", "AccessibilityHoverEvent",
        "accessibility.sendAccessibilityEvent",
    }
    fact_names = set(re.findall(r"^\|\s*(accessibility[\w.]*|onAccessibility\w+|accessibility\.sendAccessibilityEvent)",
                                facts, re.M))
    unknown = fact_names - registered
    check("事实表属性均在源码注册表白名单内", not unknown, f"未知项: {sorted(unknown)}")
    # 事实表必须为每个通用属性行带来源（含 frameworks/ 路径）与下限 API
    rows = [ln for ln in facts.splitlines() if ln.startswith("| accessibility") or ln.startswith("| onAccessibility")]
    no_source = [ln.split("|")[1].strip() for ln in rows
                 if "frameworks/" not in ln and "treeviewv2" not in ln]
    check("事实表每行带来源", not no_source, f"缺来源: {no_source}")
    no_ver = [ln.split("|")[1].strip() for ln in rows if "API" not in ln]
    check("事实表每行带 API 版本标注", not no_ver, f"缺版本: {no_ver}")
    check("事实表含 accessibilityPreferred 合并文本规则", "accessibilityPreferred" in facts)

    print("== D. templates 属性合规性 ==")
    fact_vocab = registered | {"accessibility.EventInfo"}
    for tpl in ["templates/basic_attributes_template.ets",
                "templates/group_announcement_template.ets",
                "templates/event_focus_template.ets",
                "templates/virtual_node_template.ets"]:
        content = read(tpl) or ""
        used = set(re.findall(r"\.(accessibility\w+|onAccessibility\w+)\s*(?:\(|,|\()", content))
        used |= set(re.findall(r"\.(accessibility\w+|onAccessibility\w+)", content))
        bad = {u for u in used if u not in fact_vocab}
        check(f"{os.path.basename(tpl)} 属性均在事实表词汇内", not bad, f"越界: {sorted(bad)}")

    # vod-5 回归防护：virtualNode 模板基线为单 Text 直述，禁止裸 group 包裹反例
    vn_tpl = read("templates/virtual_node_template.ets") or ""
    check("virtual_node_template 含单 Text 直述基线",
          "单个 Text 直述" in vn_tpl or "单个 Text 直接描述" in vn_tpl)
    check("virtual_node_template 无裸 .accessibilityGroup(true) 包裹反例",
          ".accessibilityGroup(true)" not in vn_tpl)
    check("virtual_node_template 含 accessibilityPreferred 正解", "accessibilityPreferred" in vn_tpl)

    # vod-6 回归防护：nextFocusId 简约性——模板不得教默认值冗余参数与源组件冗余 id
    ef_tpl = read("templates/event_focus_template.ets") or ""
    check("event_focus_template 无默认值冗余 isConsiderDescendants: false",
          "isConsiderDescendants: false" not in ef_tpl)
    check("event_focus_template 含仅目标加 id 简约性说明", "仅目标组件需要" in ef_tpl)
    check("SKILL.md 含第 6 步代码简约性检查", "代码简约性检查" in skill)

    print("== E. 用例集完整性 ==")
    cases = read("test-cases/cases-b01-b20.md") or ""
    for i in range(1, 21):
        check(f"用例 B{i:02d} 存在", f"B{i:02d}" in cases)
    case_apis = set(re.findall(r"(accessibility\w*|onAccessibility\w+)", cases))
    option_fields = {"accessibilityPreferred"}  # group options 字段（vod-5 正解），非独立 API
    bad_case = {a for a in case_apis if a not in fact_vocab and not a.startswith("Accessibility")
                and a not in option_fields}
    check("用例引用 API 在事实表词汇内", not bad_case, f"越界: {sorted(bad_case)}")

    print(f"\n结果: {PASSED} PASS, {len(FAILURES)} FAIL")
    if FAILURES:
        for f in FAILURES:
            print(f"  - {f}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
