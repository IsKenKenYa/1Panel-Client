---
name: hmos-call-service-kit-outgoing-call
description: 实现应用主动发起音视频通话的去电场景功能，支持语音和视频通话，需要在应用前台调用，最大支持1路去电通话，适用于即时通讯、视频会议场景
---

# 去电场景技能

## 功能描述

本技能提供HarmonyOS应用主动发起音/视频通话的去电场景实现能力。应用通过Call Service Kit向系统上报去电信息，系统会在屏幕左上角展示通话胶囊，用户可在实况窗通知上执行静音、挂断等操作。

**核心能力**：
- 上报去电请求，携带通话属性信息
- 监听用户在通话UI上的操作事件（静音、挂断等）
- 上报通话状态变化（拨号中、已接听、已挂断等）
- 上报音频事件变化（静音/取消静音、扬声器开关）

**技术限制**：
- 支持Phone、Tablet设备，从API 6.0(20)开始支持Wearable设备，API 6.1.1(24)开始支持PC/2in1设备
- 去电通话只能有1路，如来电最多允许3路
- 上报去电时，通话状态必须为`VOIP_CALL_STATE_DIALING`
- 用户头像图片最大221x221像素，推荐112x112像素，PixelMap大小需小于196608字节

## 使用场景

### 触发词
- "发起通话"
- "去电"
- "主动呼叫"
- "拨打语音电话"
- "拨打视频电话"
- "发起VoIP通话"
- "上报去电"

### 能做
- 实现应用主动发起语音/视频通话的去电功能
- 在屏幕左上角展示通话胶囊UI
- 监听用户在通话UI上的操作（静音、挂断、扬声器等）
- 上报通话状态变化（拨号中→已接听→已挂断）
- 上报音频事件变化（静音/取消静音、扬声器开关）
- 处理用户在实况窗通知上的操作

### 绝不做
- 不处理来电场景（需使用来电场景技能）
- 不处理运营商通话（仅支持应用内VoIP通话）
- 不在有蜂窝通话时发起去电（会返回错误）
- 不处理通话中的音视频编解码（仅管理通话状态和UI）
- 不支持在后台发起去电（必须在应用前台）

### 补充
- 必须先注册`voipCallUiEvent`事件监听，再上报去电
- 上报去电时通话状态必须为`VOIP_CALL_STATE_DIALING`，否则返回错误码1007200001
- 对端接听后，必须上报状态为`VOIP_CALL_STATE_ACTIVE`
- 通话结束后，建议取消注册`voipCallUiEvent`事件
- 去电场景不需要横幅通知，只显示通话胶囊

## 调用规范和规则

### 输入约束
- **callId**: 应用内通话唯一ID，字符串类型，必填
- **voipCallType**: 通话类型，枚举值`VOIP_CALL_VOICE`(0)或`VOIP_CALL_VIDEO`(1)，必填
- **userName**: 用户昵称，字符串类型，必填
- **userProfile**: 用户头像，PixelMap类型，最大221x221像素，推荐112x112像素，大小<196608字节，必填
- **abilityName**: 接听后加载的界面ability名称，字符串类型，必填
- **voipCallState**: 通话状态，上报去电时必须为`VOIP_CALL_STATE_DIALING`(5)，必填
- **showBannerForIncomingCall**: 是否显示横幅通知，布尔值，默认true，可选
- **isConferenceCall**: 是否为会议，布尔值，默认false，可选
- **isVoiceAnswerSupported**: 视频通话是否支持语音接听，布尔值，默认true，可选
- **isUserMuteRingToneAllowed**: 是否支持用户按键静音铃声，布尔值，默认false，可选（API 6.0.2+）
- **isDialingAllowedDuringCarrierCall**: 是否允许运营商通话中发起VoIP主叫，布尔值，默认false，可选（API 6.0.2+）

### 执行约束
- **最大去电路数**: 最多1路去电通话
- **最大来电路数**: 最多3路来电通话
- **调用时序**: 必须先注册事件监听，再上报去电
- **状态约束**: 上报去电时状态必须为`VOIP_CALL_STATE_DIALING`
- **API版本**: 起始版本4.1.0(11)，部分特性需要更高版本

### 内容约束
- 禁止使用已存在的callId重复上报去电
- 禁止在有蜂窝通话时发起去电
- 禁止在非前台状态发起去电
- 禁止使用非法的通话状态或通话类型
- 禁止使用超过大小限制的头像图片

### 降级约束
- **网络失败**: 提示用户网络异常，稍后重试
- **服务未启动**: 返回错误码1007200002，建议重启应用或设备
- **参数无效**: 返回错误码1007200001，检查参数合法性
- **内部错误**: 返回错误码1007200003，可能通话数量超限或与运营商通话冲突
- **权限不足**: 检查是否申请了必要的权限

## 调用流程和步骤

### 步骤1：准备阶段

**导入依赖模块**：
```typescript
import { voipCall } from '@kit.CallServiceKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
```

**权限检查**：
```typescript
// 确保应用已申请必要的权限
// 检查麦克风权限、摄像头权限（视频通话需要）
// 检查通知权限
```

**准备通话参数**：
```typescript
// 构建通话属性对象
let voipCallAttribute: voipCall.VoipCallAttribute = {
  callId: 'unique-call-id-12345', // 应用内唯一的通话ID
  voipCallType: voipCall.VoipCallType.VOIP_CALL_VOICE, // 语音通话
  userName: 'Jack', // 对端用户昵称
  userProfile: await createUserAvatar(), // 创建用户头像PixelMap
  abilityName: 'VoipCallAbility', // 接听后的Ability名称
  voipCallState: voipCall.VoipCallState.VOIP_CALL_STATE_DIALING, // 拨号中状态
  showBannerForIncomingCall: true, // 显示横幅通知
  isVoiceAnswerSupported: true // 支持语音接听
};
```

### 步骤2：注册事件监听

**注册voipCallUiEvent事件**（必须在上报去电之前）：
```typescript
// 注册通话UI事件监听
voipCall.on('voipCallUiEvent', (data: voipCall.VoipCallUiEventInfo) => {
  hilog.info(0x0000, 'CallDemo', 
    `Received UI event - CallId: ${data.callId}, Event: ${data.voipCallUiEvent}, Error: ${data.errorReason}`);
  
  // 处理不同的UI事件
  switch (data.voipCallUiEvent) {
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_HANGUP:
      // 用户点击挂断
      handleHangup(data.callId);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTED:
      // 用户开启静音
      handleMute(data.callId, true);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_UNMUTED:
      // 用户取消静音
      handleMute(data.callId, false);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTE_RINGTONE:
      // 用户按键静音铃声
      handleMuteRingtone(data.callId);
      break;
    default:
      hilog.warn(0x0000, 'CallDemo', `Unhandled event: ${data.voipCallUiEvent}`);
  }
});

hilog.info(0x0000, 'CallDemo', 'Succeeded in registering voipCallUiEvent');
```

### 步骤3：上报去电

**向系统上报去电信息**：
```typescript
// 上报去电请求
async function makeOutgoingCall(): Promise<void> {
  try {
    const errorReason = await voipCall.reportOutgoingCall(voipCallAttribute);
    
    if (errorReason === voipCall.ErrorReason.ERROR_NONE) {
      hilog.info(0x0000, 'CallDemo', 'Succeeded in reporting the outgoing call');
      // 去电上报成功，系统会显示通话胶囊UI
      // 此时通话状态为VOIP_CALL_STATE_DIALING（拨号中）
    } else {
      hilog.error(0x0000, 'CallDemo', 
        `Failed to report outgoing call, error: ${errorReason}`);
      handleOutgoingCallError(errorReason);
    }
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', 
      `Exception in reporting outgoing call: ${error.message}`);
    throw error;
  }
}
```

**错误处理**：
```typescript
function handleOutgoingCallError(errorReason: voipCall.ErrorReason): void {
  switch (errorReason) {
    case voipCall.ErrorReason.CELLULAR_CALL_EXISTS:
      hilog.error(0x0000, 'CallDemo', 'Cellular call exists, cannot make VoIP call');
      // 提示用户当前有运营商通话，无法发起VoIP通话
      break;
    case voipCall.ErrorReason.VOIP_CALL_EXISTS:
      hilog.error(0x0000, 'CallDemo', 'VoIP call already exists');
      // 提示用户当前已有应用内通话
      break;
    case voipCall.ErrorReason.INVALID_CALL:
      hilog.error(0x0000, 'CallDemo', 'Invalid call parameters');
      // 检查参数是否合法，特别是voipCallState必须为DIALING
      break;
    case voipCall.ErrorReason.USER_ANSWER_CELLULAR_FIRST:
      hilog.error(0x0000, 'CallDemo', 'User chose to answer cellular call');
      // 用户选择接听运营商通话
      break;
    default:
      hilog.error(0x0000, 'CallDemo', `Unknown error: ${errorReason}`);
  }
}
```

### 步骤4：上报通话状态变化

**对端接听后上报ACTIVE状态**：
```typescript
// 当对端接听通话后，需要上报通话状态为ACTIVE
async function handleCallAnswered(callId: string): Promise<void> {
  try {
    await voipCall.reportCallStateChange(
      callId, 
      voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE
    );
    hilog.info(0x0000, 'CallDemo', 
      `Call answered, reported ACTIVE state for call: ${callId}`);
    // 系统会更新通话胶囊UI，开始显示通话计时
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', 
      `Failed to report call state change: ${error.message}`);
  }
}
```

**通话中状态变化**：
```typescript
// 通话状态变化时上报（如：保持、断开等）
async function reportCallState(
  callId: string, 
  callState: voipCall.VoipCallState
): Promise<void> {
  try {
    await voipCall.reportCallStateChange(callId, callState);
    hilog.info(0x0000, 'CallDemo', 
      `Reported call state: ${callState} for call: ${callId}`);
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', 
      `Failed to report call state: ${error.message}`);
  }
}
```

**视频通话升降级**：
```typescript
// 视频通话降级为语音通话，或语音通话升级为视频通话
async function changeCallType(
  callId: string, 
  callState: voipCall.VoipCallState,
  callType: voipCall.VoipCallType
): Promise<void> {
  try {
    // 使用带callType参数的接口上报通话类型变化
    await voipCall.reportCallStateChange(callId, callState, callType);
    hilog.info(0x0000, 'CallDemo', 
      `Reported call type change: ${callType} for call: ${callId}`);
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', 
      `Failed to report call type change: ${error.message}`);
  }
}
```

### 步骤5：处理用户UI事件

**静音与取消静音**：
```typescript
// 用户在实况窗通知上点击静音/取消静音
async function handleMute(callId: string, isMuted: boolean): Promise<void> {
  try {
    const callAudioEvent = isMuted 
      ? voipCall.CallAudioEvent.AUDIO_EVENT_MUTED 
      : voipCall.CallAudioEvent.AUDIO_EVENT_UNMUTED;
    
    await voipCall.reportCallAudioEventChange(callId, callAudioEvent);
    hilog.info(0x0000, 'CallDemo', 
      `Reported mute state: ${isMuted} for call: ${callId}`);
    
    // 在应用内执行实际的静音/取消静音操作
    // 例如：控制音频采集
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', 
      `Failed to report audio event: ${error.message}`);
  }
}
```

**挂断通话**：
```typescript
// 用户在实况窗通知上点击挂断
async function handleHangup(callId: string): Promise<void> {
  try {
    // 上报通话已断开状态
    await voipCall.reportCallStateChange(
      callId, 
      voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED
    );
    hilog.info(0x0000, 'CallDemo', `Call hung up: ${callId}`);
    
    // 清理应用内的通话资源
    cleanupCall(callId);
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', 
      `Failed to report hangup: ${error.message}`);
  }
}
```

### 步骤6：清理资源

**通话结束后取消事件监听**：
```typescript
// 通话结束后，取消注册voipCallUiEvent事件
function cleanupCall(callId: string): void {
  try {
    // 取消事件监听
    voipCall.off('voipCallUiEvent');
    hilog.info(0x0000, 'CallDemo', 
      `Unregistered voipCallUiEvent for call: ${callId}`);
    
    // 清理应用内的通话状态
    // 释放音频/视频资源
    // 更新UI状态
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', 
      `Failed to cleanup call: ${error.message}`);
  }
}
```

**降级处理**：
```typescript
// 如果上报失败或服务异常，提供降级方案
async function fallbackCallHandling(callId: string): Promise<void> {
  hilog.warn(0x0000, 'CallDemo', 
    'Call Service Kit unavailable, using fallback mode');
  
  // 降级方案：
  // 1. 使用应用内自定义通话UI
  // 2. 不显示系统通话胶囊
  // 3. 手动管理通话状态
  // 4. 提示用户可能无法收到系统通知
  
  showCustomCallUI(callId);
}
```

## 错误码说明

| 错误码 | 错误信息 | 说明 | 解决方法 |
|-------|---------|------|---------|
| 401 | Parameter error | 参数错误 | 检查参数类型、数量、必填项是否正确 |
| 1007200001 | Invalid parameter value | 参数值无效 | 1. 检查callId是否唯一且正确<br>2. 上报去电时状态必须为`VOIP_CALL_STATE_DIALING`<br>3. 通话类型必须为`VOIP_CALL_VOICE`或`VOIP_CALL_VIDEO`<br>4. 避免重复上报同一路通话 |
| 1007200002 | Cannot connect to service | 服务未启动 | Call Service Kit服务启动失败，建议重启应用或设备，或联系华为支持 |
| 1007200003 | System internal error | 内部错误 | 可能原因：<br>1. 通话数量超限（去电最多1路，来电最多3路）<br>2. 与运营商通话冲突<br>建议等待当前通话结束或挂断运营商通话 |
| 1007200999 | Unknown error code | 未知错误 | 联系华为技术支持处理 |

**ErrorReason枚举值**：
| 错误原因 | 值 | 说明 |
|---------|---|------|
| ERROR_NONE | 0 | 无错误 |
| CELLULAR_CALL_EXISTS | 1 | 当前已存在蜂窝通话 |
| VOIP_CALL_EXISTS | 2 | 当前已存在其他应用内通话 |
| INVALID_CALL | 3 | 通话无效（callId校验失败等） |
| USER_ANSWER_CELLULAR_FIRST | 4 | 用户选择接听蜂窝通话 |

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "abilities": [
      {
        "name": "VoipCallAbility",
        "srcEntry": "./ets/va/vipcallability/VoipCallAbility.ts",
        "description": "$string:VoipCallAbility_desc",
        "icon": "$media:icon",
        "label": "$string:VoipCallAbility_label",
        "exported": true
      }
    ]
  }
}
```

**module.json5权限声明**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.MICROPHONE",
        "reason": "$string:permission_microphone_reason",
        "usedScene": {
          "abilities": ["VoipCallAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:permission_camera_reason",
        "usedScene": {
          "abilities": ["VoipCallAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 环境要求
- **HarmonyOS SDK**: API 4.1.0(11) 及以上
- **DevEco Studio**: 3.1及以上版本
- **设备支持**: Phone、Tablet（API 4.1+）、Wearable（API 6.0+）、PC/2in1（API 6.1.1+）

### 常见编译问题

**问题1：找不到'@kit.CallServiceKit'模块**
```
Error: Cannot find module '@kit.CallServiceKit'
```
**解决方法**：
- 检查HarmonyOS SDK版本是否≥4.1.0(11)
- 在build-profile.json5中配置compileSdkVersion为API 11及以上
- 同步项目：File > Sync and Refresh Project

**问题2：PixelMap创建失败**
```
Error: Failed to create PixelMap
```
**解决方法**：
- 检查图片资源是否存在
- 确保图片大小不超过221x221像素
- 确保PixelMap字节大小<196608字节
- 使用正确的图片格式（PNG、JPEG等）

**问题3：权限未授予**
```
Error: Permission denied
```
**解决方法**：
- 在module.json5中声明必要权限
- 对于敏感权限，在运行时动态申请
- 检查usedScene配置是否正确

**问题4：状态上报失败（错误码1007200001）**
```
Error: Invalid parameter value
```
**解决方法**：
- 确认上报去电时voipCallState为`VOIP_CALL_STATE_DIALING`
- 检查callId是否唯一且格式正确
- 确认没有重复上报同一路通话
- 检查voipCallType是否为合法值

**问题5：服务连接失败（错误码1007200002）**
```
Error: Cannot connect to service
```
**解决方法**：
- 重启应用或设备
- 检查系统服务是否正常运行
- 联系华为技术支持

## 常见问题与解决方法

### Q1：上报去电后没有显示通话胶囊UI
**原因**：
- 上报失败，返回错误码非ERROR_NONE
- showBannerForIncomingCall设置为false
- 系统UI服务异常

**解决方法**：
- 检查`reportOutgoingCall`返回值是否为`ERROR_NONE`
- 确认`showBannerForIncomingCall`参数设置为true（默认true）
- 检查系统日志，确认Call Service Kit服务是否正常启动
- 重启应用或设备

### Q2：无法监听到用户的静音、挂断等操作
**原因**：
- 未在上报去电前注册`voipCallUiEvent`事件
- 事件监听注册失败
- 回调函数逻辑错误

**解决方法**：
- 确保在调用`reportOutgoingCall`之前调用`voipCall.on('voipCallUiEvent', callback)`
- 检查事件监听是否注册成功（查看日志）
- 在回调函数中正确处理各个事件类型
- 检查callId是否匹配

### Q3：对端接听后通话计时未开始
**原因**：
- 未上报通话状态为`VOIP_CALL_STATE_ACTIVE`
- callId与上报去电时不一致

**解决方法**：
- 对端接听后，立即调用`reportCallStateChange(callId, VOIP_CALL_STATE_ACTIVE)`
- 确保callId与上报去电时使用的callId完全一致
- 检查上报是否成功（使用Promise的then/catch）

### Q4：视频通话降级为语音通话后UI未更新
**原因**：
- 使用了不带callType参数的`reportCallStateChange`接口
- 该接口不能改变通话类型

**解决方法**：
- 使用带callType参数的重载接口：
  ```typescript
  voipCall.reportCallStateChange(callId, callState, callType);
  ```
- 例如：`voipCall.reportCallStateChange(callId, VOIP_CALL_STATE_ACTIVE, VOIP_CALL_VOICE)`

### Q5：上报失败返回错误码1007200003（内部错误）
**原因**：
- 已有去电通话存在（去电最多1路）
- 与运营商通话冲突
- 系统资源不足

**解决方法**：
- 检查是否已有去电通话，如有需先结束当前通话
- 检查是否有运营商通话，如有需先挂断运营商通话
- 使用`isDialingAllowedDuringCarrierCall`参数（API 6.0.2+）控制是否允许运营商通话中发起VoIP
- 重启应用或设备释放资源

### Q6：头像图片加载失败或显示异常
**原因**：
- 图片大小超过限制（最大221x221像素，推荐112x112）
- PixelMap字节大小≥196608字节
- 图片格式不支持

**解决方法**：
- 使用图片处理库（如ImageKit）压缩图片
- 推荐尺寸：112x112像素
- 使用PNG或JPEG格式
- 通过`pixelMap.getPixelBytesNumber()`检查字节数
- 示例：
  ```typescript
  const imageSource = image.createImageSource(buffer);
  const pixelMap = await imageSource.createPixelMap();
  const pixelBytes = pixelMap.getPixelBytesNumber();
  if (pixelBytes >= 196608) {
    // 压缩图片或使用小图
  }
  ```

### Q7：通话结束后再次上报失败
**原因**：
- 使用了相同的callId
- 未清理上一次通话的状态

**解决方法**：
- 每次通话使用唯一的callId（UUID或时间戳）
- 通话结束后调用`voipCall.off('voipCallUiEvent')`取消监听
- 上报`VOIP_CALL_STATE_DISCONNECTED`状态结束通话
- 等待一段时间后再发起新通话

### Q8：应用在后台无法上报去电
**原因**：
- 去电场景要求应用在前台
- 后台时系统限制VoIP通话

**解决方法**：
- 确保应用在前台时上报去电
- 如需后台接听来电，使用来电场景技能
- 使用后台任务管理器申请长时任务（如需）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "callId": "unique-call-id-12345",
  "callType": "VOIP_CALL_VOICE",
  "callState": "VOIP_CALL_STATE_DIALING",
  "userName": "Jack",
  "abilityName": "VoipCallAbility",
  "apiUsed": [
    "voipCall.on('voipCallUiEvent')",
    "voipCall.reportOutgoingCall()",
    "voipCall.reportCallStateChange()",
    "voipCall.reportCallAudioEventChange()",
    "voipCall.off('voipCallUiEvent')"
  ],
  "errorReason": "ERROR_NONE",
  "timestamp": "2026-07-03T10:00:00Z"
}
```

## 参考文档

- [API开发指南](references/api-guide.md) - 去电场景开发指南
- [API参考说明](references/api-reference.md) - voipCall模块API文档
- [错误码说明](references/error-code.md) - Call Service Kit错误码

## 完整示例代码

- [ArkTS完整示例](assets/outgoing-call-example.ets) - 包含完整的去电场景实现
- [工具函数示例](assets/call-utils.ets) - 通话工具函数封装
- [配置文件示例](assets/module.json5) - 模块配置和权限声明

## 测试用例

### 正向测试用例
- [发起语音去电](tests/test_voice_outgoing_call.ets) - 测试正常发起语音通话去电流程
- [发起视频去电](tests/test_video_outgoing_call.ets) - 测试正常发起视频通话去电流程
- [监听UI事件](tests/test_ui_event_listener.ets) - 测试监听用户操作事件
- [上报状态变化](tests/test_state_change.ets) - 测试上报通话状态变化

### 边界测试用例
- [最大头像尺寸](tests/test_max_avatar_size.ets) - 测试头像图片最大尺寸限制
- [多路去电限制](tests/test_multiple_outgoing_limit.ets) - 测试最多1路去电限制
- [状态转换](tests/test_state_transition.ets) - 测试通话状态正确转换

### 异常测试用例
- [参数无效](tests/test_invalid_params.ets) - 测试非法参数的错误处理
- [服务未启动](tests/test_service_unavailable.ets) - 测试服务异常的降级处理
- [重复上报](tests/test_duplicate_report.ets) - 测试重复上报的错误处理
- [蜂窝通话冲突](tests/test_cellular_conflict.ets) - 测试与运营商通话冲突