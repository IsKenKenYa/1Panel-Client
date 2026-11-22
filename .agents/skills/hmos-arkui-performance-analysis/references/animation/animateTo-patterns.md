# animateTo 闭包缺失与自定义动画

## 版本与前提

针对动态ArkTS。全局animateTo从API7支持、API18起废弃；UIContext.animateTo从API10支持，优先用于明确UI上下文。API12不能仅因使用全局接口就判为该版本已废弃。animation属性从API7、animator从API9支持，按目标版本与实际调用位置选型。

## 检查方法

1. 跟进属性初值、绑定、实际变化及触发回调。animation需要绑定属性发生变化，固定rotate(360)加无限循环参数不能代替启动。animateTo在节点已建立初值后调用，例如节点onAppear或交互回调；aboutToAppear发生在首次build前，不能在其中直接为尚未创建的内部节点启动属性动画。已有合法驱动时，直接赋值并不等于缺动画闭包；一次触发与持续驱动也不决定唯一合法API。
2. 业务要求平滑过渡，却直接修改可动画属性且没有相应驱动时，指出瞬时跳变，给出系统动画方案。缺少过渡首先是功能效果问题，不凭静态代码宣称严重卡顿。
3. setInterval/setTimeout或FrameCallback.onFrame手动逐帧计算时，评估animation/animateTo/animator能否保持触发、持续时间、曲线、完成值和必要清理。仅做属性插值、没有逐帧业务工作时，优先用animation/UIContext.animateTo提交目标值。postFrameCallback的一次登记不是永久监听，持续驱动需看再次提交。需要暂停/恢复等控制时可选animator，但AnimatorResult.onFrame逐帧写状态仍有应用回调与状态提交，不能宣称已消除这部分工作。属性动画也不等于没有UI工作，width/height等布局动画仍可能逐帧布局。
4. 检查animateTo闭包是否混入与过渡无关的文本或业务状态更新。文本内容不做字符插值，但仍会触发文本更新；业务允许延后时，将其移出动画闭包，在onFinish中更新，把这部分工作移到动画结束后。按实际UI依赖判断：驱动条件转场的布尔值属于动画依赖，不能按变量类型一律移出，也不能把文本更新说成每帧追加或非法操作。
5. animateTo同步执行闭包，属性动画持续到后续帧。仅将赋值挪到调用前后，不等于移出了动画阶段；用onFinish确定完成时机，不用固定setTimeout(duration)代替。业务明确要求同时更新时说明延后的时序代价，不擅自改变要求；不能仅凭闭包位置宣称已减少布局次数或改善帧率。

## 最小修改示例

进入后开始旋转：保留angle初值，在Text出现后一次提交360°目标，3000ms一圈、线性循环。此处只演示启动；当前存在Tab等不可见路径时，还需按[不可见刷新](redundant-refresh.md)接入实际控停。

```ts
@Component
struct SpinningIcon {
  @State angle: number = 0;
  build() {
    Text('旋转')
      .rotate({ angle: this.angle })
      .onAppear(() => {
        this.getUIContext().animateTo({
          duration: 3000, curve: Curve.Linear, iterations: -1
        }, () => { this.angle = 360; });
      })
  }
}
```

原点击只要求展开时，保留展开语义，不额外增加收起交互：

```ts
this.getUIContext()?.animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
  this.cardWidth = 400;
});
```

文本追加与高度、透明度过渡无关，且业务允许动画结束后更新时，将文本更新移出动画闭包。保留点击触发、300ms过渡及最终文本，改用onFinish确定更新时机：

```ts
this.getUIContext()?.animateTo({
  duration: 300,
  curve: Curve.EaseInOut,
  onFinish: () => {
    this.message += '1';
  }
}, () => {
  this.cardOpacity = 0.8;
  this.cardHeight = 300;
});
```

## 建议与验证

- 动画是否发生及视觉效果：观察或录屏检查过渡、触发和结束状态；状态赋值的起止日志只能说明提交值，不能单独证明屏幕每帧插值。只要求展开的输入，不以缺少收起作为失败。
- 手动逐帧改属性动画：保持相同参数与动作，比较实际启动至结束或固定循环窗口内的回调次数与UI工作；已删除的定时器在返回可见后也应保持零回调，用视觉或新驱动指标验证动画恢复。采用animator时按实际onFrame工作解释收益，不预设固定帧率收益。
- 无关状态更新移出动画阶段：在触发、onFinish和文本赋值处记录时间戳，配合录屏确认文本从动画开始时更新改为结束后更新，过渡与最终内容正确。Trace可比较相同初始内容、相同点击下动画窗口内的文本更新和布局工作；延后不等于取消这部分工作，不宣称总耗时必然下降。已有取消/销毁路径时保留相应处理。
- Trace可辅助观察实际布局、渲染或线程工作，不能仅凭ReceiveVsync总时长或RSThread事件是否出现就证明属性已被插值。选择方法见[常用验证](../verification.md)，需要采集指导时再读[动效观察](../trace-guidance.md#动效问题观察)。
- 只有发现实际不可见路径及期间持续工作的证据时，才读取[不可见刷新规则](redundant-refresh.md#版本与前提)并判断是否增加发现。已有有限结束与销毁清理时，不因定时器或缺onPageHide假设后台/Tab问题；不能用将来可能接入的页面结构作为当前缺陷。

## 依据

- [显式动画接口及废弃版本](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-explicit-animation/)。
- [UIContext.animateTo](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-uicontext-uicontext/)。
