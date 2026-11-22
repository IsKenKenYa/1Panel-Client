import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 穿戴设备状态订阅示例
 * 本示例演示如何订阅穿戴设备的各种状态变化事件
 */

// 获取MonitorClient对象
let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(this.getUIContext().getHostContext());

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

let chargeStatusCallback = (monitorEventData: wearEngine.MonitorEventData) => {
  const chargeStatusMap = {
    1: '充电开始',
    2: '充电结束',
    3: '充电完成'
  };
  const chargeStatus = chargeStatusMap[monitorEventData.data.code] || '未知状态';
  console.info(`Charge status changed to ${chargeStatus}, event is ${monitorEventData.event}`);
  // 处理充电状态变化业务逻辑
};

let connectionCallback = (monitorEventData: wearEngine.MonitorEventData) => {
  const connectionStatusMap = {
    2: '连接成功',
    3: '连接断开',
    5: '设备解绑'
  };
  const connectionStatus = connectionStatusMap[monitorEventData.data.code] || '未知状态';
  console.info(`Connection status changed to ${connectionStatus}, event is ${monitorEventData.event}`);
  // 处理连接状态变化业务逻辑
};

let powerModeCallback = (monitorEventData: wearEngine.MonitorEventData) => {
  const powerModeMap = {
    0: '智能模式',
    1: '超长续航模式'
  };
  const powerMode = powerModeMap[monitorEventData.data.code] || '未知模式';
  console.info(`Power mode changed to ${powerMode}, event is ${monitorEventData.event}`);
  // 处理设备模式切换业务逻辑
};

/**
 * 订阅佩戴状态变化
 * @param deviceRandomId 设备随机ID
 */
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

/**
 * 订阅电量降低
 * @param deviceRandomId 设备随机ID
 */
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

/**
 * 订阅心率告警(需要USER_STATUS权限)
 * @param deviceRandomId 设备随机ID
 */
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

/**
 * 订阅充电状态变化
 * @param deviceRandomId 设备随机ID
 */
async function subscribeChargeStatus(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.subscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED,
      chargeStatusCallback
    );
    console.info('Succeeded in subscribing charge status');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to subscribe charge status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 订阅连接状态变化
 * @param deviceRandomId 设备随机ID
 */
async function subscribeConnectionStatus(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.subscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
      connectionCallback
    );
    console.info('Succeeded in subscribing connection status');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to subscribe connection status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 订阅设备模式切换
 * @param deviceRandomId 设备随机ID
 */
async function subscribePowerModeChange(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.subscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_POWER_MODE_CHANGED,
      powerModeCallback
    );
    console.info('Succeeded in subscribing power mode change');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to subscribe power mode change. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 取消订阅佩戴状态变化
 * @param deviceRandomId 设备随机ID
 */
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

/**
 * 取消订阅电量降低
 * @param deviceRandomId 设备随机ID
 */
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

/**
 * 取消订阅心率告警
 * @param deviceRandomId 设备随机ID
 */
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

/**
 * 取消订阅充电状态变化
 * @param deviceRandomId 设备随机ID
 */
async function unsubscribeChargeStatus(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.unsubscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED,
      chargeStatusCallback
    );
    console.info('Succeeded in unsubscribing charge status');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to unsubscribe charge status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 取消订阅连接状态变化
 * @param deviceRandomId 设备随机ID
 */
async function unsubscribeConnectionStatus(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.unsubscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
      connectionCallback
    );
    console.info('Succeeded in unsubscribing connection status');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to unsubscribe connection status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 取消订阅设备模式切换
 * @param deviceRandomId 设备随机ID
 */
async function unsubscribePowerModeChange(deviceRandomId: string): Promise<void> {
  try {
    await monitorClient.unsubscribeEvent(
      deviceRandomId,
      wearEngine.MonitorEvent.EVENT_POWER_MODE_CHANGED,
      powerModeCallback
    );
    console.info('Succeeded in unsubscribing power mode change');
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to unsubscribe power mode change. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 主函数: 执行状态订阅
 */
async function main(): Promise<void> {
  try {
    // 1. 获取已连接设备列表
    let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
    let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    
    if (devices.length === 0) {
      console.error('No connected device found');
      return;
    }
    
    // 2. 选择目标设备(选择第一个设备)
    let targetDevice: wearEngine.Device = devices[0];
    console.info(`Target device: ${targetDevice.name}, randomId: ${targetDevice.randomId}`);
    
    // 3. 订阅各种状态变化事件
    await subscribeWearStatus(targetDevice.randomId);
    await subscribeBatteryDrop(targetDevice.randomId);
    await subscribeHeartRateAlarm(targetDevice.randomId);
    await subscribeChargeStatus(targetDevice.randomId);
    await subscribeConnectionStatus(targetDevice.randomId);
    await subscribePowerModeChange(targetDevice.randomId);
    
    console.info('=== All subscriptions registered successfully ===');
    console.info('Waiting for device status changes...');
    
    // 4. 模拟等待一段时间后取消订阅
    await new Promise(resolve => setTimeout(resolve, 60000)); // 等待60秒
    
    // 5. 取消所有订阅
    await unsubscribeWearStatus(targetDevice.randomId);
    await unsubscribeBatteryDrop(targetDevice.randomId);
    await unsubscribeHeartRateAlarm(targetDevice.randomId);
    await unsubscribeChargeStatus(targetDevice.randomId);
    await unsubscribeConnectionStatus(targetDevice.randomId);
    await unsubscribePowerModeChange(targetDevice.randomId);
    
    console.info('=== All subscriptions unsubscribed successfully ===');
    
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to execute main function. Code is ${businessError.code}, message is ${businessError.message}`);
  }
}

// 执行主函数
main();