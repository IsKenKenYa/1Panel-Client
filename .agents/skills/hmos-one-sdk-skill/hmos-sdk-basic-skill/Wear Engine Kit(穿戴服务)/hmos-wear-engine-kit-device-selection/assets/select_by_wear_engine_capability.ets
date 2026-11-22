import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct SelectDeviceByWearEngineCapabilityExample {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  build() {
    Column() {
      Button('选择支持MONITOR能力的设备')
        .onClick(async () => {
          try {
            const device = await this.selectDeviceByCapability(wearEngine.WearEngineCapability.MONITOR);
            console.info('成功选择设备:', JSON.stringify(device));
          } catch (error) {
            console.error('选择设备失败:', error);
          }
        })
        .width('80%')
        .margin(20);
        
      Button('选择支持SENSOR能力的设备')
        .onClick(async () => {
          try {
            const device = await this.selectDeviceByCapability(wearEngine.WearEngineCapability.SENSOR);
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

  async selectDeviceByCapability(capability: wearEngine.WearEngineCapability): Promise<wearEngine.Device> {
    let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.context);
    
    let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    
    if (devices.length === 0) {
      throw new Error('设备列表为空，请先连接穿戴设备');
    }

    let targetDevice: wearEngine.Device | null = null;
    
    for (let index = 0; index < devices.length; index++) {
      const device = devices[index];
      
      try {
        const isSupported = await device.isWearEngineCapabilitySupported(capability);
        
        if (isSupported) {
          targetDevice = device;
          console.info(`找到支持${capability}能力的设备: ${device.name}, ID: ${device.randomId}`);
          break;
        }
      } catch (error) {
        const err = error as BusinessError;
        console.error(`查询设备${device.name}能力失败: Code=${err.code}, Message=${err.message}`);
        continue;
      }
    }

    if (!targetDevice) {
      throw new Error(`未找到支持${capability}能力的设备`);
    }

    return targetDevice;
  }
}