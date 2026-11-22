---
name: hmos-wear-engine-kit-device-selection
description: 从已连接的穿戴设备列表中选择目标设备，支持按设备类型、WearEngine能力集、Device能力集三种方式筛选，适用于多设备场景下的设备定位和选择
---

# 目标设备选择技能

## 功能描述

本技能提供从已连接穿戴设备列表中选择目标设备的能力，支持三种选择策略：
1. **按设备类型选择**：根据设备的`DeviceCategory`字段（WATCH/BAND/OTHER_DEVICES）筛选目标设备
2. **按WearEngine能力集选择**：根据设备支持的`WearEngineCapability`能力集筛选目标设备
3. **按Device能力集选择**：根据设备支持的`DeviceCapability`能力集筛选目标设备

当已连接设备列表中包含多个设备时，本技能帮助开发者根据业务需求正确挑选合适的目标设备。

## 使用场景

### 触发词
- "选择目标设备"
- "挑选穿戴设备"
- "筛选已连接设备"
- "根据设备类型选择设备"
- "根据能力集选择设备"
- "目标设备选择"

### 能做
- 从已连接设备列表中按设备类型（手表/手环/其他）筛选目标设备
- 从已连接设备列表中按WearEngine能力集（P2P_COMMUNICATION/MONITOR/NOTIFICATION/SENSOR）筛选目标设备
- 从已连接设备列表中按Device能力集（APP_INSTALLATION/CBT_I）筛选目标设备
- 提供设备选择的错误处理和异常降级方案
- 处理设备未找到、设备不支持指定能力等异常情况

### 绝不做
- 不处理设备连接和配对流程（由其他技能负责）
- 不修改设备属性或状态
- 不执行设备间的数据传输操作
- 不处理单个设备的场景（无需选择）

### 补充
- 需要先调用"已连接穿戴设备查询"技能获取设备列表
- 设备能力查询需要设备保持连接状态
- 部分设备能力查询可能需要特定权限

## 调用规范和规则

### 输入约束
- 设备列表：必须是通过`getConnectedDevices()`获取的有效设备数组
- 设备列表长度：至少包含1个设备，建议不超过10个设备
- 设备类型筛选参数：`DeviceCategory`枚举值（WATCH/BAND/OTHER_DEVICES）
- 能力集筛选参数：`WearEngineCapability`或`DeviceCapability`枚举值
- 能力查询超时：建议设置3-5秒超时

### 执行约束
- 最大耗时：单次能力查询不超过5秒
- 最大迭代次数：设备列表遍历不超过10次
- 异步调用：能力查询接口为异步，需使用`async/await`或`Promise`
- 错误重试：能力查询失败建议重试1次

### 内容约束
- 禁止生成：设备连接代码、设备配对代码
- 禁止操作：直接修改设备状态、发送数据到设备
- 禁止假设：不假设设备一定支持某项能力，必须通过API查询确认
- 日志输出：必须包含设备ID、查询结果等关键信息

### 降级约束
- 设备列表为空：返回错误提示"无可选设备，请先连接穿戴设备"
- 所有设备都不满足条件：返回错误提示"未找到满足条件的设备"
- 能力查询失败：记录错误日志，跳过该设备继续查询其他设备
- 网络异常：提示网络错误，建议检查网络连接和华为账号登录状态

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备列表是否为空（`deviceList.length > 0`）
2. 检查设备列表是否为数组类型
3. 确认已获取必要的权限（如需要查询设备信息）

**参数准备**：
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

// 设备列表（假设已通过getConnectedDevices获取）
let deviceList: wearEngine.Device[] = [...];

// 选择策略参数
// 策略1: 按设备类型
let targetCategory: wearEngine.DeviceCategory = wearEngine.DeviceCategory.WATCH;

// 策略2: 按WearEngine能力集
let requiredCapability: wearEngine.WearEngineCapability = wearEngine.WearEngineCapability.MONITOR;

// 策略3: 按Device能力集
let requiredDeviceCapability: wearEngine.DeviceCapability = wearEngine.DeviceCapability.APP_INSTALLATION;
```

### 步骤2：选择目标设备

**策略1：按设备类型选择**

```typescript
async function selectDeviceByCategory(
  deviceList: wearEngine.Device[],
  category: wearEngine.DeviceCategory
): Promise<wearEngine.Device> {
  // 参数校验
  if (!deviceList || deviceList.length === 0) {
    throw new Error('设备列表为空，无法选择目标设备');
  }

  // 声明目标设备
  let targetDevice: wearEngine.Device | null = null;

  // 遍历设备列表，查找匹配类型的设备
  for (let index = 0; index < deviceList.length; index++) {
    const device = deviceList[index];
    
    // 检查设备类型是否匹配
    if (device.category === category) {
      targetDevice = device;
      console.info(`找到目标设备: 设备名称=${device.name}, 设备类型=${device.category}, 设备ID=${device.randomId}`);
      break;
    }
  }

  // 如果未找到目标设备，抛出错误
  if (!targetDevice) {
    throw new Error(`未找到类型为 ${category} 的设备`);
  }

  return targetDevice;
}
```

**策略2：按WearEngine能力集选择**

```typescript
async function selectDeviceByWearEngineCapability(
  deviceList: wearEngine.Device[],
  capability: wearEngine.WearEngineCapability
): Promise<wearEngine.Device> {
  // 参数校验
  if (!deviceList || deviceList.length === 0) {
    throw new Error('设备列表为空，无法选择目标设备');
  }

  // 声明目标设备
  let targetDevice: wearEngine.Device | null = null;

  // 遍历设备列表，查找支持指定能力的设备
  for (let index = 0; index < deviceList.length; index++) {
    const device = deviceList[index];
    
    try {
      // 查询设备是否支持指定能力
      const isSupported = await device.isWearEngineCapabilitySupported(capability);
      
      if (isSupported) {
        targetDevice = device;
        console.info(`找到支持 ${capability} 能力的设备: 设备名称=${device.name}, 设备ID=${device.randomId}`);
        break;
      }
    } catch (error) {
      // 能力查询失败，记录错误并继续查询其他设备
      const err = error as BusinessError;
      console.error(`查询设备 ${device.name} 的能力失败: Code=${err.code}, Message=${err.message}`);
      continue;
    }
  }

  // 如果未找到目标设备，抛出错误
  if (!targetDevice) {
    throw new Error(`未找到支持 ${capability} 能力的设备`);
  }

  return targetDevice;
}
```

**策略3：按Device能力集选择**

```typescript
async function selectDeviceByDeviceCapability(
  deviceList: wearEngine.Device[],
  capability: wearEngine.DeviceCapability
): Promise<wearEngine.Device> {
  // 参数校验
  if (!deviceList || deviceList.length === 0) {
    throw new Error('设备列表为空，无法选择目标设备');
  }

  // 声明目标设备
  let targetDevice: wearEngine.Device | null = null;

  // 遍历设备列表，查找支持指定能力的设备
  for (let index = 0; index < deviceList.length; index++) {
    const device = deviceList[index];
    
    try {
      // 查询设备是否支持指定能力
      const isSupported = await device.isDeviceCapabilitySupported(capability);
      
      if (isSupported) {
        targetDevice = device;
        console.info(`找到支持 ${capability} 能力的设备: 设备名称=${device.name}, 设备ID=${device.randomId}`);
        break;
      }
    } catch (error) {
      // 能力查询失败，记录错误并继续查询其他设备
      const err = error as BusinessError;
      console.error(`查询设备 ${device.name} 的能力失败: Code=${err.code}, Message=${err.message}`);
      continue;
    }
  }

  // 如果未找到目标设备，抛出错误
  if (!targetDevice) {
    throw new Error(`未找到支持 ${capability} 能力的设备`);
  }

  return targetDevice;
}
```

### 步骤3：错误处理

```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

async function selectTargetDeviceWithErrorHandling(
  deviceList: wearEngine.Device[],
  category?: wearEngine.DeviceCategory,
  wearEngineCapability?: wearEngine.WearEngineCapability,
  deviceCapability?: wearEngine.DeviceCapability
): Promise<wearEngine.Device> {
  try {
    // 根据传入参数选择不同的筛选策略
    if (category !== undefined) {
      return await selectDeviceByCategory(deviceList, category);
    } else if (wearEngineCapability !== undefined) {
      return await selectDeviceByWearEngineCapability(deviceList, wearEngineCapability);
    } else if (deviceCapability !== undefined) {
      return await selectDeviceByDeviceCapability(deviceList, deviceCapability);
    } else {
      throw new Error('未指定设备筛选条件');
    }
  } catch (error) {
    const err = error as BusinessError;
    
    // 根据错误码进行不同处理
    switch (err.code) {
      case 401:
        console.error('参数错误: 请检查参数类型和必填参数');
        throw new Error('参数错误，请检查输入参数');
        
      case 801:
        console.error('能力不支持: 当前设备不支持此能力');
        throw new Error('当前设备不支持所需能力');
        
      case 1008500001:
        console.error('网络错误: 网络不可用');
        throw new Error('网络错误，请检查网络连接');
        
      case 1008500002:
        console.error('设备未绑定: 没有绑定设备');
        throw new Error('设备未绑定，请先绑定穿戴设备');
        
      case 1008500003:
        console.error('设备已断开: 设备连接已断开');
        throw new Error('设备已断开连接，请重新连接设备');
        
      case 1008500004:
        console.error('应用未申请服务: 应用未申请Wear Engine服务');
        throw new Error('应用未申请Wear Engine服务');
        
      case 1008500006:
        console.error('用户隐私未同意: 用户未同意隐私协议');
        throw new Error('请先同意用户隐私协议');
        
      case 1008500008:
        console.error('账号错误: 用户未登录华为账号');
        throw new Error('请先登录华为账号');
        
      case 1008500009:
        console.error('账号错误: 获取华为账号信息失败');
        throw new Error('获取华为账号信息失败，请重试');
        
      case 1008509999:
        console.error('内部错误: Wear Engine内部错误');
        throw new Error('系统内部错误，请稍后重试');
        
      default:
        console.error(`未知错误: Code=${err.code}, Message=${err.message}`);
        throw new Error(`选择设备失败: ${err.message}`);
    }
  }
}
```

### 步骤4：降级处理

```typescript
async function selectTargetDeviceWithFallback(
  deviceList: wearEngine.Device[],
  preferredCategory: wearEngine.DeviceCategory,
  fallbackCategory?: wearEngine.DeviceCategory
): Promise<wearEngine.Device> {
  try {
    // 优先选择首选类型的设备
    return await selectDeviceByCategory(deviceList, preferredCategory);
  } catch (error) {
    console.warn(`未找到 ${preferredCategory} 类型的设备，尝试降级方案`);
    
    // 如果提供了备选类型，尝试选择备选设备
    if (fallbackCategory !== undefined) {
      try {
        const fallbackDevice = await selectDeviceByCategory(deviceList, fallbackCategory);
        console.info(`已选择备选类型设备: ${fallbackCategory}`);
        return fallbackDevice;
      } catch (fallbackError) {
        console.error('降级方案也失败，无法找到合适的设备');
        throw new Error(`未找到 ${preferredCategory} 或 ${fallbackCategory} 类型的设备`);
      }
    }
    
    // 如果没有备选方案，返回第一个可用设备
    if (deviceList.length > 0) {
      console.warn('使用默认策略: 返回第一个可用设备');
      return deviceList[0];
    }
    
    // 所有方案都失败
    throw new Error('无法选择目标设备，设备列表为空');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数类型是否正确，必填参数是否已提供 |
| 801 | 能力不支持 | 当前设备不支持所需能力，尝试使用其他设备或其他能力 |
| 1008500001 | 网络错误 | 检查网络连接是否正常，确保网络可用 |
| 1008500002 | 设备未绑定 | 先绑定穿戴设备，再进行设备选择 |
| 1008500003 | 设备已断开 | 重新连接穿戴设备 |
| 1008500004 | 应用未申请服务 | 在开发者后台申请Wear Engine服务 |
| 1008500006 | 用户隐私未同意 | 引导用户同意隐私协议 |
| 1008500008 | 未登录华为账号 | 引导用户登录华为账号 |
| 1008500009 | 获取账号信息失败 | 稍后重试或重新登录华为账号 |
| 1008509999 | 内部错误 | 系统内部错误，稍后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS: 5.0.0(12) 及以上版本
- DevEco Studio: 最新版本
- Node.js: 14.x 及以上版本

### 常见编译问题

**问题1：找不到@kit.WearEngine模块**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：
1. 确认HarmonyOS SDK版本不低于5.0.0(12)
2. 在`build-profile.json5`中添加依赖：
```json
{
  "dependencies": {
    "@kit.WearEngine": "^5.0.0"
  }
}
```

**问题2：Device类型错误**
```
Error: Property 'category' does not exist on type 'Device'
```
**解决方法**：
1. 确认`Device`对象是通过`getConnectedDevices()`获取的
2. 检查TypeScript版本是否支持最新的API定义

**问题3：异步调用错误**
```
Error: await is only valid in async function
```
**解决方法**：
确保包含`await`的函数声明为`async`函数：
```typescript
async function selectDevice() {
  const device = await selectDeviceByCategory(deviceList, category);
}
```

## 常见问题与解决方法

### Q1：设备列表为空怎么办？
**原因**：没有已连接的穿戴设备或获取设备列表失败
**解决方法**：
1. 确认穿戴设备已开机并与手机配对
2. 检查蓝牙连接状态
3. 确认应用已获取必要的权限
4. 检查华为账号登录状态

### Q2：能力查询失败怎么办？
**原因**：设备不支持该能力或网络/账号问题
**解决方法**：
1. 检查错误码，根据错误码采取相应措施
2. 确认设备型号是否支持该能力
3. 检查网络连接是否正常
4. 确认华为账号已登录

### Q3：如何选择最合适的设备？
**原因**：多个设备同时满足条件时的选择策略不明确
**解决方法**：
1. 明确业务需求，确定首选和备选筛选条件
2. 实现优先级排序逻辑（如设备连接强度、电量等）
3. 使用降级方案，当首选设备不可用时选择备选设备

### Q4：设备能力查询耗时较长怎么办？
**原因**：能力查询为异步操作，且可能受网络影响
**解决方法**：
1. 设置合理的超时时间（建议3-5秒）
2. 并发查询多个设备的能力（使用Promise.all）
3. 实现查询缓存机制，避免重复查询
4. 提供用户友好的加载提示

### Q5：如何在多设备场景下优化选择性能？
**原因**：遍历查询所有设备能力效率较低
**解决方法**：
1. 先按设备类型快速筛选，减少需要查询能力的设备数量
2. 使用Promise.all并发查询多个设备的能力
3. 实现设备能力缓存，减少重复查询
4. 根据业务场景选择最优的筛选策略

## 输出结果报告

执行完成后输出以下信息：

```typescript
interface DeviceSelectionResult {
  status: 'success' | 'error';
  device?: wearEngine.Device;
  errorMessage?: string;
  errorCode?: number;
  selectionStrategy: 'category' | 'wearEngineCapability' | 'deviceCapability';
  queryTime?: number; // 查询耗时（毫秒）
}

// 成功示例
{
  "status": "success",
  "device": {
    "randomId": "device-123",
    "category": "WATCH",
    "name": "Huawei Watch GT",
    "softwareVersion": "2.0.0",
    "model": "WATCH-GT",
    "isSmartWatch": true
  },
  "selectionStrategy": "category",
  "queryTime": 1234
}

// 失败示例
{
  "status": "error",
  "errorMessage": "未找到类型为 WATCH 的设备",
  "errorCode": 1008500003,
  "selectionStrategy": "category",
  "queryTime": 500
}
```

## 参考文档

- [目标设备选择开发指南](references/we-device-selection.md)
- [WearEngine API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)
- [已连接穿戴设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices)
- [穿戴设备信息查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_device_info)

## 完整示例代码

- [ArkTS示例 - 按设备类型选择](assets/select_by_category.ets)
- [ArkTS示例 - 按WearEngine能力集选择](assets/select_by_wear_engine_capability.ets)
- [ArkTS示例 - 按Device能力集选择](assets/select_by_device_capability.ets)
- [ArkTS示例 - 综合示例](assets/device_selection_example.ets)

## 测试用例

### 正向测试用例
- [测试用例1：成功选择手表类型设备](tests/test_positive_category.ets) - 测试在包含手表设备的列表中成功选择手表设备
- [测试用例2：成功选择支持MONITOR能力的设备](tests/test_positive_capability.ets) - 测试在包含支持MONITOR能力设备的列表中成功选择设备

### 边界测试用例
- [测试用例1：设备列表仅包含一个设备](tests/test_boundary_single_device.ets) - 测试在只有一个设备的场景下的选择逻辑
- [测试用例2：多个设备都满足条件](tests/test_boundary_multiple_match.ets) - 测试在多个设备都满足条件时选择第一个匹配设备

### 异常测试用例
- [测试用例1：设备列表为空](tests/test_exception_empty_list.ets) - 测试设备列表为空时的错误处理
- [测试用例2：没有匹配的设备类型](tests/test_exception_no_match.ets) - 测试没有匹配设备类型时的错误处理
- [测试用例3：能力查询失败](tests/test_exception_query_failed.ets) - 测试能力查询失败时的降级处理
- [测试用例4：网络异常](tests/test_exception_network.ets) - 测试网络异常时的错误处理