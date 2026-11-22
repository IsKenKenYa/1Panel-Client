# 无障碍属性参考

## 概述
设置组件的无障碍属性和事件，以充分利用无障碍功能。

## accessibilityActionOptions

设置组件的无障碍操作选项。

**参数说明**：
- `scrollStep`: number - 指定由无障碍手势触发的无障碍滚动操作步数

**适用场景**：
- 屏幕朗读模式下，聚焦Slider组件时，通过上下扫动手势调节滑动条
- 实际步长 = scrollStep × step
- 避免连续调节时重复播报相同状态值

**完整API参考**

详细API文档请参考：
- [无障碍属性完整文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)