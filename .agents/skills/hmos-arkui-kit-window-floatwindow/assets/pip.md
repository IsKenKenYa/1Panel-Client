# 画中画（写程序先读本文件）

步骤：[guide-pip.md](../references/guides/guide-pip.md)。签名：[js-apis-pipWindow.md](../references/apis/js-apis-pipWindow.md)。无特殊权限。

再只读 **一条** 骨架。不要 XC 和 typeNode 接到同一个宿主、同时 `startPiP`。

| 用户要什么 | 读 | create | 一镜到底 |
|------------|----|--------|----------|
| 默认 / 视频从小窗飞出、接着播 | [pip-xcomponent.md](pip-xcomponent.md) | `create(config)` 无第二参 | 是 |
| 迁自定义节点到小窗 | [pip-typenode.md](pip-typenode.md) | `create(config, contentNode)` | **否** |

## 页面怎么加载（必须）

Ability 只 `loadContent('pages/Index')`。视频不在 Index 上时，**宿主 `@Entry` 必须进 `main_pages.json`**，否则二级页出不来。

| 工程 | 宿主 | `navigationId` |
|------|------|----------------|
| 写新 demo / Index 已是入口列表 | `@Entry` 宿主 + `xcomponent/Page1`。宿主 `Navigation.id` 与 `create` 的 `navigationId` **同一字符串**。`PageMap` 直接 `Page1()`，根节点必须是 `NavDestination()` | 必填 |
| 已有单页、没有 Navigation，画面就做在这一页 | `XComponent` 直接画在该页。不要为了 PiP 再包 `Navigation` | **不要写** |

`Page1` 不是 `@Entry`，不要登记进 `main_pages.json`。片源 `resources/rawfile/test.mp4`，没有则小窗黑。播放器 `ets/model/AVPlayer.ets`，不要写进页面。

## 调用顺序（唯一，和骨架一致）

```text
Page1 根节点 NavDestination
  → 布局 XComponent(SURFACE, 同一 controller)
  → onLoad：surfaceId + AVPlayer（initialized 里设 surfaceId 再 prepare）
  → 按钮（主窗已 show）：create(config) 一次、无第二参
  → 此时已在视频页：setAutoStartEnabled(true)
  → on('stateChange') / on('controlEvent')
  → startPiP → 以 STARTED 为准
  → 进 PiP 不摘 XComponent、不重建 / release 播放器
```

不要在 `aboutToAppear` / `onPageShow` 里 `create` 或 `startPiP`。不要因 `surfaceId` 为空就 return。不要 `.clip(true)`。`create` 一次，连点走 `1300015`。

## 模板（改这三处，顺序不变）

`controlGroups` 必须与 `templateType` 同族，否则 `401`。`controlEvent` 也要同族：**不要只改 `tpl` 却留播放暂停事件。**

| 用户说法 | `templateType` | `controlGroups` | `controlEvent` |
|----------|----------------|-----------------|----------------|
| 未说 / 播放、点播、看视频 | `VIDEO_PLAY` | 可不填；若填只能播放族。`VIDEO_PREVIOUS_NEXT`(101) 与 `FAST_FORWARD_BACKWARD`(102) **不要同时** | `VIDEO_PLAY_PAUSE` → play/pause |
| 通话 | `VIDEO_CALL` | `MICROPHONE_SWITCH` + `HANG_UP_BUTTON` + `CAMERA_SWITCH`（最多 3 个） | 麦克风/挂断/摄像头；不要当播放键 |
| 会议 | `VIDEO_MEETING` | `HANG_UP_BUTTON` + `CAMERA_SWITCH` + `MUTE_SWITCH`（或麦克风，仍会议族） | 挂断 → `stopPiP`；静音 → `setMuted`；摄像头可空操作 |
| 直播 | `VIDEO_LIVE` | `VIDEO_PLAY_PAUSE` + `MUTE_SWITCH` | 播放/暂停 + 静音 |

改 `tpl` 那一行，`getControlGroups(tpl)` 带上同族控件；`onControlEvent` 必须按上表同族处理（见 [pip-xcomponent.md](pip-xcomponent.md)）。
