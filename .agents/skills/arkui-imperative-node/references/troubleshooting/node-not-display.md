# 命令式节点显示检查

## 检查条件

代码中使用了 `appendChild` / `insertChildAfter` / `getFrameNode` / `getRenderNode` 等方法挂载或获取命令式节点，或在 `NodeController.makeNode` 中创建 BuilderNode / FrameNode。典型场景：BuilderNode 创建后通过 `getFrameNode()` 取节点挂载、FrameNode 之间通过 `appendChild` 组装子树、RenderNode 通过 `getRenderNode()` 上树、跨容器复用缓存的节点。凡涉及命令式节点创建与挂载的位置，都需检查创建时序、挂载路径与复用策略的正确性。

## 检查步骤

1. **检查双挂**：追踪同一 FrameNode（尤其是 `BuilderNode.getFrameNode()` 返回的节点）的挂载历史。判断是否出现以下情况：
   - 同一节点被 `appendChild` / `insertChildAfter` 挂载到多个不同父节点；
   - 跨页面或跨 NodeController 复用缓存的 BuilderNode 时，未先从原父节点 `removeChild` 就直接挂载到新父节点。
   - 命令式节点的挂载是排他的，一个节点同一时间只能有一个父节点，已有父节点时 `appendChild` 会抛异常（错误码 100025）。
2. **检查 build 与 getFrameNode 的顺序**：对每个 `BuilderNode.getFrameNode()` 调用，检查其是否在 `build()` 调用之后。`getFrameNode()` 在 `build()` 之前返回 `null`，挂载 null 节点会导致页面不显示。
3. **检查 makeNode 是否每次调用都创建新的 BuilderNode / FrameNode**：`makeNode` 在 NodeContainer 需要节点时被调用（如首次挂载、从冻结态恢复、复用触发）。若每次 makeNode 都 `new BuilderNode(context)` 且不缓存引用，会导致：旧节点未被 dispose（内存泄漏）、同一段内容出现多个 BuilderNode 实例、复用场景下内容闪烁。正确做法是缓存 BuilderNode 引用，判空后复用，仅在首次创建时 new。
4. **检查 RenderNode 上树方式**：若使用 RenderNode，检查其是否通过 `FrameNode.getRenderNode()` 挂载到 FrameNode 树上。RenderNode 不能直接作为命令式节点挂载到任意父节点，必须依附于 FrameNode。单独 `new RenderNode()` 创建的 RenderNode 不会显示在页面上。
5. **检查 BuilderNode 通过 getRenderNode 挂载到 RenderNode 树时是否设置了 selfIdealSize**：当 BuilderNode 的 FrameNode 不通过 NodeContainer 上树，而是通过 `getRenderNode()` 挂入 RenderNode 树时，FrameNode 未上声明式组件树，布局测量不触发，大小默认为 [0,0]，内容不可见。需在 `new BuilderNode(context, { selfIdealSize: { width: ..., height: ... } })` 构造函数中显式指定理想尺寸。
6. **检查 @Builder 根节点是否为语法节点或自定义组件**：`@Builder` 函数的根节点若是 `if/else`、`ForEach` 等语法节点，或直接是自定义组件（`@Component`），会生成 BuilderProxyNode 中间节点，导致 BuilderNode 内部树结构发生变化。BuilderProxyNode 会影响触摸测试（hitTest）事件传递、节点遍历（getFirstChild/getNextSibling 返回的是代理节点而非实际内容节点），部分场景下导致点击无响应或节点定位错乱。建议 @Builder 根节点为单一原生组件（Text/Image/Column 等），将自定义组件包裹在原生组件内部。

## 诊断与修复

### 发现问题时

- **诊断**：命令式节点创建后页面不显示，或挂载时抛异常；makeNode 重复触发后内存持续增长或内容闪烁；@Builder 含自定义组件根节点后点击事件丢失或节点遍历异常。
- **原因**：以下机制导致节点无法正确上树显示：
  - **双挂**：命令式节点挂载排他，后一次挂载不会叠加，前一次挂载被移除或抛异常；
  - **build 前调用 getFrameNode**：`getFrameNode()` 在 `build()` 后才返回有效对象，build 前返回 `null`；
  - **重复创建**：makeNode 无幂等性保护，每次调用产生新实例，旧实例未释放，前端引用被覆盖后无法 dispose；
  - **RenderNode 未通过 FrameNode 上树**：RenderNode 依附于 FrameNode，脱离 FrameNode 树无法显示；
  - **缺少 selfIdealSize**：BuilderNode 的 FrameNode 未上声明式树时，不会被父容器测量，尺寸退化为 0；
  - **BuilderProxyNode**：@Builder 根为语法节点/自定义组件时，框架插入代理节点隔断事件传递与节点遍历。
- **修复方向**：确保节点单挂（复用前先 removeChild）；确保 `build()` 完成后再调用 `getFrameNode()`；makeNode 内判空复用缓存引用；确保 RenderNode 通过 `FrameNode.getRenderNode()` 上树；BuilderNode 挂 RenderNode 树时构造函数传 selfIdealSize；@Builder 根节点用单一原生组件。
- **修复代码模式**：
```typescript
// 模式一：build 后再 getFrameNode，确保单挂
makeNode(context: UIContext): FrameNode | null {
  if (this.builderNode === null) {            // 仅首次创建
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder(buildFn), params); // 先 build
  }
  return this.builderNode.getFrameNode();      // build 后获取，复用缓存
}

// 模式二：跨容器复用节点前先移除旧父节点（避免双挂）
function safeReMount(newParent: FrameNode, child: FrameNode): void {
  const oldParent = child.getParent();
  if (oldParent !== null && oldParent !== undefined) {
    oldParent.removeChild(child); // 先摘除旧父节点
  }
  newParent.appendChild(child);    // 再挂到新父节点
}

// 模式三：RenderNode 正确上树路径
const hostFrame = new FrameNode(context);
const hostRender = hostFrame.getRenderNode();       // 获取 FrameNode 关联的 RenderNode 根
const childRender = new RenderNode();
childRender.setBackgroundColor('#FF0000EE');
hostRender.appendChild(childRender);                // 子 RenderNode 挂入，进入渲染管线

// 模式四：BuilderNode 挂 RenderNode 树时设置 selfIdealSize
const bn = new BuilderNode(context, {
  selfIdealSize: { width: 300, height: 80 }       // 显式尺寸，避免 [0,0]
});
bn.build(wrapBuilder(buildFn), params);
hostRender.appendChild(bn.getRenderNode());

// 模式五：@Builder 根节点为单一原生组件，自定义组件作为子节点
@Builder
function buildCard(param: Params) {
  Column() {                          // 根节点是原生组件，不生成 BuilderProxyNode
    CustomChild({ item: param.item }) // 自定义组件作为子节点
  }
}
```

### 未发现问题时

每个节点只挂载到一个父节点，复用前已移除原父节点；`getFrameNode()` 均在 `build()` 之后调用；makeNode 判空复用缓存引用；RenderNode 通过 FrameNode 树上树；BuilderNode 挂 RenderNode 树时传了 selfIdealSize；@Builder 根节点为原生组件。不报告。

## 规则依据

- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)："创建组件树"章节——`getFrameNode()` 在 `build()` 后返回有效 FrameNode；"BuilderNode 内的 BuilderProxyNode 导致树结构发生变化"章节——@Builder 根为语法节点或自定义组件时生成代理节点，影响触摸测试与节点遍历。
- [RenderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-renderNode.md)："操作节点树"章节——RenderNode 需通过 `FrameNode.getRenderNode()` 上树，单独创建的 RenderNode 不显示。
- [FrameNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-frameNode.md)：`appendChild` 方法说明，节点已有父节点时抛错误码 100025；`getParent()` 返回当前父节点。
- [BuilderNode API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：构造函数 `RenderOptions.selfIdealSize`——FrameNode 未上树时需显式指定理想尺寸，否则大小默认 [0,0]。
