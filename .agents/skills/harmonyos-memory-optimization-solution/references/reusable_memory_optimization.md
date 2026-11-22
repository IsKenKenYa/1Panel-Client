# 可复用自定义组件内存优化策略指南

## 目录

1. [内存优化概述](#内存优化概述)
2. [ReusableOptions 配置](#reusableoptions-配置)
3. [ReusableMemOptStrategy 内存优化策略](#reusablememoptstrategy-内存优化策略)
4. [复用池容量限额机制](#复用池容量限额机制)
5. [适用范围 @Reusable 与 @ReusableV2](#适用范围-reusable-与-reusablev2)
6. [完整使用示例](#完整使用示例)

---

## 内存优化概述

可复用自定义组件（`@Reusable` / `@ReusableV2`）通过复用池机制实现组件实例的复用，避免反复创建和销毁。当组件被回收时，实例进入复用池暂存；当需要同类组件时，优先从复用池取用。然而，复用池中暂存的实例仍占用内存，在应用退后台或整机低内存时，未释放的复用池实例会导致内存占用偏高。

从 API version 26.0.0 开始，`@Reusable` 和 `@ReusableV2` 装饰器支持传入 `ReusableOptions`，通过 `memoryOptimizationStrategy` 配置内存优化策略，在应用退后台、组件不可见、整机低内存等场景自动释放复用池中的组件，进一步降低内存占用。

---

## ReusableOptions 配置

### 装饰器参数

`@Reusable` 和 `@ReusableV2` 装饰器接受可选的 `ReusableOptions` 参数：

```typescript
@Reusable(options?: ReusableOptions)
@ReusableV2(options?: ReusableOptions)
```

### ReusableOptions 属性

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| memoryOptimizationStrategy | [ReusableMemOptStrategy](#reusablememoptstrategy-内存优化策略) | 否 | 是 | 可复用自定义组件的内存优化策略。创建时设定，不支持动态修改。传入 `ENABLE_AUTO_CACHE_OPTIMIZATION` 时启用自动内存优化，在应用退后台、组件不可见或整机低内存等场景下自动释放复用池中的组件；不传入时使用默认值 `DEFAULT`（无内存优化策略）。 |

> **说明：** 不传入 `ReusableOptions` 时，`@Reusable` / `@ReusableV2` 行为与之前一致（无内存优化策略），复用池中暂存的实例不会被自动释放。

---

## ReusableMemOptStrategy 内存优化策略

可复用自定义组件内存优化策略枚举。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

### 枚举值

| 名称 | 值 | 说明 |
| --- | --- | --- |
| DEFAULT | 0 | 无内存优化策略。 |
| ENABLE_AUTO_CACHE_OPTIMIZATION | 1 << 0 | 自动内存优化策略。建议在需要降低可复用自定义组件内存使用量的场景下使用此策略。 |

### 自动内存优化策略触发时机

当配置为 `ENABLE_AUTO_CACHE_OPTIMIZATION` 时，满足以下任一条件即释放复用池内的所有该类型自定义组件：

| 触发条件 | 说明 |
| --- | --- |
| 应用退后台时 | 应用进入后台 |
| 复用池所在组件不可见时 | `visibility` 属性设置为 `Visible` 以外的值，或组件面积为 0（不考虑遮挡） |
| 整机低内存时 | `MemoryLevel` 达到 `MEMORY_LEVEL_LOW` 或 `MEMORY_LEVEL_CRITICAL` |

> **重要说明：** 在释放节点时，会触发[自定义组件生命周期](https://developer.huawei.com/consumer/cn/doc/application-devs/ui/state-management/arkts-page-custom-components-lifecycle)回调（`aboutToAppear` / `aboutToDisappear` 等）。开发者应确保生命周期回调中的逻辑能正确处理组件的创建和销毁。

---

## 复用池容量限额机制

除了上述三种触发条件外，`ENABLE_AUTO_CACHE_OPTIMIZATION` 还提供基于复用池容量的自动裁剪机制：

### 裁剪规则

当复用池中相同 ReuseId 的该类型自定义组件数量超过复用池容量限额，且 5 秒钟内不再增加时，保留限额内的组件，释放其余组件。

### 容量限额（按设备内存分级）

| 设备内存 | 复用池容量限额 |
| --- | --- |
| 大于 8G | 48 |
| 大于 6G 且小于等于 8G | 4 |
| 小于等于 6G | 2 |

---

## 适用范围 @Reusable 与 @ReusableV2

### @Reusable（状态管理 V1）

`@Reusable` 适用于状态管理 V1（`@Component`）的自定义组件。配合 `@Reusable` 装饰器使用时，组件可被复用，通过 `aboutToReuse` 回调接收复用参数。

```typescript
@Reusable({ memoryOptimizationStrategy: ReusableMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
@Component
struct ReusableComponent {
  aboutToRecycle() {
    console.info('ReusableComponent aboutToRecycle');
  }
  aboutToReuse(params: Record<string, Object>): void {
    console.info('ReusableComponent aboutToReuse');
  }
  build() {
    Text('ReusableComponent')
  }
}
```

### @ReusableV2（状态管理 V2）

`@ReusableV2` 适用于状态管理 V2（`@ComponentV2`）的自定义组件。`@ReusableV2` 同样支持传入 `ReusableOptions` 配置内存优化策略。

```typescript
@ReusableV2({ memoryOptimizationStrategy: ReusableMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
@ComponentV2
struct ReusableV2Component {
  aboutToReuse(): void {
    console.info('ReusableV2Component aboutToReuse');
  }
  build() {
    Text('ReusableV2Component')
  }
}
```

---

## 完整使用示例

### 示例1：@Reusable 使用自动内存优化策略

以下示例中，可复用自定义组件通过 `ReusableOptions` 的 `memoryOptimizationStrategy` 属性使用了自动内存优化策略。点击 Recycle 按钮触发组件回收，之后应用退后台可触发复用池缓存释放。

从 API version 26.0.0 开始支持。

```typescript
@Reusable({ memoryOptimizationStrategy: ReusableMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
@Component
struct ReusableComponent {
  aboutToRecycle() {
    console.info('ReusableComponent aboutToRecycle');
  }
  aboutToDisappear() {
    console.info('ReusableComponent aboutToDisappear');
  }
  build() {
    Text('ReusableComponent')
  }
}

@Entry
@Component
struct MemoryOptimizeDemo {
  @State showReusableComponent: boolean = true;
  build() {
    Column() {
      Button('Recycle').onClick(() => {
        // 点击按钮触发组件回收，组件进入复用池
        this.showReusableComponent = false;
      })
      if (this.showReusableComponent) {
        ReusableComponent()
      }
    }
  }
}
```

参考[可复用组件内存优化示例](../assets/ReusableMemOptExample.ets)

## 核心约束

- `@Reusable`（V1）和 `@ReusableV2`（V2）均支持通过装饰器参数传入 `ReusableOptions` 配置 `memoryOptimizationStrategy`，创建时设定，不支持动态修改。
- 复用池持有大量实例的场景，应启用 `ENABLE_AUTO_CACHE_OPTIMIZATION` 自动释放复用池中的组件（退后台/组件不可见/整机低内存时释放）。
- `ENABLE_AUTO_CACHE_OPTIMIZATION` 释放的是**复用池内的所有该类型自定义组件**，与 LazyForEach（释放预加载区域节点）和 Repeat（释放缓存池节点）作用对象不同。
- 除三种触发条件外，复用池还有**容量限额裁剪机制**：相同 ReuseId 的组件数量超过限额且 5 秒内不再增加时，保留限额内的组件释放其余组件（>8G 限额 48，>6G&<=8G 限额 4，<=6G 限额 2）。
- 释放节点时会触发自定义组件生命周期回调，必须确保 `aboutToAppear` / `aboutToDisappear` / `aboutToReuse` / `aboutToRecycle` 能正确处理组件的创建、销毁和复用。
- `@ReusableV2` 与 Repeat 配合时，Repeat 的 `reusable: true`（默认）优先于 `@ReusableV2` 复用能力；若需由 `@ReusableV2` 接管复用，应设置 Repeat 的 `reusable: false`。
- `ReusableOptions` 从 API version 26.0.0 开始支持，仅可在 Stage 模型下使用。

