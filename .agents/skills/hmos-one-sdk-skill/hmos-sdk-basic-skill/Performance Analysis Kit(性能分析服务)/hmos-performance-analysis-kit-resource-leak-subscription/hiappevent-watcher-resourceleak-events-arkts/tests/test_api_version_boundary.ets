import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';
import { describe, it, expect } from '@ohos/hypium';

export default function testApiVersionBoundary() {
  describe('API Version Compatibility Tests', () => {
    it('should_check_api_version_9_support', () => {
      let minApiVersion = 9;
      expect(deviceInfo.sdkApiVersion).assertLargerThanOrEqual(minApiVersion);
      
      let holder = hiAppEvent.addWatcher({
        name: 'api9TestWatcher',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
          }
        ]
      });
      
      expect(holder).not.toBeNull();
      hiAppEvent.removeWatcher({ name: 'api9TestWatcher' });
    });
    
    it('should_check_api_version_12_setEventParam', async () => {
      let supported = deviceInfo.sdkApiVersion >= 12;
      
      if (supported) {
        let success = false;
        
        await hiAppEvent.setEventParam({ 'test': 'value' }, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
          .then(() => {
            success = true;
          });
        
        expect(success).assertTrue();
      } else {
        hilog.warn(0x0000, 'TestTag', 'API version < 12, setEventParam not supported');
      }
      
      expect(deviceInfo.sdkApiVersion).assertTrue();
    });
    
    it('should_check_api_version_15_setEventConfig', async () => {
      let supported = deviceInfo.sdkApiVersion >= 15;
      
      if (supported) {
        let success = false;
        
        await hiAppEvent.setEventConfig(hiAppEvent.event.RESOURCE_OVERLIMIT, { 'js_heap_logtype': 'event' })
          .then(() => {
            success = true;
          });
        
        expect(success).assertTrue();
      } else {
        hilog.warn(0x0000, 'TestTag', 'API version < 15, setEventConfig not supported');
      }
    });
    
    it('should_check_api_version_22_configEventPolicy', async () => {
      let supported = deviceInfo.sdkApiVersion >= 22;
      
      if (supported) {
        let success = false;
        
        let policy: hiAppEvent.EventPolicy = {
          'resourceOverlimitPolicy': {
            'pageSwitchLogEnable': true
          }
        };
        
        await hiAppEvent.configEventPolicy(policy)
          .then(() => {
            success = true;
          });
        
        expect(success).assertTrue();
      } else {
        hilog.warn(0x0000, 'TestTag', 'API version < 22, configEventPolicy not supported');
      }
    });
    
    it('should_gracefully_handle_lower_api_version', () => {
      if (deviceInfo.sdkApiVersion < 24) {
        let policy: hiAppEvent.EventPolicy = {
          'resourceOverlimitPolicy': {
            'pageSwitchLogEnable': true
          }
        };
        
        let errorCaught = false;
        
        hiAppEvent.configEventPolicy(policy)
          .catch((err: BusinessError) => {
            errorCaught = true;
          });
        
        expect(errorCaught).assertTrue();
      }
    });
    
    it('should_support_api_version_24_page_switch_log', async () => {
      if (deviceInfo.sdkApiVersion >= 24) {
        let policy: hiAppEvent.EventPolicy = {
          'resourceOverlimitPolicy': {
            'pageSwitchLogEnable': true
          }
        };
        
        let success = false;
        
        await hiAppEvent.configEventPolicy(policy)
          .then(() => {
            success = true;
          });
        
        expect(success).assertTrue();
      }
    });
  });
}