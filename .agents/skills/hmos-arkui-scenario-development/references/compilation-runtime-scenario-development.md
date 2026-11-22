# 编译与运行时案例集

## 目录

### [一、稳定性问题](#一稳定性问题)
1. [网络图片 syncLoad 同步下载导致冻屏](#场景1网络图片-syncload-同步下载导致冻屏)
2. [自定义组件 aboutToDisappear 回调异常](#场景2自定义组件-abouttodisappear-回调异常)

### [二、渲染卡顿](#二渲染卡顿)
3. [主线程耗时操作导致丢帧](#场景3主线程耗时操作导致丢帧)
4. [滑动场景长帧与丢帧分析](#场景4滑动场景长帧与丢帧分析)

### [三、响应时延](#三响应时延)
5. [滑动列表占位符加载完成时延](#场景5滑动列表占位符加载完成时延)

### [四、状态与渲染异常](#四状态与渲染异常)
6. [列表 key 不稳定致渲染错乱](#场景6列表-key-不稳定致渲染错乱)
7. [@Watch 回调修改被监听变量致死循环](#场景7watch-回调修改被监听变量致死循环)
8. [子线程直接更新 @State 致 UI 不刷新](#场景8子线程直接更新-state-致-ui-不刷新)

---

## 一、稳定性问题

### 场景1：网络图片 syncLoad 同步下载导致冻屏

**场景描述：** 列表 / 九宫格铺满网络图片，页面打开就卡死几秒；快速滑动时整个界面冻住、点击无响应；弱网下直接弹「应用无响应 / ANR」。系统日志出现 **AppFreeze / ThreadBlock** 事件。本地小图不明显，弱网 / 超时场景症状急剧恶化。

**根因：** `Image` 组件的 `syncLoad`（API 8+）默认 `false`（异步）。一旦设为 `syncLoad(true)`，图片的**下载（网络 IO）与解码（CPU 密集）会同步在主线程执行**。网络下载耗时不可控、大图解码可达数十毫秒，主线程被这两类操作阻塞后无法处理输入事件与下一帧渲染，连续超时即被 watchdog 判定为应用冻屏。**`syncLoad(true)` 严禁用于网络图。**

**诊断方法：**
- **HiAppEvent**：订阅 `APP_FREEZE` 事件，确认故障类型为 ThreadBlock，取瞬时栈。
- **DevEco Studio Profiler / hiLog**：看主线程是否长时间停留在图片解码 / 网络请求栈帧。
- **弱网复现**：用限速 / 断网放大阻塞时长，若冻屏随之恶化即可佐证。

**解决方案：** 网络图保持 `syncLoad` 默认 `false`（异步），用占位图兜底。

```ts
// ❌ 反例：网络图开启同步加载，主线程被下载 + 解码阻塞
List({ space: 8 }) {
  ForEach(this.urls, (url: string) => {
    ListItem() {
      Image(url).syncLoad(true).width(120).height(120)   // 网络 IO + 解码全在主线程
    }
  }, (url: string) => url)
}

// ✅ 正例：保持异步，占位兜底 + 按显示尺寸解码
Image(url)
  .alt($r('app.media.ic_placeholder')) // 加载过程中显示占位图，避免白屏闪烁
  .autoResize(true)                    // 仅按显示尺寸解码，省内存
  .width(120).height(120)
```

若确需「先拿到图再展示」的同步语义，应**异步预下载到本地再交给 Image**：

```ts
import { request } from '@kit.RequestKit';
import { common } from '@kit.AbilityKit';

// context 由调用方（组件）传入，如 getContext(this)
async function prefetch(context: common.UIAbilityContext, url: string): Promise<string> {
  const filePath = `${context.cacheDir}/${Date.now()}.png`;   // 本地缓存路径
  const task = await request.downloadFile(context, { url, filePath });
  await new Promise<void>((resolve, reject) => {              // DownloadTask 无 complete()，用 on 回调等待
    task.on('complete', () => resolve());
    task.on('fail', () => reject(new Error('下载失败')));
  });
  return filePath;   // Image 直接加载该本地文件
}
```

**关键点 / 避坑：**
1. `syncLoad(true)` 仅适合**本地小图**（已知尺寸的图标 / 已解码 PixelMap），**严禁用于网络图**。
2. 长列表网络图务必配 `autoResize(true)` + `alt`（占位）+ 图片缓存库，避免重复下载与内存峰值。
3. 生命周期函数内禁止任何同步网络 / 文件操作（`fs.openSync` 同理需改 `await`）。
4. 复现优先用弱网 / 断网放大信号，再用 HiAppEvent + Profiler 定界主线程阻塞栈。

---

### 场景2：自定义组件 aboutToDisappear 回调异常

**场景描述：** Navigation 路由返回、`if` 分支由 true 变 false、ForEach 数组项减少或应用退出后，出现报错崩溃；在 `aboutToDisappear` 里读到的对象变 undefined / 空引用；回调里跑的 `setTimeout` / `Promise` 把组件引用取出来再用就报错或 UI 不刷新。

**根因：** `aboutToDisappear` 在自定义组件**析构销毁之前**执行，此时后端节点已标记 detached、即将被摘除，组件实例及 `@State/@Link` 随时会被 GC。三类典型错误：
- **改状态变量**：尤其改 `@Link` 会破坏与同步源的绑定关系，导致应用行为不稳定。
- **异步闭包持有 `this`**：`async/await` / `Promise` / `setTimeout` 闭包持有组件实例，阻止 GC；异步任务真正执行时引用大概率已失效。
- **方法重名 override**：在 `@Component` 内定义与生命周期同名的业务方法，框架回调时序错乱，异常可能被框架静默吞掉。

**诊断方法：** `aboutToAppear` / `aboutToDisappear` / 异步任务内分别 `hilog.info` 打点，确认回调与异步任务的执行时序；用 `errorManager.on('error')`（`@kit.AbilityKit`，注册全局错误观测器，其 `onException` 回调可拿到异常 name/message/stack）观测回调里未处理的异常；回调体内加 try-catch 打印 stack 定位失效对象。

**解决方案：** 回调内只做**同步清理**（取消定时器、解注册监听、关闭资源），耗时任务提前到 `aboutToAppear` 注册并在销毁前取消。

```ts
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
struct Child {
  @State count: number = 0
  private timer: number = -1
  private disposed: boolean = false

  aboutToAppear() {
    this.timer = setInterval(() => {
      if (this.disposed) return   // 销毁后异步任务自行退出
      this.count++
    }, 1000)
  }

  aboutToDisappear() {
    clearInterval(this.timer)     // ① 同步清理定时器 / 监听
    this.disposed = true          // ② 标记已销毁
    try {
      hilog.info(0x0000, 'Child', 'cleanup done')
    } catch (e) {                 // ③ try-catch 兜底，避免静默吞异常
      hilog.error(0x0000, 'Child', 'cleanup error: %{public}s', `${e}`)
    }
    // 切勿在此修改 @State/@Link，切勿再启动持有 this 的异步任务
  }

  build() { Text(`${this.count}`) }
}
```

**关键点 / 避坑：**
1. 回调内**禁改状态变量**（尤其 `@Link`）；只读的子组件别用 `@Link`，改用 `@Prop` 单向。
2. **禁用 async/await / Promise**：异步闭包持有 `this` 阻止 GC。
3. 销毁收尾以同步清理为主；耗时任务提前注册、销毁前取消。
4. 不要在 `@Component` 内定义与 `aboutToAppear/aboutToDisappear` 同名的业务方法。

---

## 二、渲染卡顿

### 场景3：主线程耗时操作导致丢帧

**场景描述：** 「列表滑动明显卡顿」「点击按钮界面冻住半秒」「加载更多时动画中断」「冷启动白屏长」。Profiler Trace 中主线程出现连续长任务（引自性能最佳实践，单次 20ms+，超过 8.3ms 的 Vsync 周期），丢帧率高。诱因往往不是 UI 写得复杂，而是主线程在「不该做事的地方」做了重活。

**根因：** ArkUI 的布局、绘制、状态刷新、Vsync 回调全跑在主线程。一旦某段代码独占主线程超过一帧（约 16.6ms@60fps / 8.3ms@120fps），本帧渲染管线被挤压即丢帧。常见耗时源（下列耗时数值引自性能最佳实践，量级参考）：
- **高频回调里塞耗时操作**：`onWillScroll`、`aboutToReuse`、`aboutToAppear`、`LazyForEach` 的 `itemGenerator/keyGenerator`、组件属性入参函数——每帧 / 每 item 触发一次，叠加百万循环、JSON.parse、同步 IO 后单次轻松突破 20ms。
- **接口选错**：`getStringSync($r(...))` 传 resource 对象（该 Resource 重载已废弃、有额外开销，~1.9ms），传 `.id`（number 重载）更轻（~0.07ms）。
- **release 残留冗余**：未移除的 `hilog.debug`、空 `onAreaChange` 回调，底层仍有跨层通信开销（实测单条日志均值 84μs，一次滑动累计 35ms+）。

**诊断方法：** 用 DevEco Studio Profiler 的 Frame 轨道抓滑动/点击时段，定位 Main 线程红色长帧所在函数（可疑回调可用 hiTraceMeter `startTrace/finishTrace` 量单次耗时）；Code Linter 可批量扫描空回调和主线程网络请求。

**解决方案：**

```ts
import { taskpool } from '@kit.ArkTS';

// ① 高频回调瘦身：只留轻量赋值，耗时计算下沉 TaskPool
@Concurrent
function parseData(raw: ArrayBuffer): Model[] {
  return JSON.parse(new TextDecoder().decode(raw)) as Model[];   // 子线程解析，不卡主线程
}
aboutToAppear() {
  taskpool.execute(parseData, this.rawBuffer).then((res: Model[]) => this.dataList = res)
}

// ② 接口选优：传 id 而非 resource 对象
resourceManager.getStringSync($r('app.string.test').id)   // ✅ 引用 0.07ms
// resourceManager.getStringSync($r('app.string.test'))   // ❌ 深拷贝 1.9ms
```

**关键点 / 避坑：**
1. **异步 ≠ 不阻塞**：`async/await` 的回调最终仍由主线程执行，`JSON.parse` 大数据照样卡帧，必须下沉 `taskpool`/`Worker`。
2. **回调频率决定危害**：`onWillScroll`、`aboutToReuse`、`itemGenerator` 每帧 / 每项触发，单次仅几毫秒高频叠加也会连续丢帧——优先排查热点。
3. 组件属性是「整体刷新」，改一个 `width` 会连带重算同组件其他属性入参函数，不要把耗时函数挂在任何属性上。
4. release 包必须移除测试接口（`getInspectorByKey` / `sendEventByKey`）与冗余日志 / 空回调。

---

### 场景4：滑动场景长帧与丢帧分析

**场景描述：** List / Grid / Scroll 长列表滑动「卡顿、不跟手」：滑动中画面撕裂、瞬时停滞、白块或残影；Profiler 中应用或 RenderService 进程连续丢帧（**最大连续丢帧数 ≥ 3 用户即可明显感知**）；帧率波动大无法稳定在 60fps / 120fps；快速 fling 惯性滚动阶段卡顿尤其明显。

**根因：** 每帧渲染超时即长帧 / 丢帧。ArkUI 渲染流水线分 Animation → Events → UpdateUI → Measure → Layout → Render → SendMessage 七阶段，任一阶段过长都拖垮整帧。常见拖累项：
- **组件复用失效**：滑动时大量 `H:CustomNode:BuildItem`，未命中复用池而重复创建。
- **@Prop 深拷贝**：复杂 Object / class 传入触发 `deepCopyObject`，BuildItem 阶段 3ms+（引自性能最佳实践）。
- **冗余状态变量**：`@State` 修饰但未绑定 UI 的变量，每次更新仍走 Set 流程产生耗时。
- **LazyForEach 全量刷新**：`notifyDataReload()` 导致大量项重建。
- **嵌套层级深 / cachedCount 过小**：每帧 measure 阶段才创建 item。

**诊断方法：** 抓 Trace 前先开 ArkUI debug 开关（`hdc shell param set persist.ace.trace.enabled 1` 等）。用 Profiler Frame 轨道先判断丢帧在**应用进程还是 RS 进程**（RS 丢帧但应用侧均衡，多半是系统绘制问题），再框选红色帧到 ArkTS Callstack 看耗时阶段——重点看 `BuildItem`（复用失效）、`deepCopyObject`（@Prop 深拷贝）、`ViewPU.ViewPropertyHasChanged`（冗余状态变量）。

**解决方案：**

```ts
// ① @Reusable + reuseId 正确启用复用（消除滑动时的 BuildItem）
@Reusable
@Component
struct OneMomentItem {
  @State item: MomentData = new MomentData()
  aboutToReuse(params: Record<string, Object>): void { this.item = params.item as MomentData }
  build() { /* ... */ }
}
LazyForEach(this.dataSource, (item: MomentData) => {
  OneMomentItem({ item }).reuseId(item.type === 'video' ? 'video' : 'image')  // 多模板必须用 reuseId 区分
}, (item: MomentData) => item.id)

// ② 用 @ObjectLink 替代 @Prop（避免深拷贝）
@Observed class MomentData { id: number = 0 }
@Component struct Child { @ObjectLink item: MomentData }   // 浅拷贝

// ③ 删除未绑定 UI 的冗余状态变量
scrollOffset: number = 0   // 改普通变量，不再走 @State 的 Set 流程

// ④ 减少嵌套：RelativeContainer 扁平化 或 @Builder 代替 @Component（避免 __Common__ 节点）
```

**关键点 / 避坑：**
1. **先定位丢帧进程**：Frame 轨道区分应用 vs RS，避免误判。
2. **抓 Trace 必开 debug 开关**，否则看不到引起标脏的具体变量。
3. **@Prop 严禁传复杂对象**：单帧 BuildItem 若 3ms+ 基本就是深拷贝。
4. **组件复用看 reuseId**：仅加 `@Reusable` 不够，多模板场景必须用 `reuseId` 区分，否则复用池命中率低。

---

## 三、响应时延

### 场景5：滑动列表占位符加载完成时延

**场景描述：** 长列表惯性滚动停止后，屏幕内图片占位符迟迟加载不出来、出现空白块；上拉加载更多后 loading 动画卡很久才结束；上拉次数越多加载越慢；占位图加载带的透明度 / 缩放渐变动画反而拖长感知等待。

衡量指标 **「滑动页面占位符加载完成时延」**：从滚动停止（`APP_LIST_FLING` 终点）起算，到屏幕内占位符加载完成（应用不再向 RenderService 提交 Vsync）为止，**标准 ≤ 40ms**。

**根因：**
- **网络时延**：上拉触发 `createHttp → request → parse → OnDataReloaded` 链路过长，外加网图 `CreateImagePixelMap` 解码耗时。
- **渲染时延**：主线程超长帧 / 异常帧。常见于 LazyForEach 用 `notifyDataReload()` 全量刷新，或子组件未用 `@Reusable` 在滑动中被 `aboutToBeDeleted` 析构后又重建。
- **动画时延**：占位图加载用了 `JSAnimation`（透明度 / 缩放），duration 直接叠加在加载完成时延上。

**诊断方法：** 以 `APP_LIST_FLING` 终点（滚动停止）为起点、应用停止送帧为终点度量，标准 **≤ 40ms**。用 Profiler Frame 泳道定位超长帧成因——常见于 LazyForEach 全量刷新（`notifyDataReload`）、组件未复用（大量 `aboutToBeDeleted`）、占位图 `JSAnimation` duration 拖累。

**解决方案：**

```ts
// ① 网络：预请求（快滑到底部提前触发）+ 本地占位 + 图片缓存
Image(item.url).alt($r('app.media.placeholder')).objectFit(ImageFit.Cover)

// ② 改全量刷新为局部刷新（性能杀手 notifyDataReload）
this.dataSource.notifyDataAdd(this.dataSource.totalCount() - 1)  // ✅ 仅刷新新增项
// this.dataSource.notifyDataReload()                            // ❌ 键值未变的项也被重建

// ③ @Reusable 复用，避免滑动中 GridItem 反复析构重建
@Reusable @Component
struct GridItemView {
  @State item: Item = new Item()
  aboutToReuse(params: Record<string, Object>): void { this.item = params.item as Item }
  build() { /* ... */ }
}
LazyForEach(this.dataSource, (item: Item) => {
  GridItem() { GridItemView({ item }) }.reuseId('gridItem')
}, (item: Item) => item.id.toString())

// ④ 动画：评估占位图渐变动画必要性，缩短 duration 或移除
```

**关键点 / 避坑：**
1. **先定起止点再分析**：务必用 `APP_LIST_FLING` 终点作为时延起点，否则测量口径错误。
2. **`notifyDataReload` 是性能杀手**：增量数据用 `notifyDataAdd/notifyDataChange` 局部刷新。
3. **`@Reusable` + `reuseId` 必须配对**：Trace 里大量 `aboutToBeDeleted` 即未复用信号。
4. **动画时长 = 时延**：占位图加载阶段的自定义动画 duration 直接计入加载完成时延，能免则免。

---

## 四、状态与渲染异常

### 场景6：列表 key 不稳定致渲染错乱

**场景描述：** 列表 / 网格在删除、插入、排序或下拉刷新后，部分项显示错位的内容——删除第二项后第三项内容没动、缩略图串显到别的条目、输入框文字对到错误的一项；或数据变了界面却不刷新。

**根因：** ForEach / LazyForEach 靠 `keyGenerator` 生成的键值来识别"哪个数据对应哪个组件"，决定增删改时是复用还是重建。键值必须满足**唯一性 + 一致性**（数据不变则键不变）。常见错误：
- **用 index 作 key**：`(item, i) => i.toString()`——删除 / 重排后同一 index 指向了不同数据，框架判定为"同一组件、数据变了"，复用旧组件塞入新数据，导致内容错位、图片串显。
- **LazyForEach 不传 keyGenerator**：默认键值是 `viewId + '-' + index`（仅受 index 影响），同样不稳定。
- **key 不唯一或随时间变化**：框架无法正确识别增删，该刷新的不刷新、不该重建的重建。

**诊断方法：** 现象只在"增删 / 排序 / 刷新"时出现、纯展示不动时正常 → 基本就是 key 问题。检查 keyGenerator 是否用了 index、是否唯一且持久。

**解决方案：**

```ts
// ❌ 反例：用 index 作 key，删除/重排后内容错位
ForEach(this.list, (item: Item) => {
  ListItem() { ItemRow({ item }) }
}, (item: Item, index: number) => index.toString())   // index 不稳定

LazyForEach(this.dataSource, (item: Item) => {        // 没传 keyGenerator → 默认 viewId-index
  ListItem() { ItemRow({ item }) }
})

// ✅ 正例：用数据自身的稳定唯一 id 作 key
ForEach(this.list, (item: Item) => {
  ListItem() { ItemRow({ item }) }
}, (item: Item) => item.id.toString())

LazyForEach(this.dataSource, (item: Item) => {
  ListItem() { ItemRow({ item }) }
}, (item: Item) => item.id.toString())                // 显式提供稳定唯一 key
```

**关键点 / 避坑：**
1. key 必须满足「唯一 + 持久」：每个数据项对应唯一键，数据不变时键不变。
2. **严禁用 index 作 key**：删除 / 插入 / 排序后 index 与数据错位，组件复用到错误数据。
3. LazyForEach 别省 keyGenerator（默认是 index 系），长列表务必显式传 `item.id`。
4. keyGenerator 内不要做耗时操作（如对整个对象 `JSON.stringify`），会拖垮滑动性能。

---

### 场景7：@Watch 回调修改被监听变量致死循环

**场景描述：** 给某个 @State / @Prop / @Link 变量加了 @Watch 监听，改动该变量后界面卡死无响应，甚至栈溢出崩溃；或 CPU 飙高、严重掉帧。

**根因：** @Watch 回调在状态变量变更后**同步执行**；若在回调里（直接或间接）又修改了被监听的同一个状态变量，会再次触发该 @Watch → 无限递归 → 卡死 / 栈溢出。@Watch 的设计用途是"快速响应变化做轻量计算"，不应在其中改回被监听变量、也不应做异步重活。

**诊断方法：** 现象在"改动某个被 @Watch 的变量"后立刻出现 → 排查该 @Watch 回调函数体，是否对被监听变量（或会间接触发它的变量）做了赋值。

**解决方案：**

```ts
// ❌ 反例：回调里改被监听变量 → 无限递归
@State @Watch('onCountChanged') count: number = 0
onCountChanged(prop: string): void {
  this.count = this.count + 1   // 又改 count → 再次触发 onCountChanged → 死循环
}

// ✅ 正例：回调只读被监听变量、只改"别的"状态
@State @Watch('onCountChanged') count: number = 0
@State total: number = 0
onCountChanged(prop: string): void {
  this.total = this.count * 10   // 读 count、改无关的 total，不动 count 本身
}
```

**关键点 / 避坑：**
1. **不要在 @Watch 回调里修改它监听的变量**（直接或间接），否则死循环。
2. 回调只做快速运算；不要在 @Watch 里用 async/await（异步会拖慢重新渲染）。
3. 多个变量绑定同一个 @Watch 回调时，用 `changedPropertyName` 参数区分处理。

---

### 场景8：子线程直接更新 @State 致 UI 不刷新

**场景描述：** 把耗时任务（数据请求、解码、批量计算）放到 TaskPool / Worker 子线程，算完结果后界面没更新；同样的逻辑放主线程就能正常刷新。

**根因：** @State 等状态变量驱动 UI 刷新依赖主线程的渲染管线，**状态必须在 UI（主）线程更新**。子线程里算出的结果不会自动流回主线程的状态——"丢"在子线程的赋值不触发渲染；且 @State / @Observed 装饰的复杂对象本身不能跨线程传输。

**诊断方法：** 子线程跑完后 UI 不动、把同样赋值挪到主线程就正常 → 即跨线程更新问题。

**解决方案：** 把子线程的结果"送回"主线程，在主线程赋值 @State。

```ts
import { taskpool } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';

// ① 一次性结果：return + then（.then 在主线程执行，最简单）
@Concurrent
function heavyCompute(input: number): number {
  return input * 2   // 子线程算完 return，不要在这里碰任何 @State
}
aboutToAppear() {
  taskpool.execute(heavyCompute, 42).then((res: number) => {
    this.value = res   // 主线程赋值 @State → UI 正常刷新
  })
}

// ② 持续 / 流式产出（如长时任务）：emitter 发回普通数据
const EVT = 1001
@Concurrent
function streamProduce(): void {
  // 持续产出，用 emitter 发回"普通数据"（不能是 @State/@Observed 对象）
  emitter.emit({ eventId: EVT }, { data: { v: newData } })
}
aboutToAppear() {
  emitter.on({ eventId: EVT }, (e: emitter.EventData) => {
    this.value = e.data?.v as number   // 主线程回调里赋值 @State
  })
}
aboutToDisappear() {
  emitter.off(EVT)   // 销毁时注销订阅，避免泄漏
}
```

**关键点 / 避坑：**
1. **状态必须在主线程更新**：子线程直写 / 丢结果都不会触发渲染。
2. 一次性结果优先 `taskpool.execute(fn).then(res => this.x = res)`；持续产出才用 emitter。
3. emitter 只传**普通数据**（不能是 @State / @Observed 装饰的对象），主线程回调里再赋值状态。
4. emitter 订阅须在 `aboutToDisappear` 里 `emitter.off` 注销，防止泄漏。

---
