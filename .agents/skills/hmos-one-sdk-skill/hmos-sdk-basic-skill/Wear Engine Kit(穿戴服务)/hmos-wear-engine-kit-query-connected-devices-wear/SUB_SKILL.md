---
name: hmos-wear-engine-kit-query-connected-devices
description: 查询已连接的穿戴设备列表并获取设备信息和操作系统类型，支持获取设备标识、名称、型号等基本信息，适用于穿戴设备应用开发的设备发现和选择场景
---

# 已连接对端设备查询技能

## 功能描述

本技能提供查询用户在穿戴侧已连接的对端设备列表的能力，支持获取设备的详细信息，包括设备随机唯一标识符、设备类型、设备名称、软件版本号、设备型号、是否为智能表以及操作系统类型。建议开发者在使用Wear Engine其他API接口前先实现该接口功能，从已连接的对端设备列表中选定设备进行后续通信。

## 使用场景

### 触发词
- "查询已连接设备"
- "获取穿戴设备列表"
- "获取对端设备"
- "设备发现"
- "选择穿戴设备"

### 能做
- 查询当前已连接且支持wearEngine能力集的穿戴设备列表
- 获取设备的基本信息（设备ID、名称、型号、软件版本等）
- 查询设备的操作系统类型（HarmonyOS/iOS/其他）
- 查询设备是否为智能手表
- 为后续的设备通信、传感器数据获取等功能提供目标设备选择

### 绝不做
- 不处理设备连接/断开连接事件（需要使用其他Monitor API）
- 不获取设备的实时传感器数据
- 不进行设备间的消息通信或文件传输
- 不查询设备的详细硬件能力（需使用isWearEngineCapabilitySupported等接口）

### 补充
- 仅支持Stage模型
- 仅支持Phone和Tablet设备，在其他设备类型中会返回801错误码
- 需要先申请Wear Engine服务并授权
- 需要用户使用HUAWEI ID登录
- 需要用户同意隐私协议

## 调用规范和规则

### 输入约束
- 应用上下文：必须提供有效的Context对象（支持connectServiceExtensionAbility方法）
- 权限要求：需要申请Wear Engine服务权限
- 账户要求：用户必须使用HUAWEI ID登录
- 隐私要求：用户必须同意隐私协议

### 执行约束
- 最大耗时：网络请求超时时间通常为30秒
- API调用频次：无明确限制，但建议避免频繁调用
- 异步模式：使用Promise异步回调

### 内容约束
- 禁止生成：不生成设备连接/断开监听代码
- 禁止使用高危函数：无特殊限制
- 禁止操作：不修改设备系统设置

### 降级约束
- 网络失败：提示用户检查网络连接并重试
- 无设备连接：提示用户先连接穿戴设备
- 权限不足：引导用户授予相应权限
- 未登录：引导用户使用HUAWEI ID登录

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用已申请Wear Engine服务
2. 确认用户已使用HUAWEI ID登录
3. 确认用户已同意隐私协议
4. 确认运行设备为Phone或Tablet

**参数准备**：
```typescript
// 导入必要模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// 声明目标设备变量
let targetDevice: wearEngine.Device | undefined = undefined;
```

### 步骤2：获取DeviceClient对象

**示例代码**：
```typescript
// 获取DeviceClient对象
// this.getUIContext().getHostContext() 表示应用上下文Context对象
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
console.info('Succeeded in getting device client.');
```

**说明**：
- 参数：context为应用上下文，必须是包含connectServiceExtensionAbility方法的Context
- 返回值：DeviceClient对象，用于调用设备相关API
- 错误码：
  - 401：参数错误（必填参数未指定或参数类型错误）
  - 801：能力不支持（非Phone/Tablet设备）
  - 1008509999：内部错误

### 步骤3：查询已连接设备列表

**示例代码**：
```typescript
// 调用getConnectedDevices方法，查询用户已连接的穿戴设备列表
deviceClient.getConnectedDevices().then((devices: wearEngine.Device[]) => {
  console.info(`Succeeded in getting deviceList, deviceList number is ${devices.length}`);
  
  // 检查设备列表是否为空
  if (devices.length === 0) {
    console.warn('No connected devices found.');
    return;
  }
  
  // 从已连接设备列表中选定需要通信的对端设备
  targetDevice = devices[0];
  console.info(`Succeeded in getting target device: ${targetDevice.name}`);
  
  // 查询对端设备的操作系统类型
  let osCategory: wearEngine.OsCategory | undefined = targetDevice.osCategory;
  console.info(`The osCategory of target device is ${osCategory}`);
  
}).catch((error: BusinessError) => {
  // 处理调用失败时捕获到的异常
  console.error(`Failed to get deviceList. Code is ${error.code}, message is ${error.message}`);
});
```

**说明**：
- 返回值：Promise<Device[]>，返回已连接设备数组
- Device对象包含的属性：
  - randomId: string - 设备随机唯一标识符（每次绑定自动生成）
  - category: DeviceCategory - 设备类型（DEFAULT/WATCH/BAND/OTHER_DEVICES）
  - name: string - 设备名称
  - softwareVersion: string - 设备软件版本号
  - model: string - 设备型号
  - isSmartWatch: boolean - 是否为智能表
  - osCategory: OsCategory - 操作系统类型（HARMONYOS/IOS/OTHER_OS，API版本5.1.0+）

### 步骤4：错误处理

```typescript
// 完整的错误处理代码
async function queryConnectedDevices(): Promise<void> {
  try {
    // 获取DeviceClient
    let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
    
    // 查询设备列表
    const devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    
    if (devices.length === 0) {
      console.warn('No connected devices found. Please connect a wearable device first.');
      return;
    }
    
    // 选择目标设备
    const targetDevice = devices[0];
    console.info(`Target device found: ${targetDevice.name}, OS: ${targetDevice.osCategory}`);
    
  } catch (error) {
    const businessError = error as BusinessError;
    
    switch (businessError.code) {
      case 1008500001:
        console.error('Network error. Please check network connection.');
        break;
      case 1008500004:
        console.error('App has not applied for the Wear Engine service.');
        break;
      case 1008500006:
        console.error('User privacy is not agreed.');
        break;
      case 1008500008:
        console.error('Account error. Please login with HUAWEI ID.');
        break;
      case 1008500009:
        console.error('Account error. Failed to obtain account information.');
        break;
      case 1008509999:
        console.error('Internal error. Please try again later.');
        break;
      default:
        console.error(`Unknown error. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
}
```

### 步骤5：降级处理

```typescript
// 降级处理代码
async function queryDevicesWithFallback(): Promise<void> {
  try {
    // 尝试获取设备列表
    const deviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
    const devices = await deviceClient.getConnectedDevices();
    
    if (devices.length > 0) {
      // 成功获取设备列表
      console.info(`Found ${devices.length} connected device(s).`);
      return;
    }
    
    // 设备列表为空的降级处理
    console.warn('No devices connected. Available actions:');
    console.warn('1. Check if Bluetooth is enabled');
    console.warn('2. Pair and connect a wearable device');
    console.warn('3. Ensure the device supports Wear Engine capabilities');
    
  } catch (error) {
    const businessError = error as BusinessError;
    
    // 根据错误类型提供降级方案
    if (businessError.code === 1008500001) {
      // 网络错误降级
      console.warn('Network unavailable. Please check your network connection and retry.');
    } else if (businessError.code === 1008500008 || businessError.code === 1008500009) {
      // 账户错误降级
      console.warn('Please login with HUAWEI ID to use this feature.');
    } else {
      // 其他错误降级
      console.warn('Failed to query devices. Please try again later.');
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型错误 | 检查参数类型和必填参数是否正确 |
| 801 | 能力不支持 | 确认设备类型为Phone或Tablet |
| 1008500001 | 网络错误，网络不可用 | 检查网络连接状态，提示用户检查网络设置 |
| 1008500004 | 应用未申请Wear Engine服务 | 引导开发者申请Wear Engine服务 |
| 1008500006 | 用户隐私未同意 | 引导用户同意隐私协议 |
| 1008500008 | 账户错误，用户未使用HUAWEI ID登录 | 引导用户使用HUAWEI ID登录 |
| 1008500009 | 账户错误，获取HUAWEI ID账户信息失败 | 提示用户检查账户状态并重试 |
| 1008509999 | 内部错误 | 记录日志并提示用户稍后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0",
    "@kit.AbilityKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.0(12)及以上
- 开发环境：DevEco Studio 5.0.0及以上
- 目标设备：Phone、Tablet
- API版本：API 12及以上

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：
1. 确认HarmonyOS SDK版本不低于5.0.0(12)
2. 在build-profile.json5中配置正确的compileSdkVersion
3. 同步项目依赖：File > Sync and Refresh Project

**问题2：getUIContext方法未定义**
```
Error: Property 'getUIContext' does not exist on type 'XXX'
```
**解决方法**：
1. 确认代码运行在UIAbility或UI组件上下文中
2. 使用正确的上下文获取方式：
   - UIAbility中：`this.context`
   - UI组件中：`this.getUIContext().getHostContext()`

**问题3：类型定义错误**
```
Error: Type 'Device' is not defined
```
**解决方法**：
1. 确保正确导入类型：`import { wearEngine } from '@kit.WearEngine'`
2. 使用完整类型名称：`wearEngine.Device`

## 常见问题与解决方法

### Q1：查询设备列表返回为空
**原因**：
- 没有设备连接
- 设备不支持Wear Engine能力集
- 蓝牙未开启

**解决方法**：
- 确认设备已通过蓝牙配对并连接
- 确认设备支持Wear Engine能力
- 检查设备蓝牙开关状态

### Q2：调用API时返回1008500008错误
**原因**：用户未使用HUAWEI ID登录

**解决方法**：
- 引导用户使用HUAWEI ID登录华为账号
- 确认账号状态正常

### Q3：调用API时返回1008500006错误
**原因**：用户未同意隐私协议

**解决方法**：
- 调用AuthClient.requestAuthorization申请权限
- 引导用户同意隐私协议

### Q4：如何选择目标设备
**原因**：设备列表可能包含多个设备，需要选择合适的设备

**解决方法**：
- 根据设备名称、型号筛选
- 根据设备类型（isSmartWatch）筛选
- 根据操作系统类型（osCategory）筛选
- 记录用户选择，下次优先使用

### Q5：如何判断设备是否支持特定能力
**原因**：不同设备支持的能力可能不同

**解决方法**：
- 使用device.isWearEngineCapabilitySupported查询WearEngine能力
- 使用device.isDeviceCapabilitySupported查询设备能力
- 在调用其他API前先查询能力支持情况

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "deviceCount": 1,
  "devices": [
    {
      "randomId": "xxxxx",
      "name": "HUAWEI WATCH",
      "category": "WATCH",
      "model": "WATCH-xxx",
      "softwareVersion": "5.0.0",
      "isSmartWatch": true,
      "osCategory": "HARMONYOS"
    }
  ],
  "apiUsed": [
    "wearEngine.getDeviceClient",
    "DeviceClient.getConnectedDevices"
  ]
}
```

## 参考文档

- [API开发指南](references/watch_query_connected_devices.md)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)

## 完整示例代码

- [ArkTS示例](assets/query_connected_devices.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [成功查询设备列表](tests/test_positive.ts)：测试正常情况下查询设备列表
- [获取设备详细信息](tests/test_positive.ts)：测试获取设备的各项属性信息

### 边界测试用例
- [设备列表为空](tests/test_boundary.ts)：测试无设备连接时的处理
- [单设备连接](tests/test_boundary.ts)：测试只有一个设备连接的情况
- [多设备连接](tests/test_boundary.ts)：测试多个设备连接的情况

### 异常测试用例
- [网络异常](tests/test_exception.ts)：测试网络不可用时的错误处理
- [未登录账号](tests/test_exception.ts)：测试未使用HUAWEI ID登录的错误处理
- [权限未授权](tests/test_exception.ts)：测试隐私协议未同意的错误处理