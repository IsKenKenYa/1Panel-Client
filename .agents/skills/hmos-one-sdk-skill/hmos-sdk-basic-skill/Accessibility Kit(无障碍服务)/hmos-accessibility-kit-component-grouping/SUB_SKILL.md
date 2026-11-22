---
name: hmos-accessibility-kit-component-grouping
description: 将多个UI组件组合为一个无障碍焦点进行统一播报，支持accessibilityGroup和accessibilityText属性配置，适用于表示同一对象信息的多个组件场景，提升屏幕朗读效率和信息聚合体验
---

# 组合场景无障碍组件技能

## 功能描述

将多个功能上相关的UI组件组合成一个独立的无障碍焦点，通过accessibilityGroup属性将组件及其子组件作为一个整体向屏幕朗读器表达。当组件组合启用无障碍分组后，无障碍服务将不再关注子组件的独立焦点，而是将组内所有文本信息合并播报，提高视障用户的信息获取效率，减少信息冗余和触摸浏览时的焦点跳转次数。

**核心能力**：
- 将多个子组件聚合为一个可获焦的无障碍单元
- 自动合并组内子组件的文本内容进行统一播报
- 支持自定义无障碍文本覆盖自动合并内容
- 提高触摸浏览的焦点管理效率

**适用范围**：
- 表示同一个对象信息的多个组件（如日期、天气、温度）
- 功能上完整的UI对象由多个小组件组合而成的场景
- 需要减少信息冗余和焦点跳转次数的复合组件

**技术限制**：
- API版本要求：API version 10及以上
- 子组件accessibilityLevel设置为"yes"时不受分组约束
- 需合理设置无障碍文本避免播报内容不清晰

## 使用场景

### 触发词
- "组合组件无障碍设置"
- "accessibilityGroup设置"
- "多个组件统一播报"
- "无障碍焦点聚合"
- "组件分组朗读"

### 能做
- 将多个表示同一对象信息的组件组合为一个无障碍焦点
- 设置accessibilityGroup属性启用无障碍分组
- 配置accessibilityText自定义组的播报内容
- 合理控制子组件的焦点获取行为
- 提高视障用户的触摸浏览效率

### 绝不做
- 不对功能上独立的组件进行分组
- 不在子组件设置accessibilityLevel="yes"时强制分组生效
- 不设置过于复杂的嵌套分组结构
- 不忽略无障碍文本的配置导致播报内容不清晰

### 补充
- 建议对表示同一对象信息的组件进行组合标注
- 组内子组件数量不宜过多（建议3-5个）
- 需验证组合后的播报内容是否符合语义逻辑
- 特殊场景可使用accessibilityGroup14+的accessibilityPreferred优先拼接无障碍文本

## 调用规范和规则

### 输入约束
- 组件数量：组合的子组件数量建议在3-5个，不宜超过10个
- 组件层级：建议在单一层级进行组合，避免多层嵌套分组
- 文本长度：合并后的文本总长度不宜超过200字符，避免播报时间过长
- API版本：最低支持API version 10，部分功能需要API version 14+

### 执行约束
- 配置顺序：先配置子组件的基础属性，再设置父组件的accessibilityGroup
- 测试验证：配置后需使用屏幕朗读器测试验证播报效果
- 性能考量：避免过度分组导致组件树遍历性能下降

### 内容约束
- 禁止对功能独立组件分组：不同功能的组件不应组合为一个焦点
- 禁止忽略文本配置：若组内子组件无文本属性，必须设置accessibilityText
- 禁止过度嵌套：不建议三层以上的嵌套分组结构

### 降级约束
- 文本长度过长：提示用户精简文本内容或拆分为多个组
- 子组件过多：建议拆分为多个逻辑组或使用列表组件
- 版本不兼容：API version 10以下环境提示升级或使用替代方案

## 调用流程和步骤

### 步骤1：识别组合场景

**判定条件**：
- 多个UI组件是否表示同一个对象的信息
- 组件在功能或语义上是否需要聚合为一个整体
- 独立朗读是否会造成信息冗余或效率降低

**操作步骤**：
1. 分析UI结构，识别表示同一对象信息的组件集合
2. 判断组件在功能上的关联性（如日期、天气、温度属于同一天气信息）
3. 评估独立朗读的效果，确定是否需要组合

### 步骤2：准备组合组件结构

**代码示例**：
```typescript
// 示例：天气信息组合组件
@Entry
@Component
struct WeatherInfo {
  build() {
    // 步骤2.1: 构建子组件结构
    Row() {
      // 日期信息
      Text('23 Dec 2023')
        .fontSize(32)
        .fontColor(Color.Red)
        .fontWeight(FontWeight.Bold)
        .margin({ right: 20 })
      
      // 天气图标（无文本组件）
      Column()
        .backgroundColor(Color.Yellow)
        .width(50)
        .height(50)
        .accessibilityText('Sunny')  // 步骤2.2: 为无文本组件设置accessibilityText
        .margin({ right: 20 })
      
      // 温度信息
      Text('-7')
        .fontSize(20)
        .fontColor(Color.Green)
        .fontWeight(FontWeight.Bold)
    }
    // 步骤3: 设置父组件的accessibilityGroup
    .accessibilityGroup(true)
  }
}
```

### 步骤3：设置accessibilityGroup属性

**核心API调用**：
```typescript
// API version 10+ 基础用法
Row() {
  // ... 子组件
}
.accessibilityGroup(true)  // 启用无障碍分组

// API version 14+ 扩展用法（优先拼接无障碍文本）
Row() {
  Text('天气信息')
  Column().accessibilityText('晴天')
  Text('25°C')
}
.accessibilityGroup(true, { 
  accessibilityPreferred: true  // 优先拼接无障碍文本
})
```

**参数说明**：
- `value: boolean` - 设置为true启用无障碍分组
- `isGroup: boolean` (API 14+) - 同value参数
- `accessibilityOptions: AccessibilityOptions` (API 14+) - 包含accessibilityPreferred等选项

### 步骤4：配置无障碍文本（可选）

**条件判断**：
- 若组内所有子组件都有文本属性，系统会自动拼接文本内容
- 若部分子组件无文本属性（如图标Column），需要设置accessibilityText
- 若需要自定义播报内容，覆盖自动拼接结果，可设置父组件的accessibilityText

**代码示例**：
```typescript
// 方式1：依赖自动拼接（所有子组件都有文本）
Row() {
  Text('23 Dec 2023')
  Text('Sunny')
  Text('-7°C')
}
.accessibilityGroup(true)  // 播报："23 Dec 2023 Sunny -7°C"

// 方式2：自定义播报内容
Row() {
  Text('23 Dec 2023')
  Column().accessibilityText('Sunny')
  Text('-7')
}
.accessibilityGroup(true)
.accessibilityText('12月23日，晴天，零下7度')  // 自定义播报内容
```

### 步骤5：处理特殊子组件

**场景说明**：
- 某些子组件需要保持独立焦点（如重要的操作按钮）
- 使用accessibilityLevel="yes"可以让子组件不受分组约束

**代码示例**：
```typescript
Row() {
  Text('天气信息')
  Column().accessibilityText('晴天')
  
  // 重要操作按钮保持独立焦点
  Button('详情')
    .accessibilityLevel('yes')  // 不受accessibilityGroup约束，可独立获焦
}
.accessibilityGroup(true)
```

### 步骤6：测试验证

**验证步骤**：
1. 启用设备的屏幕朗读功能
2. 触摸浏览组合组件区域
3. 验证焦点行为：组合后的组件应为单一焦点
4. 验证播报内容：播报内容应准确、完整、符合语义
5. 验证子组件焦点：子组件不应单独获焦（除非设置accessibilityLevel="yes"）

**预期结果**：
- 组合后的父组件为唯一可获焦单元
- 播报内容完整准确，无信息冗余
- 触摸浏览效率提升，焦点跳转次数减少

## 错误码说明

| 错误场景 | 说明 | 解决方法 |
|---------|------|---------|
| 子组件过多 | 组合的子组件超过10个，导致播报时间过长 | 拆分为多个逻辑组，或使用列表组件管理 |
| 文本缺失 | 组内部分子组件无文本属性且未设置accessibilityText | 为无文本组件设置accessibilityText，或设置父组件accessibilityText |
| 过度嵌套 | 三层以上嵌套分组结构，导致性能下降 | 简化分组层级，避免多层嵌套 |
| 版本不兼容 | API version低于10，不支持accessibilityGroup | 提示用户升级系统或使用替代方案 |
| 焦点冲突 | 同时设置accessibilityGroup和子组件accessibilityLevel="yes" | 根据需求调整配置，明确焦点优先级 |

## 编译和修复问题

### 依赖声明
无需额外依赖，accessibilityGroup为ArkUI内置通用属性。

### 环境要求
- HarmonyOS API version 10及以上
- DevEco Studio 3.1及以上版本
- 支持ArkTS语言开发

### 常见编译问题

**问题1：accessibilityGroup属性未生效**
```
编译通过但屏幕朗读器未识别分组
```
**解决方法**：
- 检查是否正确设置为`true`
- 验证API版本是否符合要求
- 确认屏幕朗读功能已启用

**问题2：播报内容不完整**
```
屏幕朗读播报内容缺失部分子组件信息
```
**解决方法**：
- 检查子组件是否都有文本属性或accessibilityText
- 若有子组件无文本，需设置父组件accessibilityText
- 验证子组件的accessibilityLevel设置

**问题3：子组件仍可独立获焦**
```
设置accessibilityGroup(true)后子组件仍能获焦
```
**解决方法**：
- 检查子组件是否设置了accessibilityLevel="yes"
- 移除或调整子组件的accessibilityLevel配置
- 验证屏幕朗读器的焦点管理逻辑

## 常见问题与解决方法

### Q1：何时应该使用组件组合？
**原因**：开发者可能不清楚组合场景的适用条件
**解决方法**：
- 判断多个组件是否表示同一对象信息（如天气信息的日期、图标、温度）
- 评估独立朗读是否造成信息冗余或效率降低
- 参考设计原则：功能上完整的UI对象由小组件组合时，应聚合为一个焦点

### Q2：组合后的播报内容不清晰怎么办？
**原因**：自动拼接的文本可能不符合语义逻辑或播报习惯
**解决方法**：
- 设置父组件的accessibilityText自定义播报内容
- 使用API version 14+的accessibilityPreferred优先拼接无障碍文本
- 优化子组件的文本内容，确保拼接后的语义清晰

### Q3：组内某些组件需要独立获焦怎么办？
**原因**：部分重要组件（如操作按钮）需要保持独立交互能力
**解决方法**：
- 为需要独立获焦的子组件设置accessibilityLevel="yes"
- 注意：设置"yes"后子组件不受accessibilityGroup约束
- 验证焦点行为是否符合预期

### Q4：如何处理多层嵌套的组合场景？
**原因**：复杂UI结构可能需要多层分组
**解决方法**：
- 避免三层以上的嵌套分组结构
- 优先在最合适的层级设置分组
- 使用列表组件管理复杂结构而非多层分组

### Q5：组合后的焦点跳转逻辑如何控制？
**原因**：需要自定义屏幕朗读的焦点跳转顺序
**解决方法**：
- 使用accessibilityNextFocusId指定下一个焦点组件
- 使用accessibilityDefaultFocus设置页面首焦点
- 参考无障碍属性文档中的焦点控制API

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "componentType": "组合式无障碍组件",
  "groupEnabled": true,
  "childComponentCount": 3,
  "accessibilityTextConfigured": true,
  "broadcastContent": "12月23日，晴天，零下7度",
  "apiUsed": [
    "accessibilityGroup",
    "accessibilityText"
  ],
  "apiVersion": "API version 10+",
  "verificationResult": {
    "focusBehavior": "单一焦点，符合预期",
    "broadcastAccuracy": "播报内容完整准确",
    "navigationEfficiency": "焦点跳转次数减少50%"
  }
}
```

## 参考文档

- [组合场景开发指南](references/scenario-multicomponent.md)
- [无障碍属性API参考](references/ts-universal-attributes-accessibility.md)
- [AccessibilityOptions类型定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-types)
- [Accessibility Kit概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/accessibility-kit-overview)

## 完整示例代码

- [ArkTS基础组合示例](assets/weather-info-basic.ets) - 天气信息组合组件（API version 10+）
- [ArkTS扩展组合示例](assets/weather-info-advanced.ets) - 优先拼接无障碍文本示例（API version 14+）
- [嵌套分组示例](assets/nested-group-example.ets) - 复杂场景的处理示例

## 测试用例

### 正向测试用例
- [天气信息组合测试](tests/test_weather_group.ets) - 验证天气信息组件的组合播报效果
- [列表项组合测试](tests/test_list_item_group.ets) - 验证列表项的组合焦点行为

### 边界测试用例
- [最多子组件测试](tests/test_max_children.ets) - 测试10个子组件的组合效果
- [无文本组件测试](tests/test_no_text_component.ets) - 测试组内包含无文本组件的处理

### 异常测试用例
- [过多子组件测试](tests/test_excessive_children.ets) - 测试超过10个子组件的降级处理
- [嵌套层级测试](tests/test_deep_nesting.ets) - 测试三层以上嵌套的性能影响
- [版本兼容性测试](tests/test_api_version.ets) - 测试API version 9环境下的兼容性处理