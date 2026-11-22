# 方案七：不可见组件主动下树优化

**适用场景**：页面中存在条件可见的重量级组件（折叠面板、弹窗/对话框、侧边栏、条件展示区域），使用 `visibility: Hidden` 隐藏而非 `if` 条件渲染下树，导致不可见组件仍占据内存。

**方案原理**：ArkUI 中 `visibility: Hidden` 仅隐藏视觉效果，组件仍保留在组件树中，持续占用内存（状态变量、内部数据结构、事件监听器、渲染上下文等）。通过将 `visibility` 替换为 `if` 条件渲染，可使框架在条件为 false 时将组件从树中移除并释放内存，条件为 true 时重新创建。

## 效果参考（华为最佳实践数据）

| 场景 | 不主动下树 | 主动下树 | 节省内存 |
|------|-----------|---------|---------|
| 长列表滚动 | 250KB | 50KB | 80% |
| 标签页切换 | 150KB | 50KB | 66.7% |
| 折叠面板 | 100KB | 20KB | 80% |
| 复杂页面 | 200KB | 60KB | 70% |

## if 条件渲染 vs visibility 对比

| 对比项 | `if` 条件渲染 | `visibility: Hidden` |
|--------|--------------|---------------------|
| 组件是否在树中 | 否（条件 false 时销毁） | 是（始终存在） |
| 内存占用 | 仅可见组件 | 所有组件 |
| 重新显示耗时 | 需重新创建（~10-50ms） | 即时（0ms） |
| 状态保持 | 需手动保存/恢复 | 自动保持 |
| GC 压力 | 低（组件少） | 高（组件多） |

## 适用场景判断

| 场景 | 推荐 if 下树 | 推荐 visibility | 原因 |
|------|-------------|----------------|------|
| 折叠面板（不频繁切换） | ✅ | ❌ | 展开时重建代价低 |
| 弹窗/对话框 | ✅ | ❌ | 关闭时释放所有资源 |
| 侧边栏导航 | ✅ | ❌ | 收起时释放内容内存 |
| 条件展示区域 | ✅ | ❌ | 不显示时无需占用 |
| 频繁切换 Tab（< 1s） | ❌ | ✅ | 频繁创建销毁影响体验 |
| 动画过渡中的组件 | ❌ | ✅ | 动画需要组件存在 |
| 轻量组件（< 1KB） | ❌ | ✅ | 节省内存不明显 |

## 代码修改模板

### 1. 折叠面板下树

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
@Component
struct CollapsiblePanel {
  @State isExpanded: boolean = false;
  // 保存展开状态的数据，组件下树后仍可恢复
  @State savedSummary: string = '';

  build() {
    Column() {
      // 标题栏始终存在
      Row() {
        Text('面板标题')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(this.isExpanded ? '收起' : '展开')
          .fontSize(14)
          .fontColor('#1698CE')
          .onClick(() => {
            this.isExpanded = !this.isExpanded;
          })
      }
      .width('100%')
      .padding(16)

      // 内容区：使用 if 条件渲染，收起时下树释放内存
      if (this.isExpanded) {
        this.ContentView()
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  @Builder
  ContentView() {
    Column() {
      // 重型内容（List / Web / 大图等）
      Text('面板内容')
        .padding(16)
    }
  }
}
```

### 2. 弹窗/对话框下树

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
@Component
struct DialogWithDetach {
  @State showDialog: boolean = false;

  build() {
    Column() {
      Button('打开弹窗')
        .onClick(() => {
          this.showDialog = true;
        })

      // 弹窗关闭时从树中移除，释放内部组件内存
      if (this.showDialog) {
        this.DialogContent()
      }
    }
  }

  @Builder
  DialogContent() {
    Column() {
      Text('弹窗标题')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)

      // 弹窗内重型内容
      Image('https://example.com/large-image.png')
        .width('100%')
        .height(200)
        .autoResize(true)

      Row() {
        Button('关闭')
          .onClick(() => {
            this.showDialog = false;
          })
      }
      .margin({ top: 16 })
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .width('80%')
  }
}
```

### 3. 替换 visibility: Hidden 为 if 条件渲染

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范

// ❌ 修改前：使用 visibility 隐藏，组件仍在树中占内存
@Component
struct HiddenPanel {
  @State isHidden: boolean = true;

  build() {
    Column() {
      HeavyContentComponent()
    }
    .visibility(this.isHidden ? Visibility.Hidden : Visibility.Visible)
  }
}

// ✅ 修改后：使用 if 条件渲染，组件下树释放内存
@Component
struct DetachedPanel {
  @State isVisible: boolean = false;

  build() {
    Column() {
      if (this.isVisible) {
        HeavyContentComponent()
      }
    }
  }
}
```

### 4. 条件展示区域下树

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范
@Component
struct ConditionalSection {
  @State showDetail: boolean = false;

  build() {
    Column() {
      Text('概览信息')
        .fontSize(16)
        .padding(16)

      Button(this.showDetail ? '隐藏详情' : '查看详情')
        .onClick(() => {
          this.showDetail = !this.showDetail;
        })

      // 详情区域：不查看时下树，包含复杂内容（图表/地图/WebView）
      if (this.showDetail) {
        this.DetailView()
      }
    }
  }

  @Builder
  DetailView() {
    Column() {
      // 重型组件：图表、地图、WebView 等
      Text('详情内容')
        .padding(16)
    }
    .width('100%')
    .padding(16)
  }
}
```

## 检测规则

```
规则: 不可见组件未主动下树
检测条件（满足以下任一组即触发）:

  组 A - visibility Hidden 隐藏重型组件:
  - 代码中使用 .visibility(Visibility.Hidden) 或 .visibility(Visibility.None)
  - 被隐藏的组件包含重量级子组件（List/Web/Video/Image>5）
  - 该组件大部分时间处于隐藏状态

  组 B - 折叠面板内容未下树:
  - UI 树中存在折叠面板（Column/Row 内含可展开内容）
  - 折叠状态下内容仍使用 visibility 隐藏而非 if 条件渲染

  组 C - 弹窗/对话框内容未下树:
  - UI 树中存在弹窗组件
  - 弹窗关闭后内容仍使用 visibility 隐藏而非 if 条件渲染

  组 D - 条件展示区域未下树:
  - 页面中存在条件展示的内容区域
  - 使用 visibility 控制而非 if 条件渲染

定位方法:
  → 代码搜索: "Visibility.Hidden" / "Visibility.None" / "visibility(" → 定位使用 visibility 的组件
  → 代码搜索: ".visibility(" → 检查是否可用 if 替代
  → UI 树 JSON: 查找 visible=false 但仍在树中的组件节点
  → 结合 meminfo ark ts heap 占比评估影响程度

级别: Medium (最佳实践优化，效果显著但非紧急)
```

## 预期效果

| 场景 | 优化前 | 优化后 | 说明 |
|------|--------|--------|------|
| 折叠面板（含 List） | 展开和折叠时 List 均在树中 | 折叠时 List 下树释放 | ark ts heap 降低 30-60KB/面板 |
| 弹窗（含大图） | 关闭后图片仍占内存 | 关闭时组件下树释放图片 | native heap 降低 20-50MB/弹窗 |
| 条件展示区域 | 始终渲染 | 不查看时不渲染 | ark ts heap + native heap 均降低 |

**内存降幅预估**：
- 每个下树的重型组件可释放 1-50MB（取决于内部组件复杂度）
- 含 Web 的条件区域下树可释放 50-100MB native heap
- 含大图的条件区域下树可释放 20-50MB native heap

## C-API 代码修改模板（NDK 接口）

适用于使用 ArkUI NDK C-API 开发的场景。C-API 通过 `NODE_VISIBILITY` 属性控制节点可见性，通过 `addChild` / `removeChild` 实现条件挂载/卸载。

### 核心概念对照

| ArkTS 概念 | C-API 对应 | 说明 |
|-----------|-----------|------|
| `Visibility.Visible` | `ARKUI_VISIBILITY_VISIBLE` (0) | 可见 |
| `Visibility.Hidden` | `ARKUI_VISIBILITY_HIDDEN` (1) | 隐藏但占位 |
| `Visibility.None` | `ARKUI_VISIBILITY_NONE` (2) | 隐藏且不占位 |
| `if (condition) { Component() }` | `addChild` / `removeChild` | 条件挂载/卸载 |
| `aboutToDisappear` 资源清理 | `disposeNode` + 手动清理 | 释放节点和资源 |

### 1. 条件挂载/卸载替代 visibility Hidden（C-API）

```cpp
// ConditionNodeManager.h
// 管理条件性挂载的重量级节点

#include <arkui/native_node.h>
#include <arkui/native_interface.h>
#include <memory>

class ConditionNodeManager {
public:
    ConditionNodeManager(ArkUI_NativeNodeAPI_1 *nodeApi) : nodeApi_(nodeApi) {}

    // 挂载节点（等价于 if (true) { Component() }）
    void AttachNode(ArkUI_NodeHandle parent, ArkUI_NodeHandle child) {
        nodeApi_->addChild(parent, child);
        isAttached_ = true;
    }

    // 卸载节点（等价于 if (false) → 组件下树）
    // 从父节点移除并释放内存
    void DetachNode(ArkUI_NodeHandle parent, ArkUI_NodeHandle child) {
        nodeApi_->removeChild(parent, child);
        // 释放节点资源（等价于组件从组件树移除）
        nodeApi_->disposeNode(child);
        isAttached_ = false;
    }

    // 安全地切换挂载状态
    void ToggleAttach(
        ArkUI_NodeHandle parent,
        std::function<ArkUI_NodeHandle()> createFunc  // 创建函数
    ) {
        if (isAttached_ && childNode_ != nullptr) {
            DetachNode(parent, childNode_);
            childNode_ = nullptr;
        } else {
            childNode_ = createFunc();
            AttachNode(parent, childNode_);
        }
    }

    bool IsAttached() const { return isAttached_; }

private:
    ArkUI_NativeNodeAPI_1 *nodeApi_ = nullptr;
    ArkUI_NodeHandle childNode_ = nullptr;
    bool isAttached_ = false;
};
```

### 2. 折叠面板条件渲染（C-API）

```cpp
// CollapsiblePanel.h
// C-API 折叠面板：展开时创建内容节点，折叠时销毁

class CollapsiblePanel {
public:
    CollapsiblePanel(ArkUI_NativeNodeAPI_1 *nodeApi)
        : nodeApi_(nodeApi), isExpanded_(false) {}

    ArkUI_NodeHandle Create() {
        // 创建标题栏（始终存在）
        panelNode_ = nodeApi_->createNode(ARKUI_NODE_COLUMN);

        auto titleRow = nodeApi_->createNode(ARKUI_NODE_ROW);
        auto titleText = nodeApi_->createNode(ARKUI_NODE_TEXT);
        ArkUI_AttributeItem titleItem{nullptr, 0, "Panel Title"};
        nodeApi_->setAttribute(titleText, NODE_TEXT_CONTENT, &titleItem);
        nodeApi_->addChild(titleRow, titleText);

        auto toggleText = nodeApi_->createNode(ARKUI_NODE_TEXT);
        ArkUI_AttributeItem toggleItem{nullptr, 0, "Expand"};
        nodeApi_->setAttribute(toggleText, NODE_TEXT_CONTENT, &toggleItem);
        nodeApi_->addChild(titleRow, toggleText);

        nodeApi_->addChild(panelNode_, titleRow);
        return panelNode_;
    }

    // 展开：创建并挂载内容节点
    void Expand() {
        if (!isExpanded_) {
            contentNode_ = CreateHeavyContent();
            nodeApi_->addChild(panelNode_, contentNode_);
            isExpanded_ = true;
        }
    }

    // 折叠：从父节点移除并销毁（下树释放内存）
    void Collapse() {
        if (isExpanded_ && contentNode_ != nullptr) {
            nodeApi_->removeChild(panelNode_, contentNode_);
            nodeApi_->disposeNode(contentNode_);
            contentNode_ = nullptr;
            isExpanded_ = false;
        }
    }

private:
    ArkUI_NodeHandle CreateHeavyContent() {
        auto content = nodeApi_->createNode(ARKUI_NODE_COLUMN);
        // 创建重量级子节点（List/Image/Web 等）
        auto text = nodeApi_->createNode(ARKUI_NODE_TEXT);
        ArkUI_AttributeItem textItem{nullptr, 0, "Heavy Content"};
        nodeApi_->setAttribute(text, NODE_TEXT_CONTENT, &textItem);
        nodeApi_->addChild(content, text);
        return content;
    }

    ArkUI_NativeNodeAPI_1 *nodeApi_ = nullptr;
    ArkUI_NodeHandle panelNode_ = nullptr;
    ArkUI_NodeHandle contentNode_ = nullptr;
    bool isExpanded_ = false;
};
```

### 3. 使用 NODE_VISIBILITY 隐藏（不推荐用于重型组件）

```cpp
// ⚠️ 不推荐：使用 NODE_VISIBILITY 隐藏重型组件
// 组件仍在节点树中，持续占用内存
// 仅适用于轻量组件或频繁切换（< 1s）的场景

void SetNodeHidden(ArkUI_NativeNodeAPI_1 *nodeApi, ArkUI_NodeHandle node) {
    // ARKUI_VISIBILITY_HIDDEN = 1: 隐藏但占位
    ArkUI_NumberValue val[] = {{.i32 = ARKUI_VISIBILITY_HIDDEN}};
    ArkUI_AttributeItem item = {val, 1};
    nodeApi->setAttribute(node, NODE_VISIBILITY, &item);
}

void SetNodeVisible(ArkUI_NativeNodeAPI_1 *nodeApi, ArkUI_NodeHandle node) {
    // ARKUI_VISIBILITY_VISIBLE = 0: 可见
    ArkUI_NumberValue val[] = {{.i32 = ARKUI_VISIBILITY_VISIBLE}};
    ArkUI_AttributeItem item = {val, 1};
    nodeApi->setAttribute(node, NODE_VISIBILITY, &item);
}

void SetNodeGone(ArkUI_NativeNodeAPI_1 *nodeApi, ArkUI_NodeHandle node) {
    // ARKUI_VISIBILITY_NONE = 2: 隐藏且不占位
    ArkUI_NumberValue val[] = {{.i32 = ARKUI_VISIBILITY_NONE}};
    ArkUI_AttributeItem item = {val, 1};
    nodeApi->setAttribute(node, NODE_VISIBILITY, &item);
}
```

### C-API 关键 API 映射

| C-API | 说明 | 适用场景 |
|-------|------|---------|
| `nodeApi->addChild(parent, child)` | 挂载子节点 | 条件渲染（if true） |
| `nodeApi->removeChild(parent, child)` | 移除子节点 | 条件卸载（if false） |
| `nodeApi->disposeNode(node)` | 销毁节点释放内存 | 配合 removeChild 完全释放 |
| `NODE_VISIBILITY` | 可见性控制 | 轻量组件或频繁切换 |

## 注意事项

- 频繁切换（< 1s）的组件不建议用 if 下树，反复创建销毁影响体验和性能
- 下树后状态不自动保持，需要用 `@State` 变量手动保存/恢复关键数据
- 动画过渡中的组件必须保持 in-tree，动画完成后再下树
- 轻量组件（< 1KB）下树收益不大，不建议优化
- `aboutToDisappear` 中应清理组件持有的资源（Timer/监听器等），与方案三（资源泄漏修复）配合使用
- 本方案与方案六（Tabs 缓存分档）互补：方案六控制 TabContent 缓存数量，本方案控制 TabContent 内部的条件渲染
- **C-API 注意**：`disposeNode` 会完全销毁节点及其所有子节点，之后不可再使用该 handle，如需重新显示必须重新创建
- **C-API 注意**：`removeChild` 仅从父节点移除但不释放内存，需配合 `disposeNode` 才能真正释放
- **C-API 注意**：C-API 没有自动的 `aboutToDisappear` 生命周期回调，需在 `removeChild` / `disposeNode` 前手动清理所有持有的资源（Timer、监听器、Native 指针等）
