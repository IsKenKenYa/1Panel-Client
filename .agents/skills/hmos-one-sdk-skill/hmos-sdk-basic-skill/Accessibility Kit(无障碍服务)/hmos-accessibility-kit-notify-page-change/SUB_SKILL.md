---
name: hmos-accessibility-kit-notify-page-change
description: 主动通知屏幕朗读页面变化，支持指定根节点聚焦，防止自定义页面切换时焦点丢失，适用于堆叠页面、弹窗切换、tab切换等无障碍场景
---

# 主动通知页面变化技能

## 功能描述

本技能用于实现 HarmonyOS 应用中的主动通知页面变化功能，通过调用 `accessibility.sendAccessibilityEvent` API，在自定义页面切换时主动通知屏幕朗读服务，防止焦点丢失。支持指定新页面的根节点，确保屏幕朗读能正确识别并聚焦到新页面的首个可聚焦元素。

**核心能力**：
- 发送 `pageActive` 类型无障碍事件
- 支持指定自定义页面根节点 ID（customId）
- 自动引导屏幕朗读在新页面寻找焦点
- 防止堆叠页面切换导致的焦点丢失问题

## 使用场景

### 触发词
- "页面变化通知"
- "主动通知页面变化"
- "屏幕朗读焦点丢失"
- "自定义页面切换"
- "无障碍页面通知"
- "pageActive事件"
- "防止焦点丢失"

### 能做
- 在自定义页面切换（如堆叠页面、弹窗切换）时主动通知屏幕朗读
- 指定新页面的根节点，引导屏幕朗读从该节点开始聚焦
- 处理多层页面堆叠切换的无障碍焦点问题
- 实现 tab 切换、模态对话框切换的无障碍支持
- 确保屏幕朗读用户能正确感知页面变化

### 绝不做
- 不替代系统默认的页面导航行为
- 不处理正常的路由跳转场景（系统会自动处理）
- 不在非页面切换场景使用（如单纯的数据更新）
- 不修改组件的无障碍属性配置（如 accessibilityLevel）

### 补充
- 仅适用于自定义实现的页面切换效果（如通过 zIndex、visibility 控制页面显示）
- 需配合组件的无障碍属性设置（如 accessibilityLevel）
- 必须提供正确的 bundleName 和 customId 参数
- 建议在页面切换动作完成后立即调用

## 调用规范和规则

### 输入约束
- bundleName：必须为当前应用的包名，格式为 `com.xxx.xxx`
- customId：必须为有效的新页面根节点 ID，对应组件的 `.id()` 属性值
- type：必须为 `'pageActive'`
- triggerAction：推荐使用 `'common'`

### 执行约束
- 调用时机：必须在页面切换完成后立即调用
- 最大耗时：异步调用，无阻塞限制
- 调用频次：每次页面切换调用一次，避免重复调用
- 错误处理：必须捕获并处理 Promise 异常

### 内容约束
- 禁止在正常路由跳转场景使用
- 禁止在不涉及页面切换的场景使用
- 禁止发送非 pageActive 类型事件用于此场景
- customId 必须真实存在，禁止使用虚假 ID

### 降级约束
- API调用失败：记录错误日志，不影响页面切换功能
- 屏幕朗读未开启：API调用仍可执行，但不会产生实际效果
- customId无效：屏幕朗读将从窗口根节点开始寻找焦点

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认页面切换已完成（如 zIndex、visibility 已修改）
2. 确认新页面根节点已设置正确的 `.id()` 属性
3. 确认新页面组件已配置正确的无障碍属性（accessibilityLevel）

**参数准备**：
```typescript
// 定义事件信息
const eventInfo: accessibility.EventInfo = {
  type: 'pageActive',           // 主动通知页面变化事件类型
  bundleName: 'com.example.app', // 当前应用包名
  triggerAction: 'common',      // 触发动作
  customId: 'new_page_root'     // 新页面根节点ID（对应组件.id()值）
};
```

### 步骤2：调用API

**示例代码**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

// 页面切换后主动通知屏幕朗读
async function notifyPageChange(customId: string): Promise<void> {
  try {
    // 定义事件信息
    const eventInfo: accessibility.EventInfo = {
      type: 'pageActive',
      bundleName: 'com.samples.uiextensionandaccessibility',
      triggerAction: 'common',
      customId: customId
    };
    
    // 发送主动通知页面变化的事件
    await accessibility.sendAccessibilityEvent(eventInfo);
    console.info(`pageActive event send succeeded, customId=${customId}`);
  } catch (error) {
    console.error(`failed to send pageActive event: ${error.message}`);
  }
}
```

### 步骤3：错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  await accessibility.sendAccessibilityEvent(eventInfo);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('Parameter error: check bundleName and customId');
      break;
    default:
      console.error(`Unknown error: code=${err.code}, message=${err.message}`);
  }
}
```

### 步骤4：完整实现示例

**堆叠页面切换示例**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';

@Entry
@Component
struct StackPageExample {
  @State topLayer: number = 0;
  
  @Builder
  PageLayer(text: string, index: number) {
    Column() {
      Text(text)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      Button(`切换到页面${index === 0 ? 1 : 0}`)
        .onClick(() => {
          // 切换顶层页面
          this.topLayer = index === 0 ? 1 : 0;
          
          // 主动通知页面变化
          const eventInfo: accessibility.EventInfo = {
            type: 'pageActive',
            bundleName: 'com.example.app',
            triggerAction: 'common',
            customId: `PageLayer_${this.topLayer}`
          };
          
          accessibility.sendAccessibilityEvent(eventInfo).then(() => {
            console.info(`Page change notified: layer=${this.topLayer}`);
          }).catch((err: BusinessError) => {
            console.error(`Failed to notify: ${err.message}`);
          });
        })
    }
    .id(`PageLayer_${index}`)  // 设置根节点ID
    .width('100%')
    .height('100%')
    .zIndex(this.topLayer === index ? 1 : 0)  // 控制页面层级
    .accessibilityLevel(this.topLayer === index ? 'no' : 'no-hide-descendants')
  }
  
  build() {
    Stack() {
      this.PageLayer('页面0', 0)
      this.PageLayer('页面1', 1)
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数缺失、参数类型错误、参数校验失败 | 检查 EventInfo 对象的 type、bundleName、triggerAction、customId 参数 |
| 其他 | 系统内部错误 | 查看错误日志，确认系统状态 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "API 9+"
  }
}
```

### 环境要求
- HarmonyOS API version：9 或更高版本
- 开发环境：DevEco Studio 3.1+
- 系统能力：SystemCapability.BarrierFree.Accessibility.Core

### 常见编译问题

**问题1：导入模块失败**
```
Module '@kit.AccessibilityKit' not found
```
**解决方法**：确保项目 API version >= 9，在 `build-profile.json5` 中配置正确的 compileSdkVersion

**问题2：EventInfo 类型错误**
```
Type 'EventInfo' is not defined
```
**解决方法**：确保正确导入 `import { accessibility } from '@kit.AccessibilityKit'`

**问题3：customId 无效**
```
屏幕朗读未聚焦到指定节点
```
**解决方法**：确认组件的 `.id()` 属性值与 customId 参数一致，且组件已设置无障碍属性

## 常见问题与解决方法

### Q1：页面切换后屏幕朗读没有聚焦到新页面
**原因**：
- customId 参数与组件实际 id 不匹配
- 新页面组件未设置无障碍属性（如 accessibilityLevel）
- 页面切换逻辑存在问题

**解决方法**：
- 确认组件的 `.id(customId)` 值与 EventInfo.customId 一致
- 为新页面组件设置正确的 accessibilityLevel（如 `'no'`）
- 检查页面切换逻辑是否正确执行

### Q2：屏幕朗读聚焦到错误的节点
**原因**：
- customId 指向了非根节点
- 多个组件使用了相同的 ID

**解决方法**：
- customId 应指向新页面的根容器组件
- 确保组件 ID 在页面中唯一

### Q3：调用 API 后没有效果
**原因**：
- 屏幕朗读服务未开启
- bundleName 参数不正确
- API 调用失败但未处理异常

**解决方法**：
- 在设置中开启屏幕朗读功能
- 使用当前应用的实际包名（查看 app.json5 中的 bundleName）
- 添加 Promise 异常捕获和日志输出

### Q4：是否需要在每次页面切换都调用？
**原因**：用户对调用时机有疑问

**解决方法**：
- 仅在自定义实现的页面切换（如堆叠、弹窗）场景调用
- 系统标准的路由跳转无需调用（系统会自动处理）
- 每次实际的页面切换调用一次即可

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "eventSent": true,
  "eventType": "pageActive",
  "customId": "PageLayer_1",
  "bundleName": "com.example.app",
  "message": "页面变化通知已发送，屏幕朗读将在新页面寻找焦点"
}
```

## 参考文档

- [主动通知页面变化开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/proactively-notify-page-changes)
- [@ohos.accessibility API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)

## 完整示例代码

- [ArkTS堆叠页面切换示例](assets/stack_page_change_example.ets)
- [ArkTS弹窗切换示例](assets/dialog_change_example.ets)

## 测试用例

### 正向测试用例
- [页面切换成功通知](tests/test_positive_page_change.ts)：验证堆叠页面切换后正确发送 pageActive 事件
- [指定根节点聚焦](tests/test_positive_custom_id.ts)：验证 customId 参数正确引导屏幕朗读聚焦

### 边界测试用例
- [空 customId 参数](tests/test_boundary_empty_customid.ts)：验证不指定 customId 时从窗口根节点聚焦
- [多次连续切换](tests/test_boundary_multiple_changes.ts)：验证连续多次页面切换的场景

### 异常测试用例
- [无效 bundleName](tests/test_exception_invalid_bundle.ts)：验证 bundleName 参数错误时的错误处理
- [API调用失败](tests/test_exception_api_failed.ts)：验证 sendAccessibilityEvent 调用失败的降级处理
- [屏幕朗读未开启](tests/test_exception_screenreader_off.ts)：验证屏幕朗读关闭时的表现