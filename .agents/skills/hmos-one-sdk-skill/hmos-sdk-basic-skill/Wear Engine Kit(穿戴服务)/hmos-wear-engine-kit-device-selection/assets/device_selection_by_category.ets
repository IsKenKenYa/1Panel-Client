import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

async function selectDeviceByCategory(deviceList: wearEngine.Device[], targetCategory: wearEngine.DeviceCategory): Promise<wearEngine.Device> {
  let targetDevice: wearEngine.Device | undefined;
  
  for (let index = 0; index < deviceList.length; index++) {
    if (deviceList[index].category === targetCategory) {
      targetDevice = deviceList[index];
      console.info(`找到目标设备: ${deviceList[index].name}, 类型: ${targetCategory}`);
      break;
    }
    if (index === deviceList.length - 1) {
      throw new Error('cannot find target device with category: ' + targetCategory);
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
    
    let targetDevice = await selectDeviceByCategory(deviceList, wearEngine.DeviceCategory.WATCH);
    console.info(`成功选择目标设备: ${targetDevice.name}, 随机ID: ${targetDevice.randomId}`);
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`设备选择失败. Code: ${err.code}, Message: ${err.message}`);
  }
}

main();