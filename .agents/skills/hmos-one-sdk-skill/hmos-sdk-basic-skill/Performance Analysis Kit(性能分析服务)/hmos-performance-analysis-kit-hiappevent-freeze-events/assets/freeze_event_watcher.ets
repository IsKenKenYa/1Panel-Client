import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

export class FreezeEventWatcher {
  private watcherName: string = "freeze_watcher";
  
  constructor(watcherName?: string) {
    if (watcherName) {
      this.watcherName = watcherName;
    }
  }
  
  async init(): Promise<void> {
    await this.setCustomParams();
    
    if (deviceInfo.sdkApiVersion >= 24) {
      await this.configPageSwitchLog();
    }
    
    this.subscribeFreezeEvent();
  }
  
  private async setCustomParams(): Promise<void> {
    const params: Record<string, hiAppEvent.ParamType> = {
      "app_version": "1.0.0",
      "user_id": "test_user_123",
      "session_id": Date.now().toString(),
    };
    
    try {
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.APP_FREEZE);
      hilog.info(0x0000, 'FreezeWatcher', `Success to set custom params for freeze event`);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'FreezeWatcher', `Failed to set params: code=${error.code}, msg=${error.message}`);
    }
  }
  
  private async configPageSwitchLog(): Promise<void> {
    const switchLogPolicy: hiAppEvent.EventPolicy = {
      "appFreezePolicy": {
        "pageSwitchLogEnable": true
      }
    };
    
    try {
      await hiAppEvent.configEventPolicy(switchLogPolicy);
      hilog.info(0x0000, 'FreezeWatcher', `Success to config page switch log`);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'FreezeWatcher', `Failed to config policy: code=${error.code}, msg=${error.message}`);
    }
  }
  
  private subscribeFreezeEvent(): void {
    try {
      const holder = hiAppEvent.addWatcher({
        name: this.watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_FREEZE]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          this.handleFreezeEvent(domain, appEventGroups);
        }
      });
      
      if (holder == null) {
        hilog.error(0x0000, 'FreezeWatcher', 'Failed to add watcher, holder is null');
        return;
      }
      
      hilog.info(0x0000, 'FreezeWatcher', `Success to subscribe freeze event, watcher=${this.watcherName}`);
      
    } catch (err) {
      const error = err as BusinessError;
      this.handleSubscriptionError(error);
    }
  }
  
  private handleFreezeEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(0x0000, 'FreezeWatcher', `Received freeze event, domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'FreezeWatcher', `Event name: ${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        this.logEventInfo(eventInfo);
        this.processFreezeEvent(eventInfo);
      }
    }
  }
  
  private logEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(0x0000, 'FreezeWatcher', `--- Freeze Event Info ---`);
    hilog.info(0x0000, 'FreezeWatcher', `Domain: ${eventInfo.domain}`);
    hilog.info(0x0000, 'FreezeWatcher', `Name: ${eventInfo.name}`);
    hilog.info(0x0000, 'FreezeWatcher', `Type: ${eventInfo.eventType}`);
    
    const params = eventInfo.params;
    
    hilog.info(0x0000, 'FreezeWatcher', `Time: ${params['time']}`);
    hilog.info(0x0000, 'FreezeWatcher', `Foreground: ${params['foreground']}`);
    hilog.info(0x0000, 'FreezeWatcher', `Bundle Name: ${params['bundle_name']}`);
    hilog.info(0x0000, 'FreezeWatcher', `Process Name: ${params['process_name']}`);
    hilog.info(0x0000, 'FreezeWatcher', `PID: ${params['pid']}`);
    hilog.info(0x0000, 'FreezeWatcher', `UID: ${params['uid']}`);
    hilog.info(0x0000, 'FreezeWatcher', `Process Life Time: ${params['process_life_time']}`);
    
    const exception = params['exception'];
    hilog.info(0x0000, 'FreezeWatcher', `Exception: ${JSON.stringify(exception)}`);
    
    if (params['hilog']) {
      hilog.info(0x0000, 'FreezeWatcher', `Hilog count: ${params['hilog'].length}`);
    }
    
    if (params['threads']) {
      hilog.info(0x0000, 'FreezeWatcher', `Thread count: ${params['threads'].length}`);
    }
    
    if (params['memory']) {
      hilog.info(0x0000, 'FreezeWatcher', `Memory: ${JSON.stringify(params['memory'])}`);
    }
    
    if (params['external_log']) {
      hilog.info(0x0000, 'FreezeWatcher', `External Log: ${JSON.stringify(params['external_log'])}`);
      hilog.info(0x0000, 'FreezeWatcher', `Log Over Limit: ${params['log_over_limit']}`);
    }
    
    if (params['page_switch_log']) {
      hilog.info(0x0000, 'FreezeWatcher', `Page Switch Log: ${JSON.stringify(params['page_switch_log'])}`);
    }
    
    if (params['app_version']) {
      hilog.info(0x0000, 'FreezeWatcher', `Custom App Version: ${params['app_version']}`);
    }
    if (params['user_id']) {
      hilog.info(0x0000, 'FreezeWatcher', `Custom User ID: ${params['user_id']}`);
    }
    if (params['session_id']) {
      hilog.info(0x0000, 'FreezeWatcher', `Custom Session ID: ${params['session_id']}`);
    }
  }
  
  private processFreezeEvent(eventInfo: hiAppEvent.AppEventInfo): void {
    const params = eventInfo.params;
    const exception = params['exception'];
    
    if (exception && exception['name']) {
      const freezeType = exception['name'];
      hilog.warn(0x0000, 'FreezeWatcher', `Detected freeze type: ${freezeType}`);
      
      if (freezeType === 'THREAD_BLOCK_6S') {
        hilog.warn(0x0000, 'FreezeWatcher', 'App main thread blocked for 6 seconds');
      } else if (freezeType === 'THREAD_BLOCK_3S') {
        hilog.warn(0x0000, 'FreezeWatcher', 'App main thread blocked for 3 seconds');
      }
      
      if (exception['message']) {
        hilog.warn(0x0000, 'FreezeWatcher', `Exception message: ${exception['message']}`);
      }
    }
    
    const externalLog = params['external_log'];
    if (externalLog && Array.isArray(externalLog) && externalLog.length > 0) {
      hilog.info(0x0000, 'FreezeWatcher', `Fault log files: ${externalLog.join(', ')}`);
    }
  }
  
  private handleSubscriptionError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(0x0000, 'FreezeWatcher', `Parameter error: ${error.message}`);
        break;
      case 11102001:
        hilog.error(0x0000, 'FreezeWatcher', `Invalid watcher name: ${error.message}`);
        break;
      case 11102002:
        hilog.error(0x0000, 'FreezeWatcher', `Invalid filtering event domain: ${error.message}`);
        break;
      default:
        hilog.error(0x0000, 'FreezeWatcher', `Unknown error: code=${error.code}, message=${error.message}`);
    }
  }
  
  removeWatcher(): void {
    try {
      hiAppEvent.removeWatcher({
        name: this.watcherName
      });
      hilog.info(0x0000, 'FreezeWatcher', `Success to remove watcher: ${this.watcherName}`);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'FreezeWatcher', `Failed to remove watcher: ${error.message}`);
    }
  }
}

export function createFreezeWatcher(watcherName?: string): FreezeEventWatcher {
  const watcher = new FreezeEventWatcher(watcherName);
  return watcher;
}