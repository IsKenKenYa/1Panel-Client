---
name: hmos-networkboost-kit-netmultipath-statechangecallback
description: 监听多网状态变化事件，感知可用网络链路状态和变化原因，支持多网并发场景，适用于网络切换、多网传输优化
---

# 多网状态监听技能

## 功能描述

本技能提供HarmonyOS多网状态监听能力，通过订阅`multiPathStateChange`事件，实时感知多网链路的状态变化、变化原因、链路类型等信息，帮助应用在多网并发场景下优化数据传输策略。支持监听多网的建立、释放、挂起、恢复等状态变化，以及获取链路的NetHandle、路径状态、路径类型等详细信息。

## 使用场景

### 触发词
- "监听多网状态"
- "多网状态变化"
- "多网链路状态"
- "感知网络切换"
- "多网并发监听"
- "NetworkBoost多网监听"

### 能做
- 订阅多网状态变化事件
- 获取多网状态（空闲、建立中、已建立、释放中）
- 获取多网链路状态（空闲、已连接、挂起）
- 获取多网变化原因（正常请求/释放、网络原因、配额耗尽、功耗限制等）
- 获取多网链路的NetHandle和路径类型信息
- 取消订阅多网状态变化事件

### 绝不做
- 不用于监听单一网络状态（应使用Network Kit的connection模块）
- 不用于主动发起多网请求（应使用requestMultiPath接口）
- 不用于主动释放多网（应使用releaseMultiPath接口）
- 不用于监听连接迁移事件（应使用handoverChange事件）
- 不用于获取网络质量信息（应使用netQuality模块）

### 补充
- 需要申请`ohos.permission.LINKTURBO`权限
- 仅支持API version 6.0.0(20)及以上版本
- 回调函数在多网状态变化时被系统调用，应用需要及时处理回调信息
- 在应用退出或业务流程结束时，必须取消订阅以释放资源

## 调用规范和规则

### 输入约束
- 回调函数类型必须为`Callback<MultiPathStateInfo>`
- type参数必须为字符串`'multiPathStateChange'`
- 取消订阅时callback参数可选，不提供则取消所有订阅

### 执行约束
- 最大订阅数量：无限制，但建议不超过10个订阅
- 回调函数执行时间：应控制在100ms内，避免阻塞
- API调用频次：无限制，但建议避免频繁订阅/取消订阅

### 内容约束
- 禁止在回调函数中执行耗时操作（如网络请求、文件IO）
- 禁止在回调函数中修改MultiPathStateInfo对象
- 禁止在回调函数中调用阻塞API
- 回调函数必须处理所有可能的MultiPathState枚举值

### 降级约束
- 权限申请失败：提示用户授予LINKTURBO权限，降级为不监听多网状态
- API不支持：检查API版本，降级为使用单网模式
- 回调函数异常：记录错误日志，继续监听但不处理异常回调
- 系统服务异常：等待系统恢复后重新订阅

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备API版本是否≥6.0.0(20)
2. 检查是否已申请`ohos.permission.LINKTURBO`权限
3. 检查回调函数是否符合`Callback<MultiPathStateInfo>`类型

**参数准备**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

const stateChangeCallback = (data: netHandover.MultiPathStateInfo) => {
  // 回调函数逻辑
};
```

### 步骤2：订阅多网状态变化

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

try {
  netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
    console.info("on multiPathStateChange: " + JSON.stringify(data));
    
    // 处理多网状态变化
    switch (data.multiPathState) {
      case netHandover.MultiPathState.MULTIPATH_IDLE:
        console.info('多网处于空闲状态');
        break;
      case netHandover.MultiPathState.MULTIPATH_CREATING:
        console.info('多网正在建立中');
        break;
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        console.info('多网已建立');
        // 可以开始使用多网链路传输数据
        break;
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        console.info('多网正在释放中');
        break;
    }
    
    // 处理链路状态
    console.info('链路状态: ' + data.pathState);
    console.info('链路类型: ' + data.pathType);
    console.info('变化原因: ' + data.cause);
    console.info('NetHandle: ' + JSON.stringify(data.netHandle));
  });
} catch (err) {
  const error = err as BusinessError;
  console.error('订阅失败 errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

### 步骤3：错误处理

```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

try {
  netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
    console.info("多网状态变化: " + JSON.stringify(data));
  });
} catch (err) {
  const error = err as BusinessError;
  switch (error.code) {
    case 201:
      console.error('权限校验失败，请申请ohos.permission.LINKTURBO权限');
      // 降级处理：提示用户授予权限
      break;
    case 1013600001:
      console.error('内部处理异常，请稍后重试');
      // 降级处理：等待一段时间后重新订阅
      break;
    case 1013600002:
      console.error('系统处理异常，网络管理服务未启动');
      // 降级处理：等待系统恢复后重新订阅
      break;
    default:
      console.error('未知错误: ' + error.message);
      // 降级处理：记录日志，使用单网模式
  }
}
```

### 步骤4：取消订阅

```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

try {
  // 取消所有订阅
  netHandover.off('multiPathStateChange');
  console.info('取消多网状态监听成功');
} catch (err) {
  const error = err as BusinessError;
  console.error('取消订阅失败 errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

### 步骤5：降级处理

```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

let isSubscribed = false;
let retryCount = 0;
const maxRetryCount = 3;

async function subscribeMultiPathState(): Promise<void> {
  try {
    netHandover.on('multiPathStateChange', handleMultiPathStateChange);
    isSubscribed = true;
    console.info('多网状态监听订阅成功');
  } catch (err) {
    const error = err as BusinessError;
    console.error('订阅失败: ' + error.message);
    
    if (retryCount < maxRetryCount) {
      retryCount++;
      console.info('等待5秒后重试，当前重试次数: ' + retryCount);
      await new Promise(resolve => setTimeout(resolve, 5000));
      await subscribeMultiPathState();
    } else {
      console.warn('已达最大重试次数，降级为单网模式');
      // 降级处理：使用单网模式，不监听多网状态
    }
  }
}

function handleMultiPathStateChange(data: netHandover.MultiPathStateInfo): void {
  try {
    console.info('多网状态变化: ' + JSON.stringify(data));
    // 处理状态变化逻辑
  } catch (err) {
    console.error('处理回调异常: ' + (err as Error).message);
    // 不中断监听，继续接收后续回调
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败，未申请ohos.permission.LINKTURBO权限 | 在module.json5中申请权限：`"requestPermissions": [{"name": "ohos.permission.LINKTURBO"}]` |
| 1013600001 | 内部处理异常，如状态机异常、消息队列阻塞等 | 等待一段时间后重新订阅，或重启应用 |
| 1013600002 | 系统处理异常，如IPC调用失败、网络管理服务未启动 | 检查网络管理服务状态，等待系统恢复后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "your_app",
  "version": "1.0.0",
  "dependencies": {},
  "requestPermissions": [
    {
      "name": "ohos.permission.LINKTURBO",
      "reason": "用于监听多网状态变化，优化数据传输策略"
    }
  ]
}
```

### 环境要求
- HarmonyOS API version: ≥6.0.0(20)
- DevEco Studio: ≥5.0.0
- 系统能力: SystemCapability.Communication.NetworkBoost.Core

### 常见编译问题

**问题1：权限未声明**
```
Error: Permission ohos.permission.LINKTURBO is not declared
```
**解决方法**：在`entry/src/main/module.json5`中添加权限声明：
```json
"requestPermissions": [
  {
    "name": "ohos.permission.LINKTURBO",
    "reason": "监听多网状态变化"
  }
]
```

**问题2：API版本不支持**
```
Error: API 'netHandover.on' is not supported on this device
```
**解决方法**：检查设备的API版本，确保≥6.0.0(20)，在代码中添加版本检查：
```typescript
if (canIUse('SystemCapability.Communication.NetworkBoost.Core')) {
  // 使用多网状态监听
} else {
  console.warn('设备不支持多网状态监听，使用单网模式');
}
```

**问题3：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：确保项目依赖正确配置，检查`build-profile.json5`中的API版本配置。

## 常见问题与解决方法

### Q1：回调函数没有被触发
**原因**：
- 未申请权限或权限未授予
- 多网功能未开启或设备不支持
- 未调用requestMultiPath发起多网请求

**解决方法**：
- 检查权限配置和权限授予状态
- 检查设备API版本是否≥6.0.0(20)
- 确认已调用requestMultiPath发起多网请求

### Q2：取消订阅失败
**原因**：
- 订阅时使用的回调函数与取消订阅时提供的回调函数不一致
- 订阅已经被取消

**解决方法**：
- 取消订阅时不提供callback参数，取消所有订阅：`netHandover.off('multiPathStateChange')`
- 保存订阅时的回调函数引用，取消订阅时传入相同的引用

### Q3：收到MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA事件
**原因**：应用的多网配额已耗尽

**解决方法**：
- 调用`netHandover.getMultiPathQuotaStats()`查询配额使用情况
- 合理控制多网使用时长和频率
- 在配额不足时释放多网，避免系统强制释放

### Q4：收到MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER事件
**原因**：多网链路进入挂起状态，无法传输数据

**解决方法**：
- 暂停使用该多网链路传输数据
- 等待MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE事件恢复传输
- 或使用其他可用链路传输数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "subscribed": true,
  "eventName": "multiPathStateChange",
  "permission": "ohos.permission.LINKTURBO",
  "apiUsed": [
    "netHandover.on",
    "netHandover.off"
  ],
  "capability": "SystemCapability.Communication.NetworkBoost.Core",
  "apiVersion": "6.0.0(20)"
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-statechangecallback)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)

## 完整示例代码

- [ArkTS示例](assets/example_multi_path_state_change.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [订阅多网状态监听](tests/test_subscribe_positive.ets)：正常订阅并接收状态变化回调
- [取消订阅成功](tests/test_unsubscribe_positive.ets)：正常取消订阅并验证回调不再触发
- [处理所有状态类型](tests/test_handle_all_states.ets)：验证处理所有MultiPathState枚举值

### 边界测试用例
- [最大订阅数量](tests/test_max_subscriptions.ets)：测试订阅多个回调函数
- [回调函数执行时间](tests/test_callback_duration.ets)：验证回调函数执行时间限制

### 异常测试用例
- [权限未申请](tests/test_permission_missing.ets)：测试未申请权限时的错误处理
- [API版本不支持](tests/test_api_version_unsupported.ets)：测试低版本设备的降级处理
- [系统服务异常](tests/test_system_error.ets)：测试系统异常时的重试和降级