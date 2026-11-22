# LazyForEach 内存优化策略指南

## 目录

1. [内存优化概述](#内存优化概述)
2. [LazyForEachOptions 配置](#lazyforeachoptions-配置)
3. [LazyForEachMemOptStrategy 内存优化策略](#lazyforeachmemoptstrategy-内存优化策略)
4. [LazyForEachReleaseStrategy 资源释放策略](#lazyforeachreleasestrategy-资源释放策略)
5. [自定义组件冻结](#自定义组件冻结)
6. [完整使用示例](#完整使用示例)

---

## 内存优化概述

LazyForEach 是一种懒加载渲染控制组件，从提供的数据源中按需迭代数据并创建相应组件。当组件滑出可视区域外时，框架会进行组件销毁回收以降低内存占用。在大量子组件场景下，LazyForEach 与缓存列表项（`cachedCount`）、动态预加载、组件复用等方法配合使用，可以进一步提升滑动帧率并降低应用内存占用。

从 API version 26.0.0 开始，LazyForEach 新增第四个可选参数 `LazyForEachOptions`，支持配置内存优化策略、资源释放策略以及自定义组件冻结，在长列表场景下进一步降低内存占用。

---

## LazyForEachOptions 配置

### 接口说明

从 API version 26.0.0 开始，LazyForEach 支持传入 `LazyForEachOptions`：

```typescript
LazyForEach(
  dataSource: IDataSource,
  itemGenerator: (item: any, index: number) => void,
  keyGenerator?: (item: any, index: number) => string,
  options?: LazyForEachOptions
)
```

> **说明：**
> 1. 使用 `LazyForEachOptions` 时，**必须设置键值生成函数**（`keyGenerator`），否则将编译失败。
> 2. 不传入 `options` 时使用默认配置：自定义组件冻结模式默认为 `AUTO`，资源释放策略默认为 `BATCH`，内存优化策略默认为 `DEFAULT`。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

### LazyForEachOptions 属性

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| customComponentFreezeMode | [LazyForEachCustomComponentFreezeMode](#自定义组件冻结) | 否 | 是 | 选择是否使能自定义组件冻结。仅在 LazyForEach 下直接使用自定义组件时生效，其他情况不适用。默认为 `AUTO`。 |
| releaseStrategy | [LazyForEachReleaseStrategy](#lazyforeachreleasestrategy-资源释放策略) | 否 | 是 | 为 LazyForEach 配置资源释放策略。默认使用 `BATCH`，批量释放节点。 |
| memoryOptimizationStrategy | [LazyForEachMemOptStrategy](#lazyforeachmemoptstrategy-内存优化策略) | 否 | 是 | LazyForEach 的内存优化策略。该参数在创建 LazyForEach 时设定，**不支持动态修改**。默认值：`DEFAULT`。 |

---

## LazyForEachMemOptStrategy 内存优化策略

LazyForEach 内存优化策略枚举。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

### 枚举值

| 名称 | 值 | 说明 |
| --- | --- | --- |
| DEFAULT | 0 | 无内存优化策略。 |
| ENABLE_AUTO_CACHE_OPTIMIZATION | 1 << 0 | 自动内存优化策略。当 LazyForEach 承载的列表项数量较多（例如达到数百项以上）或单项子组件结构复杂（例如包含多层嵌套或数十个子节点），导致内存占用偏高（可通过性能分析工具检测内存占用情况）时，建议使用此策略以降低内存使用量。 |

### 自动内存优化策略触发时机

当配置为 `ENABLE_AUTO_CACHE_OPTIMIZATION` 时，框架在以下场景自动释放预加载区域内的节点：

| 触发条件 | 说明 |
| --- | --- |
| 应用退后台时 | 应用进入后台，LazyForEach 所在页面不可见 |
| LazyForEach 所在组件不可见时 | `visibility` 属性设置为 `Visible` 以外的值，或组件面积为 0（不考虑遮挡） |
| 整机低内存时 | `MemoryLevel` 达到 `MEMORY_LEVEL_LOW` 或 `MEMORY_LEVEL_CRITICAL` |

### 不同设备内存的释放策略

| 设备内存 | 释放行为 |
| --- | --- |
| 内存大于 6G 的设备 | 释放预加载区域内的部分节点，直至上下预加载区域内的节点数量均不超过 2 |
| 内存小于等于 6G 的设备 | 释放预加载区域内的全部节点 |

### 节点恢复时机

当以下条件满足时，框架自动恢复预加载区域内的节点：

| 恢复条件 | 说明 |
| --- | --- |
| 应用恢复前台时 | 应用从后台回到前台 |
| LazyForEach 所在组件恢复显示时 | 组件从不可见恢复为可见 |
| LazyForEach 发生滑动时 | 用户滑动列表触发节点重建 |

> **重要说明：** 在释放和恢复节点时，会触发[自定义组件生命周期](https://developer.huawei.com/consumer/cn/doc/application-devs/ui/state-management/arkts-page-custom-components-lifecycle)回调（`aboutToAppear` / `aboutToDisappear` 等）。开发者应确保生命周期回调中的逻辑能正确处理节点的创建和销毁。

---

## LazyForEachReleaseStrategy 资源释放策略

选择 LazyForEach 的资源释放策略。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

### 枚举值

| 名称 | 值 | 说明 |
| --- | --- | --- |
| BATCH | 0 | BATCH 为默认使用的资源释放策略，该策略在当前帧释放掉所有废弃节点资源。如果存在节点复用，此时能够最大化节点复用率，但如果存在组件层级较深、子组件数量较多的节点，单节点资源释放耗时较长。大量节点在当前帧释放可能会导致超大帧，影响性能。 |
| PROGRESSIVE | 1 | PROGRESSIVE 为根据节点释放时间和当前帧剩余时间自动调整节点释放的策略，如果当前帧时间不足以释放剩余节点，会放到后续帧继续释放，避免超大帧的出现，优化性能。此时，LazyForEach 会继续持有节点，可能导致复用率下降，在节点大量产生来不及释放的情况下，内存会相应地升高。开发者需关注性能和内存的影响，合理选择资源释放策略。 |

---

## 自定义组件冻结

### LazyForEachCustomComponentFreezeMode 枚举

选择是否使能自定义组件冻结。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

| 名称 | 值 | 说明 |
| --- | --- | --- |
| AUTO | 0 | 跟随 module.json5 配置文件中 metadata 的设置。 |
| DISABLED | 1 | 不使能自定义组件冻结。 |
| ENABLED | 2 | 使能自定义组件冻结。 |

### 冻结效果

在 LazyForEach 下直接使用自定义组件时，使能冻结后，当自定义组件不在可视区域时，框架会暂停该组件的状态变量更新等处理逻辑，以降低资源消耗；组件重新进入可视区域时恢复正常处理。

> **说明：** 该配置仅在 LazyForEach 下直接使用自定义组件时生效，其他情况不适用。

---

## 完整使用示例

### 示例：使用自动内存优化策略

以下示例中，通过 `LazyForEachOptions` 的 `memoryOptimizationStrategy` 属性使用了自动内存优化策略。应用退后台时自动清理预加载缓存，应用恢复前台时自动恢复缓存。

从 API version 26.0.0 开始支持。

```typescript
import { BasicDataSource } from './BasicDataSource';

class DataSource extends BasicDataSource {
  public dataArray: string[] = [];
  public totalCount(): number {
    return this.dataArray.length;
  }
  public getData(index: number): string {
    return this.dataArray[index];
  }
  public pushData(data: string): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }
}

@Component
struct ChildComponent {
  aboutToAppear() {
    console.info('ChildComponent aboutToAppear');
  }
  aboutToDisappear() {
    console.info('ChildComponent aboutToDisappear');
  }
  build() {
    Text('ChildComponent')
  }
}

@Entry
@Component
struct MemoryOptimizeDemo {
  private data: DataSource = new DataSource();
  aboutToAppear() {
    for (let i = 0; i < 100; i++) {
      this.data.pushData(`item ${i}`);
    }
  }
  build() {
    Column() {
      List() {
        LazyForEach(this.data,
          (item: string, index: number) => {
            ListItem() {
              ChildComponent()
            }
          },
          (item: string, index: number) => item,
          // 使用自动内存优化策略
          { memoryOptimizationStrategy: LazyForEachMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION }
        )
      }
      .cachedCount(2)
    }
  }
}
```

参考[LazyForEach 内存优化示例](../assets/LazyForEachMemOptExample.ets)

## 核心约束

- 使用 `LazyForEachOptions`（第四个参数 `options`）时，必须设置 `keyGenerator` 键值生成函数，否则编译失败。
- `memoryOptimizationStrategy` 在创建 LazyForEach 时设定，不支持动态修改，需在初始化时确定策略。
- 列表项数量较多（数百项以上）或单项子组件结构复杂时，应启用 `ENABLE_AUTO_CACHE_OPTIMIZATION` 自动释放预加载节点。
- 节点释放和恢复时会触发自定义组件生命周期回调，必须确保 `aboutToAppear` / `aboutToDisappear` 能正确处理节点的创建和销毁。
- `releaseStrategy` 选择 `PROGRESSIVE` 时会跨帧释放节点，可能导致复用率下降和内存升高，节点结构简单时应优先使用 `BATCH`。
- `LazyForEachOptions` 从 API version 26.0.0 开始支持，低版本不可用。
