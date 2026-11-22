# 离线组件预加载个数优化指南

## 目录

1. [优化概述](#优化概述)
2. [预加载个数分级策略](#预加载个数分级策略)
3. [限制预创建个数实现](#限制预创建个数实现)
4. [常见问题排查](#常见问题排查)

---

## 优化概述

每个离线 Web 组件大约占用 200MB 内存。如果应用一次性创建多个离线组件进行预渲染，内存占用会成倍增长，尤其是在小程序场景下，多个小程序会加剧内存的占用。本方案根据设备能力分级限制预创建离线组件的个数：低端机不创建离线组件，高端机最多创建 1-2 个，避免预创建过多组件导致内存占用过高。

### 适用与不适用场景

| 场景 | 是否适用 |
| --- | --- |
| 应用预创建多个离线组件导致内存占用过高 | 适用 |
| 需要根据设备能力分级控制预创建数量 | 适用 |
| 应用只创建单个离线组件且设备性能充足 | 不适用 |
| 不涉及离线 Web 组件预渲染 | 不适用 |

---

## 预加载个数分级策略

### 分级规则

| 设备能力 | 预创建个数 | 说明 |
| --- | --- | --- |
| 高端机（HIGH） | 1-2 个 | 预创建高频使用的页面组件 |
| 中端机（MEDIUM） | 1 个 | 仅预创建命中率最高的页面组件 |
| 低端机（LOW） | 0 个 | 不预创建，进入页面时按需创建 |

### 选择预创建目标的原则

当预创建个数有限时，应优先预创建命中率高、使用频繁的页面：

1. **首页跳转的子页面**：用户进入首页后大概率会访问的小程序页面或其他web页面。
2. **高频访问的功能页**：根据埋点数据选择访问频次最高的页面。
3. **避免低命中页面预创建**：访问概率低的页面不预创建。

---

## 限制预创建个数实现

### 核心原理

1. 使用 `deviceInfo.performanceClass`（API 19+）获取设备能力分级
2. 根据分级确定最大预创建个数
3. 通过 `Map`（`nodeMap`）管理离线组件，**`nodeMap` 只持有空闲（未绑定）的预创建组件**——已绑定到 `NodeContainer` 正在显示的组件在 `onBind` 时从 `nodeMap` 中删除
4. `createNWeb` 创建前检查 `nodeMap.size >= maxPreloadCount`，达到上限则不再创建
5. `onBind`：组件被 `NodeContainer` 绑定（正在使用），从 `nodeMap` 中删除，不再占预创建名额
6. `onUnbind`：组件从 `NodeContainer` 解绑，检查 `nodeMap.size < maxPreloadCount`：未满则重新注册回池（供下次复用），已满则 `dispose` 释放内存
7. `NWebManager` 采用单例模式，确保全局只有一个离线组件管理器实例，统一管理预创建个数和组件生命周期

> **高发失误警告**：预创建上限检查不得用包含已绑定组件的 `nodeMap.size`——如果 `onBind` 时不从 `nodeMap` 中删除，则 `nodeMap.size` 包含了已绑定到页面正在显示的组件，用户进入 Web 页后绑定组件占名额、后续预创建被误拦。正确做法是 `onBind` 删除 / `onUnbind` 重新注册（见下方 [onBind 删除 / onUnbind 重新注册](#onbind-删除--onunbind-重新注册)）。

### 设备能力与预创建个数映射

```typescript
import { deviceInfo } from '@kit.BasicServicesKit';

// 根据设备能力获取最大预创建离线组件个数
function getMaxPreloadCount(): number {
  if (deviceInfo.performanceClass !== undefined) {
    switch (deviceInfo.performanceClass) {
      case deviceInfo.PerformanceClassLevel.CLASS_LEVEL_HIGH:
        return 2; // 高端机：最多预创建2个
      case deviceInfo.PerformanceClassLevel.CLASS_LEVEL_MEDIUM:
        return 1; // 中端机：最多预创建1个
      case deviceInfo.PerformanceClassLevel.CLASS_LEVEL_LOW:
        return 0; // 低端机：不预创建
      default:
        return 0;
    }
  }
  // 低版本回退：保守起见不预创建
  return 0;
}
```

### 限制预创建个数的离线组件管理（单例模式）

`NWebManager` 采用单例模式，确保全局只有一个管理器实例，统一管理离线组件的预创建个数上限和组件生命周期。通过 `NWebManager.getInstance()` 获取单例实例，所有 API 均通过该实例调用。

```typescript
import { deviceInfo } from '@kit.BasicServicesKit';
import { NodeController, UIContext } from '@kit.ArkUI';

// 离线组件管理器（单例），限制预创建个数
class NWebManager {
  private static instance: NWebManager | null = null;
  // nodeMap 只持有空闲（未绑定）的预创建组件；已绑定的在 onBind 时删除
  private nodeMap: Map<string, MyNodeController> = new Map();
  private maxPreloadCount: number = 0;

  // 私有构造函数，禁止外部直接 new
  private constructor() {
    this.maxPreloadCount = this.getMaxPreloadCount();
  }

  // 获取单例实例
  static getInstance(): NWebManager {
    if (NWebManager.instance === null) {
      NWebManager.instance = new NWebManager();
    }
    return NWebManager.instance;
  }

  private getMaxPreloadCount(): number {
    if (deviceInfo.performanceClass !== undefined) {
      switch (deviceInfo.performanceClass) {
        case deviceInfo.PerformanceClassLevel.CLASS_LEVEL_HIGH:
          return 2;
        case deviceInfo.PerformanceClassLevel.CLASS_LEVEL_MEDIUM:
          return 1;
        case deviceInfo.PerformanceClassLevel.CLASS_LEVEL_LOW:
          return 0;
        default:
          return 0;
      }
    }
    return 0;
  }

  // 创建离线组件（受预创建个数限制）
  createNWeb(url: string, uiContext: UIContext): boolean {
    // 已存在则直接返回
    if (this.nodeMap.has(url)) {
      return true;
    }
    // nodeMap 只持有空闲组件，size 即空闲预创建数
    if (this.nodeMap.size >= this.maxPreloadCount) {
      console.info('preload count limit reached: ' + this.maxPreloadCount + ', current: ' + this.nodeMap.size);
      return false;
    }
    // 创建离线Web组件并加入管理
    let controller = new MyNodeController(url, uiContext);
    controller.setMapKey(url);
    this.nodeMap.set(url, controller);
    console.info('create offline web, pool size: ' + this.nodeMap.size);
    return true;
  }

  // onBind 时调用：从 nodeMap 中删除（组件正在使用，不再占预创建名额）
  onBindNode(key: string): void {
    this.nodeMap.delete(key);
    console.info('onBind: removed from pool, key=' + key + ', pool size=' + this.nodeMap.size);
  }

  // onUnbind 时调用：检查池是否需要补充，未满则重新注册，已满则释放
  onUnbindNode(controller: MyNodeController, key: string): void {
    if (this.nodeMap.size < this.maxPreloadCount) {
      // 预创建池未满，重新注册回池
      this.nodeMap.set(key, controller);
      console.info('onUnbind: re-registered to pool, key=' + key + ', pool size=' + this.nodeMap.size);
    } else {
      // 预创建池已满，释放该组件
      controller.disposeNode();
      console.info('onUnbind: pool full, disposed, key=' + key);
    }
  }

  getNWeb(url: string): MyNodeController | undefined {
    return this.nodeMap.get(url);
  }

  // 释放所有离线组件
  recycleAll(): void {
    this.nodeMap.clear();
  }
}
```

### onBind 删除 / onUnbind 重新注册

> **高发失误**：预创建上限检查用 `nodeMap.size` 但 `onBind` 时不从 `nodeMap` 中删除。组件被 `NodeContainer` 绑定后仍在 `nodeMap` 中，`nodeMap.size` 包含了已绑定到页面正在显示的组件，用户进入 Web 页后绑定组件占名额、后续预创建被误拦。

**正确做法**：`nodeMap` 只持有空闲（未绑定）的预创建组件。通过 `MyNodeController` 的 `onBind` / `onUnbind` 回调维护池：

- `onBind`：组件被 `NodeContainer` 绑定（正在使用），**从 `nodeMap` 中删除**，不再占预创建名额。
- `onUnbind`：组件从 `NodeContainer` 解绑，**检查 `nodeMap.size < maxPreloadCount`**：未满则**重新注册**回池（供下次复用），已满则 `dispose` 释放内存。

```typescript
export class MyNodeController extends NodeController {
  private rootNode: BuilderNode<[WebData]> | null = null;
  private mapKey: string | null = null;

  setMapKey(key: string): void {
    this.mapKey = key;
  }

  makeNode(uiContext: UIContext): FrameNode | null {
    return this.rootNode?.getFrameNode() ?? null;
  }

  // 组件被 NodeContainer 绑定（正在使用），从预创建池中删除
  onBind(_containerId: number): void {
    if (this.mapKey !== null) {
      NWebManager.getInstance().onBindNode(this.mapKey);
    }
  }

  // 组件从 NodeContainer 解绑，检查池是否需要补充
  onUnbind(_containerId: number): void {
    if (this.mapKey !== null) {
      NWebManager.getInstance().onUnbindNode(this, this.mapKey);
    }
  }

  disposeNode(): void {
    this.rootNode?.dispose();
    this.rootNode = null;
  }
}
```

> `onBind` / `onUnbind` 的 API 签名为 `(containerId: number)`（API 26+）。早期文档示例的 `(detached: FrameNode)` 已过时，照抄编译失败。

### 在 EntryAbility 中按个数限制预创建

通过 `NWebManager.getInstance()` 获取单例实例，在 `onWindowStageCreate` 中按个数限制预创建离线组件：

```typescript
import { NWebManager } from '../pages/Common';
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err && err.code) {
        return;
      }
      let windowClass: window.Window = windowStage.getMainWindowSync();
      if (!windowClass) {
        return;
      }
      let uiContext = windowClass.getUIContext();
      // 通过单例获取管理器实例
      let manager = NWebManager.getInstance();
      // 高端机预创建高频页面（受个数限制），低端机不预创建
      // 仅当 createNWeb 返回 true 时才会创建
      manager.createNWeb('https://xxx/main', uiContext);
      manager.createNWeb('https://xxx/detail', uiContext);
    });
  }
}
```

### 低端机进入页面时按需创建

低端机不预创建离线组件，进入页面时再创建 Web 组件。通过 `NWebManager.getInstance()` 获取单例实例，调用 `getNWeb()` 获取预创建的离线组件，未获取到时按需创建：

```typescript
import { NWebManager } from '../pages/Common';

@Entry
@Component
struct WebPage {
  private controller: webview.WebviewController = new webview.WebviewController();
  @State url: string = 'https://xxx';

  build() {
    Column() {
      // 通过单例获取管理器实例
      // 高端机：getNWeb 返回预创建的离线组件
      // 低端机：getNWeb 返回 undefined，进入页面时直接创建Web组件加载
      NodeContainer(NWebManager.getInstance().getNWeb(this.url) ?? new MyNodeController(this.url, this.getUIContext()))
        .height('90%')
        .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}

---

## 常见问题排查

### 预创建个数过多导致内存占用过高

**现象**：应用启动后内存占用远超预期。

**原因**：未限制预创建个数，或 `maxPreloadCount` 计算结果不符合预期。

**解决方案**：
1. 检查 `getMaxPreloadCount()` 返回值，确认低端机返回 0。
2. 在 `NWebManager.getInstance().createNWeb()` 中确认上限检查逻辑生效。
3. 通过 `hidebug.getPss()` 观察创建前后内存变化，每个 Web 组件约 200MB。

### 低端机仍预创建离线组件

**现象**：低端机启动后仍创建了离线组件。

**原因**：`deviceInfo.performanceClass` 在低版本 API（< 19）不可用，回退策略未设置为 0。

**解决方案**：
1. 确认设备 API 版本 >= 19。
2. 低版本回退策略应默认 `maxPreloadCount = 0`，不预创建。
3. 拿不准设备能力时，按低端机保守处理。

## 核心约束

- 每个窗口推荐只使用一个 Web 组件，避免一次性创建大量离线 Web 组件。
- 创建 Web 组件将占用内存（每个 Web 组件大约 200MB）和计算资源，必须按需创建和释放。
- 必须根据设备能力分级（`deviceInfo.performanceClass`）决定是否预先创建离线组件，低端机不预先创建，进入页面时按需创建 Web 组件加载。
- 预创建离线组件个数必须受设备能力分级限制：低端机不创建，中端机最多 1 个，高端机最多 1-2 个。
- **`nodeMap` 只持有空闲（未绑定）的预创建组件**：已绑定到 `NodeContainer` 正在显示的组件在 `onBind` 时从 `nodeMap` 中删除，不占预创建名额。`createNWeb` 的上限检查用 `nodeMap.size`（即空闲组件数），无需额外遍历。
- **`onBind` 删除**：组件被 `NodeContainer` 绑定（正在使用）时，必须从 `nodeMap` 中删除，使 `nodeMap.size` 准确反映空闲预创建数。
- **`onUnbind` 重新注册**：组件从 `NodeContainer` 解绑时，必须检查 `nodeMap.size < maxPreloadCount`：未满则重新注册回池（供下次复用），已满则 `dispose` 释放内存。
- `MyNodeController` 须持有 `mapKey` 字段记录自身在 `nodeMap` 中的键，供 `onBind`/`onUnbind` 删除/重新注册使用。`onBind`/`onUnbind` 的 API 签名为 `(containerId: number)`。