# API参考说明

## 文档来源

本文档来源于HarmonyOS官方API参考文档，提供wearEngine模块的详细API说明。

原文链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

## 模块概述

**模块名称**：wearEngine(穿戴设备能力开放)

**起始版本**：5.0.0(12)

**系统能力**：SystemCapability.Health.WearEngine

**功能说明**：
本模块提供手机与穿戴设备侧的交互能力。应用可调用模块内接口实现如下功能：
- 获取与当前设备已连接配对的设备列表、与对端设备互通消息互送文件等
- 查询穿戴设备状态、向穿戴设备发送模板化通知、接收穿戴设备传感器的相关数据等

**模型约束**：仅可在Stage模型下使用

**设备约束**：在Phone、Tablet中可正常调用，在其他设备类型中返回801错误码

## 核心API接口

### 1. wearEngine.getDeviceClient

**接口定义**：
```typescript
getDeviceClient(context: common.Context): DeviceClient
```

**功能**：获取Device模块的客户端

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| context | common.Context | 是 | Context上下文，仅支持包含connectServiceExtensionAbility方法的Context |

**返回值**：
| 类型 | 说明 |
|------|------|
| DeviceClient | Device客户端，存储了Device模块的相关方法 |

**错误码**：
| 错误码ID | 错误信息 |
|---------|---------|
| 401 | Parameter error. Mandatory parameters left unspecified or incorrect parameter types |
| 1008509999 | Internal error |

### 2. DeviceClient.getConnectedDevices

**接口定义**：
```typescript
getConnectedDevices(): Promise<Device[]>
```

**功能**：获取当前已连接且支持wearEngine能力集的设备

**返回值**：
| 类型 | 说明 |
|------|------|
| Promise<Device[]> | Promise对象，返回设备列表 |

**错误码**：
| 错误码ID | 错误信息 |
|---------|---------|
| 1008500001 | Network error. The network is unavailable |
| 1008500004 | App has not applied for the Wear Engine service |
| 1008500006 | User privacy is not agreed |
| 1008500008 | Account error. The user has not logged in with HUAWEI ID |
| 1008500009 | Account error. Failed to obtain account information with HUAWEI ID |
| 1008509999 | Internal error |

### 3. Device类

**属性**：
| 名称 | 类型 | 只读 | 可选 | 说明 |
|------|------|------|------|------|
| randomId | string | 否 | 否 | 设备随机唯一标识符，每次绑定自动生成 |
| category | DeviceCategory | 否 | 是 | 设备类型 |
| name | string | 否 | 是 | 设备名称 |
| softwareVersion | string | 否 | 是 | 设备软件版本号 |
| model | string | 否 | 是 | 设备型号 |
| isSmartWatch | boolean | 否 | 是 | 设备是否为智能表 |
| osCategory | OsCategory | 否 | 是 | 设备的操作系统类别(5.1.0(18)起) |

### 4. Device.isWearEngineCapabilitySupported

**接口定义**：
```typescript
isWearEngineCapabilitySupported(capability: WearEngineCapability): Promise<boolean>
```

**功能**：查询设备是否支持指定的WearEngine能力集

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| capability | WearEngineCapability | 是 | 指定的WearEngine能力 |

**返回值**：
| 类型 | 说明 |
|------|------|
| Promise<boolean> | Promise对象，返回是否支持指定能力。true：支持，false：不支持 |

**错误码**：
| 错误码ID | 错误信息 |
|---------|---------|
| 401 | Parameter error |
| 801 | Capability not supported |
| 1008500001 | Network error |
| 1008500002 | No device is bound |
| 1008500003 | Device disconnected |
| 1008500004 | App has not applied for the Wear Engine service |
| 1008500006 | User privacy is not agreed |
| 1008500008 | Account error. The user has not logged in with HUAWEI ID |
| 1008500009 | Account error. Failed to obtain account information |
| 1008509999 | Internal error |

### 5. Device.isDeviceCapabilitySupported

**接口定义**：
```typescript
isDeviceCapabilitySupported(capability: DeviceCapability): Promise<boolean>
```

**功能**：查询设备是否支持指定的Device能力集

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| capability | DeviceCapability | 是 | 指定的Device能力 |

**返回值**：
| 类型 | 说明 |
|------|------|
| Promise<boolean> | Promise对象，返回是否支持指定能力。true：支持，false：不支持 |

**错误码**：同isWearEngineCapabilitySupported

### 6. Device.getSerialNumber

**接口定义**：
```typescript
getSerialNumber(): Promise<string>
```

**功能**：查询设备的序列号(SN)

**返回值**：
| 类型 | 说明 |
|------|------|
| Promise<string> | Promise对象，返回设备SN |

**错误码**：
| 错误码ID | 错误信息 |
|---------|---------|
| 801 | Capability not supported |
| 1008500001 | Network error |
| 1008500002 | No device is bound |
| 1008500003 | Device disconnected |
| 1008500004 | App has not applied for the Wear Engine service |
| 1008500005 | The HUAWEI ID is not authorized |
| 1008500006 | User privacy is not agreed |
| 1008500008 | Account error. The user has not logged in with HUAWEI ID |
| 1008500009 | Account error. Failed to obtain account information |
| 1008509999 | Internal error |

## 枚举类型

### WearEngineCapability

**功能**：WearEngine能力集枚举类型

| 名称 | 值 | 说明 |
|------|----|------|
| P2P_COMMUNICATION | 1 | P2P(peer-to-peer)能力 |
| MONITOR | 2 | Monitor能力 |
| NOTIFICATION | 3 | Notify能力 |
| SENSOR | 4 | Sensor能力 |

### DeviceCapability

**功能**：Device能力集枚举类型

| 名称 | 值 | 说明 |
|------|----|------|
| APP_INSTALLATION | 14 | 支持应用安装能力 |
| CBT_I | 128 | CBTI数字疗法能力 |

### DeviceCategory

**功能**：设备类型枚举类

| 名称 | 值 | 说明 |
|------|----|------|
| DEFAULT | 1 | 手机或平板类型 |
| WATCH | 2 | 手表类型 |
| BAND | 3 | 手环类型 |
| OTHER_DEVICES | 255 | 其它设备类型 |

### Permission

**功能**：权限枚举类型

| 名称 | 值 | 说明 |
|------|----|------|
| USER_STATUS | 2 | 获取用户状态权限 |
| MOTION_SENSOR | 3 | 获取运动传感器数据权限 |
| HEALTH_SENSOR | 4 | 获取人体传感器数据权限 |
| DEVICE_IDENTIFIER | 6 | 获取已连接穿戴设备的序列号 |

## 权限说明

### 设备基础信息权限
- 用于查询设备能力集(WearEngine和Device能力)
- 在开发者联盟申请

### 设备标识符权限(受限开放)
- 用于查询设备序列号(SN)
- 需要用户在华为健康应用中授权
- 属于敏感权限，受限开放

## 使用限制

1. 仅支持Stage模型
2. 仅在Phone、Tablet设备上可正常调用
3. 需要申请Wear Engine服务
4. 需要用户登录华为账号
5. 需要用户同意隐私协议
6. 设备需已连接并配对

## 完整API文档

详细的API说明请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api