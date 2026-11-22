# 动画参数配置

## 版本与前提

动态ArkTS中，先区分动画不执行的代码缺陷与业务主动配置。animateTo/animation从API7、UIContext.animateTo从API10、animator从API9支持；目标API10+按适用条件使用UIContext版本。参数合理性结合当前场景，不从单个数值推断已测性能问题。

| 参数 | 检查与处理 |
|---|---|
| iterations | 0或负值（非-1）按无效值检查；期望播放却不执行时给修正。正整数与-1循环按业务使用 |
| duration | 16—5000ms为本规则参考范围，超出或处于体验敏感边界时提示核实设计，不自动改短 |
| curve、delay、playMode/direction | 结合动效意图；delay>1000ms等只提示影响，不擅改既定时序/曲线 |

## 业务明确要求的时长与循环

持续展示所需iterations:-1不是缺陷，也不能证明不可见冗余刷新。仅报告参数与相关体验影响，直接建议开发者核实当前意图，不主动给参数替换、假设后台/Tab的暂停恢复方案。只有已确认不可见期间仍持续刷新时，才按[不可见刷新](redundant-refresh.md#版本与前提)独立判断。

```text
位置：Banner的.animation({ duration: 5000, curve: Curve.Linear, iterations: -1 })。
参数影响：单次渐变5秒并持续循环；不把既定展示效果作为缺陷。
建议：请开发者结合当前动效意图与体验要求，核实动画时长和持续循环配置是否合理；符合慢速渐变展示需求时可保留。
验证：在目标设备观察过渡时间和体验是否符合设计。
```

## fling 方向与体验

velocity单位vp/s：正值向顶部，负值向底部，0不产生本次滚动。先结合初始位置、边界和业务意图判断方向，负值本身合法；不从单个速度值推断固定时长、距离或已测卡顿。

惯性滚动场景直接建议开发者结合当前交互意图核实方向、初始位置、速度与实际距离；符合需求可保留。fling接受初始速度，不接受精确目标位置；若业务要求精确定位，可说明scrollTo/scrollToIndex与惯性效果的差别后选型，不擅自替换已明确的交互。

## 无效iterations示例

```ts
// 期望点击后播放过渡，iterations:0却使动画不执行。
.animation({ duration: 800, iterations: 0, curve: Curve.EaseInOut })
// 按一次播放语义修正；持续循环业务才使用-1。
.animation({ duration: 800, iterations: 1, curve: Curve.EaseInOut })
```

保持触发、结束状态和循环语义。不因Linear、较长duration或-1直接判错；缺相关业务场景时补最小信息。效果用目标设备的实际过渡/滚动体验观察，不把静态参数分析说成已测耗时或帧率。

依据：[合理设置动效时长](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reasonable-using-animation.md#合理设置动效时长)。

方向与版本依据：[Scroller.fling（API12+）](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-container-scroll/)。
