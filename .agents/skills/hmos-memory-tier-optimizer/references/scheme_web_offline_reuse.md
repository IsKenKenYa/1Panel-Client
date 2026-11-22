# 方案十：Web 离线组件分档复用与释放优化

## 来源

基于华为 HarmonyOS 指南「使用离线Web组件」：
https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-offline-mode#%E6%95%B4%E4%BD%93%E6%9E%B6%E6%9E%84

文档说明：离线 Web 组件基于 `NodeContainer` 和 `NodeController` 实现，创建后不会立即挂载到组件树中，状态为 Hidden 和 Inactive；创建 Web 组件会占用内存和计算资源，官方提示每个 Web 组件大约 200MB，建议避免一次性创建大量离线 Web 组件，并通过复用和释放离线 Web 组件优化内存占用。

## 适用场景

- 项目使用离线 Web 组件：`NodeContainer`、`NodeController`、`BuilderNode`、`createNWeb`、`getNWeb`。
- 页面使用 Web 预启动渲染进程或预渲染 Web 页面。
- 存在多个离线 Web 组件、全局 `nodeMap` / `controllerMap` 持续增长，或应用后台后仍保留离线 Web。
- native heap、PSS 或 ArkWeb 相关进程内存偏高。

## 优化目标

1. 减少离线 Web 组件总数，默认遵循每个窗口只保留一个 Web 组件。
2. 复用空闲离线 Web 组件，避免重复创建多个 Web 组件造成额外内存开销。
3. 在应用退后台、页面隐藏或一段时间内不再需要 Web 时释放离线 Web 组件。
4. 按设备分档控制离线组件数量、预渲染范围和释放时机。

## 分档策略

| 设备分档 | 离线 Web 数量 | 预渲染策略 | 释放策略 |
|----------|---------------|------------|----------|
| low | 0-1 个，仅保留当前窗口必要 Web | 默认不预渲染，仅按需加载 | 页面隐藏或应用退后台立即释放未绑定组件 |
| medium | 每窗口 1 个可复用离线 Web | 仅预渲染首屏关键页面 | 应用退后台释放，页面切换时复用空闲组件 |
| high | 每窗口 1 个，允许短时间保留 1 个候选预渲染组件 | 可预渲染关键跳转页面 | 空闲超时、内存压力或退后台释放候选组件 |

> 高端机的候选预渲染组件只能作为短生命周期优化，不能让离线 Web 池无限增长。

## 检测规则

### 关键词

| 关键词 | 用途 |
|--------|------|
| `NodeContainer` | 定位离线 Web 挂载容器 |
| `NodeController` | 定位离线 Web 控制器 |
| `BuilderNode` | 定位命令式创建组件 |
| `createNWeb` | 定位离线 Web 创建入口 |
| `getNWeb` | 定位离线 Web 复用入口 |
| `nodeMap`, `controllerMap` | 检查离线组件缓存是否有上限 |
| `loadUrl('about:blank')` | 判断是否复用前清空旧页面 |
| `recycleNWeb`, `recycleNWebs` | 判断是否有释放接口 |
| `dispose`, `rebuild`, `delete` | 判断是否释放节点并更新容器 |
| `onBackground`, `onForeground`, `onWillHide` | 判断生命周期释放和恢复路径 |
| `onBind`, `onUnbind`, `isBound` | 判断释放前是否检查绑定状态 |

### 告警条件

满足以下任一组时输出 High 级别告警：

- 存在 `createNWeb` / `BuilderNode` 创建离线 Web，但没有设备分档或数量上限。
- `nodeMap` / `controllerMap` 只增不减，缺少 `recycleNWeb`、`dispose`、`rebuild` 或 `delete`。
- 多个页面各自创建离线 Web，没有复用空闲组件或 `loadUrl('about:blank')` 清空旧页面。
- 应用 `onBackground`、页面 `onWillHide` 或长时间不需要 Web 时没有释放未绑定离线组件。
- 释放逻辑未检查 `onBind` / `onUnbind` / `isBound` 状态，存在已绑定组件被释放导致白屏的风险。

## ArkTS 修改模板

```ts
import { UIContext, NodeController } from '@kit.ArkUI';

type DeviceLevel = 'low' | 'medium' | 'high';

const offlineWebLimit: Record<DeviceLevel, number> = {
  low: 1,
  medium: 1,
  high: 2
};

let nodeMap: Map<ResourceStr, MyNodeController> = new Map();
let recycledNWebs: Set<ResourceStr> = new Set();

function canCreateOfflineWeb(level: DeviceLevel): boolean {
  return nodeMap.size < offlineWebLimit[level];
}

export function createTieredNWeb(url: ResourceStr, uiContext: UIContext, level: DeviceLevel): boolean {
  if (nodeMap.has(url)) {
    return true;
  }
  if (!canCreateOfflineWeb(level)) {
    return false;
  }

  const node = new MyNodeController();
  node.initWeb(url, uiContext);
  nodeMap.set(url, node);
  recycledNWebs.delete(url);
  return true;
}

export function reuseNWeb(oldUrl: ResourceStr, nextUrl: ResourceStr): MyNodeController | undefined {
  const node = nodeMap.get(oldUrl);
  if (!node) {
    return undefined;
  }

  node.getController()?.loadUrl('about:blank');
  node.getController()?.loadUrl(nextUrl.toString());
  nodeMap.delete(oldUrl);
  nodeMap.set(nextUrl, node);
  return node;
}

export function recycleNWeb(url: ResourceStr, force: boolean = false): boolean {
  const node = nodeMap.get(url);
  if (!node) {
    return false;
  }
  if (!force && node.isBound()) {
    return false;
  }

  node.rootNode?.dispose();
  node.rebuild();
  nodeMap.delete(url);
  recycledNWebs.add(url);
  return true;
}

export function recycleIdleNWebs(force: boolean = false): void {
  nodeMap.forEach((_node, url) => {
    recycleNWeb(url, force);
  });
}
```

## 生命周期接入

```ts
onBackground(): void {
  recycleIdleNWebs();
}

onForeground(): void {
  // 仅恢复业务确定仍需要的离线 Web，不做全量恢复。
}
```

页面切换时优先复用空闲离线 Web：旧页面隐藏时先加载 `about:blank`，取消与当前 UI 的关联；新页面展示时再加载目标 URL。释放前必须确认离线 Web 未绑定到 UI 页面，否则可能导致 `NodeContainer` 白屏。

## 验证方式

1. 全仓扫描 `createNWeb`、`NodeContainer`、`nodeMap`，统计离线 Web 创建数量和缓存上限。
2. 检查是否存在 `recycleNWeb` / `recycleNWebs`，以及 `dispose`、`rebuild`、`delete` 释放链路。
3. 检查 `onBackground`、`onWillHide`、内存压力回调是否触发释放未绑定离线 Web。
4. 优化前后采集 meminfo，对比 native heap、PSS 总量和 ArkWeb 相关进程内存。
5. 回归页面跳转、复用、退后台再切前台场景，确认无白屏。

## 注意事项

- 不要为了演示效果在生产逻辑中长期保留多个离线 Web 组件。
- `force` 释放仅用于明确可接受重建的场景，默认释放必须检查绑定状态。
- 本方案可与 `scheme_web_preload.md` 和 `scheme_web_on_active.md` 同时使用：先控制离线 Web 数量，再处理预加载分档和预渲染后的活跃状态。
