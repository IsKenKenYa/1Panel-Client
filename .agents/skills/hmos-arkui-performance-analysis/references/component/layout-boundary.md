# 内容切换的布局边界

供转场与组件布局诊断共用。检查内容尺寸变化是否扩大到外部无关区域，不将“没有显式 width/height”直接视为问题。

## 成立条件与机制

在同一宿主切换列表/详情等内容页，子内容高度不同，宿主随之改变占用尺寸，公共工具栏等外部区域被重新放置或测量；业务规格却允许内容宿主保持稳定尺寸。稳定宿主尺寸与约束，可减少由尺寸变化向外传播的布局工作，内部新子树仍须正常构建和布局。

读取父约束、内容实际大小、对齐和外部区域职责。只看到 width('100%')，或 Trace 中某个布局区间，不足以证明边界不合理。

## Bad / Good 对照

前提：V1/API 12，宿主按业务应保持 400vp，ListBody/DetailBody 分别高 240/360vp，均可完整显示；公共工具栏不应随内容切换移动。两组保持同样动画及子组件。

```ts
// Bad：内容切换会改变宿主高度，外部工具栏跟着移动。
Column() {
  Stack({ alignContent: Alignment.TopStart }) {
    if (this.page === 0) { ListBody() } else { DetailBody() }
  }.width('100%')
  Footer()
}
```

```ts
// Good：只稳定业务已允许固定的区域。
Column() {
  Stack({ alignContent: Alignment.TopStart }) {
    if (this.page === 0) { ListBody() } else { DetailBody() }
  }.width('100%').height(400)
  Footer()
}
```

这里是已定义子组件的宿主片段，400vp 不是通用推荐高度。窗口、字体、内容可能变大时，选择符合业务的自适应约束与滚动方案，不能裁正文、遮挡交互或改变可达范围。

## 检查与预期变化

- 先确认外部区域随宿主尺寸变化而参与布局；已由父约束稳定的容器不要求再写固定宽高。
- 设计要求内容撑开父级、工具栏跟随内容、或尺寸变化本身就是转场效果时，不把固定尺寸作为优化。
- 对比宿主尺寸、Footer 位置和实际目标节点的 Measure/Layout。预期外部无关布局工作减少；不承诺内部测量为零，不把状态更新、测量和创建次数混为一谈。

## 依据

[提升应用响应速度：使用指定宽高的容器限制刷新范围](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/improve-application-response.md)。原文是局部条件内容变化，本规则应用于具备同样布局依赖的内容页切换；不能把原文组件统计值称作当前转场总耗时。
