# Repeat 内存优化策略指南

## 目录

1. [内存优化概述](#内存优化概述)
2. [Repeat 组件与虚拟滚动](#repeat-组件与虚拟滚动)
3. [VirtualScrollOptions 配置](#virtualscrolloptions-配置)
4. [RepeatMemOptStrategy 内存优化策略](#repeatmemoptstrategy-内存优化策略)
5. [TemplateOptions 与缓存池管理](#templateoptions-与缓存池管理)
6. [reusable 复用配置](#reusable-复用配置)
7. [完整使用示例](#完整使用示例)

**关键注意点：**

- [使用前提：必须使用 Repeat 自身复用能力](#使用前提必须使用-repeat-自身复用能力)——启用内存优化策略必须保持 `reusable: true`，不可由 `@ReusableV2` 接管复用。
- [释放对象](#释放对象)——Repeat 只回收缓存池中的节点，与 LazyForEach 释放预加载区域节点有差异。

---

## 内存优化概述

Repeat 是基于数组类型数据进行循环渲染的组件，一般与滚动容器组件配合使用。Repeat 开启虚拟滚动（`virtualScroll`）后，仅加载可见区域及预加载区域内的子组件，而非加载全部数据项，从而提升大数据量场景下的滚动性能。

从 API version 26.0.0 开始，Repeat 的 `VirtualScrollOptions` 新增 `memoryOptimizationStrategy` 属性，支持配置内存优化策略，在应用退后台、组件不可见、整机低内存等场景自动释放缓存池内的节点，进一步降低内存占用。

> **注意：**
>
> - Repeat 只是回收**缓存池（复用池）中的节点**，与 LazyForEach 释放预加载区域节点有差异（详见[释放对象](#释放对象)）。
> - 启用内存优化策略**必须使用 Repeat 自身的复用能力**（`reusable: true`，默认值）。若由 `@ReusableV2` 接管复用（`reusable: false`），Repeat 的内存优化策略不生效（详见[使用前提](#使用前提必须使用-repeat-自身复用能力)）。

---

## Repeat 组件与虚拟滚动

### Repeat 基本用法

Repeat 基于数组类型数据进行循环渲染，支持 `.each()`、`.key()`、`.virtualScroll()`、`.template()`、`.templateId()` 等属性。

```typescript
// arr 是 Array<string> 类型的数组，为每个数据创建一个 Text 组件
List() {
  Repeat<string>(this.arr)
    .each((repeatItem: RepeatItem<string>) => { ListItem() { Text(repeatItem.item) }})
    .virtualScroll()
}
```

### 虚拟滚动原理

`virtualScroll()` 开启后，Repeat 仅加载可见区域及预加载区域内的子组件，而非加载全部数据项。滚动时，离开可见区域的旧节点进入缓存池（而非直接销毁），新进入可见区域的节点优先从缓存池复用。当缓存池中无可用节点时才创建新节点。

> **说明：** Repeat 的 `each` 属性必须有，否则运行时会报错。`RepeatItem` 参数将 `item` 和 `index` 结合到一起，请勿拆开使用。

---

## VirtualScrollOptions 配置

### virtualScroll 属性

```typescript
virtualScroll(virtualScrollOptions?: VirtualScrollOptions)
```

开启虚拟滚动，适用于数据项数量超出屏幕可见区域的长列表场景。

### VirtualScrollOptions 属性

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| totalCount | number | 否 | 是 | 期望加载的数据项总数，可不等于数据源长度。不设置时默认取数据源长度。与 `onTotalCount()` 最多设置一个，同时设置时忽略 `totalCount`。 |
| reusable | boolean | 否 | 是 | 是否开启复用功能。默认值：true。（API 18+） |
| memoryOptimizationStrategy | [RepeatMemOptStrategy](#repeatmemoptstrategy-内存优化策略) | 否 | 是 | Repeat 的内存优化策略。创建时设定，不支持动态修改。默认值：DEFAULT。（API 26.0.0+） |
| onTotalCount | () => number | 否 | 是 | 计算期望加载的数据项总数的自定义方法。（API 19+） |
| onLazyLoading | (index: number) => void | 否 | 是 | 懒加载指定索引数据的方法。（API 19+） |

> **说明：** `memoryOptimizationStrategy` 从 API version 26.0.0 开始支持，仅可在 Stage 模型下使用。

### 基本配置示例

```typescript
List() {
  Repeat<string>(this.arr)
    .each((repeatItem: RepeatItem<string>) => { ListItem() { Text(repeatItem.item) }})
    .virtualScroll({ totalCount: this.arr.length, reusable: true })
}
```

---

## RepeatMemOptStrategy 内存优化策略

Repeat 内存优化策略枚举。

**起始版本：** 26.0.0

**模型约束：** 此接口仅可在 Stage 模型下使用。

### 枚举值

| 名称 | 值 | 说明 |
| --- | --- | --- |
| DEFAULT | 0 | 无内存优化策略。 |
| ENABLE_AUTO_CACHE_OPTIMIZATION | 1 << 0 | 自动内存优化策略，当需要降低 Repeat 子节点的内存占用时，建议使用此策略以降低内存使用量。 |

### 自动内存优化策略触发时机

当配置为 `ENABLE_AUTO_CACHE_OPTIMIZATION` 时，框架在以下场景自动释放缓存池内的所有节点：

| 触发条件 | 说明 |
| --- | --- |
| 应用退后台时 | 应用进入后台，Repeat 所在页面不可见 |
| Repeat 所在组件不可见时 | `visibility` 属性设置为 `Visible` 以外的值，或组件面积为 0（不考虑遮挡） |
| 整机低内存时 | `MemoryLevel` 达到 `MEMORY_LEVEL_LOW` 或 `MEMORY_LEVEL_CRITICAL` |

### 使用前提：必须使用 Repeat 自身复用能力

Repeat 的内存优化策略释放的是 Repeat **缓存池（复用池）中的节点**，因此生效的前提是列表节点滚动离屏后进入 Repeat 缓存池，即开启 Repeat 自身的复用能力（`VirtualScrollOptions.reusable` 为 `true`，默认值）。

若子组件使用 `@ReusableV2` 装饰且设置 `reusable: false`（由 `@ReusableV2` 接管复用），滚动离屏的节点不会进入 Repeat 缓存池，Repeat 的 `memoryOptimizationStrategy` **没有可释放的对象，不生效**。此场景下应改用 `@ReusableV2` 的 `ReusableOptions` 配置其自身的内存优化策略（见[可复用自定义组件内存优化策略指南](./reusable_memory_optimization.md)）。

### 释放对象

与 LazyForEach 释放"预加载区域节点"不同，Repeat 的 `ENABLE_AUTO_CACHE_OPTIMIZATION` 只回收**缓存池内的所有节点**（即滑动后进入缓存池、暂未被复用的旧节点），不涉及其他节点：

| 组件 | 释放对象 | 说明 |
| --- | --- | --- |
| Repeat | 缓存池（复用池）内的节点 | 滑动离屏后暂存在缓存池、未被复用的旧节点 |
| LazyForEach | 预加载区域节点 | 可见区域外、容器 `.cachedCount()` 预加载区域内的节点 |

两者作用对象不同，不可混用，也互不替代。

### 节点恢复时机

当以下条件满足时，框架自动恢复缓存池内的节点：

| 恢复条件 | 说明 |
| --- | --- |
| 应用恢复前台时 | 应用从后台回到前台 |
| Repeat 所在组件恢复显示时 | 组件从不可见恢复为可见 |

> **重要说明：** 在释放和恢复节点时，会触发[自定义组件生命周期](https://developer.huawei.com/consumer/cn/doc/application-devs/ui/state-management/arkts-page-custom-components-lifecycle)回调（`aboutToAppear` / `aboutToDisappear` 等）。开发者应确保生命周期回调中的逻辑能正确处理节点的创建和销毁。

---

## TemplateOptions 与缓存池管理

### template 属性

```typescript
template(type: string, itemBuilder: RepeatItemBuilder<T>, templateOptions?: TemplateOptions)
```

由 template type 渲染对应的 template 子组件，适用于列表中存在多种类型数据项、需要按类型展示不同样式布局的场景。

### TemplateOptions 属性

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| cachedCount | number | 否 | 是 | 当前 template 的缓存池中可缓存子组件节点的最大数量。取值范围 [0, +∞)，默认值为容器组件显示区域节点与预加载区域节点的个数之和。 |

> **说明：**
>
> 当 `cachedCount` 值被设置为当前 template 在容器组件显示区域的最大节点数量时，Repeat 会做到最大程度的复用。当容器组件显示区域内没有当前 template 的节点时，缓存池不会释放，同时应用内存增大。开发者需要根据应用对内存占用和组件复用效率的需求自行调整，推荐 `cachedCount` 值设置为容器组件显示区域内节点个数。需要注意，不建议设置 `cachedCount` 小于 2，这会导致在快速滑动场景下频繁创建新的节点，从而造成性能劣化。
>
> 滚动容器组件属性 `.cachedCount()` 和 Repeat 组件属性 `.template()` 的参数 `cachedCount` 都是为了平衡性能和内存，但是含义是不同的：
> - 滚动容器组件 `.cachedCount()`：是指在容器组件显示区域外预加载区域的大小，该区域内子组件节点位于组件树上。滚动容器组件会额外渲染这些预加载区域的节点，从而提高列表滑动性能。
> - `.template()` 中的 `cachedCount`：指 Repeat 每个 template 的缓存池大小，当渲染新的子组件时，Repeat 先判断对应 template 缓存池中是否有可用节点，有则复用，没有则创建新节点。

### 多模板配置示例

```typescript
List() {
  Repeat<string>(this.arr)
    .each((repeatItem: RepeatItem<string>) => {})
    .virtualScroll()
    .template('temp', (repeatItem: RepeatItem<string>) => { 
      ListItem() { Text(repeatItem.item) }
    }, { cachedCount: 2 })
    .templateId((item: string, index: number) => { return 'temp' })
}
```

---

## reusable 复用配置

### reusable 属性（API 18+）

`VirtualScrollOptions.reusable` 控制是否开启 Repeat 自身的复用功能。

| 值 | 说明 |
| --- | --- |
| true（默认） | 开启 Repeat 复用，优先使用 Repeat 缓存池 |
| false | 关闭 Repeat 复用，由 `@ReusableV2` 接管复用 |

> **说明：** 当 Repeat 的子组件为 `@ReusableV2` 装饰的自定义组件时，Repeat 自身的复用能力优先于 `@ReusableV2` 的复用能力。若开发者希望使用 `@ReusableV2` 的复用能力，需关闭 Repeat 自身的复用能力（设置 `reusable: false`）。
>
> **注意：** 设置 `reusable: false` 后，Repeat 的 `memoryOptimizationStrategy` 随之失效（见[使用前提](#使用前提必须使用-repeat-自身复用能力)）。若同时需要内存优化，应改用 `@ReusableV2` 的 `ReusableOptions` 配置内存优化策略。

---

## 完整使用示例

### 示例：使用自动内存优化策略

以下示例中，通过 `VirtualScrollOptions` 的 `memoryOptimizationStrategy` 属性使用了自动内存优化策略。点击 Scroll 按钮触发列表跳转，旧节点进入缓存池。应用退后台时自动清理缓存，应用恢复前台时自动恢复缓存。

从 API version 26.0.0 开始支持。

```typescript
@ComponentV2
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
@ComponentV2
struct MemoryOptimizeDemo {
  @Local data: Array<number> = [];
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    for (let i = 0; i < 100; i++) {
      this.data.push(i);
    }
  }

  build() {
    Column() {
      Button('Scroll').onClick(() => {
        // 点击按钮触发列表跳转，旧组件进入缓存池
        this.scroller.scrollToIndex(30);
      })
      List({ scroller: this.scroller }) {
        Repeat<number>(this.data)
          .each((repeatItem: RepeatItem<number>) => {
            ListItem() {
              ChildComponent()
            }
          })
          // 使用自动内存优化策略
          .virtualScroll({ memoryOptimizationStrategy: RepeatMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
      }
      .cachedCount(2)
    }
  }
}
```

参考[Repeat 内存优化示例](../assets/RepeatMemOptExample.ets)

## 核心约束

- Repeat 的 `.each()` 属性必须有，否则运行时会报错。
- `memoryOptimizationStrategy` 通过 `virtualScroll()` 的 `VirtualScrollOptions` 传入，创建时设定，不支持动态修改。
- **启用 Repeat 内存优化策略必须使用 Repeat 自身的复用能力**（`reusable: true`，默认值）。若子组件为 `@ReusableV2` 且设置 `reusable: false`（由 `@ReusableV2` 接管复用），节点不进入 Repeat 缓存池，`memoryOptimizationStrategy` 不生效；此场景应改用 `@ReusableV2` 的 `ReusableOptions` 配置内存优化策略。
- 使用虚拟滚动（`virtualScroll`）的长列表场景，应启用 `ENABLE_AUTO_CACHE_OPTIMIZATION` 自动释放缓存池节点（退后台/低内存/组件不可见时释放，回前台/恢复显示时恢复）。
- 与 LazyForEach 不同，Repeat 的 `ENABLE_AUTO_CACHE_OPTIMIZATION` 只回收**缓存池（复用池）内的所有节点**，而非预加载区域节点；两者作用对象不同，不可混用、互不替代。
- `TemplateOptions.cachedCount` 控制缓存池大小，推荐设置为容器显示区域节点个数，不建议小于 2（会导致快速滑动频繁创建节点）；`cachedCount` 数量不会减少，设置过大时内存持续增长。
- 容器组件 `.cachedCount()` 控制预加载区域，template 的 `cachedCount` 控制缓存池大小，两者含义不同，不可混用。
- 子组件使用 `@ReusableV2` 装饰时，Repeat 自身复用能力优先于 `@ReusableV2`；若需由 `@ReusableV2` 接管复用，应设置 `reusable: false`（同时 Repeat 内存优化策略失效，见上）。
- 节点释放和恢复时会触发自定义组件生命周期回调，必须确保 `aboutToAppear` / `aboutToDisappear` 能正确处理节点的创建和销毁。
- `RepeatMemOptStrategy` 从 API version 26.0.0 开始支持，仅可在 Stage 模型下使用。
