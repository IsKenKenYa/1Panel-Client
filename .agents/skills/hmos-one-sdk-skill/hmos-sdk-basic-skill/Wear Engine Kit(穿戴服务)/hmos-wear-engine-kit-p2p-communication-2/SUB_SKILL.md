---
name: hmos-wear-engine-kit-p2p-communication
description: 穿戴设备应用间P2P消息与文件传输,支持消息发送、文件传输、应用拉起等功能,消息长度最大4096字节,文件大小最大100MB,适用于穿戴设备与对端设备应用间通信场景
---

# 穿戴设备应用间消息通信技能

## 功能描述

本技能提供穿戴设备应用与对端设备应用之间的P2P(peer-to-peer)通信能力,包括:

- 检测对端设备应用是否安装
- 发送点对点消息(最大4096字节)
- 发送文件(最大100MB)
- 接收对端应用消息
- 接收对端应用文件
- 拉起对端设备应用
- 获取对端应用版本号

## 使用场景

### 触发词
- "穿戴设备消息通信"
- "手表应用间通信"
- "P2P消息传输"
- "穿戴设备文件传输"
- "拉起对端应用"
- "Wear Engine P2P"

### 能做
- 实现穿戴设备与对端设备(手机/平板)应用间的双向消息通信
- 在穿戴设备和已连接的对端设备间传输文件(最大100MB)
- 从穿戴设备拉起对端设备的指定应用
- 查询对端设备应用的安装状态和版本信息
- 注册监听接收对端应用发来的消息和文件

### 绝不做
- 不处理超过4096字节的消息传输(需使用文件传输或分包)
- 不传输超过100MB的文件
- 不在未连接设备时执行通信操作
- 不处理非穿戴设备场景的通信

### 补充
- 使用前需确保对端设备侧已有对应应用
- 对端设备侧应用和穿戴设备应用必须同时处于已启动状态
- 需要先查询已连接设备并选定目标设备
- 消息长度超过4096字节时建议使用文件传输方式或进行消息分包控制

## 调用规范和规则

### 输入约束
- 消息内容长度: [1, 4096)字节
- 文件大小: 最大100MB
- 文件路径: 不能包含'..'
- 设备ID: 必须是有效的randomId(通过getConnectedDevices获取)
- 应用包名: 必须是有效的bundleName
- 应用指纹: 必须是有效的fingerprint或APP ID

### 执行约束
- 最大耗时: 30秒(文件传输可能更长)
- 最大迭代次数: 3次(失败重试)
- API调用频次: 遵循系统限制,建议间隔100ms以上
- 并发限制: 同一类型回调函数最多注册1个

### 内容约束
- 禁止传输敏感信息(密码、密钥等)未加密
- 禁止使用eval、exec等高危函数处理接收内容
- 禁止文件路径遍历攻击(检查'..'等危险字符)
- 禁止传输恶意文件或病毒

### 降级约束
- 网络失败: 提示用户检查设备连接状态,延迟重试
- 文件过大: 拒绝传输并提示文件大小限制(100MB)
- 权限不足: 引导用户进行隐私授权和权限申请
- 应用未安装: 提示用户先安装对端应用
- 设备未连接: 引导用户连接设备后再操作

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查设备连接状态
2. 验证对端应用是否已安装
3. 确认应用权限已授权

**参数准备**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';

let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
```

### 步骤2: 查询已连接设备

**示例代码**:
```typescript
async function getTargetDevice(): Promise<wearEngine.Device | null> {
  try {
    let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    if (devices.length === 0) {
      console.error('No connected devices found');
      return null;
    }
    
    for (let device of devices) {
      let isSupportP2P = await device.isWearEngineCapabilitySupported(wearEngine.WearEngineCapability.P2P_COMMUNICATION);
      if (isSupportP2P) {
        console.info(`Found P2P capable device: ${device.name}`);
        return device;
      }
    }
    
    console.error('No P2P capable device found');
    return null;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get devices. Code: ${err.code}, Message: ${err.message}`);
    return null;
  }
}
```

### 步骤3: 检测对端应用是否安装

**示例代码**:
```typescript
async function checkRemoteAppInstalled(deviceRandomId: string, bundleName: string): Promise<boolean> {
  try {
    let isInstalled: boolean = await p2pClient.isRemoteAppInstalled(deviceRandomId, bundleName);
    console.info(`Remote app ${bundleName} is installed: ${isInstalled}`);
    return isInstalled;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to check remote app. Code: ${err.code}, Message: ${err.message}`);
    return false;
  }
}
```

### 步骤4: 发送消息

**示例代码**:
```typescript
async function sendMessage(deviceRandomId: string, bundleName: string, fingerprint: string, messageContent: string): Promise<void> {
  try {
    let appInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    let textEncoder: util.TextEncoder = new util.TextEncoder();
    let message: wearEngine.P2pMessage = {
      content: textEncoder.encodeInto(messageContent)
    };
    
    let result: wearEngine.P2pResult = await p2pClient.sendMessage(deviceRandomId, appParam, message);
    
    if (result.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
      console.info('Message sent successfully');
    } else {
      console.error(`Message send failed with code: ${result.code}`);
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to send message. Code: ${err.code}, Message: ${err.message}`);
  }
}
```

### 步骤5: 发送文件

**示例代码**:
```typescript
async function sendFile(deviceRandomId: string, bundleName: string, fingerprint: string, filePath: string): Promise<void> {
  let p2pFile: wearEngine.P2pFile | undefined;
  
  try {
    p2pFile = {
      file: fileIo.openSync(filePath)
    };
    
    let appInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    p2pClient.transferFile(deviceRandomId, appParam, p2pFile, (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
      if (error) {
        console.error(`Failed to transfer file. Code: ${error.code}, Message: ${error.message}`);
        return;
      }
      
      if (p2pResult.code) {
        if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
          console.info('File transferred successfully');
        } else {
          console.error(`File transfer failed with code: ${p2pResult.code}`);
        }
      }
      
      if (p2pResult.progress) {
        console.info(`Transfer progress: ${p2pResult.progress}%`);
      }
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to send file. Code: ${err.code}, Message: ${err.message}`);
  } finally {
    if (p2pFile && p2pFile.file) {
      try {
        await fileIo.close(p2pFile.file);
        console.info('File closed successfully');
      } catch (closeError) {
        const err: BusinessError = closeError as BusinessError;
        console.error(`Failed to close file. Code: ${err.code}, Message: ${err.message}`);
      }
    }
  }
}
```

### 步骤6: 接收消息

**示例代码**:
```typescript
async function registerMessageReceiver(deviceRandomId: string, bundleName: string, fingerprint: string): Promise<void> {
  try {
    let appInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    let callback = (p2pMessage: wearEngine.P2pMessage) => {
      console.info(`Received message: ${p2pMessage.content}`);
    };
    
    await p2pClient.registerMessageReceiver(deviceRandomId, appParam, callback);
    console.info('Message receiver registered successfully');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to register message receiver. Code: ${err.code}, Message: ${err.message}`);
  }
}
```

### 步骤7: 接收文件

**示例代码**:
```typescript
async function registerFileReceiver(deviceRandomId: string, bundleName: string, fingerprint: string): Promise<void> {
  try {
    let appInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    let callback = (p2pFile: wearEngine.P2pFile) => {
      console.info('Received file successfully');
    };
    
    await p2pClient.registerFileReceiver(deviceRandomId, appParam, callback);
    console.info('File receiver registered successfully');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to register file receiver. Code: ${err.code}, Message: ${err.message}`);
  }
}
```

### 步骤8: 拉起对端应用

**示例代码**:
```typescript
async function startRemoteApp(deviceRandomId: string, bundleName: string, fingerprint: string): Promise<void> {
  try {
    let remoteAppInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let startConfig: wearEngine.StartConfig = {
      entryType: wearEngine.EntryType.DISTRIBUTED_SERVICE,
      entryName: 'EntryAbility'
    };
    
    let result: wearEngine.P2pResult = await p2pClient.startRemoteApp(deviceRandomId, remoteAppInfo, startConfig);
    
    if (result.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
      console.info('Remote app started successfully');
    } else {
      console.error(`Failed to start remote app with code: ${result.code}`);
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to start remote app. Code: ${err.code}, Message: ${err.message}`);
  }
}
```

### 步骤9: 错误处理

```typescript
function handleP2pError(errorCode: number): string {
  switch (errorCode) {
    case 200:
      return 'Remote app not installed';
    case 201:
      return 'Remote app not running';
    case 203:
      return 'Unknown error';
    case 206:
      return 'Communication failure';
    case 1008500001:
      return 'Network error. Please check network connection';
    case 1008500002:
      return 'No device is bound';
    case 1008500003:
      return 'Device disconnected. Please reconnect device';
    case 1008500004:
      return 'App has not applied for Wear Engine service';
    case 1008500005:
      return 'The HUAWEI ID is not authorized';
    case 1008500006:
      return 'User privacy is not agreed. Please open Health app';
    case 1008500007:
      return 'Device capability not supported';
    case 1008500008:
      return 'Account error. Please login with HUAWEI ID';
    case 1008500010:
      return 'Device ID is invalid. Please get device list again';
    case 1008500011:
      return 'File is invalid. Please check file path';
    default:
      return `Unknown error code: ${errorCode}`;
  }
}
```

### 步骤10: 降级处理

```typescript
async function fallbackCommunication(deviceRandomId: string, bundleName: string, messageContent: string): Promise<void> {
  try {
    let isInstalled = await checkRemoteAppInstalled(deviceRandomId, bundleName);
    if (!isInstalled) {
      console.warn('Remote app not installed, cannot send message');
      return;
    }
    
    await sendMessage(deviceRandomId, bundleName, '', messageContent);
  } catch (error) {
    console.error('Primary communication failed, no fallback available for this scenario');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查必选参数是否传入、参数类型是否正确 |
| 801 | 设备不支持此API | 检查设备是否支持使用的API |
| 1008500001 | 网络错误 | 检查网络配置和设备连接状态 |
| 1008500002 | 无绑定设备 | 检查设备是否已正确连接手机 |
| 1008500003 | 设备未连接 | 检查设备侧与手机侧的蓝牙是否打开,运动健康APP中是否已绑定并连接设备 |
| 1008500004 | 应用未申请Wear Engine服务 | 申请WearEngine服务时勾选兼容选项,在开发者联盟申请WearEngine服务 |
| 1008500005 | 用户未授权 | 确认用户已授权相关权限 |
| 1008500006 | 用户未同意隐私授权 | 引导用户启动运动健康App,进行隐私授权 |
| 1008500007 | 穿戴设备侧能力不支持 | 核查设备能力集 |
| 1008500008 | 账号未登录 | 登录华为账号后再重新调用接口 |
| 1008500009 | 账号异常 | 更换注册地为中国境内账号再操作 |
| 1008500010 | 无效设备ID | 调用getConnectedDevices接口重新获取设备ID |
| 1008500011 | 无效文件 | 检查文件路径是否合法、文件是否存在 |
| 1008500012 | 回调函数过多 | 及时关闭已经不再使用的监听事件 |
| 1008509999 | 内部错误 | 检查应用的签名证书等信息,断开重连设备,在metadata中配置clientId |
| 200 | 对端应用未安装 | 引导用户安装对端应用 |
| 201 | 对端应用未运行 | 引导用户启动对端应用 |
| 203 | 未知错误 | 重试操作或联系技术支持 |
| 206 | 通信失败 | 检查网络连接和设备状态 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "5.0.0(12)",
    "@kit.BasicServicesKit": "5.0.0(12)",
    "@kit.ArkTS": "5.0.0(12)",
    "@kit.CoreFileKit": "5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS: 5.0.0(12)及以上
- DevEco Studio: 5.0及以上
- Stage模型: 仅支持Stage模型

### 常见编译问题

**问题1: 模块导入失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**: 确保项目已配置正确的依赖版本,检查build-profile.json5中的compatibleSdkVersion

**问题2: API不存在**
```
Error: Property 'getP2pClient' does not exist on type 'wearEngine'
```
**解决方法**: 检查API版本是否支持(需要5.0.0(12)及以上),使用canIUse接口判断

**问题3: 设备能力不支持**
```
Error code: 801 - Capability not supported
```
**解决方法**: 使用isWearEngineCapabilitySupported接口检查设备是否支持P2P_COMMUNICATION能力

**问题4: 权限未授权**
```
Error code: 1008500006 - User privacy is not agreed
```
**解决方法**: 引导用户打开运动健康App进行隐私授权

## 常见问题与解决方法

### Q1: 消息发送失败怎么办?
**原因**: 可能是设备未连接、应用未安装、网络错误等
**解决方法**:
- 检查设备连接状态
- 确认对端应用已安装并运行
- 检查网络连接
- 查看错误码并针对性处理

### Q2: 文件传输进度如何获取?
**原因**: 文件传输使用callback回调方式
**解决方法**:
- 在transferFile的callback中监听progress字段
- progress字段返回0-100的进度值
- 可根据进度实现进度条显示

### Q3: 如何取消文件传输?
**原因**: 文件传输过程中需要取消
**解决方法**:
- 调用cancelFileTransfer接口
- 传入相同的设备ID、应用参数和文件对象
- 注意文件对象需与传输时一致

### Q4: 接收消息时回调函数如何管理?
**原因**: 同一类型回调函数注册过多会报错
**解决方法**:
- 保证回调函数的生命周期延长至取消监听时
- 及时调用unregisterMessageReceiver取消不需要的监听
- 取消监听时传入与注册时相同的回调函数对象

### Q5: 如何处理消息长度超过限制?
**原因**: 消息长度限制为4096字节
**解决方法**:
- 方案1: 使用文件传输方式(支持最大100MB)
- 方案2: 进行消息分包,分多次发送
- 方案3: 对消息内容进行压缩处理

### Q6: 对端应用如何被拉起?
**原因**: 需要在对端应用中配置metadata
**解决方法**:
- 在对端应用的module.json5中配置wearEngineRemoteAppNameList
- 配置wearEngineUIAbilityName指定要拉起的Ability
- 配置wearEngineAwaitRegisterReceiver等待订阅完成

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "deviceUsed": "device_random_id",
  "remoteApp": "bundle_name",
  "communicationType": "message|file",
  "resultCode": 207,
  "messageSize": "1024 bytes",
  "fileSize": "5 MB",
  "transferProgress": "100%",
  "apiUsed": [
    "getConnectedDevices",
    "isRemoteAppInstalled",
    "sendMessage",
    "transferFile",
    "registerMessageReceiver",
    "registerFileReceiver"
  ]
}
```

## 参考文档

- [API开发指南](references/watch_p2p_communication.md)
- [API参考说明](references/wearengine_api.md)
- [API错误码](references/wearengine_api_error_code.md)
- [已连接对端设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/watch_query_connected_devices)
- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/configuration_client_id)

## 完整示例代码

- [ArkTS完整示例](assets/p2p_communication_example.ets)
- [配置文件示例](assets/module.json5配置示例.json)

## 测试用例

### 正向测试用例
- [发送小消息测试](tests/test_send_small_message.ets): 测试发送1024字节以内消息
- [发送文件测试](tests/test_send_file.ets): 测试发送小于100MB文件
- [接收消息测试](tests/test_receive_message.ets): 测试接收对端消息
- [拉起应用测试](tests/test_start_remote_app.ets): 测试拉起对端应用

### 边界测试用例
- [消息长度边界测试](tests/test_message_boundary.ets): 测试4095字节消息
- [文件大小边界测试](tests/test_file_boundary.ets): 测试接近100MB文件
- [多设备测试](tests/test_multiple_devices.ets): 测试多个已连接设备场景

### 异常测试用例
- [设备未连接测试](tests/test_device_disconnected.ets): 测试设备未连接时的处理
- [应用未安装测试](tests/test_app_not_installed.ets): 测试对端应用未安装的处理
- [网络异常测试](tests/test_network_error.ets): 测试网络异常时的降级处理
- [权限未授权测试](tests/test_permission_denied.ets): 测试权限不足时的处理