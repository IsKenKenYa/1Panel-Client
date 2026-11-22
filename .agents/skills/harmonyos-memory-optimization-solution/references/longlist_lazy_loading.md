# 长列表懒加载改造指南（ForEach → LazyForEach / Repeat）

## 目录

1. [优化概述](#优化概述)
2. [问题：长列表滚动使用 ForEach 一次性加载](#问题长列表滚动使用-foreach-一次性加载)
3. [方案一：改用 LazyForEach 按需加载](#方案一改用-lazyforeach-按需加载)
4. [方案二：改用 Repeat virtualScroll 按需加载](#方案二改用-repeat-virtualscroll-按需加载)
5. [LazyForEach 与 Repeat 选型](#lazyforeach-与-repeat-选型)
6. [常见问题排查](#常见问题排查)

---

## 优化概述

长列表滚动场景未使用懒加载（`ForEach` 一次性加载全部列表项）时，优化方案是**改用 `LazyForEach` 或 `Repeat`（virtualScroll）**，由框架按可视区域按需创建节点。

| 问题案例 | 优化建议 |
| --- | --- |
| 长列表滚动使用 ForEach，一次性构建全部列表项 | 改用 LazyForEach（按需加载）或 Repeat virtualScroll（按需加载 + 复用） |

### 适用与不适用场景

| 场景 | 是否适用 |
| --- | --- |
| List/Grid/Swiper/WaterFlow 长列表（数据量上百项以上）使用 ForEach 渲染 | 适用 |
| 首帧加载慢、内存峰值高，根因是 ForEach 全量构建列表节点 | 适用 |
| 数据量少（几十项以内）、结构简单的非长列表遍历 | 不适用（ForEach 足够） |
| 非滚动容器内的遍历渲染 | 不适用（LazyForEach 懒加载不生效，见排查项） |

---

## 问题：长列表滚动使用 ForEach 一次性加载

`ForEach` 接收数组后为**每个元素创建组件，一次性全部挂载到组件树**——不感知滚动容器，无按需加载与节点回收能力：

- 首次渲染即构建全部列表项节点，数据量上百/上千时首帧耗时长；
- 全部节点与列表项内图片同时驻留内存，内存峰值高；
- 滚动链路承受节点创建、状态初始化、图片加载压力，容易掉帧；
- `cachedCount`、预加载区域释放等优化能力均不适用（这些是 LazyForEach/Repeat 的能力）。

典型反例：

```typescript
// 反例：长列表使用 ForEach，一次性构建全部 ListItem
List() {
  ForEach(this.feedItems, (item: FeedItem) => {
    ListItem() {
      FeedItemView({ item: item })  // 1000 项全部构建
    }
  }, (item: FeedItem) => item.id)
}
```

---

## 方案一：改用 LazyForEach 按需加载

`LazyForEach` 从数据源（`IDataSource`）按需迭代数据并创建组件，节点滑出可视区域后销毁回收，配合容器 `cachedCount` 平衡预加载与内存。

**Step 1：实现 IDataSource 数据源**（listener 通知机制是数据刷新的关键）：

```typescript
import { IDataSource, DataChangeListener } from '@kit.ArkUI';

class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private originDataArray: FeedItem[] = [];

  totalCount(): number {
    return this.originDataArray.length;
  }

  getData(index: number): FeedItem {
    return this.originDataArray[index];
  }

  registerListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  // 数据变化时通知框架刷新（改数据必须走这些通知，不能只改数组）
  notifyDataReload(): void {
    this.listeners.forEach((listener) => listener.onDataReloaded());
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach((listener) => listener.onDataAdd(index));
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach((listener) => listener.onDataDelete(index));
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach((listener) => listener.onDataChange(index));
  }
}

class FeedDataSource extends BasicDataSource {
  setData(items: FeedItem[]): void {
    this.originDataArray = items;
    this.notifyDataReload();
  }

  addData(index: number, item: FeedItem): void {
    this.originDataArray.splice(index, 0, item);
    this.notifyDataAdd(index);
  }
}
```

**Step 2：滚动容器内替换 ForEach 为 LazyForEach**：

```typescript
@State dataSource: FeedDataSource = new FeedDataSource();

List() {
  LazyForEach(this.dataSource, (item: FeedItem) => {
    ListItem() {
      FeedItemView({ item: item })  // 仅构建可视区域 + cachedCount 预加载区域
    }
  }, (item: FeedItem) => item.id)  // keyGenerator
}
.cachedCount(2)  // 预加载区域节点数，建议不超过 2
```

**迁移要点：**

- `LazyForEach` 的数据懒加载**仅在 List、Grid、Swiper、WaterFlow 容器内生效**；放在 Scroll/Column 等非滚动容器内不生效（等同全量加载）；
- 数据更新必须通过 `DataChangeListener` 通知（`onDataReloaded`/`onDataAdd` 等），直接修改数组 UI 不刷新；
- 推荐显式提供 `keyGenerator`（第三参数），键值稳定可减少无效刷新；
- 进阶：API 26+ 可通过第四参数 `LazyForEachOptions` 配置内存优化策略（退后台/低内存自动释放预加载节点），见 [LazyForEach 内存优化策略指南](./lazyforeach_memory_optimization.md)。

---

## 方案二：改用 Repeat virtualScroll 按需加载

`Repeat` 的 `virtualScroll` 模式让框架**按可视窗口懒加载**，节点滑出后进入缓存池**复用**（不销毁重建），配合 `template` 多模板与 `cachedCount` 进一步优化：

```typescript
List() {
  Repeat(this.feedItems)
    .virtualScroll({ cachedCount: 2 })  // 按需加载 + 预加载区域（不超过 2）
    .templateId((item: FeedItem) => item.type)  // 多模板场景按类型选模板
    .template('text', (row: FeedItem) => {
      ListItem() {
        TextFeedItemView({ item: row })
      }
    }, { cachedCount: 5 })  // 模板缓存池大小
    .template('image', (row: FeedItem) => {
      ListItem() {
        ImageFeedItemView({ item: row })
      }
    }, { cachedCount: 3 })
    .key((item: FeedItem, index: number) => `${item.id}-${index}`)
    .each((row: FeedItem) => {  // .each() 必须设置，否则运行时报错
      ListItem() {
        FeedItemView({ item: row })
      }
    })
}
```

**迁移要点：**

- 单一模板时只需 `.virtualScroll()` + `.each()`，`template` 用于多模板（不同 item 结构）场景；
- `.each()` 属性必须设置，否则运行时报错；
- Repeat virtualScroll 自带节点复用（滑出节点进缓存池），与 LazyForEach"滑出即销毁"不同；
- 进阶：API 26+ 可通过 `VirtualScrollOptions.memoryOptimizationStrategy` 配置缓存池自动释放，见 [Repeat 内存优化策略指南](./repeat_memory_optimization.md)。

---

## LazyForEach 与 Repeat 选型

| 维度 | LazyForEach | Repeat virtualScroll |
| --- | --- | --- |
| 按需加载 | 是（按可视区域创建） | 是（按可视窗口创建） |
| 滑出处理 | 销毁回收，滑回重建 | 进缓存池，滑回复用（不重建） |
| 组件复用 | 无内置复用（需配合 @Reusable） | 内置（template 缓存池） |
| 数据源 | 需实现 IDataSource（listener 通知） | 直接使用数组 |
| 多模板 | 不支持（需自行处理） | 原生支持（template/templateId） |
| 进阶内存优化 | API 26+ LazyForEachOptions | API 26+ VirtualScrollOptions |

建议：

- 简单结构长列表、已有 IDataSource 基础：**LazyForEach**；
- 多模板混排（图文/视频流）、对滑动性能与复用要求高：**Repeat virtualScroll**；
- 两者都会带来"节点按需创建"，配合分页加载（数据侧按需拉取）收益更大。

---

## 核心约束

- `ForEach` 为每个元素创建组件并**一次性全部挂载**到组件树，不感知滚动容器；长列表（数据量上百项以上）滚动场景不应使用 ForEach 全量渲染。
- 未使用懒加载的长列表应改用 **LazyForEach**（按需创建，滑出销毁回收）或 **Repeat virtualScroll**（按需创建，滑出进缓存池复用）。
- LazyForEach 的数据懒加载**仅在 List/Grid/Swiper/WaterFlow 容器内生效**；放在 Scroll/Column/Row 等非滚动容器内不生效（等同全量加载）。
- LazyForEach 需实现 `IDataSource`；数据变更必须通过 `DataChangeListener` 通知（`onDataReloaded`/`onDataAdd` 等），直接修改数组 UI 不刷新。
- Repeat 的 `.each()` 属性必须设置，否则运行时报错；多模板场景用 `template`/`templateId` 配合各模板 `cachedCount`。
- 懒加载改造需与数据侧分页按需拉取配合；容器 `cachedCount` 不宜过大，建议不超过 2（详见 [滚动容器 cachedCount 预加载优化指南](./scroll_cachedcount_optimization.md)）。
- 进阶（退后台/低内存自动释放）：LazyForEach 见 `LazyForEachOptions`（lazyforeach_memory_optimization.md），Repeat 见 `VirtualScrollOptions`（repeat_memory_optimization.md）。
