import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { describe, it, expect } from '@ohos/hypium';

export default function testInvalidParams() {
  describe('Invalid Params Tests', () => {
    it('should_reject_param_name_starting_with_number', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        '123param': 'value',
      };
      
      let errorCaught = false;
      let errorCode = 0;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
          errorCode = err.code;
        });
      
      expect(errorCaught).assertTrue();
      expect(errorCode).assertEqual(11101005);
    });
    
    it('should_reject_param_name_with_invalid_chars', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'param@name': 'value',
      };
      
      let errorCaught = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
        });
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_reject_invalid_domain', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': 'value',
      };
      
      let invalidDomain = 'Invalid@Domain';
      let errorCaught = false;
      let errorCode = 0;
      
      await hiAppEvent.setEventParam(params, invalidDomain, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
          errorCode = err.code;
        });
      
      expect(errorCaught).assertTrue();
      expect(errorCode).assertEqual(11101001);
    });
    
    it('should_reject_invalid_event_name', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': 'value',
      };
      
      let invalidEventName = 'InvalidEventName!';
      let errorCaught = false;
      let errorCode = 0;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, invalidEventName)
        .catch((err: BusinessError) => {
          errorCaught = true;
          errorCode = err.code;
        });
      
      expect(errorCaught).assertTrue();
      expect(errorCode).assertEqual(11101002);
    });
    
    it('should_reject_null_params', async () => {
      let errorCaught = false;
      let errorCode = 0;
      
      await hiAppEvent.setEventParam(null as any, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
          errorCode = err.code;
        });
      
      expect(errorCaught).assertTrue();
      expect(errorCode).assertEqual(401);
    });
    
    it('should_reject_null_domain', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': 'value',
      };
      
      let errorCaught = false;
      
      await hiAppEvent.setEventParam(params, null as any, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
        });
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_reject_empty_domain', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': 'value',
      };
      
      let errorCaught = false;
      
      await hiAppEvent.setEventParam(params, '', hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
        });
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_reject_domain_longer_than_32_chars', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': 'value',
      };
      
      let longDomain = 'domainNameLongerThan32CharactersShouldFail';
      let errorCaught = false;
      
      await hiAppEvent.setEventParam(params, longDomain, hiAppEvent.event.RESOURCE_OVERLIMIT)
        .catch((err: BusinessError) => {
          errorCaught = true;
        });
      
      expect(errorCaught).assertTrue();
    });
    
    it('should_reject_event_name_longer_than_48_chars', async () => {
      let params: Record<string, hiAppEvent.ParamType> = {
        'test_param': 'value',
      };
      
      let longEventName = 'eventNameLongerThan48CharactersThisShouldFail123456789';
      let errorCaught = false;
      
      await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, longEventName)
        .catch((err: BusinessError) => {
          errorCaught = true;
        });
      
      expect(errorCaught).assertTrue();
    });
  });
}