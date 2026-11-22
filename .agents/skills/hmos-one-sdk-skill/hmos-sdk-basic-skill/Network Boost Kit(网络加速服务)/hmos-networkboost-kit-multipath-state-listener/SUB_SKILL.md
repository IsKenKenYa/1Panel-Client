---
name: hmos-networkboost-kit-multipath-state-listener
description: 监听多网状态变化事件，获取多网链路状态、类型、变化原因等信息，需要LINKTURBO权限，适用于多网并发场景，API版本6.0.0(20)及以上
---

# 多网状态监听技能

## 功能描述

本技能实现多网状态变化的监听功能，通过订阅`multiPathStateChange`事件，实时感知多网链路的状态变化，包括链路建立、释放、挂起等状态，以及链路类型、变化原因等详细信息。应用可以根据这些状态信息调整多网传输策略，实现智能化的网络管理。

## 使用场景

### 触发词
- "监听多网状态"
- "多网状态变化"
- "MultiPath状态监听"
- "Network Boost 多网监听"
- "多网并发状态"

### 能做
- 订阅多网状态变化事件，实时获取多网链路状态信息
- 监听多网链路的建立、释放、挂起、恢复等状态变化
- 获取多网链路类型（WiFi/蜂窝）和NetHandle信息
- 获取多网状态变化原因（正常请求/释放、网络原因、功耗原因、流量不足等）
- 在应用退出或业务结束时取消订阅，释放资源

### 绝不做
- 不处理单网场景的网络状态监听
- 不提供主动发起多网请求的功能（需使用requestMultiPath）
- 不提供主动释放多网的功能（需使用releaseMultiPath）
- 不处理连接迁移事件（需使用handoverChange）
- 不提供多网配额查询功能（需使用getMultiPathQuotaStats）

### 补充
- 需要申请`ohos.permission.LINKTURBO`权限
- API起始版本：6.0.0(20)
- 系统能力：SystemCapability.Communication.NetworkBoost.Core
- 订阅回调会在多网状态变化时触发，应用需处理异步回调

## 调用规范和规则

### 输入约束
- 权限要求：应用必须申请`ohos.permission.LINKTURBO`权限
- API版本：设备API版本不低于6.0.0(20)
- 系统能力：设备需支持SystemCapability.Communication.NetworkBoost.Core
- 订阅次数：无明确限制，但建议应用只订阅一次，避免重复订阅

### 执行约束
- 回调函数执行时间：建议不超过100ms，避免阻塞主线程
- 状态变化监听：实时监听，无调用频次限制
- 取消订阅：建议在应用退出或业务结束时调用off方法

### 内容约束
- 禁止在回调函数中执行耗时操作（如网络请求、文件IO）
- 禁止在回调函数中修改UI（应使用事件通知机制）
- 禁止在未取消订阅的情况下销毁应用组件
- 建议在回调中记录日志，便于问题排查

### 降级约束
- 权限不足：提示用户授权，或使用单网模式降级
- 设备不支持：提示用户设备不支持多网功能，使用单网模式
- 回调异常：捕获异常并记录日志，不影响主业务流程

## 调用流程和步骤

### 步骤1：权限申请和导入模块

**权限配置**：
在`module.json5`文件中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "$string:linkturbo_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**导入模块**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：订阅多网状态变化

**示例代码**：
```typescript
// 定义回调函数处理多网状态变化
const multiPathStateCallback = (data: netHandover.MultiPathStateInfo) => {
  console.info(`[MultiPathState] State: ${data.multiPathState}, Cause: ${data.cause}`);
  console.info(`[MultiPathState] NetHandle: ${data.netHandle.netId}`);
  console.info(`[MultiPathState] PathState: ${data.pathState}, PathType: ${data.pathType}`);
  
  // 根据多网状态执行业务逻辑
  switch (data.multiPathState) {
    case netHandover.MultiPathState.MULTIPATH_IDLE:
      console.info('[MultiPathState] 多网处于空闲状态');
      break;
    case netHandover.MultiPathState.MULTIPATH_CREATING:
      console.info('[MultiPathState] 多网正在建立中');
      break;
    case netHandover.MultiPathState.MULTIPATH_CREATED:
      console.info('[MultiPathState] 多网已建立，可以使用多网传输数据');
      break;
    case netHandover.MultiPathState.MULTIPATH_RELEASING:
      console.info('[MultiPathState] 多网正在释放中');
      break;
    default:
      console.warn('[MultiPathState] 未知状态');
  }
  
  // 根据状态变化原因执行业务逻辑
  switch (data.cause) {
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_REQUEST_NORMAL:
      console.info('[MultiPathState] 正常发起多网请求');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NORMAL:
      console.info('[MultiPathState] 正常释放多网请求');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
      console.warn('[MultiPathState] 网络原因释放多网');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA:
      console.warn('[MultiPathState] 配额耗尽释放多网');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION:
      console.warn('[MultiPathState] 功耗原因释放多网');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER:
      console.warn('[MultiPathState] 多网进入挂起状态，无法传输数据');
      break;
    case netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE:
      console.info('[MultiPathState] 多网退出挂起状态，可以恢复数据传输');
      break;
    default:
      console.info(`[MultiPathState] 状态变化原因: ${data.cause}`);
  }
};

// 订阅多网状态变化
try {
  netHandover.on('multiPathStateChange', multiPathStateCallback);
  console.info('[MultiPathState] 订阅多网状态变化成功');
} catch (err) {
  const error = err as BusinessError;
  console.error(`[MultiPathState] 订阅失败: code=${error.code}, message=${error.message}`);
  // 处理订阅失败的情况
  handleSubscribeError(error);
}
```

### 步骤3：错误处理

**错误处理代码**：
```typescript
function handleSubscribeError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('[MultiPathState] 权限校验失败，请检查是否申请了ohos.permission.LINKTURBO权限');
      break;
    case 1013600001:
      console.error('[MultiPathState] 内部处理异常，请稍后重试');
      break;
    case 1013600002:
      console.error('[MultiPathState] 系统处理异常，请检查网络管理服务是否正常');
      break;
    default:
      console.error(`[MultiPathState] 订阅失败，未知错误: code=${error.code}`);
  }
}
```

### 步骤4：取消订阅

**取消订阅代码**：
```typescript
// 在应用退出或业务结束时取消订阅
try {
  netHandover.off('multiPathStateChange', multiPathStateCallback);
  console.info('[MultiPathState] 取消订阅多网状态变化成功');
} catch (err) {
  const error = err as BusinessError;
  console.error(`[MultiPathState] 取消订阅失败: code=${error.code}, message=${error.message}`);
}

// 或者取消所有订阅
try {
  netHandover.off('multiPathStateChange');
  console.info('[MultiPathState] 取消所有订阅成功');
} catch (err) {
  const error = err as BusinessError;
  console.error(`[MultiPathState] 取消所有订阅失败: code=${error.code}, message=${error.message}`);
}
```

### 步骤5：降级处理

**降级处理代码**：
```typescript
// 多网功能降级方案
class MultiPathManager {
  private isMultiPathSupported: boolean = true;
  private stateCallback: ((data: netHandover.MultiPathStateInfo) => void) | null = null;
  
  async initialize(): Promise<void> {
    try {
      // 尝试订阅多网状态
      this.stateCallback = (data: netHandover.MultiPathStateInfo) => {
        this.handleMultiPathState(data);
      };
      netHandover.on('multiPathStateChange', this.stateCallback);
      console.info('[MultiPathManager] 多网监听初始化成功');
    } catch (error) {
      this.isMultiPathSupported = false;
      console.warn('[MultiPathManager] 多网监听初始化失败，降级为单网模式');
      // 降级为单网模式
      this.fallbackToSinglePath();
    }
  }
  
  private handleMultiPathState(data: netHandover.MultiPathStateInfo): void {
    // 业务处理逻辑
  }
  
  private fallbackToSinglePath(): void {
    console.info('[MultiPathManager] 使用单网模式');
    // 单网模式的业务逻辑
  }
  
  async destroy(): Promise<void> {
    if (this.stateCallback && this.isMultiPathSupported) {
      try {
        netHandover.off('multiPathStateChange', this.stateCallback);
        console.info('[MultiPathManager] 清理多网监听成功');
      } catch (error) {
        console.error('[MultiPathManager] 清理多网监听失败', error);
      }
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败，未申请`ohos.permission.LINKTURBO`权限 | 在`module.json5`中添加权限声明，并引导用户授权 |
| 401 | 参数检查失败，传入的回调函数无效 | 确保传入的回调函数类型正确，不是null或undefined |
| 801 | 设备不支持该API | 提示用户设备不支持多网功能，降级为单网模式 |
| 1013600001 | 内部处理异常，内部管理状态机异常或消息队列处理阻塞 | 记录日志，稍后重试，或重启应用 |
| 1013600002 | 系统处理异常，IPC跨进程调用失败或网络管理服务启动失败 | 检查系统服务状态，重启设备或联系系统管理员 |

## 编译和修复问题

### 依赖声明
在`oh-package.json5`文件中添加依赖：
```json
{
  "dependencies": {
    "@kit.NetworkBoostKit": "^6.0.0",
    "@kit.BasicServicesKit": "^6.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：API版本不低于6.0.0(20)
- DevEco Studio：版本不低于4.0
- 开发语言：ArkTS

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit' or its corresponding type declarations.
```
**解决方法**：检查`oh-package.json5`中的依赖配置，确保已安装最新版本的HarmonyOS SDK。

**问题2：权限声明无效**
```
Error: Permission denied: ohos.permission.LINKTURBO
```
**解决方法**：在`module.json5`中正确配置权限声明，并确保用户已授权。

**问题3：类型定义错误**
```
Error: Property 'MultiPathStateInfo' does not exist on type 'typeof netHandover'.
```
**解决方法**：检查API版本，确保设备API版本不低于6.0.0(20)。

## 常见问题与解决方法

### Q1：订阅后没有收到回调
**原因**：可能设备不支持多网功能，或多网未被激活
**解决方法**：
- 检查设备API版本是否不低于6.0.0(20)
- 检查设备是否支持多网功能（WiFi+蜂窝双网环境）
- 确认已申请`ohos.permission.LINKTURBO`权限
- 确认已调用`requestMultiPath`发起多网请求

### Q2：取消订阅失败
**原因**：传入的回调函数与订阅时不一致
**解决方法**：
- 确保取消订阅时传入的回调函数是同一个引用
- 如果不传回调函数参数，则取消所有订阅
- 建议在订阅时保存回调函数的引用

### Q3：多网状态异常
**原因**：网络环境变化、配额耗尽、功耗限制等
**解决方法**：
- 根据回调的`cause`字段判断具体原因
- 对于配额耗尽，提示用户或使用单网模式
- 对于功耗限制，优化应用功耗或等待系统恢复
- 记录详细日志，便于问题排查

### Q4：权限申请失败
**原因**：用户拒绝授权或系统版本不支持
**解决方法**：
- 引导用户在设置中手动授权
- 提供降级方案，使用单网模式
- 说明多网功能的优势，提高用户授权意愿

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "subscribed": true,
  "eventName": "multiPathStateChange",
  "callbackRegistered": true,
  "apiUsed": [
    "netHandover.on('multiPathStateChange', callback)",
    "netHandover.off('multiPathStateChange', callback)"
  ],
  "permission": "ohos.permission.LINKTURBO",
  "apiVersion": "6.0.0(20)"
}
```

## 参考文档

- [API开发指南：多网状态监听](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-statechangecallback)
- [API参考说明：netHandover](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)

## 完整示例代码

- [ArkTS示例：多网状态监听](assets/multipath_state_listener.ets)
- [完整应用示例](assets/multipath_manager_example.ets)

## 测试用例

### 正向测试用例
- [订阅多网状态成功](tests/test_positive.py)：测试正常订阅流程，验证回调函数注册成功
- [接收多网状态变化](tests/test_positive.py)：测试接收多网状态变化回调，验证数据正确性
- [取消订阅成功](tests/test_positive.py)：测试取消订阅流程，验证资源释放成功

### 边界测试用例
- [多网状态为空闲](tests/test_boundary.py)：测试多网处于空闲状态的回调处理
- [多网状态为挂起](tests/test_boundary.py)：测试多网进入和退出挂起状态的回调处理
- [配额耗尽场景](tests/test_boundary.py)：测试配额耗尽导致多网释放的场景

### 异常测试用例
- [权限不足](tests/test_exception.py)：测试未申请权限时的订阅失败处理
- [设备不支持](tests/test_exception.py)：测试设备API版本不支持时的降级处理
- [回调函数无效](tests/test_exception.py)：测试传入无效回调函数时的错误处理