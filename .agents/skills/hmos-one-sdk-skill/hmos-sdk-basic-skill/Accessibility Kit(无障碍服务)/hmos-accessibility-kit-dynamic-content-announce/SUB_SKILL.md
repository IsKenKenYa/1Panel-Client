---
name: hmos-accessibility-kit-dynamic-content-announce
description: 主动播报界面动态变化内容，支持文本播报和Resource类型播报，适用于内容更新、状态变化等需及时通知用户的场景
---

# 内容动态变化场景主动播报技能

## 功能描述

本技能实现无障碍主动播报功能，当界面上的重要内容发生动态变化时，通过Accessibility Kit提供的主动播报接口`sendAccessibilityEvent`发送`announceForAccessibility`事件，让屏幕朗读功能自动播报变化后的内容。适用于需要及时通知用户界面内容更新的场景，如数据刷新、状态变化、提示信息更新等。

## 使用场景

### 触发词
- "动态内容播报"
- "内容变化通知"
- "主动播报"
- "屏幕朗读播报"
- "无障碍播报"
- "内容更新通知"

### 能做
- 在界面内容动态变化后主动触发屏幕朗读播报
- 支持播报文本字符串内容
- 支持播报Resource类型的字符串资源
- 可自定义播报内容，确保用户及时了解重要信息变化
- 适用于数据刷新、状态变化、提示更新等场景

### 绝不做
- 不用于处理静态内容展示
- 不用于常规的用户操作反馈
- 不用于替代组件的accessibilityText属性
- 不用于播报用户已知的固定内容
- 不用于频繁播报（需控制播报频率避免干扰用户体验）

### 补充
- 播报内容应简洁明了，避免过长文本影响用户体验
- 建议仅在重要内容变化时触发播报，避免过度播报
- 需确保屏幕朗读功能已开启才能生效
- 从API version 12开始支持Resource类型播报

## 调用规范和规则

### 输入约束
- 播报内容长度：建议不超过100字符，避免播报时间过长
- 播报内容格式：支持string类型或Resource类型（仅支持string资源）
- 播报频率：建议单次操作最多触发1次播报，避免连续多次播报
- bundleName：必须传入当前应用包名，不可缺省

### 执行约束
- API调用时机：仅在内容确实发生变化且对用户有重要提示作用时调用
- 最大播报次数：单页面同时最多建议不超过3个播报队列
- 异步调用：使用Promise或AsyncCallback方式异步调用
- 必须校验：调用前无需特别校验，API内部会处理错误情况

### 内容约束
- 禁止播报：敏感信息、密码、密钥等隐私内容
- 禁止播报：系统级错误信息、异常堆栈信息
- 禁止播报：过于技术化的内部实现细节
- 建议播报：用户可理解的状态变化、数据更新、提示信息

### 降级约束
- 屏幕朗读未开启：播报不会生效，但不影响应用正常运行，无需降级处理
- API调用失败：记录日志并继续执行后续逻辑，不影响用户体验
- Resource资源不存在：使用fallback文本替代或忽略播报

## 调用流程和步骤

### 步骤1：准备阶段

**前置条件**：
1. 界面内容确实发生了动态变化
2. 变化内容对用户有必要的提示、告知或指导作用
3. 已导入Accessibility Kit模块

**参数准备**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

// 构造EventInfo对象
const eventInfo: accessibility.EventInfo = {
  type: 'announceForAccessibility',  // 主动播报事件类型
  bundleName: 'com.example.myapp',   // 当前应用包名
  triggerAction: 'common',            // 触发动作
  textAnnouncedForAccessibility: '内容已更新' // 播报内容（string类型）
};

// 或使用Resource类型播报（API version 12+）
const eventInfoWithResource: accessibility.EventInfo = {
  type: 'announceForAccessibility',
  bundleName: 'com.example.myapp',
  triggerAction: 'common',
  textResourceAnnouncedForAccessibility: $r('app.string.update_message') // Resource类型
};
```

### 步骤2：调用API

**使用Promise方式**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function announceContentChange(content: string): Promise<void> {
  try {
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.myapp', // 替换为实际应用包名
      triggerAction: 'common',
      textAnnouncedForAccessibility: content
    };
    
    await accessibility.sendAccessibilityEvent(eventInfo);
    console.info(`Succeeded in sending accessibility event`);
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to send accessibility event, Code: ${err.code}, Message: ${err.message}`);
  }
}

// 调用示例
announceContentChange('数据已成功更新');
```

**使用AsyncCallback方式**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

function announceContentChangeCallback(content: string): void {
  const eventInfo: accessibility.EventInfo = {
    type: 'announceForAccessibility',
    bundleName: 'com.example.myapp', // 替换为实际应用包名
    triggerAction: 'common',
    textAnnouncedForAccessibility: content
  };
  
  accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
    if (err) {
      console.error(`Failed to send accessibility event, Code: ${err.code}, Message: ${err.message}`);
      return;
    }
    console.info(`Succeeded in sending accessibility event`);
  });
}

// 调用示例
announceContentChangeCallback('状态已发生变化');
```

### 步骤3：错误处理

```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function safeAnnounceContent(content: string): Promise<void> {
  try {
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.myapp',
      triggerAction: 'common',
      textAnnouncedForAccessibility: content
    };
    
    await accessibility.sendAccessibilityEvent(eventInfo);
  } catch (error) {
    const err = error as BusinessError;
    switch (err.code) {
      case 401:
        console.error('Parameter error: check EventInfo fields');
        break;
      default:
        console.error(`Unknown error: ${err.message}`);
    }
  }
}
```

### 步骤4：降级处理

```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function announceWithFallback(primaryContent: string, fallbackContent?: string): Promise<void> {
  const contentToAnnounce = fallbackContent || primaryContent;
  
  try {
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.myapp',
      triggerAction: 'common',
      textAnnouncedForAccessibility: contentToAnnounce
    };
    
    await accessibility.sendAccessibilityEvent(eventInfo);
  } catch (error) {
    const err = error as BusinessError;
    console.warn(`Accessibility announcement failed, continuing without announcement`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，可能原因：1. 必填参数未指定；2. 参数类型错误；3. 参数验证失败 | 检查EventInfo对象中的type、bundleName、triggerAction是否正确设置，确保textAnnouncedForAccessibility为string类型 |
| 其他错误 | 系统内部错误或无障碍服务异常 | 记录日志并继续执行，不影响应用主流程 |

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
- HarmonyOS API version 9+（sendAccessibilityEvent）
- HarmonyOS API version 12+（textResourceAnnouncedForAccessibility）
- 屏幕朗读功能需在系统设置中启用

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccessibilityKit'
```
**解决方法**：确保项目使用HarmonyOS SDK，并在build-profile.json5中配置正确的API版本

**问题2：EventInfo类型错误**
```
Error: Type 'string' is not assignable to type 'EventType'
```
**解决方法**：确保type字段值为'announceForAccessibility'，triggerAction字段值为'common'或其他有效的Action类型

**问题3：Resource类型不支持**
```
Error: textResourceAnnouncedForAccessibility is not supported
```
**解决方法**：升级到API version 12+，或使用textAnnouncedForAccessibility替代

## 常见问题与解决方法

### Q1：播报没有生效，用户听不到内容
**原因**：
- 屏幕朗读功能未开启
- bundleName参数不正确
- 播报内容为空或无效

**解决方法**：
- 在系统设置中启用屏幕朗读功能
- 确认bundleName为当前应用的实际包名
- 检查textAnnouncedForAccessibility内容是否有效

### Q2：播报内容过长影响用户体验
**原因**：
- 未控制播报内容长度
- 播报频率过高

**解决方法**：
- 精简播报内容，建议不超过100字符
- 仅在重要变化时触发播报
- 避免短时间内连续播报

### Q3：Resource类型播报失败
**原因**：
- API版本低于12
- Resource资源不存在或类型错误

**解决方法**：
- 升级到API version 12+
- 确保Resource为string类型资源
- 使用fallback文本作为降级方案

### Q4：多次调用导致播报队列混乱
**原因**：
- 未控制调用频率
- 异步调用未等待完成

**解决方法**：
- 控制播报频率，单页面同时不超过3个播报
- 使用Promise方式等待前一次播报完成后再触发下一次

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "eventType": "announceForAccessibility",
  "bundleName": "com.example.myapp",
  "contentAnnounced": "内容已更新",
  "apiUsed": [
    "accessibility.sendAccessibilityEvent",
    "accessibility.EventInfo"
  ]
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-dynamic-content-change)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)

## 完整示例代码

- [ArkTS示例（文本播报）](assets/example_text_announce.ets)
- [ArkTS示例（Resource播报）](assets/example_resource_announce.ets)
- [完整应用示例](assets/example_complete.ets)

## 测试用例

### 正向测试用例
- [基本播报功能测试](tests/test_basic_announce.py)：验证文本播报功能正常
- [Resource播报测试](tests/test_resource_announce.py)：验证Resource类型播报功能
- [Promise方式测试](tests/test_promise_announce.py)：验证Promise调用方式

### 边界测试用例
- [空内容测试](tests/test_empty_content.py)：验证空内容的处理
- [长文本测试](tests/test_long_text.py)：验证长文本播报
- [高频播报测试](tests/test_high_frequency.py)：验证高频播报的处理

### 异常测试用例
- [参数错误测试](tests/test_invalid_params.py)：验证错误参数的处理
- [Resource不存在测试](tests/test_missing_resource.py)：验证Resource资源缺失的降级处理
- [屏幕朗读未开启测试](tests/test_screen_reader_off.py)：验证无障碍服务未开启的情况