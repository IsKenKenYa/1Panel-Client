import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MinorsProtectionSync';
const DOMAIN = 0x0000;

let cachedMinorsMode: boolean = false;
let cachedAgeGroup: minorsProtection.AgeGroup | null = null;

export class MinorsProtectionSyncExample {
  checkMinorsModeSync(): void {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      hilog.info(DOMAIN, TAG, 'Current device does not support minors protection API');
      return;
    }

    try {
      if (!minorsProtection.supportMinorsMode()) {
        hilog.info(DOMAIN, TAG, 'Current device environment does not support minors mode');
        return;
      }

      const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo = 
        minorsProtection.getMinorsProtectionInfoSync();

      const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
      cachedMinorsMode = minorsProtectionMode;

      hilog.info(DOMAIN, TAG, `Minors protection mode: ${minorsProtectionMode.valueOf()}`);

      if (minorsProtectionMode) {
        const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
        if (ageGroup) {
          cachedAgeGroup = ageGroup;
          hilog.info(DOMAIN, TAG, `Age range: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
          this.applyAgeRestriction(ageGroup.lowerAge, ageGroup.upperAge);
        } else {
          hilog.warn(DOMAIN, TAG, 'Minors mode is on but age group is not available');
          this.applyDefaultMinorsRestriction();
        }
      } else {
        hilog.info(DOMAIN, TAG, 'Minors mode is off, no content restriction');
        this.clearAgeRestriction();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Failed to query minors mode. Code: ${error.code}, Message: ${error.message}`);
      this.handleMinorsModeError(error.code);
    }
  }

  getCachedMinorsMode(): boolean {
    return cachedMinorsMode;
  }

  getCachedAgeGroup(): minorsProtection.AgeGroup | null {
    return cachedAgeGroup;
  }

  private applyAgeRestriction(lowerAge: number, upperAge: number): void {
    hilog.info(DOMAIN, TAG, `Applying age restriction for [${lowerAge}, ${upperAge})`);
    
    switch (lowerAge) {
      case 0:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 0-3');
        break;
      case 3:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 3-8');
        break;
      case 8:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 8-12');
        break;
      case 12:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 12-16');
        break;
      case 16:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 16-18');
        break;
      default:
        hilog.warn(DOMAIN, TAG, `Unknown age range: ${lowerAge}-${upperAge}`);
    }
  }

  private applyDefaultMinorsRestriction(): void {
    hilog.info(DOMAIN, TAG, 'Applying default minors restriction');
  }

  private clearAgeRestriction(): void {
    hilog.info(DOMAIN, TAG, 'Clearing age restriction, showing all content');
  }

  private handleMinorsModeError(errorCode: number): void {
    switch (errorCode) {
      case 1001502009:
        hilog.error(DOMAIN, TAG, 'Internal error occurred, please try again later');
        break;
      case 1009900002:
        hilog.info(DOMAIN, TAG, 'Minors mode is not enabled');
        this.clearAgeRestriction();
        break;
      case 1009900011:
        hilog.error(DOMAIN, TAG, 'Service not available, please retry later');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error code: ${errorCode}`);
    }
  }
}