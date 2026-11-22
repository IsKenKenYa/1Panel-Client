import { commonEventManager } from '@kit.BasicServicesKit';
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MinorsModeEvents';
const DOMAIN = 0x0000;

export class MinorsModeEventSubscriber {
  private subscribers: commonEventManager.CommonEventSubscriber[] = [];
  private minorsModeEnabled: boolean = false;
  private ageGroup: minorsProtection.AgeGroup | undefined = undefined;

  constructor() {
    this.initialize();
  }

  private initialize() {
    this.refreshMinorsModeStatus();
    this.subscribeEvents();
  }

  private refreshMinorsModeStatus() {
    try {
      if (!minorsProtection.supportMinorsMode()) {
        hilog.info(DOMAIN, TAG, 'Device environment does not support minors mode.');
        this.minorsModeEnabled = false;
        this.ageGroup = undefined;
        return;
      }

      const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
      this.minorsModeEnabled = minorsProtectionInfo.minorsProtectionMode;
      this.ageGroup = minorsProtectionInfo.ageGroup;

      hilog.info(DOMAIN, TAG, 
        `Refreshed minors mode status: ${this.minorsModeEnabled}`);
      
      if (this.ageGroup) {
        hilog.info(DOMAIN, TAG, 
          `Age group: [${this.ageGroup.lowerAge}, ${this.ageGroup.upperAge})`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to refresh minors mode status.');
    }
  }

  private subscribeEvents() {
    this.subscribeMinorsModeOnEvent();
    this.subscribeMinorsModeOffEvent();
  }

  private subscribeMinorsModeOnEvent() {
    const onSubscriber = commonEventManager.createCommonEventSubscriber(
      { event: 'usual.event.MINORSMODE_ON' }
    );

    commonEventManager.subscribeCommonEvent(onSubscriber, (err, data) => {
      if (!err) {
        hilog.info(DOMAIN, TAG, 'Minors mode turned ON event received.');
        this.onMinorsModeEnabled();
      } else {
        hilog.error(DOMAIN, TAG, 'Failed to receive MINORSMODE_ON event.');
      }
    });

    this.subscribers.push(onSubscriber);
  }

  private subscribeMinorsModeOffEvent() {
    const offSubscriber = commonEventManager.createCommonEventSubscriber(
      { event: 'usual.event.MINORSMODE_OFF' }
    );

    commonEventManager.subscribeCommonEvent(offSubscriber, (err, data) => {
      if (!err) {
        hilog.info(DOMAIN, TAG, 'Minors mode turned OFF event received.');
        this.onMinorsModeDisabled();
      } else {
        hilog.error(DOMAIN, TAG, 'Failed to receive MINORSMODE_OFF event.');
      }
    });

    this.subscribers.push(offSubscriber);
  }

  private onMinorsModeEnabled() {
    this.minorsModeEnabled = true;
    this.refreshMinorsModeStatus();
    hilog.info(DOMAIN, TAG, 'Minors mode is now enabled. App should switch to minors mode.');
  }

  private onMinorsModeDisabled() {
    this.minorsModeEnabled = false;
    this.ageGroup = undefined;
    hilog.info(DOMAIN, TAG, 'Minors mode is now disabled. App should switch to normal mode.');
  }

  public getMinorsModeEnabled(): boolean {
    return this.minorsModeEnabled;
  }

  public getAgeGroup(): minorsProtection.AgeGroup | undefined {
    return this.ageGroup;
  }

  public unsubscribeAllEvents() {
    for (const subscriber of this.subscribers) {
      commonEventManager.unsubscribeCommonEvent(subscriber, (err) => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'Failed to unsubscribe event.');
        } else {
          hilog.info(DOMAIN, TAG, 'Successfully unsubscribed event.');
        }
      });
    }
    this.subscribers = [];
  }
}

export function createMinorsModeEventSubscriber(): MinorsModeEventSubscriber {
  return new MinorsModeEventSubscriber();
}