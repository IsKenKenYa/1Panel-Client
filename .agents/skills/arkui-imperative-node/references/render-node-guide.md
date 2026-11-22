# RenderNode 使用指导

> 对应规格 R-9。指导开发者完成 RenderNode 接入骨架代码生成。

## 概述

RenderNode 是更轻量的渲染节点，仅具备与渲染相关的功能。提供渲染属性设置（背景色、不透明度、变换、阴影、边框等）、节点树操作（增删查改）和自定义绘制能力。不参与布局和事件。适合不具备自身渲染环境的三方框架，需依赖系统基础渲染和动画的场景。

**API 版本：** 12+（`isDisposed` 为 20+）

---

## 核心结构

```
创建 → FrameNode.getRenderNode 挂载 → 设置渲染属性 / draw 绘制 → dispose
```

### 1. 创建

```typescript
new RenderNode()
```

- 构造函数无参数，创建后对应一个实体节点。
- 可继承 RenderNode 重写 `draw(context: DrawContext)` 实现自定义绘制。

### 2. 挂载

```typescript
// 通过 FrameNode 的 getRenderNode 获取根 RenderNode，再 appendChild 挂载
const frameNode = new FrameNode(uiContext);
const rootRenderNode = frameNode.getRenderNode();
if (rootRenderNode !== null) {
  rootRenderNode.appendChild(renderNode);
}
```

- **RenderNode 需通过 FrameNode 的 `getRenderNode()` 上树显示，不能独立上树。**
- RenderNode 的子树结构由开发者通过 `appendChild` 传入的参数构建。

### 3. 设置渲染属性

| 属性 | 类型 | 说明 |
|---|---|---|
| `frame` | `Frame` | 大小和位置（x/y/width/height） |
| `size` | `Size` | 大小（与 frame 同时用时以后设置的为准） |
| `position` | `Position` | 位置（与 frame 同时用时以后设置的为准） |
| `backgroundColor` | `number` | 背景色，ARGB 格式，默认 0x00000000 |
| `clipToFrame` | `boolean` | 是否剪裁到组件区域，默认 true |
| `opacity` | `number` | 不透明度 [0,1]，默认 1 |
| `pivot` | `Pivot` | 轴心，影响缩放和旋转，默认 {0.5, 0.5} |
| `scale` | `Scale` | 缩放比例，默认 {1, 1} |
| `translation` | `Translation` | 平移量，默认 {0, 0} |
| `rotation` | `Rotation` | 旋转角度，默认 {0, 0, 0} |
| `transform` | `Matrix4` | 变换矩阵，默认单位矩阵 |
| `shadowColor` | `number` | 阴影颜色 ARGB |
| `shadowOffset` | `Offset` | 阴影偏移 |
| `shadowAlpha` | `number` | 阴影 Alpha [0,1] |
| `shadowElevation` | `number` | 阴影光照高度 (vp) |
| `shadowRadius` | `number` | 阴影模糊半径 (vp) |
| `borderStyle` | `Edges<BorderStyle>` | 边框样式，默认 Solid |
| `borderWidth` | `Edges<number>` | 边框宽度 (vp) |
| `borderColor` | `Edges<number>` | 边框颜色 ARGB |
| `borderRadius` | `BorderRadiuses` | 边框圆角 (vp) |
| `shapeMask` | `ShapeMask` | 遮罩 |
| `shapeClip` | `ShapeClip` | 裁剪形状 |
| `markNodeGroup` | `boolean` | 是否优先绘制（半透明合成），默认 false |
| `label` | `string` | 标签（Inspector 显示），默认 "" |

### 4. draw 绘制（可选）

```typescript
class MyRenderNode extends RenderNode {
  draw(context: DrawContext) {
    const canvas = context.canvas;
    // 使用 drawing API 进行自定义绘制
  }
}
```

- 重写 `draw(context: DrawContext)` 实现自定义绘制。
- `invalidate()` 触发重新绘制（重新调用 draw）。
- 同时同步触发多个 `invalidate()` 仅触发一次重新绘制。
- DrawContext 中的 Canvas 是记录指令的临时 Canvas，变换矩阵应使用 `concatMatrix` 而非 `setMatrix`。

### 5. dispose

```typescript
dispose(): void
```

- 解除与后端实体节点的引用关系。
- dispose 后再次调用接口可能出现 crash 或返回默认值。
- `isDisposed()`（API 20+）可查询是否已解除引用。

---

## 关键约束

| 约束 | 说明 |
|---|---|
| 需通过 FrameNode 的 getRenderNode 上树显示 | 不能独立上树，必须挂载到 FrameNode 的 RenderNode 下 |
| 比 FrameNode 更轻量 | 仅渲染相关，不参与布局（无 onMeasure/onLayout）和事件（无事件回调） |
| 颜色用 ARGB 数字格式 | `setColor(0xAARRGGBB)` 用数字，**不要用对象字面量** `{ alpha, red, green, blue }`（ArkTS 禁止无类型对象字面量，编译报错 arkts-no-untyped-obj-literals） |
| 不建议修改 BuilderNode 的 RenderNode | BuilderNode 属性由状态管理驱动，时序不可控，同时设置可能不符预期 |
| 属性默认值 | 未传入参数或非法值时返回默认值 |
| 不支持 JSON 序列化 | RenderNode 对象不支持 JSON 序列化 |
| 单位 | 默认使用 vp，可通过 `lengthMetricsUnit` 设置为 PX |

---

## 节点树操作

| 操作 | 接口 |
|---|---|
| 添加子节点（末尾） | `appendChild(node: RenderNode)` |
| 在指定子节点后插入 | `insertChildAfter(child: RenderNode, sibling: RenderNode \| null)` |
| 删除子节点 | `removeChild(node: RenderNode)` |
| 清除所有子节点 | `clearChildren()` |
| 获取指定位置子节点 | `getChild(index: number)` |
| 获取首个子节点 | `getFirstChild()` |
| 获取兄弟节点 | `getNextSibling()` / `getPreviousSibling()` |

---

## 代码示例

```typescript
import { FrameNode, NodeController, RenderNode, UIContext } from '@kit.ArkUI';
import { drawing } from '@kit.ArkGraphics2D';

// 自定义绘制 RenderNode
class MyRenderNode extends RenderNode {
  public width: number = 200;

  draw(context: DrawContext) {
    const canvas = context.canvas;
    const brush = new drawing.Brush();
    brush.setColor(0xFF519DB4);
    canvas.attachBrush(brush);
    canvas.drawRect({ left: 0, right: this.width, top: 0, bottom: 200 });
    canvas.detachBrush();
  }
}

class MyNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private renderNode: MyRenderNode | null = null;

  makeNode(uiContext: UIContext): FrameNode | null {
    // 1. 创建 FrameNode 作为载体
    this.rootNode = new FrameNode(uiContext);

    // 2. 创建 RenderNode 并设置渲染属性
    this.renderNode = new MyRenderNode();
    this.renderNode.frame = { x: 0, y: 0, width: 300, height: 300 };
    this.renderNode.backgroundColor = 0xffd5d5d5;
    this.renderNode.opacity = 0.5;

    // 3. 通过 FrameNode.getRenderNode 挂载上树
    const rootRenderNode = this.rootNode.getRenderNode();
    if (rootRenderNode !== null) {
      rootRenderNode.frame = { x: 0, y: 0, width: 500, height: 500 };
      rootRenderNode.appendChild(this.renderNode);
    }

    return this.rootNode;
  }

  // 4. 触发重绘
  invalidate() {
    if (this.renderNode) {
      this.renderNode.width += 10;
      this.renderNode.invalidate();
    }
  }

  // 5. dispose
  disposeNodes() {
    this.renderNode?.dispose();
    this.rootNode?.dispose();
    this.renderNode = null;
    this.rootNode = null;
  }
}

@Entry
@Component
struct RenderNodePage {
  private controller: MyNodeController = new MyNodeController();

  build() {
    Column() {
      NodeContainer(this.controller)
        .width('100%')
        .height(320)
      Button('Invalidate')
        .onClick(() => {
          this.controller.invalidate();
        })
    }
  }
}
```

> **API 版本：** 12+
