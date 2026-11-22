---
name: hmos-networkboostkit-scenecallback
description: 订阅网络场景识别信息变化回调，支持监听网络拥塞、弱信号、频繁切换等场景，提供数传策略建议和弱信号预测，适用于视频播放、游戏、直播等实时业务场景
---

# 网络场景识别回调技能

## 功能描述

本技能用于订阅网络场景识别信息变化回调，实时监听网络场景状态（包括正常、拥塞、弱信号、频繁切换），获取数传策略建议（缓存、停止发包、降低/增加发包速率）以及弱信号预测信息（预计进入弱信号区域时间和停留时长）。应用可根据场景信息调整缓存、码率、帧率、分辨率等策略，实现网络自适应优化。

## 使用场景

### 触发词
- "订阅网络场景识别"
- "监听网络场景变化"
- "网络场景回调"
- "网络场景识别"
- "弱信号预测"
- "网络拥塞监听"
- "数传策略建议"

### 能做
- 订阅网络场景识别信息变化，实时获取网络场景状态
- 监听网络拥塞场景，及时调整发包策略
- 监听弱信号场景和弱信号预测信息，提前进行策略调整
- 监听频繁切换场景，优化网络切换时的业务体验
- 获取数传策略建议（缓存、停止/降低/增加/保持发包速率）
- 取消订阅网络场景识别信息

### 绝不做
- 不处理超出网络场景识别范围的请求（如网络质量信息订阅使用 netQosChange）
- 不直接修改网络配置或网络参数
- 不替代应用层的业务策略决策（只提供建议）
- 不处理不涉及 Network Boost Kit 的网络功能

### 补充
- 需要 ohos.permission.GET_NETWORK_INFO 权限
- 仅支持 API version 5.0.0(12) 及以上
- 需要 SystemCapability.Communication.NetworkBoost.Core 系统能力
- 回调信息为 Array<NetworkScene>，包含多条路径的网络场景信息

## 调用规范和规则

### 输入约束
- 无输入参数要求（订阅/取消订阅操作）
- callback 参数必须为有效的回调函数（订阅时必填，取消订阅时可选）
- type 参数固定为 'netSceneChange' 字符串

### 执行约束
- 订阅后系统在网络场景实时信息或预测信息变化后回调给应用
- 回调频率由系统网络场景变化决定，非固定频率
- 取消订阅时若传入 callback，必须与订阅时传入的回调函数是同一个
- 取消订阅时若不传入 callback，则取消所有注册的回调函数

### 内容约束
- 禁止使用固定的回调频率假设
- 禁止在回调函数中执行耗时超过 100ms 的操作（会影响系统回调性能）
- 禁止在回调函数中直接修改网络配置
- 回调函数必须包含异常处理逻辑

### 降级约束
- 权限不足时抛出 201 错误，需要提示用户申请权限
- 参数检查失败时抛出 401 错误，需要校验参数有效性
- 设备不支持该 API 时抛出 801 错误，需要提示用户设备不支持
- 网络场景识别不可用时，使用默认策略或降级为网络质量监听

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持 SystemCapability.Communication.NetworkBoost.Core
2. 检查应用是否已申请 ohos.permission.GET_NETWORK_INFO 权限
3. 检查 API version 是否 >= 5.0.0(12)

**参数准备**：
```typescript
// 导入必要模块
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：订阅网络场景识别信息

**示例代码**：
```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义回调函数处理网络场景信息
function handleNetworkSceneChange(list: Array<netQuality.NetworkScene>): void {
  if (list.length > 0) {
    list.forEach((sceneInfo) => {
      // 处理网络场景信息
      console.info('Network scene changed on path:', sceneInfo.pathType);
      
      // 处理不同场景类型
      switch (sceneInfo.scene) {
        case 'normal':
          console.info('Network is normal');
          // 正常场景处理：恢复默认策略
          break;
        case 'congestion':
          console.info('Network is congested');
          // 拥塞场景处理：降低码率、减少发包
          break;
        case 'frequentHandover':
          console.info('Network is frequent handover');
          // 频繁切换场景处理：缓存数据、暂停关键操作
          break;
        case 'weakSignal':
          console.info('Network is weak signal');
          // 弱信号场景处理：大幅降低码率、增加缓存
          break;
      }
      
      // 处理数传策略建议
      if (sceneInfo.recommendedAction) {
        console.info('Recommended action:', sceneInfo.recommendedAction);
        switch (sceneInfo.recommendedAction) {
          case 'doCaching':
            // 执行缓存动作
            console.info('Execute caching strategy');
            break;
          case 'suspendData':
            // 停止发包
            console.info('Suspend data transmission');
            break;
          case 'decreaseData':
            // 降低发包速率
            console.info('Decrease data rate');
            break;
          case 'increaseData':
            // 增加发包速率
            console.info('Increase data rate');
            break;
          case 'keepData':
            // 保持当前发包速率
            console.info('Keep current data rate');
            break;
        }
      }
      
      // 处理弱信号预测信息
      if (sceneInfo.weakSignalPrediction) {
        const prediction = sceneInfo.weakSignalPrediction;
        if (prediction.isLastPredictionValid) {
          console.info('Weak signal prediction: will enter weak signal in', 
                      prediction.startTime, 'seconds');
          console.info('Will stay in weak signal area for', 
                      prediction.duration, 'seconds');
          // 提前调整策略：增加缓存、降低码率等
        } else {
          console.info('Weak signal prediction is invalid');
        }
      }
    });
  }
}

// 订阅网络场景识别信息
try {
  netQuality.on('netSceneChange', handleNetworkSceneChange);
  console.info('Succeeded in subscribing to netSceneChange');
} catch (err) {
  const error = err as BusinessError;
  console.error('Failed to subscribe to netSceneChange. errCode:', error.code, 
               ', errMessage:', error.message);
}
```

### 步骤3：取消订阅网络场景识别信息

**示例代码**：
```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消订阅所有回调
try {
  netQuality.off('netSceneChange');
  console.info('Succeeded in unsubscribing from netSceneChange');
} catch (err) {
  const error = err as BusinessError;
  console.error('Failed to unsubscribe from netSceneChange. errCode:', error.code, 
               ', errMessage:', error.message);
}

// 取消订阅特定回调
try {
  netQuality.off('netSceneChange', handleNetworkSceneChange);
  console.info('Succeeded in unsubscribing specific callback from netSceneChange');
} catch (err) {
  const error = err as BusinessError;
  console.error('Failed to unsubscribe specific callback. errCode:', error.code, 
               ', errMessage:', error.message);
}
```

### 步骤4：错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  netQuality.on('netSceneChange', handleNetworkSceneChange);
} catch (err) {
  const error = err as BusinessError;
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please apply for ohos.permission.GET_NETWORK_INFO');
      // 提示用户申请权限
      break;
    case 401:
      console.error('Parameter check failed. Please verify callback function is valid');
      // 校验参数有效性
      break;
    case 801:
      console.error('Device does not support this API');
      // 提示用户设备不支持，降级处理
      break;
    default:
      console.error('Unknown error:', error.message);
      // 其他错误处理
  }
}
```

### 步骤5：降级处理

```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 降级方案：网络场景识别不可用时使用默认策略
function useDefaultNetworkStrategy(): void {
  console.warn('Network scene detection unavailable, using default strategy');
  // 使用保守的默认策略
  // 例如：使用较低的码率、较大的缓存
}

// 尝试订阅网络场景识别，失败时降级
try {
  netQuality.on('netSceneChange', handleNetworkSceneChange);
} catch (err) {
  const error = err as BusinessError;
  if (error.code === 801) {
    // 设备不支持网络场景识别，使用默认策略
    useDefaultNetworkStrategy();
  } else if (error.code === 201) {
    // 权限不足，提示用户并使用默认策略
    console.warn('Permission required for network scene detection');
    useDefaultNetworkStrategy();
  } else {
    // 其他错误，抛出异常或使用默认策略
    console.error('Failed to subscribe network scene:', error.message);
    useDefaultNetworkStrategy();
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败，缺少 ohos.permission.GET_NETWORK_INFO 权限 | 在 module.json5 中申请权限：`"requestPermissions": [{"name": "ohos.permission.GET_NETWORK_INFO"}]` |
| 401 | 参数检查失败，callback 参数无效 | 确保 callback 为有效的回调函数，且符合 `Callback<Array<NetworkScene>>` 类型 |
| 801 | 设备不支持该 API，缺少 SystemCapability.Communication.NetworkBoost.Core | 提示用户设备不支持，使用默认策略或降级为网络质量监听 |

## 编译和修复问题

### 依赖声明

**module.json5 配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**package.json 配置**（如果使用 npm 包管理）：
```json
{
  "dependencies": {
    "@kit.NetworkBoostKit": "5.0.0",
    "@kit.BasicServicesKit": "5.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version：>= 5.0.0(12)
- DevEco Studio：>= 5.0.0
- 系统能力：SystemCapability.Communication.NetworkBoost.Core

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit' or its corresponding type declarations.
```
**解决方法**：
- 检查 HarmonyOS SDK 版本是否 >= 5.0.0
- 在 DevEco Studio 中更新 SDK 到最新版本
- 确认 module.json5 中已正确配置

**问题2：权限声明缺失**
```
Error: Permission denied: ohos.permission.GET_NETWORK_INFO
```
**解决方法**：
- 在 module.json5 的 requestPermissions 中添加权限声明
- 确保权限的 reason 和 usedScene 配置正确

**问题3：类型定义错误**
```
Error: Property 'scene' does not exist on type 'NetworkScene'.
```
**解决方法**：
- 检查 NetworkScene 类型定义是否正确导入
- 确认使用的是 `netQuality.NetworkScene` 类型
- 更新 SDK 到最新版本以获取完整的类型定义

## 常见问题与解决方法

### Q1：订阅后没有收到回调信息？
**原因**：
- 网络场景未发生变化（保持正常状态）
- 回调函数未正确定义
- 权限未授予

**解决方法**：
- 检查网络环境是否发生变化（切换网络、进入弱信号区域等）
- 验证回调函数是否正确实现并包含 console.info 等日志输出
- 确认应用已获得 ohos.permission.GET_NETWORK_INFO 权限

### Q2：回调信息中 weakSignalPrediction 为 null？
**原因**：
- 当前网络场景不涉及弱信号预测
- 系统未提供弱信号预测信息
- isLastPredictionValid 为 false

**解决方法**：
- 检查 `sceneInfo.weakSignalPrediction` 是否存在后再处理
- 当 `isLastPredictionValid` 为 false 时忽略预测信息
- 在代码中添加可选链操作符：`sceneInfo.weakSignalPrediction?.isLastPredictionValid`

### Q3：取消订阅后仍收到回调？
**原因**：
- 取消订阅时传入的 callback 与订阅时不一致
- 多次订阅导致多个回调函数注册
- 取消订阅失败

**解决方法**：
- 确保取消订阅时传入的 callback 与订阅时完全相同（同一个函数引用）
- 使用 `netQuality.off('netSceneChange')` 取消所有回调
- 在取消订阅后添加日志验证是否成功

### Q4：如何在业务中应用数传策略建议？
**原因**：应用需要根据 recommendedAction 调整业务策略

**解决方法**：
- `doCaching`：增加视频/音频缓存，预加载更多数据
- `suspendData`：暂停实时数据传输（如直播推流）
- `decreaseData`：降低码率、帧率、分辨率
- `increaseData`：恢复或提高码率、帧率、分辨率
- `keepData`：保持当前策略不变

### Q5：弱信号预测信息如何用于业务优化？
**原因**：应用需要提前调整策略以应对即将到来的弱信号区域

**解决方法**：
- 根据 `startTime` 提前调整策略（提前 startTime 秒）
- 根据 `duration` 确定弱信号持续时间，决定缓存策略
- 在进入弱信号前增加缓存、降低码率
- 在弱信号持续期间保持保守策略
- 在离开弱信号区域后恢复正常策略

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "subscribe/unsubscribe",
  "eventType": "netSceneChange",
  "callbackRegistered": true,
  "apiUsed": [
    "netQuality.on('netSceneChange', callback)",
    "netQuality.off('netSceneChange', callback?)"
  ],
  "networkScenes": [
    {
      "pathType": "CELLULAR_PRIMARY",
      "scene": "normal",
      "recommendedAction": "keepData",
      "weakSignalPrediction": null
    }
  ]
}
```

## 参考文档

- [API开发指南 - 网络场景识别](references/networkboost-scenecallback-guide.md)
- [API参考说明 - netQuality](references/networkboost-netquality-reference.md)

## 完整示例代码

- [ArkTS示例代码](assets/networkboost_scenecallback_example.ets)

## 测试用例

### 正向测试用例
- [订阅网络场景识别成功](tests/test_positive.ets)：验证订阅成功并收到回调
- [处理多种网络场景](tests/test_positive.ets)：验证处理 normal、congestion、weakSignal 等场景
- [处理弱信号预测信息](tests/test_positive.ets)：验证处理有效的弱信号预测
- [取消订阅成功](tests/test_positive.ets)：验证取消订阅不再收到回调

### 边界测试用例
- [空回调数组处理](tests/test_boundary.ets)：验证回调数组为空时的处理
- [多个路径的场景信息](tests/test_boundary.ets)：验证处理多条路径的网络场景
- [取消订阅特定回调](tests/test_boundary.ets)：验证取消订阅特定回调函数

### 异常测试用例
- [权限不足场景](tests/test_exception.ets)：验证缺少权限时的错误处理
- [参数错误场景](tests/test_exception.ets)：验证 callback 参数无效时的错误处理
- [设备不支持场景](tests/test_exception.ets)：验证设备不支持 API 时的降级处理
- [网络场景识别不可用](tests/test_exception.ets)：验证系统服务不可用时的降级处理