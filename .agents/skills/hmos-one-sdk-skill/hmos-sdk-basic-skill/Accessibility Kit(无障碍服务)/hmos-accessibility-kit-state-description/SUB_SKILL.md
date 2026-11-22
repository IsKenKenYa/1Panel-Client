---
name: hmos-accessibility-kit-state-description
description: 设置组件状态说明标签实现屏幕朗读状态播报+适用于可切换状态控件+支持string和Resource类型+典型场景:收藏按钮等状态切换控件
---

# 自定义控件播报状态技能

## 功能描述

本技能用于设置可切换状态控件的状态说明标签,实现屏幕朗读模式下的状态播报。通过`accessibilityStateDescription` API为组件指定状态说明文本,当用户聚焦控件或执行双击操作后,屏幕朗读会播报指定的状态说明标签,帮助用户理解控件的当前状态。

**核心能力**:
- 为可切换状态控件设置状态说明标签
- 支持string类型和Resource类型参数
- 实现屏幕朗读状态播报
- 配合accessibilitySelected使用完善状态管理

**适用场景**:
- 收藏按钮(已收藏/未收藏)
- 开关按钮(已开启/已关闭)
- 选择按钮(已选中/未选中)
- 其他可切换状态的交互控件

## 使用场景

### 触发词
- "状态播报"
- "状态说明标签"
- "accessibilityStateDescription"
- "控件状态播报"
- "无障碍状态说明"
- "屏幕朗读状态"

### 能做
- 为可切换状态控件设置状态说明标签
- 实现屏幕朗读模式下的状态播报
- 根据控件状态动态切换播报内容
- 配合accessibilitySelected完善无障碍状态管理
- 支持string类型和Resource类型的状态文本

### 绝不做
- 不适用于不可切换状态的控件(如纯展示文本)
- 不替代控件的实际状态管理逻辑
- 不处理超出无障碍状态播报范围的功能
- 不用于设置无障碍文本或说明(accessibilityText/accessibilityDescription)

### 补充
- 必须配合accessibilitySelected使用才能完整实现状态播报
- 状态说明标签会覆盖默认推导的状态说明
- 状态文本建议简洁明了,便于屏幕朗读播报
- API从HarmonyOS 10开始支持

## 调用规范和规则

### 输入约束
- 状态文本长度: 建议10个字符以内,便于播报
- 参数类型: string或Resource类型
- 状态变化逻辑: 必须有明确的状态切换逻辑

### 执行约束
- 状态更新时机: 状态切换后立即更新状态说明标签
- 状态同步: accessibilityStateDescription与accessibilitySelected状态保持一致
- 播报触发: 用户聚焦或双击操作触发播报

### 内容约束
- 禁止使用过长状态文本(超过30字符)
- 禁止使用模糊状态描述(如"改变了"等)
- 禁止在不可切换控件上使用
- 状态文本必须准确反映控件当前状态

### 降级约束
- 未设置状态说明: 使用系统默认推导的状态说明
- 状态文本为空: 不播报状态说明,仅播报控件内容
- Resource资源不存在: 使用默认空字符串
- 状态切换失败: 保持原状态说明标签不变

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 确认组件为可切换状态控件(如Button、Switch等)
2. 定义状态管理变量(如isSelected)
3. 准备状态说明文本资源(如"已收藏"/"未收藏")

**参数准备**:
```typescript
// ArkTS示例
@State private isSelected: boolean = false; // 控件状态变量
private selectedText: string = "已收藏"; // 已选中状态文本
private unselectedText: string = "未收藏"; // 未选中状态文本
```

### 步骤2:设置状态说明标签

**示例代码**:
```typescript
// 导入必要模块(无需额外导入,ArkUI内置)

// 设置按钮的状态说明标签和选中状态
Button() {
  // 根据状态显示不同的图标
  Image(this.isSelected ? $r('app.media.favorIcon') : $r('app.media.unfavorIcon'))
    .width(30)
    .height(30)
}
// 指定按钮的状态说明标签
.accessibilityStateDescription(this.isSelected ? this.selectedText : this.unselectedText)
// 设置按钮的选中状态
.accessibilitySelected(this.isSelected)
// 按钮点击事件处理程序
.onClick(() => {
  this.isSelected = !this.isSelected; // 切换选中状态
})
```

### 步骤3:错误处理

```typescript
// 错误处理代码示例
@State private isSelected: boolean = false;
@State private statusError: string = "";

// 安全的状态文本获取
private getStatusText(): string {
  try {
    // 根据状态返回对应的文本
    return this.isSelected ? "已收藏" : "未收藏";
  } catch (error) {
    // 记录错误但不影响功能
    this.statusError = `状态文本获取失败: ${error.message}`;
    return ""; // 返回空字符串作为降级方案
  }
}

// 在组件中使用
Button()
  .accessibilityStateDescription(this.getStatusText())
  .accessibilitySelected(this.isSelected)
  .onClick(() => {
    try {
      this.isSelected = !this.isSelected;
    } catch (error) {
      console.error(`状态切换失败: ${error.message}`);
      // 保持原状态不变
    }
  })
```

### 步骤4:降级处理

```typescript
// 降级处理代码示例
// 当无法提供状态说明时,使用系统默认推导
Button()
  .accessibilitySelected(this.isSelected) // 仅设置选中状态,系统自动推导状态说明
  .onClick(() => {
    this.isSelected = !this.isSelected;
  })

// 或使用Resource类型作为降级方案
Button()
  .accessibilityStateDescription(this.isSelected ? 
    $r('app.string.selected_state') : // 使用Resource资源
    $r('app.string.unselected_state')
  )
  .accessibilitySelected(this.isSelected)
  .onClick(() => {
    this.isSelected = !this.isSelected;
  })
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| INVALID_STATE | 状态变量未定义或类型错误 | 使用@State定义boolean类型状态变量 |
| EMPTY_DESCRIPTION | 状态说明文本为空 | 提供有效的状态文本或使用系统默认推导 |
| RESOURCE_NOT_FOUND | Resource资源文件不存在 | 检查资源文件路径,使用string类型作为降级 |
| STATE_MISMATCH | 状态说明与选中状态不匹配 | 确保accessibilityStateDescription与accessibilitySelected状态一致 |
| TYPE_ERROR | 参数类型错误 | 使用string或Resource类型参数 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    // 无需额外依赖,ArkUI内置API
  }
}
```

### 环境要求
- HarmonyOS API version: 10及以上
- DevEco Studio: 3.1及以上
- ArkTS编译器: 支持最新语法

### 常见编译问题

**问题1:无法识别accessibilityStateDescription**
```
Error: 'accessibilityStateDescription' is not defined
```
**解决方法**: 
- 检查API version是否≥10
- 确认使用正确的组件类型(Button等通用组件)
- 无需导入,ArkUI内置API

**问题2:Resource类型编译错误**
```
Error: Cannot find resource 'app.string.selected_state'
```
**解决方法**: 
- 检查资源文件路径是否正确
- 在resources/base/element/string.json中定义字符串资源
- 使用string类型作为替代方案

**问题3:状态更新不生效**
```
屏幕朗读未播报更新后的状态说明
```
**解决方法**: 
- 确保使用@State状态变量
- 检查状态切换逻辑是否正确执行
- 确认accessibilitySelected状态同步更新

## 常见问题与解决方法

### Q1:状态说明标签播报时机是什么?
**原因**: 屏幕朗读播报状态说明标签有两个时机
**解决方法**:
- 用户聚焦控件时播报状态说明
- 用户执行双击操作后播报状态说明
- 状态切换后下次聚焦播报新状态

### Q2:如何选择使用string还是Resource类型?
**原因**: 两种类型各有优势
**解决方法**:
- string类型: 适合简单固定文本,便于调试
- Resource类型: 适合国际化场景,便于资源管理
- 推荐Resource类型用于正式项目

### Q3:状态说明与无障碍文本有什么区别?
**原因**: 两者功能和使用场景不同
**解决方法**:
- accessibilityStateDescription: 专门用于状态播报(已收藏/未收藏)
- accessibilityText: 用于控件内容播报(收藏按钮)
- accessibilityDescription: 用于详细说明(点击收藏此内容)
- 三者可同时使用,播报顺序:文本→状态→说明

### Q4:状态说明标签可以动态变化吗?
**原因**: 状态说明标签需要与控件状态同步
**解决方法**:
- 使用三元表达式根据状态选择文本: `this.isSelected ? "已收藏" : "未收藏"`
- 状态切换后自动更新播报内容
- 确保状态变量使用@State修饰

### Q5:多个控件如何统一管理状态说明?
**原因**: 需要复用状态说明文本
**解决方法**:
- 定义公共状态文本常量或资源
- 使用函数封装状态文本获取逻辑
- 建议使用Resource类型便于统一管理

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "SUCCESS",
  "functionImplemented": "设置组件状态说明标签实现屏幕朗读状态播报",
  "apiUsed": [
    "accessibilityStateDescription",
    "accessibilitySelected"
  ],
  "stateManagement": "使用@State状态变量管理控件状态",
  "accessibilityLevel": "组件可被无障碍服务识别",
  "screenReaderSupport": "支持屏幕朗读状态播报"
}
```

## 参考文档

- [API开发指南](references/accessibilitystatedescription-guide.md)
- [API参考说明](references/ts-universal-attributes-accessibility.md)

## 完整示例代码

- [ArkTS示例(收藏按钮)](assets/favorite_button_example.ets)
- [ArkTS示例(开关按钮)](assets/switch_button_example.ets)
- [ArkTS示例(选择按钮)](assets/select_button_example.ets)

## 测试用例

### 正向测试用例
- [收藏按钮状态播报测试](tests/test_favorite_button.ets): 测试收藏按钮状态切换和播报
- [开关按钮状态播报测试](tests/test_switch_button.ets): 测试开关按钮状态播报功能
- [Resource类型状态文本测试](tests/test_resource_type.ets): 测试Resource类型状态文本

### 边界测试用例
- [空状态文本测试](tests/test_empty_text.ets): 测试空字符串状态文本的处理
- [长状态文本测试](tests/test_long_text.ets): 测试长文本状态说明的播报
- [状态快速切换测试](tests/test_fast_toggle.ets): 测试快速状态切换的播报响应

### 异常测试用例
- [状态变量未定义测试](tests/test_undefined_state.ets): 测试状态变量未定义的错误处理
- [Resource资源不存在测试](tests/test_missing_resource.ets): 测试Resource资源缺失的降级处理
- [状态不匹配测试](tests/test_state_mismatch.ets): 测试状态说明与选中状态不一致的处理