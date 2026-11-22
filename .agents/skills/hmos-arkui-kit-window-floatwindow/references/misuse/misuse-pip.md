# 画中画误用清单

签名以 [js-apis-pipWindow.md](../apis/js-apis-pipWindow.md) 为准。本文件不列接口表。调用顺序与页面加载以 [pip.md](../../assets/pip.md) 为准。

模块：`import { PiPWindow } from '@kit.ArkUI'`（typeNode 路径再加 `typeNode`）  
起始：API 11；typeNode 路径 API 12+。无特殊 `ohos.permission.*`。  
syscap：`SystemCapability.Window.SessionManager`

**做什么**：把画面迁到系统小窗，系统画控制条。  
**不要用来**：自定义页面（闪控窗）、贴边球（闪控球）、子窗 / `TYPE_FLOAT`。

| 路径 | 何时用 | create |
|------|--------|--------|
| **页面 XComponent（默认 / 一镜到底）** | 写 demo | `create(config)` 无第二参；布局 `XComponent` 与 `componentController` 同一个；进 PiP 不摘组件、不重建播放器 |
| typeNode | 用户明确迁自定义节点 | `create(config, contentNode)`。系统 `unable to locate source rect`，**不是一镜到底**；`ABOUT_TO_START` 摘节点 |

`updateContentNode` **仅** typeNode。单页不要写 `navigationId`。

## 调用顺序

与骨架相同：`onLoad` 绑 AVPlayer → 视频页按钮 `create(config)` 一次无第二参 → `setAutoStartEnabled(true)` → `startPiP` → `STARTED`。

不要在 `onAppear` / `aboutToAppear` / `onPageShow` 里 create 或 start。不要摘页面 `XComponent`。`create` / `startPiP` 的 Promise 成功 ≠ 用户看见小窗。系统「智慧多窗 → 自动启动画中画」关闭只挡住退后台自动拉起，不挡住按钮 `startPiP`。

## 易错约束

- `context`：组件内 `getHostContext()` 转为 `UIAbilityContext`
- `controlGroups` / `controlEvent` 必须与 `templateType` 同族，最多 3 个；`VIDEO_PLAY` 下 101 与 102 互斥。对照 [pip.md](../../assets/pip.md) 模板表
- 宿主 `@Entry` 必须进 `main_pages.json`；`Page1` 根节点必须是 `NavDestination()`，否则二级页白屏
- 用 Navigation 则 `navigationId` 与 `Navigation.id` 同一字符串；单页不要写。Index 进 PipHost 可用 `getRouter().pushUrl`（PiP 尚未 start）；`startPiP` 之后禁止再切页
- 在**视频页**再 `setAutoStartEnabled(true)`。首页就 true，还原会回到首页
- 画面黑但框还在：没绑 surface / 没 rawfile / typeNode 节点宽高为 0，不是 start 失败
- 小窗控制条没反应：没听 `controlEvent`，或 AVPlayer 没有 `play` / `pause` / `setMuted`

## 错误码（应用侧）

| 码 | 改什么 |
|----|--------|
| 401 | config：缺 context/controller、控件组不匹配/冲突 |
| 801 | 先 `isPiPEnabled` |
| 1300013 | 主窗 show 后再 start；Navigation id 配对 |
| 1300015 | 状态机：仅 STOPPED 可 start；`create` 一次 |
| 1300034 | 已有闪控窗则先停 |

## 误用清单（查错用）

1. `create` 成功就以为小窗出来了，没有 `startPiP`
2. 默认走 typeNode 却要一镜到底；或 `create(config, contentNode)` 后又在 `ABOUT_TO_START` 摘页面 `XComponent` / 重建 AVPlayer
3. 页面 XComponent 路径：用了一个 controller，create 传了另一个；进 PiP 时摘掉了布局里的 `XComponent`
4. `context` 不是 `UIAbilityContext` → 401
5. 在 `onCreate`/`aboutToAppear` 里 `startPiP`，主窗尚未 show → 1300013
6. `controlGroups` 用了别的模板的枚举，或同时塞了 101 和 102 → 401
7. 用 Navigation 但没设 `navigationId` / 没给 `Navigation.id` / 两处字符串不一致；或单页却写了 `navigationId` → 1300013 或还原错页
7b. 有 Navigation 却在首页就 `setAutoStartEnabled(true)`；`navigationId` 填成了 NavDestination `name`
7c. PiP 回调里在主窗非前台时 push/pop；`ABOUT_TO_START` 里 pop 了却没在 `ABOUT_TO_RESTORE` 里 push 回去
7d. 宿主 `@Entry` 没进 `main_pages.json`；`PageMap` 返回的组件根节点不是 `NavDestination()` → 二级页白屏
8. 没听 `controlEvent` 去 play/pause，控制条按钮点了没反应
9. 已有闪控窗还 startPiP → 1300034
10. 重复 start（用户连点、每次都 `create`）→ 1300015
11. 画面黑但小窗框/控制条在：没绑 surface、没 rawfile 视频、typeNode 节点宽高为 0
12. 把 `createSubWindow` 或 `TYPE_FLOAT` 当成 PiP
