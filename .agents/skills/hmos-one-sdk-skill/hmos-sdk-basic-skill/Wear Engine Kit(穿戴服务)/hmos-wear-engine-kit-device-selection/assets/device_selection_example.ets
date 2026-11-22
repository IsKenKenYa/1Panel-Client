import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

interface DeviceSelectionResult {
  status: 'success' | 'error';
  device?: wearEngine.Device;
  errorMessage?: string;
  errorCode?: number;
  selectionStrategy: 'category' | 'wearEngineCapability' | 'deviceCapability';
  queryTime?: number;
}

@Entry
@Component
struct DeviceSelectionExample {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State deviceList: wearEngine.Device[] = [];
  @State selectedDevice: wearEngine.Device | null = null;
  @State resultMessage: string = '';

  build() {
    Column() {
      Text('设备选择示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin(20);
        
      Button('获取已连接设备列表')
        .onClick(async () => {
          await this.loadConnectedDevices();
        })
        .width('80%')
        .margin(10);
        
      if (this.deviceList.length > 0) {
        Text(`已连接设备数: ${this.deviceList.length}`)
          .fontSize(16)
          .margin(10);
        
        Button('按设备类型选择（手表）')
          .onClick(async () => {
            await this.selectDeviceByCategory(wearEngine.DeviceCategory.WATCH);
          })
          .width('80%')
          .margin(10);
          
        Button('按WearEngine能力选择（MONITOR）')
          .onClick(async () => {
            await this.selectDeviceByWearEngineCapability(wearEngine.WearEngineCapability.MONITOR);
          })
          .width('80%')
          .margin(10);
          
        Button('按Device能力选择（APP_INSTALLATION）')
          .onClick(async () => {
            await this.selectDeviceByDeviceCapability(wearEngine.DeviceCapability.APP_INSTALLATION);
          })
          .width('80%')
          .margin(10);
          
        Button('综合选择（带降级）')
          .onClick(async () => {
            await this.selectDeviceWithFallback();
          })
          .width('80%')
          .margin(10);
      }
      
      if (this.selectedDevice) {
        Text(`已选择设备: ${this.selectedDevice.name}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin(20);
        
        Text(`设备ID: ${this.selectedDevice.randomId}`)
          .fontSize(14)
          .margin(5);
        
        Text(`设备类型: ${this.selectedDevice.category}`)
          .fontSize(14)
          .margin(5);
        
        Text(`设备型号: ${this.selectedDevice.model}`)
          .fontSize(14)
          .margin(5);
        
        Text(`软件版本: ${this.selectedDevice.softwareVersion}`)
          .fontSize(14)
          .margin(5);
      }
      
      if (this.resultMessage) {
        Text(this.resultMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin(10);
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding(20);
  }

  async loadConnectedDevices(): Promise<void> {
    try {
      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.context);
      this.deviceList = await deviceClient.getConnectedDevices();
      
      if (this.deviceList.length === 0) {
        this.resultMessage = '未找到已连接的设备';
      } else {
        this.resultMessage = '';
        console.info(`获取到 ${this.deviceList.length} 个已连接设备`);
      }
    } catch (error) {
      const err = error as BusinessError;
      this.resultMessage = `获取设备列表失败: ${err.message}`;
      console.error('获取设备列表失败:', err);
    }
  }

  async selectDeviceByCategory(category: wearEngine.DeviceCategory): Promise<void> {
    const startTime = Date.now();
    
    try {
      if (this.deviceList.length === 0) {
        throw new Error('设备列表为空');
      }

      let targetDevice: wearEngine.Device | null = null;
      
      for (const device of this.deviceList) {
        if (device.category === category) {
          targetDevice = device;
          break;
        }
      }

      if (!targetDevice) {
        throw new Error(`未找到${category}类型的设备`);
      }

      this.selectedDevice = targetDevice;
      this.resultMessage = '';
      
      const queryTime = Date.now() - startTime;
      console.info(`成功选择设备，耗时: ${queryTime}ms`);
      
    } catch (error) {
      const err = error as BusinessError;
      this.selectedDevice = null;
      this.resultMessage = `选择失败: ${err.message}`;
      console.error('选择设备失败:', err);
    }
  }

  async selectDeviceByWearEngineCapability(capability: wearEngine.WearEngineCapability): Promise<void> {
    const startTime = Date.now();
    
    try {
      if (this.deviceList.length === 0) {
        throw new Error('设备列表为空');
      }

      let targetDevice: wearEngine.Device | null = null;
      
      for (const device of this.deviceList) {
        try {
          const isSupported = await device.isWearEngineCapabilitySupported(capability);
          
          if (isSupported) {
            targetDevice = device;
            break;
          }
        } catch (error) {
          const err = error as BusinessError;
          console.error(`查询设备${device.name}能力失败:`, err);
          continue;
        }
      }

      if (!targetDevice) {
        throw new Error(`未找到支持${capability}能力的设备`);
      }

      this.selectedDevice = targetDevice;
      this.resultMessage = '';
      
      const queryTime = Date.now() - startTime;
      console.info(`成功选择设备，耗时: ${queryTime}ms`);
      
    } catch (error) {
      const err = error as BusinessError;
      this.selectedDevice = null;
      this.resultMessage = `选择失败: ${err.message}`;
      console.error('选择设备失败:', err);
    }
  }

  async selectDeviceByDeviceCapability(capability: wearEngine.DeviceCapability): Promise<void> {
    const startTime = Date.now();
    
    try {
      if (this.deviceList.length === 0) {
        throw new Error('设备列表为空');
      }

      let targetDevice: wearEngine.Device | null = null;
      
      for (const device of this.deviceList) {
        try {
          const isSupported = await device.isDeviceCapabilitySupported(capability);
          
          if (isSupported) {
            targetDevice = device;
            break;
          }
        } catch (error) {
          const err = error as BusinessError;
          console.error(`查询设备${device.name}能力失败:`, err);
          continue;
        }
      }

      if (!targetDevice) {
        throw new Error(`未找到支持${capability}能力的设备`);
      }

      this.selectedDevice = targetDevice;
      this.resultMessage = '';
      
      const queryTime = Date.now() - startTime;
      console.info(`成功选择设备，耗时: ${queryTime}ms`);
      
    } catch (error) {
      const err = error as BusinessError;
      this.selectedDevice = null;
      this.resultMessage = `选择失败: ${err.message}`;
      console.error('选择设备失败:', err);
    }
  }

  async selectDeviceWithFallback(): Promise<void> {
    const startTime = Date.now();
    
    try {
      if (this.deviceList.length === 0) {
        throw new Error('设备列表为空');
      }

      let targetDevice: wearEngine.Device | null = null;
      
      for (const device of this.deviceList) {
        if (device.category === wearEngine.DeviceCategory.WATCH) {
          targetDevice = device;
          console.info('找到手表设备');
          break;
        }
      }

      if (!targetDevice) {
        for (const device of this.deviceList) {
          if (device.category === wearEngine.DeviceCategory.BAND) {
            targetDevice = device;
            console.info('手表未找到，使用手环设备作为备选');
            break;
          }
        }
      }

      if (!targetDevice && this.deviceList.length > 0) {
        targetDevice = this.deviceList[0];
        console.warn('使用第一个可用设备作为最终降级方案');
      }

      if (!targetDevice) {
        throw new Error('无法选择任何设备');
      }

      this.selectedDevice = targetDevice;
      this.resultMessage = '';
      
      const queryTime = Date.now() - startTime;
      console.info(`成功选择设备，耗时: ${queryTime}ms`);
      
    } catch (error) {
      const err = error as BusinessError;
      this.selectedDevice = null;
      this.resultMessage = `选择失败: ${err.message}`;
      console.error('选择设备失败:', err);
    }
  }
}