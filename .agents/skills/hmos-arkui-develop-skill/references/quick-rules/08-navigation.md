# 11. 导航与路由约束

## 规则

| 规则 | 说明 | 错误码 |
|------|------|--------|
| 推荐使用 Navigation + NavDestination | 替代 @ohos.router 和 pageTransition | — |
| Router 页面栈上限 32 | 超过 32 页报错 | **100003** |
| Navigation 默认转场时长不可控 | 弹簧曲线，时长因设备而异。**不要将业务逻辑耦合到默认转场时长** | — |
| 共享元素转场需禁用默认转场 | geometryTransition 时**必须禁用**系统默认转场动画 | — |
| customNavContentTransition 优先级更高 | 同时设置 Navigation 级和 NavDestination 级转场时，Navigation 级优先 | — |
| 未注册 builder 函数 | Navigation 跳转未注册 builder 的页面 | **100005** |
| 无 NavDestination 组件 | Navigation 跳转未包含 NavDestination 的页面 | **100006** |
| pushPath/pushDestination param 禁内联字面量 | `param: { id: 1 }` 是无类型字面量 → **10605038** | **10605038** |
| NavDestination 无 titleMode | titleMode 是 Navigation 专属属性，NavDestination 只有 `.title()` | **10505001** |
| 路由栈读取 | 目标页 `NavDestination().onReady((ctx: NavDestinationContext) => { this.navPathStack = ctx.pathStack })` 取栈，`ctx.pathInfo.param` 取参；不推荐 `@Provide`/`@Consume` 传 NavPathStack | — |
| 目标页根节点为 NavDestination | 目标页 `build()` 首节点必须是 `NavDestination`，否则白屏/挂载失败 | **100006** |
| 单 navDestination builder | 链式多次 `.navDestination()` 后者覆盖前者，所有路由落到最后一个页面（编译期不报错，运行时白屏） | — |
| 路由表与 .navDestination 互斥 | `module.json5` 声明了 `"routerMap"` 后**不要再写 `.navDestination(builder)`**：路由表已解析所有 name→page，builder 是冗余（重复映射、易漂移）。二者择一，有路由表就删掉 builder | — |
| loadContent 路径三处一致 | `windowStage.loadContent('pages/Index')`（Index 为示例，以具体工程的文件名为准）的 `Index` 必须与 `main_pages.json` 的 `src` 数组注册名、磁盘 `.ets` 文件名三者一致；未注册或不存在的路径运行时加载失败 → 白屏（app 不崩、编译期无诊断）。命名一个页面后，loadContent、main_pages、文件名三处用同一个名字 | — |
| 禁止 AppStorage 共享 NavPathStack | 经 `AppStorage.setOrCreate`/`AppStorage.get` 传栈与 `@Provide`/`@Consume` 同属反模式：其他组件在首帧渲染期间取栈并 `pushPathByName` → `@State`/`@Local` 状态变量在 render 期间被改（`AceStateMgmt: ... has changed during render!`）。目标页统一用 `NavDestination().onReady((ctx: NavDestinationContext) => { this.navPathStack = ctx.pathStack })` 取栈 | — |
| hideNavBar 语义陷阱 | `.hideNavBar(true)` 隐藏导航页（标题+内容+工具栏），栈空时首页显示空白，且失去自适应分栏能力；全屏需求用 NavDestination 的 `.fullScreenOverlay(true)`，只藏标题用 `.hideTitleBar(true)` | — |
| Dialog 类型 NavDestination 无默认转场 | API 13 前无默认转场动画 | — |

### 参数传递

```ts
// ❌ WRONG -- param 内联字面量
this.stack.pushPath({ name: 'first', param: { id: 1 } })   // 10605038

// ✅ RIGHT -- param 先声明类型再传变量
interface PageParam { id: number }
const p: PageParam = { id: 1 }
this.stack.pushPath({ name: 'first', param: p })
```

### 转场动画约束

| 规则 | 说明 |
|------|------|
| 默认转场时长不可控 | 弹簧曲线，因设备而异，不要把业务逻辑耦合到默认转场时长 |
| geometryTransition 须禁用默认转场 | 否则叠加产生视觉异常 |
| 同时设置 Navigation 级和 NavDestination 级转场 | Navigation 级（customNavContentTransition）优先 |
| pageTransition 已废弃 | 用 Navigation 转场和 Modal 转场 |

---

## 多文件 Navigation 路由架构

**不要把所有页面放在一个文件**。`@ComponentV2 export struct` 支持跨文件导出。

### 方案一（推荐）：系统路由表 router_map.json

无需 import 页面、按需加载、天然跨模块，多页面一律用此方案。

- 配置 `resources/base/profile/router_map.json`（`routerMap` 数组：`name` + `buildMethod` + `pageSourceFile`）
- `module.json5` 添加 `"routerMap": "$profile:router_map"`
- 页面文件导出 `@Builder export function XxxBuilder(): void { XxxPage() }`
- 主文件用 `pushDestination({ name: 'PageName', param })` 跳转：Promise 返回、错误码经 reject 传递（`pushPath`/`pushPathByName` 无错误码返回，不推荐）
- 目标页在 `NavDestination().onReady((ctx: NavDestinationContext) => { this.navPathStack = ctx.pathStack })` 取栈，`ctx.pathInfo.param` 取参（见上方规则表）

> ⚠️ **方案一与方案二互斥，不可并存**：声明了 `router_map.json` + `module.json5` `"routerMap"` 后，**不要再挂 `.navDestination(builder)`**。路由表已独自解析所有 `name`→page，再写 builder 只是重复映射（两处 name→page 易漂移、难维护）。有路由表就删掉 builder；要 builder 就别建路由表。

### 方案二（备选）：自定义路由表 .navDestination(builder)

仅限单层简单场景。必须用**单个** builder 内 `if/else` 做 name→page 映射；**链式多次 `.navDestination()` 后者覆盖前者**，所有路由会落到最后一个页面（编译期不报错，运行时白屏）。

```ts
// PageA.ets
@ComponentV2 export struct PageA {
  @Param navPathStack: NavPathStack = new NavPathStack()
  @Param goodsIdValue: string = ''
  build() { NavDestination() { /* ... */ } }
}

// MainHost.ets
import { PageA } from './PageA'
@Entry @ComponentV2 struct MainHost {
  @Local navPathStackValue: NavPathStack = new NavPathStack()
  @Builder pageMap(name: string, param: Object) {
    if (name === 'PageA') { PageA({ navPathStack: this.navPathStackValue, goodsIdValue: '123' }) }
  }
  build() {
    Navigation(this.navPathStackValue) { /* 首页 */ }.navDestination(this.pageMap)
  }
}
```

> 页面获取栈：`onReady` 从 NavDestinationContext 取（推荐，可同时取 `pathInfo.param`）；`queryNavigationInfo()`（12+，推荐）任意自定义组件任意时机可取、不依赖生命周期。**禁止** `@Provide`/`@Consume` 或 AppStorage 传栈（渲染期取栈 `pushPathByName` 会触发 `AceStateMgmt: ... has changed during render!`）。

---

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| 使用 `@ohos.router` 做页面跳转 | Navigation + NavDestination | Router 不推荐 |
| 多个页面各自 `@Entry` | 单 Page 应用只有一个 @Entry | 多页面通过 Navigation 管理 |
| Navigation 跳转未注册 builder | 必须在 Navigation 中注册 destination builder | 100005 |
| 使用 `pageTransition` 做页面转场 | Navigation 转场或 Modal 转场 | pageTransition 已废弃 |
| pushPath 的 param 内联字面量 | 先声明 interface 再用 interface 类型变量传递 | 10605038 |
| NavDestination 调用 titleMode | NavDestination 只用 `.title()`，`.titleMode()` 只挂 Navigation | 10505001 |
| 路由表 + `.navDestination()` 并存 | 声明 `router_map.json` 后删掉 `.navDestination(builder)`，二者只留其一 | 冗余 |
| `loadContent('pages/Index')` 但 `main_pages.json` 注册的是 `pages/IndexPage` | loadContent 路径、`main_pages.json` 的 `src` 注册名、磁盘 `.ets` 文件名三处用同一个名字 | 白屏 |
| `AppStorage.setOrCreate('navStack', this.pathStack)` 全局共享栈 | 目标页 `NavDestination().onReady((ctx) => { this.navPathStack = ctx.pathStack })` 取栈 | 渲染期改状态报错 |

## 参考

- 废弃接口替换见 [19-deprecated](14-deprecated.md)
- 对话框与半模态见 [12-dialog](09-dialog.md)