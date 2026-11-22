import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';

export class ResourceLeakSubscriptionExample {
  private watcherName: string = "resourceLeakWatcher";
  
  async setupResourceLeakSubscription(): Promise<void> {
    try {
      await this.setEventCustomParams();
      await this.setEventConfig();
      await this.configEventPolicy();
      this.addWatcher();
      hilog.info(0x0000, 'ResourceLeakTag', 'Successfully setup resource leak subscription');
    } catch (error) {
      hilog.error(0x0000, 'ResourceLeakTag', 'Failed to setup resource leak subscription');
    }
  }
  
  private async setEventCustomParams(): Promise<void> {
    let params: Record<string, hiAppEvent.ParamType> = {
      "test_data": 100,
      "app_version": "1.0.0",
      "user_id": "test_user_001"
    };
    
    try {
      await hiAppEvent.setEventParam(
        params,
        hiAppEvent.domain.OS,
        hiAppEvent.event.RESOURCE_OVERLIMIT
      );
      hilog.info(0x0000, 'ResourceLeakTag', 'Success to set event custom params');
    } catch (err) {
      let error = err as BusinessError;
      this.handleSetEventParamError(error);
    }
  }
  
  private async setEventConfig(): Promise<void> {
    let configParams: Record<string, hiAppEvent.ParamType> = {
      "js_heap_logtype": "event"
    };
    
    try {
      await hiAppEvent.setEventConfig(
        hiAppEvent.event.RESOURCE_OVERLIMIT,
        configParams
      );
      hilog.info(0x0000, 'ResourceLeakTag', 'Success to set event config');
    } catch (err) {
      let error = err as BusinessError;
      hilog.error(0x0000, 'ResourceLeakTag', `Failed to set event config: code ${error.code}, message ${error.message}`);
    }
  }
  
  private async configEventPolicy(): Promise<void> {
    if (deviceInfo.sdkApiVersion < 24) {
      hilog.warn(0x0000, 'ResourceLeakTag', 'API version < 24, page switch log not supported');
      return;
    }
    
    let switchLogPolicy: hiAppEvent.EventPolicy = {
      "resourceOverlimitPolicy": {
        "pageSwitchLogEnable": true
      }
    };
    
    try {
      await hiAppEvent.configEventPolicy(switchLogPolicy);
      hilog.info(0x0000, 'ResourceLeakTag', 'Success to config event policy with page switch log enabled');
    } catch (err) {
      let error = err as BusinessError;
      hilog.error(0x0000, 'ResourceLeakTag', `Failed to config event policy: code ${error.code}, message ${error.message}`);
    }
  }
  
  private addWatcher(): void {
    let holder = hiAppEvent.addWatcher({
      name: this.watcherName,
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        this.handleResourceLeakEvent(domain, appEventGroups);
      }
    });
    
    if (holder === null) {
      hilog.error(0x0000, 'ResourceLeakTag', 'Failed to add watcher, subscription not active');
    } else {
      hilog.info(0x0000, 'ResourceLeakTag', 'Watcher added successfully');
    }
  }
  
  private handleResourceLeakEvent(
    domain: string,
    appEventGroups: Array<hiAppEvent.AppEventGroup>
  ): void {
    hilog.info(0x0000, 'ResourceLeakTag', `onReceive triggered: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'ResourceLeakTag', `Event name: ${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        let resourceType = eventInfo.params['resource_type'];
        hilog.info(0x0000, 'ResourceLeakTag', `Resource type: ${resourceType}`);
        
        if (resourceType === 'pss_memory') {
          this.handlePssMemoryLeak(eventInfo);
        } else if (resourceType === 'js_heap') {
          this.handleJsHeapLeak(eventInfo);
        }
      }
    }
  }
  
  private handlePssMemoryLeak(eventInfo: hiAppEvent.AppEventInfo): void {
    let memory = eventInfo.params['memory'] as Record<string, number>;
    hilog.info(0x0000, 'ResourceLeakTag', `PSS Memory Leak detected:`);
    hilog.info(0x0000, 'ResourceLeakTag', `  PSS: ${memory['pss']} KB`);
    hilog.info(0x0000, 'ResourceLeakTag', `  RSS: ${memory['rss']} KB`);
    hilog.info(0x0000, 'ResourceLeakTag', `  VSS: ${memory['vss']} KB`);
    
    let externalLog = eventInfo.params['external_log'] as Array<string>;
    if (externalLog && externalLog.length > 0) {
      hilog.info(0x0000, 'ResourceLeakTag', `External log files: ${JSON.stringify(externalLog)}`);
    }
    
    let pageSwitchLog = eventInfo.params['page_switch_log'];
    if (pageSwitchLog) {
      hilog.info(0x0000, 'ResourceLeakTag', `Page switch log: ${pageSwitchLog}`);
    }
  }
  
  private handleJsHeapLeak(eventInfo: hiAppEvent.AppEventInfo): void {
    let memory = eventInfo.params['memory'] as Record<string, number>;
    hilog.info(0x0000, 'ResourceLeakTag', `JS Heap Memory Leak detected:`);
    hilog.info(0x0000, 'ResourceLeakTag', `  Live object size: ${memory['live_object_size']} KB`);
    hilog.info(0x0000, 'ResourceLeakTag', `  Limit size: ${memory['limit_size']} KB`);
    
    let customData = eventInfo.params['test_data'];
    if (customData) {
      hilog.info(0x0000, 'ResourceLeakTag', `Custom data: ${customData}`);
    }
    
    let externalLog = eventInfo.params['external_log'] as Array<string>;
    if (externalLog && externalLog.length > 0) {
      hilog.info(0x0000, 'ResourceLeakTag', `JS heap snapshot files: ${JSON.stringify(externalLog)}`);
    }
  }
  
  private handleSetEventParamError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(0x0000, 'ResourceLeakTag', 'Parameter error. Check parameter types and values');
        break;
      case 11100001:
        hilog.error(0x0000, 'ResourceLeakTag', 'Function disabled. Enable with hiAppEvent.configure({disable: false})');
        break;
      case 11101001:
        hilog.error(0x0000, 'ResourceLeakTag', 'Invalid event domain. Use hiAppEvent.domain.OS');
        break;
      case 11101002:
        hilog.error(0x0000, 'ResourceLeakTag', 'Invalid event name. Use hiAppEvent.event.RESOURCE_OVERLIMIT');
        break;
      case 11101004:
        hilog.error(0x0000, 'ResourceLeakTag', 'Invalid string length. Reduce to 1024 chars or less');
        break;
      case 11101005:
        hilog.error(0x0000, 'ResourceLeakTag', 'Invalid param name. Must start with letter or $, max 32 chars');
        break;
      case 11101007:
        hilog.error(0x0000, 'ResourceLeakTag', 'Too many params. Reduce to 64 or fewer');
        break;
      default:
        hilog.error(0x0000, 'ResourceLeakTag', `Unknown error: ${error.code}, ${error.message}`);
    }
  }
  
  removeWatcher(): void {
    hiAppEvent.removeWatcher({
      name: this.watcherName
    });
    hilog.info(0x0000, 'ResourceLeakTag', 'Watcher removed');
  }
}

export async function setupNologHeapSnapshot(): Promise<void> {
  let configParams: Record<string, hiAppEvent.ParamType> = {
    "js_heap_logtype": "event_rawheap"
  };
  
  try {
    await hiAppEvent.setEventConfig(
      hiAppEvent.event.RESOURCE_OVERLIMIT,
      configParams
    );
    hilog.info(0x0000, 'NologTag', 'Successfully configured for nolog heap snapshot generation');
    hilog.warn(0x0000, 'NologTag', 'Note: Heap snapshot size ~0.4-1.2GB, limited to 1 per app per week');
  } catch (err) {
    let error = err as BusinessError;
    hilog.error(0x0000, 'NologTag', `Failed to configure nolog heap snapshot: ${error.code}, ${error.message}`);
  }
}