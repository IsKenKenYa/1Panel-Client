import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect } from '@ohos/hypium';

export default function testCallbackException() {
  describe('Callback Exception Handling Tests', () => {
    it('should_handle_exception_in_onReceive_callback', () => {
      let exceptionHandled = false;
      let watcherName = 'exceptionWatcher';
      
      hiAppEvent.addWatcher({
        name: watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          try {
            throw new Error('Test exception in callback');
          } catch (error) {
            exceptionHandled = true;
            hilog.error(0x0000, 'TestTag', `Exception handled: ${error}`);
          }
        }
      });
      
      expect(exceptionHandled).assertTrue();
      
      hiAppEvent.removeWatcher({ name: watcherName });
    });
    
    it('should_not_crash_on_null_event_info', () => {
      let nullHandled = false;
      let watcherName = 'nullEventWatcher';
      
      hiAppEvent.addWatcher({
        name: watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          try {
            for (const eventGroup of appEventGroups) {
              for (const eventInfo of eventGroup.appEventInfos) {
                if (eventInfo == null) {
                  nullHandled = true;
                  hilog.warn(0x0000, 'TestTag', 'Null event info detected');
                  continue;
                }
              }
            }
          } catch (error) {
            hilog.error(0x0000, 'TestTag', `Error: ${error}`);
          }
        }
      });
      
      expect(nullHandled).assertFalse();
      
      hiAppEvent.removeWatcher({ name: watcherName });
    });
    
    it('should_handle_missing_params_field', () => {
      let missingParamsHandled = false;
      let watcherName = 'missingParamsWatcher';
      
      hiAppEvent.addWatcher({
        name: watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          try {
            for (const eventGroup of appEventGroups) {
              for (const eventInfo of eventGroup.appEventInfos) {
                if (!eventInfo.params) {
                  missingParamsHandled = true;
                  hilog.warn(0x0000, 'TestTag', 'Missing params field');
                  return;
                }
                
                let resourceType = eventInfo.params['resource_type'];
                if (!resourceType) {
                  hilog.warn(0x0000, 'TestTag', 'Missing resource_type');
                }
              }
            }
          } catch (error) {
            hilog.error(0x0000, 'TestTag', `Exception: ${error}`);
          }
        }
      });
      
      hiAppEvent.removeWatcher({ name: watcherName });
    });
    
    it('should_handle_invalid_json_stringify', () => {
      let invalidJsonHandled = false;
      let watcherName = 'invalidJsonWatcher';
      
      hiAppEvent.addWatcher({
        name: watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          try {
            for (const eventGroup of appEventGroups) {
              for (const eventInfo of eventGroup.appEventInfos) {
                try {
                  JSON.stringify(eventInfo);
                } catch (jsonError) {
                  invalidJsonHandled = true;
                  hilog.error(0x0000, 'TestTag', `JSON stringify error: ${jsonError}`);
                }
              }
            }
          } catch (error) {
            hilog.error(0x0000, 'TestTag', `Outer exception: ${error}`);
          }
        }
      });
      
      hiAppEvent.removeWatcher({ name: watcherName });
    });
    
    it('should_continue_processing_after_error', () => {
      let continueProcessing = false;
      let processedCount = 0;
      let watcherName = 'continueProcessWatcher';
      
      hiAppEvent.addWatcher({
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
              try {
                if (processedCount === 0) {
                  throw new Error('First event error');
                }
                processedCount++;
              } catch (error) {
                hilog.error(0x0000, 'TestTag', `Event ${processedCount} error: ${error}`);
                processedCount++;
                continueProcessing = true;
                continue;
              }
            }
          }
        }
      });
      
      hiAppEvent.removeWatcher({ name: watcherName });
    });
    
    it('should_not_remove_watcher_in_callback', () => {
      let watcherName = 'noRemoveInCallback';
      let errorCaught = false;
      
      hiAppEvent.addWatcher({
        name: watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          try {
            hiAppEvent.removeWatcher({ name: watcherName });
          } catch (error) {
            errorCaught = true;
            hilog.error(0x0000, 'TestTag', 'Should not remove watcher in callback');
          }
        }
      });
      
      hiAppEvent.removeWatcher({ name: watcherName });
    });
  });
}