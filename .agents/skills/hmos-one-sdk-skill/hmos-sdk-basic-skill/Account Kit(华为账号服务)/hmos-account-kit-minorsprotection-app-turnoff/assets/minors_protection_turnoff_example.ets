import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const TAG = 'MinorsProtectionTurnOff';
const DOMAIN = 0x0000;

let userTurnOffFlag: boolean = false;

function dealVerifyAllError(error: BusinessError<Object>): void {
  hilog.error(DOMAIN, TAG, `Failed to verify. Code: ${error.code}, message: ${error.message}`);
  switch (error.code) {
    case 1009900002:
      hilog.error(DOMAIN, TAG, 'Minors mode is not enabled.');
      break;
    case 1009900003:
      hilog.warn(DOMAIN, TAG, 'User canceled the operation.');
      break;
    case 1001502009:
      hilog.error(DOMAIN, TAG, 'Internal error occurred.');
      break;
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error. Context is invalid.');
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
  }
}

async function checkMinorsProtectionStatus(): Promise<boolean> {
  try {
    if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      if (minorsProtection.supportMinorsMode()) {
        const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo =
          minorsProtection.getMinorsProtectionInfoSync();
        const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
        hilog.info(DOMAIN, TAG,
          `Succeeded in getting minorsProtectionMode is: ${minorsProtectionMode.valueOf()}`);
        
        if (minorsProtectionMode && minorsProtectionInfo.ageGroup) {
          const ageGroup: minorsProtection.AgeGroup = minorsProtectionInfo.ageGroup;
          hilog.info(DOMAIN, TAG,
            `Age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        }
        
        return minorsProtectionMode;
      } else {
        hilog.info(DOMAIN, TAG,
          'The current device environment does not support the minors mode.');
        return false;
      }
    } else {
      hilog.info(DOMAIN, TAG,
        'The current device does not support the minors protection capability.');
      return false;
    }
  } catch (error) {
    hilog.error(DOMAIN, TAG,
      `Failed to get minors protection status. errCode: ${error.code}, errMessage: ${error.message}`);
    return false;
  }
}

async function verifyAndTurnOffMinorsProtection(context: common.Context): Promise<boolean> {
  try {
    const minorsModeEnabled: boolean = await checkMinorsProtectionStatus();
    if (!minorsModeEnabled) {
      hilog.warn(DOMAIN, TAG, 'Minors mode is not enabled, cannot verify.');
      return false;
    }

    const verifyResult: boolean = await minorsProtection.verifyMinorsProtectionCredential(context);
    hilog.info(DOMAIN, TAG, `Succeeded in getting verify result is: ${verifyResult.valueOf()}`);

    if (verifyResult) {
      userTurnOffFlag = true;
      hilog.info(DOMAIN, TAG, 'Application minors mode turned off successfully.');
      return true;
    } else {
      hilog.warn(DOMAIN, TAG, 'Verification failed, minors mode password incorrect.');
      return false;
    }
  } catch (error) {
    const businessError: BusinessError<Object> = error as BusinessError<Object>;
    dealVerifyAllError(businessError);
    return false;
  }
}

function subscribeMinorsModeEvents(): void {
  const subscriber = commonEventManager.createSubscriber({
    events: [
      commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_ON,
      commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_OFF
    ]
  });

  commonEventManager.subscribeCommonEvent(subscriber, (err, data) => {
    if (err) {
      hilog.error(DOMAIN, TAG, `Failed to subscribe event: ${err.message}`);
      return;
    }
    if (data.event === commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_ON) {
      hilog.info(DOMAIN, TAG, 'Minors mode turned on.');
      if (!userTurnOffFlag) {
        const info = minorsProtection.getMinorsProtectionInfoSync();
        if (info.ageGroup) {
          hilog.info(DOMAIN, TAG,
            `Age group: [${info.ageGroup.lowerAge}, ${info.ageGroup.upperAge})`);
        }
      }
    } else if (data.event === commonEventManager.CommonEventSupport.COMMON_EVENT_MINORSMODE_OFF) {
      hilog.info(DOMAIN, TAG, 'Minors mode turned off.');
      userTurnOffFlag = false;
    }
  });
}

function unsubscribeMinorsModeEvents(subscriber: commonEventManager.CommonEventSubscriber): void {
  commonEventManager.unsubscribeCommonEvent(subscriber, (err) => {
    if (err) {
      hilog.error(DOMAIN, TAG, `Failed to unsubscribe event: ${err.message}`);
    } else {
      hilog.info(DOMAIN, TAG, 'Unsubscribed minors mode events successfully.');
    }
  });
}

@Entry
@Component
struct MinorsProtectionTurnOffPage {
  private context: common.Context | null = null;
  private eventSubscriber: commonEventManager.CommonEventSubscriber | null = null;

  aboutToAppear(): void {
    this.context = this.getUIContext().getHostContext();
    subscribeMinorsModeEvents();
  }

  aboutToDisappear(): void {
    if (this.eventSubscriber) {
      unsubscribeMinorsModeEvents(this.eventSubscriber);
    }
  }

  build() {
    Column() {
      Text('关闭应用未成年人模式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Button('验证并关闭未成年人模式')
        .width('80%')
        .height(50)
        .onClick(async () => {
          if (this.context) {
            const result: boolean = await verifyAndTurnOffMinorsProtection(this.context);
            if (result) {
              AlertDialog.show({
                title: '提示',
                message: '应用的未成年人模式已关闭，系统的未成年人模式仍保持开启',
                confirm: {
                  value: '确定',
                  action: () => {}
                }
              });
            }
          } else {
            hilog.error(DOMAIN, TAG, 'Context is null, cannot verify.');
          }
        });

      Text(`关闭状态标记: ${userTurnOffFlag ? '已关闭' : '未关闭'}`)
        .fontSize(16)
        .margin({ top: 20 });

      Text('注意: 仅关闭应用的未成年人模式，系统的未成年人模式仍保持开启')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10, bottom: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}