# Slider组件参考

## 概述
滑动条组件，通常用于快速调节设置值，如音量调节、亮度调节等应用场景。

## 无障碍相关属性

### accessibilityActionOptions
设置组件的无障碍操作选项。

**参数说明**：
- `scrollStep`: number - 指定由无障碍手势触发的无障碍滚动操作步数

**适用组件**：
- 仅对Slider组件配置生效

**取值范围**：
- [1, (max-min)/step]

**默认值**：
- 1

**特殊说明**：
- 设置值超出取值范围时取默认值1
- 设置值为取值范围内的非整数时向下取整

## 完整API参考

详细API文档请参考：
- [Slider组件完整文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-slider)
- [无障碍属性完整文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)