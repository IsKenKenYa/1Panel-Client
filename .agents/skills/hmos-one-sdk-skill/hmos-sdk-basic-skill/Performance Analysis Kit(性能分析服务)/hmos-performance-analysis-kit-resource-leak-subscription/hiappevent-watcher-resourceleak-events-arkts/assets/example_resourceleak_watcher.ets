import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';

export class ResourceLeakWatcher {
  private watcherName: string = 'resourceLeakWatcher';
  
  initWatcher(): void {
    this.setEventParams();
    this.setEventConfig();
    this.configEventPolicy();
    this.addWatcher();
  }
  
  private setEventParams(): void {
    let params: Record<string, hiAppEvent.ParamType> = {
      'test_data': 100,
      'app_version': '1.0.0',
    };
    
    hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
      .then(() => {
        hilog.info(0x0000, 'ResourceLeakWatcher', 'Success to set event param');
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, 'ResourceLeakWatcher', 
          `Failed to set event param. Code: ${err.code}, message: ${err.message}`);
      });
  }
  
  private setEventConfig(): void {
    let configParams: Record<string, hiAppEvent.ParamType> = {
      'js_heap_logtype': 'event',
    };
    
    hiAppEvent.setEventConfig(hiAppEvent.event.RESOURCE_OVERLIMIT, configParams)
      .then(() => {
        hilog.info(0x0000, 'ResourceLeakWatcher', 'Success to set event config');
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, 'ResourceLeakWatcher',
          `Failed to set event config. Code: ${err.code}, message: ${err.message}`);
      });
  }
  
  private configEventPolicy(): void {
    if (deviceInfo.sdkApiVersion >= 24) {
      let switchLogPolicy: hiAppEvent.EventPolicy = {
        'resourceOverlimitPolicy': {
          'pageSwitchLogEnable': true
        }
      };
      
      hiAppEvent.configEventPolicy(switchLogPolicy)
        .then(() => {
          hilog.info(0x0000, 'ResourceLeakWatcher', 'Success to config event policy');
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0000, 'ResourceLeakWatcher',
            `Failed to config event policy. Code: ${err.code}, message: ${err.message}`);
        });
    } else {
      hilog.warn(0x0000, 'ResourceLeakWatcher', 
        'API version < 24, page switch log config not supported');
    }
  }
  
  private addWatcher(): void {
    try {
      let holder = hiAppEvent.addWatcher({
        name: this.watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          this.handleEvent(domain, appEventGroups);
        }
      });
      
      if (holder == null) {
        hilog.error(0x0000, 'ResourceLeakWatcher', 'Failed to add watcher');
      } else {
        hilog.info(0x0000, 'ResourceLeakWatcher', 'Watcher added successfully');
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'ResourceLeakWatcher',
        `Exception adding watcher. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  private handleEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(0x0000, 'ResourceLeakWatcher', `onReceive: domain=${domain}`);
    
    try {
      for (const eventGroup of appEventGroups) {
        hilog.info(0x0000, 'ResourceLeakWatcher', `eventName=${eventGroup.name}`);
        
        for (const eventInfo of eventGroup.appEventInfos) {
          let resourceType = eventInfo.params['resource_type'];
          
          if (resourceType === 'pss_memory') {
            this.handlePssMemoryLeak(eventInfo);
          } else if (resourceType === 'js_heap') {
            this.handleJsHeapLeak(eventInfo);
          }
          
          let externalLog = eventInfo.params['external_log'];
          if (externalLog && Array.isArray(externalLog) && externalLog.length > 0) {
            hilog.info(0x0000, 'ResourceLeakWatcher', 
              `External log files: ${JSON.stringify(externalLog)}`);
          }
          
          let pageSwitchLog = eventInfo.params['page_switch_log'];
          if (pageSwitchLog) {
            hilog.info(0x0000, 'ResourceLeakWatcher',
              `Page switch log: ${JSON.stringify(pageSwitchLog)}`);
          }
        }
      }
    } catch (error) {
      hilog.error(0x0000, 'ResourceLeakWatcher', `Error handling event: ${error}`);
    }
  }
  
  private handlePssMemoryLeak(eventInfo: hiAppEvent.AppEventInfo): void {
    let memory = eventInfo.params['memory'];
    if (memory) {
      hilog.info(0x0000, 'ResourceLeakWatcher',
        `PSS memory leak detected: pss=${memory.pss} KB, rss=${memory.rss} KB`);
      hilog.info(0x0000, 'ResourceLeakWatcher',
        `Memory details: vss=${memory.vss}, sys_avail_mem=${memory.sys_avail_mem}`);
    }
  }
  
  private handleJsHeapLeak(eventInfo: hiAppEvent.AppEventInfo): void {
    let memory = eventInfo.params['memory'];
    if (memory) {
      hilog.info(0x0000, 'ResourceLeakWatcher',
        `JS heap leak detected: limit_size=${memory.limit_size}, live_object_size=${memory.live_object_size}`);
    }
    
    let testData = eventInfo.params['test_data'];
    if (testData) {
      hilog.info(0x0000, 'ResourceLeakWatcher', `Custom test_data: ${testData}`);
    }
  }
  
  removeWatcher(): void {
    hiAppEvent.removeWatcher({
      name: this.watcherName
    });
    hilog.info(0x0000, 'ResourceLeakWatcher', 'Watcher removed');
  }
}

let watcher = new ResourceLeakWatcher();
watcher.initWatcher();