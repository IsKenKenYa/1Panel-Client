---
name: hmos-arkui-accessibility-skill
description: Guides ArkUI/HarmonyOS screen-reader accessibility adaptation — routes demands to accessibility/focus attributes with semantic guardrails and build-profile.json5 version gating; answers knowledge-only questions (零代码). Use when the user mentions 接入/适配无障碍, 读屏/屏幕朗读, 播报文本, 聚合播报, 自定义走焦/首焦点, Canvas 自绘读不到, 支持哪些无障碍能力/默认使能/接口是什么（问答）, accessibility 编译报错, or edits .ets involving accessibility* attributes.
license: MIT
metadata:
  version: "1.6.1"
---

# ArkUI 通用无障碍快速接入 Skill

帮助开发者为 ArkUI 应用快速、正确地适配无障碍能力（屏幕朗读等辅助技术）。

## 核心工作流程（必须按序执行）

**快路径（触发/范围判定类输入）**：开发者仅要求判断诉求是否属于本 Skill 处理范围（如"只判断
是否属于处理范围，简短说明，不展开适配方案"）时，直接依据第 1 步路由表给出判定结论与依据即可
——**不读取任何文件、不做版本门禁、不生成适配代码**。

**知识问答模式（Q 类·能力/接口知识问句，先于第 0 步判定）**：开发者仅询问 ArkUI 无障碍能力
与接口知识（如"ArkUI 都支持哪些无障碍能力""哪些默认使能、哪些需要主动适配"
"accessibilityText 是什么/什么意思"），无"帮我改/适配/实现"意图、未指定待适配组件时，进入
本模式，依据 `references/api-facts.md`（能力总览 + 属性/事件事实表 + 默认值清单）作答，必要时
按知识库索引深读对应 references——**不读取工程文件（含 build-profile.json5）、不做版本门禁、
不进入第 0~6 步**。与 D0 的分界：针对开发者**自己的应用**的泛化适配诉求（"从哪里开始适配"）
仍走第 0 步 D0 门；本模式只答平台/接口知识本身。

回答框架（按问句类型）：

- **能力全景**（"都支持哪些无障碍能力"）：先说明默认使能（屏幕朗读四要素：组件类型、文本
  内容、操作结果、当前状态，有文本标准组件免适配），再按 7 类清单逐项给一句语义 + 下限 API
  （播报内容 / 聚合与可见性 / 状态语义 / 自绘与走焦 / 交互行为 / 事件回调 / 动态播报）——
  口径以 `references/api-facts.md` 能力总览为准，且**必须显式包含路由表未覆盖的 4 个接口**：
  `accessibilityRole`、`accessibilityStateDescription`、`accessibilityCustomActions`、
  `accessibilityScrollTriggerable`（缺任一即清单不完整）；
- **默认 vs 主动适配**（"哪些默认使能、哪些要自己适配"）：两栏对照——默认使能（四要素，
  有文本标准组件零属性）vs 需主动适配（按能力类别列接口清单）；
- **具体接口**（"accessibilityText 是什么/怎么用"）：四元组——签名 / 下限 API / 关键语义
  （含陷阱与默认值，以事实表与默认值清单为准）/ 关联深读文档；允许**一行级内联用法示意**
  （如 `.accessibilityText('播放')`），不输出完整适配方案或多行代码；
- **版本口径**：回答中的"下限 API"仅为事实陈述，不构成对开发者工程的门禁判定（不读
  build-profile.json5，不发起版本追问）；
- **知识边界**：事实表未覆盖的问题（如 @ohos.accessibility 完整接口契约），明示超出本
  Skill 知识范围，已知的部分注明来源可信级别（源码/官方文档），不臆造；
- **混合输入**（知识问句 + 明确适配诉求，如"virtualNode 怎么用？顺便把我的折线图改了"）：
  拆分处理——知识部分按本模式回答，适配部分进入核心工作流（第 0 步起，含版本门禁与代码落地）。

### 第 0 步：D0 默认能力门（先判"要不要适配"）

ArkUI 默认已支持屏幕朗读，自动播报四要素：**组件类型、文本内容、操作结果、当前状态**。
有文本内容的标准组件（如 Button：朗读"按钮，提交订单，单指双击即可执行"）**无需适配**。

- 开发者诉求**泛化**（如"要从哪里开始适配无障碍"）：先输出 D0 门说明——默认播报四要素、
  需要额外适配的边界（无文本图标/图片、自绘内容、需显式状态语义、聚合/走焦等高阶诉求）、
  无障碍可达三前提（可识别、功能及操作信息、状态与行为）——然后**明确询问**默认能力是否满足，
  此时**不直接生成属性代码**。
- 诉求**明显超出**默认能力（如"图标读屏听不出是干嘛的"）：跳过 D0，直接进入第 1 步路由
  （如无文本图标 → A 无文本播报）。
- 默认可满足：明确告知"已默认适配，无需额外设置"，**不输出多余属性代码（避免过度适配）**，收尾。

### 第 1 步：诉求路由（A~G）

| 诉求 | 开发者会怎么说 | 属性 | 下限 API |
|---|---|---|---|
| D0 | 默认屏幕朗读够用吗？ | 无需适配 | — |
| A 让无文本元素能读懂 | "图标按钮读屏听不出是干嘛的" | `accessibilityText` | 12 |
| B 说明操作后果 | "聚焦只播'单指双击即可执行'太含糊" | `accessibilityDescription` | 10 |
| C 整组朗读降噪 | "日期三个 Text 分开读，很碎" | `accessibilityGroup(true)` | 12 |
| D 控制可识别性 | "关键操作要能被聚焦 / 装饰元素别读出来" | `accessibilityLevel`（`auto`/`yes`/`no`/`no-hide-descendants`；auto 决策指引见第 3 步规则 5） | 12 |
| E 传达选中状态 | "复选框/单选项读不出选没选" | `accessibilityChecked`（二态/三态）/ `accessibilitySelected`（互斥单选，**逐项挂载**，见第 3 步规则 4） | 13 |
| F 自绘制组件读屏 | "Canvas/自绘内容读屏读不到" | `accessibilityVirtualNode`（**@Builder 方法引用直传**，禁 lambda/对象包裹；builder 内**单个 Text 直述**，禁容器 group(true)+子 accessibilityText 组合） | 11 |
| G 自定义走焦 | "自定义首焦点 / 下一个获焦焦点" | `accessibilityDefaultFocus` / `accessibilityNextFocusId(id, { isConsiderDescendants? })`（子节点控制走第二参数，非独立属性；**仅目标组件加 `.id()`**，源组件不加；isConsiderDescendants 默认 false，默认行为不传参；**单独落 defaultFocus 的答复必须对比两者语义差异**：defaultFocus=页面默认/首个焦点，nextFocusId=指定某组件获焦后的下一获焦节点） | 18 |

路由判定后**说明判定依据**（对应开发者原话）。组合诉求（如 A+E、C+D+A）一次落齐，不留半成品。
详表与对比见 `references/decision-matrix.md`。

诉求路由决策树（自上而下逐级判定）：

```text
答疑类输入（"为什么编译报错/为什么不生效"）→ 通用答疑模式（faq-vod.md）：读属性/参数名查
事实表下限 API（含 options 参数版本分层，如 group 角色参数 23+，vod-9）→ 读 build-profile
三字段 → 任一低于下限：说明原因 + 字段提升建议，不输出该属性代码

诉求是否明确超出默认能力？
├─ 否（泛化"从哪里开始"）→ D0 门：说明默认四要素 + 适配边界 + 三前提，
│   询问默认能力是否满足，不生成代码
├─ 是（具体诉求）→ A~G 路由：
│   ├─ 无文本元素听不出用途 → A：accessibilityText
│   ├─ 操作后果太含糊 → B：accessibilityDescription
│   ├─ 多段文本分开读太碎 → C：容器 accessibilityGroup(true)
│   ├─ 聚焦/隐藏确定性控制 → D：accessibilityLevel 显式取值
│   │   （只藏自身 no / 连后代 no-hide-descendants / 强制可识别 yes）
│   ├─ 选中状态听不出 → E：物理状态 checked / 互斥单选 selected
│   ├─ Canvas/自绘读不到 → F：accessibilityVirtualNode（@Builder 引用直传）
│   ├─ 触摸预览 → 事件：onAccessibilityHover（12+，双参）
│   ├─ 聚焦移入/移出回调 → 事件：onAccessibilityFocus（18+）
│   └─ 首焦点/下一焦点 → G：defaultFocus / nextFocusId(id, { isConsiderDescendants? })
└─ 组合诉求（A+E、C+D+A 等）→ 合并对应路径，一次落齐
```

### 第 2 步：API 版本门禁（涉及有下限的属性时必做）

读取工程 `build-profile.json5` 三字段：`compileSdkVersion` / `compatibleSdkVersion` / `targetSdkVersion`：

- 任一字段 **低于属性下限** → 阻断该属性路径：说明需 API X+，给出提升字段的具体修改建议，
  **不输出该属性的任何代码**——包括"方案示意""仅供参考""版本就绪后可用"等形式的代码块
  （阻断≠报错，是主动拦截；仅输出阻断说明与版本提升建议，页面保持原始态）。
- 字段缺失/文件缺失（如开发者仅提供内联代码片段，上下文中无 build-profile.json5）→ 直接按第 5 步
  向开发者追问版本信息，**不发起文件系统搜索**，不臆测放行。
- 焦点类（API 18+，如 accessibilityDefaultFocus/NextFocusId/onAccessibilityFocus）：对满足版本的工程
  仅做版本软提示，不阻断。
- **options 参数版本分层（独立于属性本体，逐参数标注）**：`accessibilityGroup` 第二参数
  `accessibilityPreferred` 需 14+，`stateControllerRoleType` / `actionControllerRoleType` 需 **23+**
  （低于 23 编译报错，vod-9）；`accessibilityNextFocusId` 的 `isConsiderDescendants` 需 26+。
- 事件回调版本差异：`onAccessibilityHover` 需 12+（回调**双参** `(isHover: boolean, event: AccessibilityHoverEvent)`；触摸/预览类诉求用它），`onAccessibilityFocus` 需 18+（聚焦移入/移出用它），两者不混用，逐方法标注。

### 第 3 步：语义硬规则（输出前强制自检）

1. **A/B 职责边界**：`accessibilityText` = 是什么（功能简述）；`accessibilityDescription` = 点了会怎样
   （操作后果/不可用原因）。text 中不放操作引导与状态信息。
2. **覆盖语义（强制确认）**：组件既有文本又设 `accessibilityText` 时，**原文本不再播报**。
   就地修改既有文本组件前，必须先向开发者提示该后果并取得确认，未确认前不修改。以下两类输入
   **视为已取得确认**，直接落地并在输出中重申该后果，不再二次追问：
   - 诉求中已明确知晓该后果并确认（如"我知道原文本不再播报，确认修改"）；
   - 明确指示直接修改（如"请直接帮我修改"、"直接改"）。
3. **替代语义**：`accessibilityDescription` 替代系统默认新手提醒；用户关闭新手提醒开关后
   description 也不播报——不能承诺"必达"。
4. **checked vs selected**：checked = 控件物理状态（二态/三态，Checkbox/Toggle）；
   selected = 互斥单选当前项（List/Tabs）。**selected 使能前提 + 逐项挂载 + 三同原则**：
   使能前提——selected 只在**读屏焦点节点**上被播报（节点自身有文本 / 挂 onClick / 组件内建
   点击三选一）。逐项挂载于与
   **内容、视觉选中态、点击交互同一节点**的选项语义容器（每项独立布尔 `state === i`）——
   List 挂项内容容器（如 Row，onClick 同层；onClick+selected 同挂 ListItem 亦可，B23 实测）；
   **禁止错位**：挂 Tabs/List 容器整仓单一布尔（切到其余项时听不出选中）；输出对比表（见 decision-matrix）。
5. **level 取值与 auto 决策指引**：仅 `auto` / `yes` / `no` / `no-hide-descendants`（`no` 只隐藏当前节点，
   `no-hide-descendants` 连同后代隐藏；源码级枚举无 `default` 成员，但**属性默认值为 `auto`**（官方文档）
   ——显式 `yes`/`no`/`no-hide-descendants` 均为**非默认取值**，属有效确定性设置）。`auto` 决策指引：
   - **支持场景**：组件无确定性聚焦/隐藏诉求、维持系统默认行为时，可建议 `auto`，并说明其语义
     ——由无障碍服务与 ArkUI 按组件类型和内容综合判断，**不保证聚焦或隐藏结果**；
   - **不支持场景**：诉求为"关键操作必须可聚焦"、"元素必须不播报"等**确定性要求**时，
     **不输出 `auto` 方案**，改给 `yes` / `no` / `no-hide-descendants` 显式取值建议；
   - **必传信息**：向开发者明确传递"`auto` 结果不确定，确定性诉求须使用显式取值"；
   - **默认值边界（防误删）**：`yes`/`no`/`no-hide-descendants` 都不是默认值，任何情况下都不是
     "与默认值一致的冗余参数"；开发者提出确定性诉求（如"返回按钮必须保留能读"）时**必须显式落码**，
     不得以"组件系统默认已可读/可聚焦"为由省略——**组件默认行为 ≠ 属性默认值**（完整默认值清单见
     `references/api-facts.md`）。
6. **反 group**：group 后组内某组件仍需单独朗读 → 该组件 `accessibilityLevel('yes')`。
7. **播报优先级**：`accessibilityText` 不为空时朗读无障碍文本，否则朗读显示文本。
8. **group 合并文本（C/F 类必检）**：父组件设 `accessibilityGroup(true)` 且自身无通用文本、
   未设 accessibilityText 时，合并文本默认**拼接子组件通用文本，不使用子组件 accessibilityText**
   （播报残缺，vod-5）。规避：子组件通用文本直述完整描述 / 容器设 accessibilityText /
   `accessibilityGroup(true, { accessibilityPreferred: true })`（优先取子无障碍文本，较新参数输出前核对版本）。
9. **文案质量**：text 支持字符串或资源引用，简洁达意。
10. **签名硬约束（编译红线）**：
    - `accessibilityVirtualNode` 直传 @Builder 方法引用：`.accessibilityVirtualNode(this.customAccessibilityNode)`；
      lambda 包裹 `() => { this.xxx(); }` 与对象包裹 `{ builder: ... }` **均编译报错**；
      builder 内容用**单个 Text 直述**（默认播报即可，无需叠加属性），禁容器
      `accessibilityGroup(true)`+子 `accessibilityText` 组合（合并文本只拼子组件通用文本，
      无障碍文本被丢弃，vod-5）；确需分组用 `{ accessibilityPreferred: true }`；
   - `onAccessibilityHover` 回调为**双参** `(isHover: boolean, event: AccessibilityHoverEvent)`，
     单参数写法编译报错；触摸/预览诉求用 hover（12+），聚焦移入/移出用 `onAccessibilityFocus(isFocus)`（18+）；
    - `accessibilityNextFocusId` 子节点控制走**第二参数** `{ isConsiderDescendants: boolean }`（API 26+），
      不是独立属性；isConsiderDescendants **默认 false**，跳过目标子节点（默认行为）**不传第二参数**，
      仅进入目标子节点时显式传 true；**仅目标组件需要 `.id()`**，源组件（挂 nextFocusId 的组件）不加 id；
    - Checkbox **无 onSelect 方法**，状态同步用 `@State` + 受控 `.select(state)` + `.onChange()` 三要素。
11. **操作提示动态开关（vod-7）**：诉求"仅某状态播默认'单指双击即可执行'、另一状态不播" →
    `.accessibilityDescription(state ? ' ' : '')`：空串分支=保留系统默认操作提示（空串即默认值，
    但此处是**行为开关分支**，非冗余），非空分支（空格 `' '`）=替代后不再播报；第 6 步不得按
    简约性删空串分支。
12. **空文本跳焦兜底（vod-8）**：显示文本可能为空的组件（如 Text 绑定可空状态变量）内容为空串时
    会被读屏跳焦（"焦点自动跳到下一个组件"）→ `.accessibilityText(content === '' ? ' ' : content)`：
    空串兜底空格保焦点，非空原样传入；**禁止误路由** level('yes')/nextFocusId（根因是内容为空，
    非可识别性/走焦问题）。

### 第 4 步：输出模式（按开发者意图）

- **方案模式**：输出适配方案 + 改前/改后播报差异说明，不改文件。
- **就地模式**：目标唯一明确时在原属性链上**追加**属性，保留既有属性/样式/事件链，
  展示改动说明与路由依据，不改无关文件。
- 意图不明 → 追问确认模式。

### 第 5 步：信息不足时追问

缺组件类型、缺诉求、缺 build-profile 版本字段时，针对缺失项追问（限定在无障碍适配必需信息内），
不输出臆造方案。

### 第 6 步：代码简约性检查（输出前最后自检）

对将要输出的代码做最小化审视，命中以下任一项即**删除后再输出**：

- **无业务用途的冗余代码**：与诉求无关的属性/样式/事件/id 一律不生成——典型：nextFocusId
  场景给**源组件**（挂 nextFocusId 的组件）加 `.id()`，id 只是被指向的**目标组件**需要的
  （2026-10 评测 redundant_id 实测，vod-6）；
- **参数值与默认值一致**：显式传默认值不改变行为、徒增噪音——典型：
  `.accessibilityNextFocusId(id, { isConsiderDescendants: false })`（false 为默认值，直接省略
  第二参数）、`accessibilityChecked(undefined)`（等价于不设置）。默认值判定**只以官方默认值清单为准**
  （`references/api-facts.md`：level=`'auto'`、group=`false`、text/description=`""`、
  checked/selected=`undefined`、defaultFocus=`false`、isConsiderDescendants=`false`），
  **禁止以"组件默认行为已满足"推断某取值为默认值而删除**——如 `accessibilityLevel('yes')`
  （默认值是 `'auto'` 不是 `'yes'`）永远不是默认值参数，确定性诉求（"必须能读/必须可聚焦"）的
  显式取值不得按简约性删除；**动态分支例外（vod-7/vod-8）**：三元/条件表达式中作为分支取值的
  默认值是**行为开关**，不属冗余——`description(state ? ' ' : '')` 的空串分支（保留默认操作提示）、
  `text(content === '' ? ' ' : content)` 的空串兜底（保焦点），不得删除；
- **重复/已有能力**：开发者代码已具备的能力不重复输出；默认能力可满足的场景零属性收尾
  （回 D0 门）。

目标：**最小、最精准**的修改满足开发者诉求——每一行新增代码都能对应诉求本身，删掉任何一行
都不再成立。

## 知识库索引（references 目录）

| 文件 | 内容 | 何时读 |
|------|------|--------|
| `references/api-facts.md` | 能力总览（默认使能 vs 需主动适配）+ 属性/事件事实表（签名/下限 API/来源）+ 默认值清单 | 任何属性用法输出前；知识问答模式作答 |
| `references/decision-matrix.md` | A~G 详表、checked/selected 对比、反 group、组合诉求、组件类别接口选择 | 路由判定与组合诉求 |
| `references/group-dynamic-announcement.md` | 聚合播报与动态播报（sendAccessibilityEvent） | C 类诉求/动态更新 |
| `references/event-and-focus.md` | 事件响应（hover/focus）与自定义走焦 | 事件回调/走焦诉求 |
| `references/virtual-node.md` | Canvas/自绘虚拟节点方案 | F 类诉求 |
| `references/faq-vod.md` | 已知缺陷与编译报错答疑（vod-1~9 + 通用答疑模式） | text 不生效/编译报错/"为什么报错"答疑 |

## 代码模板（templates/）

- `templates/basic_attributes_template.ets` — A/B/D/E 基础属性组合
- `templates/group_announcement_template.ets` — C 聚合 + 反 group
- `templates/event_focus_template.ets` — 事件回调 + 走焦 + 动态播报
- `templates/virtual_node_template.ets` — F 虚拟节点

输出代码时以模板为基线，按第 2/3 步做版本与语义适配。

## 输出前检查清单

- [ ] 知识问答模式：纯知识问句依据 api-facts.md 能力总览/事实表作答（含下限 API 与默认值），仅一行级用法示意；零工程文件读取、零版本门禁、零适配代码；混合诉求已拆分处理（知识段问答 + 适配段走工作流）
- [ ] D0 门：泛化诉求先说明默认能力并询问，未确认前不生成代码；默认可满足时零属性收尾
- [ ] 版本门禁：涉下限属性已读 build-profile.json5 三字段，任一低于下限即阻断并给字段提升建议，阻断时零属性代码输出（含"方案示意"形式）
- [ ] A/B 职责：text=是什么、description=点了会怎样，text 中无操作引导与状态信息
- [ ] 覆盖语义：既有文本组件设 text 前已提示"原文本不再播报"并取得确认
- [ ] checked/selected：物理状态用 checked、互斥单选用 selected，未混用；selected 按使能前提（挂载节点为读屏焦点节点：自身文本/onClick/内建点击）+ 三同原则逐项挂载于选项语义容器（内容+视觉态+交互同节点）
- [ ] level 取值：确定性诉求未输出 auto，使用 yes/no/no-hide-descendants 显式取值（显式取值均非默认值——默认值为 auto；不以"默认已可读"为由省略落码）
- [ ] 签名硬约束：virtualNode @Builder 引用直传（无 lambda/对象包裹）、builder 内单个 Text 直述（无 group 容器+子 accessibilityText 组合）、hover 双参、nextFocusId 子节点控制走第二参数、Checkbox 用 onChange（无 onSelect）
- [ ] G 类语义差异：首焦点（defaultFocus）诉求的答复已对比 nextFocusId 语义差异（defaultFocus=页面默认/首个焦点，nextFocusId=指定某组件获焦后的下一获焦节点），单独使用 defaultFocus 时不遗漏该对比
- [ ] group 合并文本：group 容器无自身文本时未依赖子组件 accessibilityText 承载合并语义（规避三选一已说明，必要时 accessibilityPreferred: true）
- [ ] 动态播报控制（vod-7/8）：操作提示按状态开关用 description(state ? ' ' : '')（空串=默认提示）；空文本跳焦用 text 空格兜底；三元默认值分支未被简约性误删；未误路由 level/nextFocusId
- [ ] options 参数版本分层：group 角色参数（23+）、preferred（14+）、isConsiderDescendants（26+）逐参数核对，低于下限按门禁阻断（答疑类输入走通用答疑模式）
- [ ] 代码简约性（第 6 步）：无与诉求无关的冗余 id/属性/事件；未显式传与默认值一致的参数（如 isConsiderDescendants: false）；每行新增代码均对应诉求；默认值判定以 api-facts 默认值清单为准，不以系统默认行为推断（如 level('yes') 非默认值，不删）
- [ ] 组合诉求（如 A+E、C+D+A）一次落齐，无半成品
- [ ] 输出模式符合开发者意图（方案/就地/追问），就地模式保留原属性链与无关文件
