---
name: hmos-accessibility-kit-dynamic-content-announcement
description: 主动播报界面内容动态变化，支持文本和Resource类型播报内容，适用于内容更新通知、状态变化提示、重要信息告知场景
---

# 内容动态变化主动播报技能

## 功能描述

本技能提供界面内容动态变化后的主动播报能力。当界面上重要内容发生动态变化且对用户具有必要的提示/告知/指导作用时，调用无障碍API主动播报变化内容，使屏幕朗读等辅助应用能够及时向用户传达信息更新。

**核心功能**：
- 主动播报文本内容变化
- 支持Resource类型播报内容
- 异步发送无障碍事件
- 支持自定义播报内容

**技术特点**：
- 使用accessibility.sendAccessibilityEvent API
- EventInfo对象配置播报参数
- Promise/Callback两种调用模式
- API version 9+ 支持

## 使用场景

### 触发词
- "内容变化播报"
- "动态内容通知"
- "主动播报"
- "无障碍播报"
- "屏幕朗读通知"
- "announceForAccessibility"

### 能做
- 在内容动态变化后主动发送播报事件
- 支持文本和Resource两种播报内容格式
- 提供Promise和Callback两种异步调用方式
- 配置EventInfo对象的播报参数

### 绝不做
- 不用于静态内容的朗读（应使用accessibilityText属性）
- 不用于组件焦点管理（应使用requestFocusForAccessibility事件）
- 不替代系统自动的文本更新通知（textUpdate事件）
- 不处理无障碍服务的查询和监听

### 补充
- 适用于界面上重要内容动态变化的场景
- 播报内容应简洁明了，避免过于冗长
- 需确保屏幕朗读等辅助应用已启用
- API调用可能失败，需要错误处理

## 调用规范和规则

### 输入约束
- 播报内容长度：建议不超过100字符，避免过长影响用户体验
- bundleName：必须为当前应用包名
- type：必须为'announceForAccessibility'或'announceForAccessibilityNotInterrupt'
- triggerAction：通常设置为'common'
- EventInfo对象必须包含必需参数

### 执行约束
- API调用模式：异步调用（Promise或Callback）
- 调用时机：内容变化后立即调用
- 最大调用频次：避免短时间内频繁调用，建议间隔大于500ms
- 错误处理：必须捕获错误并提供降级方案

### 内容约束
- 禁止播报敏感信息（密码、隐私数据等）
- 播报内容必须清晰明确，避免模糊描述
- 禁止在无屏幕朗读环境下强制调用
- 禁止播报过于频繁导致用户体验下降

### 降级约束
- API调用失败：记录日志并提示用户手动刷新
- 屏幕朗读未开启：跳过播报或使用其他通知方式（Toast提示）
- 参数错误：校验参数并提示开发者修正
- 系统异常：延迟重试或降级为UI提示

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查屏幕朗读是否已开启（可选）
2. 确认内容变化对用户具有必要的提示作用
3. 准备播报内容文本或Resource对象

**参数准备**：
```arkts
import { accessibility } from '@kit.AccessibilityKit';

const eventInfo: accessibility.EventInfo = {
  type: 'announceForAccessibility', // 主动播报事件类型
  bundleName: 'com.example.myapp', // 当前应用包名
  triggerAction: 'common', // 触发动作
  textAnnouncedForAccessibility: '内容已更新', // 播报文本内容
};
```

### 步骤2：调用API

**Promise方式示例代码**：
```arkts
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function announceContentChange(message: string): Promise<void> {
  const eventInfo: accessibility.EventInfo = {
    type: 'announceForAccessibility',
    bundleName: 'com.example.myapp',
    triggerAction: 'common',
    textAnnouncedForAccessibility: message,
  };

  try {
    await accessibility.sendAccessibilityEvent(eventInfo);
    console.info(`播报成功: ${message}`);
  } catch (error) {
    const err = error as BusinessError;
    console.error(`播报失败: Code=${err.code}, Message=${err.message}`);
    throw err;
  }
}

// 调用示例
announceContentChange('新消息已到达').catch((err) => {
  console.error('播报降级处理:', err);
});
```

**Callback方式示例代码**：
```arkts
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

function announceContentChangeCallback(message: string): void {
  const eventInfo: accessibility.EventInfo = {
    type: 'announceForAccessibility',
    bundleName: 'com.example.myapp',
    triggerAction: 'common',
    textAnnouncedForAccessibility: message,
  };

  accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
    if (err) {
      console.error(`播报失败: Code=${err.code}, Message=${err.message}`);
      return;
    }
    console.info(`播报成功: ${message}`);
  });
}

// 调用示例
announceContentChangeCallback('订单状态已更新');
```

**Resource类型播报示例**：
```arkts
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const eventInfo: accessibility.EventInfo = {
  type: 'announceForAccessibility',
  bundleName: 'com.example.myapp',
  triggerAction: 'common',
  textResourceAnnouncedForAccessibility: $r('app.string.update_message'),
};

accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
  if (err) {
    console.error(`播报失败: Code=${err.code}, Message=${err.message}`);
    return;
  }
  console.info('Resource播报成功');
});
```

### 步骤3：错误处理

```arkts
import { BusinessError } from '@kit.BasicServicesKit';

try {
  await accessibility.sendAccessibilityEvent(eventInfo);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('参数错误：缺少必需参数或参数类型不正确');
      break;
    default:
      console.error(`未知错误: Code=${err.code}, Message=${err.message}`);
  }
}
```

### 步骤4：降级处理

```arkts
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function announceWithFallback(message: string): Promise<void> {
  try {
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.myapp',
      triggerAction: 'common',
      textAnnouncedForAccessibility: message,
    };

    await accessibility.sendAccessibilityEvent(eventInfo);
    console.info('播报成功');
  } catch (error) {
    const err = error as BusinessError;
    console.warn(`播报失败，降级为Toast提示: ${err.message}`);

    try {
      // 降级方案：使用Toast提示
      promptAction.showToast({
        message: message,
        duration: 2000,
      });
    } catch (toastError) {
      console.error('降级方案失败:', toastError);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必需参数未指定、参数类型不正确、参数验证失败 | 检查EventInfo对象的必需字段是否正确配置 |
| 其他 | 系统内部错误 | 查看日志信息，必要时重试或降级处理 |

**常见参数错误场景**：
- type字段未指定或类型错误
- bundleName字段为空或不匹配
- triggerAction字段未指定
- textAnnouncedForAccessibility字段为空

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "API version 9+",
    "@kit.BasicServicesKit": "API version 9+"
  }
}
```

### 环境要求
- HarmonyOS API version: 9+
- DevEco Studio: 3.1+
- 屏幕朗读服务: 需已安装并启用

### 常见编译问题

**问题1：导入错误**
```
Cannot find module '@kit.AccessibilityKit' or its corresponding type declarations.
```
**解决方法**：确保项目API version >= 9，并在module.json5中配置正确的依赖。

**问题2：类型错误**
```
Type 'EventInfo' is not assignable to parameter of type 'EventInfo'.
```
**解决方法**：检查EventInfo对象的所有必需字段是否正确配置，确保类型匹配。

**问题3：运行时错误**
```
Error code: 401, Parameter error.
```
**解决方法**：校验所有必需参数，确保bundleName为当前应用包名，type为正确的EventType值。

## 常见问题与解决方法

### Q1：播报内容没有被朗读
**原因**：屏幕朗读服务未开启或参数配置错误
**解决方法**：
- 使用accessibility.isOpenAccessibilitySync()检查辅助应用是否开启
- 使用accessibility.isScreenReaderOpenSync()检查屏幕朗读是否开启
- 确认EventInfo参数配置正确

### Q2：播报内容过长，用户体验差
**原因**：播报内容超过最佳长度范围
**解决方法**：
- 限制播报内容长度在100字符以内
- 提取关键信息，简洁表达
- 使用Resource类型管理播报文本，便于国际化

### Q3：频繁播报导致朗读混乱
**原因**：短时间内多次调用播报API
**解决方法**：
- 控制播报频率，间隔大于500ms
- 使用'announceForAccessibilityNotInterrupt'事件类型避免打断
- 合理安排播报时机，避免冲突

### Q4：API调用失败
**原因**：参数错误或系统异常
**解决方法**：
- 校验EventInfo对象的必需字段
- 检查bundleName是否为当前应用包名
- 添加错误处理和降级方案

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "播报内容": "内容已更新",
  "事件类型": "announceForAccessibility",
  "调用方式": "Promise",
  "apiUsed": [
    "accessibility.sendAccessibilityEvent",
    "accessibility.EventInfo"
  ],
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-dynamic-content-change)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)

## 完整示例代码

- [ArkTS完整示例](assets/dynamic_content_announcement.ets)
- [Resource播报示例](assets/resource_announcement.ets)

## 测试用例

### 正向测试用例
- [文本播报测试](tests/test_text_announcement.ts)：验证文本内容播报功能
- [Resource播报测试](tests/test_resource_announcement.ts)：验证Resource类型播报功能
- [Promise调用测试](tests/test_promise_call.ts)：验证Promise方式调用

### 边界测试用例
- [空内容测试](tests/test_empty_content.ts)：验证空播报内容的处理
- [长内容测试](tests/test_long_content.ts)：验证长播报内容的处理
- [高频调用测试](tests/test_high_frequency.ts)：验证高频调用的限制

### 异常测试用例
- [参数错误测试](tests/test_invalid_params.ts)：验证错误参数的处理
- [无屏幕朗读测试](tests/test_no_screen_reader.ts)：验证无辅助应用环境的降级
- [系统异常测试](tests/test_system_error.ts)：验证系统异常的错误处理