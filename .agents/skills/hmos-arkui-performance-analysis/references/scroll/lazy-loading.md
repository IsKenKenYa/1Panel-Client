# 懒加载与按需创建

## 前提与机制

先分清数据准备、ListItem等条目节点创建、内部子树构建和实际布局；ForEach全量创建条目节点，不代表List所有离屏内部子树已构建。按真实规模、可见范围和职责判断，小而有界、全量显示有业务需要的列表可保留ForEach。

| 状态管理与场景 | 使用路径 |
|---|---|
| V1长列表 | 支持的List/Grid/WaterFlow/Swiper容器内LazyForEach+完整IDataSource；实例复用另按[共享规则](../component/reuse-and-keys.md)判断 |
| V2长列表，API12+ | 优先Repeat+.each(...)+.virtualScroll()；也可用通知与参数同步正确的LazyForEach/IDataSource，不能仅据其名称判V1/V2混用 |
| V2非列表组件切换，API18+ | 真实反复回收/加入且成本成立时评估@ReusableV2，不将其版本门槛套给Repeat |

Scroll/Column/Row/Stack不是LazyForEach支持的按需创建容器，直接放其中会全量生成。容器主轴约束、可见与缓存范围须能使按需创建实际成立，不能只换函数名。

## 检查方法

核对数据规模/上界、数据源四方法、变更通知、稳定业务key与条目状态同步。JSON.stringify整对象的成本独立于实例是否已复用，不因已有装饰器就忽略实际昂贵key。

缓存影响屏外预加载：过小可能白块，过大增加创建和内存成本；结合目标版本、可见条目数、条目复杂度和滑动速度调整，不固定为5，不把所有预加载工作都计入首帧。Grid按目标版本和列数理解缓存单位。

有图片/数据准备且滑动时不能及时就绪时，可评估目标版本支持的IDataSourcePrefetching.prefetch，或等价的可见范围驱动预取与有界缓存；确认预取实际接入请求和可用数据更新。cachedCount提前创建节点，不等于图片已就绪；已就绪的静态数据不为形式补预取。预取需处理重复请求、身份、失败、过期结果和内存/网络代价。仅当真实调用全量onDataReloaded并存在无关更新时考虑增量通知；方法仅定义未调用不报。Grid不规则项与scrollToIndex问题按版本评估GridLayoutOptions，不给所有列表套用。

## V1最小数据源

静态数据也需四方法；数据后续变化时发出对应通知：

```ts
class RowsSource implements IDataSource {
  private rows: string[] = [];
  private listeners: DataChangeListener[] = [];
  constructor(rows: string[]) { this.rows = rows; }
  totalCount(): number { return this.rows.length; }
  getData(index: number): string { return this.rows[index]; }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) { this.listeners.push(listener); }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) { this.listeners.splice(index, 1); }
  }
  append(row: string): void {
    const index = this.rows.length;
    this.rows.push(row);
    this.listeners.forEach((listener: DataChangeListener) => listener.onDataAdd(index));
  }
}
// 位于有明确可视范围的List中，字符串在本例中唯一且不变。
List() {
  LazyForEach(this.source, (row: string) => {
    ListItem() { Text(row) }
  }, (row: string) => row);
}
```

## V2最小列表

```ts
List() {
  Repeat<string>(this.rows)
    .each((item: RepeatItem<string>) => { ListItem() { Text(item.item) } })
    .key((row: string) => row)
    .virtualScroll();
}
```

保留RepeatItem响应绑定，数据内容和点击身份随当前条目更新。LazyForEach/IDataSource也能用于@ComponentV2，但数据源结构变化需对应通知，子组件参数需正确同步；不为形式替换已有合法Repeat，也不在V2组件上套V1的@Reusable，不能因.each与virtualScroll共存就声称懒加载失效。

## 批量数据提交与分帧

一次追加大量数据不等于当帧创建/测量全部节点。只有实际复杂可见子树集中且业务允许渐进提交时，才读取[分帧规则](../component/frame-splitting.md)，不能把DisplaySync当作后台线程。

## 建议与验证

建议保持首末项、完整滚动范围、key身份、条目状态与增删改通知；用户要求代码时覆盖关键接口和调用。性能按相同数据、滚动路径与缓存条件比较，区分首次创建和后续滚动。

## 打点与预期变化

| 目标 | 观察与限制 |
|---|---|
| 首帧条目创建量 | 按[列表创建](../startup/list-creation.md#首帧-listitem-创建量的-trace-验证)在同一首帧窗口统计Create[ListItem]调用及self ID；不能用测量次数冒充创建数 |
| V1按需构建 | Builder:BuildLazyItem可辅助观察范围；ForEach没有同一路径，V2 Repeat也不以该标签为统一依据。总创建变化另按相同条目口径比较 |
| 缓存/预测 | 结合当前版本OnIdle、List predict、expiringItem_等实际事件解释准备范围；不能仅凭某个count或事件缺失认定缓存错误 |
| 增量更新 | 观察实际受影响条目与布局工作，不把整页数据准备成本都归因通知；监听器注册前的通知不应预设已有对应事件 |

未实测写预期，缺事件先核对开关和窗口。代码审查后仍慢再读[详细Trace指南](../trace-guidance.md)。依据：[LazyForEach优化](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/lazyforeach_optimization.md)、[Repeat](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/rendering-control/arkts-new-rendering-control-repeat.md)。

兼容性依据：[LazyForEach的V2示例](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-rendering-control-lazyforeach/)。
