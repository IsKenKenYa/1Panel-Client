import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

const TAG = 'MinorsProtectionSubscribe';
const DOMAIN = 0x0000;

let subscriber: commonEventManager.CommonEventSubscriber | null = null;
let cachedMinorsMode: boolean = false;
let cachedAgeGroup: minorsProtection.AgeGroup | null = null;

export class MinorsProtectionSubscribeExample {
  subscribeMinorsModeEvents(): void {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      hilog.info(DOMAIN, TAG, 'Current device does not support minors protection API');
      return;
    }

    try {
      const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
        events: [
          commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON,
          commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF
        ]
      };

      commonEventManager.createSubscriber(subscribeInfo)
        .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
          subscriber = commonEventSubscriber;
          
          commonEventManager.subscribe(subscriber, this.handleCommonEvent.bind(this));
          
          hilog.info(DOMAIN, TAG, 'Successfully subscribed to minors mode events');
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN, TAG, 
            `Failed to create subscriber. Code: ${error.code}, Message: ${error.message}`);
        });
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Failed to subscribe. Code: ${error.code}, Message: ${error.message}`);
    }
  }

  unsubscribeMinorsModeEvents(): void {
    if (!subscriber) {
      hilog.warn(DOMAIN, TAG, 'No subscriber to unsubscribe');
      return;
    }

    try {
      commonEventManager.unsubscribe(subscriber, (error: BusinessError) => {
        if (error) {
          hilog.error(DOMAIN, TAG, 
            `Failed to unsubscribe. Code: ${error.code}, Message: ${error.message}`);
          return;
        }
        hilog.info(DOMAIN, TAG, 'Successfully unsubscribed from minors mode events');
        subscriber = null;
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Failed to unsubscribe. Code: ${error.code}, Message: ${error.message}`);
    }
  }

  private handleCommonEvent(error: BusinessError, data: commonEventManager.CommonEventData): void {
    if (error) {
      hilog.error(DOMAIN, TAG, 
        `Event subscription error. Code: ${error.code}, Message: ${error.message}`);
      return;
    }

    hilog.info(DOMAIN, TAG, `Received event: ${data.event}`);

    if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON) {
      hilog.info(DOMAIN, TAG, 'Minors mode turned ON');
      this.onMinorsModeOn();
    } else if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF) {
      hilog.info(DOMAIN, TAG, 'Minors mode turned OFF');
      this.onMinorsModeOff();
    }
  }

  private onMinorsModeOn(): void {
    cachedMinorsMode = true;
    this.queryAndUpdateAgeGroup();
  }

  private onMinorsModeOff(): void {
    cachedMinorsMode = false;
    cachedAgeGroup = null;
    this.clearAgeRestriction();
  }

  private queryAndUpdateAgeGroup(): void {
    try {
      if (!minorsProtection.supportMinorsMode()) {
        hilog.warn(DOMAIN, TAG, 'Device does not support minors mode');
        return;
      }

      const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo = 
        minorsProtection.getMinorsProtectionInfoSync();

      if (minorsProtectionInfo.ageGroup) {
        cachedAgeGroup = minorsProtectionInfo.ageGroup;
        hilog.info(DOMAIN, TAG, 
          `Updated age group: [${cachedAgeGroup.lowerAge}, ${cachedAgeGroup.upperAge})`);
        this.applyAgeRestriction(cachedAgeGroup.lowerAge, cachedAgeGroup.upperAge);
      } else {
        hilog.warn(DOMAIN, TAG, 'Age group not available, using default');
        this.applyDefaultMinorsRestriction();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Failed to query age group. Code: ${error.code}, Message: ${error.message}`);
      this.applyDefaultMinorsRestriction();
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
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 0-3: baby-safe content only');
        break;
      case 3:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 3-8: preschool-friendly content');
        break;
      case 8:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 8-12: elementary school appropriate');
        break;
      case 12:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 12-16: teen-friendly content');
        break;
      case 16:
        hilog.info(DOMAIN, TAG, 'Applying restrictions for ages 16-18: young adult content');
        break;
      default:
        hilog.warn(DOMAIN, TAG, `Unknown age range: ${lowerAge}-${upperAge}`);
    }
  }

  private applyDefaultMinorsRestriction(): void {
    hilog.info(DOMAIN, TAG, 'Applying default minors restriction (12-16 age group)');
    this.applyAgeRestriction(12, 16);
  }

  private clearAgeRestriction(): void {
    hilog.info(DOMAIN, TAG, 'Clearing age restriction, all content accessible');
  }
}