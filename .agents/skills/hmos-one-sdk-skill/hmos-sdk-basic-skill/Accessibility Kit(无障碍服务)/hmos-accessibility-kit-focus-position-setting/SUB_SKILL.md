---
name: hmos-accessibility-kit-focus-position-setting
description: 主动设置无障碍焦点位置，支持组件消失后重新定位焦点，通过sendAccessibilityEvent发送requestFocusForAccessibility事件实现主动聚焦，最大支持单次聚焦一个组件，适用于无障碍服务、屏幕朗读场景
---

# 重新设置新焦点位置技能

## 功能描述

本技能实现HarmonyOS应用中主动设置无障碍焦点位置的功能。当当前焦点所在的控件消失或隐藏后，通过调用`accessibility.sendAccessibilityEvent`接口发送主动聚焦事件，重新设置新的焦点位置。新焦点通常设置在原控件位置的下一个控件上，避免焦点跳变到前面的控件。

**核心能力**：
- 发送主动聚焦事件(requestFocusForAccessibility)
- 精准定位目标组件(通过customId指定组件ID)
- 异步回调处理结果(Promise/AsyncCallback双模式)

**技术特点**：
- 基于Accessibility Kit无障碍服务Kit
- 支持ArkTS语言开发
- 需API version 9及以上版本
- 异步非阻塞调用模式

## 使用场景

### 触发词
- "重新设置焦点位置"
- "主动聚焦"
- "焦点重新定位"
- "组件消失后设置焦点"
- "无障碍焦点管理"
- "accessibility焦点"
- "requestFocusForAccessibility"

### 能做
- 当组件消失或隐藏后，主动设置新的焦点位置
- 通过组件ID精准定位需要聚焦的组件
- 处理焦点跳转逻辑，避免焦点反向跳变
- 异步发送无障碍事件并处理回调结果
- 集成到无障碍服务应用中，提升屏幕朗读体验

### 绝不做
- 不处理组件显示/隐藏的触发逻辑(需配合组件生命周期)
- 不自动选择焦点目标组件(需由开发者明确指定)
- 不处理焦点移动的动画效果(仅负责事件发送)
- 不替代组件的accessibility属性配置(如accessibilityText)
- 不处理无障碍服务未启用的情况(需先检查isOpenAccessibility)

### 补充
- 目标组件必须设置唯一的id属性，id的唯一性由开发者保证
- 需先导入AccessibilityKit: `import { accessibility } from '@kit.AccessibilityKit'`
- 支持Promise和AsyncCallback两种异步调用模式
- 焦点设置成功后会触发屏幕朗读播报目标组件的accessibilityText

## 调用规范和规则

### 输入约束
- **EventInfo参数**：
  - type: 必填，固定为'requestFocusForAccessibility'
  - bundleName: 必填，当前应用包名(可通过context获取)
  - triggerAction: 必填，固定为'common'(主动聚焦场景)
  - customId: 必填，目标组件的id属性值，字符串类型
- **组件ID约束**：
  - 目标组件必须已设置id属性
  - id值必须唯一，避免重复
  - id值建议使用有意义的命名(如'button1', 'submitBtn')
- **调用时机**：
  - 在组件消失/隐藏事件触发后立即调用
  - 确保目标组件已渲染完成且可访问

### 执行约束
- **异步模式**：推荐使用Promise模式，便于链式调用
- **错误处理**：必须捕获错误码401(参数错误)
- **调用频率**：避免短时间内频繁调用，建议间隔至少100ms
- **最大耗时**：单次调用耗时不超过1秒

### 内容约束
- **禁止伪造参数**：必须使用真实的bundleName和组件id
- **禁止空值调用**：customId不能为空字符串或null
- **禁止跨应用调用**：bundleName必须是当前应用包名，不能调用其他应用组件

### 降级约束
- **无障碍服务未启用**：提示用户开启无障碍服务，不执行聚焦
- **组件id不存在**：记录错误日志，不抛出异常，保持应用稳定运行
- **参数校验失败**：返回错误码401，提示开发者检查参数
- **网络/系统异常**：捕获异常，记录日志，不阻塞主线程

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查无障碍服务是否启用(可选，推荐)
   ```typescript
   let status: boolean = accessibility.isOpenAccessibilitySync();
   if (!status) {
     console.info('screen reader not enable.');
     return;
   }
   ```
2. 确认目标组件已设置id属性
3. 准备EventInfo参数对象

**参数准备**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

const eventInfo: accessibility.EventInfo = ({
  type: 'requestFocusForAccessibility',
  bundleName: 'com.example.myapplication',
  triggerAction: 'common',
  customId: 'button2'
});
```

### 步骤2：调用API(Promise模式)

**示例代码**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function setFocusPosition(customId: string): Promise<void> {
  const eventInfo: accessibility.EventInfo = ({
    type: 'requestFocusForAccessibility',
    bundleName: 'com.example.myapplication',
    triggerAction: 'common',
    customId: customId
  });
  
  try {
    await accessibility.sendAccessibilityEvent(eventInfo);
    console.info(`Succeeded in send event, eventInfo is: ${JSON.stringify(eventInfo)}`);
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to send event, Code is ${err.code}, message is ${err.message}`);
    throw error;
  }
}
```

### 步骤3：调用API(AsyncCallback模式)

**示例代码**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

function setFocusPositionWithCallback(customId: string): void {
  const eventInfo: accessibility.EventInfo = ({
    type: 'requestFocusForAccessibility',
    bundleName: 'com.example.myapplication',
    triggerAction: 'common',
    customId: customId
  });
  
  accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
    if (err) {
      console.error(`Failed to send event, Code is ${err.code}, message is ${err.message}`);
      return;
    }
    console.info(`Succeeded in send event, eventInfo is: ${JSON.stringify(eventInfo)}`);
  });
}
```

### 步骤4：错误处理

```typescript
try {
  await setFocusPosition('button2');
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types; 3. Parameter verification failed.');
      break;
    default:
      console.error(`Unknown error: ${err.message}`);
  }
}
```

### 步骤5：集成到组件生命周期

**完整组件示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct FocusPositionExample {
  eventInfo: accessibility.EventInfo = ({
    type: 'requestFocusForAccessibility',
    bundleName: 'com.example.myapplication',
    triggerAction: 'common',
    customId: 'button1'
  });
  
  build() {
    Column() {
      Button('button1')
        .id('button1')
        .accessibilityText('第一个按钮')
        .onClick(() => {
          this.eventInfo.customId = 'button2';
          accessibility.sendAccessibilityEvent(this.eventInfo).then(() => {
            console.info(`Succeeded in send event, eventInfo is: ${JSON.stringify(this.eventInfo)}`);
          }).catch((err: BusinessError) => {
            console.error(`Failed to send event, Code is ${err.code}, message is ${err.message}`);
          });
        })
      
      Button('button2')
        .id('button2')
        .accessibilityText('第二个按钮')
        .onClick(() => {
          this.eventInfo.customId = 'button1';
          accessibility.sendAccessibilityEvent(this.eventInfo).then(() => {
            console.info(`Succeeded in send event, eventInfo is: ${JSON.stringify(this.eventInfo)}`);
          }).catch((err: BusinessError) => {
            console.error(`Failed to send event, Code is ${err.code}, message is ${err.message}`);
          });
        })
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型错误；3. 参数校验失败 | 检查EventInfo对象的所有必填参数：type、bundleName、triggerAction、customId是否正确设置 |
| - | 组件id不存在 | 确认目标组件已设置id属性且id值与customId一致 |
| - | bundleName不匹配 | 使用当前应用的包名，可通过context.applicationInfo.name获取 |

## 编译和修复问题

### 依赖声明
```json
{
  "app": {
    "products": [
      {
        "buildMode": "debug"
      }
    ]
  },
  "modules": {
    "entry": {
      "target": "default",
      "type": "feature",
      "dependencies": []
    }
  }
}
```

**导入模块**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 环境要求
- HarmonyOS SDK: API version 9及以上
- DevEco Studio: 3.1及以上版本
- 目标设备: 支持无障碍服务的HarmonyOS设备

### 常见编译问题

**问题1：模块导入错误**
```
Error: Cannot find module '@kit.AccessibilityKit'
```
**解决方法**：检查build-profile.json5中的API版本配置，确保API version >= 9

**问题2：EventInfo类型错误**
```
Error: Type 'Object' is not assignable to type 'EventInfo'
```
**解决方法**：使用正确的EventInfo构造方式，参考步骤1中的示例代码

**问题3：组件id未设置**
```
运行时错误：Failed to send event
```
**解决方法**：为目标组件添加`.id('uniqueId')`属性

## 常见问题与解决方法

### Q1：调用后焦点没有变化
**原因**：
- 无障碍服务未启用
- 组件id不存在或不匹配
- 目标组件未设置accessibilityText

**解决方法**：
- 检查无障碍服务状态：`accessibility.isOpenAccessibilitySync()`
- 确认组件id和customId一致
- 为目标组件添加`.accessibilityText('描述文本')`属性

### Q2：如何获取当前应用包名
**原因**：bundleName参数需要填写当前应用包名

**解决方法**：
```typescript
import { common } from '@kit.AbilityKit';

const context = getContext(this) as common.UIAbilityContext;
const bundleName = context.applicationInfo.name;
```

### Q3：能否同时设置多个组件焦点
**原因**：sendAccessibilityEvent一次只能聚焦一个组件

**解决方法**：
- 不支持批量聚焦，需逐个调用
- 如需焦点轮转，建议使用定时器间隔调用

### Q4：如何在组件消失后自动设置焦点
**原因**：需要配合组件生命周期触发

**解决方法**：
```typescript
@Component
struct MyComponent {
  @State isVisible: boolean = true;
  
  aboutToDisappear() {
    if (!this.isVisible) {
      setFocusPosition('nextComponent');
    }
  }
  
  build() {
    if (this.isVisible) {
      Button('即将消失的按钮')
        .onClick(() => {
          this.isVisible = false;
          setFocusPosition('nextButton');
        })
    }
  }
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "eventType": "requestFocusForAccessibility",
  "targetComponent": "button2",
  "bundleName": "com.example.myapplication",
  "timestamp": "2026-07-01T23:37:00Z",
  "apiUsed": [
    "accessibility.sendAccessibilityEvent",
    "accessibility.EventInfo"
  ]
}
```

## 参考文档

- [API开发指南 - 重新设置新焦点位置的场景](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-focus-position-setting)
- [API参考说明 - @ohos.accessibility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)

## 完整示例代码

- [ArkTS示例 - 焦点位置设置](assets/focus-position-example.ets)

## 测试用例

### 正向测试用例
- [组件消失后成功设置焦点](tests/test_positive.ets)：验证组件隐藏后能成功聚焦到下一个组件
- [焦点循环跳转](tests/test_positive.ets)：验证两个组件间焦点循环跳转功能

### 边界测试用例
- [快速连续调用](tests/test_boundary.ets)：验证短时间内多次调用的事件处理
- [自定义id长度限制](tests/test_boundary.ets)：测试超长customId字符串的处理

### 异常测试用例
- [组件id不存在](tests/test_exception.ets)：验证customId指向不存在组件时的错误处理
- [空参数调用](tests/test_exception.ets)：测试EventInfo缺少必填参数时的错误码
- [bundleName错误](tests/test_exception.ets)：验证使用错误bundleName时的错误处理