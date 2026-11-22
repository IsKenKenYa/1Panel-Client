import { pushService } from '@kit.PushKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export async function deletePushToken(): Promise<void> {
  try {
    await pushService.deleteToken();
    hilog.info(DOMAIN, 'testTag', 'Succeeded in deleting push token');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'testTag', 'Failed to delete push token: %{public}d %{public}s', e.code, e.message);
    handleDeleteTokenError(e);
  }
}

export function deletePushTokenWithCallback(): void {
  try {
    pushService.deleteToken((err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN, 'testTag', 'Failed to delete push token: %{public}d %{public}s', err.code, err.message);
      } else {
        hilog.info(DOMAIN, 'testTag', 'Succeeded in deleting push token');
      }
    });
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, 'testTag', 'Failed to delete push token: %{public}d %{public}s', e.code, e.message);
  }
}

function handleDeleteTokenError(err: BusinessError): void {
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
      hilog.error(DOMAIN, 'testTag', 'APP identity verification failed');
      break;
    case 1000900011:
      hilog.error(DOMAIN, 'testTag', 'Network unavailable');
      break;
    default:
      hilog.error(DOMAIN, 'testTag', 'Unknown error: %{public}d', err.code);
  }
}