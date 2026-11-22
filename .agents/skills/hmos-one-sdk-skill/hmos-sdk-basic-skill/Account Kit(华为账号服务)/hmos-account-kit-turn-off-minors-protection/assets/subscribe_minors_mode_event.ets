import { commonEventManager } from '@kit.BasicServicesKit';
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MinorsModeEvent';
const DOMAIN = 0x0000;

class MinorsModeEventManager {
  private subscribedOn: boolean = false;
  private subscribedOff: boolean = false;

  subscribeMinorsModeEvents(callback?: (mode: boolean) => void) {
    try {
      if (!this.subscribedOn) {
        commonEventManager.subscribe('usual.event.MINORSMODE_ON', (data) => {
          hilog.info(DOMAIN, TAG, 'Received MINORSMODE_ON event');
          this.handleMinorsModeOn(data, callback);
        });
        this.subscribedOn = true;
        hilog.info(DOMAIN, TAG, 'Successfully subscribed to MINORSMODE_ON event');
      }

      if (!this.subscribedOff) {
        commonEventManager.subscribe('usual.event.MINORSMODE_OFF', (data) => {
          hilog.info(DOMAIN, TAG, 'Received MINORSMODE_OFF event');
          this.handleMinorsModeOff(data, callback);
        });
        this.subscribedOff = true;
        hilog.info(DOMAIN, TAG, 'Successfully subscribed to MINORSMODE_OFF event');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to subscribe events: ${error.message}`);
    }
  }

  unsubscribeMinorsModeEvents() {
    try {
      if (this.subscribedOn) {
        commonEventManager.unsubscribe('usual.event.MINORSMODE_ON');
        this.subscribedOn = false;
        hilog.info(DOMAIN, TAG, 'Successfully unsubscribed from MINORSMODE_ON event');
      }

      if (this.subscribedOff) {
        commonEventManager.unsubscribe('usual.event.MINORSMODE_OFF');
        this.subscribedOff = false;
        hilog.info(DOMAIN, TAG, 'Successfully unsubscribed from MINORSMODE_OFF event');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to unsubscribe events: ${error.message}`);
    }
  }

  private handleMinorsModeOn(data: any, callback?: (mode: boolean) => void) {
    hilog.info(DOMAIN, TAG, 'Minors mode turned ON');
    
    if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      try {
        if (minorsProtection.supportMinorsMode()) {
          const info = minorsProtection.getMinorsProtectionInfoSync();
          if (info.ageGroup) {
            hilog.info(DOMAIN, TAG, 
              `Age group: [${info.ageGroup.lowerAge}, ${info.ageGroup.upperAge})`);
          }
        }
      } catch (error) {
        hilog.error(DOMAIN, TAG, 
          `Failed to get minors protection info: ${error.message}`);
      }
    }

    if (callback) {
      callback(true);
    }
  }

  private handleMinorsModeOff(data: any, callback?: (mode: boolean) => void) {
    hilog.info(DOMAIN, TAG, 'Minors mode turned OFF');
    
    if (callback) {
      callback(false);
    }
  }

  isSubscribed(): boolean {
    return this.subscribedOn && this.subscribedOff;
  }
}

export { MinorsModeEventManager };

export function createMinorsModeEventManager(): MinorsModeEventManager {
  return new MinorsModeEventManager();
}