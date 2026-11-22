# ArkUI 无障碍 API 事实表

> 每条事实带来源。来源分两级：
> - **源码**（高可信）：本仓 `arkui_ace_engine` 注册/实现核验。
> - **官方文档**（中可信）：`interface_sdk-js` 未在本工作区检出，下限 API 与外部模块契约以公开官方文档为准
>   （arkts-universal-attributes-accessibility 开发指导/参考）。
> 维护：API 演进后按本表来源列增量核验更新；事实冲突时以源码为准并回溯修订。

## 无障碍能力总览（知识问答口径）

> 知识问答模式（SKILL.md Q 类输入）的回答基线：本节 + 下文属性/事件事实表与默认值清单。

**默认使能（免适配）**：ArkUI 默认支持屏幕朗读（系统无障碍服务，如"屏幕朗读"），聚焦组件
自动播报四要素：**组件类型、文本内容、操作结果、当前状态**。有文本内容的标准组件（如
Button：朗读"按钮，提交订单，单指双击即可执行"）**无需任何 accessibility* 属性**。

**需主动适配**（按能力类别，接口详情与陷阱见下文事实表）：

| 能力类别 | 解决场景 | 接口（下限 API） |
|---|---|---|
| 播报内容 | 无文本元素读不出用途 / 操作后果太含糊 / 状态补充说明 / 角色声明 | `accessibilityText`（12）、`accessibilityDescription`（10）、`accessibilityStateDescription`（18）、`accessibilityRole`（12） |
| 聚合与可见性 | 多段文本读得碎 / 装饰元素别读、关键元素必须读 | `accessibilityGroup`（12）、`accessibilityLevel`（12；历史名 `accessibilityImportance`） |
| 状态语义 | 勾选/开关物理状态 / 互斥单选当前项 | `accessibilityChecked`（13）、`accessibilitySelected`（13） |
| 自绘与走焦 | Canvas/自绘内容读屏读不到 / 自定义首焦点与下一焦点 | `accessibilityVirtualNode`（11）、`accessibilityDefaultFocus`（18）、`accessibilityNextFocusId`（18；isConsiderDescendants 26） |
| 交互行为 | 自定义读屏操作菜单 / 可见区无可聚焦组件时自动触发滚动 | `accessibilityCustomActions`（12）、`accessibilityScrollTriggerable`（18） |
| 事件回调 | 读屏用户单指触摸悬停探测 / 读屏聚焦移入移出 | `onAccessibilityHover`（12）、`onAccessibilityFocus`（18） |
| 动态播报 | 界面内容动态更新后辅助服务不自动识别 | `@ohos.accessibility` 的 `sendAccessibilityEvent`（`@kit.AccessibilityKit`，版本以官方文档为准） |

## 通用属性（声明式）

| 属性 | 签名 | 下限 API | 关键语义 | 来源 |
|------|------|----------|----------|------|
| accessibilityText | `.accessibilityText(value: string \| Resource)` | API 12 | 无障碍播报文本；不为空时优先于显示文本（原文本不再播报）；组播报时作为组文本候选；**空内容兜底（vod-8）**：显示文本可能为空的组件（如 Text 绑定可空状态变量）内容为空串时会被读屏**跳焦**，三元兜底 `.accessibilityText(content === '' ? ' ' : content)` 保持可聚焦（空格非空即占位，非空分支原样传入） | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10448`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:72-80`；优先级 `frameworks/core/accessibility/utils/accessibility_property_utils.cpp:43`（GetContent）；下限 API 官方文档；空内容兜底经历史 VOD 实测（vod-8） |
| accessibilityDescription | `.accessibilityDescription(value: string)` | API 10 | 操作后果/详细说明；在文本后播报并**替代**系统默认新手提醒；用户关闭新手提醒后不播报；**空串开关（vod-7）**：空串（默认值）=保留系统默认操作提示（"单指双击即可执行"），非空串（含空格 `' '`）=替代之不再播报——动态场景三元切换 `.accessibilityDescription(state ? ' ' : '')` | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10450`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:108-126`；替代语义官方文档；空串开关经历史 VOD 实测（vod-7） |
| accessibilityGroup | `.accessibilityGroup(value: boolean, options?: AccessibilityGroupOptions)` | API 12 | 容器聚合为单一聚焦单元整体播报；组文本=用户文本优先，否则组内文本聚合；**合并文本陷阱（vod-5）**：父组件设 group 且自身无通用文本、未设 accessibilityText 时，合并文本默认**拼接子组件通用文本，不使用子组件 accessibilityText**；`options.accessibilityPreferred: true` 深度遍历子节点时优先取其无障碍文本（较新参数，下限版本以官方文档为准，输出前核对）；options 另有 `stateControllerRoleType` / `actionControllerRoleType`（**API 23+**，AccessibilityRoleType 角色声明，低于 23 编译报错，vod-9） | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10447`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:32-70`；合并文本规则经 2026-10 评测 virtualNode 问题汇总实测（vod-5）；角色参数版本经历史 VOD 核查（vod-9，官方文档） |
| accessibilityLevel | `.accessibilityLevel(value: 'auto' \| 'yes' \| 'no' \| 'no-hide-descendants')` | API 12 | 可识别性控制；**属性默认值 `'auto'`**（官方文档）；`no` 只隐藏当前节点，`no-hide-descendants` 连同后代隐藏；显式 `yes`/`no`/`no-hide-descendants` 均为非默认取值；与 accessibilityImportance 等价（level 推荐） | 枚举源码 `frameworks/core/components_ng/property/accessibility_property.h:494-501`（Level 常量，无 default 枚举成员；默认值 `'auto'` 官方文档）；等价写入 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:170-173`；下限 API 官方文档 |
| accessibilityImportance | `.accessibilityImportance(value: 同 level 枚举)` | API 12 | 同 accessibilityLevel（历史名） | 源码等价写入 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:165-168`；下限 API 官方文档 |
| accessibilityChecked | `.accessibilityChecked(value?: boolean)` | API 13 | 二态/三态物理选中（Checkbox、Toggle）；undefined 重置并可由系统依据组件状态判断；checked 需真实状态源同步：`@State` + 受控 `.select(state)` + `.onChange()`（**Checkbox 无 onSelect 方法**，状态同步一律用 onChange） | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10456`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:211-225`；Checkbox 无 onSelect 经 DevEco 260（API 26）SDK 首编实测核验（2026-10 评测 vod-3）；下限 API 官方文档 |
| accessibilitySelected | `.accessibilitySelected(value?: boolean)` | API 13 | 互斥单选当前项（List、Tabs）；**使能前提 + 逐项挂载 + 三同原则**：只在**读屏焦点节点**上被播报（节点自身文本/挂 onClick/内建点击三选一）；挂在与内容、视觉选中态、点击交互**同一节点**的选项语义容器（每项独立 `state === i`）；`false` 正常写入，仅 `undefined` 重置 | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10455`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:195-209`（boolean 均写入，undefined 才 reset）；下限 API 官方文档 |
| accessibilityRole | `.accessibilityRole(value: Role)` | API 12 | 角色声明，读屏按角色播报组件类型 | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10457`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:243-258`（枚举转 role 字符串）；下限 API 官方文档 |
| accessibilityNextFocusId | `.accessibilityNextFocusId(value: string, options?: { isConsiderDescendants?: boolean })` | API 18（isConsiderDescendants API 26） | 自定义下一获焦节点；isConsiderDescendants 控制是否考虑**目标节点**子节点，**默认 false**（下一焦点落到目标本身）；**简约性硬约束（vod-6）**：仅目标组件需配 `.id()`（源组件不加 id）；与默认值一致的 options 不显式传（`{ isConsiderDescendants: false }` 冗余，跳过子节点直接省略第二参数） | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10449`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:87-106`；下限 API 官方文档；默认值与简约性经 2026-10 评测 redundant_id 实测（vod-6） |
| accessibilityDefaultFocus | `.accessibilityDefaultFocus(value: boolean)` | API 18 | 页面默认读屏焦点（首焦点） | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10459`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:279-288`；下限 API 官方文档 |
| accessibilityVirtualNode | `.accessibilityVirtualNode(value: () => void)` | API 11 | 自绘内容虚拟子节点；辅助工具读取虚拟节点语义而非绘制内容；**参数直传 @Builder 方法引用**：`.accessibilityVirtualNode(this.customAccessibilityNode)`；两种包裹写法均禁止——① lambda 包裹 `() => { this.customAccessibilityNode(); }`（编辑器飘红 "UI component syntax cannot be written here"）；② 对象包裹 `{ builder: ... }`（编译报错 `'builder' does not exist in type '() => any'`）；**builder 内容基线（vod-5）**：单个 Text 直述（默认播报即可），禁"容器 group(true) + 子 accessibilityText"组合（合并文本丢弃子无障碍文本） | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10453`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:175-193`；签名经 DevEco 260（API 26）SDK 首编实测核验（2026-10 评测 vod-3/vod-4）；builder 内容基线经 2026-10 评测 virtualNode 问题汇总实测（vod-5）；下限 API 官方文档 |
| accessibilityScrollTriggerable | `.accessibilityScrollTriggerable(value?: boolean)` | API 18 | 是否支持滑动触发滚动（可见区无可聚焦组件时屏幕朗读自动发起滚动） | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10461`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:227-241`；下限 API 官方文档 |
| accessibilityStateDescription | `.accessibilityStateDescription(value: string)` | API 18 | 状态描述补充播报 | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10469-10470`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:128-137`；版本差异官方文档 |
| accessibilityCustomActions | `.accessibilityCustomActions(value: Array<{ name: string, action?: string, onAction: () => void }>)` | API 12 | 自定义读屏操作菜单；name 与 onAction 缺一不生效 | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10487`、解析 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:380-429`；下限 API 官方文档 |

## 属性默认值清单（第 6 步简约性检查唯一依据）

> 来源：官方文档 ts-universal-attributes-accessibility（developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-universal-attributes-accessibility）。
> **组件"默认可读/可聚焦"是系统运行行为，不是属性默认值**——判定"参数值与默认值一致"时只看本清单，
> 禁止以"系统默认行为已满足"推断某显式取值为冗余（2026-10 评测 B06 实测教训：确定性诉求的
> `accessibilityLevel('yes')` 被误判为过度适配而删除）。

| 属性/参数 | 默认值 | 显式非默认值（有效设置，禁止按简约性删除） |
|---|---|---|
| accessibilityLevel | `'auto'`（由无障碍服务与 ArkUI 综合判断，结果不确定） | `'yes'` / `'no'` / `'no-hide-descendants'` |
| accessibilityGroup | `false` | `true` |
| accessibilityGroup options.accessibilityPreferred（API 14+） | `false` | `true` |
| accessibilityText | `""`（空字符串） | 任意非空文案 |
| accessibilityDescription | `""`（空字符串） | 任意非空文案 |
| accessibilityChecked（API 13+） | `undefined`（由组件自行确定选中状态） | `true` / `false` |
| accessibilitySelected（API 13+） | `undefined`（由组件自行确定选中状态） | `true` / `false` |
| accessibilityDefaultFocus（API 18+） | `false`（不设置为页面首焦点） | `true` |
| accessibilityNextFocusId 第二参数 isConsiderDescendants（API 26+） | `false`（不在目标后代中查找焦点） | `true` |
| accessibilityScrollTriggerable（API 18+） | `true`（`undefined` 还原默认） | `false` |

- 简约性判定口诀：与上表"默认值"列**完全一致**的显式参数 → 冗余，删除（如
  `{ isConsiderDescendants: false }`、`accessibilityChecked(undefined)`）；与默认值**不同**的任何
  显式取值 → 有效代码，保留。
- **动态分支例外（vod-7/vod-8）**：条件/三元表达式中作为**分支取值**的默认值是行为开关，不属冗余——
  `accessibilityDescription(state ? ' ' : '')` 的空串分支（空串=保留默认操作提示）、
  `accessibilityText(content === '' ? ' ' : content)` 的空串兜底（保持可聚焦）；第 6 步简约性检查不得删除。
- accessibilityVirtualNode、onAccessibilityHover/onAccessibilityFocus 等事件回调无默认值概念，
  不存在"显式传默认值"问题。

## 事件/方法

| 事件 | 签名 | 下限 API | 关键语义 | 来源 |
|------|------|----------|----------|------|
| onAccessibilityFocus | `.onAccessibilityFocus(callback: (isFocus: boolean) => void)` | API 18 | 读屏聚焦/失焦回调（移入/移出）；参数为聚焦状态；undefined 可取消注册 | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10458`、实现 `frameworks/bridge/declarative_frontend/jsview/js_accessibility.cpp:260-277`；下限 API 官方文档 |
| onAccessibilityHover | `.onAccessibilityHover(callback: (isHover: boolean, event: AccessibilityHoverEvent) => void)` | API 12 | 开启无障碍后单指触摸组件触发（悬停探测）；**回调双参数**：isHover=触摸进入/离开布尔，event=位置等事件信息；单参数 `(event)` 写法编译报错（`boolean` 与 `AccessibilityHoverEvent` 参数不兼容）；与属性可叠加 | 源码 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10422`、实现同文件 `:11817-11824`；签名经 DevEco 260（API 26）SDK 首编实测核验（2026-10 评测 vod-3）；下限 API 官方文档 |

## 动态播报（@ohos.accessibility / @kit.AccessibilityKit）

| API | 签名 | 下限 API | 关键语义 | 来源 |
|-----|------|----------|----------|------|
| accessibility.sendAccessibilityEvent | `accessibility.sendAccessibilityEvent(eventInfo: accessibility.EventInfo): Promise<void>`（EventInfo 含 type/bundleName/triggerAction/customId 等） | API 版本以官方文档为准（外部模块） | 界面内容动态更新时辅助服务不会自动识别，需主动发送事件（如 requestFocusForAccessibility 请求聚焦抢播报） | 仓内真实用法 `advanced_ui_component/treeviewv2/source/treeviewv2.ets:1384`（导入 `:20` `import { accessibility } from '@kit.AccessibilityKit'`）；完整契约官方文档（中可信） |

## 播报优先级（组内）

读屏查询组件内容（`AccessibilityPropertyUtils::GetContent`）：
1. 用户设置文本（accessibilityText / 组文本）优先；
2. 否则取组内文本聚合（GetGroupText）。

来源：源码 `frameworks/core/accessibility/utils/accessibility_property_utils.cpp:43`。

## 事实冲突处理

Skill 输出与事实表冲突时，以事实表为准并回溯修订知识库；发现事实表与最新源码/官方文档冲突时，
停止输出生成，提示维护者更新事实表（来源列可增量核验）。
