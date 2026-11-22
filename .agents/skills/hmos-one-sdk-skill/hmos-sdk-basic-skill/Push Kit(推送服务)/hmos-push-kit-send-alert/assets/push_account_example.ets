import { pushCommon, pushService } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';

const DOMAIN = 0x0000;
const PROFILE_ID = 'user_123_anonymous';

export class PushAccountManager {
  private profileId: string = PROFILE_ID;
  private appProfileType: pushCommon.AppProfileType = pushCommon.AppProfileType.PROFILE_TYPE_APPLICATION_ACCOUNT;

  async bindUserAccount(): Promise<void> {
    try {
      await pushService.bindAppProfileId(this.appProfileType, this.profileId);
      hilog.info(DOMAIN, 'testTag', 'Succeeded in binding app profile id: %{public}s', this.profileId);
      this.uploadProfileToServer(this.profileId);
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      this.handleBindError(e);
    }
  }

  async unbindUserAccount(): Promise<void> {
    try {
      await pushService.unbindAppProfileId(this.appProfileType, this.profileId);
      hilog.info(DOMAIN, 'testTag', 'Succeeded in unbinding app profile id');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      this.handleUnbindError(e);
    }
  }

  uploadProfileToServer(profileId: string): void {
    hilog.info(DOMAIN, 'testTag', 'Uploading profileId to server: %{public}s', profileId);
  }

  handleBindError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(DOMAIN, 'testTag', 'Parameter error: %{public}s', error.message);
        break;
      case 1000900001:
        hilog.error(DOMAIN, 'testTag', 'System internal error');
        break;
      case 1000900008:
        hilog.error(DOMAIN, 'testTag', 'Failed to connect to the push service');
        break;
      case 1000900015:
        hilog.error(DOMAIN, 'testTag', 'The number of bound profile-app relationships exceeds the maximum');
        break;
      case 1000900016:
        hilog.error(DOMAIN, 'testTag', 'The os distributed account is not logged in');
        break;
      default:
        hilog.error(DOMAIN, 'testTag', 'Unknown error: %{public}d %{public}s', error.code, error.message);
    }
  }

  handleUnbindError(error: BusinessError): void {
    hilog.error(DOMAIN, 'testTag', 'Failed to unbind profile id: %{public}d %{public}s', error.code, error.message);
  }
}

export default class PushMessageAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'PushMessageAbility onCreate');
    
    try {
      pushService.receiveMessage('DEFAULT', this, (payload) => {
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Receive message for DEFAULT type.');
        try {
          const data: string = payload?.data;
          if (data) {
            const notificationData = JSON.parse(data);
            hilog.info(DOMAIN, 'testTag', 'Succeeded in getting notification, data=%{public}s',
              JSON.stringify(notificationData?.notification));
            this.processNotificationData(notificationData);
          }
        } catch (err) {
          const e: BusinessError = err as BusinessError;
          hilog.error(DOMAIN, 'testTag', 'Failed to process data: %{public}d %{public}s.', e.code, e.message);
        }
      });
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'Succeeded in registering default message.');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Failed to register default message: %{public}d %{public}s', e.code, e.message);
    }
  }

  processNotificationData(notificationData: any): void {
    const title = notificationData?.notification?.title;
    const body = notificationData?.notification?.body;
    const customData = notificationData?.notification?.clickAction?.data;
    
    hilog.info(DOMAIN, 'testTag', 'Processing notification: title=%{public}s, body=%{public}s', title, body);
    
    if (customData) {
      hilog.info(DOMAIN, 'testTag', 'Custom data: %{public}s', JSON.stringify(customData));
    }
  }
}