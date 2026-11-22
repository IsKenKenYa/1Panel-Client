import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SubscribeStatusExample {
  private targetDevice: wearEngine.Device | null = null;
  private wearStatusCallback: (data: wearEngine.MonitorEventData) => void | null = null;
  private powerStatusCallback: (data: wearEngine.MonitorEventData) => void | null = null;
  private chargeStatusCallback: (data: wearEngine.MonitorEventData) => void | null = null;
  private connectionStatusCallback: (data: wearEngine.MonitorEventData) => void | null = null;
  
  private @State wearStatus: string = '未查询';
  private @State powerLevel: string = '未查询';
  private @State chargeStatus: string = '未查询';
  private @State connectionStatus: string = '未查询';
  
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
  
  async subscribeWearStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      this.wearStatusCallback = (monitorEventData: wearEngine.MonitorEventData) => {
        let wearStatusText: string = monitorEventData.data.code === 1 ? '佩戴中' : '未佩戴';
        this.wearStatus = wearStatusText;
        console.info(`佩戴状态变化: ${wearStatusText}`);
      };
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
        this.wearStatusCallback
      );
      
      console.info('订阅佩戴状态成功');
      AlertDialog.show({
        message: '订阅佩戴状态成功'
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`订阅佩戴状态失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async subscribePowerStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      this.powerStatusCallback = (monitorEventData: wearEngine.MonitorEventData) => {
        this.powerLevel = `${monitorEventData.data.code}%`;
        console.info(`电量降低: ${monitorEventData.data.code}%`);
      };
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
        this.powerStatusCallback
      );
      
      console.info('订阅电量状态成功');
      AlertDialog.show({
        message: '订阅电量状态成功'
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`订阅电量状态失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async subscribeChargeStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      this.chargeStatusCallback = (monitorEventData: wearEngine.MonitorEventData) => {
        let chargeStatusText: string = '';
        switch (monitorEventData.data.code) {
          case 1:
            chargeStatusText = '充电开始';
            break;
          case 2:
            chargeStatusText = '充电结束';
            break;
          case 3:
            chargeStatusText = '充电完成';
            break;
        }
        this.chargeStatus = chargeStatusText;
        console.info(`充电状态变化: ${chargeStatusText}`);
      };
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED,
        this.chargeStatusCallback
      );
      
      console.info('订阅充电状态成功');
      AlertDialog.show({
        message: '订阅充电状态成功'
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`订阅充电状态失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async subscribeConnectionStatus(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      this.connectionStatusCallback = (monitorEventData: wearEngine.MonitorEventData) => {
        let connectionStatusText: string = '';
        switch (monitorEventData.data.code) {
          case 2:
            connectionStatusText = '连接成功';
            break;
          case 3:
            connectionStatusText = '连接断开';
            break;
          case 5:
            connectionStatusText = '设备解绑';
            break;
        }
        this.connectionStatus = connectionStatusText;
        console.info(`连接状态变化: ${connectionStatusText}`);
      };
      
      await monitorClient.subscribeEvent(
        this.targetDevice.randomId,
        wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
        this.connectionStatusCallback
      );
      
      console.info('订阅连接状态成功');
      AlertDialog.show({
        message: '订阅连接状态成功'
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`订阅连接状态失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  async unsubscribeAll(): Promise<void> {
    if (!this.targetDevice) {
      console.error('Device not prepared.');
      return;
    }
    
    try {
      let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(
        this.getUIContext().getHostContext()
      );
      
      if (this.wearStatusCallback) {
        await monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_WEAR_STATUS_CHANGED,
          this.wearStatusCallback
        );
        this.wearStatusCallback = null;
      }
      
      if (this.powerStatusCallback) {
        await monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
          this.powerStatusCallback
        );
        this.powerStatusCallback = null;
      }
      
      if (this.chargeStatusCallback) {
        await monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_CHARGE_STATUS_CHANGED,
          this.chargeStatusCallback
        );
        this.chargeStatusCallback = null;
      }
      
      if (this.connectionStatusCallback) {
        await monitorClient.unsubscribeEvent(
          this.targetDevice.randomId,
          wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED,
          this.connectionStatusCallback
        );
        this.connectionStatusCallback = null;
      }
      
      console.info('取消所有订阅成功');
      AlertDialog.show({
        message: '取消所有订阅成功'
      });
    } catch (error) {
      let businessError: BusinessError = error as BusinessError;
      console.error(`取消订阅失败. Code: ${businessError.code}, Message: ${businessError.message}`);
    }
  }
  
  build() {
    Column() {
      Text('订阅设备状态示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Text(`佩戴状态: ${this.wearStatus}`)
        .fontSize(16)
        .margin({ bottom: 10 })
      
      Text(`电量: ${this.powerLevel}`)
        .fontSize(16)
        .margin({ bottom: 10 })
      
      Text(`充电状态: ${this.chargeStatus}`)
        .fontSize(16)
        .margin({ bottom: 10 })
      
      Text(`连接状态: ${this.connectionStatus}`)
        .fontSize(16)
        .margin({ bottom: 20 })
      
      Button('订阅佩戴状态')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.subscribeWearStatus())
      
      Button('订阅电量状态')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.subscribePowerStatus())
      
      Button('订阅充电状态')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.subscribeChargeStatus())
      
      Button('订阅连接状态')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => this.subscribeConnectionStatus())
      
      Button('取消所有订阅')
        .width('80%')
        .onClick(() => this.unsubscribeAll())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}