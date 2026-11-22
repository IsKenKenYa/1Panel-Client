/**
 * 完整查询流程示例
 * 本示例展示完整的穿戴设备信息查询流程，包含所有步骤和最佳实践
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 设备信息查询结果类
 */
export class DeviceInfoResult {
  deviceName: string = '';
  deviceModel: string = '';
  deviceRandomId: string = '';
  wearEngineCapabilities: Map<string, boolean> = new Map();
  deviceCapabilities: Map<string, boolean> = new Map();
  deviceSN: string = '';
  querySuccess: boolean = false;
  errors: string[] = [];
}

/**
 * 设备信息查询服务类
 * 提供完整的查询流程和结果管理
 */
export class DeviceInfoQueryService {
  private context: common.UIAbilityContext;
  private deviceClient: wearEngine.DeviceClient | null = null;
  private cachedDevices: wearEngine.Device[] = [];
  private cacheExpiry: number = 0;
  private readonly CACHE_DURATION: number = 300000; // 5分钟缓存

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 初始化服务
   */
  async initialize(): Promise<void> {
    console.info('Initializing DeviceInfoQueryService...');
    
    try {
      this.deviceClient = wearEngine.getDeviceClient(this.context);
      console.info('DeviceInfoQueryService initialized successfully');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to initialize service. Code: ${err.code}, Message: ${err.message}`);
      throw error;
    }
  }

  /**
   * 获取设备列表(带缓存)
   */
  async getDeviceList(useCache: boolean = true): Promise<wearEngine.Device[]> {
    // 检查缓存是否有效
    if (useCache && this.cachedDevices.length > 0 && Date.now() < this.cacheExpiry) {
      console.info('Using cached device list');
      return this.cachedDevices;
    }

    if (!this.deviceClient) {
      await this.initialize();
    }

    try {
      let devices = await this.deviceClient!.getConnectedDevices();
      
      // 更新缓存
      this.cachedDevices = devices;
      this.cacheExpiry = Date.now() + this.CACHE_DURATION;
      
      console.info(`Retrieved ${devices.length} connected devices`);
      return devices;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to get device list. Code: ${err.code}, Message: ${err.message}`);
      throw error;
    }
  }

  /**
   * 选择目标设备
   * 可根据名称、型号、类型等条件选择
   */
  selectTargetDevice(
    devices: wearEngine.Device[],
    criteria?: { name?: string; model?: string; isSmartWatch?: boolean }
  ): wearEngine.Device | null {
    if (devices.length === 0) {
      console.warn('No devices to select from');
      return null;
    }

    // 如果没有指定条件，返回第一个设备
    if (!criteria) {
      console.info('No selection criteria specified, returning first device');
      return devices[0];
    }

    // 根据条件筛选设备
    let selectedDevices = devices.filter(device => {
      let match = true;
      
      if (criteria.name && device.name !== criteria.name) {
        match = false;
      }
      
      if (criteria.model && device.model !== criteria.model) {
        match = false;
      }
      
      if (criteria.isSmartWatch !== undefined && device.isSmartWatch !== criteria.isSmartWatch) {
        match = false;
      }
      
      return match;
    });

    if (selectedDevices.length === 0) {
      console.warn('No device matches the selection criteria');
      return null;
    }

    console.info(`Selected device: ${selectedDevices[0].name} (${selectedDevices[0].model})`);
    return selectedDevices[0];
  }

  /**
   * 查询单个设备的完整信息
   */
  async queryDeviceFullInfo(device: wearEngine.Device): Promise<DeviceInfoResult> {
    let result = new DeviceInfoResult();
    
    result.deviceName = device.name || 'Unknown';
    result.deviceModel = device.model || 'Unknown';
    result.deviceRandomId = device.randomId;

    console.info(`Starting full info query for device: ${result.deviceName}`);

    // 查询WearEngine能力集
    await this.queryWearEngineCapabilities(device, result);

    // 查询Device能力集
    await this.queryDeviceCapabilities(device, result);

    // 查询设备SN
    await this.queryDeviceSN(device, result);

    // 判断整体查询是否成功
    result.querySuccess = result.errors.length === 0;

    return result;
  }

  /**
   * 查询WearEngine能力集
   */
  private async queryWearEngineCapabilities(
    device: wearEngine.Device,
    result: DeviceInfoResult
  ): Promise<void> {
    console.info('Querying WearEngine capabilities...');

    let capabilities = [
      { enum: wearEngine.WearEngineCapability.P2P_COMMUNICATION, name: 'P2P_COMMUNICATION' },
      { enum: wearEngine.WearEngineCapability.MONITOR, name: 'MONITOR' },
      { enum: wearEngine.WearEngineCapability.NOTIFICATION, name: 'NOTIFICATION' },
      { enum: wearEngine.WearEngineCapability.SENSOR, name: 'SENSOR' }
    ];

    for (let cap of capabilities) {
      try {
        let isSupported = await device.isWearEngineCapabilitySupported(cap.enum);
        result.wearEngineCapabilities.set(cap.name, isSupported);
        console.info(`${cap.name}: ${isSupported}`);
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        result.wearEngineCapabilities.set(cap.name, false);
        result.errors.push(`Failed to query ${cap.name}: ${err.message}`);
        console.error(`Failed to query ${cap.name}. Code: ${err.code}, Message: ${err.message}`);
      }
    }
  }

  /**
   * 查询Device能力集
   */
  private async queryDeviceCapabilities(
    device: wearEngine.Device,
    result: DeviceInfoResult
  ): Promise<void> {
    console.info('Querying Device capabilities...');

    let capabilities = [
      { enum: wearEngine.DeviceCapability.APP_INSTALLATION, name: 'APP_INSTALLATION' },
      { enum: wearEngine.DeviceCapability.CBT_I, name: 'CBT_I' }
    ];

    for (let cap of capabilities) {
      try {
        let isSupported = await device.isDeviceCapabilitySupported(cap.enum);
        result.deviceCapabilities.set(cap.name, isSupported);
        console.info(`${cap.name}: ${isSupported}`);
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        result.deviceCapabilities.set(cap.name, false);
        result.errors.push(`Failed to query ${cap.name}: ${err.message}`);
        console.error(`Failed to query ${cap.name}. Code: ${err.code}, Message: ${err.message}`);
      }
    }
  }

  /**
   * 查询设备SN
   */
  private async queryDeviceSN(device: wearEngine.Device, result: DeviceInfoResult): Promise<void> {
    console.info('Querying device SN...');

    try {
      let sn = await device.getSerialNumber();
      result.deviceSN = sn;
      console.info(`Device SN: ${sn}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      result.errors.push(`Failed to query device SN: ${err.message}`);
      console.error(`Failed to query device SN. Code: ${err.code}, Message: ${err.message}`);
      
      // SN查询失败的特殊提示
      if (err.code === 1008500005) {
        result.errors.push('User needs to authorize device identifier permission in Huawei Health app');
      }
    }
  }

  /**
   * 执行完整查询流程
   * 包含初始化、获取设备列表、选择设备、查询信息
   */
  async executeFullQueryFlow(deviceSelectionCriteria?: any): Promise<DeviceInfoResult[]> {
    console.info('=== Starting Full Device Info Query Flow ===');

    let results: DeviceInfoResult[] = [];

    try {
      // 步骤1: 初始化服务
      await this.initialize();

      // 步骤2: 获取设备列表
      let devices = await this.getDeviceList(false); // 不使用缓存，获取最新数据

      if (devices.length === 0) {
        console.warn('No connected devices found');
        let emptyResult = new DeviceInfoResult();
        emptyResult.errors.push('No connected devices found');
        emptyResult.querySuccess = false;
        results.push(emptyResult);
        return results;
      }

      // 步骤3: 选择目标设备
      let targetDevice = this.selectTargetDevice(devices, deviceSelectionCriteria);

      if (!targetDevice) {
        console.warn('No device selected');
        let noSelectionResult = new DeviceInfoResult();
        noSelectionResult.errors.push('No device selected based on criteria');
        noSelectionResult.querySuccess = false;
        results.push(noSelectionResult);
        return results;
      }

      // 步骤4: 查询设备完整信息
      let deviceInfo = await this.queryDeviceFullInfo(targetDevice);
      results.push(deviceInfo);

      // 可选：查询所有设备的信息
      // for (let device of devices) {
      //   let info = await this.queryDeviceFullInfo(device);
      //   results.push(info);
      // }

      console.info('=== Full Device Info Query Flow Completed ===');
      return results;

    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Query flow failed. Code: ${err.code}, Message: ${err.message}`);
      
      let errorResult = new DeviceInfoResult();
      errorResult.errors.push(`Query flow failed: ${err.message}`);
      errorResult.querySuccess = false;
      results.push(errorResult);
      
      return results;
    }
  }

  /**
   * 批量查询所有设备信息
   */
  async batchQueryAllDevices(): Promise<DeviceInfoResult[]> {
    console.info('Starting batch query for all devices...');

    let devices = await this.getDeviceList(false);
    let results: DeviceInfoResult[] = [];

    for (let device of devices) {
      try {
        let info = await this.queryDeviceFullInfo(device);
        results.push(info);
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        let errorResult = new DeviceInfoResult();
        errorResult.deviceName = device.name || 'Unknown';
        errorResult.errors.push(`Query failed: ${err.message}`);
        errorResult.querySuccess = false;
        results.push(errorResult);
      }
    }

    console.info(`Batch query completed for ${results.length} devices`);
    return results;
  }

  /**
   * 查询特定能力支持情况
   */
  async checkSpecificCapability(
    deviceRandomId: string,
    capabilityType: 'WearEngine' | 'Device',
    capability: wearEngine.WearEngineCapability | wearEngine.DeviceCapability
  ): Promise<boolean> {
    console.info(`Checking ${capabilityType} capability for device ${deviceRandomId}`);

    let devices = await this.getDeviceList();
    let device = devices.find(d => d.randomId === deviceRandomId);

    if (!device) {
      console.error(`Device not found: ${deviceRandomId}`);
      throw new Error('Device not found');
    }

    try {
      if (capabilityType === 'WearEngine') {
        return await device.isWearEngineCapabilitySupported(capability as wearEngine.WearEngineCapability);
      } else {
        return await device.isDeviceCapabilitySupported(capability as wearEngine.DeviceCapability);
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Capability check failed. Code: ${err.code}, Message: ${err.message}`);
      throw error;
    }
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.cachedDevices = [];
    this.cacheExpiry = 0;
    console.info('Device list cache cleared');
  }

  /**
   * 打印查询结果摘要
   */
  printResultSummary(results: DeviceInfoResult[]): void {
    console.info('\n=== Query Results Summary ===');
    
    for (let result of results) {
      console.info(`\nDevice: ${result.deviceName} (${result.deviceModel})`);
      console.info(`RandomId: ${result.deviceRandomId}`);
      console.info(`SN: ${result.deviceSN || 'Not available'}`);
      console.info('WearEngine Capabilities:');
      
      for (let [key, value] of result.wearEngineCapabilities) {
        console.info(`  ${key}: ${value ? 'Supported' : 'Not supported'}`);
      }
      
      console.info('Device Capabilities:');
      for (let [key, value] of result.deviceCapabilities) {
        console.info(`  ${key}: ${value ? 'Supported' : 'Not supported'}`);
      }
      
      console.info(`Query Status: ${result.querySuccess ? 'Success' : 'Failed'}`);
      
      if (result.errors.length > 0) {
        console.info('Errors:');
        for (let error of result.errors) {
          console.info(`  - ${error}`);
        }
      }
    }
    
    console.info('\n=== Summary End ===');
  }
}

/**
 * 使用示例
 */
@Entry
@Component
struct FullQueryFlowExample {
  @State queryResults: DeviceInfoResult[] = [];
  @State isQuerying: boolean = false;
  @State message: string = '点击开始查询设备信息';

  private queryService: DeviceInfoQueryService | null = null;

  aboutToAppear() {
    let context = getContext(this) as common.UIAbilityContext;
    this.queryService = new DeviceInfoQueryService(context);
  }

  async startFullQuery(): Promise<void> {
    if (!this.queryService) {
      this.message = '服务未初始化';
      return;
    }

    this.isQuerying = true;
    this.message = '正在查询设备信息...';

    try {
      this.queryResults = await this.queryService.executeFullQueryFlow();
      this.queryService!.printResultSummary(this.queryResults);
      this.message = '查询完成';
    } catch (error) {
      this.message = '查询失败';
      console.error('Query failed:', error);
    } finally {
      this.isQuerying = false;
    }
  }

  build() {
    Column() {
      Text('完整查询流程示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(this.message)
        .fontSize(16)
        .margin({ bottom: 20 });

      Button('开始完整查询')
        .onClick(() => {
          this.startFullQuery();
        })
        .width('80%')
        .enabled(!this.isQuerying)
        .margin({ bottom: 20 });

      if (this.queryResults.length > 0) {
        Text('查询结果:')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 });

        ForEach(this.queryResults, (result: DeviceInfoResult, index: number) => {
          Column() {
            Text(`设备 ${index + 1}: ${result.deviceName}`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 5 });

            Text(`型号: ${result.deviceModel}`)
              .fontSize(12)
              .margin({ bottom: 5 });

            if (result.deviceSN) {
              Text(`SN: ${result.deviceSN}`)
                .fontSize(12)
                .margin({ bottom: 5 });
            }

            Text(`查询状态: ${result.querySuccess ? '成功' : '失败'}`)
              .fontSize(12)
              .fontColor(result.querySuccess ? Color.Green : Color.Red)
              .margin({ bottom: 10 });
          }
          .width('80%')
          .padding(10)
          .backgroundColor('#F0F0F0')
          .margin({ bottom: 10 });
        });
      }
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}