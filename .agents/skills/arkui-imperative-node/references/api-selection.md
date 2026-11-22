# API 选型决策矩阵

> 对应规格 R-4 / R-5 / R-6。用于在确认需要命令式节点后，选择 BuilderNode / FrameNode / RenderNode 之一。

## 概述

三个命令式节点 API 的核心区分维度：是否需要声明式构建内部树、是否需要自定义测量/布局/绘制、是否仅需要渲染。按下表决策矩阵匹配开发者需求维度，推荐最合适的 API。

---

## 决策矩阵

| 能力维度 | BuilderNode | FrameNode | RenderNode |
|---|---|---|---|
| 整体控制节点树（作为整体挂载/管理） | ✅ 支持 | ✅ 支持 | ❌ 不支持 |
| 内部树命令式控制（增删查改子节点） | ❌ 内部树由 @Builder 声明式构建 | ✅ 支持 | ✅ 支持（仅渲染树） |
| 内部树声明式构建（@Builder） | ✅ 支持 | ❌ 不支持 | ❌ 不支持 |
| 自定义测量（onMeasure） | ❌ 不支持 | ✅ 支持 | ❌ 不支持 |
| 自定义布局（onLayout） | ❌ 不支持 | ✅ 支持 | ❌ 不支持 |
| 自定义绘制（draw / onDraw） | ❌ 不支持 | ✅ 支持（onDraw） | ✅ 支持（draw） |
| 通用属性设置（width/height/position 等） | ❌ 通过 @Builder 内声明式设置 | ✅ 支持（commonAttribute） | ✅ 支持（渲染属性） |
| 通用事件回调（onClick/onTouch 等） | ❌ 通过 @Builder 内声明式设置 | ✅ 支持（commonEvent） | ❌ 不支持 |
| 状态管理（@Prop/@Observed 等） | ✅ 支持 | ❌ 不支持 | ❌ 不支持 |
| 纹理导出（同层渲染） | ✅ 支持（RENDER_TYPE_TEXTURE） | ❌ 不支持 | ❌ 不支持 |
| 事件注入（postTouchEvent） | ✅ 支持 | ✅ 支持（dispatchInputEvent） | ❌ 不支持 |
| 组件预创建 | ✅ 支持 | ✅ 支持 | ✅ 支持 |
| 轻量程度 | 中 | 重（含布局+事件） | 最轻（仅渲染） |
| 最低 API 版本 | 12+ | 12+ | 12+ |

---

## R-4: BuilderNode 选型

**适用条件：** 开发者需求为"整体控制节点树、内部树结构用 @Builder 声明式构建、使用状态管理能力"。

**决策依据：** BuilderNode 适合需要整体管理一棵组件树（创建、挂载、更新、释放），但内部树结构本身用声明式 `@Builder` 构建并依赖状态管理（`@Prop` / `@Observed` / `@ObjectLink`）驱动更新的场景。BuilderNode 仅可作为叶子节点使用——它持有一棵完整的声明式组件树，但自身不参与内部树的命令式增删。

**优势：**
- 内部树用 `@Builder` 声明式构建，开发效率高。
- 支持状态管理装饰器（`@Prop`，API 12+ 支持 `@LocalStorageProp`/`@LocalStorageLink`）。
- 支持组件预创建，优化初始化耗时（Web、XComponent 等）。
- 支持纹理导出（`RENDER_TYPE_TEXTURE`），可与 XComponent 实现同层渲染。
- 支持 `update(arg)` 触发数据更新，`reuse`/`recycle` 传递复用事件。

**限制：**
- 仅支持一个 `wrapBuilder` 包装的 `@Builder`，最多一个入参。
- 仅可作为叶子节点，内部树不可命令式增删。
- `build` 后才能 `getFrameNode`，否则返回 null。
- 子节点不支持 `@Reusable` 装饰器（会导致 JSCrash）。
- 不支持 `@Link` 跨 BuilderNode 同步数据。
- 不建议通过获取的 RenderNode 修改属性（状态管理时序不可控）。

**API 版本：** 12+

---

## R-5: FrameNode 选型

**适用条件：** 开发者需求为"对内部树形结构进行命令式控制（增删查改）、自定义测量/布局/绘制"。

**决策依据：** FrameNode 表示组件树中的实体节点，支持节点树增删查改（`appendChild` / `removeChild` / `insertChildAfter` / `clearChildren` / `getChild`）、通用属性和事件设置（`commonAttribute` / `commonEvent`）、以及完整的自定义能力（`onMeasure` / `onLayout` / `onDraw`）。适合第三方框架（JSON/XML/DOM 驱动）需要命令式控制节点树结构并自定义布局的场景。FrameNode 可配合 BuilderNode 实现混合显示（FrameNode 树中嵌入声明式组件）。

**优势：**
- 完整的节点树命令式操作（增删查改、`moveTo` 跨父节点迁移）。
- 通用属性和事件设置（`commonAttribute` / `commonEvent` / `gestureEvent`）。
- 自定义测量（`onMeasure`）、布局（`onLayout`）、绘制（`onDraw`）。
- 可获取关联的 RenderNode 进行渲染属性操作。
- 支持 `typeNode.createNode` 创建具体类型的 FrameNode（Column/Row/Text 等）。
- 代理节点可遍历系统组件树、查询节点信息、注册事件监听。

**限制：**
- 构造需传入 UIContext，否则创建抛出异常。
- 代理节点（`isModifiable()` 返回 false）不可修改属性和子树结构。
- 无法获取系统组件代理节点的 RenderNode。
- 自定义测量/布局/绘制需通过继承 FrameNode 重写 `onMeasure`/`onLayout`/`onDraw`。
- 自定义绘制内容无法超出组件大小。

**API 版本：** 基础能力 12+；`moveTo` 18+。

---

## R-6: RenderNode 选型

**适用条件：** 开发者需求为"仅需渲染属性设置与自定义绘制、不参与布局和事件"。

**决策依据：** RenderNode 是最轻量的渲染节点，仅具备渲染相关功能。它不参与布局（无 `onMeasure`/`onLayout`）、不处理事件（无事件回调）、不设置通用属性（无 `commonAttribute`/`commonEvent`）。适合不具备自身渲染环境的三方框架，仅需系统基础渲染和动画支持的场景。RenderNode 需通过 FrameNode 的 `getRenderNode()` 挂载上树才能显示。

**优势：**
- 最轻量，仅渲染相关属性，无布局和事件开销。
- 丰富的渲染属性：`backgroundColor` / `opacity` / `frame` / `scale` / `rotation` / `transform` / `shadow` / `border` / `shapeMask` / `shapeClip` 等。
- 支持自定义绘制（重写 `draw(context: DrawContext)`）。
- 支持渲染节点树操作（`appendChild` / `removeChild` 等）。
- 支持通过 `invalidate()` 触发重绘。
- 可设置 `label` 便于 Inspector 区分节点。

**限制：**
- 需通过 FrameNode 的 `getRenderNode()` 挂载上树显示，不能独立上树。
- 不参与布局，无测量和布局能力。
- 不参与事件，无事件回调。
- 不建议对 BuilderNode 中获取的 RenderNode 进行修改操作（可能导致显示异常）。

**API 版本：** 12+

---

## 选型决策流程

```
确认需要命令式节点
    │
    ├─ 内部树需要 @Builder 声明式构建 + 状态管理？ ──是──→ R-4: BuilderNode
    │        │否
    ├─ 需要命令式控制内部子树结构 + 自定义测量/布局？ ──是──→ R-5: FrameNode
    │        │否
    ├─ 仅需渲染属性 + 自定义绘制，不需布局和事件？ ──是──→ R-6: RenderNode
    │        │否
    └─ 混合需求：BuilderNode（声明式子树）+ FrameNode（命令式容器）+ RenderNode（自定义绘制）
```

> **混合使用：** 三者可组合使用。典型混合模式：FrameNode 作为根节点容器，BuilderNode 挂载声明式组件树到 FrameNode 子节点，RenderNode 挂载到 FrameNode 的 getRenderNode() 实现自定义绘制叠加。
