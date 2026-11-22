import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { describe, it, expect } from '@ohos/hypium';

export default function testInvalidWatcherName() {
  describe('Invalid Watcher Name Tests', () => {
    it('should_reject_name_starting_with_number', () => {
      let invalidName = '123Watcher';
      let errorCaught = false;
      let errorCode = 0;
      
      try {
        hiAppEvent.addWatcher({
          name: invalidName,
          appEventFilters: [
            {
              domain: hiAppEvent.domain.OS,
              names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
            }
          ]
        });
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        errorCaught = true;
        errorCode = err.code;
      }
      
      expect(errorCaught).assertTrue();
      expect(errorCode).assertEqual(11102001);
    });
    
    it('should_reject_name_with_space', () => {
      let invalidName = 'test watcher';
      let errorCaught = false;
      
      try {
        hiAppEvent.addWatcher({
          name: invalidName,
          appEventFilters: [
            {
              domain: hiAppEvent.domain.OS,
              names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
            }
          ]
        });
      } catch (error) {
        errorCaught = true;
      }
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_reject_name_with_special_chars', () => {
      let invalidNames = ['test@watcher', 'test#watcher', 'test!watcher', 'test$watcher%'];
      
      for (const name of invalidNames) {
        let errorCaught = false;
        
        try {
          hiAppEvent.addWatcher({
            name: name,
            appEventFilters: [
              {
                domain: hiAppEvent.domain.OS,
                names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
              }
            ]
          });
        } catch (error) {
          errorCaught = true;
        }
        
        expect(errorCaught).assertTrue();
      }
    });
    
    it('should_reject_name_with_hyphen', () => {
      let invalidName = 'test-watcher';
      let errorCaught = false;
      
      try {
        hiAppEvent.addWatcher({
          name: invalidName,
          appEventFilters: [
            {
              domain: hiAppEvent.domain.OS,
              names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
            }
          ]
        });
      } catch (error) {
        errorCaught = true;
      }
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_reject_name_ending_with_underscore', () => {
      let invalidName = 'testWatcher_';
      let errorCaught = false;
      
      try {
        hiAppEvent.addWatcher({
          name: invalidName,
          appEventFilters: [
            {
              domain: hiAppEvent.domain.OS,
              names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
            }
          ]
        });
      } catch (error) {
        errorCaught = true;
      }
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_reject_null_name', () => {
      let errorCaught = false;
      
      try {
        hiAppEvent.addWatcher({
          name: null as any,
          appEventFilters: [
            {
              domain: hiAppEvent.domain.OS,
              names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
            }
          ]
        });
      } catch (error) {
        errorCaught = true;
      }
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_return_error_code_11102001_for_invalid_name', () => {
      let invalidName = 'InvalidWatcherName!';
      let errorCode = 0;
      
      try {
        hiAppEvent.addWatcher({
          name: invalidName,
          appEventFilters: [
            {
              domain: hiAppEvent.domain.OS,
              names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
            }
          ]
        });
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        errorCode = err.code;
      }
      
      expect(errorCode).assertEqual(11102001);
    });
  });
}