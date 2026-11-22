---
name: hmos-network-boost-kit-netmultipath-recommendcallback
description: 监听系统多网建议信息变化，支持订阅和取消订阅多网推荐事件，根据建议发起或释放多网请求，适用于弱网、网络切换等场景的智能网络加速，需要ohos.permission.LINKTURBO权限，API版本6.0.0(20)+
---

# 多网建议监听技能

## 功能描述

本技能提供多网建议监听功能，用于监听系统多网推荐信息的变化。系统感知到应用可能需要使用多网络加速的场景时（如弱网、网络切换等特定场景），会给出建议。应用通过监听多网络加速的建议，决策发起多网络加速的请求，实现智能的网络加速策略。

**核心能力**：
- 订阅多网建议信息变化事件
- 取消订阅多网建议信息变化事件
- 获取多网推荐动作（建议发起或释放多网请求）

**适用场景**：弱网环境、网络切换、多网并发加速、智能网络优化等场景。

## 使用场景

### 触发词
- "监听多网建议"
- "多网推荐监听"
- "订阅多网建议"
- "多网加速建议"
- "网络加速建议监听"
- "multiPathRecommendation"

### 能做
- 订阅系统多网建议变化事件，获取推荐动作
- 根据系统建议发起多网请求或释放多网请求
- 取消订阅多网建议事件
- 处理多网推荐信息，实现智能网络加速策略

### 绝不做
- 不直接发起多网请求（需要根据建议决策）
- 不处理连接迁移事件（使用其他技能）
- 不处理多网状态变化事件（使用其他技能）
- 不获取配额信息（使用其他技能）

### 补充
- 需要申请 ohos.permission.LINKTURBO 权限
- 仅支持 API 版本 6.0.0(20) 及以上
- 回调函数必须正确处理 MultiPathRecommendationInfo 信息
- 取消订阅时建议传入原始回调函数，避免取消所有回调

## 调用规范和规则

### 输入约束
- 回调函数类型：必须是 Callback<MultiPathRecommendationInfo> 类型
- type参数：固定填写 'multiPathRecommendation' 字符串
- 取消订阅callback参数：可选，建议传入原始回调函数

### 执行约束
- 最大订阅数：无限制，但建议同一应用只订阅一次
- 回调执行时间：应在100ms内完成处理，避免阻塞
- API调用频次：订阅和取消订阅应在业务流程开始和结束时调用，避免频繁调用

### 内容约束
- 禁止在回调中进行耗时操作
- 禁止在回调中直接发起网络请求（应在主线程处理）
- 必须正确处理 MultiPathAction 枚举值
- 必须进行异常捕获和错误处理

### 降级约束
- 权限不足：提示用户申请 ohos.permission.LINKTURBO 权限
- API版本不支持：提示用户升级系统到 API 6.0.0(20) 及以上
- 内部处理异常：记录错误日志，不影响应用主流程
- 系统处理异常：提示用户检查网络管理服务状态

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查 API 版本是否满足 6.0.0(20) 及以上要求
2. 检查是否已申请 ohos.permission.LINKTURBO 权限
3. 检查网络管理服务是否正常运行
4. 确定业务流程需要监听多网建议的时间范围

**参数准备**：
```typescript
// 导入必要模块
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义回调函数
const recommendationCallback = (data: netHandover.MultiPathRecommendationInfo) => {
  // 回调信息处理
  console.info("on multiPathRecommendation: " + JSON.stringify(data));
};
```

### 步骤2：订阅多网建议事件

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 订阅多网建议变化事件
function subscribeMultiPathRecommendation(): void {
  try {
    netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
      // 处理多网推荐信息
      if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
        console.info('System recommends to request multi-path');
        // 建议发起多网请求，应用可根据业务需求决策是否发起
        // 这里可以调用 requestMultiPath 技能发起多网请求
      } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
        console.info('System recommends to release multi-path');
        // 建议释放多网请求，应用可根据业务需求决策是否释放
        // 这里可以调用 releaseMultiPath 技能释放多网请求
      }
    });
    console.info('Successfully subscribed to multiPathRecommendation');
  } catch (err) {
    const error = err as BusinessError;
    console.error('Failed to subscribe: errCode: ' + error.code + ', errMessage: ' + error.message);
    // 错误处理
    handleSubscriptionError(error);
  }
}

// 错误处理函数
function handleSubscriptionError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please apply for ohos.permission.LINKTURBO permission.');
      break;
    case 1013600001:
      console.error('Internal processing exception. Please check system state.');
      break;
    case 1013600002:
      console.error('System processing exception. Please check network management service.');
      break;
    case 801:
      console.error('API not supported on this device. Please upgrade system to API 6.0.0(20)+.');
      break;
    default:
      console.error('Unknown error: ' + error.message);
  }
}
```

### 步骤3：处理多网推荐信息

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';

// 处理多网推荐信息
function handleRecommendationInfo(data: netHandover.MultiPathRecommendationInfo): void {
  // 根据推荐动作进行业务决策
  switch (data.action) {
    case netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST:
      // 系统建议发起多网请求
      console.info('Recommendation: Request multi-path');
      // 应用可根据当前业务场景决定是否发起多网请求
      // 例如：当前有重要数据传输任务，可发起多网请求加速
      decideToRequestMultiPath();
      break;
    case netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE:
      // 系统建议释放多网请求
      console.info('Recommendation: Release multi-path');
      // 应用可根据当前业务场景决定是否释放多网请求
      // 例如：当前网络质量已恢复，可释放多网请求节省资源
      decideToReleaseMultiPath();
      break;
    default:
      console.warn('Unknown recommendation action: ' + data.action);
  }
}

// 业务决策函数（示例）
function decideToRequestMultiPath(): void {
  // 根据业务需求决定是否发起多网请求
  const hasImportantTask = checkImportantDataTransmission();
  if (hasImportantTask) {
    console.info('Decided to request multi-path for important task');
    // 调用 requestMultiPath 技能发起多网请求
    // requestMultiPath();
  } else {
    console.info('Skipped multi-path request due to no important task');
  }
}

function decideToReleaseMultiPath(): void {
  // 根据业务需求决定是否释放多网请求
  const isNetworkQualityGood = checkNetworkQuality();
  if (isNetworkQualityGood) {
    console.info('Decided to release multi-path due to good network quality');
    // 调用 releaseMultiPath 技能释放多网请求
    // releaseMultiPath();
  } else {
    console.info('Kept multi-path due to still poor network quality');
  }
}

// 辅助检查函数（示例）
function checkImportantDataTransmission(): boolean {
  // 检查是否有重要数据传输任务
  // 这里需要根据实际业务逻辑实现
  return false; // 示例返回值
}

function checkNetworkQuality(): boolean {
  // 检查网络质量是否已恢复
  // 这里需要根据实际业务逻辑实现
  return false; // 示例返回值
}
```

### 步骤4：取消订阅多网建议事件

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消订阅多网建议变化事件
function unsubscribeMultiPathRecommendation(): void {
  try {
    // 取消订阅所有回调
    netHandover.off('multiPathRecommendation');
    console.info('Successfully unsubscribed from multiPathRecommendation');
  } catch (err) {
    const error = err as BusinessError;
    console.error('Failed to unsubscribe: errCode: ' + error.code + ', errMessage: ' + error.message);
    // 错误处理
    handleUnsubscriptionError(error);
  }
}

// 取消订阅特定回调
function unsubscribeSpecificCallback(callback: (data: netHandover.MultiPathRecommendationInfo) => void): void {
  try {
    netHandover.off('multiPathRecommendation', callback);
    console.info('Successfully unsubscribed specific callback from multiPathRecommendation');
  } catch (err) {
    const error = err as BusinessError;
    console.error('Failed to unsubscribe specific callback: errCode: ' + error.code + ', errMessage: ' + error.message);
    handleUnsubscriptionError(error);
  }
}

// 错误处理函数
function handleUnsubscriptionError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please apply for ohos.permission.LINKTURBO permission.');
      break;
    case 1013600001:
      console.error('Internal processing exception. Please check system state.');
      break;
    case 1013600002:
      console.error('System processing exception. Please check network management service.');
      break;
    case 801:
      console.error('API not supported on this device. Please upgrade system to API 6.0.0(20)+.');
      break;
    default:
      console.error('Unknown error: ' + error.message);
  }
}
```

### 步骤5：降级处理

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 降级处理：订阅失败后的替代方案
function fallbackSubscriptionHandling(): void {
  console.warn('Using fallback strategy for multi-path recommendation');
  
  // 方案1：使用定时检查替代实时监听
  startPeriodicNetworkCheck();
  
  // 方案2：使用网络状态监听替代建议监听
  subscribeNetworkStateChange();
  
  // 方案3：提示用户手动触发多网请求
  showManualMultiPathOption();
}

// 定时检查网络状态（降级方案）
function startPeriodicNetworkCheck(): void {
  // 定时检查网络质量，根据质量决定是否发起多网请求
  const checkInterval = 5000; // 5秒检查一次
  setInterval(() => {
    const networkQuality = getCurrentNetworkQuality();
    if (networkQuality.isPoor) {
      console.info('Network quality is poor, consider requesting multi-path');
    }
  }, checkInterval);
}

// 订阅网络状态变化（降级方案）
function subscribeNetworkStateChange(): void {
  // 使用 connection API 监听网络状态变化
  // 这里需要导入 connection 模块并实现具体逻辑
  console.info('Subscribed to network state change as fallback');
}

// 显示手动触发选项（降级方案）
function showManualMultiPathOption(): void {
  // 在应用界面提供手动触发多网请求的按钮
  console.info('Provided manual multi-path request option to user');
}

// 辅助函数（示例）
function getCurrentNetworkQuality(): { isPoor: boolean } {
  // 获取当前网络质量
  // 这里需要根据实际业务逻辑实现
  return { isPoor: false }; // 示例返回值
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败。应用未申请 ohos.permission.LINKTURBO 权限。 | 在 module.json5 中声明 ohos.permission.LINKTURBO 权限，并引导用户授权。 |
| 401 | 参数检查失败。传入的参数类型或值不正确。 | 检查 type 参数是否为 'multiPathRecommendation'，callback 参数是否为正确类型的回调函数。 |
| 801 | 设备不支持该API。系统版本低于 API 6.0.0(20)。 | 提示用户升级系统到 HarmonyOS API 6.0.0(20) 及以上版本。 |
| 1013600001 | 内部处理异常。系统内部状态机异常或消息队列阻塞。 | 记录错误日志，稍后重试，或提示用户重启应用。 |
| 1013600002 | 系统处理异常。IPC跨进程调用失败或网络管理服务启动失败。 | 检查网络管理服务状态，提示用户检查系统网络设置，或重启设备。 |

## 编译和修复问题

### 依赖声明

**module.json5 权限声明**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "用于监听系统多网建议信息，实现智能网络加速",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**导入依赖**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 环境要求
- HarmonyOS API版本：6.0.0(20) 及以上
- DevEco Studio版本：5.0.0 及以上
- 系统能力：SystemCapability.Communication.NetworkBoost.Core

### 常见编译问题

**问题1：权限声明缺失**
```
Error: Permission 'ohos.permission.LINKTURBO' is not declared in module.json5
```
**解决方法**：在 module.json5 的 requestPermissions 数组中添加 ohos.permission.LINKTURBO 权限声明。

**问题2：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit' or its corresponding type declarations
```
**解决方法**：
- 检查项目 SDK 版本是否为 HarmonyOS NEXT SDK
- 在 DevEco Studio 中更新 SDK 到最新版本
- 检查 build-profile.json5 中的 compileSdkVersion 是否设置为 20 或更高

**问题3：API版本不兼容**
```
Error: Property 'on' does not exist on type 'netHandover'
```
**解决方法**：确认 API 版本为 6.0.0(20) 及以上，在 build-profile.json5 中设置正确的 compileSdkVersion。

**问题4：BusinessError 类型导入失败**
```
Error: Cannot find name 'BusinessError'
```
**解决方法**：添加导入语句 `import { BusinessError } from '@kit.BasicServicesKit';`

## 常见问题与解决方法

### Q1：订阅后没有收到回调通知
**原因**：
- 系统未感知到需要多网加速的场景
- 网络质量一直良好，系统未发出建议
- 权限未正确授权

**解决方法**：
- 确认已申请 ohos.permission.LINKTURBO 权限并获得授权
- 检查是否处于弱网环境或网络切换场景
- 添加日志记录订阅成功和回调触发情况
- 使用模拟网络切换场景测试回调触发

### Q2：取消订阅时回调函数匹配失败
**原因**：
- 取消订阅时传入的回调函数与订阅时的回调函数不是同一个引用
- 使用了不同的函数实例

**解决方法**：
- 确保取消订阅时传入的回调函数与订阅时传入的回调函数是同一个函数对象
- 使用函数变量保存回调函数引用，取消订阅时传入该引用
- 如果不需要取消特定回调，可以不传入 callback 参数，取消所有回调

### Q3：回调处理阻塞应用主线程
**原因**：
- 在回调函数中执行了耗时操作
- 在回调中直接发起网络请求或进行复杂计算

**解决方法**：
- 回调函数应快速处理，只进行简单的信息记录和状态更新
- 耗时操作应放在异步任务或工作线程中执行
- 使用 Promise 或 async/await 处理耗时操作
- 避免在回调中直接调用 requestMultiPath 或 releaseMultiPath，应在主线程决策后调用

### Q4：权限申请失败
**原因**：
- ohos.permission.LINKTURBO 是系统权限，用户可能拒绝授权
- 权限声明格式不正确

**解决方法**：
- 在 module.json5 中正确声明权限，包括 name、reason、usedScene 字段
- reason 字段应清晰说明权限用途，帮助用户理解
- 在应用启动时引导用户授权，并提供权限说明
- 如果用户拒绝授权，提供降级方案或提示用户手动开启权限

### Q5：API版本不支持
**原因**：
- 设备系统版本低于 HarmonyOS API 6.0.0(20)
- compileSdkVersion 设置过低

**解决方法**：
- 在应用启动时检查 API 版本，低于 6.0.0(20) 时提示用户升级系统
- 在 build-profile.json5 中设置 compileSdkVersion 为 20 或更高
- 提供兼容性处理，低版本系统使用替代方案（如定时检查网络状态）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "subscriptionStatus": "订阅成功",
  "eventName": "multiPathRecommendation",
  "callbackRegistered": true,
  "apiUsed": [
    "netHandover.on('multiPathRecommendation', callback)",
    "netHandover.off('multiPathRecommendation', callback?)"
  ],
  "permissionRequired": "ohos.permission.LINKTURBO",
  "apiVersion": "6.0.0(20)+",
  "recommendationInfoType": "MultiPathRecommendationInfo",
  "recommendationActions": [
    "MULTIPATH_ACTION_REQUEST",
    "MULTIPATH_ACTION_RELEASE"
  ]
}
```

## 参考文档

- [多网建议监听开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-recommendcallback)
- [netHandover API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-arkts-errorcode)

## 完整示例代码

- [ArkTS订阅示例](assets/subscribe_multi_path_recommendation.ets)
- [ArkTS取消订阅示例](assets/unsubscribe_multi_path_recommendation.ets)
- [完整业务流程示例](assets/multi_path_recommendation_example.ets)
- [降级处理示例](assets/fallback_handling.ets)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [订阅多网建议成功测试](tests/test_subscribe_success.py)：验证正常订阅流程
- [取消订阅成功测试](tests/test_unsubscribe_success.py)：验证正常取消订阅流程
- [回调处理测试](tests/test_callback_handling.py)：验证回调信息处理逻辑

### 边界测试用例
- [多次订阅测试](tests/test_multiple_subscription.py)：验证多次订阅同一事件的处理
- [取消特定回调测试](tests/test_unsubscribe_specific_callback.py)：验证取消特定回调函数的处理
- [取消所有回调测试](tests/test_unsubscribe_all_callbacks.py)：验证取消所有回调的处理

### 异常测试用例
- [权限不足测试](tests/test_permission_denied.py)：验证未申请权限时的错误处理
- [API版本不兼容测试](tests/test_api_version_incompatible.py)：验证低版本系统的兼容性处理
- [参数错误测试](tests/test_invalid_parameter.py)：验证传入错误参数时的错误处理
- [内部异常测试](tests/test_internal_exception.py)：验证系统内部异常时的降级处理
- [系统异常测试](tests/test_system_exception.py)：验证网络管理服务异常时的处理