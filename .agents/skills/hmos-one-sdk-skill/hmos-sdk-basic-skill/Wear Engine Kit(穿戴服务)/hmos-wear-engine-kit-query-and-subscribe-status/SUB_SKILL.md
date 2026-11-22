---
name: hmos-wear-engine-kit-query-and-subscribe-status
description: 查询穿戴设备状态信息并订阅状态变化事件,支持电量、充电、佩戴、设备模式等状态查询和订阅,需申请设备基础信息权限与USER_STATUS权限,适用于健康监测、设备管理、运动提醒场景
---

# 状态查询与订阅技能

## 功能描述

本技能提供穿戴设备状态查询与订阅能力,实现手机侧应用对穿戴设备各类状态的实时监控。支持查询电量状态、充电状态、佩戴状态、设备模式、可用存储空间等指标,同时支持订阅设备连接状态变化、低电量告警、心率告警、佩戴状态变化等事件。通过MonitorClient模块提供的API接口,开发者可以在手机侧应用中获取穿戴设备的实时状态信息,并根据状态变化执行相应业务逻辑。

**核心能力**:
- 查询设备状态:电量、充电、佩戴、设备模式、可用空间
- 订阅状态变化:连接状态、电量降低、充电状态、佩戴状态、心率告警、设备模式切换
- 取消订阅监听:解除已注册的状态变化监听

**适用场景**:健康管理应用实时监控佩戴状态、运动提醒应用订阅心率告警、设备管理应用显示电量与充电状态、低功耗应用根据设备模式调整策略

## 使用场景

### 触发词
- "查询穿戴设备状态"
- "订阅穿戴设备状态变化"
- "查询设备电量"
- "订阅佩戴状态"
- "监控心率告警"
- "查询设备充电状态"
- "订阅设备连接状态"
- "取消订阅设备状态"

### 能做
- 查询穿戴设备的电量状态、充电状态、佩戴状态、设备模式、可用存储空间
- 订阅穿戴设备的连接状态变化、电量降低事件、充电状态变化、佩戴状态变化、心率告警、设备模式切换
- 取消已订阅的设备状态变化监听
- 根据设备状态执行业务逻辑调整

### 绝不做
- 不支持同时查询多个状态(一次只能查询一个状态指标)
- 不处理超出MonitorClient模块范围的状态查询
- 不直接操作穿戴设备应用(仅查询和订阅状态)
- 不替代穿戴设备侧应用的功能实现

### 补充
- 查询和订阅佩戴状态、心率告警需要申请USER_STATUS权限(仅限企业开发者)
- 设备电量、充电、佩戴、心率告警状态查询需确保穿戴设备和华为运动健康App处于连接状态
- 订阅事件的回调函数对象必须保持生命周期延长至取消订阅时,否则可能导致订阅失败或无法正常取消
- 取消订阅时必须传入与订阅时相同的回调函数对象
- 穿戴设备侧无对应应用时,手机侧应用也可使用此能力获取设备状态

## 调用规范和规则

### 输入约束
- deviceRandomId:必须是有效的已连接设备随机标识符,长度限制为字符串类型
- MonitorItem:必须是有效的状态枚举值(WEAR_STATUS、POWER_STATUS、CHARGE_STATUS、AVAILABLE_STORAGE_SPACE、POWER_MODE)
- MonitorEvent:必须是有效的事件枚举值(EVENT_CONNECTION_STATUS_CHANGED、EVENT_BATTERY_LEVEL_DROPPED、EVENT_WEAR_STATUS_CHANGED、EVENT_HEART_RATE_ALARM、EVENT_CHARGE_STATUS_CHANGED、EVENT_POWER_MODE_CHANGED)
- callback:订阅回调函数必须是Function类型,且生命周期需延长至取消订阅时
- 同一设备同一事件类型最多注册有限数量的回调函数(系统限制)

### 执行约束
- 最大耗时:单次查询或订阅操作最大耗时10秒
- 最大迭代次数:单次调用无迭代限制
- API调用频次:建议查询操作间隔至少1秒,避免频繁查询
- 状态查询一次只能查询一个指标,不支持批量查询

### 内容约束
- 禁止生成:非MonitorClient模块的API调用代码
- 禁止使用高危函数:无特殊高危函数限制
- 禁止操作:禁止在未获取权限情况下调用接口、禁止使用无效的deviceRandomId、禁止在设备未连接状态下查询电量/充电/佩戴/心率告警状态

### 降级约束
- 网络失败:提示用户检查网络连接并重试
- 设备未连接:提示用户在华为运动健康App中查看设备连接状态,调用getConnectedDevices检查连接
- 权限未申请:引导用户申请相应权限(设备基础信息权限或USER_STATUS权限)
- 用户未授权:提示用户授予相应权限授权
- 回调函数过多:提示用户取消部分订阅后再重新订阅

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 验证应用已在开发者联盟申请设备基础信息权限或USER_STATUS权限
2. 验证用户已授予相应权限授权(通过AuthClient.getAuthorization检查)
3. 验证穿戴设备已连接(通过DeviceClient.getConnectedDevices检查)
4. 验证设备支持Monitor能力(通过Device.isWearEngineCapabilitySupported检查)

**参数准备**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

async function prepareMonitorParams(): Promise<void> {
  // 获取DeviceClient
  let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
  
  // 获取已连接设备列表
  let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
  
  if (devices.length === 0) {
    console.error('No connected devices found.');
    return;
  }
  
  // 选择目标设备(示例选择第一个设备)
  let targetDevice: wearEngine.Device = devices[0];
  
  // 检查设备Monitor能力
  let isMonitorSupported: boolean = await targetDevice.isWearEngineCapabilitySupported(
    wearEngine.WearEngineCapability.MONITOR
  );
  
  if (!isMonitorSupported) {
    console.error('Device does not support Monitor capability.');
    return;
  }
  
  console.info(`Target device ready: ${targetDevice.name}, randomId: ${targetDevice.randomId}`);
}
```

### 步骤2:查询设备状态

**示例代码**:
```typescript
async function queryDeviceStatus(targetDevice: wearEngine.Device): Promise<void> {
  try {
    // 获取MonitorClient对象
    let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
      this.getUIContext().getHostContext()
    );
    
    // 查询佩戴状态(示例)
    let result: wearEngine.MonitorData = await monitorClient.queryStatus(
      targetDevice.randomId,
      wearEngine.MonitorItem.WEAR_STATUS
    );
    
    // 处理查询结果
    // 佩戴状态返回值: 1-佩戴中, 2-未佩戴
    console.info(`Succeeded in querying wear status, result is ${result.code}.`);
    
    if (result.code === 1) {
      console.info('Device is being worn.');
    } else if (result.code === 2) {
      console.info('Device is not being worn.');
    }
    
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    console.error(
      `Failed to query status. Code is ${businessError.code}, message is ${businessError.message}.`
    );
  }
}

// 查询其他状态的示例
async function queryPowerStatus(targetDevice: wearEngine.Device): Promise<number> {
  let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
    this.getUIContext().getHostContext()
  );
  
  let result: wearEngine.MonitorData = await monitorClient.queryStatus(
    targetDevice.randomId,
    wearEngine.MonitorItem.POWER_STATUS
  );
  
  // 电量状态返回值: 0-100(电量百分比)
  console.info(`Current battery level: ${result.code}%`);
  return result.code;
}

async function queryChargeStatus(targetDevice: wearEngine.Device): Promise<number> {
  let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
    this.getUIContext().getHostContext()
  );
  
  let result: wearEngine.MonitorData = await monitorClient.queryStatus(
    targetDevice.randomId,
    wearEngine.MonitorItem.CHARGE_STATUS
  );
  
  // 充电状态返回值: 1-正在充电, 2-未充电, 3-电量已充满
  console.info(`Charge status: ${result.code}`);
  return result.code;
}
```

### 步骤3:订阅设备状态变化

**示例代码**:
```typescript
// 定义回调函数(必须保持对象生命周期)
let wearStatusCallback: (data: wearEngine.MonitorEventData) => void = null;

async function subscribeDeviceStatus(targetDevice: wearEngine.Device): Promise<void> {
  try {
    let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
      this.getUIContext().getHostContext()
    );
    
    // 定义回调函数
    wearStatusCallback = (monitorEventData: wearEngine.MonitorEventData) => {
      // 处理状态变化事件
      console.info(
        `Status changed: event=${monitorEventData.event}, new status=${monitorEventData.data.code}`
      );
      
      // 根据事件类型处理业务逻辑
      switch (monitorEventData.event) {
        case wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED:
          // 佩戴状态变化: 1-佩戴, 2-未佩戴
          if (monitorEventData.data.code === 1) {
            console.info('Device is now being worn.');
          } else if (monitorEventData.data.code === 2) {
            console.info('Device is now removed from wrist.');
          }
          break;
          
        case wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED:
          // 电量降低事件
          console.info(`Battery level dropped to ${monitorEventData.data.code}%`);
          break;
          
        case wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED:
          // 充电状态变化: 1-充电开始, 2-充电结束, 3-充电完成
          if (monitorEventData.data.code === 1) {
            console.info('Charging started.');
          } else if (monitorEventData.data.code === 2) {
            console.info('Charging stopped.');
          } else if (monitorEventData.data.code === 3) {
            console.info('Charging completed.');
          }
          break;
          
        case wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED:
          // 连接状态变化: 2-连接成功, 3-连接断开, 5-设备解绑
          if (monitorEventData.data.code === 2) {
            console.info('Device connected.');
          } else if (monitorEventData.data.code === 3) {
            console.info('Device disconnected.');
          } else if (monitorEventData.data.code === 5) {
            console.info('Device removed.');
          }
          break;
          
        case wearEngine.MonitorEvent.EVENT_HEART_RATE_ALARM:
          // 心率告警: 1-静态心率过高, 2-静态心率过低, 3-运动心率过高, 4-运动心率过低
          console.info(`Heart rate alarm: ${monitorEventData.data.code}`);
          break;
          
        case wearEngine.MonitorEvent.EVENT_POWER_MODE_CHANGED:
          // 设备模式切换: 0-切换至智能模式, 1-切换至超长续航模式
          if (monitorEventData.data.code === 0) {
            console.info('Device switched to smart mode.');
          } else if (monitorEventData.data.code === 1) {
            console.info('Device switched to ultra-long battery life mode.');
          }
          break;
      }
    };
    
    // 订阅佩戴状态变化事件(示例)
    await monitorClient.subscribeEvent(
      targetDevice.randomId,
      wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
      wearStatusCallback
    );
    
    console.info('Succeeded in subscribing wear status.');
    
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    console.error(
      `Failed to subscribe status. Code is ${businessError.code}, message is ${businessError.message}.`
    );
  }
}
```

### 步骤4:取消订阅监听

**示例代码**:
```typescript
async function unsubscribeDeviceStatus(targetDevice: wearEngine.Device): Promise<void> {
  try {
    let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
      this.getUIContext().getHostContext()
    );
    
    // 取消订阅(必须传入订阅时相同的回调函数对象)
    await monitorClient.unsubscribeEvent(
      targetDevice.randomId,
      wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
      wearStatusCallback  // 必须是订阅时使用的同一个回调函数对象
    );
    
    console.info('Succeeded in unsubscribing wear status.');
    
    // 清空回调函数引用
    wearStatusCallback = null;
    
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    console.error(
      `Failed to unsubscribe status. Code is ${businessError.code}, message is ${businessError.message}.`
    );
  }
}
```

### 步骤5:错误处理

**错误处理代码**:
```typescript
function handleMonitorError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error. Check parameter types and values.');
      break;
      
    case 801:
      console.error('Capability not supported. This device does not support Monitor.');
      break;
      
    case 1008500001:
      console.error('Network error. Please check network connection.');
      break;
      
    case 1008500002:
      console.error('No device is bound. Please bind a device first.');
      break;
      
    case 1008500003:
      console.error('Device disconnected. Please connect device in Health App.');
      break;
      
    case 1008500004:
      console.error('App has not applied for Wear Engine service. Please apply for service.');
      break;
      
    case 1008500005:
      console.error('HUAWEI ID is not authorized. Please authorize in Health App.');
      break;
      
    case 1008500006:
      console.error('User privacy is not agreed. Please agree privacy policy.');
      break;
      
    case 1008500007:
      console.error('Device capability is not supported.');
      break;
      
    case 1008500008:
      console.error('Account error. User has not logged in with HUAWEI ID.');
      break;
      
    case 1008500009:
      console.error('Account error. Failed to obtain account information.');
      break;
      
    case 1008500010:
      console.error('Device ID is invalid. Please check device randomId.');
      break;
      
    case 1008500012:
      console.error('Too many callbacks of the same type. Please unsubscribe some callbacks first.');
      break;
      
    case 1008509999:
      console.error('Internal error. Please try again later.');
      break;
      
    default:
      console.error(`Unknown error: code=${error.code}, message=${error.message}`);
  }
}
```

### 步骤6:降级处理

**降级处理代码**:
```typescript
async function queryStatusWithFallback(
  targetDevice: wearEngine.Device,
  monitorItem: wearEngine.MonitorItem
): Promise<number | null> {
  try {
    // 主流程:直接查询状态
    let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
      this.getUIContext().getHostContext()
    );
    
    let result: wearEngine.MonitorData = await monitorClient.queryStatus(
      targetDevice.randomId,
      monitorItem
    );
    
    return result.code;
    
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    
    // 降级方案1:检查设备连接状态
    if (businessError.code === 1008500003) {
      console.warn('Device disconnected. Checking connection...');
      
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(
        this.getUIContext().getHostContext()
      );
      
      let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
      let isConnected = devices.some(device => device.randomId === targetDevice.randomId);
      
      if (!isConnected) {
        console.warn('Device is not connected. Please reconnect device.');
        return null;
      }
    }
    
    // 降级方案2:检查权限
    if (businessError.code === 1008500006) {
      console.warn('User privacy not agreed. Requesting authorization...');
      
      let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(
        this.getUIContext().getHostContext()
      );
      
      // 尝试请求权限
      try {
        await authClient.requestAuthorization({
          permissions: [wearEngine.Permission.USER_STATUS]
        });
        
        // 重新尝试查询
        let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
          this.getUIContext().getHostContext()
        );
        
        let result: wearEngine.MonitorData = await monitorClient.queryStatus(
          targetDevice.randomId,
          monitorItem
        );
        
        return result.code;
        
      } catch (authError) {
        console.error('Failed to request authorization.');
        return null;
      }
    }
    
    // 降级方案3:提示用户手动处理
    console.error(`Query failed: ${businessError.message}. Please check device status.`);
    return null;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因:必填参数未指定、参数类型错误、参数验证失败 | 检查参数类型和取值,确保deviceRandomId有效且MonitorItem/MonitorEvent枚举正确 |
| 801 | 能力不支持。当前设备不支持Monitor能力 | 检查设备能力支持情况,使用isWearEngineCapabilitySupported验证 |
| 1008500001 | 网络错误。网络不可用 | 提示用户检查网络连接并重试 |
| 1008500002 | 无设备绑定。未绑定穿戴设备 | 引导用户在华为运动健康App中绑定设备 |
| 1008500003 | 设备未连接。穿戴设备已断开连接 | 提示用户在华为运动健康App中查看设备连接状态,确保设备在线 |
| 1008500004 | 应用未申请Wear Engine服务 | 引导开发者申请接入Wear Engine服务 |
| 1008500005 | 华为账号ID未授权 | 引导用户在华为运动健康App中授权 |
| 1008500006 | 用户隐私协议未同意 | 引导用户同意隐私协议并授予相应权限 |
| 1008500007 | 设备能力不支持 | 检查设备能力,使用isWearEngineCapabilitySupported验证Monitor能力 |
| 1008500008 | 账号错误。用户未登录华为账号ID | 提示用户登录华为账号ID |
| 1008500009 | 账号错误。获取账号信息失败 | 提示用户重新登录华为账号ID |
| 1008500010 | 设备ID无效 | 检查deviceRandomId是否为有效的设备随机标识符 |
| 1008500012 | 同类型回调函数过多 | 取消部分订阅后再重新订阅 |
| 1008509999 | 内部错误 | 提示用户稍后重试,若持续失败请联系技术支持 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "^5.0.0(12)",
    "@kit.BasicServicesKit": "^5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS:5.0.0(12)及以上版本
- 设备类型:Phone、Tablet(其他设备类型返回801错误码)
- 系统模型:Stage模型(仅支持Stage模型)
- 系统能力:SystemCapability.Health.WearEngine

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**:确保DevEco Studio已安装HarmonyOS SDK 5.0.0(12)及以上版本,检查项目配置文件中的SDK版本

**问题2:类型定义缺失**
```
Error: Property 'MonitorClient' does not exist on type 'wearEngine'
```
**解决方法**:检查导入语句是否正确`import { wearEngine } from '@kit.WearEngine';`,确保使用完整的API路径

**问题3:Context类型错误**
```
Error: Argument of type 'Context' is not assignable to parameter of type 'common.Context'
```
**解决方法**:使用`this.getUIContext().getHostContext()`获取正确的Context类型

**问题4:权限未配置**
```
Error: 1008500004 - App has not applied for Wear Engine service
```
**解决方法**:在开发者联盟申请设备基础信息权限和USER_STATUS权限

## 常见问题与解决方法

### Q1:查询状态时返回设备未连接错误
**原因**:穿戴设备未连接到华为运动健康App
**解决方法**:
- 引导用户打开华为运动健康App,进入"设备"界面查看设备在线状态
- 调用`getConnectedDevices`检查设备连接状态
- 提示用户重新连接设备(蓝牙连接或拉近距离)

### Q2:订阅佩戴状态或心率告警时返回权限未同意错误
**原因**:USER_STATUS权限需要用户授权且仅限企业开发者申请
**解决方法**:
- 检查应用是否为企业开发者账号
- 在开发者联盟申请USER_STATUS权限
- 调用`AuthClient.requestAuthorization`请求用户授权
- 引导用户在权限弹窗中同意授权

### Q3:取消订阅时失败
**原因**:传入的回调函数与订阅时不一致
**解决方法**:
- 确保取消订阅时传入的回调函数对象与订阅时完全相同(同一个对象引用)
- 不要在订阅后重新定义回调函数
- 建议将回调函数定义为变量并保持生命周期延长至取消订阅时

### Q4:订阅同一事件类型多次失败
**原因**:系统限制同一设备同一事件类型的回调函数数量
**解决方法**:
- 检查是否已订阅过该事件类型
- 先取消之前的订阅再重新订阅
- 避免重复订阅同一事件类型

### Q5:查询状态时返回的数据含义不清楚
**原因**:不同状态类型的返回值含义不同
**解决方法**:
- 参考MonitorItem枚举说明了解查询返回值含义
- 参考MonitorEvent枚举说明了解订阅事件返回值含义
- 根据状态类型处理相应的业务逻辑

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "query_status",
  "device_random_id": "device_random_id_value",
  "monitor_item": "WEAR_STATUS",
  "result": {
    "code": 1,
    "data": null,
    "description": "佩戴状态:佩戴中"
  },
  "apiUsed": [
    "wearEngine.getDeviceClient",
    "wearEngine.getMonitorClient",
    "DeviceClient.getConnectedDevices",
    "MonitorClient.queryStatus"
  ],
  "timestamp": "2024-01-01T10:00:00Z"
}
```

订阅状态变化事件输出:
```json
{
  "status": "success",
  "operation": "subscribe_event",
  "device_random_id": "device_random_id_value",
  "monitor_event": "EVENT_WEAR_STATUS_CHANGED",
  "callback_registered": true,
  "apiUsed": [
    "wearEngine.getMonitorClient",
    "MonitorClient.subscribeEvent"
  ],
  "timestamp": "2024-01-01T10:00:00Z"
}
```

## 参考文档

- [API开发指南](references/query_and_subscribe_status.md)
- [API参考说明](references/wearengine_api.md)

## 完整示例代码

- [ArkTS查询状态示例](assets/query_status_example.ets)
- [ArkTS订阅状态示例](assets/subscribe_status_example.ets)
- [完整功能示例](assets/complete_example.ets)

## 测试用例

### 正向测试用例
- [查询佩戴状态](tests/test_query_wear_status.py):验证正常查询佩戴状态功能
- [查询电量状态](tests/test_query_power_status.py):验证正常查询电量状态功能
- [订阅佩戴状态变化](tests/test_subscribe_wear_status.py):验证正常订阅佩戴状态变化事件
- [取消订阅佩戴状态](tests/test_unsubscribe_wear_status.py):验证正常取消订阅功能

### 边界测试用例
- [查询边界电量值](tests/test_boundary_power_status.py):验证电量值0%和100%的边界情况
- [订阅所有事件类型](tests/test_subscribe_all_events.py):验证订阅所有支持的事件类型
- [多次取消订阅](tests/test_multiple_unsubscribe.py):验证多次取消订阅的边界情况

### 异常测试用例
- [查询状态设备未连接](tests/test_query_disconnected_device.py):验证设备未连接时的错误处理
- [订阅状态权限未授权](tests/test_subscribe_without_permission.py):验证权限未授权时的错误处理
- [取消订阅回调不匹配](tests/test_unsubscribe_wrong_callback.py):验证回调函数不匹配时的错误处理
- [无效设备ID查询](tests/test_query_invalid_device_id.py):验证无效deviceRandomId的错误处理