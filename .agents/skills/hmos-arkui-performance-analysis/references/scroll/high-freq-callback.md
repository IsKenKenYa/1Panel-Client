# 高频回调精简

## 前提与机制

先核对回调的实际触发条件、频率和函数体，再判断累计成本。onDidScroll 可在滑动过程中频繁触发；onTouch 按触摸事件触发，onAreaChange 按布局引起的区域变化触发，不是所有渲染帧必调。List.onScrollIndex 在可见首尾/中间索引变化等条件下触发，不等于翻页或滑动结束，也不能一概当作低频回调。

日志的成本取决于设备、日志级别、参数构造和采集配置，不使用单次 600μs 等固定值判定。Release 不保证所有级别的 hilog 都被移除；日志调用前的字符串构造或序列化仍会执行。调试统计、重复计算和空监听可增加工作，但函数调用、@State 赋值、await 或网络请求本身都不是耗时证据。

@State 只通知实际依赖它的更新；是否引起布局取决于属性与约束。不能把所有状态赋值解释为双向绑定或必然重新布局。getData/itemGenerator/keyGenerator 也可能随数据规模和滚动路径频繁执行，不能按回调名称豁免其中的重计算。

## 检查方法

1. 读取 onDidScroll/onTouch/onAreaChange/onActionUpdate/animator.onFrame 等回调及其调用目标，核对日志、参数序列化、循环、同步 IO 和重复计算。异步等待与当前线程执行的同步工作分别判断。
2. 检查 hiTraceMeter 的频率、名称及参数构造、配对与实际采集需要。必要的业务打点可保留，不因 Release 构建一律要求删除。
3. 检查 `.width()`/`.fontSize()` 等属性入参的调用目标与依赖。O(1) 判断、读取现成字段属于正常写法；确有昂贵且可复用的计算时，才按依赖变化准备结果。
4. 删除无业务用途的空监听或仅打印调试日志的监听；必要的几何同步、无障碍或业务通知保留。移除某个监听不代表框架的全部区域跟踪工作消失。
5. 核对回调中每个状态字段是否驱动 UI、派生值、监听或跨组件同步。纯统计可用普通字段；参与显示的字段须保留有效响应链，不为少一次状态赋值破坏字号、文本或交互更新。

## Bad case

前提：V1，父组件在滑动过程中持续更新 data；calcSize 的日志随相关 UI 更新重复执行，空区域监听没有业务用途。

```ts
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
struct BadCallbackItem {
  @Prop data: string = '';
  build() {
    Column() {
      Text(this.data).fontSize(this.calcSize())
    }
    .onAreaChange(() => {})
  }
  calcSize(): number {
    hilog.info(0x0000, 'tag', 'calcSize called with %{public}s', this.data);
    return this.data.length * 2 + 14;
  }
}
```

可精简的是调试日志和无用途监听。字号计算本身只是廉价表达式，不能据此报告昂贵重复计算；示例也没有额外的字符串拼接或序列化，不编造对应开销。

## Good case

保留当前 data 到文字和字号的响应关系，仅删除无用工作：

```ts
@Component
struct GoodCallbackItem {
  @Prop data: string = '';
  build() {
    Column() {
      Text(this.data).fontSize(this.data.length * 2 + 14)
    }
  }
}
```

若真实计算昂贵，按完整依赖准备和失效，不能只在 aboutToAppear 计算一次后忽略后续数据更新。具体见[高频重复工作](../component/frequent-work.md)。

下面的计数只经 displayText 驱动界面，可保存为普通字段；displayText 的必要逐次更新仍存在，不能宣称已消除每帧 UI 更新。若计数还参与其他 UI 绑定或 @Watch，须分别保留其响应关系。

```ts
@Entry
@Component
struct Page {
  @State displayText: string = '';
  private scrollCount: number = 0;
  build() {
    Column() {
      Text(this.displayText)
      List() { /* 保留原有条目 */ }
        .onDidScroll(() => {
          this.scrollCount++;
          this.displayText = `scrolled ${this.scrollCount} times`;
        })
    }
  }
}
```

## 实时回调与高负载 UI 提交

不变结果按依赖预计算，可合并事件按业务节流并保留最终值。CPU 重计算读取[生命周期执行边界](../startup/lifecycle-work.md)，需要留在 UI 线程且允许分批的子树提交读取[共享分帧规则](../component/frame-splitting.md)。aboutToAppear 与 DisplaySync 不会自动把工作迁到后台，异步 IO 也不因出现在回调中就必须包一层 TaskPool。

需要后台计算且目标版本支持时，TaskPool 示例应同时处理空输入、失败和离页后的过期结果。以下为 API12+、V1 的局部示例，data 在本次任务期间不变；业务允许时才按此路径安排计算：

```ts
import { taskpool } from '@kit.ArkTS';

@Concurrent
function heavyCompute(data: string): number {
  if (data.length === 0) { return 0; }
  let result = 0;
  for (let i = 0; i < 10000; i++) {
    result += data.charCodeAt(i % data.length);
  }
  return result;
}

@Component
struct GoodAsyncItem {
  @State result: number = 0;
  @State errorText: string = '';
  private data: string = '';
  private requestId: number = 0;

  aboutToAppear(): void { this.loadData(); }
  aboutToDisappear(): void { this.requestId++; }

  private async loadData(): Promise<void> {
    const requestId = ++this.requestId;
    const data = this.data;
    try {
      const result = await taskpool.execute(heavyCompute, data) as number;
      if (requestId === this.requestId && data === this.data) {
        this.result = result;
        this.errorText = '';
      }
    } catch {
      if (requestId === this.requestId && data === this.data) {
        this.errorText = '计算失败';
      }
    }
  }

  build() {
    Column() {
      Text(`${this.result}`)
      Text(this.errorText)
    }
  }
}
```

requestId 只使结果失效，不代表后台任务已取消。真实组件若会换数据、隐藏或回收入池，按这些实际路径更新任务版本并处理重启；每次复用需要的字段同步不能只放在初次 aboutToAppear，见[共享复用规则](../component/reuse-and-keys.md)。

## 建议与验证

调试日志按业务删除、限频或使用工程实际存在的调试开关；需要保留时，可在构造昂贵参数前用 hilog.isLoggable 检查对应日志级别。Trace 打点按采集目的和成本管理；API19+ 可在适用时用 hiTraceMeter.isTraceEnabled 判断是否开启捕获，不把它写入 API12 的无条件替换代码。所有成对打点保持参数匹配。

节流会降低更新频率，debounce 可能直到连续事件停止后才执行；只有时序允许时采用。必要的逐次 UI 更新、轻量赋值和 O(1) 计算可保留。预计算须随依赖失效，后台任务须保持结果身份与资源清理。

比较相同构建、设备、数据和滚动路径的回调单次及累计耗时；需要观察帧工作时，关联实际更新帧的完整 ReceiveVsync Duration，不能仅由 FlushVsync 间隙判定掉帧。未实测只写预期，细节见[验证方法](../verification.md)和[Trace 指导](../trace-guidance.md)。

## 打点与预期变化

| 对应场景 | 观察对象 | 预期与限制 |
|---|---|---|
| 回调内日志 | 实际回调的业务打点/CPU 调用栈，按需关联更新帧 | 删除或限制无用日志后，其参数构造和输出工作减少；帧耗时是否下降由运行结果确认 |
| 回调内重计算 | 函数计数、单次和累计耗时、执行线程 | 按依赖复用可减少重复计算；TaskPool 可减少 UI 线程计算工作，迁到其他 UI 回调不代表总成本消失 |
| 删除空监听 | 当前监听的调用次数及事件分发工作 | 该无用途回调不再分发；总体收益与原触发频率有关，不承诺所有区域跟踪或布局消失 |
| 纯统计改普通字段 | 目标状态的实际依赖与更新记录 | 无依赖的统计不再参与状态管理；需要驱动显示的字段及其更新仍保留 |

## 依据

- [List.onScrollIndex](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-list/)：可见索引变化等触发条件。
- [HiLog](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hilog/)：日志级别、Release 下 DEBUG 的默认行为及 isLoggable。
- [HiTraceMeter](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hitracemeter/)：性能打点与 isTraceEnabled 的版本条件。
- [TaskPool](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/js-apis-taskpool/)：并发函数、参数约束和异步结果。
- [避免高频回调内执行耗时操作](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/avoid_high_frequency_callback_execute_lengthy_operation.md)、[避免冗余操作](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/avoiding-redundant-operations.md)：结合实际频率和业务语义精简工作。
