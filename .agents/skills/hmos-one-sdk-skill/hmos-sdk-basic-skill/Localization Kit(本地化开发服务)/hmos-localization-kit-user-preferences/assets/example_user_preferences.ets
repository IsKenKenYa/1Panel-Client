import { i18n } from '@kit.LocalizationKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

export class UserPreferencesManager {
  private timeSubscriber: commonEventManager.CommonEventSubscriber | null = null;
  private isSubscribed: boolean = false;

  getUserPreferences(): { usingLocalDigit: boolean; is24HourClock: boolean } {
    try {
      let usingLocalDigit: boolean = i18n.System.getUsingLocalDigit();
      let is24HourClock: boolean = i18n.System.is24HourClock();
      
      console.info(`Local digit: ${usingLocalDigit}, 24Hour: ${is24HourClock}`);
      return { usingLocalDigit, is24HourClock };
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Get user preferences failed, error code: ${err.code}, message: ${err.message}.`);
      
      return { usingLocalDigit: false, is24HourClock: true };
    }
  }

  subscribeTimeFormatChange(callback: (is24Hour: boolean) => void): void {
    if (this.isSubscribed) {
      console.warn('Already subscribed to time format change event.');
      return;
    }

    let timeSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_TIME_CHANGED]
    };

    commonEventManager.createSubscriber(timeSubscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        console.info('CreateSubscriber successfully');
        this.timeSubscriber = commonEventSubscriber;
        
        commonEventManager.subscribe(this.timeSubscriber, (err, data) => {
          if (err) {
            console.error(`Failed to subscribe common event. error code: ${err.code}, message: ${err.message}.`);
            return;
          }
          
          if (data.data != undefined && data.data == '24HourChange') {
            console.info('System time format changed detected.');
            let newIs24HourClock: boolean = i18n.System.is24HourClock();
            console.info(`New 24 hour clock status: ${newIs24HourClock}`);
            callback(newIs24HourClock);
          } else {
            console.info('System time changed detected.');
          }
        });
        
        this.isSubscribed = true;
      })
      .catch((err: BusinessError) => {
        console.error(`CreateSubscriber failed, code is ${err.code}, message is ${err.message}`);
      });
  }

  unsubscribeTimeFormatChange(): void {
    if (!this.isSubscribed || this.timeSubscriber == null) {
      console.warn('Not subscribed or subscriber is null.');
      return;
    }

    commonEventManager.unsubscribe(this.timeSubscriber)
      .then(() => {
        console.info('Unsubscribe successfully');
        this.isSubscribed = false;
        this.timeSubscriber = null;
      })
      .catch((err: BusinessError) => {
        console.error(`Unsubscribe failed, code is ${err.code}, message is ${err.message}`);
      });
  }

  isUsingLocalDigit(): boolean {
    return i18n.System.getUsingLocalDigit();
  }

  is24HourClock(): boolean {
    return i18n.System.is24HourClock();
  }
}

let preferencesManager = new UserPreferencesManager();

preferencesManager.getUserPreferences();

preferencesManager.subscribeTimeFormatChange((is24Hour: boolean) => {
  console.info(`Time format changed to: ${is24Hour ? '24-hour' : '12-hour'} format.`);
});

preferencesManager.unsubscribeTimeFormatChange();