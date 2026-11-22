# 13. 性能与可见性

## 性能

| 规则 | 说明 |
|------|------|
| **禁止在 build() 的 UI 描述中改变状态** | 会导致无限重渲染循环或性能下降 |
| 网络图片 syncLoad | 大量网络图片场景，注意 syncLoad 设置，避免同步加载导致卡顿 |
| 注销回调 | 组件销毁时必须**及时注销**事件回调，避免内存泄漏 |
| AnimatorResult 销毁 | 不及时销毁会导致内存泄漏 |
| 长列表优先用 Repeat/LazyForEach | ForEach 在大数据量场景性能差 |
| 组件复用 | 使用 @Reusable/@ReusableV2 配合 LazyForEach 实现节点复用 |
| @Track 精准更新 | 使用 @Track 装饰器可减少不必要的组件重渲染 |
| 组件冻结 | 使用 freeze/freezeV2 实现非活跃组件冻结，减少不必要的更新 |

## 可见性

| 规则 | 说明 |
|------|------|
| onVisibleAreaChange | 可见区域**受父组件边界限制**，超出父组件的区域不计入。每帧计算，**尽量减少使用** |
| nodeRenderState | **不推荐**用于列表项（因节点回收），更适合页面级或 Tab 级可见性监控 |
| 渲染状态 ≠ 可见性 | ABOUT_TO_RENDER_IN 表示进入渲染管线，但可能被其他组件遮挡。渲染状态不完全等于视觉可见性 |

## 参考

- build() 约束见 [04-build](04-build.md)
- 渲染控制（ForEach/LazyForEach/Repeat）见 [06-rendering](06-rendering.md)