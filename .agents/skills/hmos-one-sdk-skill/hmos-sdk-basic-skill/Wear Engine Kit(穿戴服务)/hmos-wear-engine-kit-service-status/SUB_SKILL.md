---
name: hmos-wear-engine-kit-service-status
description: 管理应用与Wear Engine服务的连接状态,支持订阅监听服务断联事件、取消监听、主动断开连接,适用于手机侧应用与穿戴服务交互场景
---

# 管理应用与Wear Engine服务的连接状态技能

## 功能描述

本技能提供Wear Engine服务连接状态管理功能,包括:
- 监测应用与Wear Engine服务的连接状态
- 订阅监听服务端断联事件(serviceDie事件)
- 取消订阅服务端断联事件
- 主动断开应用与Wear Engine服务的连接并释放资源

适用于手机侧应用与穿戴设备服务交互的场景,帮助开发者及时感知服务状态变化并做出相应处理。

## 使用场景

### 触发词
- "监测Wear Engine服务连接状态"
- "订阅服务断联事件"
- "监听serviceDie事件"
- "取消订阅服务断联"
- "断开Wear Engine服务连接"
- "销毁Wear Engine通道"

### 能做
- 订阅监听Wear Engine服务端消亡事件,感知服务异常断开
- 取消已订阅的服务端消亡事件监听
- 主动断开与Wear Engine服务的连接,释放资源
- 处理服务断开后的清理工作

### 绝不做
- 不直接调用穿戴设备侧的接口
- 不处理设备连接状态(使用MonitorClient处理设备连接状态)
- 不替代应用生命周期管理
- 不处理权限申请相关逻辑

### 补充
- 服务断开后,监测设备状态、收消息、收文件等功能不可用
- 主动调用任意接口即可重新连接服务
- destroy方法会清理之前注册的回调函数
- 订阅监听时回调函数的生命周期需延长至取消监听时

## 调用规范和规则

### 输入约束
- 回调函数必须为有效的函数对象
- 订阅和取消订阅时需传入同一个回调函数对象
- 事件类型固定为'serviceDie'

### 执行约束
- 订阅监听建议在应用启动时完成
- 取消订阅监听建议在应用退出时完成
- destroy方法调用后将释放所有Wear Engine资源
- 同一type上注册的回调函数数量有限制(避免过多注册)

### 内容约束
- 禁止在回调函数中执行耗时操作
- 禁止在回调函数中再次调用destroy方法
- 禁止使用已销毁的客户端对象

### 降级约束
- 服务异常断开时:提示用户服务不可用,引导用户重启应用
- 订阅失败时:记录日志,后续可重新尝试订阅
- destroy失败时:检查错误码,必要时重试

## 调用流程和步骤

### 步骤1:导入必要模块

**导入模块**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2:订阅监听服务断联事件

**示例代码**:
```typescript
// 定义回调函数
let serviceDieCallback = () => {
  console.info(`The service destruction event triggered`);
  // 在这里处理服务断开的逻辑
  // 例如:通知用户、清理资源、重新初始化等
};

// 订阅服务断联事件
try {
  wearEngine.on('serviceDie', serviceDieCallback);
  console.info(`Succeeded in subscribing the service destruction event.`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to subscribe the service destruction event. Code is ${err.code}, message is ${err.message}`);
}
```

### 步骤3:取消订阅监听服务断联事件

**示例代码**:
```typescript
// 取消订阅时需传入订阅时的同一个回调函数对象
try {
  wearEngine.off('serviceDie', serviceDieCallback);
  console.info(`Succeeded in unsubscribing the service destruction event.`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to unsubscribe the service destruction event. Code is ${err.code}, message is ${err.message}`);
}
```

### 步骤4:主动断开与Wear Engine服务的连接

**示例代码**:
```typescript
wearEngine.destroy().then(() => {
  console.info(`Succeeded in destroying wear engine channel`);
  // 清理应用中的相关状态
}).catch((error: BusinessError) => {
  console.error(`Failed to destroy wear engine channel. Code is ${error.code}, message is ${error.message}`);
});
```

### 步骤5:错误处理

**错误处理代码**:
```typescript
// 统一的错误处理函数
function handleWearEngineError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error: invalid callback or event type');
      break;
    case 1008500012:
      console.error('Too many callbacks of the same type registered');
      // 建议:取消不必要的订阅后重新尝试
      break;
    case 1008509999:
      console.error('Internal error occurred');
      // 建议:检查配置或联系华为支持
      break;
    default:
      console.error(`Unknown error: ${error.code}, ${error.message}`);
  }
}
```

### 步骤6:降级处理

**降级处理代码**:
```typescript
// 服务断开后的降级处理
function handleServiceDied(): void {
  // 1. 清理应用状态
  clearAppState();
  
  // 2. 通知用户
  showUserMessage('Wear Engine服务已断开,部分功能不可用');
  
  // 3. 尝试重新连接(通过调用任意接口自动重连)
  reconnectService();
}

async function reconnectService(): Promise<void> {
  try {
    // 通过调用任意接口触发自动重连
    let deviceClient = wearEngine.getDeviceClient(getContext());
    let devices = await deviceClient.getConnectedDevices();
    console.info('Service reconnected successfully');
  } catch (error) {
    console.error('Failed to reconnect service');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因:必选参数未传入、参数类型错误 | 检查回调函数是否有效、事件类型是否为'serviceDie' |
| 1008500012 | 同一type注册的回调函数过多 | 取消不必要的订阅监听,释放回调函数资源 |
| 1008509999 | Wear Engine内部错误 | 检查应用配置是否正确,必要时联系华为技术支持 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "5.0.0(12)",
    "@kit.BasicServicesKit": "5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS版本:5.0.0(12)及以上
- 设备类型:Phone、Tablet
- 系统能力:SystemCapability.Health.WearEngine
- 模型约束:仅支持Stage模型

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**:确保HarmonyOS SDK版本>=5.0.0(12),检查项目配置

**问题2:类型定义错误**
```
Error: Property 'on' does not exist on type 'wearEngine'
```
**解决方法**:检查导入语句是否正确,确保使用最新的API定义

**问题3:回调函数类型不匹配**
```
Error: Argument of type 'xxx' is not assignable to parameter of type 'Callback<void>'
```
**解决方法**:确保回调函数无参数且返回void

## 常见问题与解决方法

### Q1:订阅监听后没有收到回调
**原因**:
- 服务未正常断开
- 回调函数对象不正确
- 应用生命周期管理不当

**解决方法**:
- 确认回调函数对象生命周期正确
- 检查华为运动健康App是否正常运行
- 在destroy前先取消订阅

### Q2:取消订阅失败
**原因**:
- 传入的回调函数与订阅时不是同一个对象
- 事件类型错误

**解决方法**:
- 使用同一个回调函数对象
- 确认事件类型为'serviceDie'

### Q3:destroy后无法重新连接
**原因**:
- 未正确初始化服务
- 网络或权限问题

**解决方法**:
- 调用任意Wear Engine接口会自动触发重连
- 检查网络连接和权限配置

### Q4:回调函数过多错误(1008500012)
**原因**:
- 多次订阅同一事件但未及时取消

**解决方法**:
- 及时取消不再使用的监听
- 在组件销毁时取消订阅
- 避免重复订阅

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "service_status_management",
  "subscriptionActive": true,
  "callbacksRegistered": 1,
  "serviceConnected": true,
  "apiUsed": [
    "wearEngine.on",
    "wearEngine.off",
    "wearEngine.destroy"
  ]
}
```

## 参考文档

- [API开发指南](references/wearengine_service_status.md)
- [API参考说明](references/wearengine_api.md)
- [错误码说明](references/wearengine_api_error_code.md)

## 完整示例代码

- [ArkTS示例](assets/example_service_status.ets)

## 测试用例

### 正向测试用例
- [订阅服务断联事件](tests/test_positive.ts):测试正常订阅和取消订阅流程
- [主动断开连接](tests/test_positive.ts):测试正常destroy流程

### 边界测试用例
- [多次订阅取消](tests/test_boundary.ts):测试多次订阅和取消的场景
- [空回调函数取消](tests/test_boundary.ts):测试不传callback参数取消所有订阅

### 异常测试用例
- [无效回调函数](tests/test_exception.ts):测试传入无效回调函数的错误处理
- [重复订阅](tests/test_exception.ts):测试重复订阅的错误处理