import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'EntryAbility onCreate');
    
    this.getPushToken();
  }

  private getPushToken(): void {
    pushService.getToken().then((token: string) => {
      hilog.info(DOMAIN, 'testTag', 'Succeeded in getting push token: %{public}s', token);
      this.reportTokenToServer(token);
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to get push token: %{public}d %{public}s', err.code, err.message);
      this.handleTokenError(err);
    });
  }

  private reportTokenToServer(token: string): void {
    hilog.info(DOMAIN, 'testTag', 'Report token to server: %{public}s', token);
  }

  private handleTokenError(err: BusinessError): void {
    switch (err.code) {
      case 1000900001:
        hilog.error(DOMAIN, 'testTag', 'System internal error');
        break;
      case 1000900008:
        hilog.error(DOMAIN, 'testTag', 'Failed to connect to push service');
        break;
      case 1000900009:
        hilog.error(DOMAIN, 'testTag', 'Internal error of push service');
        break;
      case 1000900010:
        hilog.error(DOMAIN, 'testTag', 'APP identity verification failed - Check AGC configuration');
        break;
      case 1000900011:
        hilog.error(DOMAIN, 'testTag', 'Network unavailable - Check network connection');
        break;
      case 1000900012:
        hilog.error(DOMAIN, 'testTag', 'Push service not activated - Enable push in AGC');
        break;
      case 1000900013:
        hilog.error(DOMAIN, 'testTag', 'Cross-location application not allowed');
        break;
      case 1000900014:
        hilog.error(DOMAIN, 'testTag', 'Device does not support getting token');
        break;
      default:
        hilog.error(DOMAIN, 'testTag', 'Unknown error: %{public}d', err.code);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', 'EntryAbility onDestroy');
  }
}