import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hidebug } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';

export default function testJsHeapLeakPositive() {
  describe('JS Heap Memory Leak Event Subscription', () => {
    let watcherName = 'testJsHeapWatcher';
    let leakedArray: Array<Array<number>> = [];
    
    beforeAll(() => {
      hidebug.setAppResourceLimit('js_heap', 85, false);
    });
    
    afterAll(() => {
      hiAppEvent.removeWatcher({ name: watcherName });
      leakedArray = [];
    });
    
    it('should_successfully_subscribe_js_heap_leak_event', async () => {
      let eventReceived = false;
      let resourceType = '';
      
      let holder = hiAppEvent.addWatcher({
        name: watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          for (const eventGroup of appEventGroups) {
            for (const eventInfo of eventGroup.appEventInfos) {
              resourceType = eventInfo.params['resource_type'];
              if (resourceType === 'js_heap') {
                eventReceived = true;
              }
            }
          }
        }
      });
      
      expect(holder).not.toBeNull();
      
      for (let i = 0; i < 10000; i++) {
        leakedArray.push(new Array(500000).fill(1));
      }
      
      await sleep(5000);
      
      expect(eventReceived).assertTrue();
      expect(resourceType).assertEqual('js_heap');
    });
    
    it('should_receive_custom_parameters', async () => {
      let testDataValue = 0;
      
      let params: Record<string, hiAppEvent.ParamType> = {
        'custom_test_data': 200,
      };
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT);
      
      hiAppEvent.addWatcher({
        name: watcherName + '_params',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          for (const eventGroup of appEventGroups) {
            for (const eventInfo of eventGroup.appEventInfos) {
              if (eventInfo.params['resource_type'] === 'js_heap') {
                testDataValue = eventInfo.params['custom_test_data'];
              }
            }
          }
        }
      });
      
      for (let i = 0; i < 10000; i++) {
        leakedArray.push(new Array(500000).fill(1));
      }
      
      await sleep(5000);
      
      expect(testDataValue).assertEqual(200);
    });
    
    it('should_receive_js_heap_logtype_config', async () => {
      let logType = '';
      
      let configParams: Record<string, hiAppEvent.ParamType> = {
        'js_heap_logtype': 'event_rawheap',
      };
      
      await hiAppEvent.setEventConfig(hiAppEvent.event.RESOURCE_OVERLIMIT, configParams);
      
      hiAppEvent.addWatcher({
        name: watcherName + '_config',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          for (const eventGroup of appEventGroups) {
            for (const eventInfo of eventGroup.appEventInfos) {
              if (eventInfo.params['resource_type'] === 'js_heap') {
                logType = eventInfo.params['js_heap_logtype'];
              }
            }
          }
        }
      });
      
      expect(logType).assertEqual('event_rawheap');
    });
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}