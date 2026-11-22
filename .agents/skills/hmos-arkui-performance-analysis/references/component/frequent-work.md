# 高频路径中的重复工作

## 检查场景

| 子场景 | 读取范围 | 风险成立条件 | 合理反例 |
|---|---|---|---|
| aboutToReuse | 参数生成、用户回调、调用函数 | 数据项反复复用且每次重复非必要同步计算 | 必要轻量赋值和身份更新 |
| aboutToAppear/aboutToDisappear | 创建/销毁原因、计算与清理 | 高频挂载/卸载时重复可复用计算 | 轻量初始化和必要资源释放 |
| itemGenerator/keyGenerator/getData | 数据源、key 函数、传参表达式 | 每项生成/取数都遍历、序列化或执行可提前计算的工作 | O(1) 索引访问、短稳定 key、现成字段 |
| 组件属性入参 | 同组件各属性及其调用目标 | 一个属性刷新时其他参数重复执行昂贵表达式 | 常量、简单取值、业务确需重算 |
| Repeat 回调 | each/template、key/templateId、onLazyLoading 和条目绑定 | 每次生成/分类/取数重复遍历或序列化；把一次性计算放在会重复调用的位置 | 预先准备字段、O(1) 分类和稳定 key、必要的当前项绑定 |
| FrameCallback.onFrame / onIdle | 两个帧回调的函数体、调用目标、注册频率和任务有效期 | 帧回调执行复杂计算或同步 IO；重复注册同类回调，或离页后仍更新状态 | 读取现成结果、必要的轻量状态提交及符合剩余预算的小任务 |
| onAreaChange 等布局回调 | 监听数量、关注的尺寸/位置、回写到布局的依赖链 | 区域频繁变化时重复计算，或回写影响被测布局形成反馈 | 必需的几何记录、仅相关维度变化时的轻量更新 |

缺函数体或频率证据时说明缺口，不把 fetchData/compute 等名称当成耗时证据。数组规模影响成本，但不设统一“超过 N 条必卡”的阈值；不把单次日志时间当作普遍常量。

## Bad case

```ts
sumWeights(values: number[]): number {
  let result = 0;
  for (let round = 0; round < 800; round++) {
    for (let i = 0; i < values.length; i++) { result += values[i]; }
  }
  return result;
}
aboutToReuse(params: Record<string, number[]>) {
  this.total = this.sumWeights(params.values);
}
```

前提：同一业务数据的 values 在多次复用间不变，用户只需显示总计。可指出重复同步计算风险；若每次 values 都变，必须重新安排计算，不能简单复用旧值。

## Good case

```ts
aboutToReuse(params: Record<string, number>) {
  this.total = params.total;
}
```

数据准备阶段按数据版本计算 total，依赖变更时更新结果。这里不是说“挪到 aboutToAppear 就自动异步”；计算的执行线程、时机和结果有效性仍需设计。

`aboutToAppear` 即使声明为 async 也先于首次 build 调用，首个 await 前及 await 表达式求值中的同步工作仍可能推迟构建；await 等待时让出执行，恢复后的代码仍在原线程运行。执行顺序与成本判断沿用[生命周期执行边界](../startup/lifecycle-work.md)。

迭代示例：`JSON.stringify(item)` 作为每次 key 的生成成本应结合 item 大小和频率判断；若有稳定唯一 `item.id`，可在验证身份语义后使用。`getData(index)` 中重建整份数组可改为在数据变更时更新数据源，但必须保持通知与索引一致。

属性入参示例：`Text(this.tick.toString()).fontSize(this.calculateStyle())` 中 calculateStyle 若只是返回 16，则正常；若每次扫描不变的大表，建议在依赖改变时准备结果，不能因 tick 不涉及样式就假定该函数永不执行。

## Repeat：检查实际调用路径

- `.each()`/`.template()` 定义的是节点生成逻辑，不保证随每次条目更新重新执行。昂贵初始化可能拖慢创建，普通局部变量保存的派生结果又可能在节点复用后过期；既要避免重复工作，也要保持当前项绑定。
- `.key()`/`.templateId()` 会参与识别和模板分类，应是稳定、轻量的函数。不要在其中排序、遍历全表、重复 JSON.stringify 大对象、同步 IO、打印日志或修改状态。能在数据更新阶段生成的 id、kind、显示文本，按数据版本准备一次。
- 复用后按当前 RepeatItem 读取数据、索引和事件身份，避免为解决旧值显示而反复重建节点；性能检查见[复用与 key](reuse-and-keys.md#repeat-性能检查)。
- 区分滚动容器 `.cachedCount()` 的预加载区域与 `.template(..., { cachedCount })` 的模板空闲节点池容量。扩大缓存会增加存活节点/内存，不能当作消除回调重计算的方案。
- API 19 起的 onLazyLoading(index) 需在当次回调结束前填好指定位置的数据，必要时先写占位；回调内只使用 `arr[index] = ...` 写指定索引，不 push/splice 或批量改其他位置。网络或重计算另行异步准备，结果返回时验证 ID/版本并更新对应数据，不在回调中同步等待。totalCount 大于现有数据量时同时检查缺数据、失败和占位状态。

合理反例：小且固定的列表可全量加载；纯 O(1) key/分类、真实依赖变化后的必要重算、支持版本中的正确数据占位均可保留。不机械要求打开 virtualScroll、增大缓存或关闭复用。

## onFrame / onIdle：帧回调中的耗时工作

`FrameCallback` 从API12起支持。UIContext.postFrameCallback提交下一帧任务，onFrame在该帧渲染阶段执行，onIdle在符合空闲预算的阶段执行；不自动成为永久逐帧监听。持续逐帧订阅的DisplaySync在注册并start后回调，二者不混同。重点核对回调内复杂计算和同步IO是否占用UI线程。

1. 读取两个回调及被调函数，定位循环、全表扫描、排序、深拷贝、序列化、日志参数构造和同步 IO。将不变结果按数据版本预计算；CPU 密集工作使用适用的 TaskPool/Worker，回调只读取现成结果或提交必要的轻量更新。
2. `onIdle` 的空闲时间仍是有限的帧预算，不适合承载整批复杂计算。确需留在 UI 线程的小任务按剩余预算有界拆分；需要后台执行的工作从回调中移出。仅把 onFrame 中的复杂计算搬到 onIdle，或加 async/Promise，不改变计算所在的线程。
3. 业务允许时合并同数据的未完成请求，复用已完成结果；重复提交可能重复计算，但不能据此断言永久执行、每帧成倍放大或已测掉帧。离页或换记录用有效标记/版本避免过期回写，按真实接口能力处理取消，不编造offFrameCallback或强求注销API。
4. 对比修改前后两个回调的单次耗时、每帧累计耗时与 UI 帧区间，确认计算结果、更新时机和交互仍正确。任务移出帧回调后，预期减少的是 UI 帧内的计算工作，总计算量未必减少。

进入或复用时需要分批提交重负载 UI 子树，使用[共享分帧规则](frame-splitting.md)；此处的 FrameCallback 与该规则的 DisplaySync 是不同接口，不混用生命周期或把两者称为后台线程。

`onIdle` 在空闲时间不足时会顺延，不能作为固定完成时刻。轻量读取现成结果、必要状态提交和有界空闲任务是正常用法。

依据：[FrameCallback](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-uicontext-framecallback.md)、[UIContext 帧回调注册](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-uicontext-uicontext.md#postframecallback12)。

## onAreaChange：区域变化与布局反馈

onAreaChange 响应布局引起的大小/位置变化，不是所有帧必调；translate/scale 等绘制变换不会因此触发。不能用它替代动画进度监听，也不保证父子区域回调存在固定顺序。

1. 只需要宽度时不要因位置变化重复更新；比较业务实际使用的维度，避免把整个 Area 转成字符串、记录日志或每次重算无关数据。无 UI 关联的测量结果可保存为普通字段；需要驱动 UI 的结果保留正确观测。
   若只关心尺寸，API 12 起可评估 `onSizeChange`，避免位置变化进入业务处理。但它是布局中的同步回调，直接改状态可能被纳入动画闭包；确有此风险时再选择受支持的后续帧任务或异步提交，并处理过期结果。不能只换接口名，也不能用 setTimeout 宣称重计算已离开 UI 线程。
2. 跟进回写链：如被测节点 `.width(this.boxWidth)`，回调又写 `this.boxWidth = Number(newArea.width) + 1`，可能造成多轮布局或反馈。优先使用声明式布局约束；确需测量时分开测量来源和布局输出。仅加“新旧值不同才赋值”不能修复自身持续改变尺寸的反馈关系。
3. 必需的单向测量可只在所需结果变化时提交。允许降低更新频率的业务才做节流/合并，同时保留最终值和及时交互；不对所有区域监听统一延时。
4. `onAreaChange(callback, options)` 的间隔配置重载从 26.0.0 起提供，不能直接加到 API 12/18 工程；未确认版本时不提供带 expectedUpdateInterval 的替换代码。
5. 删除没有业务用途的空监听或只输出调试日志的监听。即使回调体很短，注册仍可能带来区域跟踪与事件分发；有必要的几何同步、无障碍或业务通知不能一并删除。

验证时分别记录尺寸变化、位置变化、只做 transform 的情况，核对回调次数、布局次数、最终显示与点击命中。先按目标设备确认频率，不把一次录制结果扩成所有 onAreaChange 的固定开销。

## 建议与验证

优先消除重复工作，区分必要工作和可延后工作。需要并发时给出任务输入/输出、结果回到组件的条件和过期结果处理；仅加 async、Promise 或 setTimeout 不保证计算离开 UI 线程。不能把所有计算都迁到尚未核对的线程模型，也不把完整并发架构扩入本模块。

功能验证：输入变化后的派生值、卸载清理、复用切项、异步结果顺序；性能验证：相同动作/数据下观察相关区间频率与持续时间。未知计算先请求函数体，已知代码仍不能解释卡顿再读人工指南。

## 打点与预期变化

以下 `APP:` 名称均是建议开发者新增的业务打点，不是框架已有事件或当前 bench 已加入的业务打点。可以记录对应函数的执行次数或使用 CPU 调用栈，但两组口径必须一致；缺少精确事件时说明观察限制，不编造固定框架标签。

| 场景 | 打点或观察方式 | 修改后的预期变化 |
|---|---|---|
| 取数与条目回调 | `Builder:BuildLazyItem` 辅助定位条目构建；`APP:GetData`、`APP:ItemText`、`APP:ItemKey` 或对应函数计数/调用栈定位具体工作 | getData 内的整表复制消失，显示文本按数据版本准备，key 不再反复序列化整对象；回调调用次数不一定减少，主要比较每次工作和累计成本，准备阶段成本仍需记录 |
| Repeat key 回调 | `APP:RepeatKey` 或 key 回调 CPU 调用栈/计数 | key 内的整对象序列化消失，稳定业务 id 保持；key 回调次数与条目创建数不一定减少，不能把 LazyForEach 的 BuildLazyItem 当作 Repeat 的统一创建标签 |
| onFrame / onIdle 帧回调 | 两个回调各自的函数计数、CPU 调用栈或建议新增的 `APP:FrameTask`，在相同帧窗口比较单次和累计耗时 | 两个回调内的复杂计算及同步 IO 移出 UI 帧路径，回调只保留轻量提交；允许合并的重复任务执行次数减少，必要更新和离页失效行为保持正确 |
| 区域变化回调 | `APP:AreaCallback` 或回调计数，结合目标节点的 Measure/Layout 与 `FlushLayoutTask` | 测量值不再回写自身布局输入，多余的持续布局反馈应消失；正常尺寸/位置变化仍可触发，不能要求全部区域回调或布局次数为 0 |
