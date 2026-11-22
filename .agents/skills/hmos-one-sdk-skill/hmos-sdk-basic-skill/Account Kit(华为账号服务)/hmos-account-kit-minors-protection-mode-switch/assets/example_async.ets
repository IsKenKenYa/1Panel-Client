import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'MinorsProtectionAsync';
const DOMAIN = 0x0000;

let cachedMinorsMode: boolean = false;
let cachedAgeGroup: minorsProtection.AgeGroup | null = null;

export class MinorsProtectionAsyncExample {
  async checkMinorsModeAsync(): Promise<void> {
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
        await minorsProtection.getMinorsProtectionInfo();

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
      const businessError = error as BusinessError<Object>;
      hilog.error(DOMAIN, TAG, 
        `Failed to query minors mode. Code: ${businessError.code}, Message: ${businessError.message}`);
      this.handleMinorsModeError(businessError.code);
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
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 0-3: baby content only');
        break;
      case 3:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 3-8: preschool content');
        break;
      case 8:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 8-12: elementary school content');
        break;
      case 12:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 12-16: middle school content');
        break;
      case 16:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 16-18: high school content');
        break;
      default:
        hilog.warn(DOMAIN, TAG, `Unknown age range: ${lowerAge}-${upperAge}`);
    }
  }

  private applyDefaultMinorsRestriction(): void {
    hilog.info(DOMAIN, TAG, 'Applying default minors restriction (12-16)');
    this.applyAgeRestriction(12, 16);
  }

  private clearAgeRestriction(): void {
    hilog.info(DOMAIN, TAG, 'Clearing age restriction, showing all content');
    cachedAgeGroup = null;
  }

  private handleMinorsModeError(errorCode: number): void {
    switch (errorCode) {
      case 1001502009:
        hilog.error(DOMAIN, TAG, 'Internal error occurred, using cached data if available');
        if (cachedMinorsMode && cachedAgeGroup) {
          this.applyAgeRestriction(cachedAgeGroup.lowerAge, cachedAgeGroup.upperAge);
        } else {
          this.clearAgeRestriction();
        }
        break;
      case 1009900002:
        hilog.info(DOMAIN, TAG, 'Minors mode is not enabled');
        this.clearAgeRestriction();
        break;
      case 1009900011:
        hilog.error(DOMAIN, TAG, 'Service not available, using cached data');
        if (cachedMinorsMode && cachedAgeGroup) {
          this.applyAgeRestriction(cachedAgeGroup.lowerAge, cachedAgeGroup.upperAge);
        } else {
          this.clearAgeRestriction();
        }
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error code: ${errorCode}, clearing restrictions`);
        this.clearAgeRestriction();
    }
  }
}