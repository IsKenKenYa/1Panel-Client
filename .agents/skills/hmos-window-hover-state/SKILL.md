---
name: hmos-window-hover-state
description: 为鸿蒙（HarmonyOS/OpenHarmony）折叠屏应用提供窗口悬停态适配：折痕避让几何、上半屏内容 + 下半屏固定操作坞布局、悬停监听接入、SDK 未声明时的降级方案、系统栏避让与旋转策略。当任务涉及悬停态/半折叠（HALF_FOLD 笔记本形态）适配、悬停拍摄、悬停视频布局、折痕避让、onWindowPostureModeChange / isInWindowPostureMode 悬停监听时使用。Use when adapting apps to foldable hover state, listening for window posture mode changes, or avoiding fold crease regions. 不适用于 PC 沉浸式 title/dock hover、鼠标指针 hover 效果与 WMS 系统服务侧功能开发。
license: MIT
compatibility: 面向 HarmonyOS/OpenHarmony Stage 模型 ArkTS；悬停 API 需目标 SDK 声明 WindowPostureMode 系列（未声明走 foldStatus 降级）；仅折叠屏全屏窗口下生效，需合一架构。
metadata:
  version: "1.0.0"
  keywords:
    - 悬停态
    - 半折叠
    - HALF_FOLD
    - 悬停模式
    - WindowPostureMode
    - DESKTOP_MODE
    - onWindowPostureModeChange
    - isInWindowPostureMode
    - 折痕避让
    - fold crease
    - 折叠屏
    - 悬停拍摄
    - 窗口姿态模式
---

# 窗口悬停态适配技能（hmos-window-hover-state）

本技能覆盖鸿蒙（HarmonyOS/OpenHarmony）折叠屏应用的**窗口悬停态**适配：设备半折叠（HALF_FOLD，笔记本形态）、**折痕横向**、全屏窗口满足系统判定条件时，窗口进入 `WindowPostureMode.DESKTOP_MODE` 姿态模式（无需新增权限），应用据此做"上半屏内容 + 下半屏操作"的分区布局（视频上半屏播放下半屏控制、相机悬停拍摄等）。

典型形态：设备如笔记本电脑般半开，上半屏面向用户（内容区），下半屏近水平（操作区），中间为折痕。

## 使用流程

1. **确认目标环境**：
   - 确认设备形态：非折叠屏（`display.isFoldable()` 为 false）无需悬停态适配，直接告知用户并结束。
   - **核验 API 可用性（红线）**：检查目标 SDK 的 `@ohos.window.d.ts` 是否声明 `WindowPostureMode` / `onWindowPostureModeChange` / `isInWindowPostureMode`。已核实（2026-10）：OpenHarmony 社区 master 曾长期未声明；窗口管理仓（foundation/window/window_manager）master 已含实现；商用 SDK 已出现声明（标注 `@since 26.0.0`）——以目标工程实际 SDK 检索结果为准。未声明时走 [api-reference.md](references/api-reference.md) 中的降级方案（foldStatus 推断 + 折痕区域获取 + `windowSizeChange` 全屏自查）。
   - 确认窗口使用方式：悬停态仅在**全屏窗口**下触发（分屏/悬浮/自由窗口不会进入）。
2. **按任务路由表**阅读对应参考文档。
3. **产出适配方案**（先向用户确认再写代码）：
   - 状态驱动：`@State isInHover` 单状态源，回调只切换状态、不做重活，布局交给声明式 UI（折痕/避让缓存复核经 `setTimeout(0)` 派发为回调外独立任务）。
   - 渲染节点不重建：Video/XComponent 等渲染节点不进悬停 if/else 分支，同一节点仅改布局参数（高度/layoutWeight）——进分支会销毁重建 Surface，导致预览黑屏/播放中断（相机/视频场景真机踩坑）。
   - 折痕避让：按下方"折痕避让几何"量化公式布局。
   - 下半屏人机工学（悬停态必做）：快门/播放/挂断等主按钮加大并外扩点击区、间距上调一档（近水平视角触控精度低于常规持握，真机实测快门 74→84vp）。
   - 系统栏避让：沉浸式页面的交互/HUD 元素手动避让系统栏——进页面先 `getWindowAvoidArea(TYPE_SYSTEM / TYPE_NAVIGATION_INDICATOR)` 查**初始**高度（首帧避让依据），再随 `avoidAreaChange` **动态刷新**（查询结果会过期）。
   - 旋转策略：悬停优先级最高，不得因横屏方向被压制；全屏×旋转（耦合/解耦）取决于产品需求，按需选择勿混用。
   - 降级兼容：API 缺失或非折叠屏时行为不劣化。
   - 生命周期：注册/解注册对称，页面销毁时清理。
4. **验证**：按 [verification.md](references/verification.md) 模拟折叠形态核对事件触发与 UI 切换，逐项过边界用例清单；无真机时明确说明无法验证的内容并列出静态检查结果。

## 决策树

```
设备是折叠屏？（display.isFoldable()）
├─ 否 → 无需悬停态适配，告知用户并结束
└─ 是 → 窗口全屏？（WINDOW_MODE_FULLSCREEN；分屏/悬浮/自由窗口不触发）
    ├─ 否 → 不进入悬停态，按常规布局处理
    └─ 是 → 半折叠 + 折痕横向 + 系统判定通过 → 进入 DESKTOP_MODE
         └─ 目标 SDK 声明 WindowPostureMode 系列？（检索 @ohos.window.d.ts）
             ├─ 是 → 标准路径：isInWindowPostureMode 初始查询 + onWindowPostureModeChange 监听
             └─ 否 → 降级路径：foldStatus 推断 + 折痕区域获取 + windowSizeChange 全屏自查
```

## 任务路由表

| 场景 ID | 任务 / 需求 | 参考文档 |
| --- | --- | --- |
| HVS-01 | 理解悬停态触发机制、系统侧判定链路，排查"为什么没触发" | [wms-internals.md](references/wms-internals.md) |
| HVS-02 | 编码：API 签名、可用性核验方法、降级方案、完整状态机示例 | [api-reference.md](references/api-reference.md) |
| HVS-03 | 设计 UI 布局：场景化模式、折痕避让几何、固定操作坞、旋转策略、系统栏避让 | [adaptation-patterns.md](references/adaptation-patterns.md) |
| HVS-04 | 验证：hidumper 模拟折叠形态命令、边界用例清单 | [verification.md](references/verification.md) |
| HVS-05 | 存量页面改造：先审计再动手（结构切分点/不可重建节点/状态融合/生命周期合并/系统栏回归） | [adaptation-patterns.md](references/adaptation-patterns.md) |

## 核心接口速查

| 接口 | 说明 | 形态 |
| --- | --- | --- |
| win.onWindowPostureModeChange(mode, callback) | 注册悬停态监听（**window 实例方法**，非泛型 on 事件；mode 固定传 `WindowPostureMode.DESKTOP_MODE`） | 商用 SDK 已声明 |
| win.offWindowPostureModeChange(mode, callback?) | 注销监听（与注册对称） | 商用 SDK 已声明 |
| win.isInWindowPostureMode(mode) | 查询当前是否处于悬停态（进页面初始查询，配合监听补齐"启动时已悬停"场景） | 商用 SDK 已声明 |
| display.getDefaultDisplaySync().getLiveCreaseRegion() | 实时折痕区域（px，三级优先级第 1 级） | API 20+ |
| display.getCurrentFoldCreaseRegion() | 静态折痕区域（px，三级优先级第 2 级，第 3 级为屏幕中线兜底） | API 10+ |
| display.getFoldStatus() | 折叠状态（降级方案判据 `FOLD_STATUS_HALF_FOLDED`） | API 10+ |

> 版本备注：悬停 API 以目标 SDK 实际声明为准（社区 master 与商用 SDK 声明进度不同）；未声明时按 [api-reference.md](references/api-reference.md) 走降级方案。

## 折痕避让几何（真机三轮打磨定稿）

| 区块 | 高度公式（vp） | 说明 |
| --- | --- | --- |
| 上半屏内容区（视频/取景器/图集） | `creaseTop` | **封顶折痕区域上沿**，内容严格不进折痕区域 |
| 折痕避让带（纯占位） | `max(creaseHeight / 2 + 16, 16)` | 覆盖折痕上半段 + 中心线下方 16vp；带内不放交互/文字 |
| 下半屏操作区 | `winHeight −` 前两项 | **固定操作坞**（控制元素一次呈现，不上下拖动），内容做减法确保总高不超本区高度，主按钮加大并外扩点击区（近水平视角人机工学），底部叠加导航条安全距离 |

`creaseTop` / `creaseHeight` 获取三级优先级（取到的均为 px，**除以** `densityPixels` 转 vp）：

1. `display.getDefaultDisplaySync().getLiveCreaseRegion()` —— 实时折痕区域（API 20+，优先使用；设备不支持抛 801 需 try/catch）；
2. `display.getCurrentFoldCreaseRegion()` —— 静态折痕区域（API 10+，降级使用）；
3. 屏幕中线兜底 —— 两级都取不到时按"折痕位于屏幕垂直中线"估算（`winHeight / 2`，估算值需标注，勿当精确坐标）。

**溢出教训（真机踩坑）**：固定高度 Column 的子项溢出会**穿透底部 padding** 渲染到屏幕边缘——padding 是布局参数、不是裁剪边界。固定操作坞内容行数做减法（总高 ≤ 操作区高度）；兜底方案为内容包 `Scroll` + 底部 padding = 安全区 + 导航条高度（padding 进入内容流，真实生效）。

px → vp 是**除以** `densityPixels`。几何依据（整段折痕留白过大、内容压折痕两轮真机否决过程）与固定操作坞形态见 [adaptation-patterns.md](references/adaptation-patterns.md) 第 2、4 节。

## 布局状态优先级（旋转策略）

```
悬停（系统回调，最高） > 全屏等其余布局状态（按产品定义）
```

- 书本型折叠屏（Mate X / Z Fold 类）悬停通常出现在**横屏窗口**（DESKTOP_MODE 要求折痕横向）；悬停布局由折痕坐标锚定、与窗口方向无关——**不得用 isLandscape 压制悬停状态**（真机反模式）。
- 全屏×旋转两种产品形态：耦合（全屏按钮调 `setPreferredOrientation` 强制横屏）/ 解耦（全屏是纯布局状态位，按钮只切状态不调方向 API），取决于产品需求，勿混用。

## 红线约束

- **不要假设 API 存在**：目标 SDK 未声明即走降级方案，勿写死接口调用。
- **回调内不做重活**：悬停回调内不做折痕/避让区查询等同步重活（更不做同步 IPC、大量计算或磁盘访问）；只切换 `isInHover` 状态位，折痕/避让缓存复核经 `setTimeout(0)` 派发为回调外独立任务，布局交给声明式 UI。
- **不反向修改系统行为**：应用侧只消费状态；hidumper 等调试命令仅验证阶段使用。
- **事件语义**：回调 boolean 表示进入(true)/退出(false)悬停态，与鼠标 hover、PC 沉浸式 title/dock hover 无关。
- **注册/解注册对称**：页面销毁时清理监听。
- **下半屏主按钮人机工学（悬停态硬约束）**：主按钮（快门/播放/挂断等）在下半屏加大并外扩点击区、间距上调——近水平视角触控精度低于常规持握（真机实测快门 74→84vp）；交互元素一律避开折痕避让带与系统栏。

## 自检清单

交付前逐项勾选（完整边界用例清单见 [verification.md](references/verification.md)）：

**必须**：

- [ ] 折痕避让几何：内容封顶 `creaseTop`、避让带 `max(折痕高/2 + 16, 16)`vp、带内无交互/文字
- [ ] 渲染节点（Video/XComponent）不进悬停 if/else 分支，同一节点仅改布局参数（高度/layoutWeight）——进分支销毁重建 Surface 导致预览黑屏/播放中断
- [ ] 悬停回调只切 `isInHover` 状态位，折痕/避让缓存复核经 `setTimeout(0)` 派发为回调外独立任务
- [ ] 下半屏主按钮加大并外扩点击区、间距上调（近水平视角人机工学）
- [ ] 交互/HUD 元素避让系统栏：进页面 `getWindowAvoidArea` 查初始高度，避让高度随 `avoidAreaChange` 动态刷新（查询结果会过期）
- [ ] 固定操作坞内容做减法不溢出：固定高度 Column 子项溢出会穿透底部 padding 渲染到屏幕边缘（padding 不是裁剪边界），兜底为内容包 Scroll + 底部 padding = 安全区 + 导航条高度
- [ ] 悬停布局不因横屏方向被压制（`isHoverLayout()` 直返 `isInHover`）
- [ ] 注册/解注册对称，页面销毁时清理监听

**建议**：

- [ ] 形态切换 250ms `EaseInOut` 进出对称过渡
- [ ] 折痕 px **除以** `densityPixels` 转 vp；`expandSafeArea` 铺满与手动避让成对处理
- [ ] 悬停操作区做固定操作坞不上下滚动，控制元素一次呈现
- [ ] 降级路径在 `windowSizeChange` 回调里复核窗口仍全屏，非全屏强制清除悬停态

**可选**：

- [ ] `foldAngleChange`（API 12+）角度驱动连续过渡
- [ ] `setWindowKeepScreenOn` 视频/相机场景保持亮屏

## 关键事实速查

| 项 | 值 |
| --- | --- |
| 触发形态 | `FoldStatus.FOLD_STATUS_HALF_FOLDED`（半折叠）+ 折痕横向 |
| 应用侧枚举 | `WindowPostureMode.DESKTOP_MODE = 0` |
| 降级判据 | `getFoldStatus() === FOLD_STATUS_HALF_FOLDED` + 全屏自查（`windowSizeChange` 回调里复核窗口仍全屏） |
| 系统栏避让 | 进页面 `getWindowAvoidArea(TYPE_SYSTEM / TYPE_NAVIGATION_INDICATOR)` 查初始高度（px **除以** densityPixels），再随 `avoidAreaChange` 动态刷新（查询结果会过期） |

系统侧完整判定条件（窗口全屏校验、LS 态抑制、合一架构门控等知识型内容）下沉至 [wms-internals.md](references/wms-internals.md)。

## 输出要求

完成后报告：适配方案摘要（场景、API 路径选择及理由）、代码改动列表、验证结果（或无法验证的原因与静态检查）、遗留风险（SDK 版本依赖、设备覆盖）。
