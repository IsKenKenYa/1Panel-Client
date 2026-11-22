import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

export class ConnectedDevicesManager {
  private deviceClient: wearEngine.DeviceClient | null = null;
  
  init(context: common.Context): void {
    this.deviceClient = wearEngine.getDeviceClient(context);
  }
  
  async queryConnectedDevices(): Promise<wearEngine.Device[]> {
    if (!this.deviceClient) {
      throw new Error('DeviceClient未初始化，请先调用init方法');
    }
    
    try {
      const devices: wearEngine.Device[] = await this.deviceClient.getConnectedDevices();
      console.info(`成功获取设备列表，设备数量: ${devices.length}`);
      
      if (devices.length === 0) {
        console.warn('当前没有已连接的穿戴设备');
      } else {
        devices.forEach((device, index) => {
          console.info(`设备${index + 1}:`);
          console.info(`  随机ID: ${device.randomId}`);
          console.info(`  设备名称: ${device.name || '未知'}`);
          console.info(`  设备类型: ${device.category}`);
          console.info(`  软件版本: ${device.softwareVersion || '未知'}`);
          console.info(`  设备型号: ${device.model || '未知'}`);
          console.info(`  是否为智能表: ${device.isSmartWatch}`);
        });
      }
      
      return devices;
    } catch (error) {
      const businessError = error as BusinessError;
      this.handleError(businessError);
      throw businessError;
    }
  }
  
  private handleError(error: BusinessError): void {
    const errorMessages: Record<number, string> = {
      401: '参数错误，请检查Context对象',
      801: '设备不支持此API',
      1008500001: '网络错误，请检查网络连接',
      1008500004: '应用未申请Wear Engine服务',
      1008500006: '用户未同意隐私授权',
      1008500008: '账号未登录',
      1008500009: '账号异常，请使用中国境内注册的华为账号',
      1008509999: '内部错误'
    };
    
    const message = errorMessages[error.code] || `未知错误: ${error.code}`;
    console.error(`获取设备列表失败: ${message}, 详细信息: ${error.message}`);
  }
  
  async getDeviceByRandomId(randomId: string): Promise<wearEngine.Device | null> {
    try {
      const devices = await this.queryConnectedDevices();
      return devices.find(device => device.randomId === randomId) || null;
    } catch (error) {
      console.error(`查找设备失败: ${(error as BusinessError).message}`);
      return null;
    }
  }
  
  async isDeviceConnected(randomId: string): Promise<boolean> {
    try {
      const devices = await this.queryConnectedDevices();
      return devices.some(device => device.randomId === randomId);
    } catch (error) {
      console.error(`检查设备连接状态失败: ${(error as BusinessError).message}`);
      return false;
    }
  }
  
  async getSmartWatchDevices(): Promise<wearEngine.Device[]> {
    try {
      const devices = await this.queryConnectedDevices();
      return devices.filter(device => device.isSmartWatch);
    } catch (error) {
      console.error(`获取智能表设备列表失败: ${(error as BusinessError).message}`);
      return [];
    }
  }
}