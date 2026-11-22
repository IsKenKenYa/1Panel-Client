# BuilderNode、全局复用与跨页共享

## 前提与机制

BuilderNode 的组件结构不变、只有参数变化时，可以缓存节点并调用 `update`，减少重复 `new/build`。NodeController.rebuild 会再次调用 makeNode；若 makeNode 中无条件销毁并新建节点，频繁更新会产生可避免的构建工作。

同一类复杂组件在不同父组件下反复显示时，各父实例的默认局部复用池不能共享缓存。使用覆盖这些父组件的复用池，或将已缓存的 BuilderNode/NodeController 转交给新容器，可以减少后续重复创建；缓存本身仍有内存与生命周期成本。

`BuilderNode` 的基础 build/update 从 API 11 起提供，`reuse/recycle/dispose` 从 API 12 起提供；BuilderNode 内部自定义组件的 V2 复用事件支持从 API 26.0.0 起提供。普通 @ReusableV2 从 API 18 起支持，不代表 API 18 工程即可使用 BuilderNode 的 V2 事件能力。框架全局复用池从 API 26.0.0 起提供，建议前核对工程 SDK 和最低兼容条件。API 12 下跨父共享且需保留父组件边界时，评估下文由应用保存、转交和释放 BuilderNode 节点的方案。

## 检查方法

1. 先区分同结构参数更新与旧父销毁后的跨父共享。已有 NodeContainer/NodeController 时跟进 makeNode、rebuild、参数更新、挂载和释放；当前只有普通自定义组件或 @Reusable 时，先确认哪些父组件会销毁、哪一层持续存在；API26.0.0起优先在这一层配置框架全局复用池，较低版本再评估由应用保存和转交 BuilderNode 节点。
2. 比较更新前后的子树结构和数据依赖。只有参数变化却反复 dispose/new/build 时，给出缓存节点、使用 update 的具体改法；结构改变后的必要重建不能一并删除。
3. 跨父组件或页面切换时，检查缓存的拥有者、匹配方式和实际命中路径。父组件仅作展示封装时可评估 @Builder；父组件有独立状态和职责时，保留父组件并选择合适的共享池。
4. 按组件类型、子树结构和 UIContext 组织缓存，同构实例共享缓存，不按每条业务记录或每个临时父实例拆池。核对容量、淘汰与释放，避免无限保留或每次换父前清空缓存。

### BuilderNode 更新与回收

1. 从 `NodeContainer` 的创建点跟到 `NodeController.makeNode`、`rebuild` 和数据更新入口。对同一结构，`makeNode` 返回已持有的节点，参数变化优先调用 `BuilderNode.update`，避免频繁调用 `rebuild` 触发 `dispose/new/build`。
2. 检查缓存命中后是否确实复用原节点，参数和事件是否对应当前业务记录。更新需要保持 UI 观测和同步，不能为少一次重建而把界面字段改成无法刷新的普通值。
3. 需要将回收/复用事件传递给内部自定义组件时，使用版本支持的 `BuilderNode.recycle/reuse`，同时处理新参数和旧任务。它们传递生命周期事件，不负责替应用建立复用池；BuilderNode 直接生成的根自定义组件需遵循装饰器支持限制，不能机械添加 @Reusable。
4. 缓存中的节点为后续复用保留；确认不再使用、缓存淘汰或所属 UIContext 结束时，解除挂载并清理引用，调用支持版本的 `dispose` 释放实体节点。每次暂时卸载都 dispose 会破坏缓存收益；始终保留所有节点则增加内存和 GC 压力。

## 页签切换时局部池不能跨页共享

适用于页签切换，也适用于 replace、离页后再进入。以推荐页和关注页为例：两页各自是 ProductTabPage 的不同实例，均使用同一种 ReusableProductCard。

**Bad 的因果链必须讲清：各页拥有独立局部池 → 关注页不能取用推荐页回收的卡片，即使类型和 reuseId 相同 → 推荐页及其局部池销毁后缓存也消失 → 新页仍创建相同布局的卡片，把创建/构建成本带入转场。** @Reusable 不是没有生效，它只覆盖所属父实例内的复用；只建议再加装饰器或相同 reuseId 无法解决跨页共享。

Good 是让覆盖这些页面的存活宿主接纳已回收卡片，供后续新页使用。框架全局池配置在持续存在的上层宿主；使用 BuilderNode 时，由应用负责节点的保存、转交和释放。实例仍在退场动画中使用时不能抢给新页；首次进入时尚无可复用实例，仍需创建，后续切换再比较已回收实例的复用和新增创建情况。

先读取实际销毁路径。普通 Tabs/TabContent 或缓存页可能仅隐藏、一直保留实例，不因“切过 Tab”就报告销毁重建。D09 的 cachedCount(0) 是便于离页释放的对照，不要求产品关闭缓存以制造复用机会。固定轻量示例可用于解释机制，实际收益按子树成本验证，不虚构已测卡顿。

## 预创建与回收复用的选型

以下推荐次序和“只创建、不展开”是领域评审补充，不作为末尾官方链接的逐字结论：

| 目标 | 推荐与原因 |
|---|---|
| 首次进入前展开确定要用的 UI 子树 | 优先 BuilderNode，在合适前置时机执行 build。按本项目补充口径，GlobalReuse 预创建只创建组件实例、不展开 UI 子树，不能以 preRender 完成证明子树构建、布局和绘制都已完成。准备时机读取[提前构建](../startup/home-prebuild.md)。 |
| 页签、replace、退出后再进入时利用已创建的同构内容 | 框架版本支持且范围匹配时优先 GlobalReuse：框架管理回收与复用，范式较简单，较少依赖应用自己持有节点。BuilderNode 同样可用，但应用需要说明由谁保存节点、缓存数量上限及不再使用时如何释放。 |

GlobalReuse 推荐不等于无需内存管理，也不要求低版本工程升级平台来完成局部优化；未满足接口版本或场景条件时评估受支持的 BuilderNode 方案。

### 跨父组件共享的实现

#### 框架全局复用池（API 26.0.0 起）

工程 SDK 和最低兼容条件支持时，优先在切换期间持续存在的上层组件配置 `reusePool` 与 `poolAccepts`，让不同子页面使用已经回收的卡片。不要只建议“增加全局缓存”，要说明配置放在哪里、接受哪种组件以及缓存数量如何限制。

以下展示需要补充的配置，ReusableProductCard 需已定义或导入，页面原有字段和 build 保留：

```ts
@Component({
  reusePool: 'perInstance',
  poolAccepts: [ReusableProductCard],
  freezeWhenInactive: false
})
struct ProductHostPage {
  // 保留原有页面实现；切换子页面时本组件持续存在。
}
```

这里 perInstance 表示缓存属于这个持续存在的页面实例。其他页面组织也可使用 shared，需说明配置所在组件在切换期间是否持续存在。框架方案和应用保存 BuilderNode 节点的方案，按实际采用的一种检查，无需同时提供。

- 检查池的拥有者是否覆盖切换路径，`poolAccepts` 是否包含实际复用类型，reuseId 是否按有限结构划分；同名 reuseId 本身不会把各父实例的默认池合并。
- 按业务生命周期选择 shared 或 perInstance，检查实际命中率和缓存容量；多个父组件交替显示同类子组件时，避免池随每次父组件切换一起被释放。shared 由同一拥有组件类的实例共享，最后一个拥有实例销毁后池也销毁，不是永久的应用全局单例。
- 查询和设置对应类型、reuseId 组的 maxCount，区分池中空闲缓存与仍在使用的实例。poolAccepts 中的复用组件需已定义或已导入；reusePool、poolAccepts 和按版本要求的 freezeWhenInactive 配置一起核对。
- 复用命中时的参数同步由框架完成：V2（@ReusableV2 / GlobalReuse）复用时 `@Param` 由框架按新参数自动更新，`@Local` 按声明初值重置，普通字段需自行清理；不需要为参数同步添加 `aboutToReuse` 回调，V2 的 `aboutToReuse` 无入参，不能搬用 V1 的 `params` 赋值写法，同步细则见[复用与 key](reuse-and-keys.md)。已是正确配置的 V2 全局池不构成缺陷，不报告缺少回调。
- 不以 preRender 代替上文的 UI 子树预构建方案；确需实例预创建时检查数量、空闲时机及未命中的内存成本。

仅修改装饰器、把 reuseId 改成相同字符串或声明一个没有接入取还路径的全局容器，不足以实现跨父组件复用。目标版本不支持原生全局池时，使用受支持的 BuilderNode 方案，不要求为局部性能问题迁移整个状态管理版本。

#### 使用 BuilderNode 保存和转交节点

适用于同一 UIContext 内需要跨父组件、跨页面复用节点，且普通局部复用池无法覆盖目标场景的代码。

使用切换期间持续存在的对象保存已回收节点，按组件类型、结构和 UIContext 查找可以复用的节点，不为每个临时父组件或业务记录分别保存一份。原代码没有 NodeContainer 时，在需要共享子树的位置引入 NodeContainer/NodeController；处理顺序如下：

```text
首次使用：没有可复用节点 → new BuilderNode/build → makeNode返回getFrameNode() → NodeContainer挂载
旧父退出：解除旧容器的挂载、使旧异步任务失效 → 保存节点供后续使用、清理旧控制器引用（暂不dispose）
新父取用：取出类型和结构相同的已回收节点 → update当前参数、更新事件归属 → 挂到新容器，同一时间只挂一个容器
超过缓存数量上限或不再使用：解除挂载 → dispose → 清理缓存和控制器引用
```

仍在挂载或退场中的节点不能交给新页面；新父创建时若还没有可复用节点，可以创建新节点，后续再观察已有节点是否真正复用。取用已缓存节点不重复销毁、new/build相同子树，缓存容量和最终释放路径须明确。

同一 UIContext 内换父组件和跨 UIContext/窗口迁移分别判断，不将全局 Map 中的节点无条件交给所有窗口；跨页面时核对原页面销毁对节点更新与挂载的影响。

## Bad case

前提：最低 API 12，同一 UIContext 中 NodeContainer 持续挂载同一控制器，子树结构不变，只有 title 参数更新。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class DetailParams {
  title: string = '';
  constructor(title: string) {
    this.title = title;
  }
}
@Builder
function detailContent(data: DetailParams) { Text(data.title) }

class DetailController extends NodeController {
  private node: BuilderNode<[DetailParams]> | null = null;
  private title: string = '';

  makeNode(context: UIContext): FrameNode | null {
    this.node?.dispose();
    this.node = new BuilderNode<[DetailParams]>(context);
    this.node.build(wrapBuilder<[DetailParams]>(detailContent), new DetailParams(this.title));
    return this.node.getFrameNode();
  }
  setTitle(title: string): void {
    this.title = title;
    this.rebuild();
  }
  release(): void {
    this.node?.dispose();
    this.node = null;
  }
}
```

setTitle 每次调用 rebuild，makeNode 又无条件 dispose/new/build，导致相同结构反复销毁重建。问题成立于实际重建路径，不能仅凭出现 rebuild 就判断节点必然重建。

## Good case

保留 DetailController 的字段和最终释放方法，将 makeNode、setTitle 改为：

```ts
makeNode(context: UIContext): FrameNode | null {
  if (this.node === null) {
    this.node = new BuilderNode<[DetailParams]>(context);
    this.node.build(wrapBuilder<[DetailParams]>(detailContent), new DetailParams(this.title));
  }
  return this.node.getFrameNode();
}
setTitle(title: string): void {
  this.title = title;
  this.node?.update(new DetailParams(title));
}
```

首次创建仍需 build，后续参数变化更新已有节点；尚未创建时先保存 title，首次构建使用最新值。release 在节点确实不再使用时调用，不能移到每次参数更新或暂时卸载的位置。

## 建议与验证

首次创建、结构改变后的必要重建、已有有界缓存和参数更新的代码属于合理用法。没有反复移除与重新加入、换父或重复重建的实际路径时，不要求增加复用池。

缺少父级、UIContext 来源、池的拥有者或释放代码时，补齐相关定义和调用位置，再判断能否共享；不凭全局变量名或相同 reuseId 认定已实现全局复用。

功能验证覆盖新参数显示、事件归属、编辑状态、旧异步任务失效、缓存淘汰和最终释放。保持相同数据、父组件切换顺序、预热与缓存容量，比较创建、更新、复用和相关区间耗时；不把代码检查结论写成实测收益。

## 打点与预期变化

使用 BuilderNode 的 new/build/update/dispose 函数计数、CPU 调用栈、池命中与存活数量记录，或建议开发者新增相应业务打点，不编造专用框架事件。统计范围按目标节点、结构类型、UIContext 和相同交互窗口确定。

同结构参数更新由点击触发时，Trace 观察本次点击中的参数更新调用耗时。在页面调用控制器更新方法的前后加入成对业务打点，修改前后保持相同入口：修改前覆盖 rebuild 及其触发的销毁、创建和构建，修改后覆盖 update。搜索该业务点，直接读取其 Duration，比较相同操作的多次结果，预期本次同步更新耗时降低。

| 场景 | 观察对象 | 预期与限制 |
|---|---|---|
| 同结构参数更新 | 日志：实际 new/build/update/dispose 次数；Trace：本次点击中参数更新调用的业务打点 Duration | 缓存并 update 后，首次 build 保留，后续重复构建减少，预期点击中的同步更新耗时降低；参数与界面保持最新，不要求初次创建为 0 |
| 跨父组件或页面复用 | 池的拥有者、命中/未命中、节点创建与挂载记录 | 分别记录首次进入和后续重复切换，比较同类型已回收实例的实际复用与新增创建；更新及必要挂载仍存在 |
| 缓存寿命与释放 | 存活数量、淘汰、dispose 与内存变化 | 存活数量受容量和业务寿命限制，最终不再使用时释放；暂时卸载保留可复用节点，内存代价与创建收益一起比较 |

## 依据

- [全局自定义组件复用实现](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/node-custom-component-reusable-pool.md)：通过 BuilderNode/NodeController 保存节点并在不同父组件之间复用。
- [BuilderNode](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-builderNode.md)：build/update、reuse/recycle、dispose 的版本与用途。
- [BuilderNode 开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/arkts-user-defined-arktsNode-builderNode.md)：跨页面复用与内部自定义组件约束。
- [NodeController](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-arkui-nodeController.md)：控制器绑定、makeNode 与 rebuild。
- [全局复用池](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-global-reuse-pool.md)：API 26.0.0 起的框架全局复用。
