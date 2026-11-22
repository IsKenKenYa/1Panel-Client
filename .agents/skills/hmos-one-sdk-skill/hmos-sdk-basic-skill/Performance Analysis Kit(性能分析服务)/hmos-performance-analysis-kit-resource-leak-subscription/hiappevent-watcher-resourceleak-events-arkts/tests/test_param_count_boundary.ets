import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { describe, it, expect } from '@ohos/hypium';

export default function testParamCountBoundary() {
  describe('Param Count Boundary Tests', () => {
    it('should_accept_64_params', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {};
      
      for (let i = 0; i < 64; i++) {
        params[`param${i}`] = i;
      }
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        })
        .catch((err: BusinessError) => {
          hilog.error(0x0000, 'TestTag', `Error: ${err.code}`);
        });
      
      expect(success).assertTrue();
    });
    
    it('should_accept_single_param', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'single_param': 'value',
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        });
      
      expect(success).assertTrue();
    });
    
    it('should_reject_more_than_64_params', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {};
      
      for (let i = 0; i < 65; i++) {
        params[`param${i}`] = i;
      }
      
      let errorCaught = false;
      let errorCode = 0;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          hilog.info(0x0000, 'TestTag', 'Unexpected success');
        })
        .catch((err: BusinessError) => {
          errorCaught = true;
          errorCode = err.code;
        });
      
      expect(errorCaught).assertTrue();
      expect(errorCode).assertEqual(11101007);
    });
    
    it('should_accept_32_char_param_name', async () => {
      let paramName = 'paramNameWith32Characters12345';
      let params: Record<string, hiAppEvent.ParamType> = {};
      params[paramName] = 'test';
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        });
      
      expect(success).assertTrue();
    });
    
    it('should_reject_param_name_longer_than_32', async () => {
      let paramName = 'paramNameLongerThan32CharactersThisShouldFail';
      let params: Record<string, hiAppEvent.ParamType> = {};
      params[paramName] = 'test';
      
      let errorCaught = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
        });
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_accept_1024_char_param_value', async () => {
      let longValue = 'a'.repeat(1024);
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': longValue,
      };
      
      let success = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .then(() => {
          success = true;
        });
      
      expect(success).assertTrue();
    });
    
    it('should_reject_param_value_longer_than_1024', async () => {
      let tooLongValue = 'a'.repeat(1025);
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': tooLongValue,
      };
      
      let errorCaught = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
        });
      
      expect(errorCaught).assertTrue();
    });
  });
}