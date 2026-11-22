## 12. 导航与路由


> **组件索引**：`Navigation`、`NavPathStack 操作`、`NavDestination`、`Router`

### Navigation

**构造：** `Navigation()`

**属性方法：**

| 方法 | 签名 | 默认值 | 说明 |
|------|------|--------|------|
| .navDestination | `.navDestination(builder)` | — | 路由目标映射 |
| .title | `.title(string \| NavigationCommonTitle \| NavigationCustomTitle)` | — | 标题 |
| .subtitle | `.subtitle(string)` | — | 副标题 |
| .mode | `.mode(NavigationMode)` | Auto | Stack/Split/Auto |
| .hideNavBar | `.hideNavBar(value: boolean)` | false | 隐藏导航页（标题栏+内容区+工具栏）。栈中有 NavDestination 则显示栈顶页面，反之显示空白；API 11+ 单栏/双栏/自适应模式均生效，会失去自适应分栏能力；全屏需求改用 NavDestination 的 `.fullScreenOverlay(true)`，只藏标题用 `.hideTitleBar(true)` |
| .hideTitleBar | `.hideTitleBar(value: boolean)` | false | 隐藏标题栏 |
| .hideToolBar | `.hideToolBar(value: boolean)` | false | 隐藏工具栏 |
| .toolBar | `.toolBar(value: ToolbarConfiguration)` | — | 工具栏 |
| .navBarWidth | `.navBarWidth(value: Length)` | 240vp | 导航栏宽度 |
| .navBarPosition | `.navBarPosition(value: NavBarPosition)` | Start | 导航栏位置 |
| .splitResizable | `.splitResizable(value: boolean)` | false | 分栏可调 |

### NavPathStack 操作

| 方法 | 签名 | 说明 |
|------|------|------|
| pushPath | `pushPath(info: NavPathInfo, options?)` | 压入页面（无错误码返回） |
| pushPathByName | `pushPathByName(name, param, animated?)` | 按名称压入（无错误码返回） |
| pushDestination | `pushDestination(info, options?): Promise<void>` | 压入页面，错误经 Promise reject 错误码返回（**推荐**） |
| pushDestinationByName | `pushDestinationByName(name, param, options?): Promise<void>` | 按名称压入，错误经 reject 返回（**推荐**） |
| pop | `pop(result?, options?)` | 弹出 |
| replacePath | `replacePath(info, options?)` | 替换 |
| clear | `clear()` | 清空 |
| size | `size(): number` | 栈大小（方法） |
| getParent | `getParent(): NavPathStack \| undefined` | 获取父栈 |

### NavDestination

**构造：** `NavDestination()`

**属性方法：**

| 方法 | 签名 | 默认值 | 说明 |
|------|------|--------|------|
| .title | `.title(string \| CustomBuilder)` | — | 标题 |
| .hideTitleBar | `.hideTitleBar(boolean)` | false | 隐藏标题栏 |
| .hideBackButton | `.hideBackButton(boolean)` | false | 隐藏返回键 |
| .backgroundColor | `.backgroundColor(ResourceColor)` | — | 背景色 |

**事件：** `.onReady((context: NavDestinationContext) => void)` `.onWillShow()` `.onShown()` `.onHidden()` `.onWillHide()` `.onBackPressed()`

### Router

| 方法 | 签名 | 说明 |
|------|------|------|
| pushUrl | `router.pushUrl({url, params?})` | 压入页面 |
| replaceUrl | `router.replaceUrl({url, params?})` | 替换当前页 |
| back | `router.back(url?)` | 返回 |
| clear | `router.clear()` | 清空栈 |
| getLength | `router.getLength(): number` | 栈大小 |
| getState | `router.getState(): RouterState` | 当前状态 |

### 典型用法

#### 页面生命周期选择

| 回调 | Pop 回来触发 | 前后台切换触发 | 适用场景 |
|------|:----------:|:-----------:|---------|
| `onWillShow` | ✅ | ❌ | 页面即将显示前的初始化 |
| `onShown` | ✅ | ✅ | **前后台刷新、Pop 回来刷新** |
| `onActive` | ✅ | ❌ | overlay/Sheet 遮挡后恢复 |

> `onPageShow` 是 `@Entry` 根页面回调，感知不到 NavDestination 子页面的 push/pop，从详情页 Pop 返回时不会触发。子页面可见性用 `onShown`。

#### 参数传递与接收

```ts
// 1. 声明参数类型（禁内联字面量 → 10605038）
export interface DetailParams { capsuleId: string }

// 2. 跳转
const p: DetailParams = { capsuleId: '123' }
stack.pushPath({ name: 'Detail', param: p })

// 3. 目标页面接收
@Param navPathStack: NavPathStack = new NavPathStack()
build() {
  NavDestination()
    .onReady((ctx: NavDestinationContext) => {
      const param = ctx.pathInfo.param as DetailParams  // 取参
    })
}
```

#### 获取导航栈 NavPathStack 的方式

| 方式 | 写法 | 说明 |
|------|------|------|
| `queryNavigationInfo`（12+，推荐） | `let info = this.queryNavigationInfo(); if (info !== undefined) { this.pathStack = info.pathStack }` | 自定义组件方法，任意时机可取、不依赖 NavDestination 生命周期 |
| `onReady`（推荐） | `NavDestination().onReady((ctx: NavDestinationContext) => { this.navPathStack = ctx.pathStack; const p = ctx.pathInfo.param as DetailParams })` | NavDestination 生命周期回调，取栈同时可取本页参数 |
| AppStorage 全局共享 | 宿主 `AppStorage.setOrCreate` / 页面 `AppStorage.get` | **禁止**：渲染期取栈并 `pushPathByName` 会触发 `AceStateMgmt: ... has changed during render!` |
| `@Provide`/`@Consume` | 跨层级传递 | 不推荐 |

#### EntryAbility 加载首页

`windowStage.loadContent('pages/Index')`（Index 为示例，以具体工程的文件名为准）的 `pages/Index` 必须与 `main_pages.json` 的 `src` 数组注册名、磁盘 `pages/Index.ets` 文件名三者一致；不一致时运行时加载失败 → 白屏（编译期无诊断）。

#### 全局路由状态监听

`uiObserver.on('navDestinationUpdate', (info: NavDestinationInfo) => ...)` 监听 NavDestination 显示/隐藏状态变化（经 `this.getUIContext().getUIObserver()` 获取 observer，见 @ohos.arkui.observer）。

#### 编辑页返回确认

```ts
NavDestination()
  .onBackPressed(() => {
    if (this.hasUnsavedChanges) {
      // 拦截返回，弹出确认
      this.getUIContext().showAlertDialog({
        message: '有未保存的修改，确定返回吗？',
        primaryButton: { value: '取消', action: () => {} },
        secondaryButton: { value: '确定返回', action: () => this.navStack.pop() }
      })
      return true
    }
    return false
  })
```
