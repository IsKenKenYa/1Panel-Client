import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 穿戴设备状态监控完整示例
 * 本示例演示完整的设备状态查询、订阅、错误处理流程
 */

export class DeviceMonitor {
  private monitorClient: wearEngine.MonitorClient;
  private deviceClient: wearEngine.DeviceClient;
  private targetDevice: wearEngine.Device | null = null;
  
  // 订阅回调函数对象(必须保持引用)
  private callbacks: Map<string, (data: wearEngine.MonitorEventData) => void> = new Map();
  
  constructor() {
    this.monitorClient = wearEngine.getMonitorClient(this.getUIContext().getHostContext());
    this.deviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
  }
  
  /**
   * 初始化: 连接目标设备
   */
  async initialize(): Promise<boolean> {
    try {
      const devices: wearEngine.Device[] = await this.deviceClient.getConnectedDevices();
      
      if (devices.length === 0) {
        console.error('No connected device found');
        return false;
      }
      
      this.targetDevice = devices[0];
      console.info(`Connected to device: ${this.targetDevice.name} (${this.targetDevice.randomId})`);
      return true;
    } catch (error) {
      this.handleError(error as BusinessError);
      return false;
    }
  }
  
  /**
   * 查询设备所有状态
   */
  async queryAllStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not initialized');
      return;
    }
    
    try {
      const batteryLevel = await this.queryStatus(wearEngine.MonitorItem.POWER_STATUS);
      const chargeStatus = await this.queryStatus(wearEngine.MonitorItem.CHARGE_STATUS);
      const wearStatus = await this.queryStatus(wearEngine.MonitorItem.WEAR_STATUS);
      const storageKB = await this.queryStatus(wearEngine.MonitorItem.AVAILABLE_STORAGE_SPACE);
      const powerMode = await this.queryStatus(wearEngine.MonitorItem.POWER_MODE);
      
      console.info('=== Device Status ===');
      console.info(`Battery: ${batteryLevel}%`);
      console.info(`Charge: ${chargeStatus === 1 ? 'Charging' : chargeStatus === 2 ? 'Not Charging' : 'Full'}`);
      console.info(`Wear: ${wearStatus === 1 ? 'Wearing' : 'Not Wearing'}`);
      console.info(`Storage: ${(storageKB / 1024).toFixed(2)} MB`);
      console.info(`Mode: ${powerMode === 0 ? 'Smart' : powerMode === 1 ? 'Long Battery' : 'Unsupported'}`);
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }
  
  /**
   * 查询单个状态(支持重试)
   */
  private async queryStatus(item: wearEngine.MonitorItem, maxRetry = 3): Promise<number> {
    if (!this.targetDevice) {
      throw new Error('Device not initialized');
    }
    
    let retryCount = 0;
    while (retryCount < maxRetry) {
      try {
        const result = await this.monitorClient.queryStatus(this.targetDevice.randomId, item);
        return result.code;
      } catch (error) {
        const businessError = error as BusinessError;
        if (businessError.code === 1008500001) {
          // 网络错误,重试
          retryCount++;
          console.warn(`Network error, retrying... (${retryCount}/${maxRetry})`);
          await new Promise(resolve => setTimeout(resolve, 2000));
        } else {
          throw businessError;
        }
      }
    }
    throw new Error(`Failed after ${maxRetry} retries`);
  }
  
  /**
   * 订阅所有状态变化事件
   */
  async subscribeAllEvents(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not initialized');
      return;
    }
    
    try {
      // 定义回调函数
      const wearCallback = (data: wearEngine.MonitorEventData) => {
        console.info(`Wear status: ${data.data.code === 1 ? 'Wearing' : 'Not Wearing'}`);
      };
      
      const batteryCallback = (data: wearEngine.MonitorEventData) => {
        console.info(`Battery dropped to ${data.data.code}%`);
        if (data.data.code <= 20) {
          console.warn('Low battery warning!');
        }
      };
      
      const heartRateCallback = (data: wearEngine.MonitorEventData) => {
        const alarmTypes = ['Static High', 'Static Low', 'Exercise High', 'Exercise Low'];
        console.warn(`Heart rate alarm: ${alarmTypes[data.data.code - 1]}`);
      };
      
      const chargeCallback = (data: wearEngine.MonitorEventData) => {
        const chargeStatus = data.data.code === 1 ? 'Started' : data.data.code === 2 ? 'Stopped' : 'Completed';
        console.info(`Charge status: ${chargeStatus}`);
      };
      
      const connectionCallback = (data: wearEngine.MonitorEventData) => {
        const connStatus = data.data.code === 2 ? 'Connected' : data.data.code === 3 ? 'Disconnected' : 'Unbind';
        console.info(`Connection: ${connStatus}`);
      };
      
      const powerModeCallback = (data: wearEngine.MonitorEventData) => {
        const mode = data.data.code === 0 ? 'Smart Mode' : 'Long Battery Mode';
        console.info(`Power mode: ${mode}`);
      };
      
      // 保存回调函数对象
      this.callbacks.set('wear', wearCallback);
      this.callbacks.set('battery', batteryCallback);
      this.callbacks.set('heartRate', heartRateCallback);
      this.callbacks.set('charge', chargeCallback);
      this.callbacks.set('connection', connectionCallback);
      this.callbacks.set('powerMode', powerModeCallback);
      
      // 执行订阅
      await this.monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
        wearCallback
      );
      
      await this.monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
        batteryCallback
      );
      
      await this.monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_HEART_RATE_ALARM,
        heartRateCallback
      );
      
      await this.monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED,
        chargeCallback
      );
      
      await this.monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
        connectionCallback
      );
      
      await this.monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_POWER_MODE_CHANGED,
        powerModeCallback
      );
      
      console.info('=== All events subscribed ===');
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }
  
  /**
   * 取消所有订阅
   */
  async unsubscribeAllEvents(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not initialized');
      return;
    }
    
    try {
      // 取消订阅时必须传入与订阅时相同的回调对象
      const wearCallback = this.callbacks.get('wear');
      const batteryCallback = this.callbacks.get('battery');
      const heartRateCallback = this.callbacks.get('heartRate');
      const chargeCallback = this.callbacks.get('charge');
      const connectionCallback = this.callbacks.get('connection');
      const powerModeCallback = this.callbacks.get('powerMode');
      
      if (wearCallback) {
        await this.monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
          wearCallback
        );
      }
      
      if (batteryCallback) {
        await this.monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
          batteryCallback
        );
      }
      
      if (heartRateCallback) {
        await this.monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_HEART_RATE_ALARM,
          heartRateCallback
        );
      }
      
      if (chargeCallback) {
        await this.monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED,
          chargeCallback
        );
      }
      
      if (connectionCallback) {
        await this.monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
          connectionCallback
        );
      }
      
      if (powerModeCallback) {
        await this.monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_POWER_MODE_CHANGED,
          powerModeCallback
        );
      }
      
      // 清空回调函数对象
      this.callbacks.clear();
      
      console.info('=== All events unsubscribed ===');
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }
  
  /**
   * 统一的错误处理
   */
  private handleError(error: BusinessError): void {
    const errorMessages: Record<number, string> = {
      401: '参数错误',
      801: '设备不支持此能力',
      1008500001: '网络错误',
      1008500002: '无设备绑定',
      1008500003: '设备断开连接',
      1008500004: '应用未申请服务',
      1008500005: '账号未授权',
      1008500006: '隐私协议未同意',
      1008500007: '设备能力不支持',
      1008500008: '未登录华为账号',
      1008500009: '获取账号信息失败',
      1008500010: '设备ID无效',
      1008500012: '订阅回调过多',
      1008509999: '内部错误'
    };
    
    const message = errorMessages[error.code] || '未知错误';
    console.error(`Error ${error.code}: ${message}`);
    
    // 根据错误类型提供解决建议
    switch (error.code) {
      case 1008500003:
        console.warn('建议: 请检查设备连接状态,在运动健康App中查看设备是否在线');
        break;
      case 1008500006:
        console.warn('建议: 请引导用户同意隐私协议');
        break;
      case 1008500008:
        console.warn('建议: 请提示用户登录华为账号');
        break;
      case 1008500012:
        console.warn('建议: 减少重复订阅,取消无用订阅');
        break;
    }
  }
  
  /**
   * 获取设备信息
   */
  getDeviceInfo(): wearEngine.Device | null {
    return this.targetDevice;
  }
}

/**
 * 主函数: 演示完整流程
 */
async function main(): Promise<void> {
  const monitor = new DeviceMonitor();
  
  // 1. 初始化设备连接
  const initialized = await monitor.initialize();
  if (!initialized) {
    return;
  }
  
  // 2. 查询设备状态
  await monitor.queryAllStatus();
  
  // 3. 订阅状态变化
  await monitor.subscribeAllEvents();
  
  console.info('Monitoring device status for 60 seconds...');
  
  // 4. 等待状态变化
  await new Promise(resolve => setTimeout(resolve, 60000));
  
  // 5. 取消订阅
  await monitor.unsubscribeAllEvents();
  
  console.info('Monitoring stopped');
}

// 执行主函数
main();