# Swiper 转场的邻页缓存与资源准备

检查复杂页翻入时的创建、布局与资源等待；节点缓存和图片/数据资源缓存分别判断。这里不复制局部/全局组件复用规则。

## 邻页节点缓存

1. 读取 Swiper、子页、数据源及目标 API。区分 ForEach 已全量创建与 LazyForEach 按需创建，结合实际缓存范围判断哪些页还会在翻入时新建，不能仅因使用 ForEach 就要求迁移。
2. 读取 cachedCount 的实际配置及版本默认值。基础 cachedCount 默认是 1，未写该属性不等于没有邻页缓存；不同重载与缓存显示行为按工程版本核对。
3. 如果复杂邻页没有提前准备，创建/布局落入翻页窗口，建议在受支持的按需生成方式中保留适量邻页；已有有效缓存、页内容很轻或主要等待来自图片时，不重复报节点预加载缺失。
4. 反向检查过大缓存：复杂页大量提前创建、准备阶段集中或驻留内存增加时缩小范围。按单页准备成本、动画机会和内存调整，不机械规定 1、2、5 或某个最大值。

### Bad / Good 对照

前提：多页复杂内容通过 LazyForEach 按需生成；已确认下一个目标页在翻入时才构建。pages 是完整 IDataSource，PreviewPage 是应用的复杂页面组件。

```ts
// Bad：复杂邻页完全未缓存，准备工作留到翻入时。
Swiper(this.swiper) {
  LazyForEach(this.pages, (page: PageData) => {
    PreviewPage({ data: page })
  }, (page: PageData) => page.id)
}.cachedCount(0)
```

```ts
// Good：先用一个邻页建立对照，再按实际成本调整。
Swiper(this.swiper) {
  LazyForEach(this.pages, (page: PageData) => {
    PreviewPage({ data: page })
  }, (page: PageData) => page.id)
}.cachedCount(1)
```

另一侧的 Bad 是在相同条件下缓存大量复杂页，例如 cachedCount(12) 使几乎全部页面进入准备/驻留范围。Good 是收敛到实际翻页需要的有界窗口；不是看到 12 就直接报告问题。两项在同一位置按实际根因报告一次，不同时要求“增加缓存”和“减少缓存”。

## 资源准备与 onAnimationStart

原文的离手动画约 400ms，一个子页加载、构建和布局约 100～200ms。离手动效计算在渲染线程进行，UI 主线程在这段时间存在准备后续内容的机会，因此可利用 onAnimationStart 尽早发起后续页面的异步图片等资源准备。数值是文档案例，不是所有设备的动画规格或调度保证；onAnimationStart 也不表示主线程可以承受任意同步工作。

顺着“目标索引 → 后续缓存范围 → 资源 ID/版本 → 请求/解码/缓存 → 子页读取”核对：

- **Bad**：子页每次 aboutToAppear 都重新请求/解码同一资源；父页虽收到动画开始回调，却没有为后续窗口准备资源，或准备结果根本未被子页读取。读取具体实现后再判断，不能凭 loadImage 名称推断重复解码。
- **Good**：父页在动画开始时异步准备未来缓存窗口可能使用的资源；子页优先读取对应 ID/版本的有界缓存，未命中时保留正常加载、占位和失败路径。应用资源服务的 prepare/get 等方法是业务接口，不能写成不存在的 ArkUI API。
- 准备目标要早于该子页节点的实际预加载。原文 loop=false、cachedCount=1 的例子在 0→1 时准备资源 3，使后续 1→2 时缓存页 3 有资源可用；不能只在目标页已经开始构建后准备它，再保证当前帧会命中。
- 只保留有限近期资源；合并同 ID/版本的在途请求，异步返回核对业务身份、数据版本和当前窗口。快速反向、连续翻页、尾页和循环边界都需覆盖。失效结果不再提交不等于底层请求已经取消。

aboutToAppear 中 await/Promise/setTimeout/TaskPool 的选型与执行线程，统一读取[生命周期与预加载选择](../startup/lifecycle-work.md#abouttoappear-资源预加载的方案选择)，不在此重复维护。UI 子树构建仍在有效 UIContext 内执行。

## 建议与验证

区分冷次、热往返与预取未命中。比较翻页时目标子树的创建/布局，以及预加载期新增工作、驻留节点和资源内存。资源准备检查每个 ID/版本的请求、解码、命中和提交时机，确认准备确实前移且被使用。

首次进入仍可能需要准备；增大节点缓存不能替代资源缓存，资源预取也不等于节点已构建或目标页已上屏。原页仍在退场使用的节点不可直接抢给新页，跨页实例复用另读[共享池规则](../component/buildernode-and-global-reuse.md)。

## 依据

- [Swiper 高性能开发指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/swiper-optimization.md)：复杂邻页预加载、离手动效机会、资源提前准备案例。
- [Swiper API](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-container-swiper.md)：cachedCount、生成方式、动画回调及版本。
