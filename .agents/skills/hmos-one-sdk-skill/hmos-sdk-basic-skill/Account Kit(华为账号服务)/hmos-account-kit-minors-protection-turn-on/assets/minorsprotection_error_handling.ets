import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { minorsProtection } from '@kit.AccountKit';

const TAG = 'MinorsProtectionErrorHandling';
const DOMAIN = 0x0000;

export class MinorsProtectionErrorHandling {
  
  handleTurnOnError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, 
      `leadToTurnOnMinorsMode failed. Code: ${error.code}, message: ${error.message}`);
    
    this.logErrorDetails(error);
    
    switch (error.code) {
      case 401:
        this.handleParameterError(error);
        break;
        
      case 1001502009:
        this.handleInternalError(error);
        break;
        
      case 1009900002:
        this.handleMinorsModeNotEnabled(error);
        break;
        
      case 1009900003:
        this.handleUserCanceled(error);
        break;
        
      case 1009900005:
        this.handleMinorsModeAlreadyOn(error);
        break;
        
      case 1009900006:
        this.handleMinorsModeAlreadyOff(error);
        break;
        
      case 1009900007:
        this.handleUnsupportedAccount(error);
        break;
        
      case 1009900011:
        this.handleServiceNotAvailable(error);
        break;
        
      default:
        this.handleUnknownError(error);
    }
  }
  
  handleGetInfoError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, 
      `getMinorsProtectionInfo failed. Code: ${error.code}, message: ${error.message}`);
    
    this.logErrorDetails(error);
    
    switch (error.code) {
      case 1001502009:
        this.handleInternalError(error);
        break;
        
      default:
        this.handleUnknownError(error);
    }
  }
  
  logErrorDetails(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, `Error code: ${error.code}`);
    hilog.error(DOMAIN, TAG, `Error message: ${error.message}`);
    
    if (error.data) {
      hilog.error(DOMAIN, TAG, `Error data: ${JSON.stringify(error.data)}`);
    }
  }
  
  handleParameterError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, 'Parameter error occurred');
    hilog.error(DOMAIN, TAG, 'Possible causes:');
    hilog.error(DOMAIN, TAG, '1. Mandatory parameters are left unspecified');
    hilog.error(DOMAIN, TAG, '2. Incorrect parameter types');
    
    this.suggestParameterCheck();
  }
  
  handleInternalError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, 'Internal error occurred');
    
    this.suggestRetryOrReport();
  }
  
  handleMinorsModeNotEnabled(error: BusinessError<Object>): void {
    hilog.warn(DOMAIN, TAG, 'Minors mode is not enabled');
    
    this.suggestTurnOnMinorsMode();
  }
  
  handleUserCanceled(error: BusinessError<Object>): void {
    hilog.info(DOMAIN, TAG, 'User canceled the operation');
    
    this.handleUserCancelation();
  }
  
  handleMinorsModeAlreadyOn(error: BusinessError<Object>): void {
    hilog.info(DOMAIN, TAG, 'Minors mode is already on');
    
    this.fetchAgeGroupInfo();
  }
  
  handleMinorsModeAlreadyOff(error: BusinessError<Object>): void {
    hilog.info(DOMAIN, TAG, 'Minors mode is already off');
    
    this.handleNormalMode();
  }
  
  handleUnsupportedAccount(error: BusinessError<Object>): void {
    hilog.warn(DOMAIN, TAG, 'Unsupported HUAWEI ID (overseas account)');
    hilog.warn(DOMAIN, TAG, 
      'Minors mode only supports Chinese mainland accounts (excluding HK, Macau, Taiwan)');
    
    this.suggestAccountSwitch();
  }
  
  handleServiceNotAvailable(error: BusinessError<Object>): void {
    hilog.warn(DOMAIN, TAG, 'Service not available');
    hilog.warn(DOMAIN, TAG, 'Possible cause: device entered privacy space');
    
    this.suggestPrivacySpaceExit();
  }
  
  handleUnknownError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, `Unknown error occurred: ${error.code}`);
    
    this.reportUnknownError(error);
  }
  
  suggestParameterCheck(): void {
    hilog.info(DOMAIN, TAG, 'Suggestion: Check Context parameter is correctly passed');
    hilog.info(DOMAIN, TAG, 'Suggestion: Verify parameter types match API requirements');
  }
  
  suggestRetryOrReport(): void {
    hilog.info(DOMAIN, TAG, 'Suggestion 1: Restart device and retry');
    hilog.info(DOMAIN, TAG, 
      'Suggestion 2: Submit online ticket if issue persists');
    hilog.info(DOMAIN, TAG, 
      'Ticket URL: https://developer.huawei.com/consumer/cn/support/feedback/');
  }
  
  suggestTurnOnMinorsMode(): void {
    hilog.info(DOMAIN, TAG, 
      'Suggestion: Call leadToTurnOnMinorsMode to guide user to turn on minors mode');
  }
  
  handleUserCancelation(): void {
    hilog.info(DOMAIN, TAG, 'User cancelation handled - no special action needed');
    hilog.info(DOMAIN, TAG, 'App can continue with normal content display');
  }
  
  fetchAgeGroupInfo(): void {
    hilog.info(DOMAIN, TAG, 'Fetching age group info since minors mode is already on');
    
    try {
      if (minorsProtection.supportMinorsMode()) {
        const info = minorsProtection.getMinorsProtectionInfoSync();
        const ageGroup = info.ageGroup;
        if (ageGroup) {
          hilog.info(DOMAIN, TAG, 
            `Age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to fetch age group info');
    }
  }
  
  handleNormalMode(): void {
    hilog.info(DOMAIN, TAG, 'Handling normal mode (minors mode off)');
    hilog.info(DOMAIN, TAG, 'Displaying normal content without restrictions');
  }
  
  suggestAccountSwitch(): void {
    hilog.info(DOMAIN, TAG, 
      'Suggestion: Guide user to log in with Chinese mainland account');
    hilog.info(DOMAIN, TAG, 
      'Alternative: Implement app-level minors protection as fallback');
  }
  
  suggestPrivacySpaceExit(): void {
    hilog.info(DOMAIN, TAG, 
      'Suggestion: Guide user to Settings > Privacy & Security > Privacy Space');
    hilog.info(DOMAIN, TAG, 'Suggestion: Exit privacy space to use minors mode');
    hilog.info(DOMAIN, TAG, 
      'Alternative: Implement app-level minors protection as fallback');
  }
  
  reportUnknownError(error: BusinessError<Object>): void {
    hilog.info(DOMAIN, TAG, 
      'Action: Report unknown error to Huawei support team');
    hilog.info(DOMAIN, TAG, 
      'Include: Error code, message, device info, and reproduction steps');
  }
}

export function handleMinorsProtectionError(
  operation: string, 
  error: BusinessError<Object>
): void {
  const handler = new MinorsProtectionErrorHandling();
  
  if (operation === 'leadToTurnOnMinorsMode') {
    handler.handleTurnOnError(error);
  } else if (operation === 'getMinorsProtectionInfo') {
    handler.handleGetInfoError(error);
  } else {
    handler.handleUnknownError(error);
  }
}