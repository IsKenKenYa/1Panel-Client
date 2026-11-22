import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

class WearDeviceQueryManager {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async queryDevicesWithRetry(maxRetries: number = 3): Promise<wearEngine.Device[] | null> {
    let retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        console.info(`Attempting to query devices (attempt ${retryCount + 1}/${maxRetries})`);
        
        let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.context);
        let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
        
        console.info(`Successfully queried ${devices.length} devices`);
        return devices;
        
      } catch (error) {
        let businessError = error as BusinessError;
        retryCount++;
        
        console.error(`Query attempt ${retryCount} failed: Code ${businessError.code}, Message: ${businessError.message}`);
        
        if (this.shouldRetry(businessError.code) && retryCount < maxRetries) {
          console.info('Retrying after 2 seconds...');
          await this.delay(2000);
        } else {
          console.error('Max retries reached or error is not retryable');
          this.handleFinalError(businessError);
          return null;
        }
      }
    }
    
    return null;
  }

  private shouldRetry(errorCode: number): boolean {
    const retryableErrors = [
      1008500001,
      1008500003,
      1008509999
    ];
    
    return retryableErrors.includes(errorCode);
  }

  private handleFinalError(error: BusinessError): void {
    const errorHandlers: Record<number, () => void> = {
      401: () => this.showParameterErrorDialog(),
      801: () => this.showCapabilityNotSupportedDialog(),
      1008500001: () => this.showNetworkErrorDialog(),
      1008500002: () => this.showNoDeviceBoundDialog(),
      1008500003: () => this.showDeviceDisconnectedDialog(),
      1008500004: () => this.showServiceNotAppliedDialog(),
      1008500006: () => this.showPrivacyNotAgreedDialog(),
      1008500008: () => this.showAccountNotLoggedInDialog(),
      1008500009: () => this.showAccountErrorDialog(),
      1008509999: () => this.showInternalErrorDialog()
    };

    const handler = errorHandlers[error.code];
    if (handler) {
      handler();
    } else {
      this.showUnknownErrorDialog(error.code, error.message);
    }
  }

  private showParameterErrorDialog(): void {
    console.log('Dialog: 参数错误,请检查Context参数是否正确');
    console.log('建议: 确保使用UIAbilityContext或其他包含connectServiceExtensionAbility方法的Context');
  }

  private showCapabilityNotSupportedDialog(): void {
    console.log('Dialog: 当前设备不支持Wear Engine能力');
    console.log('建议: 仅在Phone或Tablet设备上调用此接口');
  }

  private showNetworkErrorDialog(): void {
    console.log('Dialog: 网络错误,无法查询设备');
    console.log('建议: 请检查网络连接是否正常,尝试切换网络环境');
  }

  private showNoDeviceBoundDialog(): void {
    console.log('Dialog: 无绑定设备');
    console.log('建议: 请在运动健康App中先绑定穿戴设备');
  }

  private showDeviceDisconnectedDialog(): void {
    console.log('Dialog: 设备未连接');
    console.log('建议: 请检查设备蓝牙是否开启,运动健康App是否已连接设备');
  }

  private showServiceNotAppliedDialog(): void {
    console.log('Dialog: 应用未申请Wear Engine服务');
    console.log('建议: 请在开发者联盟申请WearEngine服务,并在metadata中配置clientId');
  }

  private showPrivacyNotAgreedDialog(): void {
    console.log('Dialog: 用户未同意隐私授权');
    console.log('建议: 请引导用户打开运动健康App并同意隐私授权');
  }

  private showAccountNotLoggedInDialog(): void {
    console.log('Dialog: 账号未登录');
    console.log('建议: 请提示用户登录华为账号后重新尝试');
  }

  private showAccountErrorDialog(): void {
    console.log('Dialog: 账号异常');
    console.log('建议: 请使用注册地为中国境内的华为账号(不含港澳台)');
  }

  private showInternalErrorDialog(): void {
    console.log('Dialog: 内部错误');
    console.log('建议: 请检查应用签名证书、metadata配置clientId,或尝试重新连接设备');
  }

  private showUnknownErrorDialog(code: number, message: string): void {
    console.log(`Dialog: 未知错误 (${code})`);
    console.log(`错误信息: ${message}`);
    console.log('建议: 请通过在线提单提交问题,华为支持人员会及时处理');
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  async checkDeviceCapability(device: wearEngine.Device): Promise<void> {
    try {
      console.info('Checking device capabilities...');
      
      const capabilities = [
        wearEngine.WearEngineCapability.P2P_COMMUNICATION,
        wearEngine.WearEngineCapability.MONITOR,
        wearEngine.WearEngineCapability.NOTIFICATION,
        wearEngine.WearEngineCapability.SENSOR
      ];
      
      for (const capability of capabilities) {
        const isSupported = await device.isWearEngineCapabilitySupported(capability);
        console.info(`WearEngineCapability ${capability}: ${isSupported ? 'Supported' : 'Not Supported'}`);
      }
      
      const deviceCapabilities = [
        wearEngine.DeviceCapability.APP_INSTALLATION,
        wearEngine.DeviceCapability.CBT_I
      ];
      
      for (const capability of deviceCapabilities) {
        const isSupported = await device.isDeviceCapabilitySupported(capability);
        console.info(`DeviceCapability ${capability}: ${isSupported ? 'Supported' : 'Not Supported'}`);
      }
      
    } catch (error) {
      let businessError = error as BusinessError;
      console.error(`Failed to check device capabilities: Code ${businessError.code}, Message: ${businessError.message}`);
    }
  }

  async getDeviceSerialNumber(device: wearEngine.Device): Promise<string | null> {
    try {
      console.info('Getting device serial number...');
      const sn = await device.getSerialNumber();
      console.info(`Device SN: ${sn}`);
      return sn;
    } catch (error) {
      let businessError = error as BusinessError;
      console.error(`Failed to get device SN: Code ${businessError.code}, Message: ${businessError.message}`);
      
      if (businessError.code === 1008500005) {
        console.warn('The HUAWEI ID is not authorized for DEVICE_IDENTIFIER permission');
        console.log('建议: 请请求用户授权DEVICE_IDENTIFIER权限');
      }
      
      return null;
    }
  }
}

async function main(): Promise<void> {
  const context = getContext(this) as common.UIAbilityContext;
  const queryManager = new WearDeviceQueryManager(context);
  
  const devices = await queryManager.queryDevicesWithRetry(3);
  
  if (devices && devices.length > 0) {
    console.info(`Found ${devices.length} connected devices`);
    
    for (const device of devices) {
      console.info('---');
      console.info(`Device Name: ${device.name ?? 'Unknown'}`);
      console.info(`Device Model: ${device.model ?? 'Unknown'}`);
      console.info(`Device Category: ${device.category}`);
      console.info(`Device ID: ${device.randomId}`);
      console.info(`OS Category: ${device.osCategory}`);
      console.info(`Software Version: ${device.softwareVersion ?? 'Unknown'}`);
      console.info(`Is Smart Watch: ${device.isSmartWatch}`);
      
      await queryManager.checkDeviceCapability(device);
      
      const sn = await queryManager.getDeviceSerialNumber(device);
      if (sn) {
        console.info(`Device SN: ${sn}`);
      }
    }
  } else {
    console.error('Failed to query devices or no devices found');
  }
}

main();