# 页面生命周期与进入路径的同步耗时

## 前提与机制

启动首屏、点击进入目标页和转场路径中可识别的同步大量计算或非必要同步工作，会推迟后续页面工作。未知调用不能仅凭名称定性。进入路径的同步计算使用本规则；aboutToReuse 的重复计算同时读取[高频工作](../component/frequent-work.md)，不复制线程与生命周期规则。

必要且轻量的初始化、已有真正后台执行的调用是合理写法。async/Promise 不自动使 CPU 计算离开当前线程，setTimeout 也不自动换线程。

### aboutToAppear 与 async/await 的执行边界

`aboutToAppear` 即使声明为 `async`，仍在首次 `build()` 前被调用。首个 `await` 挂起前的代码同步执行，包括 await 右侧函数调用和 Promise 执行器中的同步工作；没有 await 时，函数体中的同步工作全部在返回前执行。这些工作仍可能推迟构建。

`await` 等待结果时会挂起当前异步函数并让出执行，框架可以继续构建，无需等待整个回调返回的 Promise 完成。await 后恢复执行的代码仍在原线程运行，其中的重计算仍可能影响 UI；恢复执行也不保证已经到了首次 build 或首帧送显之后。

分析时沿实际调用链定位同步工作，将其执行成本与异步等待时间区分。需要后台执行的 CPU 密集计算使用适用的 TaskPool/Worker，并核对结果回传与有效性。

## aboutToAppear 资源预加载的方案选择

领域评审补充：在本项目的资源预加载评审中，按方案推荐优先级从低到高考虑 **await → Promise → setTimeout → TaskPool**。这是选型偏好，不是系统调度队列的执行优先级，也不是不分任务类型的固定迁移顺序；官方依据仍按上文执行语义和具体接口核对。

- await 等待不保证首帧已显示；右侧函数和挂起前的计算仍同步执行。
- Promise 执行器同步执行，then 中的大计算也不会自动变成后台工作。
- setTimeout 可以延后提交，但回调仍在原 UI 线程上，不能据此声称重计算已异步到子线程。
- TaskPool 适用于满足接口和参数约束的 CPU 任务；真实异步 IO 可直接使用其异步服务，不为排序机械加一层任务。计入参数传递、任务排队和回传成本。

UI 节点构建、UIContext 操作和状态提交留在正确 UI 上下文；加载中离页、组件复用到新记录时，核对结果身份与任务版本。requestId 使旧结果不再提交，不代表后台任务已经取消。需要先显示目标框架的转场另读[分阶段展示](staged-display.md)。

## API 23+ 生命周期装饰器与监听

自定义组件新生命周期从 API 23 起支持（仅 Stage 模型），`@ComponentActive`/`@ComponentInactive` 从 API 26 起支持。按工程声明的 API 版本核对后再建议使用，不给低版本工程写这些接口的迁移代码。

装饰器触发时序与性能相关语义：

- `@ComponentInit`：初始化即将完成时执行，先于 `@ComponentAppear`，用于注册监听器等初始化准备；与 Appear 分别承担初始化与显现前的职责。
- `@ComponentAppear`：新实例创建后、build() 前调用，与 `aboutToAppear` 同样位于首帧路径；其中的同步重计算同样推迟构建，不因接口是新版而豁免。
- `@ComponentBuilt`：build() 首次执行后调用（APPEARED→BUILT）。可放置轻量的数据上报等不影响 UI 的工作；build 完成不代表首帧已布局、绘制或送显，不能仅将重计算移到此处就认为它已离开首帧关键路径。BUILT 回调仍在原线程执行，不是后台任务。
- `@ComponentRecycle`/`@ComponentReuse`：回收完成后（BUILT→RECYCLED）与从缓存重新加入节点树（RECYCLED→BUILT）时触发，对应 `aboutToRecycle`/`aboutToReuse`；递归触发子组件回调。回收后组件被冻结，复用池中不进行 UI 更新，但不代表已发起的异步任务已停止，仍需失效处理。V1 复用回调可带一个 `params` 入参（建议 `Record<string, Object | undefined | null>`），V2 无入参。
- `@ComponentActive`/`@ComponentInactive`（API 26）：回收入池触发 Inactive，复用出池触发 Active。
- `@ComponentDisappear`：销毁前执行，不建议修改状态变量，`@Link` 修改可能导致行为不稳定。

`CustomComponentLifecycle` 通过 `UIUtils.getLifecycle` 获取，提供 `getCurrentState()`（INIT/APPEARED/BUILT/RECYCLED/DISAPPEARED 状态机）与 `addObserver`/`removeObserver` 外部监听。addObserver 与 removeObserver 必须成对使用，组件销毁或不再需要监听时未移除，监听器会持续触发回调并造成泄漏。组件自身响应生命周期用装饰器，集中监控多个组件才用外部监听器，不为单组件引入观察者。

诊断时沿装饰器时序核对工作位置：Init/Appear 中的非必要同步计算与 aboutToAppear 同口径评估；埋点、日志等非 UI 工作位于 Init/Appear 时，可评估移至 `@ComponentBuilt` 或监听器的 `onDidBuild`；复用回调中的参数同步与资源准备按新旧两套接口的 V1/V2 入参规则检查。

## 检查方法

1. 跟进首屏相关生命周期及实际调用函数，确认数据规模、计算/IO 类型、返回结果用途和执行顺序。
2. 判断结果是否首屏必需、同版本结果是否已经存在；分别考虑推迟非必要工作、复用已有结果，或将 CPU 密集工作迁至适用的 Worker/TaskPool。同一调用路径中出现多次等价计算时，确认完整依赖与输入版本一致、跨 await 未失效，且合并不省略必要副作用，再评估计算一次并复用结果，而非将每次分别迁 TaskPool/Worker；区分“结果已在别处算好可直接读”与“本路径多次等价调用应合并为一次”两种复用。
3. 迁移时说明数据传输、业务顺序和主线程更新条件，不提供未核对 API 版本的完整迁移代码。缺被调函数或工作规模时请求最小调用代码，不编造耗时。
4. 遇到 async 生命周期时，沿调用链确认实际执行的同步工作及所在阶段，分别评估计算成本和异步等待时间。

## Bad case

前提：computeLargeDataset 在当前线程循环处理大量数据；同一数据版本的 total 已在既有数据准备流程中计算并可直接读取，此处仍重复计算。

```ts
aboutToAppear() { this.total = this.computeLargeDataset(); }
```

## Good case

```ts
aboutToAppear() { this.total = this.preparedTotal; }
```

preparedTotal 必须对应当前数据版本。这里消除的是已有结果的重复计算；若结果尚未准备好，需按实际依赖安排计算，不能把重计算简单挪到另一个 UI 生命周期，或只改为 async 就视为已解决。

## 建议与验证

结果非首屏必需时，可推迟到不影响关键内容显示的时机；必须计算的 CPU 密集工作按支持条件评估线程迁移。仅赋初始显示文本等轻量工作无需机械异步化。

保持初始化依赖顺序、取消/销毁场景和结果更新正确；无法获取 UI 的后台任务不直接操作 UI 对象。
代码与条件足够时直接给建议，不要求 Trace。必要信息已检查仍无法解释持续慢，再使用 [Trace 指导](../trace-guidance.md) 选择相关阶段。

## 打点与预期变化

对应打点：查看目标页面的 `CustomNode:OnAppear` 与其中的同步计算，结合 CPU 调用栈确认耗时函数。迁移到 TaskPool/Worker 后，预期 UI 线程生命周期内的重计算工作减少，并在实际任务线程观察到计算仍完成；需要精确归因时由开发者给计算增加业务打点。初始化次数不必减少，总 CPU 工作也不一定减少，必须同时检查结果回传、失败和离页失效，不能只凭区间变短认定业务等价。

复用已有结果时，比较同一数据版本的实际计算次数，并计入结果准备阶段；预期生命周期中的重复计算减少，不能把计算提前执行说成总成本消失。

async 回调分别观察同步调用区间和恢复后的续体，关联实际 build/布局/送显时间；回调同步返回只代表框架可以继续，不代表整个异步任务完成，也不代表续体成本已消失。标记同步段时在 await 挂起前结束该段打点，恢复后另起续体打点；跨 await 的区间包含等待，不能当作同步 CPU 耗时，也不能假定全部续体都嵌套在 CustomNode:OnAppear 中。未确认调度时序时，不断言首帧必然显示哪个中间状态。

## 依据

[减少首帧绘制时的冗余操作：减少自定义组件生命周期时间](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reduce-redundant-operations-when-render-first-frame.md#减少自定义组件生命周期时间)。

[自定义组件生命周期：aboutToAppear](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-custom-component-lifecycle.md#abouttoappear)规定其在首次 build 前调用；[异步并发](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/arkts-utils/async-concurrency-overview.md)与 [ECMAScript AsyncFunction/Await 语义](https://tc39.es/ecma262/multipage/control-abstraction-objects.html#sec-async-functions-abstract-operations)用于区分同步执行、等待与续体，不将 async/await 当作线程迁移。

[自定义组件的生命周期（推荐）](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-custom-component-new-lifecycle.md)规定 API 23 起 @ComponentInit/@ComponentAppear/@ComponentBuilt/@ComponentDisappear/@ComponentRecycle/@ComponentReuse 与 CustomComponentLifecycle（getCurrentState/addObserver/removeObserver）的触发时序；@ComponentActive/@ComponentInactive 从 API 26 起支持，均仅 Stage 模型可用。
