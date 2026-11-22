---
name: hmos-accessibility-kit-eldercare-mode-status
description: 获取系统关怀模式状态，支持查询和监听两种方式，API版本26.0.0+，适用于应用长辈关怀功能体验场景
---

# 获取关怀模式状态技能

## 功能描述

本技能提供获取和监听系统关怀模式状态的能力，让应用能够跟随系统关怀模式变化，为长辈用户提供更清晰、更易操控的界面体验。从API版本26.0.0开始支持两种获取方式：

1. **查询方式**：应用启动时，通过`isSeniorModeEnabled()`接口查询系统设置中的关怀模式开关状态
2. **监听方式**：应用运行期间，通过`onSeniorModeStateChange()`接口监听系统关怀模式开关状态变化

## 使用场景

### 触发词
- "获取关怀模式状态"
- "查询长辈模式"
- "监听关怀模式变化"
- "应用长辈关怀"
- "关怀模式开关"

### 能做
- 查询系统关怀模式的当前开关状态
- 监听系统关怀模式状态变化事件
- 取消关怀模式状态变化监听
- 根据关怀模式状态调整应用界面展示
- 让应用内关怀模式跟随系统关怀模式变化

### 绝不做
- 不直接修改系统关怀模式设置
- 不处理超出Accessibility Kit范围的请求
- 不替代系统无障碍服务功能

### 补充
- 该功能从API版本26.0.0开始支持
- 需导入@kit.AccessibilityKit模块
- 应用需具备无障碍相关权限
- 监听回调需在组件生命周期内正确注册和注销

## 调用规范和规则

### 输入约束
- 无需输入文件或复杂参数
- 回调函数需符合`Callback<boolean>`类型定义
- 监听注册和注销需使用相同的回调函数引用

### 执行约束
- 查询接口为异步调用，需使用Promise处理结果
- 监听注册需在组件`aboutToAppear`生命周期中完成
- 监听注销需在组件`aboutToDisappear`生命周期中完成
- 避免重复注册监听事件

### 内容约束
- 禁止生成虚假API调用代码
- 禁止使用未定义的API方法
- 必须导入正确的模块：`@kit.AccessibilityKit`
- 必须导入错误处理模块：`@kit.BasicServicesKit`

### 降级约束
- API调用失败：捕获错误并提供友好提示
- 监听注册失败：记录错误日志并降级为查询方式
- 设备不支持：提示用户升级系统版本至API 26.0.0+

## 调用流程和步骤

### 步骤1：导入必要模块

**导入声明**：
```typescript
import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：查询系统关怀模式状态

**场景说明**：应用启动时查询当前关怀模式状态

**示例代码**：
```typescript
@Entry
@Component
struct SeniorModeQueryDemo {
  aboutToAppear(): void {
    accessibility.isSeniorModeEnabled().then((data: boolean) => {
      console.info(`success data:isSeniorModeEnabled : ${JSON.stringify(data)}`);
      if (data) {
        console.info('系统关怀模式已开启，应用应跟随开启关怀模式');
      } else {
        console.info('系统关怀模式未开启，应用应跟随关闭关怀模式');
      }
    }).catch((err: BusinessError) => {
      console.error(`failed to call isSeniorModeEnabled, Code is ${err.code}, message is ${err.message}`);
    });
  }
  
  build() {
    Column() {
      Text('关怀模式状态查询示例')
    }
  }
}
```

### 步骤3：监听系统关怀模式状态变化

**场景说明**：应用运行期间监听关怀模式状态变化

**示例代码**：
```typescript
@Entry
@Component
struct SeniorModeListenerDemo {
  callBack = (data: boolean) => {
    console.info(`subscribe senior mode state change, result: ${JSON.stringify(data)}`);
    if (data) {
      console.info('监听到系统关怀模式已打开');
    } else {
      console.info('监听到系统关怀模式已关闭');
    }
  }
  
  aboutToAppear(): void {
    accessibility.onSeniorModeStateChange(this.callBack);
  }
  
  aboutToDisappear(): void {
    accessibility.offSeniorModeStateChange(this.callBack);
  }
  
  build() {
    Column() {
      Text('关怀模式状态监听示例')
    }
  }
}
```

### 步骤4：错误处理

**错误处理代码**：
```typescript
async function querySeniorModeStatus(): Promise<boolean> {
  try {
    const isEnabled = await accessibility.isSeniorModeEnabled();
    console.info(`关怀模式状态查询成功: ${isEnabled}`);
    return isEnabled;
  } catch (error) {
    const err = error as BusinessError;
    console.error(`查询失败: 错误码 ${err.code}, 错误信息 ${err.message}`);
    switch (err.code) {
      case 401:
        console.error('参数错误，请检查参数类型和取值范围');
        break;
      default:
        console.error('未知错误，请联系技术支持');
    }
    return false;
  }
}
```

### 步骤5：降级处理

**降级处理代码**：
```typescript
class SeniorModeManager {
  private isListening = false;
  private callBack: (data: boolean) => void;
  
  constructor() {
    this.callBack = (data: boolean) => {
      this.handleModeChange(data);
    };
  }
  
  async initialize(): Promise<void> {
    try {
      accessibility.onSeniorModeStateChange(this.callBack);
      this.isListening = true;
      console.info('关怀模式监听注册成功');
    } catch (error) {
      console.warn('监听注册失败，降级为定时查询方式');
      this.isListening = false;
      this.startPeriodicQuery();
    }
  }
  
  private startPeriodicQuery(): void {
    setInterval(async () => {
      try {
        const isEnabled = await accessibility.isSeniorModeEnabled();
        this.handleModeChange(isEnabled);
      } catch (error) {
        console.error('定时查询失败');
      }
    }, 5000);
  }
  
  private handleModeChange(isEnabled: boolean): void {
    console.info(`关怀模式状态更新: ${isEnabled}`);
  }
  
  cleanup(): void {
    if (this.isListening) {
      accessibility.offSeniorModeStateChange(this.callBack);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误、参数校验失败 | 检查参数类型是否正确，确保回调函数符合Callback<boolean>类型定义 |
| 9300003 | 不具备执行该操作的无障碍权限 | 向用户提示请求无障碍辅助操作权限，重新启用无障碍扩展应用 |
| 9300006 | 目标应用和无障碍服务建立连接失败 | 延后调用此方法，等待应用完成向无障碍框架服务注册 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccessibilityKit": "API 26.0.0+",
    "@kit.BasicServicesKit": "API 7+"
  }
}
```

### 环境要求
- HarmonyOS API版本：26.0.0及以上
- DevEco Studio版本：建议使用最新版本
- ArkTS语言支持

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.AccessibilityKit' or its corresponding type declarations.
```
**解决方法**：确保项目配置支持API 26.0.0，在build-profile.json5中配置正确的compileSdkVersion

**问题2：API不存在**
```
Property 'isSeniorModeEnabled' does not exist on type 'typeof accessibility'.
```
**解决方法**：该API从API 26.0.0开始支持，请检查项目的API版本配置是否满足要求

**问题3：类型错误**
```
Type 'boolean' is not assignable to type 'Callback<boolean>'.
```
**解决方法**：回调函数需定义为`(data: boolean) => void`类型，而非直接传递boolean值

## 常见问题与解决方法

### Q1：应用启动时如何正确查询关怀模式状态？
**原因**：查询接口为异步调用，需正确处理Promise结果
**解决方法**：
- 使用.then()和.catch()处理Promise结果和错误
- 在aboutToAppear生命周期中调用查询接口
- 根据返回的boolean值调整应用界面

### Q2：监听回调为何没有响应？
**原因**：监听注册可能失败或回调函数引用不一致
**解决方法**：
- 确认注册监听时没有抛出错误
- 注销监听时需使用与注册时相同的回调函数引用
- 检查系统是否支持该功能（API 26.0.0+）

### Q3：如何避免监听事件重复注册？
**原因**：多次调用onSeniorModeStateChange注册监听
**解决方法**：
- 使用标志变量记录监听注册状态
- 在注册前检查是否已注册
- 避免在组件渲染过程中注册监听

### Q4：设备不支持API 26.0.0如何处理？
**原因**：设备系统版本低于API 26.0.0
**解决方法**：
- 检测设备API版本，低于26.0.0时提示用户升级
- 提供降级方案，使用其他方式实现类似功能
- 在应用文档中明确最低系统版本要求

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "seniorModeEnabled": true,
  "listeningRegistered": true,
  "apiUsed": [
    "accessibility.isSeniorModeEnabled()",
    "accessibility.onSeniorModeStateChange()",
    "accessibility.offSeniorModeStateChange()"
  ],
  "message": "关怀模式状态获取成功，监听已注册"
}
```

## 参考文档

- [API开发指南 - 获取关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description)
- [API参考说明 - @ohos.accessibility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)
- [错误码说明 - 无障碍子系统错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-accessibility)

## 完整示例代码

- [ArkTS查询示例](assets/senior_mode_query_example.ets)
- [ArkTS监听示例](assets/senior_mode_listener_example.ets)
- [综合管理示例](assets/senior_mode_manager.ets)

## 测试用例

### 正向测试用例
- [查询关怀模式状态](tests/test_query_positive.ets)：测试正常查询关怀模式开关状态
- [监听关怀模式变化](tests/test_listener_positive.ets)：测试监听关怀模式状态变化事件

### 边界测试用例
- [快速切换关怀模式](tests/test_fast_switch_boundary.ets)：测试快速切换关怀模式状态的监听响应
- [并发查询和监听](tests/test_concurrent_boundary.ets)：测试同时查询和监听的场景

### 异常测试用例
- [监听注册失败](tests/test_register_failure_exception.ets)：测试监听注册失败时的降级处理
- [API版本不支持](tests/test_api_version_exception.ets)：测试API版本低于26.0.0时的处理