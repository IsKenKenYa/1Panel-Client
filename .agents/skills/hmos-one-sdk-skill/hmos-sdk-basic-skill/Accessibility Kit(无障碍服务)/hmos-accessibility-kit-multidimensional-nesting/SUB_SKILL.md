---
name: hmos-accessibility-kit-multidimensional-nesting
description: 处理多维嵌套场景下的无障碍朗读问题，避免重复朗读，优化焦点控制，适用于天气卡片、信息卡片等包含时间、位置等多维信息的嵌套组件场景
---

# 多维嵌套场景无障碍优化技能

## 功能描述

本技能用于解决HarmonyOS应用中多维嵌套组件的无障碍朗读问题。在嵌套组中，多个可获焦对象可能对同一信息结构进行重复朗读，导致用户操作步骤增加、焦点控制混乱。通过使用accessibilityGroup属性将子组件合并为一个整体，并配合accessibilityText属性设置合并后的朗读文本，可以避免重复朗读，提升无障碍体验。

**核心能力**：
- 合并嵌套组件的朗读内容，避免重复播报
- 控制焦点聚合，减少用户操作步骤
- 提供清晰的组件状态播报

**适用范围**：
- 包含多个子组件的容器组件（如Row、Column）
- 需要合并朗读信息的信息卡片（天气、时间、位置等）
- 具有嵌套结构的复杂UI组件

**技术限制**：
- 需要API version 10及以上版本支持
- 子组件的accessibilityLevel设置为"yes"时不受accessibilityGroup约束
- 合并文本优先使用accessibilityText，若无则自动拼接子组件文本

## 使用场景

### 触发词
- "避免重复朗读" - 解决嵌套组件重复播报问题
- "多维嵌套场景" - 处理包含多个子组件的信息卡片
- "无障碍分组" - 将组件及其子组件合并为一个整体
- "合并朗读文本" - 合并多个子组件的朗读内容
- "焦点控制优化" - 减少无障碍焦点切换步骤

### 能做
- 分析嵌套组件结构，识别重复朗读问题
- 使用accessibilityGroup(true)合并子组件为整体
- 设置accessibilityText提供合并后的朗读文本
- 配置accessibilityLevel控制子组件可聚焦性
- 提供正确和错误的实现对比示例

### 绝不做
- 不处理单层组件的无障碍配置（非嵌套场景）
- 不修改组件的视觉布局和样式
- 不替代accessibilityLevel为"yes"的子组件配置
- 不处理超出Accessibility Kit范围的请求

### 补充
- 当子组件设置accessibilityLevel为"yes"时，仍可单独获焦
- 合并文本时若子组件无文本属性则忽略该组件
- 建议使用accessibilityText而非依赖自动拼接

## 调用规范和规则

### 输入约束
- 组件类型：必须是容器组件（Row、Column、Stack等）
- 子组件数量：至少包含2个子组件才会出现重复朗读问题
- 文本属性：子组件应包含文本或无障碍文本属性
- API版本：项目最低API version需为10

### 执行约束
- 最大组件层级：建议不超过3层嵌套
- 文本合并策略：优先使用accessibilityText，次选自动拼接
- 焦点控制规则：accessibilityLevel为"yes"的子组件不受约束

### 内容约束
- 禁止生成：无accessibilityGroup配置的嵌套组件示例
- 禁止操作：不修改已设置accessibilityLevel为"yes"的子组件
- 禁止模式：不使用accessibilityText依赖子组件自动拼接

### 降级约束
- API version低于10：提示版本要求，建议升级
- 无文本属性的子组件：忽略该子组件，不进行拼接
- 复杂嵌套结构（超过3层）：建议拆分为多个组件或提供详细配置指南

## 调用流程和步骤

### 步骤1：识别重复朗读问题

**问题识别**：
1. 检查组件是否为容器组件（Row、Column等）
2. 检查子组件是否包含文本属性或无障碍文本属性
3. 测试无障碍朗读，识别重复播报的内容
4. 确认父组件是否已设置accessibilityText（可能导致父子重复）

**示例代码**：
```arkts
// 错误示例：存在重复朗读问题
Row() {
  Text('12:05') // 时间信息，获焦时朗读"12:05"
    .fontSize(32)
  Text('Beijing') // 位置信息，获焦时朗读"Beijing"
    .fontSize(20)
}
.accessibilityText('Time Group') // 父组件获焦时朗读"Time Group 12:05 Beijing"
// 问题：父组件、时间子组件、位置子组件都会分别获焦朗读，造成重复
```

### 步骤2：配置无障碍分组

**配置步骤**：
1. 在容器组件上设置`.accessibilityGroup(true)`
2. 设置`.accessibilityText()`提供合并后的朗读文本
3. 可选：设置`.accessibilityLevel()`控制组件重要性
4. 验证子组件不再单独获焦

**示例代码**：
```arkts
// 正确示例：使用accessibilityGroup合并朗读
Row() {
  Text('07:05') // 时间信息
    .fontSize(32)
    .fontColor(Color.Red)
    .fontWeight(FontWeight.Bold)
  Text('Moscow') // 位置信息
    .fontSize(20)
    .fontColor(Color.Green)
    .fontWeight(FontWeight.Bold)
}
.height(50)
.accessibilityGroup(true) // 启用无障碍分组，子组件不再单独获焦
// 无accessibilityText时，自动拼接子组件文本，朗读"07:05 Moscow"
```

### 步骤3：设置合并朗读文本

**参数配置**：
```arkts
// 使用accessibilityText设置合并朗读文本
Row() {
  Text('07:05')
    .fontSize(32)
  Text('Moscow')
    .fontSize(20)
}
.accessibilityGroup(true)
.accessibilityText('Time: 07:05, Location: Moscow') // 自定义合并朗读文本
.accessibilityDescription('This is a time and location information card') // 可选：提供详细说明
```

### 步骤4：处理特殊子组件

**处理accessibilityLevel为"yes"的子组件**：
```arkts
Row() {
  Text('07:05')
    .fontSize(32)
  Text('Moscow')
    .fontSize(20)
    .accessibilityLevel('yes') // 设置为"yes"后，该子组件不受accessibilityGroup约束
}
.accessibilityGroup(true)
// 结果：父组件朗读"07:05 Moscow"，但"Moscow"子组件仍可单独获焦朗读
```

### 步骤5：完整实现示例

**完整代码示例**：
```arkts
@Entry
@Component
export struct MultidimensionalNestingExample {
  title: string = 'Multidimensional Nesting Accessibility';
  
  build() {
    NavDestination() {
      Column() {
        // 错误示例：重复朗读
        Text('Incorrect behavior:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({bottom: 12})
        
        Row(){
          Text('12:05')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .margin({right: 20})
          Text('Beijing')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
        }
        .accessibilityText('Time Group')
        .height(50)
        .margin({bottom: 150})
        
        // 正确示例：合并朗读
        Text('Correct behavior:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({bottom: 12})
        
        Row(){
          Text('07:05')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .margin({right: 20})
          Text('Moscow')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
        }
        .height(50)
        .accessibilityGroup(true) // 启用无障碍分组
        .accessibilityText('Time: 07:05, Location: Moscow') // 设置合并朗读文本
        .accessibilityDescription('Weather card showing current time and location')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title(this.title)
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| ACCESSIBILITY_GROUP_ERROR | accessibilityGroup配置错误 | 确保设置为boolean类型，默认值为false |
| TEXT_MERGE_ERROR | 合并文本拼接失败 | 检查子组件是否包含文本属性，或设置accessibilityText |
| FOCUS_CONTROL_ERROR | 焦点控制异常 | 检查accessibilityLevel配置，"yes"的子组件不受约束 |
| API_VERSION_ERROR | API版本不兼容 | 升级项目最低API version至10及以上 |

## 编译和修复问题

### 依赖声明
无需额外依赖库，使用ArkUI内置无障碍属性。

### 环境要求
- HarmonyOS SDK：API version 10及以上
- DevEco Studio：3.1及以上版本
- 设备支持：支持无障碍服务的HarmonyOS设备

### 常见编译问题

**问题1：accessibilityGroup参数类型错误**
```
Type 'string' is not assignable to type 'boolean'.
```
**解决方法**：使用boolean类型，`.accessibilityGroup(true)`而非`.accessibilityGroup('true')`

**问题2：accessibilityText参数类型错误**
```
Type 'number' is not assignable to type 'string'.
```
**解决方法**：使用string类型或Resource类型，`.accessibilityText('text')`或`.accessibilityText($r('app.string.key'))`

**问题3：组件未响应无障碍分组**
```
Component still allows child focus after setting accessibilityGroup(true)
```
**解决方法**：检查子组件是否设置了`accessibilityLevel('yes')`，该配置会覆盖父组件的accessibilityGroup约束

## 常见问题与解决方法

### Q1：为什么设置accessibilityGroup后子组件仍可获焦？
**原因**：子组件设置了`accessibilityLevel('yes')`，该配置不受accessibilityGroup约束
**解决方法**：
- 移除子组件的`accessibilityLevel('yes')`配置
- 或保持子组件独立获焦，仅在父组件设置accessibilityText提供额外信息

### Q2：合并文本时某些子组件被忽略怎么办？
**原因**：子组件没有文本属性（如Text组件的content）或无障碍文本属性
**解决方法**：
- 为子组件设置文本属性或`.accessibilityText()`
- 在父组件直接设置`.accessibilityText()`提供完整合并文本

### Q3：如何控制合并文本的朗读顺序？
**原因**：自动拼接按深度优先顺序，可能不符合预期
**解决方法**：
- 使用`.accessibilityText()`手动设置合并文本，控制朗读内容
- 避免依赖自动拼接，提供明确的朗读文本

### Q4：accessibilityGroup与accessibilityText的关系是什么？
**原因**：两者配合使用，accessibilityGroup控制焦点合并，accessibilityText控制朗读内容
**解决方法**：
- accessibilityGroup(true)启用分组，子组件不再单独获焦
- accessibilityText()设置合并后的朗读文本，避免自动拼接的不确定性

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "accessibilityConfig": {
    "accessibilityGroup": true,
    "accessibilityText": "Time: 07:05, Location: Moscow",
    "accessibilityDescription": "Weather card showing current time and location"
  },
  "apiUsed": [
    "accessibilityGroup",
    "accessibilityText",
    "accessibilityDescription",
    "accessibilityLevel"
  ],
  "focusBehavior": {
    "parentFocus": true,
    "childFocus": false,
    "mergedText": "07:05 Moscow"
  },
  "verification": {
    "repeatAnnouncement": false,
    "focusStepsReduced": true
  }
}
```

## 参考文档

- [多维嵌套场景开发指南](references/scenario-multidimensional-nesting.md) - [在线文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-multidimensional-nesting)
- [无障碍属性API参考](references/ts-universal-attributes-accessibility.md) - [在线文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)

## 完整示例代码

- [ArkTS完整示例](assets/MultidimensionalNestingExample.ets)
- [错误对比示例](assets/IncorrectBehaviorExample.ets)

## 测试用例

### 正向测试用例
- [使用accessibilityGroup合并朗读](tests/test_positive.ets)：验证启用分组后子组件不再单独获焦
- [设置accessibilityText合并文本](tests/test_positive.ets)：验证自定义合并文本正确朗读
- [包含多个子组件的Row容器](tests/test_positive.ets)：验证多个子组件合并为一个焦点

### 边界测试用例
- [子组件包含文本和无障碍文本](tests/test_boundary.ets)：验证优先朗读无障碍文本
- [子组件设置accessibilityLevel为yes](tests/test_boundary.ets)：验证子组件仍可获焦
- [无文本属性的子组件](tests/test_boundary.ets)：验证忽略该子组件不拼接

### 异常测试用例
- [API version低于10](tests/test_exception.ets)：验证提示版本要求
- [嵌套层级超过3层](tests/test_exception.ets)：验证提示复杂结构建议
- [accessibilityGroup参数类型错误](tests/test_exception.ets)：验证编译错误提示