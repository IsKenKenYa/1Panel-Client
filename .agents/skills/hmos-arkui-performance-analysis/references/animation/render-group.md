# renderGroup 缺失与误用

## 版本与前提

renderGroup从API10支持。它将目标组件及子树的绘制结果离屏缓存，后续有机会复用；内容变化会使缓存失效，频繁重建可能增加开销。不透明度不为1时还需核对绘制效果。建议取决于实际绘制复杂度、动画范围、更新频率及缓存代价，组件数量只是线索。

## 检查方法

1. 确认拟缓存的具体容器及其子树：文本/图片是否稳定、子组件是否有独立动画或动态媒体、状态变化是否改变缓存内容。不能看到任意@State就排除缓存，也不能只数同屏实例就判缺陷。
2. scale/translate/rotate等整体变换作用于缓存容器自身时，可与固定子内容缓存配合；若动画位于缓存层内部的子组件，则可能频繁使缓存失效。先核对节点层级，不机械把缓存加到任意外层。
3. 大量固定内容项可明确提出renderGroup候选方案，说明拟减少的重复绘制与适用前提；只有数量而没有绘制成本依据时，保留实测决定是否启用，不把“≥10”设为普遍强制门槛。
4. 动态内容频繁更新时评估缓存重建代价；可将稳定与动态部分分层，或移除无收益的缓存。普通参数绑定若创建后不变，不能仅凭绑定形式认定其持续变化。

## 最小修改示例

以下链放在IconItem内部、承受整体缩放的原Column上。label保持固定，子Text无独立动画；原触发、尺寸与布局继续保留：

```ts
Column() {
  Text(this.label).fontSize(14)
}
.width(72).height(72)
.backgroundColor('#F5F5F5')
.scale({ x: this.scale, y: this.scale })
.animation({ duration: 300, curve: Curve.EaseInOut })
.renderGroup(true)
.onClick(() => { this.scale = this.scale === 1.0 ? 1.1 : 1.0; })
```

已有.animation能驱动该scale，不能把改成animateTo当作解决绘制缓存问题的必要条件。

## 建议与验证

核对所用接口适用于目标API，保持视觉、交互、缓存层级与动画。比较相同可见范围、触发次数和动画窗口的绘制/渲染工作与缓存代价，必要时结合render_service线程CPU工作；不以缓存出现就宣布加速，不预设固定CPU降幅。说明频繁更新时的失效风险即可，不要求把每个接口背景或通用风险句都写入每次报告。

显示正确和动画平滑属于效果核对，不能单独证明CPU/GPU工作减少；普通FlushRenderTask区间也不能单独证明缓存命中。事件可见性与采集限制按[动效观察](../trace-guidance.md#动效问题观察)核对，未采集写为预期。

## 依据

[renderGroup接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-image-effect/)、[动效实践中的固定内容缓存示例](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-animation-usage-guide/)。
