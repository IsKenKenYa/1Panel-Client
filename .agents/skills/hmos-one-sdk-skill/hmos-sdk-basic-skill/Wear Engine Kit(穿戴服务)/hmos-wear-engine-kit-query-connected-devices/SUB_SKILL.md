---
name: hmos-wear-engine-kit-query-connected-devices
description: 查询已连接穿戴设备列表+支持Wear Engine能力集+仅返回已连接设备+适用于设备查询、设备状态监控场景
---

# 已连接穿戴设备查询技能

## 功能描述

本技能用于查询当前已连接且支持Wear Engine能力集的穿戴设备列表。通过调用Wear Engine Kit提供的API接口，获取与手机侧运动健康App处于连接状态的穿戴设备信息，包括设备随机ID、设备类型、设备名称、软件版本等详细信息。

**核心能力**：
- 获取DeviceClient客户端对象
- 查询已连接的穿戴设备列表
- 返回设备详细信息（随机ID、类型、名称、版本等）

**技术特点**：
- 异步调用模式（Promise）
- 仅支持Stage模型
- 需要在开发者联盟申请设备基础信息权限
- 返回支持Wear Engine能力集的设备

**适用场景**：
- 在使用其他Wear Engine API前先查询设备连接状态
- 设备管理、设备状态监控
- 多设备场景下选择目标设备

## 使用场景

### 触发词
- "查询已连接的穿戴设备"
- "获取穿戴设备列表"
- "查询设备连接状态"
- "获取DeviceClient"
- "getConnectedDevices"
- "Wear Engine设备查询"

### 能做
- 查询当前已连接且支持Wear Engine能力的穿戴设备列表
- 获取设备的详细信息（randomId、name、category、softwareVersion等）
- 在使用其他Wear Engine功能前验证设备连接状态
- 为后续的设备操作提供设备ID（randomId）

### 绝不做
- 不返回未连接的设备
- 不返回不支持Wear Engine能力集的设备
- 不提供设备绑定功能（需要在运动健康App中绑定）
- 不支持Android/iOS平台调用
- 不支持FA模型

### 补充
- **前提条件**：需要在开发者联盟申请设备基础信息权限
- **设备要求**：设备需支持Wear Engine能力集
- **连接状态**：设备需与手机侧运动健康App处于连接状态
- **账号要求**：用户需登录华为账号且账号注册地为中国境内
- **API版本**：起始版本5.0.0(12)

## 调用规范和规则

### 输入约束
- 上下文参数：必须提供有效的Context对象（仅支持包含connectServiceExtensionAbility方法的Context）
- 调用时机：建议在使用其他Wear Engine API前先调用此接口
- 权限要求：需要在开发者联盟申请设备基础信息权限
- 账号状态：用户必须登录华为账号

### 执行约束
- 最大耗时：5秒（网络请求超时）
- 重试次数：建议失败后最多重试2次，每次间隔1秒
- API调用频次：无限制，但建议合理控制调用频率
- 执行环境：仅支持Stage模型，Phone/Tablet设备

### 内容约束
- 禁止在没有申请权限的情况下调用
- 禁止在用户未登录华为账号时调用
- 禁止在设备未连接时进行后续设备操作
- 禁止忽略错误处理
- 禁止在UI主线程进行阻塞式等待

### 降级约束
- **网络失败**：提示用户检查网络连接，建议用户切换网络后重试
- **权限不足**：引导用户到运动健康App进行隐私授权或申请相应权限
- **账号未登录**：提示用户登录华为账号后重试
- **无设备连接**：提示用户在运动健康App中绑定并连接设备
- **设备不支持**：提示用户设备不支持Wear Engine能力集

## 调用流程和步骤

### 步骤1：前置校验

**权限检查**：
1. 确认已在开发者联盟申请设备基础信息权限
2. 确认用户已登录华为账号且账号注册地为中国境内
3. 确认用户已在运动健康App中同意隐私授权

**环境检查**：
```typescript
// 检查设备是否支持Wear Engine能力集
import { wearEngine } from '@kit.WearEngine';

if (!canIUse('SystemCapability.Health.WearEngine')) {
  console.error('当前设备不支持Wear Engine能力集');
  return;
}
```

### 步骤2：导入必要模块

```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤3：获取DeviceClient对象

```typescript
// 获取DeviceClient对象
// this.getUIContext().getHostContext() 表示应用上下文Context对象
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
```

**参数说明**：
- `context`：应用上下文对象，仅支持包含connectServiceExtensionAbility方法的Context（如UIAbilityContext）

**返回值**：
- `DeviceClient`：设备客户端对象，包含设备相关方法

### 步骤4：查询已连接设备列表

```typescript
// 创建设备列表存储返回结果
let deviceList: wearEngine.Device[] = [];

// 调用getConnectedDevices方法查询设备
deviceClient.getConnectedDevices().then((devices: wearEngine.Device[]) => {
  deviceList = devices;
  console.info(`成功获取设备列表，设备数量: ${deviceList.length}`);
  
  // 处理设备列表
  if (deviceList.length === 0) {
    console.warn('当前没有已连接的穿戴设备');
  } else {
    // 遍历设备信息
    deviceList.forEach((device: wearEngine.Device, index: number) => {
      console.info(`设备${index + 1}:`);
      console.info(`  随机ID: ${device.randomId}`);
      console.info(`  设备名称: ${device.name}`);
      console.info(`  设备类型: ${device.category}`);
      console.info(`  软件版本: ${device.softwareVersion}`);
      console.info(`  设备型号: ${device.model}`);
      console.info(`  是否为智能表: ${device.isSmartWatch}`);
    });
  }
}).catch((error: BusinessError) => {
  // 错误处理
  console.error(`获取设备列表失败。错误码: ${error.code}, 错误信息: ${error.message}`);
});
```

### 步骤5：错误处理

```typescript
deviceClient.getConnectedDevices().then((devices: wearEngine.Device[]) => {
  deviceList = devices;
  console.info(`成功获取设备列表，设备数量: ${deviceList.length}`);
}).catch((error: BusinessError) => {
  switch (error.code) {
    case 1008500001:
      console.error('网络错误，请检查网络连接');
      // 引导用户检查网络
      break;
    case 1008500004:
      console.error('应用未申请Wear Engine服务，请在开发者联盟申请');
      // 引导申请服务
      break;
    case 1008500006:
      console.error('用户未同意隐私授权，请引导用户打开运动健康App进行授权');
      // 引导用户授权
      break;
    case 1008500008:
      console.error('账号未登录，请登录华为账号后重试');
      // 引导用户登录
      break;
    case 1008500009:
      console.error('账号异常，请使用中国境内注册的华为账号');
      // 提示账号要求
      break;
    case 1008509999:
      console.error('内部错误，请重试或联系技术支持');
      // 内部错误处理
      break;
    default:
      console.error(`未知错误: ${error.code}, ${error.message}`);
  }
});
```

### 步骤6：完整示例代码

```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 查询已连接的穿戴设备列表
 * @returns Promise<wearEngine.Device[]> 设备列表
 */
async function queryConnectedDevices(): Promise<wearEngine.Device[]> {
  try {
    // 步骤1：获取DeviceClient对象
    const deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
    
    // 步骤2：查询已连接设备
    const devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    
    // 步骤3：处理返回结果
    console.info(`成功获取设备列表，设备数量: ${devices.length}`);
    
    if (devices.length === 0) {
      console.warn('当前没有已连接的穿戴设备');
      return [];
    }
    
    // 步骤4：输出设备详细信息
    devices.forEach((device: wearEngine.Device, index: number) => {
      console.info(`设备${index + 1}:`);
      console.info(`  随机ID: ${device.randomId}`);
      console.info(`  设备名称: ${device.name || '未知'}`);
      console.info(`  设备类型: ${device.category}`);
      console.info(`  软件版本: ${device.softwareVersion || '未知'}`);
      console.info(`  设备型号: ${device.model || '未知'}`);
      console.info(`  是否为智能表: ${device.isSmartWatch}`);
    });
    
    return devices;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`获取设备列表失败。错误码: ${businessError.code}, 错误信息: ${businessError.message}`);
    throw businessError;
  }
}

// 调用示例
queryConnectedDevices().then((devices) => {
  // 设备列表获取成功，可以进行后续操作
  if (devices.length > 0) {
    const targetDevice = devices[0];
    console.info(`选择设备: ${targetDevice.name}`);
    // 使用设备进行后续操作...
  }
}).catch((error: BusinessError) => {
  console.error('查询设备失败:', error.message);
});
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必选参数未传入或参数类型错误 | 检查传入的Context对象是否正确 |
| 801 | 设备不支持此API | 检查设备是否支持Wear Engine能力集 |
| 1008500001 | 网络错误，网络不可用 | 检查网络连接，切换网络后重试 |
| 1008500004 | 应用未申请Wear Engine服务 | 在开发者联盟申请Wear Engine服务并勾选兼容选项 |
| 1008500006 | 用户未同意隐私授权 | 引导用户打开运动健康App进行隐私授权 |
| 1008500008 | 账号未登录 | 登录华为账号后重试 |
| 1008500009 | 账号异常，无法获取华为账号信息 | 使用中国境内注册的华为账号（不包含港澳台） |
| 1008509999 | 内部错误 | 检查应用签名证书配置，断开重连设备，或在metadata中配置clientId |

## 编译和修复问题

### 依赖声明

在`oh-package.json5`中声明依赖：
```json
{
  "dependencies": {
    "@kit.WearEngine": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求

- **HarmonyOS版本**：5.0.0(12)及以上
- **开发模型**：Stage模型
- **设备类型**：Phone、Tablet
- **系统能力**：SystemCapability.Health.WearEngine

### 权限配置

在`module.json5`中配置权限：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.HEALTH_DEVICE_BASELINE_INFO"
      }
    ]
  }
}
```

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：确保HarmonyOS SDK版本为5.0.0(12)及以上，并检查`oh-package.json5`中的依赖配置。

**问题2：Context类型错误**
```
Error: Type 'Context' is not assignable to type 'common.Context'
```
**解决方法**：使用`this.getUIContext().getHostContext()`获取正确的Context对象，或使用`this.context`（UIAbilityContext）。

**问题3：权限未配置**
```
Error: Permission denied
```
**解决方法**：在`module.json5`中添加`ohos.permission.HEALTH_DEVICE_BASELINE_INFO`权限，并在开发者联盟申请相应权限。

## 常见问题与解决方法

### Q1：获取设备列表为空
**原因**：
- 设备未与手机连接
- 设备不支持Wear Engine能力集
- 运动健康App未绑定设备

**解决方法**：
- 在运动健康App中确认设备已绑定并连接
- 确认设备支持Wear Engine能力集
- 检查设备蓝牙连接状态

### Q2：提示"应用未申请Wear Engine服务"
**原因**：
- 未在开发者联盟申请Wear Engine服务
- 申请服务时未勾选兼容选项

**解决方法**：
- 前往开发者联盟申请Wear Engine服务
- 申请时勾选兼容选项
- 确认应用的签名证书与云端配置一致

### Q3：提示"用户未同意隐私授权"
**原因**：用户从未打开过运动健康App或未同意隐私授权

**解决方法**：
- 引导用户启动运动健康App
- 确认用户已同意隐私授权

### Q4：提示"账号未登录"或"账号异常"
**原因**：
- 用户未登录华为账号
- 华为账号注册地非中国境内

**解决方法**：
- 引导用户登录华为账号
- 使用中国境内注册的华为账号（不包含港澳台）

### Q5：设备randomId会变化
**原因**：randomId是设备每次绑定自动生成的随机标识符

**解决方法**：
- 不要持久化存储randomId
- 每次使用前都重新调用getConnectedDevices获取最新的randomId

## 输出结果报告

执行完成后返回以下信息：

```json
{
  "status": "success",
  "deviceCount": 2,
  "devices": [
    {
      "randomId": "device_random_id_1",
      "name": "HUAWEI WATCH GT 4",
      "category": 2,
      "softwareVersion": "4.0.0.123",
      "model": "ARA-AL00",
      "isSmartWatch": true
    },
    {
      "randomId": "device_random_id_2",
      "name": "HUAWEI Band 9",
      "category": 3,
      "softwareVersion": "3.0.0.456",
      "model": "ADS-BL00",
      "isSmartWatch": false
    }
  ],
  "apiUsed": [
    "wearEngine.getDeviceClient",
    "deviceClient.getConnectedDevices"
  ]
}
```

## 参考文档

- [API开发指南 - 已连接穿戴设备查询](references/query_connected_devices_guide.md)
- [API参考说明 - wearEngine](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)
- [错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)

## 完整示例代码

- [ArkTS示例代码](assets/query_connected_devices.ets)
- [完整工程示例](assets/query_connected_devices_demo.ets)

## 测试用例

### 正向测试用例
- [正常查询设备列表](tests/test_positive.ts)：设备已连接且有支持Wear Engine的设备
- [空设备列表](tests/test_positive.ts)：设备未连接时返回空列表

### 边界测试用例
- [多设备场景](tests/test_boundary.ts)：多个设备同时连接
- [设备连接断开](tests/test_boundary.ts)：查询过程中设备断开连接

### 异常测试用例
- [网络错误](tests/test_exception.ts)：网络不可用场景
- [权限不足](tests/test_exception.ts)：未申请相应权限
- [账号未登录](tests/test_exception.ts)：用户未登录华为账号