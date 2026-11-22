import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hidebug } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';

export default function testPssLeakPositive() {
  describe('PSS Memory Leak Event Subscription', () => {
    let watcherName = 'testPssWatcher';
    
    beforeAll(() => {
      hidebug.setAppResourceLimit('pss_memory', 1024, false);
    });
    
    afterAll(() => {
      hiAppEvent.removeWatcher({ name: watcherName });
    });
    
    it('should_successfully_subscribe_pss_memory_leak_event', async () => {
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
              if (resourceType === 'pss_memory') {
                eventReceived = true;
              }
            }
          }
        }
      });
      
      expect(holder).not.toBeNull();
      expect(eventReceived).assertTrue();
      expect(resourceType).assertEqual('pss_memory');
    });
    
    it('should_receive_correct_pss_memory_data', async () => {
      let memoryData: Record<string, number> = {};
      
      hiAppEvent.addWatcher({
        name: watcherName + '_memory',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          for (const eventGroup of appEventGroups) {
            for (const eventInfo of eventGroup.appEventInfos) {
              if (eventInfo.params['resource_type'] === 'pss_memory') {
                memoryData = eventInfo.params['memory'];
              }
            }
          }
        }
      });
      
      await sleep(30000);
      
      expect(memoryData).not.toBeNull();
      expect(memoryData['pss']).assertLargerThan(0);
      expect(memoryData['rss']).assertLargerThan(0);
      expect(memoryData['vss']).assertLargerThan(0);
    });
    
    it('should_receive_external_log_paths', async () => {
      let externalLog: Array<string> = [];
      
      hiAppEvent.addWatcher({
        name: watcherName + '_log',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          for (const eventGroup of appEventGroups) {
            for (const eventInfo of eventGroup.appEventInfos) {
              if (eventInfo.params['resource_type'] === 'pss_memory') {
                externalLog = eventInfo.params['external_log'];
              }
            }
          }
        }
      });
      
      await sleep(30000);
      
      expect(externalLog).not.toBeNull();
      expect(externalLog.length).assertLargerThan(0);
      for (const path of externalLog) {
        expect(path).assertContain('/data/storage/el2/log/resourcelimit/');
      }
    });
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}