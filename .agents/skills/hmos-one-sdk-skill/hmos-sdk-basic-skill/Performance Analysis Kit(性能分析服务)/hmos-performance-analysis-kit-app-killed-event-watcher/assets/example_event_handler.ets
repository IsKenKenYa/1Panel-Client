import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;
const TAG = 'AppKilledEventHandler';

export class AppKilledEventHandler {
  private watcherName: string = "app_killed_watcher";
  private isSubscribed: boolean = false;
  
  subscribe(): boolean {
    hilog.info(DOMAIN, TAG, 'Subscribe app killed event');
    
    try {
      const holder = hiAppEvent.addWatcher({
        name: this.watcherName,
        
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_KILLED]
          }
        ],
        
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          this.onEventReceive(domain, appEventGroups);
        }
      });
      
      if (holder === null) {
        hilog.error(DOMAIN, TAG, 'Failed to subscribe: holder is null');
        this.isSubscribed = false;
        return false;
      }
      
      hilog.info(DOMAIN, TAG, 'Successfully subscribed');
      this.isSubscribed = true;
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Subscribe failed: code=${err.code}, message=${err.message}`);
      this.isSubscribed = false;
      return false;
    }
  }
  
  unsubscribe(): boolean {
    hilog.info(DOMAIN, TAG, 'Unsubscribe app killed event');
    
    if (!this.isSubscribed) {
      hilog.warn(DOMAIN, TAG, 'Already unsubscribed');
      return true;
    }
    
    try {
      const watcher: hiAppEvent.Watcher = {
        name: this.watcherName
      };
      
      hiAppEvent.removeWatcher(watcher);
      hilog.info(DOMAIN, TAG, 'Successfully unsubscribed');
      this.isSubscribed = false;
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Unsubscribe failed: code=${err.code}, message=${err.message}`);
      return false;
    }
  }
  
  private onEventReceive(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(DOMAIN, TAG, `Event received: domain=${domain}`);
    
    if (!appEventGroups || appEventGroups.length === 0) {
      hilog.warn(DOMAIN, TAG, 'No event groups received');
      return;
    }
    
    for (const eventGroup of appEventGroups) {
      hilog.info(DOMAIN, TAG, `Event group: name=${eventGroup.name}`);
      
      if (!eventGroup.appEventInfos || eventGroup.appEventInfos.length === 0) {
        hilog.warn(DOMAIN, TAG, 'No event infos in group');
        continue;
      }
      
      for (const eventInfo of eventGroup.appEventInfos) {
        this.processEvent(eventInfo);
      }
    }
  }
  
  private processEvent(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(DOMAIN, TAG, 'Processing app killed event');
    
    const params = eventInfo.params;
    
    if (!params) {
      hilog.error(DOMAIN, TAG, 'Event params is missing');
      return;
    }
    
    const time = this.extractParam(params, 'time');
    const foreground = this.extractParam(params, 'foreground');
    const reason = this.extractParam(params, 'reason');
    const appUniqueId = this.extractParam(params, 'app_running_unique_id');
    const bundleVersion = this.extractParam(params, 'bundle_version');
    
    hilog.info(DOMAIN, TAG, `Event details:`);
    hilog.info(DOMAIN, TAG, `  - Time: ${time}`);
    hilog.info(DOMAIN, TAG, `  - Foreground: ${foreground}`);
    hilog.info(DOMAIN, TAG, `  - Reason: ${reason}`);
    hilog.info(DOMAIN, TAG, `  - App Unique ID: ${appUniqueId}`);
    hilog.info(DOMAIN, TAG, `  - Bundle Version: ${bundleVersion}`);
    
    this.analyzeEvent(foreground, reason);
  }
  
  private extractParam(params: object, key: string): string | number | boolean | undefined {
    try {
      const value = params[key];
      if (value !== undefined && value !== null) {
        return value;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to extract param '${key}': ${error}`);
    }
    return undefined;
  }
  
  private analyzeEvent(foreground: string | number | boolean | undefined, 
                       reason: string | number | boolean | undefined): void {
    hilog.info(DOMAIN, TAG, 'Analyzing termination reason');
    
    if (foreground === true) {
      hilog.warn(DOMAIN, TAG, 'App terminated while in foreground');
    } else if (foreground === false) {
      hilog.info(DOMAIN, TAG, 'App terminated while in background');
    }
    
    if (typeof reason === 'string') {
      if (reason === 'RssThresholdKiller') {
        hilog.error(DOMAIN, TAG, 'MEMORY ISSUE: App killed due to memory threshold');
        hilog.error(DOMAIN, TAG, 'Recommendation: Check memory leaks, optimize memory usage');
      } else {
        hilog.warn(DOMAIN, TAG, `App killed by system policy: ${reason}`);
      }
    }
  }
  
  isCurrentlySubscribed(): boolean {
    return this.isSubscribed;
  }
};

export function createAppKilledEventHandler(): AppKilledEventHandler {
  return new AppKilledEventHandler();
}