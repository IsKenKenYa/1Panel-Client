import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;
const TAG = 'AppKilledWatcher';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onCreate');
    
    this.subscribeAppKilledEvent();
  }
  
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onDestroy');
  }
  
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `Failed to load content: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
    });
  }
  
  private subscribeAppKilledEvent(): void {
    hilog.info(DOMAIN, TAG, 'Start to subscribe app killed event');
    
    try {
      const holder = hiAppEvent.addWatcher({
        name: "app_killed_watcher",
        
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_KILLED]
          }
        ],
        
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.info(DOMAIN, TAG, `HiAppEvent onReceive: domain=${domain}`);
          
          if (!appEventGroups || appEventGroups.length === 0) {
            hilog.warn(DOMAIN, TAG, 'appEventGroups is empty');
            return;
          }
          
          for (const eventGroup of appEventGroups) {
            hilog.info(DOMAIN, TAG, `eventName=${eventGroup.name}`);
            
            for (const eventInfo of eventGroup.appEventInfos) {
              this.handleAppKilledEvent(eventInfo);
            }
          }
        }
      });
      
      if (holder === null) {
        hilog.error(DOMAIN, TAG, 'Failed to add watcher: holder is null');
      } else {
        hilog.info(DOMAIN, TAG, 'Successfully added app killed watcher');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to add watcher: ${JSON.stringify(error)}`);
    }
  }
  
  private handleAppKilledEvent(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(DOMAIN, TAG, `eventInfo.domain=${eventInfo.domain}`);
    hilog.info(DOMAIN, TAG, `eventInfo.name=${eventInfo.name}`);
    
    const params = eventInfo.params;
    
    if (!params) {
      hilog.warn(DOMAIN, TAG, 'params is null or undefined');
      return;
    }
    
    const time = params['time'];
    if (time !== undefined) {
      hilog.info(DOMAIN, TAG, `eventInfo.params.time=${time}`);
    }
    
    const foreground = params['foreground'];
    if (foreground !== undefined) {
      hilog.info(DOMAIN, TAG, `eventInfo.params.foreground=${foreground}`);
      
      if (foreground === true) {
        hilog.warn(DOMAIN, TAG, 'App was killed in foreground');
      } else {
        hilog.info(DOMAIN, TAG, 'App was killed in background');
      }
    }
    
    const reason = params['reason'];
    if (reason !== undefined) {
      hilog.info(DOMAIN, TAG, `eventInfo.params.reason=${reason}`);
      
      if (reason === 'RssThresholdKiller') {
        hilog.error(DOMAIN, TAG, 'App killed by memory threshold, check memory usage');
      } else {
        hilog.warn(DOMAIN, TAG, `App killed by: ${reason}`);
      }
    }
    
    const appUniqueId = params['app_running_unique_id'];
    if (appUniqueId !== undefined) {
      hilog.info(DOMAIN, TAG, `eventInfo.params.app_running_unique_id=${appUniqueId}`);
    }
    
    const bundleVersion = params['bundle_version'];
    if (bundleVersion !== undefined) {
      hilog.info(DOMAIN, TAG, `eventInfo.params.bundle_version=${bundleVersion}`);
    }
    
    hilog.info(DOMAIN, TAG, `Complete event data: ${JSON.stringify(eventInfo)}`);
  }
};