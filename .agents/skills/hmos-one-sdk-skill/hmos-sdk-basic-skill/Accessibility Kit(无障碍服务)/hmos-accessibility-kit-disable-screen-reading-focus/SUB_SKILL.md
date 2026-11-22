---
name: hmos-accessibility-kit-disable-screen-reading-focus
description: 设置控件的无障碍属性使其在屏幕朗读模式下不获取焦点，适用于装饰性控件（分隔符、占位符、美化图标等）场景
---

# 禁用屏幕朗读焦点技能

## 功能描述

本技能用于设置组件的无障碍属性，使其在屏幕朗读模式下不获取焦点和朗读。装饰性的控件一般为分隔符、占位符和美化图标等，这类图形元素仅仅起到调整页面布局或装饰性效果，并不会向用户传达有效的信息或提供交互功能，删除后不影响指引用户体验。通过设置无障碍属性可以将其设置为无障碍不可聚焦。

## 使用场景

### 触发词
- "禁用屏幕朗读焦点"
- "装饰性控件不朗读"
- "分隔符不聚焦"
- "占位符不朗读"
- "美化图标无障碍"

### 能做
- 设置单个组件在屏幕朗读模式下不可聚焦
- 设置组件及其所有子组件不可聚焦
- 设置组件组为整体不可聚焦
- 控制装饰性控件的无障碍行为

### 绝不做
- 不修改组件的可见性（visibility）属性来禁用无障碍
- 不删除组件本身
- 不影响组件的正常显示和布局
- 不用于功能性组件的无障碍设置

### 补充
- 装饰性控件包括分隔符、占位符、美化图标等纯装饰性元素
- 适用于需要优化屏幕朗读体验的场景
- 需根据具体场景选择合适的属性设置方式

## 调用规范和规则

### 输入约束
- 组件类型：支持所有ArkUI基础组件
- 属性设置：必须明确指定无障碍属性值
- 使用场景：仅适用于装饰性、非交互性控件

### 执行约束
- 最大组件数量：单次设置不超过100个组件
- 属性选择：根据场景选择合适的属性组合
- 测试验证：必须验证屏幕朗读行为

### 内容约束
- 禁止对功能性组件使用"no"或"no-hide-descendants"
- 禁止同时设置冲突的无障碍属性
- 禁止省略属性值的明确设置

### 降级约束
- 属性设置失败：记录日志并继续处理其他组件
- 属性冲突：优先使用accessibilityLevel("no")
- 场景不明确：提示用户明确控件类型

## 调用流程和步骤

### 步骤1：识别装饰性控件

**前置校验**：
1. 确认控件为装饰性元素（分隔符、占位符、美化图标等）
2. 确认控件不传达有效信息或提供交互功能
3. 确认删除控件不影响用户体验

**判断标准**：
- 分隔符：用于视觉分隔的线条或空白区域
- 占位符：用于布局占位但无实际内容
- 美化图标：仅起装饰作用的图形元素

### 步骤2：选择合适的属性设置方式

**属性选择指南**：

| 属性方式 | 适用场景 | 说明 |
|---------|---------|------|
| `accessibilityLevel("no")` | 单个组件不聚焦 | 忽略当前组件的文本属性和点击属性，组件不可聚焦 |
| `accessibilityLevel("no-hide-descendants")` | 组件及其子组件不聚焦 | 忽略当前组件及其所有子组件的文本属性和点击属性 |
| `accessibilityGroup(true)` + `accessibilityLevel("no")` | 组件组整体不聚焦 | 将组件及其子组件作为整体，设置为不可聚焦 |

### 步骤3：设置无障碍属性

**示例代码**：

```typescript
// 方式1：单个组件不聚焦
@Component
struct DecorativeIcon {
  build() {
    Image($r('app.media.decorative_icon'))
      .width(50)
      .height(50)
      .accessibilityLevel("no")  // 设置组件不可聚焦
  }
}

// 方式2：组件及其子组件不聚焦
@Component
struct DecorativeContainer {
  build() {
    Row() {
      Image($r('app.media.icon1'))
      Image($r('app.media.icon2'))
      Text('装饰性文本')
    }
    .accessibilityLevel("no-hide-descendants")  // 整个Row及其子组件不可聚焦
  }
}

// 方式3：组件组整体不聚焦
@Component
struct DecorativeGroup {
  build() {
    Column() {
      Row() {
        Text('装饰性内容1')
      }
      Row() {
        Text('装饰性内容2')
      }
    }
    .accessibilityGroup(true)  // 设置为无障碍组
    .accessibilityLevel("no")  // 整个组不可聚焦
  }
}
```

### 步骤4：验证屏幕朗读行为

**验证步骤**：
1. 启用屏幕朗读功能
2. 使用屏幕朗读扫动走焦
3. 验证装饰性控件不获取焦点
4. 验证功能性控件正常聚焦和朗读

### 步骤5：处理特殊场景

**特殊场景处理**：

```typescript
// 场景：装饰性控件包含需要朗读的子组件
@Component
struct MixedContainer {
  build() {
    Row() {
      // 装饰性图标，不需要朗读
      Image($r('app.media.decorative_icon'))
        .accessibilityLevel("no")
      
      // 功能性按钮，需要朗读
      Button('功能按钮')
        .accessibilityLevel("yes")  // 明确设置为可聚焦
    }
    .accessibilityGroup(true)  // 设置为无障碍组，但不影响子组件的"yes"设置
  }
}
```

## 错误码说明

本技能主要涉及属性设置，可能的错误情况：

| 错误场景 | 说明 | 解决方法 |
|---------|------|---------|
| 属性值错误 | 设置了无效的accessibilityLevel值 | 使用正确的值："auto"、"yes"、"no"、"no-hide-descendants" |
| 属性冲突 | 同时设置了冲突的无障碍属性 | 确保属性设置逻辑一致，避免冲突 |
| API版本不支持 | 使用的API版本低于要求版本 | 确认API版本 ≥ 10（基础属性）或 ≥ 12（卡片支持） |
| 组件类型不支持 | 某些特殊组件不支持无障碍属性 | 查阅组件文档确认支持的属性 |

## 编译和修复问题

### 依赖声明

无额外依赖，使用ArkUI内置无障碍属性。

### 环境要求
- HarmonyOS API version ≥ 10
- DevEco Studio ≥ 3.1
- ArkTS语言支持

### 常见编译问题

**问题1：属性未识别**
```
错误信息：Property 'accessibilityLevel' does not exist on type 'Image'
```
**解决方法**：确认API版本 ≥ 10，无障碍属性为通用属性，支持所有基础组件。

**问题2：属性值类型错误**
```
错误信息：Argument of type 'string' is not assignable to parameter of type 'AccessibilityLevel'
```
**解决方法**：使用正确的字符串值："auto"、"yes"、"no"、"no-hide-descendants"。

**问题3：卡片中使用报错**
```
错误信息：accessibilityLevel is not supported in ArkTS card
```
**解决方法**：确认API version ≥ 12，卡片中支持无障碍属性。

## 常见问题与解决方法

### Q1：装饰性控件仍然被朗读
**原因**：可能设置了错误的属性值，或父组件的无障碍属性影响。
**解决方法**：
- 检查accessibilityLevel是否设置为"no"或"no-hide-descendants"
- 检查父组件是否设置了accessibilityGroup(true)
- 使用屏幕朗读测试验证效果

### Q2：功能性组件也不被朗读
**原因**：错误地对功能性组件使用了禁用属性。
**解决方法**：
- 仅对装饰性控件使用禁用属性
- 功能性组件保持默认设置或明确设置为"yes"
- 使用accessibilityGroup时注意子组件的设置

### Q3：组件组内部分子组件需要朗读
**原因**：accessibilityGroup(true)会合并子组件，但不会强制禁用。
**解决方法**：
- 在需要朗读的子组件上明确设置accessibilityLevel("yes")
- 使用accessibilityGroup的规则：子组件设置为"yes"时不受父组件约束

### Q4：如何判断控件是否为装饰性
**原因**：难以区分装饰性控件和功能性控件。
**解决方法**：
- 装饰性控件定义：不传达有效信息、不提供交互、删除不影响体验
- 功能性控件定义：传达信息、提供交互、删除影响体验
- 咨询产品设计和用户体验团队

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "message": "已成功设置装饰性控件的无障碍属性",
  "componentsProcessed": 5,
  "attributesUsed": ["accessibilityLevel", "accessibilityGroup"],
  "testResult": "屏幕朗读验证通过，装饰性控件不聚焦"
}
```

## 参考文档

- [禁用屏幕朗读焦点的场景](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-disable-screen-reading-focus)
- [无障碍属性API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)

## 完整示例代码

- [ArkTS完整示例](assets/disable-screen-reading-focus-example.ets)

## 测试用例

### 正向测试用例
- [装饰性图标不聚焦测试](tests/test_decorative_icon.ets)：验证装饰性图标不获取焦点
- [分隔符不朗读测试](tests/test_separator.ets)：验证分隔符不被朗读

### 边界测试用例
- [混合容器测试](tests/test_mixed_container.ets)：验证装饰性和功能性组件混合场景
- [组件组测试](tests/test_accessibility_group.ets)：验证accessibilityGroup的正确使用

### 异常测试用例
- [属性冲突测试](tests/test_attribute_conflict.ets)：验证属性冲突场景的处理
- [API版本测试](tests/test_api_version.ets)：验证低版本API的兼容性