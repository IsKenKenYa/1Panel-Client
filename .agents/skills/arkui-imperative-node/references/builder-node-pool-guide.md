# BuilderNode 池管理指导

## 适用场景

当开发者需要管理多个 BuilderNode，在不同 NodeContainer 位置动态挂载/卸载/转移时，使用本指导生成池管理框架。

## 核心架构

```
NodePool（单例，管理多个 BuilderNode）
  ├── getNode(type, data, builder) → 获取或新建 NodeItem
  ├── recycleNode(type, node) → 回收到池中
  └── disposeAll() → 统一销毁

NodeItem extends NodeController（每个 NodeContainer 绑定一个）
  ├── makeNode(context) → 创建/复用 BuilderNode，返回 getFrameNode()
  ├── update(data) → 更新 BuilderNode 内容
  ├── rebuild() → 通知 NodeContainer 重新调用 makeNode
  └── aboutToDisappear() → 自动回收到 NodePool

NodeContainer × N（多个占位容器，各自绑定独立 NodeItem）
```

## 关键机制

### 1. 统一生命周期管理

| 操作 | 方法 | 说明 |
|------|------|------|
| 创建 | `new BuilderNode(context)` + `build(wrapBuilder, data)` | 在 makeNode 中创建，或从池中复用 |
| 挂载 | makeNode 返回 `getFrameNode()` | NodeContainer 自动挂载 |
| 更新 | `builderNode.update(new Params(data))` | 更新内容 |
| 卸载 | makeNode 返回 `null` + `rebuild()` | 清空 NodeContainer 子节点 |
| 回收 | `aboutToDisappear` → `recycleNode` | NodeContainer 从树卸载时自动回收 |
| 销毁 | `builderNode.dispose()` | 彻底释放后端实体节点 |

### 2. 动态转移（从一个 NodeContainer 转到另一个）

转移四步（动作步骤，编号与下方示例注释一一对应）：
1. **接收方旧节点先释放**：若接收方 NodeItem 已持有 BuilderNode，先 `disposeNode()` 释放，防止引用被覆盖导致后端实体节点泄漏
2. **先取出待转移节点**：调用 `fromController.getBuilderNode()`——必须在 `unbind()` 之前取（unbind 会置空引用，之后再取拿到 null，转移失效变新建）
3. **旧容器解绑**：旧 NodeItem 调 `unbind()`（makeNode 返回 null + `rebuild()` 清空容器）
4. **新容器绑定并刷新内容**：新 NodeItem 调 `bindNode(node)` 接收，再用转出方内容 `updateData(data)` 刷新（否则接收方按自身旧数据刷新，转移不可见）

**禁止项**：不能不清空旧容器直接绑定到新容器（会导致双挂，节点不显示）。

```typescript
// 转移方法示例（与上述四步一致）
transferNode(fromController: NodeItem, toController: NodeItem, data: PoolParams) {
  // 1. 接收方已有节点时先释放，防止引用覆盖导致后端实体节点泄漏
  if (toController.getBuilderNode()) {
    toController.disposeNode();
  }
  // 2. 先取出待转移节点（必须在 unbind 之前取，unbind 会置空引用，之后再取拿到 null）
  const node = fromController.getBuilderNode();
  if (!node) {
    return;
  }
  // 3. 旧容器清空（makeNode 返回 null + rebuild）
  fromController.unbind();
  // 4. 新容器接收并刷新内容（内容随节点转移，转移可见）
  toController.bindNode(node);
  toController.updateData(data);
}
```

### 3. 每个 NodeContainer 绑定独立 controller

每个 NodeContainer 必须绑定独立的 NodeItem（NodeController），不能多个 NodeContainer 共用一个 controller。

### 4. 销毁的正确顺序（树上节点 + 池中节点）

`disposeAll()` **只销毁池中已回收的节点**。仍挂载在 NodeContainer 上的节点不在池中（回收依赖 `aboutToDisappear`，容器未移除就不会回池），必须先对树上的 controller 调 `disposeNode()` 并置 `undefined` 移除容器，最后再 `disposeAll()` 清池，三者缺一不可——只调 `disposeAll()` 对树上节点无效（页面仍显示）。

## 代码模板

```typescript
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

// 数据类型
class PoolParams {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

// @Builder 函数
@Builder
function buildContent(params: PoolParams) {
  Column() {
    Text(params.text).fontSize(20).fontWeight(FontWeight.Bold)
  }
}

// NodeItem：每个 NodeContainer 绑定一个
class NodeItem extends NodeController {
  private builderNode: BuilderNode<[PoolParams]> | null = null;
  private data: PoolParams;
  private type: string;
  private builder: WrappedBuilder<[PoolParams]>;
  // 解绑标志：true 时 makeNode 返回 null，NodeContainer 清空子节点（"卸载"机制核心）
  // 若无此标志，unbind() 置空引用后 rebuild() 会触发 makeNode 走新建分支，旧容器被重新填充而非清空
  private detached: boolean = false;

  constructor(builder: WrappedBuilder<[PoolParams]>, data: PoolParams, type: string) {
    super();
    this.builder = builder;
    this.data = data;
    this.type = type;
  }

  makeNode(context: UIContext): FrameNode | null {
    if (this.detached) {
      return null; // 解绑态：返回 null 清空 NodeContainer 子节点
    }
    if (!this.builderNode) {
      this.builderNode = new BuilderNode(context);
      this.builderNode.build(this.builder, this.data);
    } else {
      this.builderNode.update(this.data);
    }
    return this.builderNode.getFrameNode();
  }

  updateData(data: PoolParams) {
    this.data = data;
    this.builderNode?.update(data);
  }

  // 从池中复用前复位状态
  reset(data: PoolParams) {
    this.detached = false;
    this.updateData(data);
  }

  unbind() {
    // 清空 NodeContainer：makeNode 返回 null + rebuild；断开引用防止双挂
    this.detached = true;
    this.builderNode = null;
    this.rebuild();
  }

  bindNode(node: BuilderNode<[PoolParams]>) {
    this.detached = false;
    this.builderNode = node;
    this.rebuild();
  }

  getBuilderNode(): BuilderNode<[PoolParams]> | null {
    return this.builderNode;
  }

  disposeNode() {
    this.builderNode?.dispose();
    this.builderNode = null;
    this.detached = true;
  }

  aboutToDisappear(): void {
    NodePool.getInstance().recycleNode(this.type, this);
  }
}

// NodePool：单例管理
// 注意：使用 ArkTS 原生 Map（而非 @ohos.util.HashMap）——HashMap 无 has 方法（需用 hasKey），
// 且其 forEach 回调参数可选（会触发 possibly undefined 编译错误），原生 Map 无这些问题
class NodePool {
  private static instance: NodePool;
  private nodePool: Map<string, Array<NodeItem>> = new Map();

  private constructor() {}

  static getInstance(): NodePool {
    if (!NodePool.instance) {
      NodePool.instance = new NodePool();
    }
    return NodePool.instance;
  }

  getNode(type: string, data: PoolParams, builder: WrappedBuilder<[PoolParams]>): NodeItem {
    let pool = this.nodePool.get(type);
    if (pool && pool.length > 0) {
      let node = pool.pop()!;
      node.reset(data); // 复用前复位解绑态并更新数据
      return node;
    }
    return new NodeItem(builder, data, type);
  }

  recycleNode(type: string, node: NodeItem): void {
    let pool = this.nodePool.get(type);
    if (!pool) {
      pool = new Array<NodeItem>();
      this.nodePool.set(type, pool);
    }
    pool.push(node);
  }

  disposeAll(): void {
    this.nodePool.forEach((pool: Array<NodeItem>) => {
      pool.forEach((node) => {
        node.disposeNode();
      });
    });
    this.nodePool.clear();
  }
}

// 使用示例
const contentBuilder = wrapBuilder<[PoolParams]>(buildContent);

@Entry
@Component
struct PoolManagerPage {
  @State controllerA: NodeItem | undefined =
    NodePool.getInstance().getNode('card', new PoolParams('Card A'), contentBuilder);
  @State controllerB: NodeItem | undefined =
    NodePool.getInstance().getNode('card', new PoolParams('Card B'), contentBuilder);

  aboutToDisappear() {
    // 宿主销毁时兜底：释放树上节点与池中节点，防止后端实体节点泄漏
    this.controllerA?.disposeNode();
    this.controllerB?.disposeNode();
    NodePool.getInstance().disposeAll();
  }

  build() {
    Column({ space: 16 }) {
      // 两个 NodeContainer 各自绑定独立 controller；支持置 undefined 移除容器
      if (this.controllerA) {
        NodeContainer(this.controllerA)
          .width('100%')
          .height(80)
          .backgroundColor(0xFFF0F0F0)
      }

      if (this.controllerB) {
        NodeContainer(this.controllerB)
          .width('100%')
          .height(80)
          .backgroundColor(0xFFE0E0F0)
      }

      Button('挂载节点到 A')
        .width('100%')
        .onClick(() => {
          if (this.controllerA) {
            return; // 已挂载则跳过（如需更新请先卸载再挂载）
          }
          // 统一创建/复用入口：池中有回收节点则复用（reset 复位解绑态），无则新建
          this.controllerA = NodePool.getInstance().getNode('card', new PoolParams('New Card A'), contentBuilder);
        })

      Button('挂载节点到 B')
        .width('100%')
        .onClick(() => {
          if (this.controllerB) {
            return; // 已挂载则跳过（如需更新请先卸载再挂载）
          }
          this.controllerB = NodePool.getInstance().getNode('card', new PoolParams('New Card B'), contentBuilder);
        })

      Button('卸载 A（回池复用）')
        .width('100%')
        .onClick(() => {
          // 置 undefined 移除容器 → NodeItem.aboutToDisappear → 自动回池等待复用
          this.controllerA = undefined;
        })

      Button('卸载 B（回池复用）')
        .width('100%')
        .onClick(() => {
          this.controllerB = undefined;
        })

      Button('Transfer A → B')
        .width('100%')
        .onClick(() => {
          if (!this.controllerA || !this.controllerB) {
            return;
          }
          // 1. 接收方已有节点时先释放，防止引用覆盖导致后端实体节点泄漏
          if (this.controllerB.getBuilderNode()) {
            this.controllerB.disposeNode();
          }
          // 2. 先取出待转移节点（必须在 unbind 之前取，unbind 会置空引用，之后再取拿到 null）
          let node = this.controllerA.getBuilderNode();
          if (node) {
            // 3. 旧容器清空（makeNode 返回 null + rebuild）
            this.controllerA.unbind();
            // 4. 新容器接收并刷新内容（内容随节点转移，转移可见）
            this.controllerB.bindNode(node);
            this.controllerB.updateData(new PoolParams('Card A'));
          }
        })

      Button('Dispose All')
        .width('100%')
        .onClick(() => {
          // 1. 释放仍挂载在树上的节点，并置 undefined 移除容器
          this.controllerA?.disposeNode();
          this.controllerB?.disposeNode();
          this.controllerA = undefined;
          this.controllerB = undefined;
          // 2. 统一销毁池中回收的节点（只清池，树上节点须先 disposeNode）
          NodePool.getInstance().disposeAll();
        })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
```

## 规则依据

- [全局自定义组件复用实现](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/node-custom-component-reusable-pool.md)：NodePool + NodeItem 池管理模式、getNode/recycleNode 生命周期、性能对比数据
- [NodeController API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-nodeController.md)：makeNode 返回 null 清空子节点、rebuild() 触发重新 makeNode
- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)：创建/build/挂载/dispose
- [节点 FAQ](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-node-faq.md)：aboutToDisappear 和 dispose 生命周期
