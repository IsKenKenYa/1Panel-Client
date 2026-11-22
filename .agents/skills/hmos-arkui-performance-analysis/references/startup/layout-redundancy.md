# 布局容器冗余

## 前提与机制

不承担必要语义的重复容器增加组件与布局工作；需逐层证明冗余，不只看层数。

容器承担对齐、背景、事件区域、裁剪、尺寸或响应式布局时，深层结构也可能有必要。

## 检查方法

1. 读取实际子树及各层容器的排布、尺寸约束、对齐、背景、裁剪、事件与适配要求。
2. 逐层确认职责，只删除可证明冗余的层；建议中说明保留的视觉与交互语义，不自动把所有 Flex 换成 Row/Column。
3. 缺样式方法或事件定义时先补；只知道层数无法确定可删除哪一层。

## Bad case

前提：中间两层没有属性、事件或独立布局职责，业务确认无需这些容器。

```ts
Column() { Column() { Column() { Text('Title') } } }
```

## Good case

```ts
Column() { Text('Title') }
```

保留承担页面职责的容器。同样三层若分别承担尺寸、点击区域和对齐，则不能套用这个删层方案。

## 建议与验证

建议中说明尺寸适配、文字换行、事件命中、占位与对齐如何保持；默认不另列功能测试步骤。不能以节点减少直接宣称布局一定等价。
代码与条件足够时直接给建议，不要求 Trace。必要信息已检查仍无法解释持续慢，再使用 [Trace 指导](../trace-guidance.md) 选择相关阶段。

## 打点与预期变化

对应打点：按目标子树的节点 ID 观察 `Create[Column]`、`Measure[Column]`、`Layout[Column]`，并比较 `FlushLayoutTask`。删除无职责中间容器后，预期对应容器的创建数量及相关布局工作减少；三层改一层的示例只计算该子树，不把应用内其他 Column 一并计入。Measure/Layout 可能重复执行，不用一次事件计数当作节点数，耗时是否改善另行比较。节点级事件缺失先核对布局 Trace 开关与系统版本。

## 依据

[减少首帧绘制时的冗余操作：减少视图嵌套层次](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/reduce-redundant-operations-when-render-first-frame.md#减少视图嵌套层次)。
