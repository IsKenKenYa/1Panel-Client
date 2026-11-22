import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export default class PushMessageAbility extends UIAbility {
  private tokenUpdateCallback: (data: string) => void;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'PushMessageAbility onCreate');
    
    this.registerTokenUpdateListener();
  }

  private registerTokenUpdateListener(): void {
    this.tokenUpdateCallback = (data: string) => {
      try {
        hilog.info(DOMAIN, 'testTag', 'Token updated: %{public}s', data);
        this.reportUpdatedTokenToServer(data);
      } catch (e) {
        const err: BusinessError = e as BusinessError;
        hilog.error(DOMAIN, 'testTag', 'Failed to handle token update: %{public}d %{public}s', err.code, err.message);
      }
    };

    try {
      pushService.on('tokenUpdate', this, this.tokenUpdateCallback);
      hilog.info(DOMAIN, 'testTag', 'Succeeded in registering token update listener');
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Failed to register token update listener: %{public}d %{public}s', err.code, err.message);
      this.handleRegisterError(err);
    }
  }

  private reportUpdatedTokenToServer(token: string): void {
    hilog.info(DOMAIN, 'testTag', 'Report updated token to server: %{public}s', token);
  }

  private handleRegisterError(err: BusinessError): void {
    switch (err.code) {
      case 401:
        hilog.error(DOMAIN, 'testTag', 'Parameter error - Check callback type');
        break;
      case 1000900001:
        hilog.error(DOMAIN, 'testTag', 'System internal error - Check if already registered');
        break;
      default:
        hilog.error(DOMAIN, 'testTag', 'Unknown error: %{public}d', err.code);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', 'PushMessageAbility onDestroy');
    
    this.unregisterTokenUpdateListener();
  }

  private unregisterTokenUpdateListener(): void {
    try {
      pushService.off('tokenUpdate');
      hilog.info(DOMAIN, 'testTag', 'Succeeded in unregistering token update listener');
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      hilog.error(DOMAIN, 'testTag', 'Failed to unregister token update listener: %{public}d %{public}s', err.code, err.message);
    }
  }
}