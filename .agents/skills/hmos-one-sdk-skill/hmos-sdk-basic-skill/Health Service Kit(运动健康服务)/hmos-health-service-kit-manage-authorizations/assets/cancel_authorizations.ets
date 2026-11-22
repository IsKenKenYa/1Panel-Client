import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CancelAuthorization';
const DOMAIN = 0x0000;

export async function cancelHealthAuthorizations(): Promise<boolean> {
  try {
    await healthStore.cancelAuthorizations();
    hilog.info(DOMAIN, TAG, 'All authorizations canceled successfully');
    return true;
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Failed to cancel authorization. Code: ${error.code}, Message: ${error.message}`);
    
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission verification failed.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
    }
    
    return false;
  }
}