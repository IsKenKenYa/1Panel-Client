# BuilderNode 使用指导

> 对应规格 R-7。指导开发者完成 BuilderNode 接入骨架代码生成。

## 概述

BuilderNode 提供能够挂载系统组件的自定义节点能力，支持通过无状态 UI 方法 `@Builder` 定制组件树，具备组件预创建、纹理导出、节点复用与回收等能力。BuilderNode 仅可作为叶子节点使用。

**API 版本：** 12+（`inheritFreezeOptions` / `isDisposed` 为 20+，`postInputEvent` 为 20+）

---

## 核心结构

```
创建 → build → 挂载 → update（可选）→ dispose
```

### 1. 创建

```typescript
new BuilderNode(context: UIContext, options?: RenderOptions)
```

- `uiContext`：必传，UI 上下文。传入非法值或未设置会导致创建失败。
- `RenderOptions.selfIdealSize`：当将 BuilderNode 内容嵌入到其他 RenderNode 中显示时需显式指定，否则默认布局约束为 [0, 0]。
- `RenderOptions.type`：渲染类型，`RENDER_TYPE_DISPLAY`（默认，显示到屏幕）或 `RENDER_TYPE_TEXTURE`（导出为纹理）。
- BuilderNode 是模板类，创建时需指定类型，类型需与后续 build 中 WrappedBuilder 类型一致。

### 2. build

```typescript
build(builder: WrappedBuilder<Args>, arg?: Object): void
build(builder: WrappedBuilder<Args>, arg: Object, options: BuildOptions): void
```

- 传入 `wrapBuilder` 包装的 `@Builder` 函数和参数，创建组件树并持有根节点。
- `@Builder` 最多拥有一个根节点，支持一个入参。
- `@Builder` 嵌套使用时需保证内外入参对象一致；入参类型不一致时需增加 `BuildOptions.nestingBuilderSupported` 字段。
- build 的参数是值传递，更新需使用 `update` 接口。
- **build 后才能 getFrameNode，否则返回 null。**

### 3. 挂载

```typescript
getFrameNode(): FrameNode | null
```

- build 后调用 `getFrameNode()` 获取根 FrameNode 对象。
- 通过 `NodeController.makeNode()` 返回该 FrameNode，配合 `NodeContainer` 挂载显示。
- 也可通过 `FrameNode.appendChild()` 挂载到其他 FrameNode 节点下。
- 若通过 `getRenderNode()` 挂载到 RenderNode 树上，需显式指定 `selfIdealSize`（不推荐此方式）。

### 4. update（可选）

```typescript
update(arg: Object): void
```

- 使用与 build 相同类型的参数更新 BuilderNode 中的节点。
- 自定义组件中需更新的变量应定义为 `@Prop`。
- 冻结态下 update 不生效（正常行为，需解冻后再调用）。

### 5. dispose

```typescript
dispose(): void
```

- 解除 BuilderNode 与后端实体节点的引用关系。
- dispose 后 FrameNode 和 RenderNode 也会同步解除引用。
- **不再需要时主动调用 dispose，防止内存泄漏。**
- dispose 后可通过 `isDisposed()`（API 20+）查询是否已解除引用。

---

## 关键约束

| 约束 | 说明 |
|---|---|
| 仅支持一个 wrapBuilder 包装的 @Builder | 无状态 UI 方法 @Builder 最多一个根节点，一个入参 |
| build 后才能 getFrameNode | build 前调用返回 null |
| 仅可作为叶子节点 | BuilderNode 持有完整声明式组件树，自身不参与内部树命令式增删 |
| 不建议通过 RenderNode 修改属性 | BuilderNode 属性由状态管理驱动，时序不可控，同时设置可能不符预期 |
| 子节点不支持 @Reusable | BuilderNode 复用机制与 @Reusable 冲突，直接子节点用 @Reusable 会 JSCrash |
| 不支持 @Link 跨 BuilderNode 同步 | 支持 @Prop，不支持 @Link 跨界同步 |
| BuilderProxyNode | @Builder 根为语法节点（if/else/foreach）或自定义组件时额外生成 FrameNode，影响事件传递 |
| 不支持预览器 | BuilderNode 不支持在预览器中使用 |
| 不支持 JSON 序列化 | BuilderNode 对象不支持 JSON 序列化 |

---

## BuilderProxyNode 说明

当传入的 `@Builder` 根节点为语法节点（`if/else`/`ForEach`/`LazyForEach`/`ContentSlot` 等）、`Span`/`ContainerSpan`/`SymbolSpan` 或自定义组件时，会额外生成一个 FrameNode，在节点树中显示为 "BuilderProxyNode"。

**影响：** BuilderProxyNode 无法设置属性，可能导致触摸测试等事件传递流程异常。

**规避方案：**
1. 用容器组件（如 `Stack`）包裹语法节点或自定义组件，避免生成 BuilderProxyNode。
2. 对自定义组件直接设置属性，会生成 `__Common__` 节点，同样可避免 BuilderProxyNode。

---

## 代码示例

```typescript
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  public text: string = '';
  constructor(text: string) {
    this.text = text;
  }
}

@Builder
function buildText(params: Params) {
  Column() {
    Text(params.text)
      .fontSize(50)
      .fontWeight(FontWeight.Bold)
  }
}

class TextNodeController extends NodeController {
  private textNode: BuilderNode<[Params]> | null = null;
  private message: string = 'DEFAULT';

  constructor(message: string) {
    super();
    this.message = message;
  }

  makeNode(context: UIContext): FrameNode | null {
    // 1. 创建
    this.textNode = new BuilderNode(context);
    // 2. build
    this.textNode.build(wrapBuilder<[Params]>(buildText), new Params(this.message));
    // 3. 挂载（通过 makeNode 返回 FrameNode，配合 NodeContainer 显示）
    return this.textNode.getFrameNode();
  }

  // 4. update（可选）
  update(message: string) {
    if (this.textNode !== null) {
      this.textNode.update(new Params(message));
    }
  }

  // 5. dispose
  disposeNode() {
    this.textNode?.dispose();
    this.textNode = null;
  }
}

@Entry
@Component
struct BuilderNodePage {
  @State message: string = 'hello';
  private controller: TextNodeController = new TextNodeController(this.message);

  build() {
    Column() {
      NodeContainer(this.controller)
        .width('100%')
        .height(100)
    }
  }
}
```

> **API 版本：** 12+

## 装饰器使用限制与 V1/V2 区分

BuilderNode 的 `@Builder` 内部可以使用 `@Component` 和 `@ComponentV2` 装饰的自定义组件，但装饰器使用有以下限制和区分：

| 装饰器 | 支持？ | 说明 | API 版本 |
|--------|--------|------|---------|
| `@Component`（V1 普通组件） | ✅ 支持 | 正常使用 | 12+ |
| `@ComponentV2`（V2 普通组件） | ✅ 支持 | 正常使用，包括 @Param/@Local/@Monitor/@Computed 等 V2 状态管理 | 12+ |
| `@Reusable`（V1 复用） | ❌ 不支持 | BuilderNode 直接子组件使用会导致 JSCrash，需用普通组件包裹 | 12+ |
| `@ReusableV2`（V2 复用） | ❌ 不支持 | 实测同样 JSCrash，与 @Reusable 行为一致，需用普通组件包裹 | 12+ |
| `@Link` / `@Provide` / `@Consume` | ❌ 不支持 | BuilderNode 隔断状态同步链路，需改用 @Prop 或参数传递 | 12+ |

**V1/V2 复用关键区分：**
- `@Reusable` + `@Component`（V1）→ BuilderNode 直接子组件使用会导致 JSCrash，必须用普通组件包裹
- `@ReusableV2` + `@ComponentV2`（V2）→ 实测同样 JSCrash，与 @Reusable 行为一致，也必须用普通组件包裹
- 虽然 API 文档标注 @ReusableV2 从 API 26 开始在 BuilderNode 内支持，但实测仍会 JSCrash，建议 V1/V2 统一用普通组件包裹方案
- 若需传递复用事件，通过 BuilderNode 的 `reuse(params)` / `recycle()` 接口手动传递（V1 和 V2 均适用）

**参考文档：**
- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："BuilderNode 在子自定义组件中使用 @Reusable 装饰器"章节
- [@ReusableV2 装饰器](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-reusableV2.md)
