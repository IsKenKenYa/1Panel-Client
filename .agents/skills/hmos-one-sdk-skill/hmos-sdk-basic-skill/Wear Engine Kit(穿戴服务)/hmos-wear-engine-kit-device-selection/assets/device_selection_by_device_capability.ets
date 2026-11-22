import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

async function selectDeviceByDeviceCapability(deviceList: wearEngine.Device[], targetCapability: wearEngine.DeviceCapability): Promise<wearEngine.Device> {
  let targetDevice: wearEngine.Device | undefined;
  
  for (let index = 0; index < deviceList.length; index++) {
    try {
      const isSupported = await deviceList[index].isDeviceCapabilitySupported(targetCapability);
      if (isSupported) {
        targetDevice = deviceList[index];
        console.info(`找到支持${targetCapability}能力的目标设备: ${deviceList[index].name}`);
        break;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`查询设备能力失败: ${err.message}`);
      continue;
    }
    
    if (index === deviceList.length - 1) {
      throw new Error('cannot find target device with Device capability: ' + targetCapability);
    }
  }
  
  if (!targetDevice) {
    throw new Error('The value of targetDevice is undefined');
  }
  
  return targetDevice;
}

async function main() {
  try {
    let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
    let deviceList: wearEngine.Device[] = await deviceClient.getConnectedDevices();
    
    if (deviceList.length === 0) {
      console.error('设备列表为空，请先连接设备');
      return;
    }
    
    let targetDevice = await selectDeviceByDeviceCapability(deviceList, wearEngine.DeviceCapability.APP_INSTALLATION);
    console.info(`成功选择支持应用安装能力的设备: ${targetDevice.name}`);
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`设备选择失败. Code: ${err.code}, Message: ${err.message}`);
  }
}

main();