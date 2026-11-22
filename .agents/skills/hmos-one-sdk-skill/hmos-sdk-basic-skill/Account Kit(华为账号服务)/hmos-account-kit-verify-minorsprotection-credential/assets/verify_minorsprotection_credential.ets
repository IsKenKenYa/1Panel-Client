import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';

const TAG = 'MinorsProtectionVerify';
const DOMAIN = 0x0000;

@Entry
@Component
struct MinorsProtectionVerifyPage {
  @State minorsModeEnabled: boolean = false;
  @State deviceSupport: boolean = false;
  @State verifyResult: boolean = false;
  @State ageGroupInfo: string = '';
  @State statusMessage: string = '';

  aboutToAppear() {
    this.checkMinorsModeStatus();
    this.subscribeMinorsModeEvents();
  }

  aboutToDisappear() {
    this.unsubscribeMinorsModeEvents();
  }

  checkMinorsModeStatus() {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      this.statusMessage = '当前设备不支持未成年人保护API';
      hilog.info(DOMAIN, TAG, 'Device does not support minors protection APIs.');
      return;
    }

    try {
      this.deviceSupport = minorsProtection.supportMinorsMode();
      
      if (!this.deviceSupport) {
        this.statusMessage = '当前设备环境不支持未成年人模式';
        hilog.info(DOMAIN, TAG, 'Device environment does not support minors mode.');
        return;
      }

      const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
      this.minorsModeEnabled = minorsProtectionInfo.minorsProtectionMode;

      if (this.minorsModeEnabled && minorsProtectionInfo.ageGroup) {
        this.ageGroupInfo = `年龄段: [${minorsProtectionInfo.ageGroup.lowerAge}, ${minorsProtectionInfo.ageGroup.upperAge})`;
        hilog.info(DOMAIN, TAG, `Minors mode enabled. Age group: ${this.ageGroupInfo}`);
      } else if (this.minorsModeEnabled) {
        this.ageGroupInfo = '年龄段信息未获取';
        hilog.info(DOMAIN, TAG, 'Minors mode enabled but age group not available.');
      } else {
        this.ageGroupInfo = '';
        this.statusMessage = '未成年人模式未开启';
        hilog.info(DOMAIN, TAG, 'Minors mode is not enabled.');
      }
    } catch (error) {
      const err = error as BusinessError<Object>;
      this.statusMessage = `检查状态失败: ${err.message}`;
      hilog.error(DOMAIN, TAG, 
        `Failed to check minors mode status. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  async verifyCredential() {
    if (!this.deviceSupport) {
      this.statusMessage = '设备不支持未成年人模式';
      return;
    }

    if (!this.minorsModeEnabled) {
      this.statusMessage = '请先开启未成年人模式';
      hilog.warn(DOMAIN, TAG, 'Minors mode is not enabled, cannot verify credential.');
      return;
    }

    try {
      const context = this.getUIContext().getHostContext();
      const result = await minorsProtection.verifyMinorsProtectionCredential(context);
      
      this.verifyResult = result;
      this.statusMessage = result ? '验证成功，可以修改设置' : '验证失败';
      
      hilog.info(DOMAIN, TAG, `Verification result: ${result}`);
      
      if (result) {
        this.modifySettings();
      }
    } catch (error) {
      const err = error as BusinessError<Object>;
      this.handleVerifyError(err);
    }
  }

  handleVerifyError(error: BusinessError<Object>) {
    switch (error.code) {
      case 1009900002:
        this.statusMessage = '未成年人模式未开启';
        hilog.error(DOMAIN, TAG, 'Minors mode is not enabled.');
        break;
      case 1009900003:
        this.statusMessage = '用户取消验证';
        hilog.error(DOMAIN, TAG, 'User canceled the operation.');
        break;
      case 1001502009:
        this.statusMessage = '内部错误，请稍后重试';
        hilog.error(DOMAIN, TAG, 'Internal error occurred.');
        break;
      case 401:
        this.statusMessage = '参数错误';
        hilog.error(DOMAIN, TAG, 'Parameter error. Check context parameter.');
        break;
      case 1009900007:
        this.statusMessage = '不支持的账号类型';
        hilog.error(DOMAIN, TAG, 'Unsupported account.');
        break;
      case 1009900011:
        this.statusMessage = '服务不可用，请退出隐私空间';
        hilog.error(DOMAIN, TAG, 'Service not available.');
        break;
      default:
        this.statusMessage = `验证失败: ${error.message}`;
        hilog.error(DOMAIN, TAG, 
          `Unknown error. Code: ${error.code}, Message: ${error.message}`);
    }
  }

  modifySettings() {
    hilog.info(DOMAIN, TAG, 'Modifying app minors protection settings...');
    this.statusMessage = '正在修改应用内未成年人模式设置';
  }

  private eventSubscribers: commonEventManager.CommonEventSubscriber[] = [];

  subscribeMinorsModeEvents() {
    const onSubscriber = commonEventManager.createCommonEventSubscriber(
      { event: 'usual.event.MINORSMODE_ON' }
    );
    
    commonEventManager.subscribeCommonEvent(onSubscriber, (err, data) => {
      if (!err) {
        hilog.info(DOMAIN, TAG, 'Minors mode turned on event received.');
        this.checkMinorsModeStatus();
      }
    });

    const offSubscriber = commonEventManager.createCommonEventSubscriber(
      { event: 'usual.event.MINORSMODE_OFF' }
    );
    
    commonEventManager.subscribeCommonEvent(offSubscriber, (err, data) => {
      if (!err) {
        hilog.info(DOMAIN, TAG, 'Minors mode turned off event received.');
        this.checkMinorsModeStatus();
      }
    });

    this.eventSubscribers.push(onSubscriber, offSubscriber);
  }

  unsubscribeMinorsModeEvents() {
    for (const subscriber of this.eventSubscribers) {
      commonEventManager.unsubscribeCommonEvent(subscriber, (err) => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'Failed to unsubscribe event.');
        }
      });
    }
    this.eventSubscribers = [];
  }

  build() {
    Column() {
      Text('未成年人模式设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      if (this.ageGroupInfo) {
        Text(this.ageGroupInfo)
          .fontSize(16)
          .margin({ bottom: 10 });
      }

      Text(this.statusMessage)
        .fontSize(14)
        .margin({ bottom: 20 })
        .fontColor(this.verifyResult ? Color.Green : Color.Red);

      Button('验证家长身份')
        .width('80%')
        .height(50)
        .enabled(this.minorsModeEnabled && this.deviceSupport)
        .onClick(() => {
          this.verifyCredential();
        });

      if (this.verifyResult) {
        Button('调整内容偏好设置')
          .width('80%')
          .height(50)
          .margin({ top: 10 })
          .onClick(() => {
            this.statusMessage = '内容偏好设置已调整';
          });

        Button('调整使用时长设置')
          .width('80%')
          .height(50)
          .margin({ top: 10 })
          .onClick(() => {
            this.statusMessage = '使用时长设置已调整';
          });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}