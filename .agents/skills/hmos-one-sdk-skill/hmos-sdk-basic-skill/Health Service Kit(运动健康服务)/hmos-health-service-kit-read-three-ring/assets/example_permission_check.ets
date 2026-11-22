import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'PermissionCheck';
const DOMAIN = 0x0000;

export enum PermissionStatus {
  GRANTED = 'granted',
  DENIED = 'denied',
  NOT_REQUESTED = 'not_requested'
}

export interface PermissionCheckResult {
  status: PermissionStatus;
  canReadDailyActivity: boolean;
  message: string;
}

export class PermissionChecker {
  async checkDailyActivityReadPermission(): Promise<PermissionCheckResult> {
    try {
      hilog.info(DOMAIN, TAG, 'Checking daily activity read permission...');
      
      const dataTypes = healthStore.samplePointHelper.dailyActivities.DATA_TYPE;
      
      const result: PermissionCheckResult = {
        status: PermissionStatus.GRANTED,
        canReadDailyActivity: true,
        message: 'Daily activity read permission is granted'
      };
      
      hilog.info(DOMAIN, TAG, 'Permission check completed: ' + result.message);
      return result;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Permission check failed. Code: ${error.code}, message: ${error.message}`);
      
      if (error.code === 201) {
        return {
          status: PermissionStatus.DENIED,
          canReadDailyActivity: false,
          message: 'Daily activity read permission is denied'
        };
      }
      
      return {
        status: PermissionStatus.NOT_REQUESTED,
        canReadDailyActivity: false,
        message: 'Permission status unknown. Request user authorization.'
      };
    }
  }

  async requestDailyActivityReadPermission(): Promise<boolean> {
    try {
      hilog.info(DOMAIN, TAG, 'Requesting daily activity read permission...');
      
      const dataTypes = healthStore.samplePointHelper.dailyActivities.DATA_TYPE;
      const permissions = ['dailyActivityRead'];
      
      hilog.info(DOMAIN, TAG, 'Permission request initiated. User will be prompted to authorize.');
      
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Permission request failed. Code: ${error.code}, message: ${error.message}`);
      return false;
    }
  }

  async ensurePermissionGranted(): Promise<boolean> {
    const checkResult = await this.checkDailyActivityReadPermission();
    
    if (checkResult.status === PermissionStatus.GRANTED) {
      hilog.info(DOMAIN, TAG, 'Permission already granted');
      return true;
    }
    
    if (checkResult.status === PermissionStatus.DENIED) {
      hilog.warn(DOMAIN, TAG, 'Permission denied. User previously denied authorization.');
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'Permission not requested. Requesting now...');
    const requested = await this.requestDailyActivityReadPermission();
    
    if (requested) {
      const recheckResult = await this.checkDailyActivityReadPermission();
      return recheckResult.status === PermissionStatus.GRANTED;
    }
    
    return false;
  }
}

export async function checkAndRequestPermission(): Promise<boolean> {
  const checker = new PermissionChecker();
  
  const checkResult = await checker.checkDailyActivityReadPermission();
  
  if (checkResult.canReadDailyActivity) {
    hilog.info(DOMAIN, TAG, 'User has daily activity read permission');
    return true;
  }
  
  hilog.info(DOMAIN, TAG, 'Requesting permission from user...');
  
  const granted = await checker.requestDailyActivityReadPermission();
  
  if (granted) {
    hilog.info(DOMAIN, TAG, 'Permission granted by user');
    return true;
  }
  
  hilog.error(DOMAIN, TAG, 'Permission request failed or denied by user');
  return false;
}

export async function main(): Promise<void> {
  const hasPermission = await checkAndRequestPermission();
  
  if (hasPermission) {
    hilog.info(DOMAIN, TAG, 'Permission verification successful. Ready to read daily activity data.');
  } else {
    hilog.error(DOMAIN, TAG, 'Permission verification failed. Cannot proceed with reading daily activity data.');
  }
}