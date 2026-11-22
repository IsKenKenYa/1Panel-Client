---
name: hmos-accessibility-kit-screen-reading-text
description: 设置组件无障碍文本用于屏幕朗读，支持string和Resource两种格式，优先级高于显示文本，适用于为视障用户提供清晰的屏幕朗读内容场景
---

# 标注屏幕朗读内容的技能

## 功能描述

本技能用于设置组件的无障碍文本，使屏幕朗读服务能够播报组件内容。无障碍文本的优先级高于显示文本，即当无障碍文本不为空时，会朗读无障碍文本，否则朗读显示文本。

**核心功能**：
- 为文本类和非文本类组件设置无障碍文本
- 支持字符串和Resource资源引用两种格式
- 在屏幕朗读场景下优先播报无障碍文本
- 提升视障用户的应用使用体验

**适用范围**：
- 适用于所有需要屏幕朗读功能的组件
- 支持ArkTS卡片和元服务
- 从API version 10开始支持，API version 12支持Resource引用

**限制条件**：
- 仅在屏幕朗读模式下生效
- 不能同时设置多种选择模式（accessibilityChecked和accessibilitySelected）
- 不支持在attributeModifier中调用

**典型场景**：
- 为按钮添加详细描述
- 为图标组件提供朗读文本
- 为颜色等视觉效果补充文本说明
- 为非文本类组件提供可朗读内容

## 使用场景

### 触发词
- "设置无障碍文本"
- "屏幕朗读文本"
- "accessibilityText"
- "添加朗读内容"
- "无障碍播报文本"

### 能做
- 为任何组件设置无障碍文本属性
- 支持使用字符串直接设置文本
- 支持使用Resource引用资源文件中的文本
- 在组件已有文本属性时覆盖显示文本的朗读内容
- 为不包含文本属性的组件提供可朗读内容

### 绝不做
- 不能用于修改组件的显示文本内容
- 不能替代组件本身的文本属性
- 不处理无障碍分组的相关逻辑（需使用accessibilityGroup）
- 不控制组件是否可被无障碍服务识别（需使用accessibilityLevel）
- 不设置组件的无障碍说明（需使用accessibilityDescription）

### 补充
- 无障碍文本仅在屏幕朗读场景下生效，不影响视觉显示
- 若组件既拥有文本属性又拥有无障碍文本属性，仅播报无障碍文本
- 推荐为图标、颜色等视觉元素补充无障碍文本说明
- 建议无障碍文本简洁明了，避免过长影响用户体验

## 调用规范和规则

### 输入约束
- 文本长度：建议不超过50个字符，避免朗读时间过长
- 文本格式：string类型或Resource类型
- 文本内容：应清晰描述组件用途或状态
- 语言要求：使用应用当前语言环境的文本

### 执行约束
- 最大设置耗时：<1ms（同步调用）
- 支持版本：API version 10+（string格式），API version 12+（Resource格式）
- 调用位置：组件属性链式调用中
- 返回值：返回组件对象，支持链式调用

### 内容约束
- 禁止使用空字符串作为有意义的无障碍文本
- 禁止在attributeModifier中调用
- 禁止设置过长文本影响朗读体验
- 禁止使用与应用无关的文本内容

### 降级约束
- 文本过长：提示用户精简文本或分段播报
- 版本不支持：提示最低API版本要求
- Resource引用失败：使用备用文本或提示资源错误
- 组件不支持：提示检查组件类型和accessibilityLevel设置

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认组件类型支持无障碍属性
2. 确认应用API版本满足要求（string: 10+，Resource: 12+）
3. 确认屏幕朗读服务已开启
4. 确认组件accessibilityLevel设置正确（默认"auto"）

**参数准备**：
```typescript
// 方式1：直接使用字符串
const accessibilityText: string = 'Accessibility text';

// 方式2：使用Resource引用
const accessibilityTextResource: Resource = $r('app.string.accessibility_text');
```

### 步骤2：调用API

**示例代码（字符串格式）**：
```typescript
@Entry
@Component
struct ScreenReadingExample {
  build() {
    Column() {
      // 为按钮设置无障碍文本
      Button('确定')
        .accessibilityText('确认提交按钮')
        .onClick(() => {
          console.info('Button clicked');
        })
      
      // 为图标设置无障碍文本
      Image($r('app.media.icon'))
        .width(50)
        .height(50)
        .accessibilityText('应用图标')
      
      // 为文本组件设置替代朗读文本
      Text('红色')
        .fontColor(Color.Red)
        .accessibilityText('红色文本，表示警告信息')
    }
  }
}
```

**示例代码（Resource格式）**：
```typescript
@Entry
@Component
struct ScreenReadingResourceExample {
  build() {
    Column() {
      Button('Submit')
        .accessibilityText($r('app.string.submit_button_accessibility'))
        .onClick(() => {
          console.info('Submit button clicked');
        })
      
      Text('Status')
        .accessibilityText($r('app.string.status_text_accessibility'))
    }
  }
}
```

### 步骤3：错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ErrorHandlingExample {
  @State accessibilityText: string = '';
  
  build() {
    Column() {
      Button('Test')
        .accessibilityText(this.accessibilityText)
        .onClick(() => {
          try {
            // 动态设置无障碍文本
            if (this.accessibilityText.length > 50) {
              console.warn('Accessibility text too long, recommended max 50 characters');
            }
            this.accessibilityText = 'Updated text';
          } catch (error) {
            const businessError: BusinessError = error as BusinessError;
            console.error(`Failed to set accessibility text: ${businessError.message}`);
          }
        })
    }
  }
}
```

### 步骤4：降级处理

```typescript
@Entry
@Component
struct FallbackExample {
  @State isResourceAvailable: boolean = true;
  
  build() {
    Column() {
      Button('Action')
        .accessibilityText(
          this.isResourceAvailable 
            ? $r('app.string.action_accessibility') 
            : '执行操作的按钮'
        )
        .onClick(() => {
          // Resource不可用时使用备用文本
          if (!this.isResourceAvailable) {
            console.warn('Resource not available, using fallback text');
          }
        })
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数类型错误 | 检查传入参数类型是否为string或Resource |
| 100001 | Resource引用失败 | 检查资源文件路径和资源ID是否正确 |
| 100002 | 组件不支持无障碍属性 | 检查组件类型是否支持accessibilityText |
| 100003 | API版本不支持 | 确认应用API version ≥ 10（string）或 ≥ 12（Resource） |

## 编译和修复问题

### 依赖声明
无额外依赖，使用系统内置ArkUI框架。

### 环境要求
- DevEco Studio: 3.1+
- HarmonyOS SDK: API version 10+（基础支持），API version 12+（完整支持）
- ArkTS: 1.0+

### 常见编译问题

**问题1：accessibilityText方法不存在**
```
Error: Property 'accessibilityText' does not exist on type 'Button'
```
**解决方法**：
- 检查SDK版本是否满足最低要求（API version 10+）
- 确认组件类型是否支持无障碍属性
- 更新DevEco Studio和HarmonyOS SDK版本

**问题2：Resource引用编译错误**
```
Error: Cannot find name '$r'
```
**解决方法**：
- 确认API version ≥ 12
- 检查资源文件是否在resources目录下
- 确认资源ID格式正确（app.string.xxx）

**问题3：链式调用类型错误**
```
Error: Type 'void' is not assignable to type 'Button'
```
**解决方法**：
- accessibilityText返回组件对象，支持链式调用
- 确认调用顺序正确，在组件构建器中调用

## 常见问题与解决方法

### Q1：设置无障碍文本后没有朗读效果
**原因**：
- 屏幕朗读服务未开启
- accessibilityLevel设置为"no"或"no-hide-descendants"
- 父组件设置了accessibilityGroup(true)且子组件未设置特殊级别

**解决方法**：
- 在设备设置中开启屏幕朗读功能
- 设置accessibilityLevel为"yes"或"auto"
- 检查父组件的accessibilityGroup设置

### Q2：无障碍文本与显示文本冲突
**原因**：
- 组件同时设置了文本属性和无障碍文本属性

**解决方法**：
- 了解优先级规则：无障碍文本优先级高于显示文本
- 若需播报显示文本，不设置无障碍文本
- 若需播报补充信息，设置无障碍文本并包含显示文本内容

### Q3：Resource引用失败
**原因**：
- API version < 12
- 资源文件路径错误
- 资源ID不存在

**解决方法**：
- 确认API version ≥ 12，否则使用string格式
- 检查resources/base/element/string.json文件
- 确认资源ID格式：app.string.{resource_name}

### Q4：文本过长影响朗读体验
**原因**：
- 无障碍文本超过推荐长度（50字符）

**解决方法**：
- 精简无障碍文本，保留关键信息
- 使用accessibilityDescription补充详细说明
- 考虑分段播报或使用accessibilityGroup分组

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "componentType": "Button",
  "accessibilityText": "Accessibility text",
  "textFormat": "string",
  "apiVersion": "12",
  "apiUsed": [
    "accessibilityText"
  ],
  "description": "为组件设置无障碍文本，屏幕朗读时播报'Accessibility text'"
}
```

## 参考文档

- [标注屏幕朗读内容的场景](references/scenario-screen-reading-guide.md)
- [无障碍属性API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)

## 完整示例代码

- [基础示例](assets/screen-reading-basic.ets)
- [Resource引用示例](assets/screen-reading-resource.ets)
- [错误处理示例](assets/screen-reading-error-handling.ets)
- [降级处理示例](assets/screen-reading-fallback.ets)

## 测试用例

### 正向测试用例
- [字符串格式设置](tests/test_positive_string.ets)：验证string格式无障碍文本设置成功
- [Resource格式设置](tests/test_positive_resource.ets)：验证Resource格式无障碍文本设置成功
- [链式调用测试](tests/test_positive_chain.ets)：验证链式调用正确性

### 边界测试用例
- [文本长度测试](tests/test_boundary_length.ets)：验证超长文本处理
- [空字符串测试](tests/test_boundary_empty.ets)：验证空字符串行为
- [版本兼容测试](tests/test_boundary_version.ets)：验证不同API版本兼容性

### 异常测试用例
- [参数类型错误](tests/test_exception_type.ets)：验证错误参数类型处理
- [Resource引用失败](tests/test_exception_resource.ets)：验证Resource引用失败处理
- [不支持组件](tests/test_exception_component.ets)：验证不支持组件类型处理