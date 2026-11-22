import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';

const TAG = 'MinorsProtection';
const DOMAIN = 0x0000;

@Entry
@Component
struct TurnOffMinorsProtectionPage {
  @State minorsProtectionMode: boolean = false;
  @State ageGroup: minorsProtection.AgeGroup | undefined = undefined;
  @State message: string = '';
  @State isProcessing: boolean = false;

  aboutToAppear() {
    this.checkMinorsProtectionStatus();
    this.subscribeMinorsModeEvents();
  }

  aboutToDisappear() {
    this.unsubscribeMinorsModeEvents();
  }

  checkMinorsProtectionStatus() {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      this.message = '当前设备不支持未成年人保护模式';
      hilog.info(DOMAIN, TAG, 'Device does not support minors protection');
      return;
    }

    try {
      if (minorsProtection.supportMinorsMode()) {
        const info = minorsProtection.getMinorsProtectionInfoSync();
        this.minorsProtectionMode = info.minorsProtectionMode;
        this.ageGroup = info.ageGroup;

        if (this.minorsProtectionMode) {
          this.message = '系统未成年人模式已开启';
          hilog.info(DOMAIN, TAG, `Minors mode is ON, ageGroup: ${JSON.stringify(this.ageGroup)}`);
        } else {
          this.message = '系统未成年人模式未开启';
          hilog.info(DOMAIN, TAG, 'Minors mode is OFF');
        }
      } else {
        this.message = '当前设备环境不支持未成年人模式';
        hilog.info(DOMAIN, TAG, 'Device environment does not support minors mode');
      }
    } catch (error) {
      this.message = `获取状态失败: ${error.message}`;
      hilog.error(DOMAIN, TAG, `Failed to check status: code=${error.code}, message=${error.message}`);
    }
  }

  turnOffMinorsProtection() {
    if (this.isProcessing) {
      hilog.warn(DOMAIN, TAG, 'Operation is already in progress');
      return;
    }

    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      this.message = '当前设备不支持此接口';
      return;
    }

    try {
      if (!minorsProtection.supportMinorsMode()) {
        this.message = '当前设备环境不支持未成年人模式';
        return;
      }

      if (!this.minorsProtectionMode) {
        this.message = '未成年人模式已关闭，无需重复操作';
        return;
      }

      this.isProcessing = true;
      this.message = '正在引导用户关闭未成年人模式...';

      minorsProtection.leadToTurnOffMinorsMode(this.getUIContext().getHostContext())
        .then(() => {
          this.isProcessing = false;
          this.minorsProtectionMode = false;
          this.ageGroup = undefined;
          this.message = '系统未成年人模式已关闭';
          hilog.info(DOMAIN, TAG, 'Successfully turned off minors mode');
        })
        .catch((error: BusinessError<Object>) => {
          this.isProcessing = false;
          this.handleTurnOffError(error);
        });
    } catch (error) {
      this.isProcessing = false;
      this.message = `调用失败: ${error.message}`;
      hilog.error(DOMAIN, TAG, `Exception: code=${error.code}, message=${error.message}`);
    }
  }

  handleTurnOffError(error: BusinessError<Object>) {
    hilog.error(DOMAIN, TAG, `Failed to turn off: code=${error.code}, message=${error.message}`);

    switch (error.code) {
      case 1009900003:
        this.message = '用户取消了关闭操作';
        hilog.info(DOMAIN, TAG, 'User canceled the operation');
        break;
      case 1009900006:
        this.message = '未成年人模式已经关闭';
        this.minorsProtectionMode = false;
        hilog.info(DOMAIN, TAG, 'Minors mode is already off');
        break;
      case 1009900011:
        this.message = '服务不可用，请退出隐私空间后重试';
        hilog.warn(DOMAIN, TAG, 'Service not available, user may be in privacy space');
        break;
      case 401:
        this.message = '参数错误，请检查调用方式';
        hilog.error(DOMAIN, TAG, 'Parameter error');
        break;
      case 1001502009:
        this.message = '内部错误，请重启设备后重试';
        hilog.error(DOMAIN, TAG, 'Internal error');
        break;
      default:
        this.message = `关闭失败: ${error.message}`;
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}`);
        break;
    }
  }

  subscribeMinorsModeEvents() {
    try {
      commonEventManager.subscribe('usual.event.MINORSMODE_ON', (data) => {
        hilog.info(DOMAIN, TAG, 'Received MINORSMODE_ON event');
        this.checkMinorsProtectionStatus();
      });

      commonEventManager.subscribe('usual.event.MINORSMODE_OFF', (data) => {
        hilog.info(DOMAIN, TAG, 'Received MINORSMODE_OFF event');
        this.minorsProtectionMode = false;
        this.ageGroup = undefined;
        this.message = '系统未成年人模式已关闭';
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to subscribe events: ${error.message}`);
    }
  }

  unsubscribeMinorsModeEvents() {
    try {
      commonEventManager.unsubscribe('usual.event.MINORSMODE_ON');
      commonEventManager.unsubscribe('usual.event.MINORSMODE_OFF');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to unsubscribe events: ${error.message}`);
    }
  }

  build() {
    Column() {
      Text('关闭系统未成年人模式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(`当前状态: ${this.message}`)
        .fontSize(16)
        .margin({ bottom: 10 });

      if (this.minorsProtectionMode && this.ageGroup) {
        Text(`年龄段: ${this.ageGroup.lowerAge}-${this.ageGroup.upperAge}岁`)
          .fontSize(14)
          .margin({ bottom: 20 });
      }

      Button(this.isProcessing ? '处理中...' : '关闭未成年人模式')
        .width('80%')
        .height(50)
        .enabled(!this.isProcessing && this.minorsProtectionMode)
        .onClick(() => {
          this.turnOffMinorsProtection();
        })
        .margin({ bottom: 20 });

      Button('刷新状态')
        .width('80%')
        .height(50)
        .onClick(() => {
          this.checkMinorsProtectionStatus();
        })
        .margin({ bottom: 20 });

      if (!this.minorsProtectionMode) {
        Text('提示: 系统未成年人模式已关闭')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 20 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}