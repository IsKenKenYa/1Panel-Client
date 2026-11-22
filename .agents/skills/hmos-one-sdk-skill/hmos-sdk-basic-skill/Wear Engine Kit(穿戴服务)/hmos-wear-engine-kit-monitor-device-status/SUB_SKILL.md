---
name: hmos-wear-engine-kit-monitor-device-status
description: 查询和订阅穿戴设备状态,支持电量/充电/佩戴/设备模式/可用空间查询和订阅连接/低电量/心率告警等状态变化,需要申请设备基础信息和穿戴用户状态权限,适用于健康监测、设备管理场景
---

# 状态查询与订阅技能

## 功能描述

本技能提供穿戴设备状态的查询与订阅能力,支持查询穿戴设备的电量状态、充电状态、佩戴状态、设备模式和可用存储空间,以及订阅设备连接状态、电量降低、充电状态变化、佩戴状态变化、心率告警、设备模式切换等状态变化事件。使用前需确保应用已申请相应权限并获得用户授权,设备已连接手机且华为运动健康App在线。

**支持的状态类型**:

**查询状态**(MonitorItem):
- 电量状态(POWER_STATUS): 返回电量百分比(0-100)
- 充电状态(CHARGE_STATUS): 1-充电中, 2-未充电, 3-已充满
- 佩戴状态(WEAR_STATUS): 1-佩戴, 2-未佩戴(需USER_STATUS权限)
- 设备模式(POWER_MODE): -1-不支持, 0-智能模式, 1-超长续航模式
- 可用空间(AVAILABLE_STORAGE_SPACE): 用户可用空间(KB)

**订阅事件**(MonitorEvent):
- 连接状态变化(EVENT_CONNECTION_STATUS_CHANGED): 2-连接成功, 3-连接断开, 5-设备解绑
- 电量降低(EVENT_BATTERY_LEVEL_DROPPED): 电量百分比(0-100)
- 充电状态变化(EVENT_CHARGE_STATUS_CHANGED): 1-充电开始, 2-充电结束, 3-充电完成
- 佩戴状态变化(EVENT_WEAR_STATUS_CHANGED): 1-佩戴, 2-未佩戴(需USER_STATUS权限)
- 心率告警(EVENT_HEART_RATE_ALARM): 1-静态心率过高, 2-静态心率过低, 3-运动心率过高, 4-运动心率过低(需USER_STATUS权限)
- 设备模式切换(EVENT_POWER_MODE_CHANGED): 0-智能模式, 1-超长续航模式

## 使用场景

### 触发词
- "查询穿戴设备电量"
- "查询穿戴设备充电状态"
- "查询佩戴状态"
- "订阅设备连接状态"
- "订阅心率告警"
- "订阅电量变化"
- "取消订阅设备状态"
- "穿戴设备状态监控"

### 能做
- 查询穿戴设备的电量、充电、佩戴、模式、存储空间等实时状态
- 订阅穿戴设备连接状态变化、电量降低、心率告警等状态变化事件
- 取消已订阅的状态变化监听
- 处理状态查询和订阅的错误情况
- 提供完整的状态监控流程代码

### 绝不做
- 不处理穿戴设备侧应用开发(仅支持手机侧应用)
- 不处理设备连接和选择流程(需要先获取连接设备列表)
- 不处理权限申请流程(需要先申请并授权)
- 不处理非Wear Engine Kit相关的设备状态
- 不支持企业开发者权限(USER_STATUS)场景的普通开发者使用

### 补充
- 查询佩戴状态和心率告警需要企业开发者申请USER_STATUS权限
- 确保穿戴设备已连接手机且华为运动健康App在线
- 订阅回调函数对象必须保持引用以便后续取消订阅
- 电量订阅仅在电量每降低1%且非充电状态时触发
- 心率告警需要在运动健康App中设置心率提醒阈值

## 调用规范和规则

### 输入约束
- 设备标识: 必须是有效的Device.randomId字符串
- 状态类型: 必须使用wearEngine.MonitorItem或wearEngine.MonitorEvent枚举值
- 回调函数: 订阅时必须提供有效的Callback对象
- 查询频率: 建议避免频繁查询,遵循最小必要原则
- 订阅数量: 同类型订阅回调数量有限制,避免重复订阅

### 执行约束
- 最大耗时: 单次查询耗时约1-3秒(取决于设备连接状态)
- 最大订阅数: 同类型MonitorEvent的订阅回调数量有限制(错误码1008500012)
- API版本: 需要API 12+ (5.0.0)
- 设备要求: 仅支持Phone和Tablet设备调用,其他设备返回801错误码
- 模型约束: 仅支持Stage模型

### 内容约束
- 禁止生成: 不生成穿戴设备侧代码、权限申请代码
- 禁止使用高危函数: 不使用eval、动态代码执行
- 禁止操作: 不直接修改设备状态、不绕过权限检查
- 数据校验: 必须验证设备randomId有效性、状态枚举值合法性

### 降级约束
- 设备未连接: 提示用户连接设备,调用getConnectedDevices检查连接状态
- 权限未授权: 提示用户授权相应权限,跳转权限申请流程
- 网络失败: 等待网络恢复后重试,建议增加重试机制(最多3次)
- 设备不支持: 检查设备能力支持情况,提示用户更换设备
- 用户未登录: 提示用户登录华为账号

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查应用是否已申请Wear Engine服务权限(设备基础信息权限或USER_STATUS权限)
2. 检查用户是否已授权相应权限
3. 检查设备是否已连接(调用getConnectedDevices)
4. 检查用户是否已登录华为账号

**参数准备**:
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

// 获取已连接设备列表
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();

// 选择目标设备
if (devices.length === 0) {
  console.error('No connected device found');
  return;
}
let targetDevice: wearEngine.Device = devices[0]; // 选择第一个设备
```

### 步骤2: 查询设备状态

**示例代码**:
```typescript
// 获取MonitorClient对象
let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(this.getUIContext().getHostContext());

// 查询电量状态
async function queryPowerStatus(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.POWER_STATUS
    );
    console.info(`Succeeded in querying power status, battery level is ${result.code}%`);
    return result.code; // 返回电量百分比
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query power status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 查询佩戴状态(需要USER_STATUS权限)
async function queryWearStatus(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.WEAR_STATUS
    );
    const wearStatus = result.code === 1 ? '佩戴中' : '未佩戴';
    console.info(`Succeeded in querying wear status, result is ${wearStatus}`);
    return result.code; // 1-佩戴, 2-未佩戴
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query wear status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 查询充电状态
async function queryChargeStatus(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.CHARGE_STATUS
    );
    const chargeStatusMap = {
      1: '正在充电',
      2: '未充电',
      3: '电量已充满'
    };
    const chargeStatus = chargeStatusMap[result.code] || '未知状态';
    console.info(`Succeeded in querying charge status, result is ${chargeStatus}`);
    return result.code;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query charge status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 查询可用存储空间
async function queryAvailableStorage(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.AVAILABLE_STORAGE_SPACE
    );
    const storageKB = result.code;
    const storageMB = storageKB / 1024;
    console.info(`Succeeded in querying available storage, result is ${storageMB.toFixed(2)} MB`);
    return result.code; // 返回KB值
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query available storage. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 查询设备模式
async function queryPowerMode(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.POWER_MODE
    );
    const powerModeMap = {
      '-1': '设备不支持模式切换',
      '0': '智能模式',
      '1': '超长续航模式'
    };
    const powerMode = powerModeMap[result.code.toString()] || '未知模式';
    console.info(`Succeeded in querying power mode, result is ${powerMode}`);
    return result.code;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query power mode. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 调用查询示例
await queryPowerStatus(targetDevice.randomId);
await queryWearStatus(targetDevice.randomId);
await queryChargeStatus(targetDevice.randomId);
```

### 步骤3: 订阅设备状态变化

**示例代码**:
```typescript
// 定义订阅回调函数(必须保持引用以便后续取消订阅)
let wearStatusCallback = (monitorEventData: wearEngine.MonitorEventData) => {
  const wearStatus = monitorEventData.data.code === 1 ? '佩戴' : '未佩戴';
  console.info(`Wear status changed to ${wearStatus}, event is ${monitorEventData.event}`);
  // 处理佩戴状态变化业务逻辑
};

let batteryCallback = (monitorEventData: wearEngine.MonitorEventData) => {
  const batteryLevel = monitorEventData.data.code;
  console.info(`Battery level dropped to ${batteryLevel}%, event is ${monitorEventData.event}`);
  // 处理电量降低业务逻辑
};

let heartRateAlarmCallback = (monitorEventData: wearEngine.MonitorEventData) => {
  const alarmTypeMap = {
    1: '静态心率过高',
    2: '静态心率过低',
    3: '运动心率过高',
    4: '运动心率过低'
  };
  const alarmType = alarmTypeMap[monitorEventData.data.code] || '未知告警';
  console.info(`Heart rate alarm: ${alarmType}, event is ${monitorEventData.event}`);
  // 处理心率告警业务逻辑
};

// 订阅佩戴状态变化
async function subscribeWearStatus(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.subscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
      wearStatusCallback
    );
    console.info('Succeeded in subscribing wear status');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to subscribe wear status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 订阅电量降低
async function subscribeBatteryDrop(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.subscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
      batteryCallback
    );
    console.info('Succeeded in subscribing battery level drop');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to subscribe battery level drop. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 订阅心率告警(需要USER_STATUS权限)
async function subscribeHeartRateAlarm(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.subscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_HEART_RATE_ALARM,
      heartRateAlarmCallback
    );
    console.info('Succeeded in subscribing heart rate alarm');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to subscribe heart rate alarm. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 订阅连接状态变化
async function subscribeConnectionStatus(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.subscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
      (monitorEventData: wearEngine.MonitorEventData) => {
        const connectionStatusMap = {
          2: '连接成功',
          3: '连接断开',
          5: '设备解绑'
        };
        const status = connectionStatusMap[monitorEventData.data.code] || '未知状态';
        console.info(`Connection status changed: ${status}`);
      }
    );
    console.info('Succeeded in subscribing connection status');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to subscribe connection status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 调用订阅示例
await subscribeWearStatus(targetDevice.randomId);
await subscribeBatteryDrop(targetDevice.randomId);
await subscribeHeartRateAlarm(targetDevice.randomId);
```

### 步骤4: 取消订阅

**示例代码**:
```typescript
// 取消订阅佩戴状态变化(必须传入与订阅时相同的回调函数对象)
async function unsubscribeWearStatus(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.unsubscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
      wearStatusCallback // 必须与订阅时的回调对象相同
    );
    console.info('Succeeded in unsubscribing wear status');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to unsubscribe wear status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 取消订阅电量降低
async function unsubscribeBatteryDrop(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.unsubscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
      batteryCallback
    );
    console.info('Succeeded in unsubscribing battery level drop');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to unsubscribe battery level drop. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 取消订阅心率告警
async function unsubscribeHeartRateAlarm(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.unsubscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_HEART_RATE_ALARM,
      heartRateAlarmCallback
    );
    console.info('Succeeded in unsubscribing heart rate alarm');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to unsubscribe heart rate alarm. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

// 调用取消订阅示例
await unsubscribeWearStatus(targetDevice.randomId);
await unsubscribeBatteryDrop(targetDevice.randomId);
```

### 步骤5: 错误处理

```typescript
// 统一的错误处理函数
function handleMonitorError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('参数错误: 参数类型错误或必填参数缺失');
      // 检查参数类型和完整性
      break;
    case 801:
      console.error('能力不支持: 当前设备不支持此能力');
      // 提示用户更换设备
      break;
    case 1008500001:
      console.error('网络错误: 网络不可用');
      // 等待网络恢复后重试
      break;
    case 1008500002:
      console.error('无设备绑定: 没有绑定的穿戴设备');
      // 提示用户绑定设备
      break;
    case 1008500003:
      console.error('设备断开连接: 穿戴设备已断开连接');
      // 提示用户重新连接设备
      break;
    case 1008500004:
      console.error('应用未申请Wear Engine服务');
      // 引导开发者申请服务
      break;
    case 1008500005:
      console.error('华为账号ID未授权');
      // 提示用户授权账号
      break;
    case 1008500006:
      console.error('用户隐私协议未同意');
      // 提示用户同意隐私协议
      break;
    case 1008500007:
      console.error('设备能力不支持');
      // 检查设备能力支持情况
      break;
    case 1008500008:
      console.error('账号错误: 用户未登录华为账号');
      // 提示用户登录华为账号
      break;
    case 1008500009:
      console.error('账号错误: 无法获取华为账号信息');
      // 检查账号状态
      break;
    case 1008500010:
      console.error('设备ID无效');
      // 检查设备randomId有效性
      break;
    case 1008500012:
      console.error('同类型回调过多');
      // 减少重复订阅,取消无用订阅
      break;
    case 1008509999:
      console.error('内部错误');
      // 等待后重试或联系技术支持
      break;
    default:
      console.error(`未知错误: ${error.message}`);
  }
}

// 使用错误处理
try {
  await queryPowerStatus(targetDevice.randomId);
} catch (error) {
  handleMonitorError(error as BusinessError);
}
```

### 步骤6: 降级处理

```typescript
// 网络失败降级处理
async function queryWithRetry(deviceRandomId: string, item: wearEngine.MonitorItem, maxRetry = 3): Promise<wearEngine.MonitorData> {
  let retryCount = 0;
  while (retryCount < maxRetry) {
    try {
      return await monitorClient.queryStatus(deviceRandomId, item);
    } catch (error) {
      const businessError = error as BusinessError;
      if (businessError.code === 1008500001) {
        // 网络错误,等待后重试
        retryCount++;
        console.warn(`Network error, retrying... (${retryCount}/${maxRetry})`);
        await new Promise(resolve => setTimeout(resolve, 2000)); // 等待2秒
      } else {
        // 其他错误直接抛出
        throw businessError;
      }
    }
  }
  throw new Error(`Failed after ${maxRetry} retries`);
}

// 设备未连接降级处理
async function handleDeviceDisconnected(): Promise<void> {
  try {
    // 检查设备连接状态
    const devices = await deviceClient.getConnectedDevices();
    if (devices.length === 0) {
      console.warn('No device connected, please connect device first');
      // 提示用户连接设备
      return;
    }
    // 继续执行查询或订阅
  } catch (error) {
    console.error('Failed to check device connection');
  }
}

// 权限未授权降级处理
async function handlePermissionDenied(): Promise<void> {
  console.warn('Permission not authorized, please request permission first');
  // 引导用户到权限申请流程
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误: 参数类型错误或必填参数缺失 | 检查参数类型、验证必填参数 |
| 801 | 能力不支持: 当前设备不支持此能力 | 提示用户更换支持此能力的设备 |
| 1008500001 | 网络错误: 网络不可用 | 等待网络恢复后重试,建议增加重试机制 |
| 1008500002 | 无设备绑定: 没有绑定的穿戴设备 | 提示用户在运动健康App中绑定设备 |
| 1008500003 | 设备断开连接: 穿戴设备已断开连接 | 提示用户重新连接设备,检查蓝牙连接 |
| 1008500004 | 应用未申请Wear Engine服务 | 引导开发者到开发者联盟申请服务 |
| 1008500005 | 华为账号ID未授权 | 提示用户授权华为账号访问 |
| 1008500006 | 用户隐私协议未同意 | 提示用户同意隐私协议 |
| 1008500007 | 设备能力不支持 | 调用isWearEngineCapabilitySupported检查设备能力 |
| 1008500008 | 账号错误: 用户未登录华为账号 | 提示用户登录华为账号 |
| 1008500009 | 账号错误: 无法获取华为账号信息 | 检查账号状态,重新登录 |
| 1008500010 | 设备ID无效 | 检查Device.randomId是否有效 |
| 1008500012 | 同类型回调过多 | 减少重复订阅,取消无用订阅 |
| 1008509999 | 内部错误 | 等待后重试,如持续失败联系技术支持 |

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
- HarmonyOS API: 12+ (5.0.0)
- 开发环境: DevEco Studio 5.0+
- 运行环境: Phone或Tablet设备
- 用户环境: 已登录华为账号,已安装华为运动健康App

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**: 确保项目已配置正确的依赖版本,在oh-package.json5中添加依赖声明

**问题2: Context类型错误**
```
Error: Parameter error. Incorrect parameter types.
```
**解决方法**: 使用UIAbilityContext而非普通Context,通过`this.getUIContext().getHostContext()`获取

**问题3: Stage模型限制**
```
Error: This interface can only be used in Stage model.
```
**解决方法**: 确保项目使用Stage模型,不支持FA模型

**问题4: 设备类型不支持**
```
Error: Capability not supported. (801)
```
**解决方法**: 确保在Phone或Tablet设备上运行,其他设备类型返回801错误码

**问题5: 订阅回调未保持引用**
```
订阅成功但无法取消订阅
```
**解决方法**: 将回调函数对象保存为变量,取消订阅时传入相同对象引用

## 常见问题与解决方法

### Q1: 查询佩戴状态返回权限错误
**原因**: 佩戴状态查询需要USER_STATUS权限,仅限企业开发者申请
**解决方法**:
- 企业开发者: 在开发者联盟申请USER_STATUS权限
- 普通开发者: 无法使用佩戴状态和心率告警功能,仅可查询电量、充电、设备模式、存储空间

### Q2: 电量订阅没有触发回调
**原因**: 电量订阅仅在电量每降低1%且设备非充电状态时触发
**解决方法**:
- 确认设备电量实际降低(降低1%)
- 确认设备处于非充电状态
- 使用queryStatus主动查询电量状态

### Q3: 心率告警订阅无响应
**原因**: 心率告警需要用户在运动健康App中设置心率提醒阈值
**解决方法**:
- 打开运动健康App,进入设备详情页
- 点击心率设置,配置静态心率上下限和运动心率阈值
- 确认心率告警开关已开启

### Q4: 设备连接状态订阅无回调
**原因**: 设备连接状态订阅需要设备实际发生连接/断开事件
**解决方法**:
- 手动断开蓝牙连接触发断开事件
- 重新连接触发连接成功事件
- 在运动健康App中删除设备触发设备解绑事件

### Q5: 取消订阅失败
**原因**: 取消订阅时传入的回调函数对象与订阅时不一致
**解决方法**:
- 将订阅回调函数保存为变量(如wearStatusCallback)
- 取消订阅时传入完全相同的对象引用
- 不要在订阅和取消订阅时使用不同的匿名函数

### Q6: 查询返回设备断开错误
**原因**: 穿戴设备未连接或蓝牙连接断开
**解决方法**:
- 检查设备蓝牙连接状态
- 打开华为运动健康App查看设备在线状态
- 调用getConnectedDevices检查已连接设备列表
- 提示用户重新连接设备

### Q7: 网络错误频繁出现
**原因**: 网络不稳定或华为运动健康服务连接异常
**解决方法**:
- 检查网络连接状态
- 等待网络恢复后重试
- 增加重试机制(建议最多3次,间隔2秒)
- 确认华为运动健康App正常运行

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operationType": "query | subscribe | unsubscribe",
  "deviceRandomId": "设备随机ID",
  "monitorItem": "POWER_STATUS | WEAR_STATUS | CHARGE_STATUS | ...",
  "monitorEvent": "EVENT_WEAR_STATUS_CHANGED | EVENT_BATTERY_LEVEL_DROPPED | ...",
  "result": {
    "code": "状态码",
    "data": "扩展数据"
  },
  "timestamp": "2026-07-03T20:30:00Z",
  "apiUsed": [
    "wearEngine.getMonitorClient",
    "MonitorClient.queryStatus",
    "MonitorClient.subscribeEvent",
    "MonitorClient.unsubscribeEvent"
  ]
}
```

## 参考文档

- [状态查询与订阅开发指南](references/query_and_subscribe_status.md)
- [wearEngine API参考说明](references/wearengine_api.md)
- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)
- [请求用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request_user_authorization)
- [已连接穿戴设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices)
- [目标设备选择](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection)
- [Wear Engine错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)

## 完整示例代码

- [ArkTS查询示例](assets/query_device_status.ets)
- [ArkTS订阅示例](assets/subscribe_device_status.ets)
- [ArkTS完整示例](assets/monitor_device_status_complete.ets)
- [错误处理示例](assets/error_handling.ets)

## 测试用例

### 正向测试用例
- [查询电量状态](tests/test_query_power_status.py): 正常查询电量百分比
- [查询佩戴状态](tests/test_query_wear_status.py): 企业开发者查询佩戴状态
- [订阅电量变化](tests/test_subscribe_battery.py): 正常订阅电量降低事件
- [取消订阅](tests/test_unsubscribe.py): 正常取消订阅并验证成功

### 边界测试用例
- [电量0%查询](tests/test_battery_zero.py): 电量为0时的查询处理
- [电量100%查询](tests/test_battery_full.py): 电量满时的查询处理
- [存储空间为0](tests/test_storage_zero.py): 可用空间为0KB的情况
- [设备模式不支持](tests/test_mode_unsupported.py): 设备返回-1(不支持模式切换)

### 异常测试用例
- [设备未连接](tests/test_device_disconnected.py): 设备断开连接时的错误处理
- [权限未授权](tests/test_permission_denied.py): USER_STATUS权限未授权的错误处理
- [网络错误](tests/test_network_error.py): 网络不可用时的重试机制
- [参数错误](tests/test_invalid_params.py): 无效设备ID或状态枚举的错误处理
- [重复订阅](tests/test_duplicate_subscribe.py): 同类型订阅回调过多的错误处理