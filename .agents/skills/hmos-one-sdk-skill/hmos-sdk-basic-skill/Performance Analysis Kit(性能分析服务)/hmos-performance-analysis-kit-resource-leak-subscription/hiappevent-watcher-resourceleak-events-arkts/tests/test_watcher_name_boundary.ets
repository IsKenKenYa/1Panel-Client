import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { describe, it, expect } from '@ohos/hypium';

export default function testWatcherNameBoundary() {
  describe('Watcher Name Boundary Tests', () => {
    it('should_accept_32_char_name', () => {
      let validName = 'watcherNameWith32Characters123';
      let holder = null;
      let errorCaught = false;
      
      try {
        holder = hiAppEvent.addWatcher({
          name: validName,
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
      
      expect(errorCaught).assertFalse();
      expect(holder).not.toBeNull();
      
      hiAppEvent.removeWatcher({ name: validName });
    });
    
    it('should_accept_min_length_name', () => {
      let minName = 'a';
      let holder = null;
      let errorCaught = false;
      
      try {
        holder = hiAppEvent.addWatcher({
          name: minName,
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
      
      expect(errorCaught).assertFalse();
      expect(holder).not.toBeNull();
      
      hiAppEvent.removeWatcher({ name: minName });
    });
    
    it('should_accept_name_with_letters_numbers_underscore', () => {
      let validName = 'test_Watcher_123';
      let holder = null;
      let errorCaught = false;
      
      try {
        holder = hiAppEvent.addWatcher({
          name: validName,
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
      
      expect(errorCaught).assertFalse();
      expect(holder).not.toBeNull();
      
      hiAppEvent.removeWatcher({ name: validName });
    });
    
    it('should_reject_name_longer_than_32', () => {
      let longName = 'watcherNameLongerThan32CharactersThisShouldFail123456789';
      let errorCaught = false;
      let errorCode = 0;
      
      try {
        hiAppEvent.addWatcher({
          name: longName,
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
    
    it('should_reject_name_with_invalid_chars', () => {
      let invalidName = 'test@Watcher#123';
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
    
    it('should_reject_empty_name', () => {
      let errorCaught = false;
      
      try {
        hiAppEvent.addWatcher({
          name: '',
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
  });
}