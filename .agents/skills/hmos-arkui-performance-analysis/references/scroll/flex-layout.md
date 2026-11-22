# Flex 二次布局

## 前提与机制

Flex的弹性尺寸分配可能在初次测量后调整子项，引入重复测量。先确认目标节点的直接父容器、主轴约束、基准尺寸、剩余空间及grow/shrink；不能仅凭出现Flex或其任意后代有flexGrow就断言同一节点测量两次。默认flexShrink同样需按实际压缩条件判断，不以“未显式设置”排除开销。

flexGrow/flexShrink描述所在组件与直接父容器之间的空间分配，Row/Column也有相应支持与尺寸条件。layoutWeight可用于单轴剩余空间分配，但不能一概视为与flexGrow的基准尺寸、压缩和对齐语义相同，也不能保证任何场景都只测量一次。

## 检查方法

1. 定位设置flexGrow/flexShrink的具体子项及其直接父容器；若中间还有Row、Column、Stack，不跳过这些节点向外层Flex归因。
2. 检查主轴尺寸、剩余空间及是否实际发生扩展/压缩。反复Measure也可能来自约束变化或其他更新，需关联当前目标节点和帧。
3. 无换行或复杂对齐需要、尺寸分配等价时，可评估Row/Column+layoutWeight；仅删除无职责的Flex也需核对原有布局。复杂布局有业务需要时保留。
4. flexShrink(0)只适用于确实不允许压缩的子项，可能引入溢出，不能作为所有子项的统一修复。

## 建议与验证

在建议中保持宽高、比例、换行、对齐与命中区域；用不同尺寸和文字长度核对。flexGrow按剩余空间扩展，不应直接将其比例当成最终宽度比例来替换。代码条件足够时可给候选方案，不要求先交Trace。

比较相同滚动路径、数据和约束下目标子树的Measure/Layout次数及耗时。实际存在重复测量时，验证对应节点是否减少；不要求所有录制恰好2次变1次。FlushLayoutTask包含其他子树，整体耗时不一定随局部优化明显下降；缺事件先核对版本与采集开关。

## 打点与预期变化

按节点tag和self ID关联Measure与Layout事件，区分事件次数、节点数和创建数。预期减少的是当前约束下可避免的弹性调整与重复测量，保留必要测量；结论按实际录制，不能由替换容器名称推导固定收益。常用步骤见[验证方法](../verification.md)，需要采集指导时再读[详细指南](../trace-guidance.md)。

## 依据

[Flex布局属性与父容器约束](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-flex-layout/)、[Flex开发性能提升](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/performance/flex-development-performance-boost.md)。
