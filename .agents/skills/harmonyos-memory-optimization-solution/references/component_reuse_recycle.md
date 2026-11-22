# 复用和释放离线组件指南

## 目录

1. [复用和释放概述](#复用和释放概述)
2. [复用离线Web组件](#复用离线web组件)
3. [离开Web页面后加载空页面](#离开web页面后加载空页面)
4. [组件创建与取件模式](#组件创建与取件模式目标-url-直接创建)
5. [页面恢复显示时重载目标页](#页面恢复显示时重载目标页)
6. [安全释放条件](#安全释放条件)
7. [退后台释放与前台恢复](#退后台释放与前台恢复)
8. [完整实现方案](#完整实现方案)
9. [常见问题排查](#常见问题排查)

---

## 复用和释放概述

通过复用和释放离线Web组件，可以优化内存占用，降低应用因内存占用过高被系统终止的概率。

### 核心原则

- 每个窗口推荐只使用一个Web组件。
- 建议复用离线Web组件，减少组件创建和销毁的性能消耗以及内存占用。
- 建议在应用退后台时释放不需要的离线Web组件。
- 仅当离线Web组件未绑定到UI页面时，才能安全释放。

### 复用与释放是两个不同操作层次——不可互相替代

> **高发失误警告**：复用（`loadUrl('about:blank')`）和释放（`dispose()` + `rebuild()`）的内存效果完全不同。复用不释放内存（组件存活、内容清空），释放才释放内存（组件销毁）。退后台时必须走释放链路，不得用复用操作替代释放操作。详见下方[复用与释放的职责划分](#复用与释放的职责划分)。

| 操作层次 | 操作 | 内存效果 | 触发时机 |
| --- | --- | --- | --- |
| **复用**（低层） | `loadUrl('about:blank')` | 组件存活，内容清空，**不释放内存** | 页面跳转 |
| **释放**（高层） | `dispose()` + `rebuild()` | 组件销毁，**释放内存** | 退后台 |

退后台时用复用操作替代释放操作（如用 `onInactive()` + `loadUrl('about:blank')` 替代 `dispose()` + `rebuild()`），会导致内存不释放、优化无效。这是最常见的实现失误。

---

## 离开Web页面后加载空页面

### 职责边界

当用户离开Web页面（页面跳转/NavDestination pop）时，**只做复用准备，不做释放**。调用 `WebviewController` 的 `loadUrl` 方法加载 `about:blank` 空页面，清空当前Web内容，使该离线组件回到空闲态，供下次其他UI页面通过 `getFreeWebNode()` 取出复用。

> **禁止在页面跳转时调用 `dispose()` + `rebuild()` 释放组件**。释放（销毁BuilderNode）是重操作，每个Web组件约200MB内存，反复创建销毁的性能与内存开销远大于复用。释放仅应在应用退后台时由 `UIAbility.onBackground` 统一触发（见[退后台释放与前台恢复](#退后台释放与前台恢复)）。

### 离开页面示例

离开时在 `onWillHide` 中加载空页面并延迟解绑（完整写法见「复用离线Web组件」的复用示例），两个步骤缺一不可：

- `loadUrl('about:blank')`：清空当前 Web 内容，为复用做准备；
- `setTimeout(() => { this.node = undefined }, 100)`：延迟解绑，`NodeContainer` 不再持有引用 → 触发 `onUnbind()` → `bindCount=0` → 组件可被 `getFreeWebNode()` 再次取到。

### 复用与释放的职责划分

| 操作 | 调用方法 | 触发时机 | 内存影响 | 适用场景 |
| --- | --- | --- | --- | --- |
| **复用准备** | `loadUrl('about:blank')` | 页面跳转（`onWillHide`） | 无（组件仍存在，内容清空） | 页面间跳转，预期快速复用 |
| **释放组件** | `dispose() + rebuild()` | 应用退后台（`onBackground`） | 高（组件销毁，释放 ~200MB） | 应用退后台，长期不可见 |

> **关键原则**：页面跳转走复用链路（`loadUrl('about:blank')`，组件在 `nodeMap` 内流转不销毁）；退后台走释放链路（`dispose()+rebuild()`，组件从 `nodeMap` 移除并记入 `recycledNWebs`），两条链路解耦，互不干扰。

参考[复用和释放离线组件示例](../assets/ComponentReuseRecycleExample.ets)

---

## 组件创建与取件模式（目标 url 直接创建）

> 实测修正（API 26 构建验证）：createNWeb 直接以目标 url 创建组件（构建即加载），仅复用空闲件时才 loadUrl。

### 创建即加载，不要「空白件 + 立即 loadUrl」

`createNWeb(目标url)` 内部 `BuilderNode.build` 传入 `Web({ src: 目标url })`，组件构建时即开始加载目标页，**无需再 loadUrl**。先创建 `about:blank` 空白件、进页后再 `loadUrl` 目标页的写法，首次进入会经历 about:blank → 目标页的二次导航，属于多余开销。

### 页面侧取件顺序（onPageShow / onWillShow）

1. 优先 `getFreeWebNode()` 复用空闲件（未绑定且内容已置空）——**仅此路径需要 loadUrl(目标url)**；
2. 池空时 `createNWeb(目标url, uiContext)` 直接创建 + `getNWeb(目标url)` 取件，**不 loadUrl**（构建即加载）；
3. 已持有组件（退后台回前台、绑定未动）不取件不 loadUrl，内容原样显示（重入守卫被结构化吸收）。

```typescript
onPageShow(): void {
  if (!this.node) {
    this.node = getFreeWebNode()                    // ① 复用路径：内容已置空的空闲件
  }
  if (!this.node) {
    createNWeb(TARGET_URL, this.getUIContext())     // ② 池空：直接以目标 url 创建，构建即加载
    this.node = getNWeb(TARGET_URL)
  }
  // 仅内容已置空的复用件才 loadUrl；新建件构建即加载，已在显示目标页的绑定件不重载
  if (this.node && this.node.isBlanked()) {
    this.node.loadUrl(TARGET_URL)
  }
}
```

### 空闲件判定必须覆盖「置空回池的目标 url 组件」

以目标 url 创建的组件，离开页面 `loadUrl('about:blank')` 置空回池后，其 **nodeMap key 仍为目标 url（不以 about:blank 开头）**。若 `getFreeWebNode` 仅按「key 以 about:blank 开头」判定，将取不到该组件——复用失效，表现为每次进页新建组件或白屏。需在控制器内维护空白态标记，判定条件扩展为「未绑定 &&（key 为 about:blank 前缀 || 空白态标记）」：

```typescript
export class MyNodeController extends NodeController {
  /** 内容是否处于空白态（loadUrl('about:blank') 置位 / 加载目标页复位） */
  private blanked: boolean = false

  initWeb(url: ResourceStr, uiContext: UIContext): void {
    if (this.rootNode !== null) {
      return
    }
    this.rootNode = new BuilderNode<[WebData]>(uiContext)
    this.rootNode.build(wrap, new WebData(url, this.webController))
    this.blanked = String(url).startsWith('about:blank')   // 按初始 url 初始化
  }

  isBlanked(): boolean {
    return this.blanked
  }

  async loadUrl(url: ResourceStr | undefined): Promise<void> {
    if (url === undefined) {
      return
    }
    try {
      this.webController.loadUrl(url)
      this.blanked = String(url).startsWith('about:blank') // 加载成功后同步空白态
    } catch (e) {
      console.info('loadUrl error: ' + JSON.stringify(e))
    }
  }
}

export const getFreeWebNode = (): MyNodeController | undefined => {
  for (let url of nodeMap.keys()) {
    const node: MyNodeController | undefined = nodeMap.get(url)
    if (node && !node.isBound() &&
      (String(url).startsWith('about:blank') || node.isBlanked())) {
      return node
    }
  }
  return undefined
}
```

### loadUrl 静默失败与时间维度兜底

`WebviewController.waitForAttached(timeout)`（API 20+，返回 `Promise<ControllerAttachState>`）返回后，`loadUrl` **仍可能静默失败**（引擎未就绪时不抛异常，Web 停留 about:blank → 白屏）。可靠兜底是加载后做时间维度校验重试：例如 300ms 间隔 × 5 次，`getUrl()` 仍为 about:blank 前缀则重载目标页。

### 本地 rawfile 目标页的 url 形式

目标页为本地 rawfile 资源时，池内 key 与 `Web src`/`loadUrl` 统一使用 `'resource://rawfile/<路径>'` 字符串形式（两者均支持 resource 协议）。不要用 `$rawfile(...)` 的 Resource 对象作 nodeMap key——每次调用产生新对象、按引用比较，`createNWeb` 的幂等判断与 `getNWeb` 取件都会失效。

### API 26 签名要点（照抄旧示例会编译失败，写前 grep 本机 d.ts）

- `NodeController`/`BuilderNode`/`FrameNode`/`UIContext`/`Size` 必须显式 `import { ... } from '@kit.ArkUI'`（非环境全局，不导入 extends 直接报 Cannot find name）。
- `BuilderNode` 为**元组泛型**：`new BuilderNode<[WebData]>(uiContext)` + `wrapBuilder<[WebData]>(webBuilder)`，`build(wrap, 单个 WebData 对象)`（@Builder 收单参数）。
- `NodeController.onBind/onUnbind` 本机 API 26 签名为 **`(containerId: number)`**；早期文档示例的 `(detached: FrameNode)` 已过时，照抄编译失败。
- `BuilderNode.dispose(): void` 存在；释放时 `dispose()` 后跟 `NodeController.rebuild()` 使节点脱离绑定。

### nodeMap 用唯一 key 而非 url

> 实测修正：`nodeMap` 的 key 必须是**唯一标识**（如 `genWebKey()` 生成的 `web_1`/`web_2`/...），**不能用 url 作 key**。否则同 url 的两个页面实例同时存活时第二个页面取到第一个页面已绑定的组件，引发绑定冲突/白屏。

**问题场景**：同一 `BadWebPage`（目标 url 相同）被 `pushPath` 连续推入两次——两个页面实例同时存活、同时需要各自的 Web 组件。若 `nodeMap` 用 url 作 key：

1. 第一个页面 `createNWeb(url, ...)` 创建组件 A，`nodeMap.set(url, A)`；
2. 第二个页面 `createNWeb(url, ...)` 命中幂等检查 `if (getNWeb(url)) return`，**不创建新组件**；
3. 第二个页面 `getNWeb(url)` 取回的是**第一个页面正在绑定的组件 A** → 两个 `NodeContainer` 绑定同一 `NodeController`，绑定状态错乱、显示冲突。

**正确做法**：`nodeMap: Map<string, MyNodeController>`，key 由 `genWebKey()` 生成唯一标识（页面实例创建时调用 `private webKey: string = genWebKey()`）。`createNWeb(key, url, uiContext)` / `getNWeb(key)` / `recycleNWeb(key)` 全部按 key 操作。`getFreeWebNode()` 扫描「未绑定 && `isBlanked()`」复用，与 key 无关。

```typescript
let webKeyCounter: number = 0;
export const genWebKey = (): string => {
  webKeyCounter += 1;
  return 'web_' + webKeyCounter.toString();
}

let nodeMap: Map<string, MyNodeController | undefined> = new Map();

export const createNWeb = (key: string, url: ResourceStr, uiContext: UIContext) => {
  if (getNWeb(key)) { return; }            // 幂等检查按 key，同 url 不同 key 不冲突
  let baseNode = new MyNodeController();
  baseNode.initWeb(url, uiContext);
  nodeMap.set(key, baseNode);
}

export const getNWeb = (key: string | undefined): MyNodeController | undefined => {
  return key === undefined ? undefined : nodeMap.get(key);
}

// 页面侧：每个实例独立 webKey
private webKey: string = genWebKey()
// onWillShow 取件：
createNWeb(this.webKey, this.targetUrl, this.getUIContext())
this.node = getNWeb(this.webKey)
```

> **配套：`getFreeWebNode` 判定改为只用 `isBlanked()`**。key 改为唯一标识后不再携带 url 信息，「key 以 about:blank 开头」判定不再适用；`isBlanked()` 已涵盖 about:blank 创建件与目标 url 创建后置空回池件两类，单独判定即可。

---

## 页面恢复显示时重载目标页

### 为什么必须重载

页面实例在 `push` 跳转后**仍然存活**（router 页面保栈 / NavDestination 入栈），`aboutToAppear` 对同一页面实例**只触发一次**。离开页面时组件已被 `loadUrl('about:blank')` 置空（见上节），若恢复显示时不重新加载，Web 将停留在 `about:blank`，表现为**白屏**。因此复用是**成对的两个动作**：

| 时机 | 动作 | 回调（NavDestination） | 回调（@Entry router 页面） |
| --- | --- | --- | --- |
| 离开页面 | `loadUrl('about:blank')` 置空 + 延迟解绑回池 | `onWillHide` | `onPageHide` |
| 恢复显示 | 重新取回组件 + `loadUrl(currentUrl)` 重载目标页 | `onWillShow` | `onPageShow` |

> **架构推荐：优先使用 Navigation/NavDestination**。`onWillShow`/`onWillHide` 是**纯导航事件，不随应用前后台触发**，复用时机语义干净。`@Entry` router 页面的 `onPageShow`/`onPageHide` **会随前后台触发且与 Ability 生命周期交错**（实测顺序：退后台 `onBackground → onPageHide`，回前台 `onPageShow → onForeground`），会引发置空/取件在错误时机执行（详见[常见问题排查](#常见问题排查)与[与退后台释放链路的衔接](#与退后台释放链路的衔接)）。router 架构继续使用时须补齐三件套守卫，见排查条目「应用退后台/回前台后 Web 白屏或组件错乱」。

> **高发失误**：只实现离开置空（onWillHide/onPageHide），漏掉恢复重载（onWillShow/onPageShow），首次进入正常（aboutToAppear 触发了加载），跳转后返回必现 `about:blank` 白屏。

### 恢复取回组件：getFreeWebNode 扫描空闲池

恢复显示时需要把离线组件重新绑回页面的 `NodeContainer`：遍历 `nodeMap` 取「未绑定（`isBound()` 为 false）且内容已置空（`isBlanked()` 为 true）」的空闲组件——不关心具体 key/url，只要有空闲件即可：

```typescript
// 获取空闲的NWebNode接口：遍历nodeMap找未绑定且isBlanked()的组件
// key 为唯一标识不携带 url 信息，空闲态只按 isBlanked() 判定
export const getFreeWebNode = (): MyNodeController | undefined => {
  for (let key of nodeMap.keys()) {
    let node = nodeMap.get(key);
    if (node && !node.isBound() && node.isBlanked()) {
      console.info('getFreeWebNode key = ' + key);
      return node;
    }
  }
  console.warn('getFreeWebNode, no offline web node returned');
  return undefined;
}
```

- 扫描式取件依赖离开页面的**置空 + 延迟解绑**（`onWillHide` 中 `loadUrl('about:blank')` + `setTimeout` 解绑）先行完成，否则组件不满足「未绑定且已置空」条件，扫描不到空闲件。
- 返回 `undefined` 时页面按需 `createNWeb(key, targetUrl, ...)` 创建兜底（同官方示例 `if (!this.node) { this.node = getFreeWebNode(); }` 的空态处理）。
- `isBlanked()` 涵盖两类空闲件：about:blank 创建件（`initWeb('about:blank')` 置位）与目标 url 创建后置空回池件（`loadUrl('about:blank')` 置位），单独判定即可，无需叠加 key 前缀判定。

### 与退后台释放链路的衔接

**退后台释放必须用非强制 `recycleNWebs()`（默认 `force=false`）：只回收未绑定（空闲池）的组件，可见页面上仍绑定的组件存活不回收。** 这样两条链路各自闭环、互不干扰：

- **可见页（NavDestination 架构）**：退后台时组件仍绑定 → 不被回收 → 内容与绑定原样保留；`onWillShow`/`onWillHide` 为纯导航事件不随前后台触发，回前台**无需任何恢复动作**，内容原样显示。
- **空闲池组件**：退后台被 `dispose()+rebuild()` 释放（内存回落）；回前台 `restoreNWebs` 用 **about:blank 重建空闲件**回池（不按原 url 重建）；下次导航到 Web 页时 `onWillShow` 经 `getFreeWebNode()` 取回重建件 → `isBlanked()=true` → `loadUrl(targetUrl)` 加载目标页——**不得沿用页面成员里残留的释放前旧 `NodeController` 引用**（其 `rootNode` 已 `dispose()`，`makeNode` 返回已销毁节点导致白屏）。

> **禁止退后台强制回收（`force=true`）**：会把可见页正绑定的组件一并销毁。router 架构下回前台 `onPageShow` 先于 `onForeground`（`restoreNWebs`）执行，此刻池是空的——取不到组件白屏；且退后台 `onBackground` 先于 `onPageHide` 执行，页面随后对已销毁组件调 `loadUrl` 乱序报错。NavDestination 架构虽无回调交错，但可见内容同样会被销毁。

### 完整页面侧闭环示例（对照官方示例 Page2.ets）

```typescript
// NavDestination 页面（官方示例 Page2.ets 核心逻辑）
@State private node?: MyNodeController = getFreeWebNode();
@State private currentUrl: ResourceStr = this.targetUrl;

// 显示前，取回空闲组件并加载目标页（首次显示与跳转返回均触发）
.onWillShow(() => {
  if (!this.node) {
    this.node = getFreeWebNode();
  }
  this.node?.loadUrl(this.currentUrl);
})
// 加载空页面，并延迟解绑离线Web组件与页面的绑定（组件回空闲池，可被下次取回）
.onWillHide(() => {
  this.node?.loadUrl('about:blank');
  setTimeout(() => {
    this.node = undefined;
  }, 100)
})
```

@Entry router 页面将上述两个回调替换为 `onPageShow()` / `onPageHide()` 页面生命周期回调即可，语义一一对应（`aboutToAppear` 只负责首次建组件，不承担复用加载）。

---

## 安全释放条件

### 绑定状态检查

通过 `NodeController` 的 `onBind` 和 `onUnbind` 回调来跟踪离线Web组件的绑定状态，确保仅当组件未绑定到 UI 页面时才释放：

```typescript
export class MyNodeController extends NodeController {
  private rootNode: BuilderNode<[WebData]> | null = null;
  private isBoundFlag: boolean = false;
  private webController: webview.WebviewController = new webview.WebviewController();

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.rootNode !== null) {
      return this.rootNode.getFrameNode();
    }
    return null;
  }

  // 当节点被绑定时回调（API 26 签名为 containerId: number；早期文档的 detached: FrameNode 已过时）
  onBind(containerId: number) {
    console.info('onBind, containerId: ' + containerId);
    this.isBoundFlag = true;
  }

  // 当节点解除绑定时回调
  onUnbind(containerId: number) {
    console.info('onUnbind, containerId: ' + containerId);
    this.isBoundFlag = false;
  }

  // 判断是否已绑定
  isBound(): boolean {
    return this.isBoundFlag;
  }

  initWeb(url: ResourceStr, uiContext: UIContext) {
    if (this.rootNode !== null) {
      return;
    }
    this.rootNode = new BuilderNode<[WebData]>(uiContext);
    // 直接以传入 url 创建（构建即加载）；controller 须作为成员持有，供后续 loadUrl 使用
    this.rootNode.build(wrap, { url: url, controller: this.webController });
  }

  // 释放 BuilderNode（销毁组件树；随后须调用 rebuild() 使节点脱离绑定）
  release(): void {
    this.rootNode?.dispose();
  }
}
```

### 强制释放

当使用 `force: true` 参数时，可以强制释放已绑定的组件，但这会导致对应的 `NodeContainer` 白屏：

```typescript
// 强制回收所有离线Web组件（包括已绑定的，会导致白屏）
recycleNWeb(url, true);
```

> **警告**：强制释放仅应在应用退后台等确保UI不再显示的场景使用。

---

## 退后台释放与前台恢复

### 释放和恢复时机

在 `UIAbility` 的生命周期回调中执行释放和恢复：

- `onBackground`：应用退后台时，释放所有离线Web组件。
- `onForeground`：应用回前台时，恢复之前释放的离线Web组件。

### 实现方案

在 `EntryAbility` 中：

```typescript
import { recycleNWebs, restoreNWebs } from '../pages/Common';

// ...
onForeground(): void {
  // Ability has brought to foreground
  hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  // 恢复之前释放的离线Web组件
  restoreNWebs();
}

onBackground(): void {
  // Ability has back to background
  hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  // 释放所有离线Web组件
  recycleNWebs();
}
```

参考[复用和释放离线组件示例](../assets/ComponentReuseRecycleExample.ets)

### 回前台用 about:blank 重建空闲件（不按原 url 重建）

> 实测修正：`restoreNWebs` 应创建 `about:blank` 空闲件回池，**不按原 url 重建**。退后台释放后组件内容已不可信，回前台直接加载原 url 可能失败/状态过期；about:blank 重建后 `isBlanked()=true`，下次 `getFreeWebNode()` 取用时统一走 `loadUrl(targetUrl)` 路径，复用更可靠。

**为什么不用原 url 重建**：

| 维度 | 按原 url 重建（旧） | about:blank 重建（新） |
| --- | --- | --- |
| 内容可信度 | 退后台后原 url 内容可能过期（登录态/SPA 状态丢失） | 回池为空白，由页面 `loadUrl` 重新加载，内容新鲜 |
| 网络 url 风险 | 回前台重建即加载网络页，网络延迟/失败时组件处于加载中态，被取用后 `isBlanked()=false` 不 loadUrl，页面显示加载中 | 空白件 `isBlanked()=true`，取用后 `loadUrl` 重新加载，可控 |
| 复用路径统一 | 新建件（构建即加载）与复用件（loadUrl）两条路径，`isBlanked` 判定需区分 | 统一：池中空闲件一律 `isBlanked()=true`，取用后一律 `loadUrl(targetUrl)` |
| `recycledNWebs` 存储 | 需存 `key→url` 映射（`Map<string, ResourceStr>`） | 只存 key（`Set<string>`），简化 |

**实现**：`recycledNWebs` 改为 `Set<string>`（只记 key），`restoreNWebs` 遍历 key 调 `createNWeb(key, 'about:blank', uiContext)`：

```typescript
let recycledNWebs: Set<string> = new Set();

export const recycleNWeb = (key: string, force: boolean = false): boolean => {
  let baseNode = nodeMap.get(key);
  if (!baseNode || (!force && baseNode.isBound())) { return false; }
  baseNode.release();      // dispose
  baseNode.rebuild();      // 脱离绑定
  nodeMap.delete(key);
  recycledNWebs.add(key);  // 只记 key，不记 url
  return true;
}

export const restoreNWebs = (uiContext: UIContext | undefined = undefined) => {
  if (!uiContext) { uiContext = globalUiContext; }
  recycledNWebs.forEach((key: string) => {
    if (uiContext) {
      createNWeb(key, 'about:blank', uiContext);   // about:blank 重建空闲件
    }
  });
  recycledNWebs.clear();
  backgroundFlag = false;
}
```

> **配套：`getFreeWebNode` 判定改为只用 `isBlanked()`**。about:blank 重建件 `initWeb('about:blank')` 时 `blanked=true`；被 `getFreeWebNode` 取用后 `loadUrl(targetUrl)` 使 `blanked=false`（非空闲）。若沿用「key 以 about:blank 开头」判定，因 key 为唯一标识（`web_1`）不以 about:blank 开头，会漏掉该空闲件——必须只用 `isBlanked()` 判定。

---

## 完整实现方案

### 全局数据结构

```typescript
// 创建Map保存所需要的NodeController（key 为唯一标识，由 genWebKey 生成，非 url）
let nodeMap: Map<string, MyNodeController | undefined> = new Map();

// 创建保存uiContext的全局变量
let globalUiContext: UIContext | undefined = undefined;

// 保存已释放组件的 key 集合，用于回前台用 about:blank 重建空闲件
let recycledNWebs: Set<string> = new Set();

// key 计数器（生成唯一 key）
let webKeyCounter: number = 0;
```

### 生成唯一 key

```typescript
// 生成唯一 key（页面实例创建时调用，作 nodeMap 的 key）
// 避免同 url 的多页面实例共享同一组件导致绑定冲突
export const genWebKey = (): string => {
  webKeyCounter += 1;
  return 'web_' + webKeyCounter.toString();
}
```

### 创建离线Web组件

```typescript
// key 为唯一标识（genWebKey 生成），url 为目标页（构建即加载）
export const createNWeb = (key: string, url: ResourceStr, uiContext: UIContext) => {
  console.info('createNWeb, key = ' + key + ', url = ' + String(url));
  if (!globalUiContext) {
    globalUiContext = uiContext;
  }
  if (getNWeb(key)) {
    console.info('createNWeb, already exit this node, key:' + key);
    return;
  }

  // 创建NodeController
  let baseNode = new MyNodeController();
  // 初始化自定义Web组件
  baseNode.initWeb(url, uiContext);
  nodeMap.set(key, baseNode);
  // 从已释放集合中移除
  recycledNWebs.delete(key);
}
```

```typescript
// 自定义获取NodeController接口（按 key 取件）
export const getNWeb = (key: string | undefined): MyNodeController | undefined => {
  if (key === undefined) {
    return undefined;
  }
  return nodeMap.get(key);
}
```

### 释放单个离线Web组件

```typescript
export const recycleNWeb = (key: string, force: boolean = false): boolean => {
  console.info('recycleNWeb, key = ' + key);
  let baseNode = nodeMap.get(key);
  if (!baseNode) {
    console.info('no such node, key: ' + key);
    return false;
  }
  // 当离线组件没有被NodeContainer绑定时，允许安全释放
  if (!force && baseNode.isBound()) {
    console.info('the node is in bound and not force, can not delete');
    return false;
  }
  // 释放BuilderNode（dispose 封装在 release() 内，避免类外访问私有 rootNode）
  baseNode.release();
  // 触发rebuild使节点脱离绑定
  baseNode.rebuild();
  // 从Map中移除
  nodeMap.delete(key);
  // 记录已释放的 key，用于后续回前台 about:blank 重建
  recycledNWebs.add(key);
  return true;
}
```

### 释放所有离线Web组件

```typescript
export const recycleNWebs = (force: boolean = false) => {
  nodeMap.forEach((_node: MyNodeController | undefined, key: string) => {
    recycleNWeb(key, force);
  });
}
```

### 恢复离线Web组件

```typescript
// 回前台用 about:blank 重建空闲件（不按原 url 重建）
// 退后台释放后组件内容已不可信，about:blank 重建后 isBlanked()=true，
// 下次 getFreeWebNode 取用时统一走 loadUrl(targetUrl) 路径
export const restoreNWebs = (uiContext: UIContext | undefined = undefined) => {
  if (!uiContext) {
    uiContext = globalUiContext;
  }
  recycledNWebs.forEach((key: string) => {
    if (uiContext) {
      createNWeb(key, 'about:blank', uiContext);
    }
  });
  recycledNWebs.clear();
}
```

---

## 常见问题排查

### 释放后NodeContainer白屏

**现象**：释放离线Web组件后，对应的 `NodeContainer` 显示空白。

**原因**：组件在仍被 `NodeContainer` 绑定时被释放。

**解决方案**：
1. 检查 `isBound()` 返回值，确保组件未绑定时才释放。
2. 使用 `force: true` 释放会导致白屏，仅在退后台等场景使用。
3. 释放后确保不再引用该 `NodeController`。

### 网络权限导致白屏

检查是否已在 `module.json5` 中添加网络权限：

```json5
"requestPermissions":[
  {
    "name" : "ohos.permission.INTERNET"
  }
],
```

### NodeContainer与节点绑定逻辑错误

检查节点是否已上组件树。建议在Web组件上方加上 `Text` 用于排查：

```typescript
@Builder
function WebBuilder(data: Data) {
  Column() {
    Text('test')
    Web({ src: data.url, controller: data.controller })
      .width("100%")
      .height("100%")
  }
}
```

如果白屏时 `Text` 也没有出现，说明 `NodeContainer` 与节点绑定存在问题。

### 退后台后组件未释放

**现象**：应用退后台后内存占用未降低。

**原因**：
1. `onBackground` 回调未正确注册。
2. `recycleNWebs()` 未被调用。
3. 组件仍处于绑定状态且未使用 `force: true`。

**解决方案**：
1. 确认 `UIAbility` 的 `onBackground` 中调用了 `recycleNWebs()`（非强制，仅回收空闲池组件）。
2. 不建议使用 `recycleNWebs(true)` 强制释放：会连可见页正绑定的组件一并销毁，回前台白屏/错乱（见「应用退后台/回前台后 Web 白屏或组件错乱」）。若确认退后台期间 UI 完全不可见且无可见页绑定组件，才可评估使用。

### 退后台误用复用操作替代释放操作

**现象**：应用退后台后内存占用未降低，但 `onBackground` 中看似已有释放逻辑。

**原因**：退后台时调用了复用层操作（如 `onInactive()` + `loadUrl('about:blank')`，暂停渲染、清空页面，**不释放内存**），而非释放层操作（`dispose()` + `rebuild()`，销毁节点、**释放内存**）。复用操作和释放操作的内存效果完全不同，不可互相替代。

**解决方案**：
1. 确认 `onBackground` 中调用的是 `recycleNWebs()`（内部执行 `dispose()` + `rebuild()`），而非 `onInactive()` + `loadUrl('about:blank')`。
2. 参见上方[复用与释放的职责划分](#复用与释放的职责划分)。

### 回前台后组件未恢复

**现象**：应用回到前台后Web页面显示空白。

**原因**：
1. `onForeground` 回调未调用 `restoreNWebs()`。
2. `globalUiContext` 未正确保存。
3. `recycledNWebs` 集合在释放后被意外清空。

**解决方案**：
1. 确认 `onForeground` 中调用了 `restoreNWebs()`。
2. 确认 `createNWeb` 中正确保存了 `globalUiContext`。
3. 确认 `restoreNWebs` 遍历 `recycledNWebs` 后才清空。

### 复用后页面内容不刷新

**现象**：复用离线Web组件加载新URL后，页面仍显示旧内容。

**原因**：`loadUrl` 调用时机不对，或Web组件仍处于 `Inactive` 状态。

**解决方案**：
1. 复用前先调用 `onActive()` 激活Web组件。
2. 确认复用取件经 `getFreeWebNode()` 取回空闲组件后再 `loadUrl`：新UI页面复用在 `aboutToAppear` 触发；跳转返回的恢复重载在 `onWillShow`/`onPageShow` 触发（`aboutToAppear` 对存活页面实例只触发一次，返回本页不再执行）。
3. 检查URL是否正确传入。

### 返回页面后 Web 显示空白（about:blank）

**现象**：首次进入 Web 页面正常；跳转到其他页面后返回，Web 区域白屏，实际停留在 `about:blank`。

**原因**：
1. 只实现了离开置空（`onWillHide`/`onPageHide` 加载 `about:blank`），未实现恢复重载（`onWillShow`/`onPageShow` 重新 `loadUrl` 目标页）——页面实例跳转后存活，`aboutToAppear` 只触发一次，返回时无人重载。
2. 退后台释放 → `restoreNWebs` 重建后，页面恢复显示时仍沿用释放前的旧 `NodeController` 引用（`rootNode` 已 `dispose()`）。

**解决方案**：
1. 恢复显示回调（NavDestination 用 `onWillShow`，@Entry router 页面用 `onPageShow`）中重新取回组件并 `loadUrl(currentUrl)`，目标页用状态变量记录（对照 Page2.ets 的 `currentUrl` 机制）。
2. 恢复时必须经 `getFreeWebNode()` 从池中重新取件（返回 `undefined` 时按需 `createNWeb` 兜底）；不得复用释放前的旧实例引用。
3. 离开页面的置空与延迟解绑（`setTimeout(() => { this.node = undefined }, 100)`）保持完整，扫描式取件依赖置空+解绑先行完成。

### 应用退后台/回前台后 Web 白屏或组件错乱（router 页面架构）

**现象**：`@Entry` router 页面承载 Web 时，退后台再回前台后白屏、组件取不到、或对已销毁组件调用报错。

**原因**：router 页面的 `onPageShow`/`onPageHide` **随前后台触发且与 Ability 生命周期交错**（实测顺序：退后台 `onBackground → onPageHide`；回前台 `onPageShow → onForeground`）：

1. 退后台用了 `recycleNWebs(true)` 强制回收 → 可见页组件被销毁 → 回前台 `onPageShow` 先执行时池是空的（`restoreNWebs` 在 `onForeground` 才跑）→ 取不到组件白屏。
2. `onPageHide` 在 `onBackground` **之后**执行 → 对已被回收的组件 `loadUrl('about:blank')`/延迟解绑乱序。
3. 回前台 `onPageShow` 重入触发 `loadUrl` 整页重载（内容本就完好，被无谓刷新）。

**解决方案**（router 架构三件套，均已真机验证）：

1. `onBackground` 改用非强制 `recycleNWebs()`（默认值）：仅回收空闲池组件，可见页组件存活不回收——回前台内容原样保留。
2. 组件池内置前后台标志（`recycleNWebs` 置位 / `restoreNWebs` 复位），页面 `onPageHide` 检测到后台引起的 hide 时**跳过置空解绑**（内容与绑定不动）。
3. `loadUrl` 加「已在显示目标页」跳过守卫（`targetUrl` 相同且 `getUrl()` 非 about:blank 前缀则跳过），防回前台重入整页重载；`onPageShow` 取件为空时 `createNWeb` 按需播种兜底。

**根治方案**：迁移到 Navigation/NavDestination——`onWillShow`/`onWillHide` 为纯导航事件，不随前后台触发，上述三件套守卫全部不再需要（仅保留非强制 `recycleNWebs()` 即可）。

## 核心约束

- **复用与释放是两个不同操作层次，不可互相替代**：复用（`loadUrl('about:blank')`）不释放内存（组件存活、内容清空），释放（`dispose()` + `rebuild()`）才释放内存（组件销毁）。退后台必须走释放链路，不得用复用操作替代释放操作。
- **页面跳转只复用、不释放**：离开Web页面（`onWillHide`）时只能调用 `loadUrl('about:blank')` 加载空页面为复用做准备，**禁止调用 `dispose()` + `rebuild()` 释放组件**。反复创建销毁的性能与内存开销远大于复用。
- **退后台才释放**：释放离线Web组件（`dispose()` + `rebuild()`）仅应在应用退后台（`UIAbility.onBackground`）时由 `recycleNWebs()` 统一触发，退后台后组件从 `nodeMap` 移除并记入 `recycledNWebs`（只记 key），回前台时由 `restoreNWebs()` 恢复。
- **回前台用 about:blank 重建空闲件（不按原 url 重建）**：`restoreNWebs` 遍历 `recycledNWebs` 的 key 调 `createNWeb(key, 'about:blank', uiContext)` 创建空白件回池，**不按原 url 重建**。退后台释放后组件内容已不可信（登录态/SPA 状态丢失、网络 url 加载失败），回前台直接加载原 url 可能失败/状态过期；about:blank 重建后 `isBlanked()=true`，下次 `getFreeWebNode` 取用统一走 `loadUrl(targetUrl)` 路径，复用更可靠。`recycledNWebs` 只存 key（`Set<string>`），无需存 url。
- **退后台释放必须用非强制 `recycleNWebs()`（默认 `force=false`，仅回收空闲池未绑定组件）**：可见页正绑定的组件存活不回收，回前台内容原样保留；禁止 `force=true` 强制释放（连可见组件一起销毁，回前台白屏）。
- **承载页面优先 Navigation/NavDestination**：`onWillShow`/`onWillHide` 为纯导航事件、不随应用前后台触发，复用时机语义干净。`@Entry` router 页面的 `onPageShow`/`onPageHide` 随前后台触发且与 Ability 生命周期交错（退后台 `onBackground → onPageHide`、回前台 `onPageShow → onForeground`），继续使用须补齐三件套守卫（非强制回收 / 后台跳过置空 / 重入跳过重载，见常见问题排查）。
- 仅当离线Web组件未绑定到UI页面（`isBound()` 返回 `false`）时，才能安全释放该组件，否则可能导致 `NodeContainer` 组件显示空白。
- 释放离线Web组件前必须调用 `BuilderNode.dispose()` 并触发 `rebuild()`，确保节点正确脱离绑定。
- 复用离线Web组件时，必须先调用 `loadUrl('about:blank')` 加载空页面，为下次复用做准备。
- 页面恢复显示时（NavDestination `onWillShow` / @Entry 页面 `onPageShow`）必须重新取回离线组件并按记录的目标页 `loadUrl` 重载：页面实例在跳转后存活、`aboutToAppear` 只触发一次，离开时组件已置空 `about:blank`，不重载必现白屏。
- 复用取件必须经 `getFreeWebNode()` 扫描空闲池取未绑定组件：新UI页面复用在 `aboutToAppear` 取件并 `loadUrl` 目标页；跳转返回的恢复重载必须在恢复显示回调（NavDestination `onWillShow` / @Entry 页面 `onPageShow`）中重新取件并重载——`aboutToAppear` 对存活页面实例只触发一次，返回本页不再执行，漏掉恢复重载 Web 停留 `about:blank` 白屏。
- **组件以目标 url 直接创建（构建即加载），仅复用内容已置空的空闲件时才 loadUrl 目标页**：不要「创建空白件后立即 loadUrl」造成 about:blank → 目标页二次导航；池空时 `createNWeb(目标url)` + `getNWeb(目标url)` 取件，不 loadUrl（见[组件创建与取件模式](#组件创建与取件模式目标-url-直接创建)）。
- **nodeMap 用唯一 key（genWebKey 生成），不用 url 作 key**：同 url 的两个页面实例同时存活时，url 作 key 会导致第二个页面 `createNWeb(url)` 命中幂等检查不创建、`getNWeb(url)` 取到第一个页面已绑定组件引发冲突。key 必须由 `genWebKey()` 生成唯一标识（`web_1`/`web_2`/...），页面实例创建时 `private webKey: string = genWebKey()` 各自独立。`createNWeb(key, url, ...)` / `getNWeb(key)` / `recycleNWeb(key)` 全部按 key 操作。
- **空闲件判定只用 `isBlanked()`**：key 改为唯一标识后不携带 url 信息，「key 以 about:blank 开头」判定不再适用；`isBlanked()` 已涵盖 about:blank 创建件（`initWeb` 时按初始 url 置位）与目标 url 创建后置空回池件（`loadUrl('about:blank')` 置位）两类，单独判定即可。判定条件 = 未绑定（`isBound()` 为 false） && `isBlanked()` 为 true。空白态随 `loadUrl` 成功翻转、`initWeb` 按初始 url 初始化。
- loadUrl 前先 `waitForAttached`（取件后未挂载场景，API 20+）；其返回后 loadUrl 仍可能静默失败（引擎未就绪、无异常），可靠兜底为加载后时间维度校验重试（`getUrl()` 仍 about:blank 前缀则重载）。本地 rawfile 目标页统一用 `'resource://rawfile/<路径>'` 字符串传给 `createNWeb` 的 url 参数与 `loadUrl`（`$rawfile` 的 Resource 对象按引用比较，不能作 url 传入）。
- 退后台释放→恢复后组件为新实例，页面必须重新从池中取回，不得沿用释放前旧 `NodeController` 引用。
