# 列表全量创建

## 前提与机制

列表数据大量超出首屏展示需要，ForEach 遍历全量数据并创建 ListItem 节点，存在首页创建成本。必须区分条目节点与条目内部子树：[列表场景性能提升实践](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/list-perf-improvement.md#懒加载)说明 List 的优化会延迟构建可视区外 ListItem 的内部组件，不能直接断言所有离屏 Text/Image/自定义子树均已构建。ForEach 的出现本身不是问题。

小而有界且全部需要显示的列表，或全量创建有明确业务需要的内容，可以保留 ForEach。不设“超过 N 条必慢”的统一阈值。

## 检查方法

1. 读取列表规模/上界、首屏条目需求、滚动容器、条目构建代码及数据更新方式。
2. 超出首屏需要的创建工作明确时，评估容器支持的按需创建方式，例如 LazyForEach；保留业务 key、数据源及变更通知契约。
3. 异步返回的数据量未知时先确认规模及首屏需求；条目函数未提供时先补代码。

## Bad case

前提：items 有 1000 项、首屏约 10 项，且没有全量创建业务需求。1000 是示例条件，不是阈值。

```ts
List() { ForEach(this.items, (item: Item) => { ListItem() { ItemView({ item: item }) } }) }
```

## Good case

前提：dataSource 已实现 IDataSource，持有同一批数据并正确发送变更通知；item.id 是唯一、稳定的字符串业务标识，List 的布局约束支持按可见范围创建。

```ts
List() {
  LazyForEach(this.dataSource, (item: Item) => {
    ListItem() { ItemView({ item: item }) }
  }, (item: Item) => item.id)
}
```

迁移不是只换函数名。数据源应提供 totalCount/getData、注册/注销监听，以及与增删改移动对应的通知；同步核对 key 的身份语义和条目更新。固定 5 项且全部展示的列表无需为形式统一强制懒加载。

## 建议与验证

迁移建议应保持首屏内容、首末项和完整滚动路径的数据及可达性，以及 key 身份和增删改通知；涉及 scrollToIndex 等程序化滚动时也保持原行为，不能为减少创建而截断数据。默认在建议中说明这些语义要求，不另列功能测试步骤；输入明确要求时再展开首项、滚动到末项等操作。建议 LazyForEach 时，同时给出下面的框架打点、统计方式和预期变化；不预设精确创建数或毫秒收益。代码与条件足够时直接给建议，不要求先提供 Trace；Trace 用于验证修改效果，持续慢再按 [Trace 指导](../trace-guidance.md)排查其他阶段。

复杂对象 key 生成避免反复 stringify，不能将 key 缺省等同于全量重建。cachedCount 影响可视区外预加载与滑动体验：过小滚动时可能出现白块，过大会增加预加载工作与内存占用；是否增加首帧工作按实际创建时间窗确认。结合目标版本、可见条目数、条目复杂度和滑动速度调整，不固定为 5；增大 cachedCount 不能作为缩短首帧的必然措施。

## 打点与预期变化

### 首帧 ListItem 创建量的 Trace 验证

ListItem 的创建入口打点是 `Create[ListItem][self:节点ID]`，在 Trace 中常显示为 `H:Create[ListItem][self:节点ID]`。告诉开发者在应用 UI 线程搜索 `Create[ListItem]`，记录创建调用及不同的 self 节点 ID；创建量按 ListItem 本身统计，与自定义组件构建及 Measure/Layout 次数分别表达。

统计范围是目标页面开始加载/构建到关联首帧提交或已确认送显的同一窗口，包含首个 ReceiveVsync 之前的同步构建，不混入首帧之后的滑动和空闲预构建。固定设备、数据、首屏尺寸及缓存条件后比较两版；存在重复创建调用或节点复用时，结合 self ID 区分调用次数与不同节点数。

预期：全量 ForEach 改为 LazyForEach 后，首帧窗口中 ListItem 的创建数量应减少，由全量条目创建变为首屏所需条目及该窗口内实际预创建/缓存项。以 1000 条、首屏约 10 条的例子，优化后应明显少于全量 1000 条，不硬性要求恰好 10 条；缓存与布局策略可能影响具体数值。创建减少是待验证的机制预期，不代表已经实测启动耗时下降。

LazyForEach 可辅助搜索 `Builder:BuildLazyItem`（后缀可能是索引及 needBuild/isCache 等参数），观察哪些条目按需构建；ForEach 没有同一懒加载路径，不能只比较这个标签的数量来判断两版 ListItem 创建是否减少。`ListLayoutAlgorithm::MeasureListItem` 是测量打点，也不能代替创建计数。含义见 [常用 Trace 使用指导](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/common-trace-using-instructions.md#懒加载)。

`Create[ListItem]` 使用布局 Trace 开关；当前实现还依赖开发者模式及 `persist.ace.trace.layout.enabled`。开发者需按目标系统版本确认开关和采集项已开启，两版配置一致；缺少事件先核对配置、版本与时间窗，不能解释为零创建。

## 依据

[减少首帧绘制时的冗余操作：按需加载](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reduce-redundant-operations-when-render-first-frame.md#按需加载)、[列表场景性能提升实践：懒加载](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/list-perf-improvement.md#懒加载)。
