# ArkUI 无障碍（屏幕朗读）适配

`hmos-arkui-accessibility-skill` 是指导开发者为 ArkUI 应用适配无障碍（屏幕朗读）能力的 Agent Skill。它先判断"要不要适配"（很多场景 ArkUI 默认已支持），再通过 A~G 诉求路由选对属性，同时内置 API 版本门禁和语义规则，避免生成无法编译或播报错误的代码；纯知识问句（支持哪些无障碍能力/默认使能/某接口是什么）走知识问答模式，零代码作答。

工作流程和约束以 [SKILL.md](../SKILL.md) 为准。

## 适用场景

| 场景 | 处理目标 |
| --- | --- |
| 默认能力判定 | 判断现有组件是否已被屏幕朗读默认支持（自动播报组件类型、文本、操作结果、状态），避免过度适配 |
| A 无文本播报 | 图标、图片等无文字元素读屏听不出用途，补"是什么"（`accessibilityText`） |
| B 操作后果说明 | 聚焦只播"单指双击即可执行"太含糊，补"点了会怎样"（`accessibilityDescription`） |
| C 聚合播报 | 日期等多段碎文本要分别聚焦多次，改成一次读完（`accessibilityGroup`） |
| D 可识别性控制 | 装饰元素别读出来、关键操作必须能聚焦（`accessibilityLevel`） |
| E 选中状态 | 复选框/开关/单选列表读不出"选没选"（`accessibilityChecked` / `accessibilitySelected`） |
| F 自绘组件读屏 | Canvas 折线图、仪表盘等自绘内容读屏完全读不到（`accessibilityVirtualNode`） |
| G 自定义走焦 | 指定读屏首焦点或下一个聚焦对象（`accessibilityDefaultFocus` / `accessibilityNextFocusId`） |
| Q 知识问答 | 纯知识问句（"支持哪些无障碍能力""哪些默认使能""accessibilityText 是什么"），按事实表能力总览作答，零代码、零工程文件读取 |
| VOD 实测场景 | 历史开发者问题沉淀：操作提示动态开关（vod-7）、空文本组件跳焦兜底（vod-8）、group 角色参数版本答疑（vod-9） |

## 快速开始

### 准备输入

使用前提供以下信息，能够帮助 Agent 确定路由方案和适配代码：

- 包含目标组件的 `.ets` 文件路径或代码片段。
- 无障碍诉求描述（如"图标读屏听不出是干嘛的"、"三段文字太碎想一次读完"）。
- 工程 `build-profile.json5` 的 SDK/API 版本（涉及有下限的属性时必需，缺失会被追问而不是臆测）。

### 加载 Skill

在支持 Agent Skills 的助手中，引用 Skill 根目录的 [SKILL.md](../SKILL.md)，并保留完整目录，以便按需读取 `references/` 和 `templates/`。

### 提示词示例

**无文本图标（A 类）：**

```text
使用 hmos-arkui-accessibility-skill，页面里的播放图标没有文字，
读屏用户听不出它是干什么的，帮我加上说明。
```

**聚合播报 + 组内例外（C 类）：**

```text
使用 hmos-arkui-accessibility-skill，把生日的三段文字合成一次播报。
```

**自绘内容（F 类）：**

```text
使用 hmos-arkui-accessibility-skill，用 Canvas 画的折线图读屏完全读不到，
请让读屏能读出当前的数据趋势。
```

## 目录与参考文档

```text
hmos-arkui-accessibility-skill/
├── SKILL.md                              # Skill 主文件：第 0~6 步工作流（含知识问答模式/快路径）、A~G 路由表、语义规则、检查清单
├── assets/
│   └── README.md                         # 使用说明和提示词示例
├── references/
│   ├── api-facts.md                      # 能力总览（默认使能 vs 需主动适配）+ 属性/事件事实表：签名、下限 API、来源
│   ├── decision-matrix.md                # A~G 详表、checked/selected 对比、组合诉求示例
│   ├── group-dynamic-announcement.md     # 聚合播报与动态播报（sendAccessibilityEvent）
│   ├── event-and-focus.md                # 触摸/聚焦事件回调与自定义走焦
│   ├── virtual-node.md                   # Canvas/自绘虚拟节点方案
│   └── faq-vod.md                        # 已知缺陷与编译报错答疑
├── templates/
│   ├── basic_attributes_template.ets     # A/B/D/E 基础属性组合模板
│   ├── group_announcement_template.ets   # C 聚合 + 反 group 模板
│   ├── event_focus_template.ets          # 事件回调 + 走焦 + 动态播报模板
│   └── virtual_node_template.ets         # F 虚拟节点模板
└── test-cases/
    ├── trigger.md                        # 触发验证用例（正向/负向各 1 例）
    ├── functional.md                     # 功能用例（D0 门、知识问答、A~G 路由、版本门禁、VOD 实测共 35 例）
    ├── cases-b01-b20.md                  # B01~B20 评测用例
    ├── test-prompts.md                   # 测试工程提示词（API 26 放行侧 / API 10 阻断侧）
    ├── check_skill.py                    # 结构与事实一致性自检脚本
    ├── report-template.md                # 评测报告模板
    ├── Accessibility-before/             # 放行侧测试工程（API 26，26 页）
    └── Accessibility-api10-before/       # 阻断侧测试工程（API 10，9 页 + B26 内联答疑用例）
```

| 参考文档 | 何时阅读 |
| --- | --- |
| [API 事实表](../references/api-facts.md) | 核对属性签名、下限 API、播报优先级等事实 |
| [决策矩阵](../references/decision-matrix.md) | 诉求路由拿不准、checked/selected 二选一、组合诉求拆解 |
| [聚合与动态播报](../references/group-dynamic-announcement.md) | 整组朗读降噪、内容变化后主动播报 |
| [事件与走焦](../references/event-and-focus.md) | 触摸预览、聚焦回调、首焦点/下一焦点 |
| [虚拟节点](../references/virtual-node.md) | Canvas/自绘内容适配 |
| [已知缺陷答疑](../references/faq-vod.md) | accessibilityText 不生效、编译报错排查 |

## 诉求路由速查

| 诉求 | 关键属性 | 下限 API |
| --- | --- | --- |
| A 无文本元素能读懂 | `accessibilityText` | 12 |
| B 说明操作后果 | `accessibilityDescription` | 10 |
| C 整组朗读降噪 | `accessibilityGroup(true)` | 12 |
| D 控制可识别性 | `accessibilityLevel`（auto/yes/no/no-hide-descendants） | 12 |
| E 传达选中状态 | `accessibilityChecked` / `accessibilitySelected` | 13 |
| F 自绘组件读屏 | `accessibilityVirtualNode` | 11 |
| G 自定义走焦 | `accessibilityDefaultFocus` / `accessibilityNextFocusId` | 18 |
| Q 知识问答 | 无属性落地，按 `references/api-facts.md` 能力总览作答（含路由表未覆盖的 role/stateDescription/customActions/scrollTriggerable） | — |

组合诉求（如 A+E、C+D+A）会一次落齐，不留半成品。纯知识问句走知识问答模式（零适配代码）；"为什么编译报错/为什么不生效"走通用答疑模式（`references/faq-vod.md`）。工程 build-profile.json5 三字段任一低于下限时，Skill 会阻断并给出版本提升建议，不输出该属性任何代码（包括"方案示意"形式）；options 参数版本独立于属性本体，逐参数核对（group 角色参数 23+ 等）。

## 常见错误警告

本 Skill 内置强制检查项，以下写法会导致播报异常或编译错误：

1. **覆盖语义** — 组件既有文本又设 `accessibilityText` 后，**原文本不再播报**（如 Button"提交订单"设 text"支付 99 元"后只播后者）。就地修改前 Skill 会强制提示并等待确认；开发者已明确知晓后果并确认、或明确指示直接修改（"请直接帮我修改"）时，视为已取得确认，直接落地并在输出中重申该后果。
2. **virtualNode 禁止包裹写法** — 必须直传 @Builder 方法引用：`.accessibilityVirtualNode(this.xxx)`；lambda 包裹和 `{ builder: ... }` 对象包裹都会编译报错。
3. **virtualNode builder 内容基线** — builder 内用**单个 Text 直接描述**即可（Text 默认播报能力够用，无需叠加属性）；禁止"容器 `accessibilityGroup(true)` + 子 accessibilityText"组合——容器无自身文本时合并文本只拼子组件**通用文本**，无障碍文本被丢弃（只播'仪表盘'而非完整描述）；确需分组用 `.accessibilityGroup(true, { accessibilityPreferred: true })`。
4. **Checkbox 无 onSelect** — 状态同步用受控三要素：`@State` + `.select(state)` + `.onChange()`，再挂 `.accessibilityChecked(state)`；写 `.onSelect()` 直接编译失败。
5. **onAccessibilityHover 是双参数** — 回调签名 `(isHover: boolean, event: AccessibilityHoverEvent)`，只写一个 event 参数编译报错。
6. **checked 与 selected 不混用** — checked 表物理勾选状态（Checkbox/Toggle），selected 表互斥单选当前项（List/Tabs）；selected 只在**读屏焦点节点**（自身文本/onClick/内建点击）上被播报，按三同原则逐项挂载在与内容、视觉选中态、点击交互同一节点的选项语义容器上。
7. **冗余代码不生成（代码简约性）** — 只做最小最精准修改：id 只加在被指向的目标组件（nextFocusId 的源组件不加）；与默认值一致的参数不显式传（`isConsiderDescendants` 默认 false，跳过目标子节点直接省略第二参数）；与诉求无关的属性/样式/事件一律不加。

## 验证与交付

适配完成后，应检查以下项目并尽量在真实工程中执行构建验证：

- 涉下限属性已核对 build-profile.json5 三字段，版本不满足时未生成代码。
- text 只说"是什么"、description 只说"点了会怎样"，状态信息没有塞进 text。
- 组合诉求一次落齐（如 A+E：text 传用途、checked 传状态）。
- level 用了显式取值（确定性诉求不给 `auto`）。
- 已过代码简约性检查：无与诉求无关的冗余 id/属性/事件，未显式传与默认值一致的参数。
- 生成代码未命中上述常见错误，附改前/改后播报差异说明。

测试场景见 [test-cases/trigger.md](../test-cases/trigger.md) 和 [test-cases/functional.md](../test-cases/functional.md)。前者验证 Skill 触发判定（无障碍诉求应触发、无关诉求不触发）；后者提供 35 个功能用例，覆盖默认能力判定、知识问答（Q 类）、A~G 全部路由类别、低版本阻断路径与 VOD 实测场景（vod-7/8/9）。结构与事实一致性自检：在 skill 根目录执行 `python3 test-cases/check_skill.py`。能力与用例明细以 [SKILL.md](../SKILL.md) 与 `references/`、`test-cases/` 为准。
