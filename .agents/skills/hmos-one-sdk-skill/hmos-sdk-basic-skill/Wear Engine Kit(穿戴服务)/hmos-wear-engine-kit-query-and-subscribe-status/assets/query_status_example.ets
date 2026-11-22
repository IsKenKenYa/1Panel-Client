import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct QueryStatusExample {
  private targetDevice: wearEngine.Device | null = null;
  
  async aboutToAppear(): Promise<void> {
    await this.prepareDevice();
  }
  
  async prepareDevice(): Promise<void> {
    try {
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
      
      if (devices.length === 0) {
        console.error('No connected devices found.');
        return;
      }
      
      this.targetDevice = devices[0];
      
      let isMonitorSupported: boolean = await this.targetDevice.isWearEngineCapabilitySupported(
        wearEngine.WearEngineCapability.MONITOR
      );
      
      if (!isMonitorSupported) {
        console.error('Device does not support Monitor capability.');
        return;
      }
      
      console.info(`Target device: ${this.targetDevice.name}`);
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`Failed to prepare device. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async queryWearStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      let result: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.WEAR_STATUS
      );
      
      let wearStatusText: string = result.code === 1 ? '佩戴中' : '未佩戴';
      console.info(`佩戴状态: ${wearStatusText}`);
      AlertDialog.show({
        message: `佩戴状态: ${wearStatusText}`
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`查询佩戴状态失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async queryPowerStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      let result: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.POWER_STATUS
      );
      
      console.info(`电量状态: ${result.code}%`);
      AlertDialog.show({
        message: `电量状态: ${result.code}%`
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`查询电量状态失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async queryChargeStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      let result: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.CHARGE_STATUS
      );
      
      let chargeStatusText: string = '';
      switch (result.code) {
        case 1:
          chargeStatusText = '正在充电';
          break;
        case 2:
          chargeStatusText = '未充电';
          break;
        case 3:
          chargeStatusText = '电量已充满';
          break;
        default:
          chargeStatusText = '未知状态';
      }
      
      console.info(`充电状态: ${chargeStatusText}`);
      AlertDialog.show({
        message: `充电状态: ${chargeStatusText}`
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`查询充电状态失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async queryStorageStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      let result: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.AVAILABLE_STORAGE_SPACE
      );
      
      let storageKB: number = result.code;
      let storageMB: number = storageKB / 1024;
      
      console.info(`可用存储空间: ${storageMB.toFixed(2)} MB`);
      AlertDialog.show({
        message: `可用存储空间: ${storageMB.toFixed(2)} MB`
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`查询存储空间失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async queryPowerMode(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      let result: wearEngine.MonitorData = await monitorClient.queryStatus(
        this.targetDevice.randomId,
        wearEngine.MonitorItem.POWER_MODE
      );
      
      let powerModeText: string = '';
      switch (result.code) {
        case -1:
          powerModeText = '设备不支持模式切换';
          break;
        case 0:
          powerModeText = '智能模式';
          break;
        case 1:
          powerModeText = '超长续航模式';
          break;
        default:
          powerModeText = '未知模式';
      }
      
      console.info(`设备模式: ${powerModeText}`);
      AlertDialog.show({
        message: `设备模式: ${powerModeText}`
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`查询设备模式失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  build() {
    Column() {
      Text('查询设备状态示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Button('查询佩戴状态')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.queryWearStatus())
      
      Button('查询电量状态')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.queryPowerStatus())
      
      Button('查询充电状态')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.queryChargeStatus())
      
      Button('查询存储空间')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.queryStorageStatus())
      
      Button('查询设备模式')
        .width('80%')
        .onClick(() => this.queryPowerMode())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}