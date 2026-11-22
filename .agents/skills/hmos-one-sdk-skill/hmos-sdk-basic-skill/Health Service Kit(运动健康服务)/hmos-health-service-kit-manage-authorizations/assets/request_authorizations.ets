import { healthStore } from '@kit.HealthServiceKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AuthorizationExample';
const DOMAIN = 0x0000;

export async function requestHealthAuthorizations(context: common.UIAbilityContext): Promise<void> {
  try {
    await healthStore.init(context);
    hilog.info(DOMAIN, TAG, 'HealthStore initialized successfully');

    const authorizationRequest: healthStore.AuthorizationRequest = {
      readDataTypes: [
        healthStore.exerciseSequenceHelper.DATA_TYPE,
        healthStore.samplePointHelper.heartRate.DATA_TYPE
      ],
      writeDataTypes: [
        healthStore.exerciseSequenceHelper.DATA_TYPE,
        healthStore.samplePointHelper.heartRate.DATA_TYPE
      ]
    };

    const authorizationResponse = await healthStore.requestAuthorizations(context, authorizationRequest);
    
    hilog.info(DOMAIN, TAG, 'Authorization request succeeded');
    
    authorizationResponse.writeDataTypes.forEach((dataType) => {
      hilog.info(DOMAIN, TAG, `Granted write permission for: ${dataType.name}`);
    });
    
    authorizationResponse.readDataTypes.forEach((dataType) => {
      hilog.info(DOMAIN, TAG, `Granted read permission for: ${dataType.name}`);
    });

  } catch (error) {
    hilog.error(DOMAIN, TAG, `Failed to request authorization. Code: ${error.code}, Message: ${error.message}`);
    
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission verification failed. Check app fingerprint configuration and permissions.');
        break;
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error. Check required parameters and data types.');
        break;
      case 1002702001:
        hilog.error(DOMAIN, TAG, 'Account not logged in. Please login with Huawei ID.');
        break;
      case 1002703001:
        hilog.error(DOMAIN, TAG, 'User privacy not agreed. Please start Health App and agree to privacy policy.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
    }
  }
}