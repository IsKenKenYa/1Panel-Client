import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 穿戴设备状态查询示例
 * 本示例演示如何查询穿戴设备的电量、充电、佩戴、模式、存储空间等状态
 */

// 获取MonitorClient对象
let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(this.getUIContext().getHostContext());

/**
 * 查询电量状态
 * @param deviceRandomId 设备随机ID
 * @returns 电量百分比(0-100)
 */
async function queryPowerStatus(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.POWER_STATUS
    );
    console.info(`Succeeded in querying power status, battery level is ${result.code}%`);
    return result.code;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query power status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 查询充电状态
 * @param deviceRandomId 设备随机ID
 * @returns 充电状态: 1-充电中, 2-未充电, 3-已充满
 */
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

/**
 * 查询佩戴状态(需要USER_STATUS权限)
 * @param deviceRandomId 设备随机ID
 * @returns 佩戴状态: 1-佩戴, 2-未佩戴
 */
async function queryWearStatus(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.WEAR_STATUS
    );
    const wearStatus = result.code === 1 ? '佩戴中' : '未佩戴';
    console.info(`Succeeded in querying wear status, result is ${wearStatus}`);
    return result.code;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query wear status. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 查询可用存储空间
 * @param deviceRandomId 设备随机ID
 * @returns 可用空间(KB)
 */
async function queryAvailableStorage(deviceRandomId: string): Promise<number> {
  try {
    const result: wearEngine.MonitorData = await monitorClient.queryStatus(
      deviceRandomId,
      wearEngine.MonitorItem.AVAILABLE_STORAGE_SPACE
    );
    const storageKB = result.code;
    const storageMB = storageKB / 1024;
    console.info(`Succeeded in querying available storage, result is ${storageMB.toFixed(2)} MB`);
    return result.code;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to query available storage. Code is ${businessError.code}, message is ${businessError.message}`);
    throw businessError;
  }
}

/**
 * 查询设备模式
 * @param deviceRandomId 设备随机ID
 * @returns 设备模式: -1-不支持, 0-智能模式, 1-超长续航模式
 */
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

/**
 * 主函数: 执行状态查询
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
    
    // 3. 查询各种状态
    const batteryLevel = await queryPowerStatus(targetDevice.randomId);
    const chargeStatus = await queryChargeStatus(targetDevice.randomId);
    const wearStatus = await queryWearStatus(targetDevice.randomId);
    const storageKB = await queryAvailableStorage(targetDevice.randomId);
    const powerMode = await queryPowerMode(targetDevice.randomId);
    
    console.info('=== Device Status Summary ===');
    console.info(`Battery: ${batteryLevel}%`);
    console.info(`Charge Status: ${chargeStatus}`);
    console.info(`Wear Status: ${wearStatus}`);
    console.info(`Available Storage: ${(storageKB / 1024).toFixed(2)} MB`);
    console.info(`Power Mode: ${powerMode}`);
    
  } catch (error) {
    const businessError = error as BusinessError;
    console.error(`Failed to execute main function. Code is ${businessError.code}, message is ${businessError.message}`);
  }
}

// 执行主函数
main();