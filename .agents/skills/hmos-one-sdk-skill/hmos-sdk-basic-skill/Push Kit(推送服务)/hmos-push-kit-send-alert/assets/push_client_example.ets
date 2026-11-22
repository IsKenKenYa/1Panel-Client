import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
      
      this.requestNotificationPermission();
      this.getPushToken();
    });
  }

  async requestNotificationPermission(): Promise<void> {
    try {
      await notificationManager.requestEnableNotification(this.context);
      hilog.info(DOMAIN, 'testTag', 'RequestEnableNotification success');
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, 'testTag', 
        `RequestEnableNotification failed, code is ${e.code}, message is ${e.message}`);
    }
  }

  async getPushToken(): Promise<string> {
    try {
      const token: string = await pushService.getToken();
      hilog.info(DOMAIN, 'testTag', 'Succeeded in getting push token: %{public}s', token);
      this.uploadTokenToServer(token);
      return token;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      this.handleTokenError(e);
      throw e;
    }
  }

  uploadTokenToServer(token: string): void {
    hilog.info(DOMAIN, 'testTag', 'Uploading push token to server...');
  }

  handleTokenError(error: BusinessError): void {
    switch (error.code) {
      case 1000900001:
        hilog.error(DOMAIN, 'testTag', 'System internal error');
        break;
      case 1000900008:
        hilog.error(DOMAIN, 'testTag', 'Failed to connect to the push service');
        break;
      case 1000900011:
        hilog.error(DOMAIN, 'testTag', 'The network is unavailable');
        break;
      case 1000900012:
        hilog.error(DOMAIN, 'testTag', 'Push rights are not activated');
        break;
      case 1000900014:
        hilog.error(DOMAIN, 'testTag', 'The device does not support getting token');
        break;
      default:
        hilog.error(DOMAIN, 'testTag', 'Unknown error: %{public}d %{public}s', error.code, error.message);
    }
  }
}