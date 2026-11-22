# 方案六：Tabs 组件缓存分档优化

**适用场景**：应用首页使用 Tabs 组件包含多个 TabContent（如首页、发现、消息、我的），默认一次性预加载所有子组件且不释放，导致内存浪费。native heap / ark ts heap 占用过高。

**方案原理**：Tabs 组件默认行为是创建时预加载所有 TabContent，已加载的页面不会被销毁。当 TabContent 包含复杂内容（List、Web、图片等）时，非活跃 Tab 持续占用内存。通过 `cachedMaxCount`（API 19+）按设备分档控制缓存数量，超出范围的子组件自动释放；API<=18 时通过自定义 TabBar + Swiper + LazyForEach 替代实现。

## API 版本对应策略

| API 版本 | 方案 | 说明 |
|---------|------|------|
| API >= 19 | `cachedMaxCount(count, mode)` | 原生支持，设置缓存个数和模式 |
| API <= 18 | 自定义 TabBar + Swiper + LazyForEach | 替代方案，实现懒加载和释放 |

## 设备分档策略

### cachedMaxCount 分档（API >= 19）

| 设备分档 | cachedMaxCount | 缓存模式 | 最多缓存 TabContent 数 | 说明 |
|---------|---------------|---------|---------------------|------|
| low | 0 | CACHE_LATEST_SWITCHED | 1（仅当前页） | 不缓存任何非活跃页 |
| medium | 1 | CACHE_LATEST_SWITCHED | 2（当前页 + 最近页） | 适度缓存 |
| high | 2 | CACHE_BOTH_SIDE | 5（当前页 + 两侧各2页） | 充分缓存提升体验 |

**缓存数量计算**：
- `CACHE_LATEST_SWITCHED`：count=n → 最多 n+1 个（当前 + 最近切换的 n 个）
- `CACHE_BOTH_SIDE`：count=n → 最多 2n+1 个（当前 + 两侧各 n 个）

### 页面复杂度辅助决策

| 页面类型 | 内存开销 | 缓存建议 |
|---------|---------|---------|
| 纯文本/简单列表 | 低 | 可适当增加缓存 |
| 含大量图片的列表 | 中 | 建议按分档配置 |
| 含 Web/Video 的页面 | 高 | 建议减少缓存，优先释放 |

## 代码修改模板

### 1. API >= 19：使用 cachedMaxCount

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';

@Entry
@Component
struct MainPage {
  @State cachedMaxCount: number = 2;
  @State tabsCacheMode: TabsCacheMode = TabsCacheMode.CACHE_BOTH_SIDE;

  aboutToAppear(): void {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      this.cachedMaxCount = 0;
      this.tabsCacheMode = TabsCacheMode.CACHE_LATEST_SWITCHED;
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      this.cachedMaxCount = 1;
      this.tabsCacheMode = TabsCacheMode.CACHE_LATEST_SWITCHED;
    } else {
      this.cachedMaxCount = 2;
      this.tabsCacheMode = TabsCacheMode.CACHE_BOTH_SIDE;
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        // 首页内容
      }
      .tabBar('首页')

      TabContent() {
        // 发现内容
      }
      .tabBar('发现')

      TabContent() {
        // 消息内容
      }
      .tabBar('消息')

      TabContent() {
        // 我的内容
      }
      .tabBar('我的')
    }
    .cachedMaxCount(this.cachedMaxCount, this.tabsCacheMode)
  }
}
```

### 2. API >= 19：提取为工具方法

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// TabsCacheConfig.ets
import { DeviceLevelDecisionCenter, DeviceLevel } from './DeviceLevelDecisionCenter';

export class TabsCacheConfig {
  count: number = 2;
  mode: TabsCacheMode = TabsCacheMode.CACHE_BOTH_SIDE;

  static getCacheConfig(): TabsCacheConfig {
    let config: TabsCacheConfig = new TabsCacheConfig();
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      config.count = 0;
      config.mode = TabsCacheMode.CACHE_LATEST_SWITCHED;
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      config.count = 1;
      config.mode = TabsCacheMode.CACHE_LATEST_SWITCHED;
    } else {
      config.count = 2;
      config.mode = TabsCacheMode.CACHE_BOTH_SIDE;
    }
    return config;
  }
}
```

### 3. API <= 18：自定义 TabBar + Swiper + LazyForEach 替代方案

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// 适用于 API <= 18，通过 Swiper 的 cachedCount 控制 TabContent 缓存
import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';

@Entry
@Component
struct TabsLazyLoad {
  @State currentIndex: number = 0;
  @State swiperCachedCount: number = 1;

  aboutToAppear(): void {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      this.swiperCachedCount = 0;
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      this.swiperCachedCount = 1;
    } else {
      this.swiperCachedCount = 2;
    }
  }

  @Builder
  tabBarBuilder(title: string, targetIndex: number) {
    Column() {
      Text(title)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
        .fontSize(14)
    }
    .width('25%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
    })
  }

  build() {
    Column() {
      // 自定义 TabBar
      Row() {
        this.tabBarBuilder('首页', 0)
        this.tabBarBuilder('发现', 1)
        this.tabBarBuilder('消息', 2)
        this.tabBarBuilder('我的', 3)
      }
      .width('100%')
      .backgroundColor('#F1F3F5')

      // Swiper 替代 TabContent，配合 LazyForEach 实现懒加载
      Swiper() {
        LazyForEach(this.dataSource, (item: TabItem) => {
          // 各页面内容
        }, (item: TabItem) => item.id.toString())
      }
      .index(this.currentIndex)
      .indicator(false)
      .cachedCount(this.swiperCachedCount)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
    }
    .width('100%')
    .height('100%')
  }
}
```

## 检测规则

```
规则: Tabs 组件缓存未按设备分档
检测条件（满足以下任一组即触发）:

  组 A - cachedMaxCount 未设置（API >= 19）:
  - 代码中使用 Tabs 组件
  - 未设置 cachedMaxCount 属性
  - TabContent 数量 > 3 个
  - ark ts heap 或 native heap PSS 占比过高

  组 B - Tabs 预加载过多（API <= 18）:
  - 代码中使用 Tabs 组件且未使用 Swiper + LazyForEach 替代
  - TabContent 内包含复杂组件（List/Grid/Web/Video）
  - 内存占用与 TabContent 数量正相关

  组 C - cachedMaxCount 硬编码:
  - 代码中 cachedCount(N) 或 cachedMaxCount(N, mode) 为硬编码常量
  - 无设备分档条件判断

定位方法:
  → 代码搜索: "Tabs(" → 定位 Tabs 组件文件
  → 代码搜索: "cachedMaxCount" → 检查是否设置及是否有分档逻辑
  → 代码搜索: "TabContent" → 统计 TabContent 数量和内部组件复杂度
  → 检查 compileSdkVersion：确认 API 版本决定使用哪种方案
  → 结合 meminfo ark ts heap 占比评估影响程度
级别: High (已有优化方案)
```

## 预期效果

| 场景 | 优化前 | 优化后（低端机） | 说明 |
|------|--------|-------------|------|
| 4 Tab 页面 | 4 个 TabContent 全部加载常驻 | 仅当前页常驻 | 切换时按需加载，离开后释放 |
| 5+ Tab 页面 | 所有页面一次性创建 | 最多缓存 2 个页面 | 内存大幅降低 |
| 含 Web 的 Tab | Web 组件始终存活 | 非活跃 Web 随 TabContent 释放 | native heap 显著下降 |

**内存降幅预估（低端机）**：
- 每个 TabContent 约占 10-30MB ark ts heap
- 含 List 的 TabContent 约占 20-50MB
- 含 Web 的 TabContent 约占 50-100MB（native heap）
- 4 Tab 应用仅缓存当前页可节省 30-300MB

## C-API 代码修改模板（NDK 接口）

适用于使用 ArkUI NDK C-API 开发的场景。Tabs 组件的 C-API 支持有限，核心缓存策略建议在 ArkTS 层管理。C-API 主要用于 Tabs/Swiper 节点的创建和 NodeAdapter 的绑定。

### 核心概念对照

| ArkTS 概念 | C-API 对应 | 说明 |
|-----------|-----------|------|
| `Tabs()` | `ARKUI_NODE_TABS` | Tabs 组件 |
| `TabContent()` | `ARKUI_NODE_TAB_CONTENT` | TabContent |
| `Swiper()` | `ARKUI_NODE_SWIPER` | Swiper 组件 |
| `cachedMaxCount(N, mode)` | ArkTS 属性（建议 ArkTS 配置） | 缓存策略 |
| `cachedCount(N)` | `NODE_CACHED_COUNT` | Swiper 预加载数 |
| `LazyForEach` | `OH_ArkUI_NodeAdapter_*` | 懒加载 |

### 1. 使用 Swiper + NodeAdapter 替代 Tabs（C-API）

```cpp
// TabManager.h
// C-API 使用 Swiper + NodeAdapter 实现 Tab 页懒加载

#include <arkui/native_node.h>
#include <arkui/native_interface.h>
#include <vector>
#include <memory>

class TabManager {
public:
    TabManager(ArkUI_NativeNodeAPI_1 *nodeApi) : nodeApi_(nodeApi) {}

    // 创建 Swiper 作为 Tab 容器
    ArkUI_NodeHandle Create(int32_t cachedCount) {
        swiperNode_ = nodeApi_->createNode(ARKUI_NODE_SWIPER);

        // 设置 cachedCount（等价于 Swiper().cachedCount(N)）
        ArkUI_NumberValue cacheVal[] = {{.i32 = cachedCount}};
        ArkUI_AttributeItem cacheItem = {cacheVal, 1};
        nodeApi_->setAttribute(swiperNode_, NODE_CACHED_COUNT, &cacheItem);

        // 隐藏默认指示器
        ArkUI_NumberValue indicatorVal[] = {{.i32 = 0}};
        ArkUI_AttributeItem indicatorItem = {indicatorVal, 1};
        nodeApi_->setAttribute(swiperNode_, NODE_SWIPER_SHOW_INDICATOR, &indicatorItem);

        return swiperNode_;
    }

    // 添加 Tab 页面
    void AddTab(ArkUI_NodeHandle content) {
        nodeApi_->addChild(swiperNode_, content);
    }

    // 切换 Tab
    void SwitchTo(int32_t index) {
        ArkUI_NumberValue val[] = {{.i32 = index}};
        ArkUI_AttributeItem item = {val, 1};
        nodeApi_->setAttribute(swiperNode_, NODE_SWIPER_INDEX, &item);
    }

    // 获取当前 Tab 索引
    int32_t GetCurrentIndex() {
        auto *result = nodeApi_->getAttribute(swiperNode_, NODE_SWIPER_INDEX);
        if (result && result->value) {
            return result->value[0].i32;
        }
        return 0;
    }

private:
    ArkUI_NativeNodeAPI_1 *nodeApi_ = nullptr;
    ArkUI_NodeHandle swiperNode_ = nullptr;
};
```

### 2. 分档 cachedCount 配置（C-API）

```cpp
// 获取 Swiper 的 cachedCount（等价于 ArkTS 的 TabsCacheConfig）
int32_t GetSwiperCachedCount(const std::string &deviceLevel) {
    if (deviceLevel == "low") {
        return 0;  // 不缓存非活跃页
    } else if (deviceLevel == "medium") {
        return 1;  // 缓存 1 个相邻页
    }
    return 2;  // 高端缓存 2 个
}
```

### 3. 自定义 TabBar（C-API）

```cpp
// 创建自定义 TabBar
ArkUI_NodeHandle CreateTabBar(
    ArkUI_NativeNodeAPI_1 *nodeApi,
    const std::vector<std::string> &titles,
    int32_t selectedIndex
) {
    auto barNode = nodeApi->createNode(ARKUI_NODE_ROW);

    for (size_t i = 0; i < titles.size(); i++) {
        auto tabItem = nodeApi->createNode(ARKUI_NODE_COLUMN);
        auto text = nodeApi->createNode(ARKUI_NODE_TEXT);

        ArkUI_AttributeItem textItem{nullptr, 0, titles[i].c_str()};
        nodeApi->setAttribute(text, NODE_TEXT_CONTENT, &textItem);

        // 高亮选中项
        if ((int32_t)i == selectedIndex) {
            ArkUI_NumberValue colorVal[] = {{.u32 = 0xFF1698CE}};
            ArkUI_AttributeItem colorItem = {colorVal, 1};
            nodeApi->setAttribute(text, NODE_FONT_COLOR, &colorItem);
        }

        nodeApi->addChild(tabItem, text);
        nodeApi->addChild(barNode, tabItem);
    }

    return barNode;
}
```

### C-API 关键属性映射

| C-API 属性名 | 说明 | 参数类型 |
|-------------|------|---------|
| `NODE_CACHED_COUNT` | Swiper 预加载数 | `.i32 = N` |
| `NODE_SWIPER_INDEX` | 当前显示页索引 | `.i32 = N` |
| `NODE_SWIPER_SHOW_INDICATOR` | 是否显示指示器 | `.i32 = 0/1` |
| `NODE_FONT_COLOR` | 文字颜色 | `.u32 = 0xAARRGGBB` |
| `NODE_TEXT_CONTENT` | 文字内容 | `.string = "text"` |

### C-API 注意事项

- **Tabs 组件**（`ARKUI_NODE_TABS`）的 `cachedMaxCount` 属性目前建议通过 ArkTS 层配置
- **Swiper 替代方案**：C-API 中推荐使用 `ARKUI_NODE_SWIPER` + `NODE_CACHED_COUNT` + NodeAdapter 实现 Tab 页懒加载
- Swiper 的 `onChange` 事件需通过 `NODE_SWIPER_ON_CHANGE` 注册回调监听
- 自定义 TabBar 需要手动管理选中状态和高亮样式

## 注意事项

- `cachedMaxCount` 从 API version 19 开始支持，低版本需使用 Swiper + LazyForEach 替代
- 设置 `cachedMaxCount` 后不会进行页面预加载，使用懒加载机制（仅切换到页面时才加载）
- 存在翻页动画时，从页面1直接切换到页面3，翻页动画会包含页面2，页面2也会被加载，切换完成后若不在缓存范围内会立即释放
- `CACHE_LATEST_SWITCHED` 模式适合 TabContent 复杂度差异大、用户经常在固定几个 Tab 间切换的场景
- `CACHE_BOTH_SIDE` 模式适合 TabContent 复杂度均匀、用户顺序浏览的场景
- 低端机设 count=0 时，每次切换 Tab 都会重新创建组件，可能有短暂延迟
