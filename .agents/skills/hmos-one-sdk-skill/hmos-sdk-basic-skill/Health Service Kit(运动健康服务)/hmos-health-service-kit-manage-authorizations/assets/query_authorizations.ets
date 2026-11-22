import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'QueryAuthorization';
const DOMAIN = 0x0000;

export async function queryHealthAuthorizations(): Promise<healthStore.AuthorizationResponse | null> {
  try {
    const queryRequest: healthStore.AuthorizationRequest = {
      readDataTypes: [
        healthStore.exerciseSequenceHelper.DATA_TYPE,
        healthStore.samplePointHelper.heartRate.DATA_TYPE
      ],
      writeDataTypes: [
        healthStore.exerciseSequenceHelper.DATA_TYPE,
        healthStore.samplePointHelper.heartRate.DATA_TYPE
      ]
    };

    const queryResponse = await healthStore.getAuthorizations(queryRequest);
    
    hilog.info(DOMAIN, TAG, 'Query authorization succeeded');
    
    if (queryResponse.writeDataTypes.length === 0 && queryResponse.readDataTypes.length === 0) {
      hilog.warn(DOMAIN, TAG, 'No permissions granted. User needs to authorize first.');
      return null;
    }
    
    queryResponse.writeDataTypes.forEach((dataType) => {
      hilog.info(DOMAIN, TAG, `Has write permission for: ${dataType.name}`);
    });
    
    queryResponse.readDataTypes.forEach((dataType) => {
      hilog.info(DOMAIN, TAG, `Has read permission for: ${dataType.name}`);
    });

    return queryResponse;

  } catch (error) {
    hilog.error(DOMAIN, TAG, `Failed to query authorization. Code: ${error.code}, Message: ${error.message}`);
    
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission verification failed.');
        break;
      case 1002701001:
        hilog.error(DOMAIN, TAG, 'Network error. Please check network connection.');
        break;
      case 1002702001:
        hilog.error(DOMAIN, TAG, 'Account not logged in.');
        break;
      case 1002702002:
        hilog.error(DOMAIN, TAG, 'Account error. Failed to obtain account information.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
    }
    
    return null;
  }
}

export function hasPermissionForDataType(
  response: healthStore.AuthorizationResponse,
  dataType: healthStore.DataType,
  isWrite: boolean
): boolean {
  const targetArray = isWrite ? response.writeDataTypes : response.readDataTypes;
  return targetArray.some((dt) => dt.id === dataType.id);
}