# 方案四：Web 预加载分档优化

**适用场景**：应用包含 Web 页面（ArkWeb 组件），存在预加载策略但未按设备分档，或预加载导致内存占用过高。

**方案原理**：ArkWeb 提供 Web 页面加载全链路优化手段（预启动渲染进程、预解析、预连接、预下载、预渲染等）。所有优化均基于「预处理」思路，如果用户实际未打开预处理的 Web 页面，将造成额外的资源消耗。其中预创建一个空白 Web 组件约消耗 200MB 内存，预渲染消耗更多（下载+渲染+存储）。

**核心矛盾**：预加载越激进，页面打开越快，但内存占用越高。需根据设备档次平衡体验与内存。

## 效果参考（华为最佳实践数据）

| 优化方法 | 效果（优化数据仅供参考） | 内存代价 | 适配难度 |
|----------|-------------------------|----------|----------|
| 预启动 Web 渲染进程 | 消除拉起渲染进程耗时，约 140ms | ~200MB/空白组件 | 低 |
| 预解析（DNS） | 消除域名解析耗时，约 66ms | 极低 | 低 |
| 预连接（DNS+TCP） | 消除域名解析+连接耗时，约 80ms | 低 | 低 |
| 预下载 | 消除资源下载+DOM 解析阻塞，约 641ms | 网络+存储 | 低 |
| 预渲染 | 页面"秒开"，约 486ms | 网络+下载+存储+渲染 | 中 |
| 预取 POST | 消除 POST 下载+阻塞，约 313ms | 网络+存储 | 中 |
| 预编译 JS Code Cache | 消除 JS 编译耗时，5.76MB 资源约 2915ms | 存储 | 中 |
| 离线资源免拦截注入 | 25MB 资源注入约 1240ms | 存储 | 中 |

## 预加载级别定义

| 预加载级别 | 启用的优化手段 | 额外内存消耗（估） | 适用设备档次 |
|-----------|--------------|-------------------|-------------|
| none | 无预加载 | 0 | low |
| minimal | 预解析（DNS） | 极低 | low |
| standard | 预解析 + 预连接 | 低 | medium |
| enhanced | 预解析 + 预连接 + 预下载 | 中等 | medium |
| aggressive | 预启动渲染进程 + 预连接 + 预下载 + 预渲染 | 高（~200MB+） | high |

## 设备分档映射

| 设备分档 | 首页 Web 预加载级别 | 非首页预加载级别 | 说明 |
|---------|--------------------|----------------|------|
| low | minimal | none | 低内存设备仅做 DNS 预解析，避免内存压力 |
| medium | standard | minimal | 中端设备首页预连接，内页仅预解析 |
| high | enhanced / aggressive | standard | 高端设备可预下载甚至预渲染首页 |

## 代码修改模板

### 1. 预加载策略配置类（WebPreloadConfig.ets）

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// WebPreloadConfig.ets
import { DeviceLevelDecisionCenter, DeviceLevel } from './DeviceLevelDecisionCenter';

export class WebPreloadLevel {
  static readonly NONE: string = 'none';         // 无预加载
  static readonly MINIMAL: string = 'minimal';   // 仅预解析
  static readonly STANDARD: string = 'standard'; // 预解析 + 预连接
  static readonly ENHANCED: string = 'enhanced'; // 预解析 + 预连接 + 预下载
  static readonly AGGRESSIVE: string = 'aggressive'; // 预启动 + 预连接 + 预下载 + 预渲染
}

export class WebPreloadConfig {
  /**
   * 获取首页 Web 预加载级别
   * 首页高概率访问，可使用更激进的预加载策略
   */
  static getHomePagePreloadLevel(): string {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      return WebPreloadLevel.MINIMAL;
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      return WebPreloadLevel.STANDARD;
    }
    return WebPreloadLevel.ENHANCED;
  }

  /**
   * 获取非首页 Web 预加载级别
   * 非首页访问概率不确定，策略更保守
   */
  static getSubPagePreloadLevel(): string {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      return WebPreloadLevel.NONE;
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      return WebPreloadLevel.MINIMAL;
    }
    return WebPreloadLevel.STANDARD;
  }

  /**
   * 是否允许预启动 Web 渲染进程
   * 预创建空白 Web 组件约消耗 200MB 内存，仅高端设备允许
   */
  static shouldPreStartRenderProcess(): boolean {
    return DeviceLevelDecisionCenter.getDeviceLevel() === DeviceLevel.TIER_HIGH;
  }

  /**
   * 是否允许预渲染
   * 预渲染消耗最大（下载+渲染+存储），仅高端设备+超高概率页面
   */
  static shouldPreRender(): boolean {
    return DeviceLevelDecisionCenter.getDeviceLevel() === DeviceLevel.TIER_HIGH;
  }

  /**
   * 预下载最大资源大小限制 (KB)
   */
  static getPreDownloadMaxSize(): number {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      return 0; // 低端设备不预下载
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      return 512; // 中端限 512KB
    }
    return 2048; // 高端限 2MB
  }
}
```

### 2. 在 Ability 中初始化预加载

```typescript
// EntryAbility.ets
import { webview } from '@kit.ArkWeb';
import { WebPreloadConfig, WebPreloadLevel } from '../utils/WebPreloadConfig';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 初始化 Web 内核（轻量，不创建组件）
    webview.WebviewController.initializeWebEngine();

    // 根据分档策略执行首页预加载
    let homePreloadLevel: string = WebPreloadConfig.getHomePagePreloadLevel();
    let homeUrl: string = 'https://www.example.com/';

    if (homePreloadLevel === WebPreloadLevel.MINIMAL) {
      // 仅预解析 DNS（第二个参数 false = 只预解析不预连接）
      webview.WebviewController.prepareForPageLoad(homeUrl, false, 1);
    } else if (homePreloadLevel === WebPreloadLevel.STANDARD) {
      // 预解析 + 预连接（第二个参数 true = 预连接）
      webview.WebviewController.prepareForPageLoad(homeUrl, true, 2);
    } else if (homePreloadLevel === WebPreloadLevel.ENHANCED
      || homePreloadLevel === WebPreloadLevel.AGGRESSIVE) {
      // 预解析 + 预连接（多 socket）
      webview.WebviewController.prepareForPageLoad(homeUrl, true, 4);
    }
    // NONE 级别不做任何操作
  }
}
```

### 3. 在 Web 页面组件中按级别预下载

```typescript
// WebPage.ets
import { webview } from '@kit.ArkWeb';
import { WebPreloadConfig, WebPreloadLevel } from '../utils/WebPreloadConfig';

@Component
export struct WebPage {
  controller: webview.WebviewController = new webview.WebviewController();
  @State preloadLevel: string = WebPreloadLevel.NONE;

  aboutToAppear(): void {
    this.preloadLevel = WebPreloadConfig.getSubPagePreloadLevel();
  }

  build() {
    Column() {
      Web({ src: 'https://www.example.com/', controller: this.controller })
        .onPageEnd(() => {
          // 页面加载完成后，根据分档决定是否预下载下一页
          if (this.preloadLevel === WebPreloadLevel.ENHANCED
            || this.preloadLevel === WebPreloadLevel.AGGRESSIVE) {
            let maxSize: number = WebPreloadConfig.getPreDownloadMaxSize();
            this.controller.prefetchPage('https://www.example.com/next-page');
          } else if (this.preloadLevel === WebPreloadLevel.STANDARD) {
            // 仅预连接下一页
            webview.WebviewController.prepareForPageLoad(
              'https://www.example.com/next-page', true, 2);
          } else if (this.preloadLevel === WebPreloadLevel.MINIMAL) {
            // 仅预解析
            webview.WebviewController.prepareForPageLoad(
              'https://www.example.com/next-page', false, 1);
          }
        })
    }
  }
}
```

### 4. 预启动渲染进程（仅高端设备）

```typescript
// 仅高端设备预创建空白 Web 组件
import { WebPreloadConfig } from '../utils/WebPreloadConfig';

// 在 EntryAbility.onWindowStageCreate 中
if (WebPreloadConfig.shouldPreStartRenderProcess()) {
  // 创建空白 Web 组件预启动渲染进程
  createNWeb('about:blank', windowStage.getMainWindowSync().getUIContext());
}
// 中低端设备跳过，节省 ~200MB 内存
```

## 配套最佳实践：Web 引擎延迟初始化

### 问题场景

应用启动时可能需要读取 Cookie（如登录态检查），传统方式需要先初始化 ArkWeb 引擎（50-100MB），仅为了获取 Cookie 就占用大量内存。

### 解决方案：CookieManager + setLazyInitializeWebEngine

**1. 使用 WebCookieManager 无需初始化引擎即可获取 Cookie：**

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
import { webview } from '@kit.ArkWeb';

// 直接获取 Cookie，无需初始化 Web 引擎（内存占用 < 1MB vs 传统 50-100MB）
let cookies: string = await webview.WebCookieManager.getCookie('https://www.example.com/');
```

**2. Web 组件设置延迟初始化，按需加载引擎：**

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
Web({ src: 'https://www.example.com/', controller: this.controller })
  .setLazyInitializeWebEngine(true)  // 延迟初始化，组件可见时才加载引擎
```

### 效果参考

| 操作 | 传统模式 | 延迟初始化 | 节省 |
|------|---------|-----------|------|
| Cookie 获取 | 50-100MB（需引擎） | < 1MB（CookieManager） | 98.9% |
| 首次 Web 加载 | 立即初始化 50-100MB | 按需初始化 0MB | 到需要时才占内存 |
| 应用启动时间 | +500-800ms | +50-100ms | 显著缩短 |

### 设备分档策略

| 设备分档 | Cookie 获取方式 | Web 引擎初始化 | 说明 |
|---------|---------------|-------------|------|
| low | CookieManager（不初始化引擎） | 延迟初始化 + 用户点击时才加载 | 最大限度节省内存 |
| medium | CookieManager（不初始化引擎） | 延迟初始化 + 首页按需加载 | 平衡体验与内存 |
| high | CookieManager（不初始化引擎） | 可预启动渲染进程 | 充分利用内存 |

### 在 Ability 中配合使用

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// EntryAbility.ets
import { webview } from '@kit.ArkWeb';

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    // 1. 使用 CookieManager 获取登录态，不初始化引擎
    let cookies: string = await webview.WebCookieManager.getCookie('https://www.example.com/');
    // 解析 Cookie 判断登录态...

    // 2. 不再调用 webview.WebviewController.initializeWebEngine()
    //    引擎将在 Web 组件首次可见时自动初始化（setLazyInitializeWebEngine(true)）
  }
}
```

## C-API 代码修改模板（NDK 接口）

> **说明**：Web 组件（ArkWeb）的预加载策略（预连接、预下载、预渲染等）主要通过 ArkTS API（`webview.WebviewController`）控制。C-API 主要用于在 NDK 层面创建和管理 Web 节点。预加载分档的**策略配置逻辑**应保持 ArkTS 实现，C-API 侧重于 Web 组件节点的创建和销毁管理。

### 核心概念对照

| ArkTS 概念 | C-API 对应 | 说明 |
|-----------|-----------|------|
| `Web({ src: url, controller })` | `ARKUI_NODE_WEB` | Web 组件 |
| `.width(N)` / `.height(N)` | `NODE_WIDTH` / `NODE_HEIGHT` | 尺寸 |
| `webview.WebviewController` | ArkTS 侧管理 | 控制器仍在 ArkTS 层 |
| `controller.prepareForPageLoad()` | ArkTS API 调用 | 预加载策略保持 ArkTS |

### 1. 创建 Web 节点（C-API）

```cpp
// WebNodeHelper.h
// C-API 创建 Web 节点

#include <arkui/native_node.h>
#include <arkui/native_interface.h>

ArkUI_NodeHandle CreateWebNode(
    ArkUI_NativeNodeAPI_1 *nodeApi,
    float width, float height
) {
    auto webNode = nodeApi->createNode(ARKUI_NODE_WEB);

    // 设置尺寸
    ArkUI_NumberValue wVal[] = {{.f32 = width}};
    ArkUI_AttributeItem wItem = {wVal, 1};
    nodeApi->setAttribute(webNode, NODE_WIDTH, &wItem);

    ArkUI_NumberValue hVal[] = {{.f32 = height}};
    ArkUI_AttributeItem hItem = {hVal, 1};
    nodeApi->setAttribute(webNode, NODE_HEIGHT, &hItem);

    return webNode;
}
```

### 2. Web 节点按需创建和销毁（C-API）

```cpp
// 按 WebPreloadConfig 分档策略控制 Web 节点的创建和销毁
// 低端设备：不预创建，仅在用户点击时创建
// 高端设备：可预创建空白 Web 节点

class WebNodeManager {
public:
    WebNodeManager(ArkUI_NativeNodeAPI_1 *nodeApi) : nodeApi_(nodeApi) {}

    // 创建并挂载 Web 节点（用户点击时）
    ArkUI_NodeHandle CreateAndMount(ArkUI_NodeHandle parent) {
        if (webNode_ != nullptr) {
            return webNode_; // 已存在
        }
        webNode_ = CreateWebNode(nodeApi_, 400, 600);
        nodeApi_->addChild(parent, webNode_);
        return webNode_;
    }

    // 销毁 Web 节点（释放 ~200MB 内存）
    void Destroy(ArkUI_NodeHandle parent) {
        if (webNode_ != nullptr) {
            nodeApi_->removeChild(parent, webNode_);
            nodeApi_->disposeNode(webNode_);
            webNode_ = nullptr;
        }
    }

private:
    ArkUI_NativeNodeAPI_1 *nodeApi_ = nullptr;
    ArkUI_NodeHandle webNode_ = nullptr;
};
```

### 3. 预加载策略调用（跨语言方式）

```cpp
// 预加载策略（prepareForPageLoad 等）仍通过 ArkTS API 调用
// C-API 通过 NAPI 调用 ArkTS 层的预加载配置

// 方式一：在 ArkTS 侧统一管理预加载策略（推荐）
// 方式二：通过 NAPI 跨语言调用
// napi_value result = nullptr;
// napi_call_function(env, global, preloadFunc, argc, args, &result);
```

### C-API 注意事项

- **Web 预加载策略**（预连接、预下载、预渲染）的 API 均在 `@kit.ArkWeb` 模块中，C-API 没有直接等价接口
- **推荐做法**：预加载分档策略在 ArkTS 层实现（`WebPreloadConfig.ets`），C-API 只负责 Web 节点的创建/销毁管理
- Web 节点的 `disposeNode` 会释放该节点占用的资源，等价于将 Web 组件从组件树中移除

## 注意事项

- 预启动渲染进程（`createNWeb('about:blank')`）消耗约 200MB，仅高端设备允许
- 预渲染消耗最大（下载+渲染+存储），需评估目标页面访问概率
- 预连接有时效性（5分钟），预下载缓存时效也为 5 分钟
- 预加载代码应集中在 Ability.onCreate / onWindowStageCreate 和 Web 组件的 onPageEnd 回调中
- `setLazyInitializeWebEngine(true)` 仅延迟引擎初始化，不影响 Web 组件的创建和布局
- 使用 CookieManager 获取 Cookie 不需要任何 Web 组件或引擎初始化
- 低端设备强烈建议使用延迟初始化 + CookieManager，避免应用启动即占用 50-100MB
- 设备分档机制详见 [device_level_tiering.md](./device_level_tiering.md)
