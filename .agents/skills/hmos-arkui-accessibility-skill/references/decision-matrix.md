# 诉求路由决策矩阵

> SKILL.md 第 1 步的详表。判定后必须向开发者说明判定依据（对应其原话）。

## A~G 诉求详表

| 诉求 | 判定问题 | 属性 | 下限 API | 输出要点 |
|---|---|---|---|---|
| D0 | 默认屏幕朗读够用吗？ | 无需适配 | — | 说明默认四要素（类型/文本/操作结果/状态）+ 三前提（可识别、功能及操作信息、状态与行为），询问是否满足 |
| A 无文本可读 | "图标按钮读屏听不出是干嘛的" | `accessibilityText` | 12 | 给 text；说明改前/改后播报差异；系统仍补充组件类型和操作提示；文案不混入操作引导/状态；**空文本跳焦兜底（vod-8）**：显示文本可能为空的组件用 `text(content === '' ? ' ' : content)`（勿误路由 level/nextFocusId） |
| B 操作后果 | "聚焦只播'单指双击即可执行'，太含糊" | `accessibilityDescription` | 10 | 给 description；说明其在文本后播报并替代默认新手提醒；警示关闭新手提醒后不播报（不能承诺必达）；**操作提示动态开关（vod-7）**：仅某状态播默认提示用 `description(state ? ' ' : '')`（空串=保留默认提示、空格=替代关闭，空串分支不删） |
| C 整组朗读 | "日期三个 Text 分开读，很碎" | `accessibilityGroup(true)` | 12 | 在**容器**上设置；说明容器成为聚焦单元、子 Text 拼接播报不再分别聚焦；不给每个 Text 单独加 text；**合并文本只拼子组件通用文本**（子 accessibilityText 不参与合并，必要时 `accessibilityGroup(true, { accessibilityPreferred: true })`，见 group-dynamic-announcement vod-5）；options 角色参数 `stateControllerRoleType`/`actionControllerRoleType` 需 API 23+（低版本编译报错，vod-9） |
| D 可识别性 | "关键操作要能被聚焦 / 装饰元素别读出来" | `accessibilityLevel` | 12 | 关键组件 `yes` 强制可识别；装饰 `no` 只隐藏当前节点；整棵子树隐藏用 `no-hide-descendants`；`auto` 按下方决策指引输出（无确定性诉求可建议，确定性要求不给） |
| E 选中状态 | "复选框/单选项读不出选没选" | `accessibilityChecked` / `accessibilitySelected` | 13 | 先版本检查（三字段 ≥13）；输出下方对比表；不混用二者；checked 需真实状态源同步：`@State` + 受控 `.select(state)` + `.onChange()`（Checkbox 无 onSelect 方法，状态同步一律用 onChange，2026-10 评测 vod-3 实测）；**selected 使能前提 + 逐项挂载·三同原则**：只在读屏焦点节点（自身文本/onClick/内建点击）上被播报，挂在与内容、视觉选中态、点击交互同一节点的选项语义容器（每项独立 `state === i`） |
| F 自绘组件 | "Canvas/自绘内容读屏读不到" | `accessibilityVirtualNode` | 11 | 先版本检查；给 @Builder 虚拟节点方案，**builder 内单个 Text 直述**（默认播报即可，不套容器 group(true)+子 accessibilityText——合并文本丢弃子无障碍文本，vod-5）；说明辅助工具读虚拟节点语义而非绘制内容 |
| G 自定义走焦 | "自定义首焦点 / 下一个获焦的焦点" | `accessibilityDefaultFocus` / `accessibilityNextFocusId` | 18 | 首焦点用 defaultFocus；指定下一个用 nextFocusId（isConsiderDescendants API 26 控制子节点）；**仅目标组件加 `.id()`**（源组件不加，vod-6）；isConsiderDescendants 默认 false——默认行为（跳过目标子节点）不传参，仅进入子节点时显式传 true；软提示版本不阻断 |

## level `auto` 决策指引（D 类必输出）

`auto` 语义：由无障碍服务与 ArkUI 按组件类型和内容**综合判断**，不保证聚焦或隐藏结果。

| 维度 | 说明 |
|------|------|
| **支持场景**（可建议 `auto`） | 组件无确定性聚焦/隐藏诉求、维持系统默认行为（如标准容器按系统默认参与聚焦） |
| **不支持场景**（不给 `auto`） | 诉求为确定性要求："关键操作必须可聚焦" → 给 `yes`；"元素必须不播报" → 给 `no`（只隐藏当前节点）或 `no-hide-descendants`（连同后代隐藏） |
| **Skill 处理** | 命中不支持场景时不输出 `auto` 方案，改给显式取值建议并说明四值语义差异 |
| **必传开发者信息** | "`auto` 结果不确定，确定性诉求须使用显式取值（`yes`/`no`/`no-hide-descendants`）" |

## checked vs selected 对比（E 类必输出）

| 维度 | accessibilityChecked | accessibilitySelected |
|------|----------------------|----------------------|
| 语义目标 | 控件物理状态（是否勾选） | 互斥单选中的当前选中项 |
| 常见场景 | 复选语义：同意条款、收藏标记 | 单选语义：标签页当前页、列表当前项 |
| 状态持久性 | 二态/三态（Checkbox、Toggle） | 单选集合中的一项（List、Tabs） |
| 典型组件 | Checkbox、Toggle | List、Tabs |
| 挂载位置 | 控件自身 | **选项语义容器且为读屏焦点节点**（使能前提：自身文本/onClick/内建点击；三同原则：与内容、视觉选中态、点击交互同节点）List→项内容容器（如 Row，onClick 同层），每项独立布尔 |
| undefined 行为 | 重置并可由系统依据组件状态判断 | 重置 |

## 反 group（组内例外朗读）

场景：group 了若干组件，但其中某个组件仍需**单独聚焦朗读**（如生日聚合后年份单独可聚焦）。
做法：该组件 `.accessibilityLevel('yes')`（level 是 group 的反操作维度），必要时配合 `accessibilityText`。

## 组合诉求示例

| 组合 | 场景 | 一次落齐 |
|------|------|----------|
| A+E | 无文字收藏图标，还要让读屏知道是否收藏 | text 传用途、checked 传状态（先过 E 的版本门）；不把状态塞进 text |
| C+D+A | 生日三 Text 聚合播报，年份单独可聚焦 | 容器 group(true) + 年份 level('yes') + 年份 text('出生年份') |
| G+事件 | 首焦点 + 聚焦统计 | defaultFocus + onAccessibilityFocus（focus 需 18+，软提示） |

## 组件类别 → 接口类别选择

| 组件类别 | 接口类别 | 说明 |
|----------|----------|------|
| 标准组件（有语义） | 属性类（accessibility*） | 通用属性直接设置 |
| 容器/组合 | 属性类（group/level） | 聚合与例外控制 |
| 自绘（Canvas 等） | 属性类（virtualNode）+ builder | 虚拟节点承载语义 |
| 需运行时交互逻辑 | 方法类（on* 回调）+ 属性叠加 | hover(12+)/focus(18+) 回调可与属性叠加 |
| 动态内容更新 | @ohos.accessibility 事件 | sendAccessibilityEvent 主动通知 |

来源：源码注册表 `frameworks/bridge/declarative_frontend/jsview/js_view_abstract.cpp:10422-10487`；
语义与下限 API 见 `api-facts.md`。
