# 画中画开发指导（Skill 落盘）

总目录：[画中画开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/window-pipwindow)

| 子页 | 何时用 |
|------|--------|
| [使用 XComponent](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/pipwindow-xcomponent) | **写 demo 默认 / 一镜到底**。`create(config)` 无第二参。同一 `XComponentController` |
| [使用 typeNode](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/pipwindow-typenode) | 仅用户明确要迁自定义节点。`create(config, contentNode)`。**不是一镜到底**（系统拿不到源矩形） |
| 使用 NDK | 本 skill **不写** C/C++ |

完整签名以 [js-apis-pipWindow.md](../apis/js-apis-pipWindow.md) 为准。本文是步骤摘要。骨架见 [pip.md](../../assets/pip.md)。日常不要打开官网。

## 一镜到底

一镜到底 = 小窗从**主页视频框**飞出，播放不中断、不重头。

系统靠页面上那个 `XComponent` 的 controller 取 `GetGlobalPosition` / `GetSize`，再把 **同一块 surface** 接到 PiP 窗。所以默认必须：

- 布局里写 `XComponent(SURFACE, 同一 controller)`（官方样例高 `800px`）
- `create(config)` **不要**第二参
- `componentController` 与布局里的是**同一个对象**
- 进 PiP **不要**摘掉这个 `XComponent`，**不要** `release` / 重建 `AVPlayer`
- `PageMap` 直接 `Page1({ navId })`，`Page1` 根节点是 `NavDestination()`

typeNode 路径源码直接打 `use typeNode, unable to locate source rect`，拉起没有源矩形；再在 `ABOUT_TO_START` 摘节点会把 surface 拆掉。用户没说迁自定义节点，不要走 typeNode。

## Navigation 避坑（写程序先判定，再填 config）

先看工程怎么管页。写新 demo 用宿主 `Navigation` + `Page1`（[pip.md](../../assets/pip.md)）。**不要**给已经是单页、没有 Navigation 的 `Index` 再包一层。

| 工程现状 | `navigationId` | 还原 |
|----------|----------------|------|
| 单页 `Index`，没有 `Navigation` | **不要写** | 系统直接回该页 |
| Index 列表进 `PipHost`（PiP 尚未 start） | PipHost 内 Navigation **必填** | 用 `this.getUIContext().getRouter().pushUrl({ url: 'pages/PipHost' })` 只负责进宿主 |
| `startPiP` 之后再 `pushUrl`/`back` | — | **禁止**；还原页会错 |
| 已有 `Navigation` / `NavPathStack` | **必填**，且与 `Navigation.id` **同一字符串** | 点还原才回视频页 |

**配对（有 Navigation 时最小写法）**

```ts
Navigation(this.pathStack) {
  // 视频页内容
}
.id('nav_pip')

this.pip = await PiPWindow.create({
  context: ctx,
  componentController: this.xCtrl,
  navigationId: 'nav_pip',
  templateType: PiPWindow.PiPTemplateType.VIDEO_PLAY
});
```

踩坑对照：

1. **写了 `navigationId` 但 `Navigation` 没 `.id()`**，或两个字符串不一致 → 还原失败 / `1300013`
2. **把 `NavDestination` 的 `name`、路由 path、文件名当成 `navigationId`**。`navigationId` 只认 `Navigation.id`
3. **`navDestination` 直接返回自定义 `@Component`，根节点不是 `NavDestination()`** → 二级页白屏。官方写法是 **Page1 自己当根节点**：

```ts
@Builder
PageMap(name: string) {
  if (name === 'pageOne') {
    Page1({ navId: this.navId }); // Page1.build() 根节点必须是 NavDestination()
  }
}
Navigation(this.pageInfos) { /* pushPath */ }
  .navDestination(this.PageMap)
  .id(this.navId)
```

4. **单页却抄了 `navigationId: 'nav_pip'`** → 无对应控件，还原异常
5. **有 Navigation + 退后台继续播**：在**已经停在视频页**后再第一次 `setAutoStartEnabled(true)`。系统会缓存该 `navigationId` 当时的**栈顶**。在首页就 true，还原会回到首页而不是视频页
6. **离开视频 `NavDestination` 时** `setAutoStartEnabled(false)`，回到视频页再 true。单页 demo 不要在 `onPageHide` 里关
7. **PiP 回调里 push/pop**：主窗不在前台时不要做。若 `ABOUT_TO_START` 里 `pop` 了视频页，必须在 `ABOUT_TO_RESTORE` 里再 `push` 回去
8. **API 22+ 还原到指定子页**才设 `handleId`（推荐 `getUniqueId()` + 系统路由表）。默认 `-1` = 栈顶。不要拿 Navigation id 字符串去填 `handleId`
9. **一镜到底不要在 `ABOUT_TO_START` 摘 `XComponent`**。摘节点只属于 typeNode

Router：`startPiP` 之后不要 `pushUrl`/`back`。Index 进 PipHost 可以 pushUrl，那是进宿主，不是 PiP 导航。

## 开发步骤（页面 XComponent，一镜到底）

官网示例里的视频播放走 **AVPlayer**。没有 surface + 播放器，小窗是黑的。不要抄接口文档空壳。

```text
pushPath → Page1 根节点 NavDestination
  → 布局 XComponent(SURFACE, 同一 controller)
  → onLoad：绑 AVPlayer
  → 按钮：create(config) 一次、无第二参 → 视频页 setAutoStartEnabled(true) → startPiP → STARTED
```

1. 布局 `XComponent` 与 `PiPConfiguration.componentController` **同一个**。不要 `.clip(true)`。高 `800px`
2. **在 `onLoad` 里取 surfaceId** 再绑 AVPlayer。先 `on('stateChange')` 再设 `fdSrc`；**仅 `initialized` 里**设 `surfaceId` 然后 `prepare`
3. `canIUse` + `isPiPEnabled` → 视频页按钮 `create(config)` 无第二参（只一次）→ `on('stateChange')` / `on('controlEvent')` → `startPiP`
4. 「退出后继续播」：在**已经停在视频页**后 `setAutoStartEnabled(true)`。系统「智慧多窗 → 自动启动画中画」关闭则不会**自动**拉起，按钮 `startPiP` 不受影响。不要在 `onPageHide` / `aboutToDisappear` 里 `stopPiP`
5. 失败要有页面提示。不要用没 surface 挡住 start。以 `STARTED` 为准。**不要** `ABOUT_TO_START` 摘组件
6. `controlGroups` / `controlEvent` 必须与 `templateType` 同族，见 [pip.md](../../assets/pip.md)
7. 用户点停止才关；进 PiP 时页面还在，不要 release 播放器

片源：模块 `resources/rawfile/test.mp4`。`contentWidth`/`contentHeight` 建议显式传入。

## typeNode（迁节点，不是一镜到底）

1:1 官方 [WindowPip Navigation typeNode](https://gitcode.com/HarmonyOS_Samples/guide-snippets/tree/master/ArkUIWindowPipSamples/WindowPip)。骨架：[pip-typenode.md](../../assets/pip-typenode.md)。

```text
Page1 根节点 NavDestination + NodeContainer
  → onShown：create(config, node)，不写 navigationId
  → 按钮 startPiP
  → ABOUT_TO_START removeNode（官方可选 pop）
  → ABOUT_TO_STOP addNode
```

`PageMap` 直接 `Page1()`，不要再包 `NavDestination`。不要给 typeNode 填 `navigationId`。系统拿不到源矩形，拉起不是从视频框飞出。

## 不要

- 只抄接口文档空壳（没有播放器）
- 把 typeNode 当默认还要求一镜到底
- 一镜到底路径 `create(config, contentNode)` 或 `ABOUT_TO_START` 摘 `XComponent`
- 进 PiP 时重建 / `release` AVPlayer
- `startPiP` 因没有 surfaceId 就 return
- `XComponent` 上 `.clip(true)`
- 用 `createSubWindow` / `TYPE_FLOAT` 冒充画中画
- 把 `create` 成功当成小窗已显示
