import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct SelectDeviceByCategoryExample {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  build() {
    Column() {
      Button('选择手表类型设备')
        .onClick(async () => {
          try {
            const device = await this.selectWatchDevice();
            console.info('成功选择设备:', JSON.stringify(device));
          } catch (error) {
            console.error('选择设备失败:', error);
          }
        })
        .width('80%')
        .margin(20);
        
      Button('选择手环类型设备')
        .onClick(async () => {
          try {
            const device = await this.selectBandDevice();
            console.info('成功选择设备:', JSON.stringify(device));
          } catch (error) {
            console.error('选择设备失败:', error);
          }
        })
        .width('80%')
        .margin(20);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  async selectWatchDevice(): Promise<wearEngine.Device> {
    let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.context);
    
    let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    
    if (devices.length === 0) {
      throw new Error('设备列表为空，请先连接穿戴设备');
    }

    let targetDevice: wearEngine.Device | null = null;
    
    for (let index = 0; index < devices.length; index++) {
      const device = devices[index];
      
      if (device.category === wearEngine.DeviceCategory.WATCH) {
        targetDevice = device;
        console.info(`找到手表设备: ${device.name}, ID: ${device.randomId}`);
        break;
      }
    }

    if (!targetDevice) {
      throw new Error('未找到手表类型的设备');
    }

    return targetDevice;
  }

  async selectBandDevice(): Promise<wearEngine.Device> {
    let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.context);
    
    let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    
    if (devices.length === 0) {
      throw new Error('设备列表为空，请先连接穿戴设备');
    }

    let targetDevice: wearEngine.Device | null = null;
    
    for (let index = 0; index < devices.length; index++) {
      const device = devices[index];
      
      if (device.category === wearEngine.DeviceCategory.BAND) {
        targetDevice = device;
        console.info(`找到手环设备: ${device.name}, ID: ${device.randomId}`);
        break;
      }
    }

    if (!targetDevice) {
      throw new Error('未找到手环类型的设备');
    }

    return targetDevice;
  }
}