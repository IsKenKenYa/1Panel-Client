# 滑动时组件复用

## 使用范围与共享规则

本文件只保留滑动场景的检查入口。实例复用、V1/V2 回调、默认组、结构分组、字段同步、Repeat 与 key 的机制统一维护在[组件复用与 key](../component/reuse-and-keys.md)，不在滑动、组件和转场中各写一套。

## 滑动检查顺序

1. 读取实际滚动容器、条目子树、数据量和数据变更方式，确认条目会离开可见/缓存范围并有后续重新创建机会；固定短列表或始终挂载的轻量子树不因缺少装饰器就报告缺陷。
2. 先分开全量创建与实例复用两个问题。前者由[懒加载规则](lazy-loading.md)检查；后者使用[共享复用规则](../component/reuse-and-keys.md)。不能只加 @Reusable 就认为 ForEach 已经按需创建，也不能只换 LazyForEach 就保证自定义条目已复用。
3. 按 V1/V2 选择适用路径。V1 可结合 LazyForEach、完整 IDataSource 与可复用条目；V2 大列表优先 Repeat 虚拟滚动，也允许数据通知与参数更新正确的 LazyForEach 方案。V2 非列表面板的回收/再加入另评估 @ReusableV2；内层列表懒加载不能代替外层实例复用。
4. 原地内联复杂条目树且反复创建时，可结合状态与生命周期职责评估提取可复用条目；不能不看子树成本就强制所有 UI 增加一层组件。嵌套 @Component 不自动构成缺陷，按[展示封装边界](../component/display-builder.md)判断。
5. 复用时的参数表达式和 aboutToReuse 重复计算读取[高频重复工作](../component/frequent-work.md)。不要把每次复用所需工作只挪到不会再次触发的 aboutToAppear，也不为减少更新把必要 UI 字段改成普通值。
6. 若实际问题是 Swiper/页签切换新页时无法使用旧页卡片，转到[局部池不能跨页共享](../component/buildernode-and-global-reuse.md#页签切换时局部池不能跨页共享)。页内条目复用与跨页共享分别判断，同一根因仅报告一次。

## 示例与验证复用

- 同父内容反复移除/加入、默认组、按记录 ID 过细拆池、有限结构分组、字段同步：使用[共享示例](../component/reuse-and-keys.md)。
- 全量创建与 IDataSource 通知：使用[懒加载示例](lazy-loading.md)，不复制实现。
- 复用后集中刷新大量复杂子组件：使用[分帧规则](../component/frame-splitting.md)，先确认当帧实际创建/测量范围。

输入要求迁移正例代码时，按当前 V1/V2 和数据变更方式给出最小代码。V1 同时迁移懒加载与实例复用时，代码应覆盖 IDataSource 的 totalCount/getData/registerDataChangeListener/unregisterDataChangeListener 签名、LazyForEach 调用及稳定 key、@Reusable 条目的 aboutToReuse 字段更新；不能只口述接口名称。静态数据与动态通知按实际需要实现。每次复用所需的字段和轻量状态更新留在 aboutToReuse，昂贵计算按依赖预计算或按条件后台处理，不能一律移到只在初次创建时调用的 aboutToAppear。

沿同样滚动路径区分首次创建与后续滚动，按条目类型、父级、数据身份与结构组比较。按当前复用机制选择适用的创建/复用日志，或使用 Trace 比较相同滚动路径的帧处理耗时；具体方法统一见共享规则及[Trace 指导](../trace-guidance.md)。V1/V2 复用事件名与版本差异见共享复用规则。若容器为 Scroll/Column/Row/Stack（非懒加载容器），LazyForEach 退化为全量加载，条目无回收路径，复用不会触发，详见[懒加载规则](lazy-loading.md)。

规则依据和版本约束随共享文件维护。这里不保留独立的装饰器、reuseId、key 或回调契约副本。
