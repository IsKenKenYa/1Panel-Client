/**
 * 已连接对端设备查询完整示例
 * 本示例演示如何查询已连接的穿戴设备列表并获取设备详细信息
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 设备查询管理类
 * 封装设备查询相关功能
 */
export class DeviceQueryManager {
  private deviceClient: wearEngine.DeviceClient | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 初始化DeviceClient
   */
  async init(): Promise<void> {
    try {
      this.deviceClient = wearEngine.getDeviceClient(this.context);
      console.info('[DeviceQueryManager] Succeeded in getting device client.');
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`[DeviceQueryManager] Failed to get device client. Code: ${businessError.code}, Message: ${businessError.message}`);
      throw businessError;
    }
  }

  /**
   * 查询已连接设备列表
   * @returns 设备列表
   */
  async queryConnectedDevices(): Promise<wearEngine.Device[]> {
    if (!this.deviceClient) {
      await this.init();
    }

    try {
      const devices: wearEngine.Device[] = await this.deviceClient!.getConnectedDevices();
      console.info(`[DeviceQueryManager] Succeeded in getting device list. Count: ${devices.length}`);
      return devices;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`[DeviceQueryManager] Failed to get device list. Code: ${businessError.code}, Message: ${businessError.message}`);
      throw businessError;
    }
  }

  /**
   * 获取第一个可用的设备
   * @returns 第一个设备，如果没有设备则返回undefined
   */
  async getFirstAvailableDevice(): Promise<wearEngine.Device | undefined> {
    const devices = await this.queryConnectedDevices();
    if (devices.length > 0) {
      const device = devices[0];
      console.info(`[DeviceQueryManager] First device: ${device.name}, OS: ${device.osCategory}`);
      return device;
    }
    console.warn('[DeviceQueryManager] No connected devices found.');
    return undefined;
  }

  /**
   * 根据设备名称查找设备
   * @param deviceName 设备名称
   * @returns 匹配的设备，如果未找到则返回undefined
   */
  async findDeviceByName(deviceName: string): Promise<wearEngine.Device | undefined> {
    const devices = await this.queryConnectedDevices();
    const device = devices.find(d => d.name === deviceName);
    if (device) {
      console.info(`[DeviceQueryManager] Found device by name: ${device.name}`);
    } else {
      console.warn(`[DeviceQueryManager] Device not found with name: ${deviceName}`);
    }
    return device;
  }

  /**
   * 根据操作系统类型查找设备
   * @param osCategory 操作系统类型
   * @returns 匹配的设备列表
   */
  async findDevicesByOsCategory(osCategory: wearEngine.OsCategory): Promise<wearEngine.Device[]> {
    const devices = await this.queryConnectedDevices();
    const filteredDevices = devices.filter(d => d.osCategory === osCategory);
    console.info(`[DeviceQueryManager] Found ${filteredDevices.length} devices with OS: ${osCategory}`);
    return filteredDevices;
  }

  /**
   * 打印设备详细信息
   * @param device 设备对象
   */
  printDeviceInfo(device: wearEngine.Device): void {
    console.info('=== Device Information ===');
    console.info(`Random ID: ${device.randomId}`);
    console.info(`Name: ${device.name}`);
    console.info(`Category: ${device.category}`);
    console.info(`Model: ${device.model}`);
    console.info(`Software Version: ${device.softwareVersion}`);
    console.info(`Is Smart Watch: ${device.isSmartWatch}`);
    console.info(`OS Category: ${device.osCategory}`);
    console.info('==========================');
  }
}

/**
 * 使用示例
 */
@Entry
@Component
struct DeviceQueryExample {
  private deviceManager: DeviceQueryManager | null = null;
  @State deviceList: wearEngine.Device[] = [];
  @State selectedDevice: wearEngine.Device | null = null;
  @State statusMessage: string = '';

  aboutToAppear() {
    // 初始化设备查询管理器
    this.deviceManager = new DeviceQueryManager(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  /**
   * 查询设备列表
   */
  async queryDevices() {
    this.statusMessage = 'Querying devices...';
    
    try {
      if (!this.deviceManager) {
        this.statusMessage = 'Device manager not initialized';
        return;
      }

      this.deviceList = await this.deviceManager.queryConnectedDevices();
      
      if (this.deviceList.length === 0) {
        this.statusMessage = 'No connected devices found. Please connect a wearable device first.';
      } else {
        this.statusMessage = `Found ${this.deviceList.length} device(s)`;
        // 打印每个设备的信息
        this.deviceList.forEach((device, index) => {
          console.info(`\nDevice ${index + 1}:`);
          this.deviceManager!.printDeviceInfo(device);
        });
      }
    } catch (error) {
      const businessError = error as BusinessError;
      this.statusMessage = `Error: ${businessError.message}`;
      this.handleError(businessError);
    }
  }

  /**
   * 选择第一个设备
   */
  async selectFirstDevice() {
    try {
      if (!this.deviceManager) {
        this.statusMessage = 'Device manager not initialized';
        return;
      }

      const device = await this.deviceManager.getFirstAvailableDevice();
      if (device) {
        this.selectedDevice = device;
        this.statusMessage = `Selected device: ${device.name}`;
        this.deviceManager.printDeviceInfo(device);
      } else {
        this.statusMessage = 'No device available';
      }
    } catch (error) {
      const businessError = error as BusinessError;
      this.statusMessage = `Error: ${businessError.message}`;
    }
  }

  /**
   * 错误处理
   */
  private handleError(error: BusinessError): void {
    switch (error.code) {
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
        console.error(`Unknown error. Code: ${error.code}, Message: ${error.message}`);
    }
  }

  build() {
    Column({ space: 20 }) {
      Text('Device Query Example')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text(this.statusMessage)
        .fontSize(14)
        .fontColor('#666666')

      Button('Query Devices')
        .width('80%')
        .onClick(() => {
          this.queryDevices();
        })

      Button('Select First Device')
        .width('80%')
        .onClick(() => {
          this.selectFirstDevice();
        })

      if (this.deviceList.length > 0) {
        Text(`Device List (${this.deviceList.length}):`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20 })

        List({ space: 10 }) {
          ForEach(this.deviceList, (device: wearEngine.Device, index: number) => {
            ListItem() {
              Column({ space: 5 }) {
                Text(`${index + 1}. ${device.name || 'Unknown'}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(`OS: ${device.osCategory || 'Unknown'}`)
                  .fontSize(12)
                Text(`Category: ${device.category || 'Unknown'}`)
                  .fontSize(12)
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
            }
          })
        }
        .width('90%')
        .height(300)
      }

      if (this.selectedDevice) {
        Text('Selected Device:')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20 })

        Column({ space: 5 }) {
          Text(`Name: ${this.selectedDevice.name || 'Unknown'}`)
          Text(`Model: ${this.selectedDevice.model || 'Unknown'}`)
          Text(`OS: ${this.selectedDevice.osCategory || 'Unknown'}`)
          Text(`Version: ${this.selectedDevice.softwareVersion || 'Unknown'}`)
        }
        .width('90%')
        .padding(10)
        .backgroundColor('#e8f4f8')
        .borderRadius(8)
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}