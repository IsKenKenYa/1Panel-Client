---
name: hmos-accessibility-kit-proactively-notify-page-changes
description: 主动通知页面变化以通知屏幕朗读聚焦新页面，支持指定根节点或从窗口根节点聚焦，适用于自定义页面堆叠覆盖导致焦点丢失的场景
---

# 主动通知页面变化技能

## 功能描述

本技能实现HarmonyOS应用主动通知页面变化的功能，通过调用无障碍辅助功能API发送pageActive事件，通知屏幕朗读服务在新页面上寻找节点聚焦。支持指定自定义页面根节点ID进行精准聚焦，若未指定则默认从当前窗口根节点开始寻找首焦点。

**核心能力**：
- 发送页面激活事件（pageActive）
- 支持指定自定义根节点ID进行精准聚焦
- 自动从窗口根节点寻找首焦点
- 配合accessibilityLevel属性优化无障碍体验

**适用范围**：HarmonyOS应用开发，ArkTS语言，API version 9及以上

**限制条件**：需导入@kit.AccessibilityKit模块，需正确设置EventInfo参数

**典型场景**：自定义页面堆叠覆盖、Z序切换导致的焦点丢失、多页面切换场景

## 使用场景

### 触发词
- "主动通知页面变化"
- "页面变化通知屏幕朗读"
- "自定义页面切换焦点丢失"
- "发送pageActive事件"
- "无障碍页面聚焦"
- "Stack组件页面切换"

### 能做
- 在自定义页面堆叠切换时主动通知屏幕朗读服务
- 指定新页面的根节点ID进行精准聚焦
- 处理Z序切换导致的焦点丢失问题
- 配合accessibilityLevel属性控制节点无障碍可见性
- 实现完整的页面切换无障碍体验优化流程

### 绝不做
- 不处理普通页面路由场景（系统自动处理）
- 不用于非页面切换的焦点管理
- 不替代系统无障碍服务的自动聚焦机制
- 不处理非堆叠式页面切换场景

### 补充
- 仅适用于自定义实现的页面切换效果（如Stack Z序切换）
- 需配合组件的id属性和accessibilityLevel属性使用
- 建议在页面切换完成后立即调用
- customId参数应与组件id属性值一致

## 调用规范和规则

### 输入约束
- bundleName：必须是有效的应用包名，格式为字符串
- customId：可选，若提供需与目标组件id属性值一致，格式为字符串
- type：必须为'pageActive'
- triggerAction：必须为'common'

### 执行约束
- API调用时机：页面切换完成后立即调用
- 最大耗时：异步调用，Promise模式返回
- 推荐调用频次：每次页面切换时调用一次
- 必须在UI组件渲染完成后调用

### 内容约束
- 禁止使用错误的事件类型（type必须为'pageActive'）
- 禁止使用错误的Action类型（triggerAction必须为'common'）
- 禁止在页面未切换时调用
- customId必须指向有效的组件节点

### 降级约束
- API调用失败：记录错误日志，不影响页面切换功能
- 组件节点不存在：屏幕朗读从窗口根节点开始寻找焦点
- 无障碍服务未启用：事件发送成功但无实际效果，不影响应用功能

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已导入@kit.AccessibilityKit模块
2. 确认目标组件已设置唯一的id属性
3. 确认页面切换逻辑已实现（如Z序切换）
4. 确认无障碍服务可能已启用（可选）

**参数准备**：
```typescript
// 定义状态变量控制页面显示
@State topLayer: number = 0;

// 定义EventInfo参数
const eventInfo: accessibility.EventInfo = {
  type: 'pageActive',
  bundleName: 'com.example.yourapp',  // 替换为实际应用包名
  triggerAction: 'common',
  customId: `Layer_${this.topLayer}`  // 与目标组件id一致
};
```

### 步骤2：实现页面切换和事件发送

**完整示例代码**：
```typescript
import { accessibility } from '@kit.AccessibilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@Entry
@Component
export struct ProactivelyNotifyPageChanges {
  // 定义状态变量，控制顶层显示的页面
  @State topLayer: number = 0;
  
  // 定义自定义页面Builder
  @Builder
  Layer(text: string, index: number) {
    Column() {
      Column() {
        Text(text)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        Text(`${text} 测试节点1`)
        Text(`${text} 测试节点2`)
        Text(`${text} 测试节点3`)
        
        // 创建页面切换按钮
        Button(`页面切换${index}`)
          .onClick(() => {
            // 切换顶层页面
            if (this.topLayer === 0) {
              this.topLayer = 1;
            } else {
              this.topLayer = 0;
            }
            
            // 定义事件信息
            const eventInfo: accessibility.EventInfo = {
              type: 'pageActive',
              bundleName: 'com.example.yourapp',  // 替换为实际包名
              triggerAction: 'common',
              customId: `Layer_${this.topLayer}`
            };
            
            // 发送主动通知页面变化的事件
            accessibility.sendAccessibilityEvent(eventInfo).then(() => {
              console.info(`pageActive event send Successed, customId=Layer_${this.topLayer}.`);
            }).catch((err: BusinessError) => {
              console.error(`Failed to send pageActive event, Code: ${err.code}, Message: ${err.message}`);
            });
          })
      }
      // 设置组件id，用于标识页面根节点
      .id('Layer_' + index)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(index === 0 ? Color.Red : Color.Green)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(16)
    .padding(20)
    // 控制页面Z序，实现切换效果
    .zIndex(this.topLayer === index ? 1 : 0)
    // 根据是否顶层显示设置无障碍可见性
    .accessibilityLevel(this.topLayer === index ? 'no' : 'no-hide-descendants')
  }
  
  build() {
    NavDestination() {
      Column() {
        Stack() {
          this.Layer('页面0', 0)
          this.Layer('页面1', 1)
        }
      }
    }
  }
}
```

### 步骤3：错误处理

```typescript
// 使用Promise模式的错误处理
accessibility.sendAccessibilityEvent(eventInfo).then(() => {
  console.info('Page change notification sent successfully.');
}).catch((err: BusinessError) => {
  console.error(`Failed to send event, Code: ${err.code}, Message: ${err.message}`);
  // 根据错误码进行处理
  switch (err.code) {
    case 401:
      console.error('Parameter error. Check EventInfo parameters.');
      break;
    case 9300003:
      console.error('No accessibility permission to perform the operation.');
      break;
    default:
      console.error('Unknown error occurred.');
  }
});

// 使用Callback模式的错误处理
accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
  if (err) {
    console.error(`Failed to send event, Code: ${err.code}, Message: ${err.message}`);
    return;
  }
  console.info('Page change notification sent successfully.');
});
```

### 步骤4：降级处理

```typescript
// 降级处理：即使事件发送失败，页面切换功能仍正常工作
Button('页面切换')
  .onClick(() => {
    // 执行页面切换逻辑
    this.topLayer = this.topLayer === 0 ? 1 : 0;
    
    // 尝试发送无障碍事件（可选功能）
    try {
      const eventInfo: accessibility.EventInfo = {
        type: 'pageActive',
        bundleName: 'com.example.yourapp',
        triggerAction: 'common',
        customId: `Layer_${this.topLayer}`
      };
      
      accessibility.sendAccessibilityEvent(eventInfo).then(() => {
        console.info('Accessibility event sent successfully.');
      }).catch((err: BusinessError) => {
        // 降级：记录错误但不影响页面切换
        console.warn(`Accessibility event failed: ${err.message}`);
      });
    } catch (error) {
      // 异常捕获：确保应用不会崩溃
      console.warn('Accessibility event sending encountered an error.');
    }
  })
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。必填参数未指定、参数类型错误或参数校验失败 | 检查EventInfo对象的所有必填参数：type、bundleName、triggerAction |
| 9300003 | 不具备执行该操作的无障碍权限 | 提示用户授权无障碍辅助操作权限，重新启用无障碍扩展应用 |
| 9300004 | 属性不存在 | 检查customId是否指向有效的组件节点 |
| 9300005 | 不支持该操作 | 确认使用正确的EventType和Action类型 |
| 9300006 | 目标应用和无障碍服务建立连接失败 | 延后调用此方法，等待应用完成向无障碍框架服务注册 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "系统Kit，无需声明版本"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 9及以上
- DevEco Studio：3.0及以上版本
- ArkTS语言支持

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.AccessibilityKit' or its corresponding type declarations.
```
**解决方法**：确保DevEco Studio版本支持系统Kit导入，检查SDK版本是否为API 9+

**问题2：EventInfo类型错误**
```
Type 'EventInfo' is not defined.
```
**解决方法**：确保使用`accessibility.EventInfo`完整类型名称，或导入完整模块

**问题3：组件id属性未设置**
```
customId对应的组件不存在
```
**解决方法**：确保目标组件设置了`.id('Layer_' + index)`属性，且值与customId一致

## 常见问题与解决方法

### Q1：发送事件后屏幕朗读没有聚焦到新页面
**原因**：无障碍服务未启用或customId指向的组件不可见
**解决方法**：
- 检查屏幕朗读服务是否开启
- 确认目标组件的accessibilityLevel属性设置正确（非顶层页面应设为'no-hide-descendants'）
- 确认customId与组件id属性值一致

### Q2：页面切换后焦点仍然在旧页面
**原因**：事件发送时机不当或旧页面节点未隐藏
**解决方法**：
- 确保在Z序切换完成后立即发送事件
- 使用accessibilityLevel隐藏非顶层页面的所有子节点
- 检查事件发送是否成功（通过Promise或Callback）

### Q3：EventInfo参数校验失败
**原因**：必填参数缺失或类型错误
**解决方法**：
- 确认type为字符串'pageActive'
- 确认bundleName为有效应用包名
- 确认triggerAction为'common'
- customId为可选，若提供需为字符串类型

### Q4：多次页面切换后焦点管理混乱
**原因**：未正确管理页面层级的无障碍可见性
**解决方法**：
- 使用accessibilityLevel动态控制节点可见性
- 顶层页面设置为'no'（可识别但子节点不自动隐藏）
- 非顶层页面设置为'no-hide-descendants'（隐藏所有子节点）
- 确保每次切换都发送正确的customId

## 输出结果报告

执行完成后将输出以下信息：

```json
{
  "status": "success",
  "eventType": "pageActive",
  "bundleName": "com.example.yourapp",
  "customId": "Layer_0",
  "message": "Page change notification sent successfully",
  "apiUsed": [
    "accessibility.sendAccessibilityEvent",
    "accessibility.EventInfo"
  ],
  "focusManagement": {
    "topLayer": 0,
    "accessibilityLevel": "no"
  }
}
```

## 参考文档

- [API开发指南 - 主动通知页面变化的场景](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/proactively-notify-page-changes)
- [API参考说明 - @ohos.accessibility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)
- [API参考说明 - Stack组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-stack)
- [错误码说明 - 无障碍子系统错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-accessibility)

## 完整示例代码

- [ArkTS示例 - 页面切换主动通知](assets/proactively_notify_page_changes.ets)
- [配置示例 - accessibilityLevel设置](assets/accessibility_config.json)

## 测试用例

### 正向测试用例
- [测试页面切换成功聚焦](tests/test_page_switch_focus.ets)：验证正常页面切换场景
- [测试指定customId聚焦](tests/test_customid_focus.ets)：验证精准聚焦指定节点
- [测试多次页面切换](tests/test_multiple_switch.ets)：验证连续切换的焦点管理

### 边界测试用例
- [测试customId为空](tests/test_empty_customid.ets)：验证不指定customId时的默认行为
- [测试组件不存在](tests/test_invalid_customid.ets)：验证customId指向不存在组件的处理
- [测试无障碍服务未启用](tests/test_service_disabled.ets)：验证降级处理

### 异常测试用例
- [测试参数错误](tests/test_parameter_error.ets)：验证必填参数缺失的错误处理
- [测试类型错误](tests/test_type_error.ets)：验证错误的EventType和Action类型
- [测试网络异常](tests/test_network_error.ets)：验证API调用失败时的降级方案