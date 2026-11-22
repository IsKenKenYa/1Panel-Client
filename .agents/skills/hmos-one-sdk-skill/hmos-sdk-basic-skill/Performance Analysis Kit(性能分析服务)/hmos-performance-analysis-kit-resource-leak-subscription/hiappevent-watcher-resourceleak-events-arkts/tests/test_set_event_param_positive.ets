import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { describe, it, expect } from '@ohos/hypium';

export default function testSetEventParamPositive() {
  describe('Set Event Param Positive Tests', () => {
    it('should_successfully_set_single_param', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_key': 'test_value',
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
          hilog.info(0x0000, 'TestTag', 'Success to set event param');
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0000, 'TestTag', `Failed: ${err.code}, ${err.message}`);
        });
      
      expect(success).assertTrue();
    });
    
    it('should_successfully_set_multiple_params', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'param1': 100,
        'param2': 'value2',
        'param3': true,
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0000, 'TestTag', `Failed: ${err.code}`);
        });
      
      expect(success).assertTrue();
    });
    
    it('should_successfully_set_number_param', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'number_param': 12345,
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        });
      
      expect(success).assertTrue();
    });
    
    it('should_successfully_set_string_param', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'string_param': 'test_string_value',
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        });
      
      expect(success).assertTrue();
    });
    
    it('should_successfully_set_boolean_param', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'boolean_param': true,
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        });
      
      expect(success).assertTrue();
    });
    
    it('should_successfully_set_array_param', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'array_param': [1, 2, 3, 4, 5],
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        });
      
      expect(success).assertTrue();
    });
  });
}