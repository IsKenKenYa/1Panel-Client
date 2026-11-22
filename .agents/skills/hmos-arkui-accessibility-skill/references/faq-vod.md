# 已知缺陷与编译报错答疑（vod）

> 需求方 vod 记录 + 本仓源码核验结论。答疑时先判版本，再给结论。

## vod-1：AccessibilityText 不生效

**现象**：Search 组件和 Toggle 组件设置 `accessibilityText` 属性后不生效（播报仍为默认内容）。

**排查路径**（按序）：

1. **版本**：accessibilityText 需 API 12+，核对 build-profile 三字段；
2. **覆盖语义**：确认没有同节点更晚设置的同名属性或组件内部文本优先级场景；
3. **组件特化实现**：多数组件在各自 pattern 下有 `*_accessibility_property.h` 特化（KB 路由
   `docs/kb/architecture/accessibility.md`），Search/Toggle 的特化实现决定最终播报内容；
   特化组件上通用属性表现以当前版本源码为准；
4. **规避**：若特化组件不满足诉求，可用相邻容器承载语义（容器加 accessibilityText）或
   accessibilityDescription 补充，必要时反馈缺陷单。

**状态**：需求方 vod 在案（缺陷链接见 proposal_full.md vod 表）；Skill 输出答疑口径如上，
不承诺平台侧修复时间。

## vod-2：accessibilityStateDescription 编译报错

**现象**：开发者使用 `accessibilityStateDescription`，编译报错"接口未暴露"，只有
`accessibilityDescription` 可用。

**结论**：

- **版本门槛**：`accessibilityStateDescription` 为较新接口；旧版本 SDK 的 d.ts 未暴露会导致编译报错。
- **master 现状**：本仓 master 已注册该入口
  （源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10469-10470`，
  解析 `js_accessibility.cpp:128-137`），报错发生在**低于该接口起始版本的 SDK**。
- **处理**：
  1. 核对 build-profile 三字段，低于起始版本 → 提升版本或改用 `accessibilityDescription`（API 10+）替代；
  2. 注意替代差异：description 定位"操作后果/详细说明"且会替代新手提醒，stateDescription 定位"状态描述"，
     语义不同，替代时向开发者说明播报差异。

## vod-3：三处签名致首编失败（DevEco 260 / API 26 SDK 实测，2026-10 评测）

**现象**：按旧事实表输出代码，5 个页面首次编译报 7 个错误：

1. `Checkbox` 上 `.onSelect(...)` → `Property 'onSelect' does not exist on type 'CheckboxAttribute'`
   **正解**：Checkbox 状态同步用**受控三要素**——`@State` + `.select(state)` + `.onChange(cb)`，
   再挂 `.accessibilityChecked(state)`；
2. `.accessibilityVirtualNode({ builder: () => {...} })` → `'builder' does not exist in type '() => any'`
   **正解**：参数**直传 @Builder 方法引用** `.accessibilityVirtualNode(this.node)`
   （lambda 包裹同样违规，飘红见 vod-4）；
3. `.onAccessibilityHover((event: AccessibilityHoverEvent) => {...})` → 参数类型不兼容
   （`boolean` 不能赋给 `AccessibilityHoverEvent`）
   **正解**：回调为**双参数** `(isHover: boolean, event: AccessibilityHoverEvent) => {...}`。

**结论**：三处均已回写 `api-facts.md` / `virtual-node.md` / `event-and-focus.md` / 相关 templates；
后续输出以修订后事实表为准。事实表与其余 SDK 版本的差异，按"通用答疑模式"核对该版本 d.ts。

## vod-4：accessibilityVirtualNode lambda 包裹编辑器飘红（2026-10 评测 Accessibility-eval 实测）

**现象**：输出 `.accessibilityVirtualNode(() => { this.customAccessibilityNode(); })`，DevEco 编辑器飘红
"UI component syntax cannot be written here"（复现于 Accessibility-eval 工程 B10LineChart.ets /
B11Dashboard.ets）。

**结论**：CustomBuilder 参数必须以 **@Builder 方法引用直传**：
`.accessibilityVirtualNode(this.customAccessibilityNode)`；lambda 包裹（`() => { this.xxx(); }`）
与对象包裹（`{ builder: ... }`，见 vod-3）均禁止。

**回写**：已回写 `api-facts.md` / `virtual-node.md` / `virtual_node_template.ets` / 相关 test-cases。

## vod-5：group 合并文本丢弃子组件 accessibilityText（2026-10 评测 virtualNode 问题汇总实测）

**现象**：virtualNode builder（或任意容器）内写
`Column { Text('仪表盘').accessibilityText('仪表盘：当前转速 2450 转每分钟') }.accessibilityGroup(true)`，
读屏只播报'仪表盘'，完整描述未播报（非编译错误，属播报语义缺陷，更隐蔽）。

**根因**：父组件启用 `accessibilityGroup(true)` 且自身**无通用文本、未设 accessibilityText** 时，
合并文本默认**拼接子组件的通用文本**，**不使用子组件的无障碍文本**。

**正解**（按优先级）：

1. **基线**：builder 内**单个 Text 直接描述**（`Text('仪表盘：当前转速 2450 转每分钟')`），
   Text 默认播报能力即可满足，无需任何无障碍属性；
2. 确需分组且要保留子无障碍文本：`.accessibilityGroup(true, { accessibilityPreferred: true })`
   ——深度遍历子节点时优先取其无障碍文本（较新参数，下限版本以官方文档为准，输出前核对）；
3. 或在容器上设 `accessibilityText` 直接指定合并文本（注意先提示覆盖语义）。

**回写**：已回写 `api-facts.md` / `virtual-node.md` / `group-dynamic-announcement.md` /
`virtual_node_template.ets` / `SKILL.md` / 相关 test-cases；accessibilityGroup 连用场景
同步补充在 `group-dynamic-announcement.md` 常见错误表。

## vod-6：nextFocusId 冗余代码（源组件 id + 默认值参数，2026-10 评测 redundant_id 实测）

**现象**：B19"搜索框聚焦后，下一焦点跳过会员卡片子内容、直达'下一步'按钮"场景，输出给
搜索框（**源组件**）加了 `.id('search_input')`，并显式传
`.accessibilityNextFocusId('next_step', { isConsiderDescendants: false })`。功能不报错，
但两处均属冗余代码。

**根因**：id 是被指向方（**目标组件**）的定位符，源组件无需 id；`isConsiderDescendants`
默认值即 false（下一焦点落到目标本身、不进入其子节点），显式传默认值不改变行为。

**正解**：源组件仅挂 `.accessibilityNextFocusId('next_step')`（不传第二参数），目标组件挂
`.id('next_step')`。仅当需要**进入目标子节点**（B18 场景）才显式传 `{ isConsiderDescendants: true }`。
该结论已上升为 SKILL.md 第 6 步"代码简约性检查"通用规则：无业务用途的冗余代码、
与默认值一致的参数值，一律删除，保持最小最精准修改。

**回写**：已回写 `api-facts.md` / `event-and-focus.md` / `event_focus_template.ets` /
`decision-matrix.md` / `SKILL.md` / 相关 test-cases。

## vod-7：按状态动态开关"单指双击即可执行"操作提示（历史 VOD 实测）

**现象**：Text 播报内容随状态变量变化（如 isDownloading 切换"下载文件"/"文件已下载"），开发者希望
仅在某状态（可执行）播报系统默认操作提示"单指双击即可执行"，另一状态（已完成）不播。

**规格根因**：`accessibilityDescription` 非空时**替代**系统默认新手提醒（"单指双击即可执行"）；
空串（默认值）时保留默认播报。空格 `' '` 是"非空但不承载有意义内容"的占位，恰好实现关闭操作提示。

**正解**：三元切换——可执行状态传空串走默认提示，不可执行状态传空格覆盖：

```ts
Text(this.isDownloading ? '文件已下载' : '下载文件')
  .onClick(() => { /* 下载文件操作 */ })
  .accessibilityDescription(this.isDownloading ? ' ' : '')
```

**注意**：空串分支与属性默认值相同但**有语义**（"恢复默认操作提示"的行为开关），第 6 步简约性
检查不得删除（api-facts 默认值清单"动态分支例外"）。

**回写**：已回写 `api-facts.md`（description 行 + 默认值清单例外）/ `SKILL.md`（第 3 步规则 11、
第 6 步例外）/ `decision-matrix.md` / 相关 test-cases。

## vod-8：空文本组件被读屏跳焦（历史 VOD 实测）

**现象**：页面首个组件为显示状态变量的 Text（如 PageTwo 的 `Text(content)`），变量为空串时读屏
焦点自动跳到下一个组件（Button），首个组件被忽略；开发者诉求"不想让它自动跳"。

**规格根因**：显示文本为空的 Text **无可播报内容**，读屏遍历时跳过该节点（焦点丢失），非组件缺陷、
与可识别性/走焦属性无关。

**正解**：`accessibilityText` 空串兜底，内容为空时传空格占位保持可聚焦，非空时原样传入：

```ts
Text(`${this.content}`)
  .fontSize(50)
  .accessibilityText(this.content === '' ? ' ' : this.content)
```

**注意**：勿误路由 `accessibilityLevel('yes')` / `accessibilityNextFocusId`（根因是内容为空，
非可识别性或走焦问题）；兜底三元属行为开关，简约性检查不得删除。

**回写**：已回写 `api-facts.md`（text 行 + 默认值清单例外）/ `SKILL.md`（第 3 步规则 12、
第 6 步例外）/ `decision-matrix.md` / 相关 test-cases。

## vod-9：accessibilityGroup 角色参数低版本编译报错（历史 VOD 核查）

**现象**：API 22 工程使用
`.accessibilityGroup(true, { stateControllerRoleType: AccessibilityRoleType.TOGGLER, actionControllerRoleType: AccessibilityRoleType.TOGGLER })`
编译报错，开发者问"为什么这段代码在 accessibilityGroup 有编译报错"。

**规格根因**：group 本体 API 12+ 可用，但 options 参数 `stateControllerRoleType` /
`actionControllerRoleType` **下限 API 23**（AccessibilityRoleType 角色声明）——**参数版本独立于
属性本体**（同类先例：nextFocusId 的 isConsiderDescendants 需 26+），22 < 23 编译报错。

**处理**（按通用答疑模式）：

1. 给出两参数起始版本（API 23+），说明与属性本体（12+）的版本分层；
2. 核对 build-profile 三字段，确认工程版本低于下限；
3. 修复建议：**提升 compatibleSdkVersion 至 23 对应版本串**（版本串以官方 SDK 版本映射为准）；
   若角色语义非必需，可暂移除两个角色参数回到 `.accessibilityGroup(true)` 基础聚合能力。

**回写**：已回写 `api-facts.md`（group 行）/ `SKILL.md`（第 2 步 options 参数版本分层）/
`decision-matrix.md` / 相关 test-cases。

## 通用答疑模式（US-6：为什么编译报错）

1. 读报错中的属性/参数名 → 查 `api-facts.md` 下限 API；
2. **options 参数版本独立于属性本体**，逐参数核对：group 的 `accessibilityPreferred` 14+、
   `stateControllerRoleType`/`actionControllerRoleType` 23+（vod-9）、nextFocusId 的
   `isConsiderDescendants` 26+；
3. 读 build-profile 三字段；
4. 任一低于下限 → 给"提升字段"具体修改建议（不输出该属性任何代码，含"方案示意"形式）；
5. 字段满足仍报错 → 引导查看 SDK 版本实际包含的 d.ts，或反馈缺陷单。
