# 方案一：滚动组件 cacheCount 设备分档优化

**适用场景**：List / Grid / WaterFlow 滚动组件的 `cachedCount` 硬编码或未设置。

**方案原理**：cachedCount 控制可视区域外预加载的 Item 数量。硬编码值在低端设备浪费内存，在高端设备体验不足。根据设备分档 + Item 复杂度动态设置，兼顾体验与内存。

## cacheCount 映射表

| 设备分档 | simple Item | complex Item |
|---------|-------------|--------------|
| low | 1 | 0 |
| medium | 2 | 1 |
| high | 3 | 2 |

## Item 复杂度评估

cacheCount 映射依赖 Item 复杂度判断，评估标准如下：

### 简单 Item（simple）
- 纯文本或简单布局
- 无图片或少量小图标
- 组件嵌套层级 ≤ 2
- 无复杂动画

### 复杂 Item（complex）
- 包含大图或多张图片
- 组件嵌套层级 > 2
- 包含 WebView、RichText、Video、Canvas 等重量级组件
- 有复杂动画效果

> 快速判断：含 WebView/Video/Canvas 或图片 > 1 或嵌套 > 8 层 → complex，否则 → simple。

## 代码修改模板

### 1. 新增文件：DeviceLevelDecisionCenter.ets

→ 详见 [device_level_tiering.md](./device_level_tiering.md) 获取完整代码模板。

### 2. 修改页面组件

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范

// === 添加 import ===
import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';

// === 添加 @State 变量 ===
@State cacheCount: number = 1;

// === 在 aboutToAppear 中初始化 ===
aboutToAppear() {
  // ⚠️ 如需传入动态性能时延，在此处测量或从缓存读取
  // DeviceLevelDecisionCenter.setPerformanceLatency(coldStartMs, pageLoadMs);
  let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
  // cacheCount 映射逻辑（属于本优化方案，不属于通用分档机制）
  if (level === DeviceLevel.TIER_LOW) {
    this.cacheCount = 1;
  } else if (level === DeviceLevel.TIER_MEDIUM) {
    this.cacheCount = 2;
  } else {
    this.cacheCount = 3;
  }
  // ... 其他初始化代码
}

// === 替换硬编码的 cachedCount ===
// 修改前
.cachedCount(4)  // 或 .cachedCount(5) 等硬编码值

// 修改后
.cachedCount(this.cacheCount)
```

### 3. cacheCount 映射函数（可选，提取为工具方法）

```typescript
import { DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';

// cacheCount 映射表（属于 cacheCount 优化方案，不属于通用分档机制）
static getCacheCountForLevel(level: string, complexity: string): number {
  if (level === DeviceLevel.TIER_LOW) {
    return complexity === 'simple' ? 1 : 0;
  } else if (level === DeviceLevel.TIER_MEDIUM) {
    return complexity === 'simple' ? 2 : 1;
  }
  return complexity === 'simple' ? 3 : 2;
}
```

## 配套最佳实践

cacheCount 分档是滚动列表内存优化的核心手段，以下实践与其互补，建议配合使用。

### 1. 使用 LazyForEach 替代 ForEach

ForEach 一次性创建所有子组件，LazyForEach 按需创建和回收，内存差异可达 98%。

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
// 基础数据源实现
class BasicDataSource implements IDataSource {
  private dataArray: string[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.dataArray.length;
  }

  getData(index: number): string {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    let pos: number = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }
}
```

### 2. 分页懒加载

配合 onScrollIndex 触发数据分页加载，避免一次加载全部数据：

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
List({ scroller: this.listScroller }) {
  LazyForEach(this.dataSource, (item: ItemData, index: number) => {
    ListItem() {
      ItemComponent({ data: item })
    }
  }, (item: ItemData, index: number) => item.id)
}
.cachedCount(this.cacheCount)
.onScrollIndex((start: number, end: number) => {
  // 滚动到接近底部时加载下一页
  if (end >= this.dataSource.totalCount() - 5) {
    this.dataSource.loadNextPage();
  }
})
```

### 3. @Reusable 组件复用

标记 ListItem 内的自定义组件为 `@Reusable`，滚动时复用组件对象而非反复创建销毁，可降低 GC 频率约 80%：

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
@Component
@Reusable
struct ReusableListItem {
  @State title: string = '';
  @State desc: string = '';

  aboutToReuse(params: Record<string, Object>): void {
    this.title = params.title as string;
    this.desc = params.desc as string;
  }

  aboutToAppear(): void {
    // 首次创建时初始化
  }

  build() {
    Row() {
      Text(this.title)
      Text(this.desc)
    }
  }
}
```

**关键点**：`aboutToReuse` 中必须重置所有状态变量，避免脏数据。

## C-API 代码修改模板（NDK 接口）

适用于使用 ArkUI NDK C-API 开发的场景。C-API 通过 `NodeAdapter` 替代 ArkTS 的 `LazyForEach` 实现懒加载，通过 `NODE_CACHED_COUNT` 属性设置预加载数量。

### 核心概念对照

| ArkTS 概念 | C-API 对应 | 说明 |
|-----------|-----------|------|
| `LazyForEach` | `OH_ArkUI_NodeAdapter_*` | 懒加载适配器 |
| `IDataSource` | `ArkUI_NodeAdapterHandle` | 数据源 |
| `cachedCount(N)` | `NODE_CACHED_COUNT` 属性 | 预加载数量 |
| `List` | `ARKUI_NODE_LIST` | 列表组件 |
| `Grid` | `ARKUI_NODE_GRID` | 网格组件 |
| `WaterFlow` | `ARKUI_NODE_WATER_FLOW` | 瀑布流组件 |
| `ListItem` | `ARKUI_NODE_LIST_ITEM` | 列表项 |
| `GridItem` | `ARKUI_NODE_GRID_ITEM` | 网格项 |
| `FlowItem` | `ARKUI_NODE_FLOW_ITEM` | 瀑布流项 |
| `@Reusable` | 缓存池（std::stack）手动复用 | 组件复用 |

### 1. NodeAdapter 懒加载适配器（C-API）

```cpp
// ListAdapter.h
// C-API 懒加载适配器，等价于 ArkTS 的 LazyForEach + IDataSource

#ifndef LIST_ADAPTER_H
#define LIST_ADAPTER_H

#include <arkui/native_node.h>
#include <arkui/native_interface.h>
#include <stack>
#include <string>
#include <vector>

class ListAdapter {
public:
    ListAdapter() {
        // 获取 NodeAPI 接口
        OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi_);
        // 创建 NodeAdapter（等价于 IDataSource）
        adapter_ = OH_ArkUI_NodeAdapter_Create();
        // 初始化数据
        for (int32_t i = 0; i < 1000; i++) {
            data_.emplace_back("Item " + std::to_string(i));
        }
        // 设置数据总量
        OH_ArkUI_NodeAdapter_SetTotalNodeCount(adapter_, data_.size());
        // 注册事件回调
        OH_ArkUI_NodeAdapter_RegisterEventReceiver(adapter_, this, OnStaticAdapterEvent);
    }

    ~ListAdapter() {
        while (!cachedItems_.empty()) { cachedItems_.pop(); }
        OH_ArkUI_NodeAdapter_UnregisterEventReceiver(adapter_);
        OH_ArkUI_NodeAdapter_Dispose(adapter_);
    }

    ArkUI_NodeAdapterHandle GetAdapter() const { return adapter_; }

private:
    static void OnStaticAdapterEvent(ArkUI_NodeAdapterEvent *event) {
        auto *self = reinterpret_cast<ListAdapter *>(OH_ArkUI_NodeAdapterEvent_GetUserData(event));
        self->OnAdapterEvent(event);
    }

    void OnAdapterEvent(ArkUI_NodeAdapterEvent *event) {
        auto type = OH_ArkUI_NodeAdapterEvent_GetType(event);
        switch (type) {
        case NODE_ADAPTER_EVENT_ON_GET_NODE_ID:
            OnGetNodeId(event);
            break;
        case NODE_ADAPTER_EVENT_ON_ADD_NODE_TO_ADAPTER:
            OnCreateNode(event);
            break;
        case NODE_ADAPTER_EVENT_ON_REMOVE_NODE_FROM_ADAPTER:
            OnRemoveNode(event);
            break;
        default: break;
        }
    }

    // 生成唯一 ID（等价于 LazyForEach 的 keyGenerator）
    void OnGetNodeId(ArkUI_NodeAdapterEvent *event) {
        auto index = OH_ArkUI_NodeAdapterEvent_GetItemIndex(event);
        auto hash = std::hash<std::string>();
        OH_ArkUI_NodeAdapterEvent_SetNodeId(event, hash(data_[index]));
    }

    // 创建或复用节点（等价于 LazyForEach 的 itemGenerator）
    void OnCreateNode(ArkUI_NodeAdapterEvent *event) {
        auto index = OH_ArkUI_NodeAdapterEvent_GetItemIndex(event);
        ArkUI_NodeHandle handle = nullptr;
        if (!cachedItems_.empty()) {
            // 从缓存池复用（等价于 @Reusable）
            handle = cachedItems_.top();
            cachedItems_.pop();
            // 更新内容
            auto *text = nodeApi_->getFirstChild(handle);
            ArkUI_AttributeItem item{nullptr, 0, data_[index].c_str()};
            nodeApi_->setAttribute(text, NODE_TEXT_CONTENT, &item);
        } else {
            // 创建新节点
            auto *text = nodeApi_->createNode(ARKUI_NODE_TEXT);
            ArkUI_AttributeItem textItem{nullptr, 0, data_[index].c_str()};
            nodeApi_->setAttribute(text, NODE_TEXT_CONTENT, &textItem);
            ArkUI_NumberValue sizeVal[] = {{100}};
            ArkUI_AttributeItem height{sizeVal, 1};
            nodeApi_->setAttribute(text, NODE_HEIGHT, &height);

            handle = nodeApi_->createNode(ARKUI_NODE_LIST_ITEM);
            nodeApi_->addChild(handle, text);
        }
        OH_ArkUI_NodeAdapterEvent_SetItem(event, handle);
    }

    // 回收到缓存池（等价于组件销毁复用）
    void OnRemoveNode(ArkUI_NodeAdapterEvent *event) {
        auto *node = OH_ArkUI_NodeAdapterEvent_GetRemovedNode(event);
        cachedItems_.emplace(node);
    }

    std::vector<std::string> data_;
    ArkUI_NativeNodeAPI_1 *nodeApi_ = nullptr;
    ArkUI_NodeAdapterHandle adapter_ = nullptr;
    std::stack<ArkUI_NodeHandle> cachedItems_;
};

#endif
```

### 2. 创建 List 并设置 cachedCount（C-API）

```cpp
// LazyListExample.h
// C-API 创建懒加载 List 并按设备分档设置 cachedCount

#include "ListAdapter.h"

// 获取分档后的 cachedCount（对应 ArkTS 的 DeviceLevelDecisionCenter 逻辑）
int32_t GetCachedCountForDeviceLevel() {
    // TODO: 调用设备分档判断逻辑
    // 以下为默认映射：
    // low → 1, medium → 2, high → 3
    // 实际应通过 DeviceLevelDecisionCenter 的 NDK 等价方式获取
    return 2; // 默认 medium
}

std::shared_ptr<ListAdapter> CreateLazyListExample() {
    // 获取 NodeAPI
    ArkUI_NativeNodeAPI_1 *nodeApi = nullptr;
    OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi);

    // 创建 List 组件
    auto listNode = nodeApi->createNode(ARKUI_NODE_LIST);

    // 设置 cachedCount（等价于 ArkTS .cachedCount(N)）
    int32_t cachedCount = GetCachedCountForDeviceLevel();
    ArkUI_NumberValue cacheVal[] = {{.i32 = cachedCount}};
    ArkUI_AttributeItem cacheItem = {cacheVal, 1};
    nodeApi->setAttribute(listNode, NODE_CACHED_COUNT, &cacheItem);

    // 创建并绑定 NodeAdapter（等价于 LazyForEach）
    auto adapter = std::make_shared<ListAdapter>();
    ArkUI_AttributeItem adapterItem{nullptr, 0, nullptr, adapter->GetAdapter()};
    nodeApi->setAttribute(listNode, NODE_LIST_NODE_ADAPTER, &adapterItem);

    return adapter;
}
```

### 3. Grid / WaterFlow 绑定 NodeAdapter（C-API）

```cpp
// Grid 示例
auto gridNode = nodeApi->createNode(ARKUI_NODE_GRID);

// 设置 cachedCount
ArkUI_NumberValue cacheVal[] = {{.i32 = cachedCount}};
ArkUI_AttributeItem cacheItem = {cacheVal, 1};
nodeApi->setAttribute(gridNode, NODE_CACHED_COUNT, &cacheItem);

// 绑定 NodeAdapter
ArkUI_AttributeItem adapterItem{nullptr, 0, nullptr, gridAdapter->GetAdapter()};
nodeApi->setAttribute(gridNode, NODE_GRID_NODE_ADAPTER, &adapterItem);

// WaterFlow 示例
auto waterFlowNode = nodeApi->createNode(ARKUI_NODE_WATER_FLOW);
nodeApi->setAttribute(waterFlowNode, NODE_CACHED_COUNT, &cacheItem);

// 绑定 NodeAdapter
ArkUI_AttributeItem wfAdapterItem{nullptr, 0, nullptr, flowAdapter->GetAdapter()};
nodeApi->setAttribute(waterFlowNode, NODE_WATER_FLOW_NODE_ADAPTER, &wfAdapterItem);
```

### 4. ListItemGroup 分组列表（C-API）

```cpp
// 创建 ListItemGroup 并绑定 NodeAdapter
auto groupNode = nodeApi->createNode(ARKUI_NODE_LIST_ITEM_GROUP);

// 设置 header/footer
auto headerNode = nodeApi->createNode(ARKUI_NODE_TEXT);
ArkUI_AttributeItem headerText{nullptr, 0, "Group Header"};
nodeApi->setAttribute(headerNode, NODE_TEXT_CONTENT, &headerText);
ArkUI_AttributeItem headerItem = {.object = headerNode};
nodeApi->setAttribute(groupNode, NODE_LIST_ITEM_GROUP_SET_HEADER, &headerItem);

// 绑定分组内的 NodeAdapter
ArkUI_AttributeItem groupAdapterItem{nullptr, 0, nullptr, groupAdapter->GetAdapter()};
nodeApi->setAttribute(groupNode, NODE_LIST_ITEM_GROUP_NODE_ADAPTER, &groupAdapterItem);
```

### C-API 关键属性映射

| C-API 属性名 | 说明 | ArkUI_NumberValue 类型 |
|-------------|------|----------------------|
| `NODE_CACHED_COUNT` | 预加载数量 | `.i32 = N` |
| `NODE_LIST_NODE_ADAPTER` | List 绑定适配器 | `.object = adapterHandle` |
| `NODE_GRID_NODE_ADAPTER` | Grid 绑定适配器 | `.object = adapterHandle` |
| `NODE_WATER_FLOW_NODE_ADAPTER` | WaterFlow 绑定适配器 | `.object = adapterHandle` |
| `NODE_LIST_ITEM_GROUP_NODE_ADAPTER` | ListItemGroup 绑定适配器 | `.object = adapterHandle` |
| `NODE_LIST_STICKY` | 吸顶模式 | `.i32 = ARKUI_STICKY_STYLE_*` |

## 适用组件

### ArkTS
- List
- Grid
- WaterFlow

### C-API（NDK）
- `ARKUI_NODE_LIST`
- `ARKUI_NODE_GRID`
- `ARKUI_NODE_WATER_FLOW`
- `ARKUI_NODE_LIST_ITEM_GROUP`

## 预期优化效果

| 设备类型 | 内存占用降低 | 效果 |
|---------|------------|------|
| 低内存设备 | 20%-30% | 避免 OOM 和卡顿 |
| 中内存设备 | 10%-20% | 兼顾流畅度和内存 |
| 高内存设备 | 5%-10% | 提升稳定性 |

## 注意事项

- 所有分档阈值均可通过 `TierConfig` 自定义调整
- Item 复杂度评估规则见 SKILL.md「Item 复杂度评估」章节
- 设备分档机制详见 [device_level_tiering.md](./device_level_tiering.md)
- 配合 LazyForEach + @Reusable 可在 cacheCount 基础上进一步降低内存和 GC 压力
- **C-API 注意**：设置 NodeAdapter 属性后，不再支持 `addChild` 等直接添加子组件的接口，子组件完全由 NodeAdapter 管理
- **C-API 注意**：NodeAdapter 不会主动释放屏幕外的组件对象，需在 `NODE_ADAPTER_EVENT_ON_REMOVE_NODE_FROM_ADAPTER` 事件中手动释放或缓存复用
- **C-API 注意**：`NODE_CACHED_COUNT` 对 List/Grid/WaterFlow 均使用相同属性名
