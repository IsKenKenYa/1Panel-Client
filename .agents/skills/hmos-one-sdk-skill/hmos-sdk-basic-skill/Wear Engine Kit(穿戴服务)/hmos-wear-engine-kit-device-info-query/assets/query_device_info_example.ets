/**
 * 穿戴设备信息查询完整示例
 * 本示例展示如何查询穿戴设备的各种信息：
 * 1. WearEngine能力集
 * 2. Device能力集
 * 3. 设备序列号(SN)
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct QueryDeviceInfoExample {
  @State deviceList: wearEngine.Device[] = [];
  @State selectedDevice: wearEngine.Device | null = null;
  @State deviceCapabilities: Map<string, boolean> = new Map();
  @State deviceSN: string = '';
  @State message: string = '准备查询设备信息';

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  /**
   * 获取已连接设备列表
   */
  async getConnectedDevices(): Promise<void> {
    try {
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.context);
      this.deviceList = await deviceClient.getConnectedDevices();
      
      if (this.deviceList.length === 0) {
        this.message = '未找到已连接的设备';
        console.warn('No connected devices found.');
        return;
      }

      this.message = `找到 ${this.deviceList.length} 个已连接设备`;
      console.info(`Succeeded in getting deviceList, devices number is ${this.deviceList.length}`);

      // 打印所有设备信息
      for (let device of this.deviceList) {
        console.info(`Device info:`);
        console.info(`  Name: ${device.name}`);
        console.info(`  Model: ${device.model}`);
        console.info(`  RandomId: ${device.randomId}`);
        console.info(`  Category: ${device.category}`);
        console.info(`  IsSmartWatch: ${device.isSmartWatch}`);
        console.info(`  SoftwareVersion: ${device.softwareVersion}`);
      }

      // 默认选择第一个设备
      if (this.deviceList.length > 0) {
        this.selectedDevice = this.deviceList[0];
        this.message = `已选择设备: ${this.selectedDevice.name}`;
      }

    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.message = `获取设备列表失败: ${err.message}`;
      console.error(`Failed to get deviceList. Code: ${err.code}, Message: ${err.message}`);
      this.handleGetDevicesError(err);
    }
  }

  /**
   * 查询所有WearEngine能力集
   */
  async queryAllWearEngineCapabilities(): Promise<void> {
    if (!this.selectedDevice) {
      this.message = '请先选择设备';
      return;
    }

    this.message = '正在查询WearEngine能力集...';

    let capabilities = [
      wearEngine.WearEngineCapability.P2P_COMMUNICATION,
      wearEngine.WearEngineCapability.MONITOR,
      wearEngine.WearEngineCapability.NOTIFICATION,
      wearEngine.WearEngineCapability.SENSOR
    ];

    let capabilityNames = ['P2P_COMMUNICATION', 'MONITOR', 'NOTIFICATION', 'SENSOR'];

    for (let i = 0; i < capabilities.length; i++) {
      try {
        let isSupported: boolean = await this.selectedDevice!.isWearEngineCapabilitySupported(capabilities[i]);
        this.deviceCapabilities.set(capabilityNames[i], isSupported);
        
        console.info(`${capabilityNames[i]} capability: ${isSupported}`);
        this.message = `${capabilityNames[i]}: ${isSupported ? '支持' : '不支持'}`;
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        console.error(`Failed to check ${capabilityNames[i]} capability. Code: ${err.code}, Message: ${err.message}`);
        this.deviceCapabilities.set(capabilityNames[i], false);
      }
    }

    this.message = 'WearEngine能力集查询完成';
  }

  /**
   * 查询所有Device能力集
   */
  async queryAllDeviceCapabilities(): Promise<void> {
    if (!this.selectedDevice) {
      this.message = '请先选择设备';
      return;
    }

    this.message = '正在查询Device能力集...';

    let capabilities = [
      wearEngine.DeviceCapability.APP_INSTALLATION,
      wearEngine.DeviceCapability.CBT_I
    ];

    let capabilityNames = ['APP_INSTALLATION', 'CBT_I'];

    for (let i = 0; i < capabilities.length; i++) {
      try {
        let isSupported: boolean = await this.selectedDevice!.isDeviceCapabilitySupported(capabilities[i]);
        this.deviceCapabilities.set(capabilityNames[i], isSupported);
        
        console.info(`${capabilityNames[i]} capability: ${isSupported}`);
        this.message = `${capabilityNames[i]}: ${isSupported ? '支持' : '不支持'}`;
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        console.error(`Failed to check ${capabilityNames[i]} capability. Code: ${err.code}, Message: ${err.message}`);
        this.deviceCapabilities.set(capabilityNames[i], false);
      }
    }

    this.message = 'Device能力集查询完成';
  }

  /**
   * 查询设备序列号
   */
  async queryDeviceSN(): Promise<void> {
    if (!this.selectedDevice) {
      this.message = '请先选择设备';
      return;
    }

    this.message = '正在查询设备SN...';

    try {
      let sn: string = await this.selectedDevice!.getSerialNumber();
      this.deviceSN = sn;
      this.message = `设备SN: ${sn}`;
      console.info(`Succeeded in getting device SN: ${sn}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.message = `查询设备SN失败: ${err.message}`;
      console.error(`Failed to get device SN. Code: ${err.code}, Message: ${err.message}`);
      
      // SN查询需要设备标识符权限
      if (err.code === 1008500005) {
        this.message = '请先在华为健康应用中授权设备标识符权限';
      }
    }
  }

  /**
   * 查询特定WearEngine能力
   */
  async querySpecificWearEngineCapability(capability: wearEngine.WearEngineCapability): Promise<boolean> {
    if (!this.selectedDevice) {
      this.message = '请先选择设备';
      return false;
    }

    try {
      let isSupported: boolean = await this.selectedDevice!.isWearEngineCapabilitySupported(capability);
      console.info(`WearEngine capability ${capability} support: ${isSupported}`);
      return isSupported;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to check WearEngine capability. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }

  /**
   * 查询特定Device能力
   */
  async querySpecificDeviceCapability(capability: wearEngine.DeviceCapability): Promise<boolean> {
    if (!this.selectedDevice) {
      this.message = '请先选择设备';
      return false;
    }

    try {
      let isSupported: boolean = await this.selectedDevice!.isDeviceCapabilitySupported(capability);
      console.info(`Device capability ${capability} support: ${isSupported}`);
      return isSupported;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to check Device capability. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }

  /**
   * 处理获取设备列表的错误
   */
  private handleGetDevicesError(error: BusinessError): void {
    switch (error.code) {
      case 1008500001:
        this.message = '网络错误，请检查网络连接';
        break;
      case 1008500004:
        this.message = '应用未申请Wear Engine服务，请先申请';
        break;
      case 1008500006:
        this.message = '用户隐私未同意，请先同意隐私协议';
        break;
      case 1008500008:
        this.message = '用户未登录华为账号，请先登录';
        break;
      case 1008500009:
        this.message = '获取账号信息失败，请重试';
        break;
      case 1008509999:
        this.message = '内部错误，请联系技术支持';
        break;
      default:
        this.message = `未知错误: ${error.code}`;
    }
  }

  /**
   * 完整的查询流程
   */
  async executeFullQueryFlow(): Promise<void> {
    // 步骤1: 获取设备列表
    await this.getConnectedDevices();

    if (this.deviceList.length === 0) {
      return;
    }

    // 步骤2: 查询所有WearEngine能力
    await this.queryAllWearEngineCapabilities();

    // 步骤3: 查询所有Device能力
    await this.queryAllDeviceCapabilities();

    // 步骤4: 查询设备SN(需要额外权限)
    await this.queryDeviceSN();

    this.message = '设备信息查询完成';
  }

  build() {
    Column() {
      Text('穿戴设备信息查询示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(this.message)
        .fontSize(16)
        .margin({ bottom: 20 });

      Button('获取设备列表')
        .onClick(() => {
          this.getConnectedDevices();
        })
        .width('80%')
        .margin({ bottom: 10 });

      Button('查询WearEngine能力')
        .onClick(() => {
          this.queryAllWearEngineCapabilities();
        })
        .width('80%')
        .margin({ bottom: 10 });

      Button('查询Device能力')
        .onClick(() => {
          this.queryAllDeviceCapabilities();
        })
        .width('80%')
        .margin({ bottom: 10 });

      Button('查询设备SN')
        .onClick(() => {
          this.queryDeviceSN();
        })
        .width('80%')
        .margin({ bottom: 10 });

      Button('完整查询流程')
        .onClick(() => {
          this.executeFullQueryFlow();
        })
        .width('80%')
        .margin({ bottom: 20 });

      if (this.selectedDevice) {
        Text(`当前设备: ${this.selectedDevice.name}`)
          .fontSize(14)
          .margin({ bottom: 10 });
        
        Text(`型号: ${this.selectedDevice.model}`)
          .fontSize(14)
          .margin({ bottom: 10 });
      }

      if (this.deviceSN) {
        Text(`设备SN: ${this.deviceSN}`)
          .fontSize(14)
          .margin({ bottom: 10 });
      }

      if (this.deviceCapabilities.size > 0) {
        Text('能力支持情况:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, bottom: 5 });

        ForEach(Array.from(this.deviceCapabilities.keys()), (key: string) => {
          Row() {
            Text(`${key}: `)
              .fontSize(12);
            Text(this.deviceCapabilities.get(key) ? '支持' : '不支持')
              .fontSize(12)
              .fontColor(this.deviceCapabilities.get(key) ? Color.Green : Color.Red);
          }
          .width('80%')
          .margin({ bottom: 5 });
        });
      }
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}