# 命令式节点 dispose 释放与安全检查

## 检查条件

代码中创建了 BuilderNode / FrameNode / RenderNode 对象（典型形式：`new BuilderNode(context)`、`new FrameNode(context)`、`new RenderNode()`），或在 NodeController 的 `makeNode` 中创建并返回了上述节点，且存在 dispose 调用或释放逻辑。凡存在命令式节点创建与释放的位置，都需检查释放路径的完整性与 dispose 后的访问安全。

## 检查步骤

1. **定位所有创建点**：在当前作用域及子作用域中搜索 `new BuilderNode(`、`new FrameNode(`、`new RenderNode(`，记录每一个创建位置持有的变量名与作用域。
2. **追踪对象生命周期**：对每个创建点，追踪该对象在何处被释放。判断是否满足以下任一释放路径：
   - 在变量置空（`= null`）、超出作用域、页面销毁、NodeController 被替换之前，调用了 `dispose()`；
   - 在 NodeController 的 `makeNode` 中创建的节点，是否有对应的清理方法在页面/容器销毁时被调用。
3. **检查仅置 null 未调 dispose**：仅将变量置 `null` 而未调用 `dispose()` —— 不满足释放条件，后端实体节点仍存在。BuilderNode / FrameNode / RenderNode 持有后端实体节点（Native 节点）的强引用，前端对象置 `null` 仅切断 ArkTS 层引用，后端实体节点与前端对象之间存在引用关系（含循环引用），虚拟机 GC 无法自动回收，导致内存泄漏。
4. **检查 dispose 后是否继续调用接口**：dispose 解除前后端引用关系后，BuilderNode / FrameNode 前端对象仍存在，但后端实体节点已被释放。继续调用 `getFrameNode()` 可能返回 null 或默认值，`update()` 不生效，`getRenderNode()` 返回 null。极端情况下访问已释放的后端实体可能 crash。需在 dispose 后立即清除引用，避免后续代码误访问。
5. **检查是否持有 dispose 后的 FrameNode / RenderNode 引用**：dispose 后，BuilderNode 持有的 FrameNode 和 RenderNode 同步解除引用，这些引用不再对应任何后端节点。若外部（如数组、Map、闭包、其他对象属性）仍持有这些引用，继续使用会得到过期数据或 null。需在 dispose 前后同步清除所有持有这些引用的集合和变量。
6. **检查是否存在前后端循环引用**：若 BuilderNode 的 `build` 参数（Params 对象）引用了 BuilderNode 自身（如 `params.builderNode = this.builderNode`），会在前后端之间形成循环引用：BuilderNode → Params → BuilderNode。即使调用 dispose，虚拟机 GC 也无法回收这条循环引用链，导致内存泄漏。需避免在 build 参数中传递 BuilderNode 自身引用，改用 ID 或弱引用。
7. **API 20+：检查是否使用 isDisposed() 在操作前验证有效性**：API 20 起提供 `isDisposed()` 接口，返回 BuilderNode 是否已解除引用。在不确定节点是否已 dispose 的场景（如异步回调、事件处理）中，操作前应调用 `isDisposed()` 判断，已 dispose 则跳过操作。

## 诊断与修复

### 发现问题时

- **诊断**：命令式节点仅在前端被置空或脱离作用域，未调用 `dispose()`，后端实体节点未被释放，内存占用持续增长；或 dispose 后调用 getFrameNode 返回 null 或 crash，update 不生效；或异步回调中访问已 dispose 节点报错。
- **原因**：
  - 未调 dispose：前端对象置 null 仅切断 ArkTS 层引用，后端实体节点与前端对象之间存在引用关系（含循环引用），GC 无法回收。
  - dispose 后访问：前端对象存活但后端实体已释放，接口行为未定义。
  - 引用残留：外部集合/闭包持有 FrameNode / RenderNode 引用，阻止前端对象 GC。
  - 循环引用：build 参数引用 BuilderNode 自身，dispose 无法切断 Params → BuilderNode 的引用链。
- **修复方向**：在不再需要节点时，主动调用 `dispose()` 解除前后端引用关系，再清除前端所有引用（变量置空、清空集合、释放闭包捕获）；build 参数不传 BuilderNode 自身引用；异步回调中用 `isDisposed()`（API 20+）或 null 检查守卫。
- **修复代码模式**：
```typescript
// 模式一：dispose 先于置空，并清除所有额外引用
class SafeNodeController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;
  private frameCache: Map<string, FrameNode> = new Map();

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder(buildFn), params);
    return this.builderNode.getFrameNode(); // build 后获取
  }

  clearNode() {
    if (this.builderNode === null) return;
    this.builderNode.dispose();          // 解除前后端引用
    this.frameCache.delete('root');      // 清除缓存的 FrameNode 引用
    this.builderNode = null;             // 清除主引用
  }

  // 操作前用 isDisposed() 守卫（API 20+）
  updateSafely(params: Params) {
    if (this.builderNode === null) return;
    if (this.builderNode.isDisposed()) { // 已 dispose，跳过
      this.builderNode = null;
      return;
    }
    this.builderNode.update(params);
  }
}

// 模式二：避免 build 参数引用 BuilderNode 自身（切断循环引用）
class BadParams {
  builderNode: BuilderNode<[BadParams]> | null = null; // ❌ 循环引用
}
class GoodParams {
  nodeId: string = ''; // ✅ 用 ID 关联，外部管理器按 ID 查找 BuilderNode
}

// 模式三：异步回调中守卫
async fetchData(controller: SafeNodeController) {
  const data = await remoteFetch();
  // 回调时节点可能已 dispose，必须守卫
  if (controller.isDisposed?.() ?? false) return; // API 20+
  controller.updateSafely(new Params(data));
}
```

### 未发现问题时

每个命令式节点在不再使用时都调用了 `dispose()`，且 dispose 之后清除了所有前端引用（变量、集合、闭包）。NodeController 在页面/容器销毁时通过显式清理方法触发 dispose。build 参数未引用 BuilderNode 自身。异步回调中有 isDisposed() 或 null 检查守卫。不报告。

## 规则依据

- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："解除实体节点引用关系"章节——dispose() 解除前后端引用关系，BuilderNode dispose 后其持有的 FrameNode 和 RenderNode 同步解除引用；"查询当前 BuilderNode 是否解除引用"章节——`isDisposed()`（API 20+）验证 dispose 状态。
- [节点 FAQ](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-node-faq.md)："BuilderNode 前后端循环引用导致的内存泄漏问题"章节——前端置 null ≠ 后端释放，须主动 dispose；build 参数引用 BuilderNode 自身形成循环引用，dispose 无法回收。
- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：`dispose()` 方法说明、`isDisposed()`（API 20+）验证接口。
