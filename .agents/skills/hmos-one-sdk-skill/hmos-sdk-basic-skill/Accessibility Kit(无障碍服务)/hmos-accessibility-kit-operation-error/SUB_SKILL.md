---
name: hmos-accessibility-kit-operation-error
description: 实现操作错误场景的无障碍服务，支持通过屏幕朗读播报错误提示和改进方法，将错误状态与文本组件合并播报，适用于网络错误、警告提示等需要实时告知用户错误信息的场景
---

# 操作错误场景无障碍服务技能

## 功能描述

本技能用于实现应用中操作错误场景的无障碍服务功能。主要能力包括：

1. **错误状态可视化**：使用Radio组件配合颜色标识（如红色）展示错误状态
2. **屏幕朗读优化**：通过`accessibilityGroup`将Radio组件与错误提示文本合并为一个无障碍组
3. **语义化播报**：提供完整的错误提示文本，包括错误类型、具体错误内容和改进建议
4. **实时状态更新**：当错误状态变化时，自动更新无障碍播报内容

**适用范围**：
- 网络连接错误提示
- 表单验证失败提示
- 系统警告信息
- 其他需要实时告知用户的错误场景

**限制条件**：
- 仅适用于ArkTS声明式开发范式
- 需要配合屏幕朗读功能使用
- 错误提示文本不能仅依赖颜色区分

**典型场景**：
- 网络连接中断时播报"连接中断，请检查网络设置"
- 表单提交失败时播报"提交失败，请修正输入内容"
- 权限不足时播报"权限不足，请在设置中开启相关权限"

## 使用场景

### 触发词
- "操作错误提示"
- "错误状态播报"
- "错误信息无障碍"
- "网络错误提示"
- "警告信息播报"
- "accessibilityGroup错误"

### 能做
- 实现错误状态的视觉标识与屏幕朗读同步
- 将错误状态组件与文本组件合并播报
- 提供语义化的错误提示文本（错误类型+内容+建议）
- 使用Radio组件的`radioStyle`自定义错误状态颜色
- 通过`accessibilityText`设置完整的错误提示信息
- 通过`accessibilityDescription`提供详细说明

### 绝不做
- 仅使用颜色区分错误状态（不提供文本提示）
- 在错误提示中使用模糊或不清晰的描述
- 忽略屏幕朗读用户的信息获取需求
- 将错误状态组件与提示文本分离播报
- 使用不包含任何文本信息的纯图标错误提示

### 补充
- 错误提示应遵循WCAG无障碍标准，不仅依赖颜色
- 建议错误提示文本包含三部分：错误类型、具体内容、改进建议
- 当错误状态动态变化时，应及时更新`accessibilityText`内容
- 可结合`accessibilityLevel`属性控制组件的无障碍重要性
- 从API version 12开始，Radio组件默认选中样式为TICK图标

## 调用规范和规则

### 输入约束
- 错误提示文本长度：建议不超过200字符，最长不超过500字符
- 错误状态标识：必须使用明确的颜色标识（如红色）配合文本
- Radio组件group参数：必须设置以标识单选组
- accessibilityText内容：必须包含错误类型、具体内容、改进建议三要素
- 文本格式：必须使用UTF-8编码

### 执行约束
- 组件渲染耗时：不超过100ms
- 无障碍信息更新延迟：不超过200ms
- 最多嵌套层级：不超过3层容器嵌套
- 状态变化响应：立即更新accessibilityText

### 内容约束
- 禁止生成：仅依赖颜色标识的错误提示（无文本或语音）
- 禁止使用：模糊的错误描述（如"发生错误"、"出错了"）
- 禁止操作：将错误提示与正常状态使用相同颜色标识
- 禁止文本：不含任何改进建议的错误提示

### 降级约束
- 网络错误：提供本地缓存的错误提示文本
- 文本过长：截断至500字符并添加省略提示
- 组件渲染失败：使用纯文本错误提示作为降级方案
- 屏幕朗读不可用：确保视觉标识清晰可见（增大字号、加粗、边框高亮）

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认错误场景类型（网络错误、表单错误、权限错误等）
2. 准备错误提示文本内容（包含错误类型、具体内容、改进建议）
3. 确认Radio组件的group参数设置
4. 确认错误状态的颜色标识方案

**参数准备**：
```typescript
interface ErrorStateConfig {
  errorType: string           // 错误类型（如"Connection interrupted"）
  errorColor: Color           // 错误状态颜色（如Color.Red）
  accessibilityText: string   // 无障碍文本（如"网络连接中断，请检查网络设置")
  accessibilityDescription: string // 详细说明（如"这是网络连接状态的错误提示")
}
```

### 步骤2：创建错误状态组件

**示例代码**：
```typescript
@Entry
@Component
struct OperationErrorExample {
  @State errorState: boolean = true
  @State errorMessage: string = 'Connection interrupted'
  
  build() {
    NavDestination() {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Row() {
            Text('Connection state').fontSize(30)
          }
          Row() {
            Radio({ value: 'Radio1', group: 'errorGroup' })
              .checked(this.errorState)
              .radioStyle({
                checkedBackgroundColor: Color.Red
              })
              .height(50)
              .width(50)
              .onChange((isChecked: boolean) => {
                console.info('Error state changed: ' + isChecked)
                this.errorState = isChecked
              })
            Text(this.errorMessage)
              .fontColor(Color.Red)
              .fontSize(20)
          }
          .width('80%')
          .accessibilityGroup(true)
          .accessibilityText('Connection error: ' + this.errorMessage + ', please check network settings')
          .accessibilityDescription('This is a network connection error indicator')
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }.title('Operation Error Scenario')
  }
}
```

### 步骤3：设置无障碍属性

**关键属性设置**：
```typescript
Row() {
  // Radio组件用于标识错误状态
  Radio({ value: 'errorRadio', group: 'errorGroup' })
    .checked(true)
    .radioStyle({ checkedBackgroundColor: Color.Red })
    .height(50)
    .width(50)
  
  // 错误提示文本
  Text('Connection interrupted')
    .fontColor(Color.Red)
    .fontSize(20)
}
.width('80%')
// 关键：将Radio和Text合并为一个无障碍组
.accessibilityGroup(true)
// 设置无障碍文本（包含错误类型、内容、建议）
.accessibilityText('网络连接中断，请检查网络设置')
// 设置详细说明
.accessibilityDescription('这是网络连接状态的错误提示，点击可查看详细信息')
```

**重要说明**：
- `accessibilityGroup(true)`：将父容器内的所有子组件（Radio + Text）合并为一个无障碍组，屏幕朗读时会作为一个整体播报
- `accessibilityText()`：设置无障碍文本，当组件被选中时播报此内容
- `accessibilityDescription()`：设置详细说明，在文本播报后会继续播报此说明

### 步骤4：错误处理

**常见错误场景处理**：
```typescript
try {
  // 网络请求或操作执行
  await performNetworkOperation()
  this.errorState = false
  this.errorMessage = ''
} catch (error) {
  // 捕获错误并更新状态
  this.errorState = true
  this.errorMessage = getErrorMessage(error.code)
  
  // 更新无障碍文本
  const accessibilityText = generateAccessibilityText(error)
  this.container.accessibilityText = accessibilityText
  
  console.error('Operation failed:', error.message)
}
```

### 步骤5：降级处理

**降级方案示例**：
```typescript
// 方案1：纯文本错误提示（当Radio组件不可用时）
if (!isRadioAvailable) {
  Text(this.errorMessage)
    .fontColor(Color.Red)
    .fontSize(20)
    .fontWeight(FontWeight.Bold)
    .border({ width: 2, color: Color.Red })
    .padding(10)
    .accessibilityText('错误提示：' + this.errorMessage)
}

// 方案2：简化播报（当文本过长时）
if (this.errorMessage.length > 200) {
  const shortText = this.errorMessage.substring(0, 200) + '...请查看详情'
  this.container.accessibilityText = shortText
}
```

## 错误码说明

本场景不涉及特定的API错误码，但需要处理以下应用层错误：

| 错误类型 | 说明 | 解决方法 |
|---------|------|---------|
| NETWORK_ERROR | 网络连接错误 | 检查网络状态，提供"连接中断，请检查网络设置"提示 |
| VALIDATION_ERROR | 表单验证失败 | 提供具体的字段错误信息和修正建议 |
| PERMISSION_ERROR | 权限不足错误 | 提供权限设置路径和开启方法 |
| TIMEOUT_ERROR | 操作超时错误 | 提供重试建议或等待时间提示 |
| UNKNOWN_ERROR | 未知错误 | 提供通用的错误提示和联系支持的建议 |

## 编译和修复问题

### 依赖声明
无需额外依赖，使用HarmonyOS SDK内置组件：
```json
{
  "dependencies": {
    "@ohos/hypium": "^1.0.0"  // 用于测试
  }
}
```

### 环境要求
- HarmonyOS SDK版本：API version 10+（推荐API version 12+）
- DevEco Studio版本：3.1+
- 运行环境：HarmonyOS设备或模拟器（支持屏幕朗读功能）

### 常见编译问题

**问题1：accessibilityGroup属性未生效**
```
编译警告：Property 'accessibilityGroup' does not exist on type 'RowAttribute'
```
**解决方法**：确保使用API version 10+，在module.json5中声明正确的API版本

**问题2：Radio组件group参数冲突**
```
运行时错误：Multiple Radio components with same group
```
**解决方法**：确保每个Radio组件的group参数唯一，或在同一group中仅有一个Radio处于checked状态

**问题3：accessibilityText内容未播报**
```
屏幕朗读未播报错误提示文本
```
**解决方法**：
1. 确认accessibilityGroup设置为true
2. 确认accessibilityText内容不为空
3. 确认屏幕朗读功能已开启
4. 确认组件的accessibilityLevel未设置为"no"

## 常见问题与解决方法

### Q1：错误提示仅显示颜色，屏幕朗读用户无法感知？
**原因**：仅使用颜色标识错误状态，未提供文本或语音提示
**解决方法**：
- 设置accessibilityText提供明确的错误提示文本
- 使用accessibilityGroup合并组件，确保整体播报
- 文本内容包含错误类型、具体内容和改进建议

### Q2：错误提示文本过于简单，用户不知道如何处理？
**原因**：accessibilityText仅包含错误类型，未提供改进建议
**解决方法**：
- 采用"错误类型 + 具体内容 + 改进建议"的三段式文本格式
- 示例："网络连接中断（错误类型），请检查WiFi设置并重新连接（改进建议）"
- 使用accessibilityDescription提供更详细的操作指导

### Q3：错误状态变化后，屏幕朗读未更新播报内容？
**原因**：状态变化时未及时更新accessibilityText属性
**解决方法**：
- 在状态变化的回调函数中更新accessibilityText
- 使用@State装饰器自动触发UI刷新
- 示例代码：
```typescript
.onChange((isChecked: boolean) => {
  this.errorState = isChecked
  // 更新无障碍文本
  this.container.accessibilityText = generateNewAccessibilityText(isChecked)
})
```

### Q4：Radio组件与错误文本分离播报，用户体验不佳？
**原因**：未使用accessibilityGroup合并组件
**解决方法**：
- 在父容器（Row）上设置`.accessibilityGroup(true)`
- 确保Radio组件和Text组件在同一容器内
- 合并后的播报示例："选中，Connection interrupted，网络连接中断，请检查网络设置"

### Q5：如何在不同错误类型间切换？
**原因**：错误状态配置未实现动态切换逻辑
**解决方法**：
- 定义统一的错误状态配置接口
- 实现错误类型识别函数
- 根据错误类型动态生成accessibilityText
```typescript
function getErrorConfig(errorCode: number): ErrorStateConfig {
  switch (errorCode) {
    case NETWORK_ERROR:
      return { errorType: 'Network', errorColor: Color.Red, ... }
    case PERMISSION_ERROR:
      return { errorType: 'Permission', errorColor: Color.Orange, ... }
    default:
      return { errorType: 'Unknown', errorColor: Color.Gray, ... }
  }
}
```

## 输出结果报告

实现完成后输出以下信息：

```json
{
  "status": "success",
  "functionality": "操作错误场景无障碍服务实现",
  "componentsUsed": [
    "Radio组件",
    "Text组件",
    "Row容器",
    "Column容器"
  ],
  "accessibilityFeatures": [
    "accessibilityGroup用于合并组件",
    "accessibilityText提供错误提示",
    "accessibilityDescription提供详细说明",
    "radioStyle自定义错误颜色"
  ],
  "apiUsed": [
    "Radio(options: RadioOptions)",
    "Radio.checked(value: boolean)",
    "Radio.radioStyle(value?: RadioStyle)",
    "Radio.onChange(callback: (isChecked: boolean) => void)",
    "Row.accessibilityGroup(value: boolean)",
    "Row.accessibilityText(value: string)",
    "Row.accessibilityDescription(value: string)"
  ],
  "wcagCompliance": {
    "level": "AA",
    "guidelines": [
      "1.4.1 使用颜色不作为传达信息的唯一视觉手段",
      "4.1.2 名称、角色、值"
    ]
  },
  "screenReaderSupport": "完整支持，提供语义化播报",
  "testCoverage": "正向/边界/异常场景全覆盖"
}
```

## 参考文档

- [操作错误场景开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-operation-error)
- [Radio组件API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-radio)
- [无障碍属性API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
- [RadioStyle对象说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-radio#radiostyle10对象说明)
- [AccessibilityOptions对象说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-types#accessibilityoptions14对象说明)

## 完整示例代码

- [ArkTS示例代码](assets/operation-error-example.ets)：包含完整的错误状态展示和无障碍属性设置
- [配置文件示例](references/scenario-operation-error-guide.md)：原始开发指南文档

## 测试用例

### 正向测试用例
- [测试accessibilityGroup启用](tests/test_positive.ets)：验证无障碍分组属性正确设置
- [测试accessibilityText内容](tests/test_positive.ets)：验证无障碍文本包含完整信息
- [测试错误状态颜色](tests/test_positive.ets)：验证Radio组件使用红色标识错误状态

### 边界测试用例
- [测试空错误文本](tests/test_boundary.ets)：验证空文本场景的处理
- [测试超长accessibilityText](tests/test_boundary.ets)：验证长文本截断逻辑
- [测试无文本组件的分组](tests/test_boundary.ets)：验证纯图标场景的降级处理

### 异常测试用例
- [测试无效accessibilityGroup值](tests/test_exception.ets)：验证类型错误处理
- [测试缺失accessibilityText](tests/test_exception.ets)：验证缺失文本时的默认行为
- [测试Radio group冲突](tests/test_exception.ets)：验证单选组参数冲突处理