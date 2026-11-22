# 滚动容器 cachedCount 预加载优化指南

## 目录

1. [优化概述](#优化概述)
2. [问题分析：cachedCount 设置过大](#问题分析cachedcount-设置过大)
3. [优化方案：cachedCount 收敛为不超过 2](#优化方案cachedcount-收敛为不超过-2)
4. [配套优化建议](#配套优化建议)
5. [常见问题排查](#常见问题排查)

---

## 优化概述

`cachedCount` 是 List/Grid/Swiper/WaterFlow 滚动容器配合懒加载（LazyForEach / Repeat virtualScroll）使用的预加载区域大小：容器除构建可视区域内的列表项外，还会在可视区域外额外构建预加载区域内的列表项（List/Grid/WaterFlow 位于滚动方向两侧，Swiper 位于前后两侧）。预加载区域内的子组件节点挂载在组件树上，列表项中的 Image 也会被一并加载和解码，解码后的图片数据随节点常驻内存。

图片密集型长列表（图片 feed 流、瀑布流、表情/壁纸/头像列表）中 cachedCount 设置过大（如 5、10）时，上下预加载区域合计多构建 2×cachedCount 个列表项，缓存图片数量过多，内存峰值高且随列表项含图量增长；数据量较少时还会使懒加载失效，退化为一次性全量加载。优化方案是 **cachedCount 设置不超过 2**。

| 问题案例 | 优化建议 |
| --- | --- |
| 图片流/瀑布流长列表 `.cachedCount(N)`（N > 2）预加载缓存图片数量过多，滚动内存峰值高 | 容器 `.cachedCount()` 收敛为不超过 2（建议 2） |
| Repeat `virtualScroll({ cachedCount: N })`（N > 2）预加载区域过大 | 同样收敛为不超过 2 |
| 列表数据量较少但 cachedCount 过大，懒加载失效一次性全量加载 | 降低 cachedCount，恢复按需加载 |

### 适用与不适用场景

| 场景 | 是否适用 |
| --- | --- |
| List/Grid/WaterFlow/Swiper 配置 `.cachedCount(N)` 且 N > 2，列表项含大图/多图，内存占用高 | 适用 |
| 快速滚动过程中内存随滑动持续上涨，滚动停止后不回落 | 适用 |
| 列表项总数较少（几十项），cachedCount 过大致懒加载失效、一次性全量加载 | 适用 |
| 未显式设置 cachedCount 或取值已为 1/2 | 不适用 |
| Repeat `.template()` 的 `TemplateOptions.cachedCount`（缓存池大小，另一概念） | 不适用（见 [Repeat 内存优化策略指南](./repeat_memory_optimization.md)） |
| 列表仍使用 ForEach 全量加载（未做懒加载改造） | 不适用（先做懒加载改造，见 [长列表懒加载改造指南](./longlist_lazy_loading.md)） |

---

## 问题分析：cachedCount 设置过大

### 1. 预加载区域节点与图片常驻内存

滚动容器 `.cachedCount()` 指容器显示区域外预加载区域的大小，该区域内的子组件节点位于组件树上（区别于 Repeat template 的缓存池，缓存池节点不在组件树上）。预加载区域内的节点会被完整构建，列表项中的 Image 组件会触发图片加载与解码，解码后的位图随组件驻留内存。

单张图片解码内存按 宽×高×4 字节（ARGB）估算：

| 图片原始尺寸 | 解码内存（未降采样） |
| --- | --- |
| 1080×1080 | ≈ 4.5 MB |
| 1440×1440 | ≈ 8 MB |
| 1080×2400 | ≈ 10 MB |

以竖屏图片 feed 流为例：每屏约 6 项、每项 1 张 1080×1080 图片（未降采样 ≈ 4.5 MB/张），滚动方向两侧预加载区域合计 2×cachedCount 项：

| cachedCount | 预加载合计项数 | 额外图片解码内存（估算） |
| --- | --- | --- |
| 10 | 20 项 | ≈ 90 MB |
| 5 | 10 项 | ≈ 45 MB |
| 2 | 4 项 | ≈ 18 MB |

预加载区域随滚动方向持续重建，快速滚动时图片加载、解码还会占用 IO/CPU，进一步加大内存波动。

### 2. cachedCount 过大使懒加载失效

当列表项总数小于「屏幕内 item 数 + cachedCount」时不会触发懒加载，LazyForEach 会一次性加载全部列表项——数据量较少的图片列表（几十项）设置大 cachedCount 时，懒加载退化，内存不降反升。

### 3. 与 Repeat template cachedCount（缓存池）的区别

| 参数 | 含义 | 本方案是否收敛 |
| --- | --- | --- |
| 容器 `.cachedCount()` / `VirtualScrollOptions.cachedCount` | 可视区域外预加载区域大小，区域内节点在组件树上 | 是，不超过 2 |
| `.template()` 的 `TemplateOptions.cachedCount` | Repeat 各 template 缓存池大小（复用池），推荐设置为容器显示区域内节点个数，且不建议小于 2 | 否（见 [Repeat 内存优化策略指南](./repeat_memory_optimization.md)） |

### 4. 与框架自动内存优化策略对齐

API 26+ 的 `ENABLE_AUTO_CACHE_OPTIMIZATION` 触发释放时，内存大于 6G 的设备会将上下预加载区域内的节点释放至均不超过 2 个（见 [LazyForEach 内存优化策略指南](./lazyforeach_memory_optimization.md)）。即框架自身内存优化目标同样是预加载区域不超过 2；cachedCount 直接设置为不超过 2，可从源头避免「先构建过量节点、再等待释放」的内存波动。

---

## 优化方案：cachedCount 收敛为不超过 2

### Step 1：定位所有 cachedCount 配置

全局检索 `.cachedCount(` 与 `cachedCount:`，覆盖 List/Grid/WaterFlow/Swiper 容器属性与 Repeat `virtualScroll` 配置，记录取值大于 2 的位置。注意区分容器 `.cachedCount()`（预加载区域，本方案收敛对象）与 `.template()` 的 `cachedCount`（缓存池大小，不在收敛范围）。

### Step 2：收敛取值为不超过 2

List/Grid/WaterFlow + LazyForEach：

```typescript
List() {
  LazyForEach(this.dataSource, (item: PhotoItem) => {
    ListItem() {
      PhotoItemView({ item: item })
    }
  }, (item: PhotoItem) => item.id)
}
.cachedCount(2)  // 预加载区域不超过 2，避免预加载缓存图片过多

// WaterFlow 瀑布流同理
WaterFlow() {
  LazyForEach(this.dataSource, (item: PhotoItem) => {
    FlowItem() {
      PhotoItemView({ item: item })
    }
  }, (item: PhotoItem) => item.id)
}
.cachedCount(2)
```

Swiper（前后两侧各预加载 cachedCount 项）：

```typescript
Swiper() {
  LazyForEach(this.dataSource, (item: BannerItem) => {
    Image(item.url)
  }, (item: BannerItem) => item.id)
}
.cachedCount(2)
```

Repeat virtualScroll：

```typescript
List() {
  Repeat(this.feedItems)
    .virtualScroll({ cachedCount: 2 })  // 预加载区域不超过 2
    .each((row: FeedItem) => {
      ListItem() {
        FeedItemView({ item: row })
      }
    })
}
```

### Step 3：验证内存与滑动体验

1. 使用 `hidebug.getPss()` 对比收敛前后静止、匀速滚动、快速滚动三种场景的内存占用与峰值。
2. 快速滑动检查是否出现白块/明显掉帧。预加载减少后若图片加载跟不上滚动速度，优先做图片降采样（`autoResize`）与组件复用，而不是改回大 cachedCount。
3. 数据量较少的列表验证懒加载恢复生效（列表项按需构建，不再一次性全量加载）。

---

## 配套优化建议

cachedCount 收敛解决的是「预加载区域过大」这一层，以下配套措施可与本方案叠加：

| 配套措施 | 解决的问题 | 参考 |
| --- | --- | --- |
| Image autoResize 降采样 | 列表项图片按原始尺寸解码，单图内存过大 | [Image组件降采样指南](./image_autoresize.md) |
| 数据分页按需拉取 | 数据源全量灌入，列表项总数失控 | [长列表懒加载改造指南](./longlist_lazy_loading.md) |
| LazyForEach/Repeat 内存优化策略（API 26+） | 退后台/低内存时自动释放预加载区域与缓存池节点 | [LazyForEach 内存优化策略指南](./lazyforeach_memory_optimization.md) / [Repeat 内存优化策略指南](./repeat_memory_optimization.md) |
| 组件复用（@Reusable/Repeat template） | 降低滚动中节点重建耗时，弥补预加载减少的流畅度 | [可复用自定义组件内存优化策略指南](./reusable_memory_optimization.md) |

---

## 核心约束

- 滚动容器 `.cachedCount()`（List/Grid/WaterFlow/Swiper，配合 LazyForEach/Repeat virtualScroll）建议**不超过 2**，图片密集型列表（图片流/瀑布流/表情壁纸）必须不超过 2。
- Repeat `virtualScroll({ cachedCount })` 的预加载区域同样不超过 2；`.template()` 的 `TemplateOptions.cachedCount` 为缓存池大小，推荐设置为容器显示区域内节点个数且不建议小于 2，不在本收敛范围内，两者含义不同、不可混用。
- 列表项总数小于「屏幕内 item 数 + cachedCount」时懒加载失效，会一次性加载全部列表项；数据量较少的列表不得设置大 cachedCount。
- cachedCount 收敛必须与图片降采样（autoResize）、数据分页按需拉取配合；出现滑动白块时应优先优化图片与节点复用，不得以改回大 cachedCount 换取流畅度。
- `.cachedCount()` 仅在懒加载（LazyForEach/Repeat virtualScroll）场景生效，ForEach 全量加载场景应先完成懒加载改造。
