import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct QueryConnectedDevicesExample {
  @State deviceList: wearEngine.Device[] = [];
  @State targetDevice: wearEngine.Device | null = null;
  @State message: string = '';

  build() {
    Column() {
      Button('查询已连接设备')
        .onClick(() => {
          this.queryConnectedDevices();
        })
        .width('80%')
        .margin({ top: 20, bottom: 20 })

      Text(this.message)
        .width('80%')
        .fontSize(16)
        .margin({ bottom: 20 })

      if (this.deviceList.length > 0) {
        List() {
          ForEach(this.deviceList, (device: wearEngine.Device) => {
            ListItem() {
              Column() {
                Text(`设备名称: ${device.name ?? 'Unknown'}`)
                  .fontSize(14)
                  .margin({ bottom: 5 })
                Text(`设备型号: ${device.model ?? 'Unknown'}`)
                  .fontSize(14)
                  .margin({ bottom: 5 })
                Text(`设备类型: ${this.getDeviceCategoryText(device.category)}`)
                  .fontSize(14)
                  .margin({ bottom: 5 })
                Text(`操作系统: ${this.getOsCategoryText(device.osCategory)}`)
                  .fontSize(14)
                  .margin({ bottom: 5 })
                Text(`软件版本: ${device.softwareVersion ?? 'Unknown'}`)
                  .fontSize(14)
                  .margin({ bottom: 5 })
                Text(`是否智能表: ${device.isSmartWatch ? '是' : '否'}`)
                  .fontSize(14)
                  .margin({ bottom: 5 })
                Text(`设备ID: ${device.randomId}`)
                  .fontSize(12)
                  .fontColor('#888888')
                  .margin({ bottom: 10 })
              }
              .padding(15)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .margin({ bottom: 10 })
            }
          })
        }
        .width('80%')
        .height('50%')
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }

  private async queryConnectedDevices(): Promise<void> {
    try {
      this.message = '正在查询设备...';

      let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();

      this.deviceList = devices;

      if (devices.length > 0) {
        this.message = `查询成功,找到 ${devices.length} 个设备`;
        this.targetDevice = devices[0];
        
        console.info(`Succeeded in getting deviceList, deviceList number is ${devices.length}`);
        console.info(`Target device: ${this.targetDevice?.name ?? 'Unknown'}`);
        
        let osCategory: wearEngine.OsCategory | undefined = this.targetDevice?.osCategory;
        console.info(`The osCategory of target device is ${osCategory}`);
      } else {
        this.message = '查询成功,但未找到已连接的设备';
        console.warn('No connected devices found');
      }
    } catch (error) {
      let businessError = error as BusinessError;
      this.message = `查询失败: ${businessError.message}`;
      console.error(`Failed to get deviceList. Code is ${businessError.code}, message is ${businessError.message}`);
      this.handleQueryError(businessError);
    }
  }

  private handleQueryError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error. Context parameter is incorrect.');
        this.message = '参数错误,请检查应用上下文';
        break;
      case 801:
        console.error('Capability not supported. This device does not support Wear Engine.');
        this.message = '当前设备不支持Wear Engine能力';
        break;
      case 1008500001:
        console.error('Network error. Please check network connection.');
        this.message = '网络错误,请检查网络连接';
        break;
      case 1008500002:
        console.error('No device is bound.');
        this.message = '无绑定设备,请先绑定穿戴设备';
        break;
      case 1008500003:
        console.error('Device disconnected.');
        this.message = '设备未连接,请检查蓝牙连接';
        break;
      case 1008500004:
        console.error('App has not applied for the Wear Engine service.');
        this.message = '应用未申请Wear Engine服务';
        break;
      case 1008500006:
        console.error('User privacy is not agreed.');
        this.message = '用户未同意隐私授权,请打开运动健康App';
        break;
      case 1008500008:
        console.error('Account error. User has not logged in with HUAWEI ID.');
        this.message = '账号未登录,请登录华为账号';
        break;
      case 1008500009:
        console.error('Account error. Failed to obtain account information.');
        this.message = '账号异常,请使用中国境内注册的账号';
        break;
      case 1008509999:
        console.error('Internal error.');
        this.message = '内部错误,请检查应用配置或重新连接设备';
        break;
      default:
        console.error(`Unknown error. Code: ${error.code}`);
        this.message = `未知错误: ${error.code}`;
    }
  }

  private getDeviceCategoryText(category?: wearEngine.DeviceCategory): string {
    if (!category) return 'Unknown';
    
    switch (category) {
      case wearEngine.DeviceCategory.DEFAULT:
        return '手机/平板';
      case wearEngine.DeviceCategory.WATCH:
        return '手表';
      case wearEngine.DeviceCategory.BAND:
        return '手环';
      case wearEngine.DeviceCategory.OTHER_DEVICES:
        return '其他设备';
      default:
        return 'Unknown';
    }
  }

  private getOsCategoryText(osCategory?: wearEngine.OsCategory): string {
    if (!osCategory) return 'Unknown';
    
    switch (osCategory) {
      case wearEngine.OsCategory.HARMONYOS:
        return 'HarmonyOS';
      case wearEngine.OsCategory.IOS:
        return 'iOS';
      case wearEngine.OsCategory.OTHER_OS:
        return '其他系统';
      default:
        return 'Unknown';
    }
  }
}