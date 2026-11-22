# 动效实现方式

## 版本与前提

动态ArkTS。animateTo/animation从API7，UIContext.animateTo与TransitionEffect从API10支持；按工程版本核对后选择。先保持视觉、交互和时序，再比较实现工作；不同参数的动画不能为减少调用而合并。

成本机制：width/height/margin/padding/position 等布局属性动画可能逐帧引起测量或布局；scale/translate/rotate 等几何变换和 opacity 透明度通常更新绘制或合成属性，不改变布局占位，有机会减少布局工作。透明度不是变换矩阵的一部分，绘制与合成仍有成本；实际收益结合属性、子树和渲染路径验证。这是评估布局动画能否改用变换或透明度动画的依据。

## 三类检查

| 场景 | 方案与边界 |
|---|---|
| width/height等布局属性动画 | 仅在效果等价时评估scale/translate/rotate/opacity等变换。scale会放大文字；字号必须保持时保留布局动画，或把背景与文字分层处理，缩放父容器仍会缩放其文字子树 |
| animateTo+opacity+onFinish控制显隐 | 条件展示语义成立时可用transition+TransitionEffect，减少触发时的额外状态更新和回调注册；核对布局占位、销毁和重新显示语义 |
| 多次相同参数animateTo | 参数、触发条件与目标时序相同才合并，减少重复同步调用和状态捕获；不同duration/curve/delay/iterations保留独立调用 |

## 最小对照

```ts
// Before：相同参数触发两次状态捕获。
this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
  this.rotateY = 180;
});
this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
  this.opacity = 0.5;
});
// After：保持两个目标与400ms过渡，一次调用。
this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
  this.rotateY = 180;
  this.opacity = 0.5;
});
```

显隐可使用原有show状态：

```ts
if (this.showToast) {
  Text('提示').transition(TransitionEffect.OPACITY);
}
```

需要保留实例或布局占位时，不能机械用if替换。

## 建议与验证

在建议中保持触发、视觉效果、结束状态、显隐时机与必要状态。常用打点见[验证方法](../verification.md)。

对合并animateTo或减少显隐触发工作，包围整个原事件回调比较相同动作下的同步耗时；不能只测其中一次调用代表总变化。布局属性与变换属性的可比目标按实际工作定位，无法从录制区分的Measure/Layout事件不作可靠归因，不默认以ReceiveVsync或RSThread帧间隔证明这些同步调用优化。详细适用性见[动效观察](../trace-guidance.md#动效问题观察)。

不能把静态机制预期写成已测加速；效果不等价则不提出该替换。仅缺函数体时先补代码，已检查仍慢再用详细Trace指导。
