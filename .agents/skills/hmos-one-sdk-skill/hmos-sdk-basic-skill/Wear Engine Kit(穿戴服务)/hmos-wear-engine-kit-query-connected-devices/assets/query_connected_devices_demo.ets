import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConnectedDevicesManager } from './query_connected_devices.ets';

@Entry
@Component
struct QueryConnectedDevicesDemo {
  @State deviceList: wearEngine.Device[] = [];
  @State message: string = '';
  @State isLoading: boolean = false;
  
  private devicesManager: ConnectedDevicesManager = new ConnectedDevicesManager();
  
  aboutToAppear(): void {
    this.devicesManager.init(this.getUIContext().getHostContext());
  }
  
  async queryDevices(): Promise<void> {
    this.isLoading = true;
    this.message = '正在查询设备...';
    
    try {
      this.deviceList = await this.devicesManager.queryConnectedDevices();
      
      if (this.deviceList.length === 0) {
        this.message = '当前没有已连接的穿戴设备';
      } else {
        this.message = `成功获取${this.deviceList.length}个设备`;
      }
    } catch (error) {
      const businessError = error as BusinessError;
      this.message = `查询失败: ${businessError.message}`;
    } finally {
      this.isLoading = false;
    }
  }
  
  build() {
    Column() {
      Text('已连接穿戴设备查询示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
      
      Button('查询设备')
        .width('80%')
        .enabled(!this.isLoading)
        .onClick(() => {
          this.queryDevices();
        })
        .margin({ bottom: 20 })
      
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ bottom: 20 })
      }
      
      Text(this.message)
        .fontSize(16)
        .margin({ bottom: 20 })
      
      if (this.deviceList.length > 0) {
        List() {
          ForEach(this.deviceList, (device: wearEngine.Device, index: number) => {
            ListItem() {
              Column() {
                Text(`设备 ${index + 1}: ${device.name || '未知设备'}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 10 })
                
                Row() {
                  Text('随机ID:')
                    .fontSize(14)
                  Text(device.randomId)
                    .fontSize(14)
                    .fontColor('#666')
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .margin({ bottom: 5 })
                
                Row() {
                  Text('设备型号:')
                    .fontSize(14)
                  Text(device.model || '未知')
                    .fontSize(14)
                    .fontColor('#666')
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .margin({ bottom: 5 })
                
                Row() {
                  Text('软件版本:')
                    .fontSize(14)
                  Text(device.softwareVersion || '未知')
                    .fontSize(14)
                    .fontColor('#666')
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .margin({ bottom: 5 })
                
                Row() {
                  Text('设备类型:')
                    .fontSize(14)
                  Text(this.getDeviceCategoryName(device.category))
                    .fontSize(14)
                    .fontColor('#666')
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                .margin({ bottom: 5 })
                
                Row() {
                  Text('是否为智能表:')
                    .fontSize(14)
                  Text(device.isSmartWatch ? '是' : '否')
                    .fontSize(14)
                    .fontColor(device.isSmartWatch ? '#00AA00' : '#666')
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#F5F5F5')
              .borderRadius(10)
              .margin({ bottom: 10 })
            }
          }, (device: wearEngine.Device) => device.randomId)
        }
        .width('90%')
        .height('60%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
  
  private getDeviceCategoryName(category: number): string {
    const categoryNames: Record<number, string> = {
      1: '手机/平板',
      2: '手表',
      3: '手环',
      255: '其他设备'
    };
    return categoryNames[category] || '未知类型';
  }
}