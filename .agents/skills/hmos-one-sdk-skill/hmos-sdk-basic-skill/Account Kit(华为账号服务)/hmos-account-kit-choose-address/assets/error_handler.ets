import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export function handleAddressChooseError(error: BusinessError): string {
  hilog.error(0x0000, 'AddressErrorHandler', 
    `Failed to choose address. Code: ${error.code}, message: ${error.message}`);

  let userMessage: string = '';

  switch (error.code) {
    case 401:
      userMessage = 'Parameter error. Please check the input parameters.';
      hilog.error(0x0000, 'AddressErrorHandler', 'Parameter error. Context may be invalid.');
      break;

    case 1008100001:
      userMessage = 'Internal error occurred. Please retry or restart your device.';
      hilog.error(0x0000, 'AddressErrorHandler', 
        'Internal error. Suggest: 1. Restart device. 2. Submit online ticket if persists.');
      break;

    case 1008100002:
      userMessage = 'Network is unavailable. Please check your network connection.';
      hilog.error(0x0000, 'AddressErrorHandler', 'Network unavailable. Check network connectivity.');
      break;

    case 1008100003:
      userMessage = 'You are not logged in. Please login with Huawei ID first.';
      hilog.error(0x0000, 'AddressErrorHandler', 
        'User not logged in. Suggest: Call LoginWithHuaweiIDRequest or guide user to settings.');
      break;

    case 1008100004:
      userMessage = 'App configuration error. Please check app certificate settings.';
      hilog.error(0x0000, 'AddressErrorHandler', 
        'Fingerprint check failed. Check: 1. client_id in module.json5. 2. Fingerprint in AGC.');
      break;

    case 1008100005:
      userMessage = 'Permission not applied. Please apply for required permissions.';
      hilog.error(0x0000, 'AddressErrorHandler', 
        'Permission not applied. Guide developer to complete permission application process.');
      break;

    case 1008100006:
      userMessage = 'You canceled the operation.';
      hilog.info(0x0000, 'AddressErrorHandler', 
        'User canceled operation. No special handling needed - this is user action.');
      break;

    case 1008100007:
      userMessage = 'Your account does not support shipping address feature.';
      hilog.error(0x0000, 'AddressErrorHandler', 
        'Account not supported. Suggest: Use China mainland account or fallback to manual input.');
      break;

    default:
      userMessage = 'Unknown error occurred. Please retry or contact support.';
      hilog.error(0x0000, 'AddressErrorHandler', 
        'Unknown error code: ${error.code}. Submit online ticket for support.');
  }

  return userMessage;
}

export function getErrorSeverity(errorCode: number): 'critical' | 'warning' | 'info' {
  if (errorCode === 1008100006) {
    return 'info';
  }
  
  if (errorCode === 1008100002 || errorCode === 1008100003) {
    return 'warning';
  }
  
  return 'critical';
}

export function shouldRetry(errorCode: number): boolean {
  const retryableErrors = [1008100001, 1008100002];
  return retryableErrors.includes(errorCode);
}

export function needsUserAction(errorCode: number): boolean {
  const userActionErrors = [1008100003, 1008100006, 1008100007];
  return userActionErrors.includes(errorCode);
}

export function needsDeveloperAction(errorCode: number): boolean {
  const developerActionErrors = [1008100004, 1008100005];
  return developerActionErrors.includes(errorCode);
}