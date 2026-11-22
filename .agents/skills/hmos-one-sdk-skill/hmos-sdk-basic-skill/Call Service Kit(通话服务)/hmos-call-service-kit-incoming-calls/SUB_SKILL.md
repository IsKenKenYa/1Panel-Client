---
name: hmos-call-service-kit-incoming-calls
description: 实现VoIP来电场景功能,包括上报来电、处理用户接听/拒接/挂断操作、上报通话状态和音频事件,支持语音和视频来电,适用于即时通讯、VoIP通话等场景
---

# 来电场景技能

## 功能描述

本技能实现HarmonyOS应用内VoIP来电场景功能,允许应用接收来自网络的音/视频通话,并通过Call Service Kit向系统上报来电信息和通话状态变化。支持以下功能:

- 上报语音/视频来电信息,包括通话ID、用户昵称、头像等
- 接收用户在系统横幅通知上的操作事件(接听、拒接、挂断、静音等)
- 上报通话状态变化(接听中、已接听、已挂断等)
- 上报音频事件(静音、解除静音)
- 支持视频通话的语音接听选项
- 支持设备:Phone、Tablet、Wearable(6.0+)、PC/2in1(6.1.1+)

## 使用场景

### 触发词
- "实现来电功能"
- "VoIP来电"
- "接收音视频来电"
- "来电场景"
- "来电横幅通知"
- "应用内通话"

### 能做
- 实现语音来电接收和处理流程
- 实现视频来电接收和处理流程
- 处理用户在横幅通知上的接听/拒接操作
- 处理通话过程中的静音/解除静音操作
- 处理通话挂断操作
- 上报通话状态变化给系统
- 支持视频通话的语音接听选项设置

### 绝不做
- 不处理去电场景(使用其他技能)
- 不处理应用内音视频编解码
- 不处理网络连接建立(应用需自行建立通话连接)
- 不替代蜂窝通话功能

### 补充
- 应用需先自行建立通话连接,再调用本技能上报来电
- 上报来电前需先注册voipCallUiEvent事件
- 建议采用两次状态上报方式(ANSWERED -> ACTIVE)以提供更好的用户体验
- 视频通话可通过isVoiceAnswerSupported参数控制是否允许语音接听

## 调用规范和规则

### 输入约束
- callId: 字符串类型,应用内通话唯一标识,长度建议不超过50字符
- userName: 字符串类型,用户昵称,建议长度不超过20字符
- userProfile: PixelMap类型,建议大小112x112像素,最大不超过221x221像素,图片字节大小不超过196608
- abilityName: 字符串类型,接听后需加载的Ability名称
- voipCallType: 枚举类型,语音通话(0)或视频通话(1)
- voipCallState: 枚举类型,通话状态(0-7)
- callAudioEvent: 枚举类型,音频事件(0-3)

### 执行约束
- 最大API调用频率: 不超过10次/秒
- 每个callId对应一次完整的通话生命周期
- 建议在上报来电前完成通话连接建立
- 必须在Ability的onCreate或合适的生命周期回调中注册事件监听

### 内容约束
- 禁止使用无效的callId
- 禁止使用错误的通话状态序列
- 禁止在未注册事件的情况下处理用户操作
- 禁止传入超过限制大小的用户头像

### 降级约束
- 上报来电失败: 调用reportIncomingCallError上报失败原因
- 用户头像加载失败: 使用默认头像或不显示头像
- 通话连接建立失败: 不上报来电,直接取消操作
- 权限不足: 提示用户授予必要权限

## 调用流程和步骤

### 步骤1: 导入依赖和准备阶段

**前置校验**:
1. 确认应用已申请必要权限(根据实际需求配置)
2. 确认设备系统版本满足要求(API 11+)
3. 确认已导入@kit.CallServiceKit模块

**依赖导入**:
```typescript
import { voipCall } from '@kit.CallServiceKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2: 注册voipCallUiEvent事件

**说明**: 在上报来电之前注册事件监听,以接收用户在横幅通知上的操作。

**示例代码**:
```typescript
// 注册voipCallUiEvent事件
voipCall.on('voipCallUiEvent', (callback: voipCall.VoipCallUiEventInfo) => {
  hilog.info(0x0000, 'CallDemo', `Received UI event: ${callback.voipCallUiEvent}, callId: ${callback.callId}`);
  
  // 处理不同的UI事件
  switch (callback.voipCallUiEvent) {
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VOICE_ANSWER:
      // 处理语音接听
      handleVoiceAnswer(callback.callId);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VIDEO_ANSWER:
      // 处理视频接听
      handleVideoAnswer(callback.callId);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_REJECT:
      // 处理拒接
      handleReject(callback.callId);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_HANGUP:
      // 处理挂断
      handleHangup(callback.callId);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTED:
      // 处理静音
      handleMuted(callback.callId);
      break;
    case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_UNMUTED:
      // 处理解除静音
      handleUnmuted(callback.callId);
      break;
    default:
      hilog.warn(0x0000, 'CallDemo', `Unknown event: ${callback.voipCallUiEvent}`);
  }
});
```

### 步骤3: 上报来电

**说明**: 应用内部建立通话连接后,向Call Service Kit上报来电信息。

**参数准备**:
```typescript
// 构造上报来电的参数
let voipCallAttribute: voipCall.VoipCallAttribute = {
  callId: '1234567890',  // 应用内通话唯一ID
  voipCallType: voipCall.VoipCallType.VOIP_CALL_VOICE,  // 语音通话
  userName: 'Callman',  // 用户昵称
  userProfile: image.createPixelMapSync(new ArrayBuffer(100), { size: { width: 90, height: 90 } }),  // 用户头像
  abilityName: 'VoipCallAbility',  // 接听后加载的Ability
  voipCallState: voipCall.VoipCallState.VOIP_CALL_STATE_RINGING,  // 呼叫传入状态
  showBannerForIncomingCall: true  // 显示来电横幅
};
```

**示例代码**:
```typescript
// 上报来电
voipCall.reportIncomingCall(voipCallAttribute).then((errorReason: voipCall.ErrorReason) => {
  if (errorReason === voipCall.ErrorReason.ERROR_NONE) {
    hilog.info(0x0000, 'CallDemo', 'Succeeded in reporting the incoming call');
  } else {
    hilog.error(0x0000, 'CallDemo', `Failed to report incoming call: ${errorReason}`);
    // 上报来电失败,调用reportIncomingCallError
    voipCall.reportIncomingCallError(voipCallAttribute.callId, voipCall.VoipCallFailureCause.OTHER);
  }
}).catch((error: Error) => {
  hilog.error(0x0000, 'CallDemo', `Exception: ${error.message}`);
});
```

### 步骤4: 处理接听操作

**说明**: 用户在横幅通知上点击接听后,应用接收事件并处理。

**推荐方式(两次状态上报)**:
```typescript
async function handleVoiceAnswer(callId: string): Promise<void> {
  try {
    // 1. 立即上报ANSWERED状态,给用户反馈
    await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED);
    hilog.info(0x0000, 'CallDemo', 'Reported ANSWERED state');
    
    // 2. 在应用内完成接听逻辑(建立音视频连接等)
    await performAppInternalAnswer(callId);
    
    // 3. 接听成功后,上报ACTIVE状态
    await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE);
    hilog.info(0x0000, 'CallDemo', 'Reported ACTIVE state');
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', `Failed to handle voice answer: ${error}`);
  }
}

async function performAppInternalAnswer(callId: string): Promise<void> {
  // 应用内接听逻辑,例如:
  // - 建立音视频连接
  // - 初始化编解码器
  // - 开始音视频传输
  hilog.info(0x0000, 'CallDemo', `Performing internal answer for call: ${callId}`);
}
```

**简化方式(一次状态上报)**:
```typescript
async function handleVoiceAnswerSimple(callId: string): Promise<void> {
  try {
    // 在应用内完成接听逻辑
    await performAppInternalAnswer(callId);
    
    // 直接上报ACTIVE状态
    await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE);
    hilog.info(0x0000, 'CallDemo', 'Reported ACTIVE state');
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', `Failed to handle voice answer: ${error}`);
  }
}
```

### 步骤5: 处理拒接操作

**示例代码**:
```typescript
async function handleReject(callId: string): Promise<void> {
  try {
    // 在应用内完成拒接逻辑
    await performAppInternalReject(callId);
    
    // 上报DISCONNECTED状态,系统会取消横幅通知
    await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
    hilog.info(0x0000, 'CallDemo', 'Call rejected and disconnected');
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', `Failed to handle reject: ${error}`);
  }
}

async function performAppInternalReject(callId: string): Promise<void> {
  // 应用内拒接逻辑,例如:
  // - 拒绝音视频连接
  // - 通知对方用户
  hilog.info(0x0000, 'CallDemo', `Performing internal reject for call: ${callId}`);
}
```

### 步骤6: 处理静音操作

**示例代码**:
```typescript
async function handleMuted(callId: string): Promise<void> {
  try {
    // 在应用内完成静音逻辑
    await performAppInternalMute(callId, true);
    
    // 上报MUTED音频事件
    await voipCall.reportCallAudioEventChange(callId, voipCall.CallAudioEvent.AUDIO_EVENT_MUTED);
    hilog.info(0x0000, 'CallDemo', 'Reported MUTED audio event');
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', `Failed to handle muted: ${error}`);
  }
}

async function handleUnmuted(callId: string): Promise<void> {
  try {
    // 在应用内完成解除静音逻辑
    await performAppInternalMute(callId, false);
    
    // 上报UNMUTED音频事件
    await voipCall.reportCallAudioEventChange(callId, voipCall.CallAudioEvent.AUDIO_EVENT_UNMUTED);
    hilog.info(0x0000, 'CallDemo', 'Reported UNMUTED audio event');
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', `Failed to handle unmuted: ${error}`);
  }
}

async function performAppInternalMute(callId: string, mute: boolean): Promise<void> {
  // 应用内静音/解除静音逻辑,例如:
  // - 控制音频采集
  // - 更新本地UI状态
  hilog.info(0x0000, 'CallDemo', `Set mute=${mute} for call: ${callId}`);
}
```

### 步骤7: 处理挂断操作

**示例代码**:
```typescript
async function handleHangup(callId: string): Promise<void> {
  try {
    // 在应用内完成挂断逻辑
    await performAppInternalHangup(callId);
    
    // 上报DISCONNECTED状态,系统会取消横幅通知
    await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
    hilog.info(0x0000, 'CallDemo', 'Call hangup and disconnected');
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', `Failed to handle hangup: ${error}`);
  }
}

async function performAppInternalHangup(callId: string): Promise<void> {
  // 应用内挂断逻辑,例如:
  // - 关闭音视频连接
  // - 释放资源
  // - 通知对方用户
  hilog.info(0x0000, 'CallDemo', `Performing internal hangup for call: ${callId}`);
}
```

### 步骤8: 取消注册事件

**说明**: 通话结束后,取消注册事件监听。

**示例代码**:
```typescript
// 解除voipCallUiEvent事件
voipCall.off('voipCallUiEvent');
hilog.info(0x0000, 'CallDemo', 'Unregistered voipCallUiEvent');
```

### 步骤9: 错误处理

**示例代码**:
```typescript
async function reportIncomingCallWithErrorHandling(
  voipCallAttribute: voipCall.VoipCallAttribute
): Promise<void> {
  try {
    const errorReason: voipCall.ErrorReason = await voipCall.reportIncomingCall(voipCallAttribute);
    
    switch (errorReason) {
      case voipCall.ErrorReason.ERROR_NONE:
        hilog.info(0x0000, 'CallDemo', 'Incoming call reported successfully');
        break;
      case voipCall.ErrorReason.CELLULAR_CALL_EXISTS:
        hilog.warn(0x0000, 'CallDemo', 'Cellular call exists, cannot report VoIP call');
        await voipCall.reportIncomingCallError(
          voipCallAttribute.callId,
          voipCall.VoipCallFailureCause.OTHER
        );
        break;
      case voipCall.ErrorReason.VOIP_CALL_EXISTS:
        hilog.warn(0x0000, 'CallDemo', 'Another VoIP call exists');
        await voipCall.reportIncomingCallError(
          voipCallAttribute.callId,
          voipCall.VoipCallFailureCause.ROUTE_BUSY
        );
        break;
      case voipCall.ErrorReason.INVALID_CALL:
        hilog.error(0x0000, 'CallDemo', 'Invalid call parameters');
        break;
      case voipCall.ErrorReason.USER_ANSWER_CELLULAR_FIRST:
        hilog.info(0x0000, 'CallDemo', 'User answered cellular call first');
        break;
      default:
        hilog.error(0x0000, 'CallDemo', `Unknown error: ${errorReason}`);
    }
  } catch (error) {
    hilog.error(0x0000, 'CallDemo', `Exception: ${error}`);
  }
}
```

## 错误码说明

### API错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error | 检查参数类型和格式是否正确 |
| 1007200001 | Invalid parameter value | 验证参数值是否在有效范围内 |
| 1007200002 | Operation failed. Cannot connect to service | 检查系统服务是否正常,重试操作 |
| 1007200003 | System internal error | 系统内部错误,稍后重试或联系系统管理员 |
| 1007200999 | Unknown error code | 未知错误,查看日志或联系技术支持 |

### 上报来电错误原因(ErrorReason)

| 错误原因 | 值 | 说明 | 解决方法 |
|---------|---|------|---------|
| ERROR_NONE | 0 | 无错误,操作成功 | - |
| CELLULAR_CALL_EXISTS | 1 | 当前已存在蜂窝通话 | 等待蜂窝通话结束或提示用户 |
| VOIP_CALL_EXISTS | 2 | 当前已存在其他应用内通话 | 等待其他通话结束或提示用户 |
| INVALID_CALL | 3 | 通话无效,callId未通过校验 | 检查callId格式和有效性 |
| USER_ANSWER_CELLULAR_FIRST | 4 | 用户选择接听蜂窝通话 | 结束当前VoIP通话流程 |

### 来电建立失败原因(VoipCallFailureCause)

| 失败原因 | 值 | 说明 |
|---------|---|------|
| OTHER | 0 | 其他失败原因 |
| ROUTE_BUSY | 1 | 应用线路忙 |
| CONNECTION_FAILED | 2 | 通话连接建立失败 |

## 编译和修复问题

### 依赖声明

在module.json5中配置:
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "abilities": [
      {
        "name": "VoipCallAbility",
        "srcEntry": "./ets/VoipCallAbility.ts"
      }
    ]
  }
}
```

在oh-package.json5中配置:
```json
{
  "dependencies": {
    "@kit.CallServiceKit": "^4.1.0",
    "@kit.ImageKit": "^4.1.0",
    "@kit.PerformanceAnalysisKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: API 11 (4.1.0) 或更高版本
- 开发工具: DevEco Studio 4.0 或更高版本
- 设备支持: Phone、Tablet、Wearable(6.0+)、PC/2in1(6.1.1+)

### 常见编译问题

**问题1: 找不到@kit.CallServiceKit模块**
```
Error: Cannot find module '@kit.CallServiceKit'
```
**解决方法**: 确认HarmonyOS SDK版本 >= API 11,在oh-package.json5中添加依赖。

**问题2: PixelMap创建失败**
```
Error: Failed to create PixelMap
```
**解决方法**: 确保图片数据格式正确,推荐使用image.createPixelMapSync方法,并传入有效的ArrayBuffer和图片尺寸。

**问题3: Ability未正确配置**
```
Error: Ability not found
```
**解决方法**: 在module.json5中正确配置Ability名称,确保与voipCallAttribute.abilityName一致。

**问题4: API调用权限错误**
```
Error: Permission denied
```
**解决方法**: 检查应用是否申请了必要的权限,参考官方文档配置权限声明。

## 常见问题与解决方法

### Q1: 上报来电后没有显示横幅通知
**原因**: 
- showBannerForIncomingCall设置为false
- 应用在后台但未获得必要的权限
- 系统通知权限未授予

**解决方法**:
- 确认voipCallAttribute.showBannerForIncomingCall为true(默认为true)
- 检查应用通知权限设置
- 在系统设置中授予应用通知权限

### Q2: 接收不到用户的UI事件回调
**原因**: 
- 未正确注册voipCallUiEvent事件
- 注册时机不对(在上报来电之后注册)
- callback函数参数类型错误

**解决方法**:
- 在上报来电前注册事件监听
- 使用正确的callback类型:`Callback<VoipCallUiEventInfo>`
- 检查事件名称拼写: 'voipCallUiEvent'

### Q3: 用户头像显示异常或模糊
**原因**: 
- 图片尺寸不符合要求
- 图片字节大小超过限制
- PixelMap创建失败

**解决方法**:
- 推荐头像尺寸: 112x112像素
- 最大尺寸: 221x221像素
- 图片字节大小: < 196608字节
- 使用image.createPixelMapSync正确创建PixelMap

### Q4: 视频来电无法语音接听
**原因**: isVoiceAnswerSupported参数未正确设置

**解决方法**:
```typescript
let voipCallAttribute: voipCall.VoipCallAttribute = {
  // ... 其他参数
  voipCallType: voipCall.VoipCallType.VOIP_CALL_VIDEO,
  isVoiceAnswerSupported: true  // 允许语音接听
};
```

### Q5: 状态上报顺序错误导致横幅不更新
**原因**: 未按推荐的状态序列上报

**解决方法**: 
- 接听流程: RINGING -> ANSWERED -> ACTIVE (推荐)
- 或简化流程: RINGING -> ACTIVE (体验稍差)
- 拒接/挂断: 任意状态 -> DISCONNECTED

### Q6: 多个来电冲突
**原因**: 未正确处理ErrorReason.VOIP_CALL_EXISTS

**解决方法**:
```typescript
if (errorReason === voipCall.ErrorReason.VOIP_CALL_EXISTS) {
  // 提示用户当前有其他通话
  showToast('当前有其他通话,请稍后再试');
  // 上报来电失败
  await voipCall.reportIncomingCallError(callId, voipCall.VoipCallFailureCause.ROUTE_BUSY);
}
```

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "callId": "1234567890",
  "callType": "VOICE",
  "userName": "Callman",
  "currentState": "ACTIVE",
  "apiUsed": [
    "voipCall.on",
    "voipCall.reportIncomingCall",
    "voipCall.reportCallStateChange",
    "voipCall.reportCallAudioEventChange",
    "voipCall.off"
  ],
  "events": [
    {
      "event": "VOIP_CALL_EVENT_VOICE_ANSWER",
      "timestamp": "2026-07-03T10:30:00.000Z"
    },
    {
      "event": "VOIP_CALL_STATE_ANSWERED",
      "timestamp": "2026-07-03T10:30:01.000Z"
    },
    {
      "event": "VOIP_CALL_STATE_ACTIVE",
      "timestamp": "2026-07-03T10:30:02.000Z"
    }
  ]
}
```

## 参考文档

- [API开发指南 - 来电场景](references/incoming-calls-guide.md)
- [API参考说明 - voipCall](references/call-voipcall-reference.md)

## 完整示例代码

- [ArkTS示例 - 语音来电](assets/incoming-call-voice-example.ets)
- [ArkTS示例 - 视频来电](assets/incoming-call-video-example.ets)
- [配置文件示例](assets/module-config.json)

## 测试用例

### 正向测试用例
- [语音来电接听流程测试](tests/test_voice_call_answer.ts): 测试完整的语音来电接听流程
- [视频来电接听流程测试](tests/test_video_call_answer.ts): 测试视频来电接听流程
- [视频来电语音接听测试](tests/test_video_call_voice_answer.ts): 测试视频来电的语音接听选项
- [静音/解除静音测试](tests/test_mute_unmute.ts): 测试通话过程中的静音操作

### 边界测试用例
- [头像尺寸边界测试](tests/test_avatar_size_boundary.ts): 测试头像尺寸在限制边界的情况
- [callId长度边界测试](tests/test_callid_boundary.ts): 测试callId的最大长度
- [并发来电测试](tests/test_concurrent_calls.ts): 测试多个来电同时到达的处理

### 异常测试用例
- [无效callId测试](tests/test_invalid_callid.ts): 测试传入无效callId的错误处理
- [重复上报来电测试](tests/test_duplicate_report.ts): 测试重复上报来电的错误处理
- [未注册事件监听测试](tests/test_no_event_listener.ts): 测试未注册事件监听时的错误处理
- [参数错误测试](tests/test_invalid_parameters.ts): 测试传入错误参数的错误处理