# FrameNode 使用指导

> 对应规格 R-8。指导开发者完成 FrameNode 接入骨架代码生成。

## 概述

FrameNode 表示组件树中的实体节点，支持节点树操作（增删查改）、通用属性和事件设置、自定义测量/布局/绘制。与 NodeContainer 配合在占位容器内构建自定义节点树。支持获取系统组件代理 FrameNode 用于遍历 UI 树和注册事件监听。

**API 版本：** 基础能力 12+（`moveTo` 18+，`isDisposed` 20+）

---

## 核心结构

```
创建 → 挂载 → getRenderNode 关联（可选）→ 自定义测量/布局/绘制（可选）→ dispose
```

### 1. 创建

```typescript
new FrameNode(uiContext: UIContext)
```

- `uiContext`：必传，UI 上下文。未传入或传入不合法会抛出异常。
- 自定义测量/布局/绘制需继承 FrameNode 重写 `onMeasure` / `onLayout` / `onDraw`。
- 若不持有 FrameNode 对象，该对象会在 GC 时被回收。

### 2. 挂载

```typescript
// 方式一：通过 NodeController.makeNode 返回，配合 NodeContainer 显示
class MyNodeController extends NodeController {
  makeNode(uiContext: UIContext): FrameNode | null {
    this.rootNode = new FrameNode(uiContext);
    return this.rootNode;
  }
}

// 方式二：通过 appendChild 挂载到其他 FrameNode 下
parentFrameNode.appendChild(childFrameNode);
```

- 通过 NodeController 的 `makeNode` 返回根 FrameNode，配合 `NodeContainer` 显示。
- 自定义占位组件显示时需保证 UI 上下文一致，否则显示异常。
- `appendChild` / `insertChildAfter` 要求子节点无父节点，否则抛出异常。

### 3. getRenderNode 关联（可选）

```typescript
getRenderNode(): RenderNode | null
```

- 获取 FrameNode 持有的 RenderNode，可动态修改渲染相关属性。
- 无法获取系统组件代理 FrameNode 的 RenderNode（返回 null）。
- BuilderNode 中 `getFrameNode()` 获取的 FrameNode 可通过 `getRenderNode()` 获取根节点 RenderNode。

### 4. 自定义测量/布局/绘制（可选）

| 方法 | 说明 |
|---|---|
| `onMeasure(constraint: LayoutConstraint)` | 重写测量方法，计算节点及内容大小 |
| `onLayout(position: Position)` | 重写布局方法，为节点及子节点指定位置 |
| `onDraw?(context: DrawContext)` | 重写绘制方法，自定义绘制内容（不可超出组件大小） |
| `setMeasuredSize(size: Size)` | 设置测量结果，建议在 onMeasure 中调用 |
| `setLayoutPosition(position: Position)` | 设置布局结果，建议在 onLayout 中调用 |
| `measure(constraint: LayoutConstraint)` | 主动触发测量，建议在 onMeasure 中调用 |
| `layout(position: Position)` | 主动触发布局，建议在 onLayout 中调用 |
| `setNeedsLayout()` | 标记下一帧重新布局 |
| `invalidate()` | 触发重新绘制（重新调用 onDraw） |

**LayoutConstraint 属性（onMeasure 入参）：**

| 属性 | 类型 | 说明 |
|---|---|---|
| `maxSize` | `Size` | 父容器允许的最大尺寸，通过 `maxSize.width` / `maxSize.height` 访问 |
| `minSize` | `Size` | 父容器要求的最小尺寸，通过 `minSize.width` / `minSize.height` 访问 |
| `percentReference` | `Size` | 子节点计算百分比时的尺寸基准 |

> **注意：** `LayoutConstraint` 没有 `maxWidth` / `maxHeight` 属性，使用 `maxSize.width` / `maxSize.height`。`maxSize.width` 可能为 `Infinity`（无限制），需判空兜底。

### 5. dispose

```typescript
dispose(): void        // 解除当前节点引用
disposeTree(): void    // 下树并递归释放子树
```

- dispose 后不再对应实体节点，调用部分查询接口可能导致 JSCrash。
- 可通过 `getUniqueId()` 判断是否对应实体节点（UniqueID > 0 表示对应实体节点）。
- `isDisposed()`（API 20+）可查询是否已解除引用。

---

## 关键能力

### 节点树增删查改

| 操作 | 接口 |
|---|---|
| 添加子节点（末尾） | `appendChild(node: FrameNode)` |
| 在指定子节点后插入 | `insertChildAfter(child: FrameNode, sibling: FrameNode \| null)` |
| 删除子节点 | `removeChild(node: FrameNode)` |
| 清除所有子节点 | `clearChildren()` |
| 获取指定位置子节点 | `getChild(index: number)` |
| 获取首个子节点 | `getFirstChild()` |
| 获取子节点数量 | `getChildrenCount()` |
| 获取父节点 | `getParent()` |
| 获取兄弟节点 | `getNextSibling()` / `getPreviousSibling()` |
| 移动到新父节点 | `moveTo(targetParent: FrameNode, index?: number)` (API 18+) |

### 通用属性和事件

| 对象 | 说明 |
|---|---|
| `commonAttribute` | 设置通用属性（width/height/position/backgroundColor 等） |
| `commonEvent` | 设置基础事件回调（onClick/onTouch 等），与声明式事件平行参与竞争 |
| `gestureEvent` | 设置手势事件 (API 14+) |

### 节点信息查询

| 查询 | 接口 |
|---|---|
| 节点类型 | `getNodeType()` |
| 节点 ID | `getId()` / `getUniqueId()` |
| 测量大小 | `getMeasuredSize()` |
| 布局位置 | `getLayoutPosition()` |
| 相对窗口位置 | `getPositionToWindow()` |
| 相对父组件位置 | `getPositionToParent()` |
| 相对屏幕位置 | `getPositionToScreen()` |
| 用户配置大小 | `getUserConfigSize()` |
| 可见性 | `isVisible()` |
| 是否挂载 | `isAttached()` |
| Inspector 信息 | `getInspectorInfo()` |

---

## 关键约束

| 约束 | 说明 |
|---|---|
| 创建需传入 UIContext | 未传入或传入不合法会抛出异常 |
| isModifiable 判断是否为代理节点 | 代理节点（系统组件代理）不可修改属性和子树 |
| 代理节点不可修改 | `isModifiable()` 返回 false 时，appendChild/removeChild 等操作抛出异常 |
| 代理节点不可获取 RenderNode | 系统组件代理 FrameNode 的 `getRenderNode()` 返回 null |
| 增删改对非法操作抛异常 | 不可修改节点、子节点有父节点、参数无效等情况抛出异常 |
| 查询仅返回 UI 节点 | 不返回语法节点（ForEach/if-else 等不作为可查询节点） |
| 自定义组件可能产生 __Common__ 节点 | 使用自定义组件时可能查询到 `__Common__` 类型节点 |
| 不支持预览器 | FrameNode 不支持在预览器中使用 |
| 不支持拖拽 | FrameNode 节点暂不支持拖拽 |
| 不支持 JSON 序列化 | FrameNode 对象不支持 JSON 序列化 |
| 颜色用 ARGB 数字格式 | `setColor(0xAARRGGBB)` 用数字，**不要用对象字面量** `{ alpha, red, green, blue }`（ArkTS 禁止无类型对象字面量，编译报错 arkts-no-untyped-obj-literals） |

---

## 代码示例

```typescript
import { FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class MyNodeController extends NodeController {
  public rootNode: FrameNode | null = null;
  public childNode: FrameNode | null = null;

  makeNode(uiContext: UIContext): FrameNode | null {
    // 1. 创建根节点
    this.rootNode = new FrameNode(uiContext);
    this.rootNode.commonAttribute
      .width('100%')
      .height(100)
      .backgroundColor(Color.Gray);

    // 创建子节点并挂载
    this.childNode = new FrameNode(uiContext);
    this.childNode.commonAttribute
      .width(50)
      .height(50)
      .backgroundColor(Color.Pink);
    this.rootNode.appendChild(this.childNode);

    // 2. 挂载（通过 makeNode 返回，配合 NodeContainer 显示）
    return this.rootNode;
  }

  // 3. dispose
  disposeNodes() {
    this.rootNode?.disposeTree();
    this.rootNode = null;
    this.childNode = null;
  }
}

@Entry
@Component
struct FrameNodePage {
  private controller: MyNodeController = new MyNodeController();

  build() {
    Column() {
      NodeContainer(this.controller)
        .width('100%')
        .height(100)
    }
  }
}
```

### 自定义测量/布局/绘制示例

```typescript
import { FrameNode, NodeController, UIContext, LayoutConstraint, Position, Size, DrawContext } from '@kit.ArkUI';
import { drawing } from '@kit.ArkGraphics2D';

class MyFrameNode extends FrameNode {
  constructor(uiContext: UIContext) {
    super(uiContext);
  }

  // 自定义测量
  onMeasure(constraint: LayoutConstraint): void {
    // maxSize.width 可能为 Infinity，需兜底
    const width = constraint.maxSize.width === Infinity ? 320 : constraint.maxSize.width;
    let height = 100;
    for (let i = 0; i < this.getChildrenCount(); i++) {
      let child = this.getChild(i);
      if (child) {
        child.measure(constraint);
        let measured = child.getMeasuredSize();
        size.height += measured.height;
      }
    }
    this.setMeasuredSize({ width, height });
  }

  // 自定义布局
  onLayout(position: Position): void {
    for (let i = 0; i < this.getChildrenCount(); i++) {
      let child = this.getChild(i);
      if (child) {
        child.layout({ x: 0, y: 0 });
      }
    }
    this.setLayoutPosition(position);
  }

  // 自定义绘制
  onDraw(context: DrawContext) {
    const canvas = context.canvas;
    const pen = new drawing.Pen();
    pen.setStrokeWidth(15);
    pen.setColor(0xFFFF0000);
    canvas.attachPen(pen);
    canvas.drawRect({ left: 10, right: 100, top: 10, bottom: 100 });
    canvas.detachPen();
  }
}
```

> **API 版本：** 基础能力 12+；`moveTo` 18+
