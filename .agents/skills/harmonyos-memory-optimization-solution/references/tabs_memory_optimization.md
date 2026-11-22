# Tabs 页签内存优化指南

## 目录

1. [优化概述](#优化概述)
2. [案例 1：低端机不使用 preloadItems 预加载不可见 TabContent](#案例-1低端机不使用-preloaditems-预加载不可见-tabcontent)
3. [案例 2：关闭切换动画避免冗余加载中间页面](#案例-2关闭切换动画避免冗余加载中间页面)
4. [案例 3：设置 cachedMaxCount 小于 2 限制缓存页签数量](#案例-3设置-cachedmaxcount-小于-2-限制缓存页签数量)
5. [常见问题排查](#常见问题排查)

---

## 优化概述

Tabs 组件默认**按需构建**：仅当前选中的 TabContent 被构建，未访问的页签不占组件树内存。但以下配置/行为会打破这一特性，导致不可见页面被提前/连带加载或加载后不释放，内存增长：

| 问题案例 | 优化建议 |
| --- | --- |
| 预加载不可见 tab 页面 | 低端机不使用 `preloadItems`，保持默认按需构建 |
| 冗余加载 tabs 中间页面（切换动画滑过） | `animationMode` 设为 `AnimationMode.NO_ANIMATION`，或 `animationDuration` 设为 0 |
| 已访问页签加载后不释放，随浏览数量累积 | 设置 `cachedMaxCount` 小于 2（API 19+），限制缓存页签数量 |

### 适用与不适用场景

| 场景 | 是否适用 |
| --- | --- |
| 低端机调用 preloadItems 预加载不可见 TabContent，内存占用高 | 适用 |
| preloadItems 无参/大数组调用，一次性加载全部或大量页签 | 适用 |
| 点击 TabBar 跨页签跳转，切换动画连带构建中间页面 | 适用 |
| 页签多且用户频繁切换，已访问页签加载后不释放导致内存累积 | 适用 |
| 页签数量少（2-3 个）且页面轻量，预加载收益明显 | 不适用 |
| 不使用 Tabs 组件 | 不适用 |

---

## 案例 1：低端机不使用 preloadItems 预加载不可见 TabContent

### 问题

`TabsController.preloadItems(indices?: Array<number>)`（API 12+）会提前构建指定下标的**不可见 TabContent**，以换取切换到这些页签时的首帧性能。内存代价：

- 预加载页面的组件树、状态数据与依赖资源提前驻留内存；
- **无参调用会一次性加载全部子节点**；带数组调用也是一次性加载数组内全部页签——官方文档明确提示"调用该接口后会一次性加载所有指定的子节点，为了性能考虑，建议分批加载子节点"；
- 页签多、页面重（长列表/大图/WebView）时内存成倍增长。

低端机内存紧张，预加载的收益（切换快）小于代价（内存高、卡顿甚至被系统查杀）。

### 优化建议

**低端机不使用 preloadItems**（不调用，保持默认按需构建）。确有切换性能诉求时，按设备能力分级处理（与离线 Web 组件预创建分级同一套思路）：

```typescript
import { deviceInfo } from '@kit.BasicServicesKit';

// 设备能力分级决定是否预加载
const isLowEnd: boolean =
  deviceInfo.performanceClass === deviceInfo.PerformanceClassLevel.CLASS_LEVEL_LOW;

if (!isLowEnd) {
  // 高端机：只预加载常用且轻量的页签，分批调用，总数建议不超过 2-3 个
  this.tabsController.preloadItems([0, 2]);
  this.tabsController.preloadItems([3]);
}
// 低端机：不调用 preloadItems，保持按需构建
```

注意：

- 预加载下标只选**常用且轻量**的页签；含长列表、大图、WebView 的重页面不要预加载；
- 页签索引从 0 开始；在 Tabs 完成渲染后调用（如首页就绪回调之后），避免预加载不存在的索引；
- `preloadItems` 返回 Promise，异常路径需 catch处理。

---

## 案例 2：关闭切换动画避免冗余加载中间页面

### 问题

点击 TabBar 页签或调用 `TabsController.changeIndex` **跨页签跳转**时（如从第 1 个跳到第 4 个），默认切换动画会**滑过中间的 TabContent**（第 2、3 个页面），中间页面在动画过程中被连带构建/加载：

- 用户从未访问的中间页签也被加载，组件树与数据驻留内存（冗余加载）；
- 页签多、跨度大时一次切换可能连带加载多个页面，内存瞬时抬升；
- Tabs 默认不销毁已构建的页签，这部分内存不会随切换结束回落。

### 优化建议

**方案 A：`animationMode` 设为 `AnimationMode.NO_ANIMATION`**（API 12+，无切换动画，直接呈现目标页）：

```typescript
Tabs({ barPosition: BarPosition.Start, controller: this.tabsController }) {
  // TabContent...
}
.animationMode(AnimationMode.NO_ANIMATION)
```

**方案 B：`animationDuration` 设为 0**（动画时长为零，同样不会滑过中间页面）：

```typescript
Tabs({ controller: this.tabsController }) {
  // TabContent...
}
.animationDuration(0)
```

两者选其一即可。机制说明（官方文档口径）：

- `animationMode`：设置点击 TabBar 页签或调用 TabsController 的 `changeIndex` 接口时切换 TabContent 的动画形式，默认 `AnimationMode.CONTENT_FIRST`（先加载目标页内容，再开始切换动画），从 API 12 开始支持；
- `animationDuration`：切换动画时长，默认 300ms（API 11+ 且 TabBar 为 BottomTabBarStyle 样式时默认 0）；`changeIndex` 默认生效切换动效，设置为 0 即关闭动画。

取舍提示：

- 关闭动画会失去页签切换的滑动过渡效果；对过渡体验有要求的产品可**仅在低端机关闭**；
- 用户**手势滑动**（`scrollable: true`）划过的页面仍会被加载，这是正常交互行为，本方案只作用于点击页签/`changeIndex` 跳转路径；
- 需要轻量过渡效果时可改用自定义动画（如目标页淡入），不触发容器滑动。

---

## 案例 3：设置 cachedMaxCount 小于 2 限制缓存页签数量

### 问题

Tabs 组件**默认所有子组件加载后都不再释放**（未设置 `cachedMaxCount` 时）。这意味着用户每访问一个新页签，该页签的组件树、状态数据与依赖资源就会驻留内存且不回落：

- 用户浏览页签越多，驻留内存的页签越多，内存随访问数量**线性累积**且不回落；
- 页签多（5+ 个）且页面重（长列表、大图、WebView）时，多次切换后内存持续攀升，低端机易触发系统查杀；
- 与案例 1（预加载）、案例 2（动画连带加载）叠加时，问题更严重——被预加载或连带加载的页面同样不会被释放。

### 优化建议

**设置 `cachedMaxCount` 为小于 2 的值（0 或 1），限制缓存页签数量**（API 19+）。`cachedMaxCount` 只对缓存范围外的子组件进行释放，不对缓存范围内的子组件进行预加载：

```typescript
Tabs({ controller: this.tabsController }) {
  // TabContent...
}
// 方案 A：count=0 + CACHE_BOTH_SIDE，仅保留当前页签（1 个）
.cachedMaxCount(0, TabsCacheMode.CACHE_BOTH_SIDE)

// 方案 B：count=1 + CACHE_LATEST_SWITCHED，保留当前页签 + 最近切换的页签（最多 2 个）
.cachedMaxCount(1, TabsCacheMode.CACHE_LATEST_SWITCHED)
```

两种缓存模式（`TabsCacheMode`，API 19+，默认 `CACHE_BOTH_SIDE`）与 count 取值的缓存上限关系：

| mode | count 取值 | 最多缓存子组件数 | 说明 |
| --- | --- | --- | --- |
| `CACHE_BOTH_SIDE`（默认） | 0 | 1（2×0+1） | 仅当前页签 |
| `CACHE_BOTH_SIDE`（默认） | 1 | 3（2×1+1） | 当前页签 + 两侧各 1 个 |
| `CACHE_LATEST_SWITCHED` | 0 | 1（0+1） | 仅当前页签 |
| `CACHE_LATEST_SWITCHED` | 1 | 2（1+1） | 当前页签 + 最近切换过的 1 个 |

**取值建议**：

- **count=0**：缓存上限始终为 1（无论哪种 mode），仅保留当前页签。每次切换离开即释放上一个页签，内存最低，适合**页签多且页面重**的低端机场景。代价是切回已释放页签时需重新构建（首帧略慢）。
- **count=1 + `CACHE_LATEST_SWITCHED`**：缓存上限为 2，保留当前页签与最近切换的页签，便于在两个页签间来回切换时免重建。适合**用户在相邻页签间频繁往返**的场景。

注意：

- `cachedMaxCount` 从 API version 19 开始支持，低版本设备不生效（回退到默认全部不释放），需做版本判断或确保目标设备版本满足；
- count 取值范围为 `[0, +∞)`，设置小于 2 是为了将缓存控制在最小范围；设置过大（如 ≥2）则缓存页签增多，内存优化效果减弱；
- `cachedMaxCount` 只释放缓存范围外的子组件，**不影响** preloadItems 的预加载行为，二者可配合使用（但低端机建议不预加载 + 小 cachedMaxCount）；
- 页签被释放后，其组件的 `aboutToDisappear` 生命周期会触发，可在其中释放页内大资源（网络请求取消、定时器清理、监听解绑等）。

---

## 核心约束

- Tabs 默认**按需构建** TabContent（仅当前选中页签构建）；`preloadItems`（TabsController 方法，API 12+）会提前构建不可见页签，**无参调用一次性加载全部子节点**，官方明确建议分批加载。
- **低端机不使用 preloadItems**：按 `deviceInfo.performanceClass` 分级，低端机保持默认按需构建；高端机确需预加载时分批调用、只选常用轻量页签、总数不超过 2-3 个，并在 Tabs 渲染完成后调用（避免预加载不存在的索引）。
- 点击 TabBar 页签或 `TabsController.changeIndex` 跨页签跳转时，默认切换动画会**滑过并连带构建中间页面**（冗余加载，且 Tabs 默认不销毁已构建页签）。
- 避免冗余加载中间页面：`animationMode` 设为 `AnimationMode.NO_ANIMATION`（API 12+，默认 `CONTENT_FIRST`），或 `animationDuration` 设为 0（默认 300ms，BottomTabBarStyle 样式且 API 11+ 默认 0）；两者选其一。
- `animationMode`/`animationDuration` 只作用于点击页签与 `changeIndex` 跳转路径；用户手势滑动（`scrollable: true`）划过的页面仍会正常构建。
- Tabs **默认所有子组件加载后都不再释放**（未设置 `cachedMaxCount` 时），已访问页签的组件树与数据随浏览数量线性累积且不回落。
- 设置 `cachedMaxCount`（API 19+）小于 2 限制缓存页签数量：`cachedMaxCount(count, mode)` 只释放缓存范围外的子组件、不预加载缓存范围内的子组件。`count=0` 时缓存上限始终为 1（仅当前页签）；`count=1` + `CACHE_LATEST_SWITCHED` 时缓存上限为 2（当前页签 + 最近切换的页签）。count 取值范围 `[0, +∞)`，默认 mode 为 `CACHE_BOTH_SIDE`（缓存上限 2n+1）。
- 页签失活路径（`onChange`/TabContent `onWillHide`/`aboutToDisappear`）应释放页内大资源；页签多且页面重时评估改用 Navigation 路由栈方案（`stackSizeLimit`/`recyclePagesOnLowMemory`）。
