---
name: hmos-networkboost-kit-multipath-recommendation
description: 监听系统多网建议变化，支持订阅和取消订阅多网建议事件，需要LINKTURBO权限，适用于弱网、网络切换等多网络加速场景
---

# 多网建议监听技能

## 功能描述

本技能提供监听系统多网建议变化的能力，帮助应用在弱网、网络切换等特定场景下获得系统建议，决策是否发起多网络加速请求。通过订阅多网建议信息，应用可以及时响应系统推荐，提升用户体验。

**核心能力**：
- 订阅系统多网建议信息变化
- 取消订阅多网建议信息变化
- 获取多网推荐动作（建议发起或释放多网请求）

**适用场景**：
- 弱网环境下的网络加速
- 网络切换场景（WiFi↔蜂窝）
- 需要多网络并发的业务场景

## 使用场景

### 触发词
- "监听多网建议"
- "订阅多网建议"
- "多网络加速建议"
- "弱网多网建议"
- "网络切换建议"

### 能做
- 订阅系统多网建议变化事件
- 获取系统推荐的多网动作（发起或释放多网请求）
- 取消订阅多网建议事件
- 在弱网或网络切换场景获得系统优化建议

### 绝不做
- 不主动发起多网请求（仅监听建议）
- 不处理连接迁移逻辑（由其他技能处理）
- 不执行网络重建操作
- 不管理多网配额

### 补充
- 需要申请 `ohos.permission.LINKTURBO` 权限
- 需要 API 版本 6.0.0(20) 及以上
- 系统能力要求：SystemCapability.Communication.NetworkBoost.Core
- 建议与其他多网技能配合使用（如多网请求、多网状态监听）

## 调用规范和规则

### 输入约束
- 回调函数类型：必须为 `Callback<MultiPathRecommendationInfo>`
- 订阅事件类型：固定字符串 `'multiPathRecommendation'`
- 取消订阅时回调参数可选，不传则取消所有订阅

### 执行约束
- 最大耗时：API调用为同步操作，立即返回
- 最大迭代次数：无迭代限制
- API调用频次：无明确限制，但建议避免频繁订阅/取消订阅

### 内容约束
- 禁止生成：无权限检查的代码
- 禁止使用高危函数：无
- 禁止操作：禁止在回调函数中执行耗时操作

### 降级约束
- 权限不足：提示用户申请 `ohos.permission.LINKTURBO` 权限
- API不支持：提示设备或系统版本不支持，建议降级使用其他网络方案
- 内部异常：记录错误日志，不影响应用主流程

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备API版本是否 >= 6.0.0(20)
2. 确认已申请 `ohos.permission.LINKTURBO` 权限
3. 确认已导入必要的模块

**参数准备**：
```typescript
// 导入必要模块
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义回调函数
const recommendationCallback = (data: netHandover.MultiPathRecommendationInfo) => {
  console.info("Received multiPath recommendation: " + JSON.stringify(data));
};
```

### 步骤2：订阅多网建议

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 订阅多网建议信息
function subscribeMultiPathRecommendation(): void {
  try {
    netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
      // 处理多网建议
      console.info("on multiPathRecommendation: " + JSON.stringify(data));
      
      // 根据建议动作执行相应操作
      if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
        console.info("System recommends to request multi-path connection");
        // 建议发起多网请求
      } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
        console.info("System recommends to release multi-path connection");
        // 建议释放多网请求
      }
    });
    console.info('Successfully subscribed to multiPathRecommendation');
  } catch (err) {
    const error = err as BusinessError;
    console.error('Failed to subscribe: errCode: ' + error.code + ', errMessage: ' + error.message);
    throw error;
  }
}
```

### 步骤3：取消订阅多网建议

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消订阅多网建议信息
function unsubscribeMultiPathRecommendation(): void {
  try {
    netHandover.off('multiPathRecommendation');
    console.info('Successfully unsubscribed from multiPathRecommendation');
  } catch (err) {
    const error = err as BusinessError;
    console.error('Failed to unsubscribe: errCode: ' + error.code + ', errMessage: ' + error.message);
    throw error;
  }
}

// 取消特定回调函数的订阅
function unsubscribeSpecificCallback(callback: (data: netHandover.MultiPathRecommendationInfo) => void): void {
  try {
    netHandover.off('multiPathRecommendation', callback);
    console.info('Successfully unsubscribed specific callback');
  } catch (err) {
    const error = err as BusinessError;
    console.error('Failed to unsubscribe: errCode: ' + error.code + ', errMessage: ' + error.message);
    throw error;
  }
}
```

### 步骤4：错误处理

```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

function handleMultiPathRecommendationError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('Permission denied: LINKTURBO permission is required');
      // 提示用户申请权限
      break;
    case 401:
      console.error('Parameter check failed: Invalid parameters');
      // 检查参数类型和格式
      break;
    case 801:
      console.error('API not supported: Device or system version does not support this API');
      // 提示用户升级系统或使用其他方案
      break;
    case 1013600001:
      console.error('Internal error: Internal processing exception');
      // 记录错误日志，稍后重试
      break;
    case 1013600002:
      console.error('System error: IPC call failed or network service not started');
      // 检查网络服务状态
      break;
    default:
      console.error('Unknown error: ' + error.message);
      // 处理未知错误
  }
}

// 使用示例
try {
  netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
    console.info("Recommendation received: " + JSON.stringify(data));
  });
} catch (err) {
  handleMultiPathRecommendationError(err as BusinessError);
}
```

### 步骤5：降级处理

```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 带降级处理的多网建议监听
function subscribeWithFallback(): void {
  try {
    // 尝试订阅多网建议
    netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
      console.info("MultiPath recommendation: " + JSON.stringify(data));
    });
    console.info('Using multiPath recommendation feature');
  } catch (err) {
    const error = err as BusinessError;
    
    // 降级处理：使用传统网络监听方案
    if (error.code === 801 || error.code === 201) {
      console.warn('MultiPath recommendation not available, using fallback network monitoring');
      // 使用 connection API 监听网络变化
      useFallbackNetworkMonitoring();
    } else {
      // 其他错误，记录日志
      console.error('Failed to subscribe multiPath recommendation: ' + error.message);
      throw error;
    }
  }
}

// 降级方案：使用传统网络监听
function useFallbackNetworkMonitoring(): void {
  // 使用 connection API 实现网络监听
  console.info('Fallback: Using connection API for network monitoring');
  // 具体实现参考 connection API
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败，缺少 `ohos.permission.LINKTURBO` 权限 | 在 module.json5 中申请 `ohos.permission.LINKTURBO` 权限 |
| 401 | 参数检查失败，参数类型或格式错误 | 检查回调函数类型是否为 `Callback<MultiPathRecommendationInfo>` |
| 801 | 设备不支持该API，系统版本过低 | 检查系统版本是否 >= 6.0.0(20)，提供降级方案 |
| 1013600001 | 内部处理异常，如状态机异常、消息队列阻塞 | 记录错误日志，稍后重试 |
| 1013600002 | 系统处理异常，如IPC调用失败、网络服务未启动 | 检查网络服务状态，重启应用 |

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "abilities": [
      {
        "name": "MainAbility",
        "srcEntry": "./ets/MainAbility/MainAbility.ts"
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "用于监听系统多网建议变化，提升网络体验"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK：API Version 6.0.0(20) 及以上
- 开发工具：DevEco Studio 4.0 及以上
- 系统能力：SystemCapability.Communication.NetworkBoost.Core

### 常见编译问题

**问题1：权限未声明**
```
Error: Permission denied: ohos.permission.LINKTURBO
```
**解决方法**：在 `module.json5` 文件的 `requestPermissions` 字段中添加 `ohos.permission.LINKTURBO` 权限声明。

**问题2：API版本不支持**
```
Error: API version 6.0.0(20) or higher is required
```
**解决方法**：
- 检查 `build-profile.json5` 中的 `compatibleSdkVersion` 是否 >= 20
- 在代码中添加API版本检查：
```typescript
if (canIUse('SystemCapability.Communication.NetworkBoost.Core')) {
  // 支持多网建议功能
} else {
  // 使用降级方案
}
```

**问题3：模块导入失败**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：确保项目依赖了 NetworkBoostKit，检查 `oh-package.json5` 中是否声明了相关依赖。

## 常见问题与解决方法

### Q1：订阅后没有收到多网建议回调
**原因**：系统未检测到弱网或网络切换场景，或多网功能未使能。
**解决方法**：
- 确认设备处于弱网环境或进行网络切换测试
- 检查多网功能是否开启
- 使用 `netHandover.getMultiPathQuotaStats()` 检查配额状态
- 确认应用未被系统限制多网功能

### Q2：取消订阅时失败
**原因**：传入的回调函数与订阅时不一致，或已经取消过订阅。
**解决方法**：
- 如果指定回调函数，确保与订阅时传入的是同一个函数引用
- 如果不传回调函数参数，将取消所有订阅
- 检查是否已经取消过订阅，避免重复取消

### Q3：收到 MULTIPATH_ACTION_REQUEST 建议，但请求多网失败
**原因**：多网配额已用尽、功耗限制或场景冲突。
**解决方法**：
- 使用 `netHandover.getMultiPathQuotaStats()` 检查剩余配额
- 检查设备功耗状态
- 确认没有其他应用正在使用多网功能
- 查看 `requestMultiPath` 返回的错误码了解具体原因

### Q4：在后台是否能收到多网建议？
**原因**：应用在后台时，系统可能限制多网建议的推送。
**解决方法**：
- 应用进入后台前取消订阅，回到前台后重新订阅
- 使用长时任务或后台任务保持应用活跃
- 考虑使用系统网络状态变化通知作为补充

### Q5：多网建议的触发条件是什么？
**原因**：系统根据网络质量、场景等因素综合判断。
**解决方法**：
- 系统在检测到弱网、网络切换、高时延等场景时会提供建议
- 建议的触发是系统自动判断，应用无需主动触发
- 不同设备和系统版本的判断策略可能有所差异

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "subscribed": true,
  "event": "multiPathRecommendation",
  "apiUsed": [
    "netHandover.on('multiPathRecommendation')",
    "netHandover.off('multiPathRecommendation')"
  ],
  "permission": "ohos.permission.LINKTURBO",
  "minApiVersion": "6.0.0(20)"
}
```

## 参考文档

- [API开发指南：多网建议监听](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-recommendcallback)
- [API参考说明：netHandover](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)

## 完整示例代码

- [ArkTS示例：订阅多网建议](assets/subscribe_multipath_recommendation.ets)
- [ArkTS示例：处理多网建议](assets/handle_multipath_recommendation.ets)
- [配置文件示例：权限声明](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试：成功订阅多网建议](tests/test_subscribe_positive.ets)：正常订阅多网建议事件
- [测试：成功取消订阅](tests/test_unsubscribe_positive.ets)：正常取消订阅多网建议事件
- [测试：接收多网建议回调](tests/test_receive_recommendation.ets)：验证能正确接收多网建议回调

### 边界测试用例
- [测试：取消所有订阅](tests/test_unsubscribe_all.ets)：不传回调参数，取消所有订阅
- [测试：取消特定订阅](tests/test_unsubscribe_specific.ets)：传入回调函数，取消特定订阅
- [测试：多次订阅](tests/test_multiple_subscribe.ets)：验证多次订阅的行为

### 异常测试用例
- [测试：权限不足](tests/test_no_permission.ets)：未申请权限时的错误处理
- [测试：API版本不支持](tests/test_api_not_supported.ets)：低版本设备的降级处理
- [测试：参数错误](tests/test_invalid_parameter.ets)：传入错误参数的错误处理