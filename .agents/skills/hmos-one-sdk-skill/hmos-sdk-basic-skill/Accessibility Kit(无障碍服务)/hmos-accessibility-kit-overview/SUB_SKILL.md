---
name: hmos-accessibility-kit-overview
description: 提供无障碍服务状态查询、无障碍事件发送等能力介绍，支持查询辅助应用状态、触摸浏览状态，适用于了解Accessibility Kit基本功能和适用场景
---

# Accessibility Kit 简介技能

## 功能描述

Accessibility Kit（无障碍服务）为应用提供无障碍适配能力，确保任何人在任何情况下都能平等、便捷地获取并利用信息。本技能提供无障碍服务的状态查询和事件发送能力，帮助开发者快速了解Accessibility Kit的基本功能和适用场景。

**核心能力**：
- **无障碍状态查询**：提供无障碍服务开启状态、触摸浏览开启状态查询接口，以便应用根据无障碍功能开启状态，更好的服务于障碍人群和障碍场景
- **无障碍事件发送**：提供主动聚焦、主动朗读等无障碍事件发送接口，以便应用结合业务场景，做到更好的无障碍体验

**系统服务支持**：
系统针对不同的障碍人群和障碍场景，提供了多种辅助服务能力：
- 屏幕朗读
- 大字体
- 高对比度文字
- 色彩校正
- 颜色反转
- 单声道音频
- 音量平衡
- 屏幕触控

**应用设计建议**：
应用在设计时，需要在以下维度考虑信息获取和应用使用的无障碍：
- 布局
- 配色
- 字体
- 交互
- 播报
- 反馈维度

## 使用场景

### 触发词
- "Accessibility Kit简介"
- "无障碍服务介绍"
- "无障碍状态查询"
- "无障碍事件发送"
- "辅助功能状态"
- "触摸浏览状态"

### 能做
- 查询无障碍服务开启状态
- 查询触摸浏览开启状态
- 发送无障碍事件（主动聚焦、主动朗读）
- 了解Accessibility Kit与ArkUI Kit的关系
- 了解模拟器支持情况和差异

### 绝不做
- 不直接实现具体的无障碍组件开发（需参考具体组件开发技能）
- 不处理超出Accessibility Kit范围的请求
- 不替代具体API的详细实现文档

### 补充
- Accessibility Kit依赖ArkUI Kit提供无障碍组件属性定义、无障碍事件发送能力
- 应用需基于ArkUI Kit为组件设置无障碍文本、描述信息等属性
- 模拟器不支持放大手势、声音修复、助听设备、闪烁提醒等功能

## 调用规范和规则

### 输入约束
- 查询参数必须符合API定义的类型要求
- 状态查询返回值为布尔类型或枚举值
- 事件发送参数必须包含必要的配置信息

### 执行约束
- 状态查询操作为同步调用，建议不超过5次/秒
- 事件发送操作为异步调用，需使用Promise或回调处理结果
- 错误处理必须包含try-catch机制

### 内容约束
- 禁止使用未声明的API接口
- 禁止在未查询状态前直接发送无障碍事件
- 禁止忽略错误码处理

### 降级约束
- 状态查询失败：返回默认值false，并记录日志
- 事件发送失败：取消事件发送，并提示用户当前环境不支持
- API调用异常：使用备用方案或提示用户系统版本不兼容

## 调用流程和步骤

### 步骤1：导入Accessibility模块

**导入示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
```

**前置校验**：
- 确认系统API版本≥7（Accessibility Kit首批接口从API version 7开始支持）
- 确认应用已获取必要权限
- 确认设备支持无障碍服务

### 步骤2：查询无障碍状态

**查询示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

// 查询辅助应用状态
async function queryAccessibilityState(): Promise<void> {
  try {
    // 获取辅助应用列表
    const abilities = await accessibility.getAccessibilityAbilityList();
    console.log('辅助应用列表:', abilities);
    
    // 查询触摸浏览状态
    const touchExploreState = await accessibility.getTouchExploreState();
    console.log('触摸浏览状态:', touchExploreState);
    
    return;
  } catch (error) {
    console.error('查询无障碍状态失败:', error.message);
    throw error;
  }
}
```

### 步骤3：发送无障碍事件

**事件发送示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

// 发送无障碍事件
async function sendAccessibilityEvent(eventType: string, componentId: string): Promise<void> {
  try {
    // 构造事件参数
    const eventParams = {
      type: eventType,
      bundleName: 'com.example.myapp',
      triggerAction: 'common'
    };
    
    // 发送事件
    await accessibility.sendEvent(eventParams);
    console.log('无障碍事件已发送:', eventType);
    
    return;
  } catch (error) {
    console.error('发送无障碍事件失败:', error.message);
    throw error;
  }
}
```

### 步骤4：错误处理

**错误处理代码**：
```typescript
try {
  await queryAccessibilityState();
} catch (error) {
  switch (error.code) {
    case 201:
      console.error('权限不足，请检查应用权限配置');
      break;
    case 401:
      console.error('参数错误，请检查输入参数类型和值');
      break;
    case 16000050:
      console.error('内部错误，请稍后重试');
      break;
    default:
      console.error('未知错误:', error.message);
  }
}
```

### 步骤5：降级处理

**降级处理代码**：
```typescript
// 降级处理示例
async function queryWithFallback(): Promise<boolean> {
  try {
    const state = await accessibility.getTouchExploreState();
    return state;
  } catch (error) {
    console.warn('查询失败，使用默认值false');
    return false; // 降级返回默认值
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限不足 | 检查应用权限配置，确保已申请必要权限 |
| 401 | 参数错误 | 检查输入参数的类型和值是否符合API要求 |
| 16000050 | 内部错误 | 系统内部错误，建议稍后重试或重启应用 |
| 16000051 | 服务未启动 | 无障碍服务未启动，请引导用户开启相关服务 |
| 16000052 | API不支持 | 当前系统版本不支持此API，请检查API版本要求 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version ≥ 7
- DevEco Studio ≥ 3.1
- Node.js ≥ 14.0

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccessibilityKit'
```
**解决方法**：检查项目配置，确保已正确配置HarmonyOS SDK和API version

**问题2：API版本不支持**
```
Error: API version mismatch
```
**解决方法**：检查build-profile.json5中的compatibleSdkVersion和targetSdkVersion配置

**问题3：权限不足**
```
Error: Permission denied
```
**解决方法**：在module.json5中添加必要权限声明，如ohos.permission.GET_ACCESSIBILITY_STATE

## 常见问题与解决方法

### Q1：查询状态返回undefined
**原因**：无障碍服务未启动或API版本不支持
**解决方法**：
- 检查系统设置中无障碍服务是否开启
- 检查设备API版本是否符合要求
- 使用降级方案返回默认值

### Q2：事件发送无响应
**原因**：组件未正确设置无障碍属性或事件类型不匹配
**解决方法**：
- 检查组件是否设置了accessibilityText等属性
- 础认事件类型是否在支持的范围内
- 检查应用是否在无障碍服务的关注列表中

### Q3：模拟器功能受限
**原因**：模拟器不支持部分无障碍功能
**解决方法**：
- 查阅[模拟器与真机的差异](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-specification)
- 在真机上测试实际功能
- 使用替代方案或跳过不支持的功能

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "accessibilityState": {
    "touchExploreEnabled": false,
    "screenReaderEnabled": true,
    "abilitiesList": []
  },
  "apiUsed": [
    "@ohos.accessibility.getAccessibilityAbilityList",
    "@ohos.accessibility.getTouchExploreState",
    "@ohos.accessibility.sendEvent"
  ],
  "version": {
    "minAPI": 7,
    "currentAPI": 12
  }
}
```

## 参考文档

- [Accessibility Kit简介](references/accessibilitykit-overview.md)
- [@ohos.accessibility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)
- [模拟器与真机的差异](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-emulator-specification)

## 完整示例代码

- [ArkTS状态查询示例](assets/query_accessibility_state.ets)
- [ArkTS事件发送示例](assets/send_accessibility_event.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [查询无障碍服务状态](tests/test_query_state_positive.ets)：测试正常查询无障碍服务状态
- [发送无障碍事件](tests/test_send_event_positive.ets)：测试正常发送无障碍事件

### 边界测试用例
- [查询空状态](tests/test_query_empty.ets)：测试无障碍服务未启动时的状态查询
- [发送无效事件](tests/test_send_invalid_event.ets)：测试发送无效事件类型的处理

### 异常测试用例
- [权限不足异常](tests/test_permission_error.ets)：测试权限不足时的错误处理
- [API版本不支持](tests/test_api_version_error.ets)：测试低版本API不支持的处理
- [参数类型错误](tests/test_param_error.ets)：测试参数类型错误的处理