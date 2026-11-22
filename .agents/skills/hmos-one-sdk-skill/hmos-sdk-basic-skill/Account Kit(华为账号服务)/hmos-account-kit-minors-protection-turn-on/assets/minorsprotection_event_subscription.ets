import { hilog } from '@kit.PerformanceAnalysisKit';
import { commonEventManager } from '@kit.BasicServicesKit';

const TAG = 'MinorsProtectionEventSubscription';
const DOMAIN = 0x0000;

export class MinorsProtectionEventSubscription {
  private minorsModeOnSubscriber: any = null;
  private minorsModeOffSubscriber: any = null;
  
  async subscribeMinorsModeEvents(): void {
    try {
      this.minorsModeOnSubscriber = await commonEventManager.subscribeCommonEvent(
        'usual.event.MINORSMODE_ON',
        (err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, 
              `Failed to subscribe MINORSMODE_ON: ${err.message}`);
            return;
          }
          hilog.info(DOMAIN, TAG, 
            `Received MINORSMODE_ON event, event data: ${JSON.stringify(data)}`);
          this.onMinorsModeTurnedOn();
        }
      );
      
      hilog.info(DOMAIN, TAG, 'Successfully subscribed MINORSMODE_ON event');
      
      this.minorsModeOffSubscriber = await commonEventManager.subscribeCommonEvent(
        'usual.event.MINORSMODE_OFF',
        (err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, 
              `Failed to subscribe MINORSMODE_OFF: ${err.message}`);
            return;
          }
          hilog.info(DOMAIN, TAG, 
            `Received MINORSMODE_OFF event, event data: ${JSON.stringify(data)}`);
          this.onMinorsModeTurnedOff();
        }
      );
      
      hilog.info(DOMAIN, TAG, 'Successfully subscribed MINORSMODE_OFF event');
      hilog.info(DOMAIN, TAG, 'All minors mode events subscribed successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Exception during event subscription: ${error.message}`);
    }
  }
  
  async unsubscribeMinorsModeEvents(): void {
    try {
      if (this.minorsModeOnSubscriber) {
        await commonEventManager.unsubscribeCommonEvent(this.minorsModeOnSubscriber);
        hilog.info(DOMAIN, TAG, 'Successfully unsubscribed MINORSMODE_ON event');
        this.minorsModeOnSubscriber = null;
      }
      
      if (this.minorsModeOffSubscriber) {
        await commonEventManager.unsubscribeCommonEvent(this.minorsModeOffSubscriber);
        hilog.info(DOMAIN, TAG, 'Successfully unsubscribed MINORSMODE_OFF event');
        this.minorsModeOffSubscriber = null;
      }
      
      hilog.info(DOMAIN, TAG, 'All minors mode events unsubscribed successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Exception during event unsubscription: ${error.message}`);
    }
  }
  
  onMinorsModeTurnedOn(): void {
    hilog.info(DOMAIN, TAG, 'Handling minors mode turned on event');
    
    this.updateMinorsModeState(true);
    this.refreshAgeGroupInfo();
    this.updateAppContent();
    this.notifyUser('未成年人模式已开启');
  }
  
  onMinorsModeTurnedOff(): void {
    hilog.info(DOMAIN, TAG, 'Handling minors mode turned off event');
    
    this.updateMinorsModeState(false);
    this.clearAgeGroupInfo();
    this.restoreNormalContent();
    this.notifyUser('未成年人模式已关闭');
  }
  
  updateMinorsModeState(enabled: boolean): void {
    hilog.info(DOMAIN, TAG, `Updating minors mode state to: ${enabled}`);
  }
  
  refreshAgeGroupInfo(): void {
    hilog.info(DOMAIN, TAG, 'Refreshing age group info from system');
  }
  
  clearAgeGroupInfo(): void {
    hilog.info(DOMAIN, TAG, 'Clearing cached age group info');
  }
  
  updateAppContent(): void {
    hilog.info(DOMAIN, TAG, 'Updating app content based on age group');
  }
  
  restoreNormalContent(): void {
    hilog.info(DOMAIN, TAG, 'Restoring normal content display');
  }
  
  notifyUser(message: string): void {
    hilog.info(DOMAIN, TAG, `Notifying user: ${message}`);
  }
}

export async function setupEventSubscription(): Promise<void> {
  const subscription = new MinorsProtectionEventSubscription();
  await subscription.subscribeMinorsModeEvents();
}

export async function cleanupEventSubscription(): Promise<void> {
  const subscription = new MinorsProtectionEventSubscription();
  await subscription.unsubscribeMinorsModeEvents();
}