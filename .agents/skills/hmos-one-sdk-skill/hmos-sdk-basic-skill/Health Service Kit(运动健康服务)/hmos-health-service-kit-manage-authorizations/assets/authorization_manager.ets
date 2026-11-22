import { healthStore } from '@kit.HealthServiceKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AuthorizationManager';
const DOMAIN = 0x0000;

export class HealthAuthorizationManager {
  private context: common.UIAbilityContext;
  private isInitialized: boolean = false;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async initialize(): Promise<boolean> {
    if (this.isInitialized) {
      hilog.info(DOMAIN, TAG, 'Already initialized');
      return true;
    }

    try {
      await healthStore.init(this.context);
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'HealthStore initialized successfully');
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize. Code: ${error.code}, Message: ${error.message}`);
      return false;
    }
  }

  async requestAuthorizations(
    readDataTypes: healthStore.DataType[],
    writeDataTypes: healthStore.DataType[]
  ): Promise<healthStore.AuthorizationResponse | null> {
    if (!this.isInitialized) {
      hilog.error(DOMAIN, TAG, 'HealthStore not initialized. Call initialize() first.');
      return null;
    }

    try {
      const request: healthStore.AuthorizationRequest = {
        readDataTypes: readDataTypes,
        writeDataTypes: writeDataTypes
      };

      const response = await healthStore.requestAuthorizations(this.context, request);
      
      hilog.info(DOMAIN, TAG, 'Authorization request succeeded');
      this.logGrantedPermissions(response);
      
      return response;
    } catch (error) {
      this.handleAuthorizationError(error);
      return null;
    }
  }

  async queryAuthorizations(
    readDataTypes: healthStore.DataType[],
    writeDataTypes: healthStore.DataType[]
  ): Promise<healthStore.AuthorizationResponse | null> {
    if (!this.isInitialized) {
      hilog.error(DOMAIN, TAG, 'HealthStore not initialized. Call initialize() first.');
      return null;
    }

    try {
      const request: healthStore.AuthorizationRequest = {
        readDataTypes: readDataTypes,
        writeDataTypes: writeDataTypes
      };

      const response = await healthStore.getAuthorizations(request);
      
      hilog.info(DOMAIN, TAG, 'Query authorization succeeded');
      this.logGrantedPermissions(response);
      
      return response;
    } catch (error) {
      this.handleAuthorizationError(error);
      return null;
    }
  }

  async cancelAllAuthorizations(): Promise<boolean> {
    if (!this.isInitialized) {
      hilog.error(DOMAIN, TAG, 'HealthStore not initialized. Call initialize() first.');
      return false;
    }

    try {
      await healthStore.cancelAuthorizations();
      hilog.info(DOMAIN, TAG, 'All authorizations canceled successfully');
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to cancel authorizations. Code: ${error.code}, Message: ${error.message}`);
      return false;
    }
  }

  hasWritePermission(response: healthStore.AuthorizationResponse, dataType: healthStore.DataType): boolean {
    return response.writeDataTypes.some((dt) => dt.id === dataType.id);
  }

  hasReadPermission(response: healthStore.AuthorizationResponse, dataType: healthStore.DataType): boolean {
    return response.readDataTypes.some((dt) => dt.id === dataType.id);
  }

  private logGrantedPermissions(response: healthStore.AuthorizationResponse): void {
    hilog.info(DOMAIN, TAG, 'Granted write permissions:');
    response.writeDataTypes.forEach((dataType) => {
      hilog.info(DOMAIN, TAG, `  - ${dataType.name} (ID: ${dataType.id})`);
    });

    hilog.info(DOMAIN, TAG, 'Granted read permissions:');
    response.readDataTypes.forEach((dataType) => {
      hilog.info(DOMAIN, TAG, `  - ${dataType.name} (ID: ${dataType.id})`);
    });
  }

  private handleAuthorizationError(error: Error): void {
    hilog.error(DOMAIN, TAG, `Authorization error. Code: ${error.code}, Message: ${error.message}`);
    
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission verification failed. Possible causes:');
        hilog.error(DOMAIN, TAG, '  - Incorrect app fingerprint configuration');
        hilog.error(DOMAIN, TAG, '  - Missing permissions in AGC configuration');
        hilog.error(DOMAIN, TAG, '  - User not authorized');
        break;
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error. Check:');
        hilog.error(DOMAIN, TAG, '  - All required parameters are provided');
        hilog.error(DOMAIN, TAG, '  - Parameter types are correct');
        hilog.error(DOMAIN, TAG, '  - Parameter values are valid');
        break;
      case 1001502001:
        hilog.error(DOMAIN, TAG, 'Huawei account not logged in. Please login first.');
        break;
      case 1001502005:
        hilog.error(DOMAIN, TAG, 'Network error. Please check network connection.');
        break;
      case 1001502012:
        hilog.warn(DOMAIN, TAG, 'User canceled authorization. Respect user choice.');
        break;
      case 1001502014:
        hilog.error(DOMAIN, TAG, 'App not authorized. Please request permissions in AGC platform.');
        break;
      case 1002701001:
        hilog.error(DOMAIN, TAG, 'Network unavailable. Please check network settings.');
        break;
      case 1002702001:
        hilog.error(DOMAIN, TAG, 'Account not logged in. Please login with Huawei ID.');
        break;
      case 1002702002:
        hilog.error(DOMAIN, TAG, 'Account error. Failed to obtain account information.');
        break;
      case 1002703001:
        hilog.error(DOMAIN, TAG, 'User privacy not agreed. Please start Health App and agree to privacy policy.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
    }
  }
}

export function createAuthorizationManager(context: common.UIAbilityContext): HealthAuthorizationManager {
  return new HealthAuthorizationManager(context);
}