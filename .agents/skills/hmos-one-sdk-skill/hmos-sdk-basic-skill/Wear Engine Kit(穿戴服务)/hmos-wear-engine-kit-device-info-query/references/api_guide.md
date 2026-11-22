# API开发指南

## 文档来源

本文档来源于HarmonyOS官方开发指南，提供穿戴设备信息查询的完整开发流程。

原文链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_device_info

## 功能概述

穿戴设备信息查询功能包含以下三个核心能力：

1. **查询穿戴设备是否支持某种WearEngine能力集**
2. **查询穿戴设备是否支持某种Device能力集**
3. **查询设备SN(序列号)**

## 开发准备

### 权限申请

在使用Wear Engine服务前，需要：

1. 在开发者联盟申请接入Wear Engine服务
   - 参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply

2. 申请相应权限：
   - **设备基础信息权限**：用于查询WearEngine能力集和Device能力集
   - **设备标识符权限**(受限开放)：用于查询设备SN，需要获得用户授权

### 导入模块

```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
```

## 开发步骤

### 一、查询穿戴设备是否支持某种WearEngine能力集

#### 前提条件
- 已申请设备基础信息权限

#### 实现流程

1. **获取DeviceClient对象**

```typescript
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
```

2. **获取已连接设备列表**

```typescript
let deviceList: wearEngine.Device[] = [];
deviceClient.getConnectedDevices().then(devices => {
  deviceList = devices;
  console.info(`Succeeded in getting deviceList, devices number is ${deviceList.length}`);
}).catch((error: BusinessError) => {
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```

3. **从设备列表中选取目标设备**

根据业务需求从设备列表中选择需要操作的设备。

4. **查询WearEngine能力集支持情况**

```typescript
if (deviceList.length > 0) {
  let targetDevice: wearEngine.Device = deviceList[0];
  targetDevice.isWearEngineCapabilitySupported(wearEngine.WearEngineCapability.P2P_COMMUNICATION).then((isSupportP2P) => {
    console.info(`Succeeded in checking p2p capability, result is ${isSupportP2P}`);
  }).catch((error: BusinessError) => {
    console.error(`Failed to check p2p capability. Code is ${error.code}, message is ${error.message}`);
  });
}
```

#### 支持的WearEngine能力类型

| 能力名称 | 枚举值 | 说明 |
|---------|--------|------|
| P2P_COMMUNICATION | 1 | P2P(peer-to-peer)通信能力 |
| MONITOR | 2 | Monitor能力(设备状态监控) |
| NOTIFICATION | 3 | Notify能力(通知发送) |
| SENSOR | 4 | Sensor能力(传感器数据获取) |

### 二、查询穿戴设备是否支持某种Device能力集

#### 前提条件
- 已申请设备基础信息权限

#### 实现流程

1. **获取DeviceClient对象**

```typescript
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
```

2. **获取已连接设备列表**

```typescript
let deviceList: wearEngine.Device[] = [];
deviceClient.getConnectedDevices().then(devices => {
  deviceList = devices;
  console.info(`Succeeded in getting deviceList, devices number is ${deviceList.length}`);
}).catch((error: BusinessError) => {
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```

3. **从设备列表中选取目标设备**

4. **查询Device能力集支持情况**

```typescript
if (deviceList.length > 0) {
  let targetDevice: wearEngine.Device = deviceList[0];
  targetDevice.isDeviceCapabilitySupported(wearEngine.DeviceCapability.APP_INSTALLATION).then((isSupportInstall) => {
    console.info(`Succeeded in checking install app capability, result is ${isSupportInstall}`);
  }).catch((error: BusinessError) => {
    console.error(`Failed to check install app capability. Code is ${error.code}, message is ${error.message}`);
  });
}
```

#### 支持的Device能力类型

| 能力名称 | 枚举值 | 说明 |
|---------|--------|------|
| APP_INSTALLATION | 14 | 支持应用安装能力 |
| CBT_I | 128 | CBTI数字疗法能力 |

### 三、查询设备SN

#### 前提条件
- 已申请设备标识符权限(受限开放)
- 已获得用户授权

#### 实现流程

1. **获取DeviceClient对象**

```typescript
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
```

2. **获取已连接设备列表**

```typescript
let deviceList: wearEngine.Device[] = [];
deviceClient.getConnectedDevices().then(devices => {
  deviceList = devices;
  console.info(`Succeeded in getting deviceList, devices number is ${deviceList.length}`);
}).catch((error: BusinessError) => {
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```

3. **从设备列表中选取目标设备**

4. **查询设备SN**

```typescript
if (deviceList.length > 0) {
  let targetDevice: wearEngine.Device = deviceList[0];
  targetDevice.getSerialNumber().then((sn) => {
    console.info(`Succeeded in getting device SN, result is ${sn}`);
  }).catch((error: BusinessError) => {
    console.error(`Failed to get device SN. Code is ${error.code}, message is ${error.message}`);
  });
}
```

## 注意事项

1. 所有查询操作需要在设备已连接状态下进行
2. 需要用户已登录华为账号
3. 需要用户已同意隐私协议
4. 仅支持Stage模型，可在Phone、Tablet设备上调用
5. 查询结果建议缓存，避免频繁重复查询

## 参考链接

- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)
- [wearEngine API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)