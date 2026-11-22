---
name: hmos-wear-engine-kit-p2p-communication
description: 实现手机应用与穿戴设备应用间的点对点消息通信和文件传输，支持消息收发、文件传输、应用拉起、应用安装检测，消息长度限制4096字节，文件大小限制100MB，适用于音乐播放控制、数据同步、文件共享场景
---

# 应用间消息通信技能

## 功能描述

本技能提供手机侧应用与穿戴设备侧应用之间的点对点通信能力，包括：

- **消息通信**：发送和接收自定义报文消息，消息长度限制4096字节
- **文件传输**：发送和接收文件，文件大小限制100MB，支持传输进度监控和取消传输
- **应用管理**：检测穿戴设备应用安装状态、获取应用版本号、拉起设备侧应用
- **双向通信**：订阅接收穿戴设备侧发送的消息和文件

## 使用场景

### 触发词
- "手机和穿戴设备通信"
- "发送消息到手表"
- "穿戴设备应用通信"
- "点对点消息"
- "P2P通信"
- "向手表发送文件"
- "拉起手表应用"
- "检测手表应用是否安装"
- "手机与手表数据同步"

### 能做
- 实现手机应用向穿戴设备应用发送简短消息（≤4096字节）
- 实现手机应用向穿戴设备应用发送文件（≤100MB）
- 实现手机应用接收穿戴设备应用发送的消息和文件
- 检测穿戴设备是否已安装指定应用
- 获取穿戴设备应用的版本号
- 拉起穿戴设备侧的应用
- 监控文件传输进度和取消文件传输

### 绝不做
- 不处理超过4096字节的消息（需分包或使用文件传输）
- 不传输超过100MB的文件
- 不处理非Wear Engine支持的穿戴设备
- 不在未申请设备基础信息权限的情况下执行通信
- 不处理手机App和穿戴设备App未同时启动的通信请求

### 补充
- 使用前必须在开发者联盟申请设备基础信息权限
- 穿戴设备必须支持应用安装能力（DeviceCapability.APP_INSTALLATION）
- 手机App和穿戴设备App必须同时处于启动状态
- 穿戴设备侧应用需要实现对应的接收功能
- 支持通过startRemoteApp方法拉起未启动的穿戴设备App

## 调用规范和规则

### 输入约束
- **消息长度**：最大4096字节，超出需使用文件传输或消息分包
- **文件大小**：最大100MB
- **文件路径**：不能包含'..'字符
- **设备标识**：必须使用有效的Device.randomId
- **应用信息**：必须提供正确的bundleName和fingerprint

### 执行约束
- **权限要求**：必须在开发者联盟申请设备基础信息权限
- **设备连接**：设备必须已连接且支持Wear Engine能力
- **应用状态**：手机App和穿戴设备App必须同时启动
- **能力检测**：发送前需检测设备是否支持APP_INSTALLATION能力
- **网络状态**：设备必须处于连接状态

### 内容约束
- **禁止发送**：空消息、超长消息、非法文件路径
- **禁止操作**：向不支持应用安装能力的设备发送
- **禁止传输**：系统文件、敏感数据文件
- **必须校验**：文件路径合法性、应用包名有效性

### 降级约束
- **消息超长**：提示用户使用文件传输或分包发送
- **文件过大**：提示用户拆分文件或压缩后传输
- **设备断开**：提示用户检查设备连接状态
- **权限不足**：提示用户申请设备基础信息权限
- **应用未安装**：提示用户安装穿戴设备侧应用
- **网络失败**：提供重试机制和错误提示

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否已申请设备基础信息权限
2. 检查设备是否支持应用安装能力
3. 检查穿戴设备侧应用是否已安装
4. 验证设备连接状态

**参数准备**：
```typescript
// 导入必要模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';

// 设置设备侧应用参数
let appInfo: wearEngine.AppInfo = {
  bundleName: 'com.example.wearapp',  // 穿戴设备应用包名
  fingerprint: ''  // 应用指纹
};

let appParam: wearEngine.P2pAppParam = {
  remoteApp: appInfo,
  transformLocalAppInfo: false  // 默认false，不转换包名指纹
};
```

### 步骤2：获取必要客户端对象

**获取客户端对象**：
```typescript
// 获取设备客户端
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());

// 获取P2P客户端
let p2pClient: wearEngine.P2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());

// 获取已连接设备列表
let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
```

### 步骤3：选择目标设备

**设备选择逻辑**：
```typescript
let targetDevice: wearEngine.Device;

for (let device of devices) {
  // 检查设备是否支持应用安装能力
  let isSupported = await device.isDeviceCapabilitySupported(wearEngine.DeviceCapability.APP_INSTALLATION);
  if (isSupported) {
    targetDevice = device;
    break;
  }
}

if (!targetDevice) {
  throw new Error('未找到支持应用安装能力的设备');
}
```

### 步骤4：检测应用安装状态

**检测应用是否已安装**：
```typescript
let remoteBundleName: string = 'com.example.wearapp';

p2pClient.isRemoteAppInstalled(targetDevice.randomId, remoteBundleName).then((isInstall) => {
  if (isInstall) {
    console.info('应用已安装在穿戴设备上');
  } else {
    console.warn('应用未安装，请先安装穿戴设备侧应用');
  }
}).catch((error: BusinessError) => {
  console.error(`检测应用安装失败。错误码：${error.code}, 错误信息：${error.message}`);
});
```

### 步骤5：发送点对点消息

**发送消息示例**：
```typescript
// 构造消息内容（长度限制4096字节）
let messageContent: string = 'Hello from phone!';
let textEncoder: util.TextEncoder = new util.TextEncoder();
let message: wearEngine.P2pMessage = {
  content: textEncoder.encodeInto(messageContent)
};

// 发送消息
p2pClient.sendMessage(targetDevice.randomId, appParam, message).then((p2pResult) => {
  if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
    console.info('消息发送成功');
  } else {
    console.warn(`消息发送失败，错误码：${p2pResult.code}`);
  }
}).catch((error: BusinessError) => {
  console.error(`发送消息失败。错误码：${error.code}, 错误信息：${error.message}`);
});
```

### 步骤6：发送文件

**发送文件示例**：
```typescript
try {
  // 打开文件（路径不能包含'..'）
  let filePath: string = '/data/local/tmp/test.txt';
  let p2pFile: wearEngine.P2pFile = {
    file: fileIo.openSync(filePath)
  };
  
  // 发送文件并监控进度
  p2pClient.transferFile(targetDevice.randomId, appParam, p2pFile, 
    (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
      if (error) {
        console.error(`文件传输失败。错误码：${error.code}, 错误信息：${error.message}`);
        return;
      }
      
      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('文件传输成功');
      } else {
        console.warn(`文件传输失败，错误码：${p2pResult.code}`);
      }
      
      if (p2pResult.progress) {
        console.info(`传输进度：${p2pResult.progress}%`);
      }
    }
  );
  
  // 关闭文件
  fileIo.close(p2pFile.file);
} catch (error) {
  console.error(`文件操作失败。错误码：${error.code}, 错误信息：${error.message}`);
}
```

### 步骤7：取消文件传输

**取消文件传输示例**：
```typescript
p2pClient.cancelFileTransfer(targetDevice.randomId, appParam, p2pFile).then((p2pResult) => {
  if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
    console.info('文件传输已取消');
  }
}).catch((error: BusinessError) => {
  console.error(`取消文件传输失败。错误码：${error.code}, 错误信息：${error.message}`);
});
```

### 步骤8：订阅接收消息

**订阅接收消息示例**：
```typescript
let messageCallback = (p2pMessage: wearEngine.P2pMessage) => {
  let textDecoder: util.TextDecoder = new util.TextDecoder('utf-8');
  let receivedMessage: string = textDecoder.decodeToString(p2pMessage.content);
  console.info(`收到消息：${receivedMessage}`);
};

// 注册消息接收监听
p2pClient.registerMessageReceiver(targetDevice.randomId, appParam, messageCallback).then(() => {
  console.info('消息接收监听已注册');
}).catch((error: BusinessError) => {
  console.error(`注册消息接收失败。错误码：${error.code}, 错误信息：${error.message}`);
});

// 取消消息接收监听（需传入同一个回调对象）
p2pClient.unregisterMessageReceiver(targetDevice.randomId, appParam, messageCallback).then(() => {
  console.info('消息接收监听已取消');
}).catch((error: BusinessError) => {
  console.error(`取消消息接收失败。错误码：${error.code}, 错误信息：${error.message}`);
});
```

### 步骤9：订阅接收文件

**订阅接收文件示例**：
```typescript
let fileCallback = (p2pFile: wearEngine.P2pFile) => {
  if (p2pFile.file) {
    console.info('收到文件');
    // 处理接收到的文件
    fileIo.close(p2pFile.file);
  }
};

// 注册文件接收监听
p2pClient.registerFileReceiver(targetDevice.randomId, appParam, fileCallback).then(() => {
  console.info('文件接收监听已注册');
}).catch((error: BusinessError) => {
  console.error(`注册文件接收失败。错误码：${error.code}, 错误信息：${error.message}`);
});
```

### 步骤10：拉起穿戴设备应用

**拉起应用示例**：
```typescript
let remoteBundleName: string = 'com.example.wearapp';

// 拉起穿戴设备侧应用
p2pClient.startRemoteApp(targetDevice.randomId, remoteBundleName).then((p2pResult) => {
  if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
    console.info('穿戴设备应用已拉起');
  } else {
    console.warn(`拉起应用失败，错误码：${p2pResult.code}`);
  }
}).catch((error: BusinessError) => {
  console.error(`拉起应用失败。错误码：${error.code}, 错误信息：${error.message}`);
});
```

### 步骤11：获取应用版本号

**获取版本号示例**：
```typescript
let remoteBundleName: string = 'com.example.wearapp';

p2pClient.getRemoteAppVersion(targetDevice.randomId, remoteBundleName).then((version) => {
  console.info(`穿戴设备应用版本号：${version}`);
}).catch((error: BusinessError) => {
  console.error(`获取应用版本号失败。错误码：${error.code}, 错误信息：${error.message}`);
});
```

### 步骤12：错误处理

**统一错误处理**：
```typescript
try {
  // 执行通信操作
  await p2pClient.sendMessage(targetDevice.randomId, appParam, message);
} catch (error) {
  let businessError: BusinessError = error as BusinessError;
  
  switch (businessError.code) {
    case 1008500001:
      console.error('网络错误，请检查设备连接状态');
      break;
    case 1008500002:
      console.error('没有绑定设备，请先绑定穿戴设备');
      break;
    case 1008500003:
      console.error('设备已断开连接');
      break;
    case 1008500004:
      console.error('应用未申请Wear Engine服务');
      break;
    case 1008500005:
      console.error('HUAWEI ID未授权');
      break;
    case 1008500006:
      console.error('用户隐私未同意');
      break;
    case 1008500007:
      console.error('设备不支持此能力');
      break;
    case 1008500008:
      console.error('用户未登录HUAWEI ID');
      break;
    case 1008500010:
      console.error('设备ID无效');
      break;
    case 1008500011:
      console.error('文件无效');
      break;
    default:
      console.error(`未知错误。错误码：${businessError.code}, 错误信息：${businessError.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数是否完整、类型是否正确、参数值是否有效 |
| 801 | 能力不支持 | 检查设备是否支持该能力，使用canIUse接口判断 |
| 1008500001 | 网络错误 | 检查网络连接状态，确保设备网络正常 |
| 1008500002 | 没有绑定设备 | 在运动健康App中绑定穿戴设备 |
| 1008500003 | 设备断开连接 | 确保设备处于连接状态，重启运动健康App |
| 1008500004 | 应用未申请Wear Engine服务 | 在开发者联盟申请接入Wear Engine服务 |
| 1008500005 | HUAWEI ID未授权 | 使用HUAWEI ID登录并授权 |
| 1008500006 | 用户隐私未同意 | 用户需同意隐私协议 |
| 1008500007 | 设备能力不支持 | 检查设备是否支持APP_INSTALLATION能力 |
| 1008500008 | 未登录HUAWEI ID | 登录HUAWEI ID账号 |
| 1008500009 | 获取账号信息失败 | 检查HUAWEI ID账号状态 |
| 1008500010 | 设备ID无效 | 使用正确的Device.randomId |
| 1008500011 | 文件无效 | 检查文件路径是否合法，文件是否存在 |
| 1008500012 | 回调函数过多 | 减少同类型的回调函数注册数量 |
| 1008509999 | 内部错误 | 重试操作，如持续失败请联系技术支持 |

## 编译和修复问题

### 依赖声明

**模块导入**：
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
```

**权限配置**：
在module.json5中配置权限：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_DISTRIBUTED_DEVICE_INFO"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS版本：5.0.0(12)及以上
- 设备类型：Phone、Tablet（其他设备返回801错误码）
- 开发模型：Stage模型
- 系统能力：SystemCapability.Health.WearEngine

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：确保HarmonyOS SDK版本>=5.0.0(12)，检查项目配置

**问题2：权限错误**
```
Error: Permission denied
```
**解决方法**：在module.json5中添加设备信息权限，并在开发者联盟申请Wear Engine服务

**问题3：设备不支持**
```
Error: Capability not supported (801)
```
**解决方法**：使用canIUse接口检查设备是否支持SystemCapability.Health.WearEngine

**问题4：文件路径错误**
```
Error: File is invalid (1008500011)
```
**解决方法**：确保文件路径不包含'..'字符，使用绝对路径

## 常见问题与解决方法

### Q1：消息发送失败
**原因**：消息长度超过4096字节限制
**解决方法**：
- 使用文件传输功能发送大消息
- 将消息分包发送
- 压缩消息内容

### Q2：文件传输失败
**原因**：文件大小超过100MB或文件路径包含'..'字符
**解决方法**：
- 压缩文件或拆分为多个小文件
- 使用合法的文件路径（不含'..'）
- 检查文件是否存在

### Q3：设备连接失败
**原因**：设备未绑定或已断开连接
**解决方法**：
- 在运动健康App中绑定穿戴设备
- 确保设备处于连接状态
- 重启运动健康App和穿戴设备

### Q4：应用未安装
**原因**：穿戴设备侧未安装对应应用
**解决方法**：
- 在穿戴设备上安装对应应用
- 使用startRemoteApp拉起应用前先检测安装状态

### Q5：接收消息失败
**原因**：未注册消息接收监听或穿戴设备应用未启动
**解决方法**：
- 使用registerMessageReceiver注册消息接收监听
- 确保穿戴设备应用处于启动状态
- 使用startRemoteApp拉起穿戴设备应用

### Q6：权限不足
**原因**：未申请设备基础信息权限
**解决方法**：
- 在开发者联盟申请Wear Engine服务
- 申请设备基础信息权限（Permission.DEVICE_IDENTIFIER）
- 用户同意隐私协议

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operationType": "sendMessage|transferFile|receiveMessage|receiveFile",
  "deviceId": "device_random_id",
  "remoteAppName": "com.example.wearapp",
  "result": {
    "code": 0,
    "message": "操作成功"
  },
  "progress": 100,
  "dataSize": 1024,
  "apiUsed": [
    "wearEngine.getDeviceClient",
    "wearEngine.getP2pClient",
    "deviceClient.getConnectedDevices",
    "device.isDeviceCapabilitySupported",
    "p2pClient.sendMessage",
    "p2pClient.transferFile"
  ]
}
```

## 参考文档

- [应用间消息通信开发指南](references/p2p_communication_guide.md)
- [wearEngine API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)
- [已连接穿戴设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices)
- [目标设备选择](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection)

## 完整示例代码

- [发送消息完整示例](assets/send_message_example.ets)
- [发送文件完整示例](assets/transfer_file_example.ets)
- [接收消息完整示例](assets/receive_message_example.ets)
- [接收文件完整示例](assets/receive_file_example.ets)
- [完整通信示例](assets/p2p_communication_complete.ets)

## 测试用例

### 正向测试用例
- [发送短消息测试](tests/test_send_short_message.py)：测试发送长度<4096字节的消息
- [发送文件测试](tests/test_send_file.py)：测试发送大小<100MB的文件
- [接收消息测试](tests/test_receive_message.py)：测试接收穿戴设备发送的消息
- [应用安装检测测试](tests/test_check_app_install.py)：测试检测应用安装状态

### 边界测试用例
- [消息长度边界测试](tests/test_message_boundary.py)：测试4096字节边界值
- [文件大小边界测试](tests/test_file_boundary.py)：测试100MB边界值
- [多设备选择测试](tests/test_multi_device.py)：测试多个设备的选择逻辑

### 异常测试用例
- [网络断开测试](tests/test_network_disconnect.py)：测试网络断开时的处理
- [设备断开测试](tests/test_device_disconnect.py)：测试设备断开时的处理
- [权限不足测试](tests/test_permission_denied.py)：测试权限不足时的处理
- [应用未安装测试](tests/test_app_not_install.py)：测试应用未安装时的处理
- [文件路径非法测试](tests/test_invalid_file_path.py)：测试非法文件路径的处理