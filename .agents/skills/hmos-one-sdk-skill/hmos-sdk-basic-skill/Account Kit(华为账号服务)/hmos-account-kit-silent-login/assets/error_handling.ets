import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ErrorHandler';
const DOMAIN = 0x0000;

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_FINGERPRINT_FAILED = 1001500001,
  ERROR_CODE_INVALID_PARAM = 1001502003,
  ERROR_CODE_NOT_AUTHORIZED = 1001502002
}

export enum UserAction {
  LOGIN_HUAWEI_ID,
  CHECK_NETWORK,
  RETRY,
  USE_OTHER_LOGIN,
  WAIT_AND_RETRY,
  CHECK_CLIENT_ID,
  CHECK_FINGERPRINT,
  CONTACT_SUPPORT,
  NONE
}

export interface ErrorHandlingResult {
  shouldRetry: boolean;
  userAction: UserAction;
  userMessage: string;
  technicalMessage: string;
}

export function handleSilentLoginError(error: BusinessError): ErrorHandlingResult {
  hilog.error(DOMAIN, TAG, `Error occurred. Code: ${error.code}, Message: ${error.message}`);
  
  switch (error.code) {
    case ErrorCode.ERROR_CODE_LOGIN_OUT:
      return {
        shouldRetry: false,
        userAction: UserAction.LOGIN_HUAWEI_ID,
        userMessage: '请先登录华为账号，或使用其他方式登录',
        technicalMessage: 'User has not logged in with HUAWEI ID. forceLogin is set to false.'
      };
      
    case ErrorCode.ERROR_CODE_NETWORK_ERROR:
      return {
        shouldRetry: true,
        userAction: UserAction.CHECK_NETWORK,
        userMessage: '网络异常，请检查网络连接并重试',
        technicalMessage: 'Network error detected. Device may be offline.'
      };
      
    case ErrorCode.ERROR_CODE_INTERNAL_ERROR:
      return {
        shouldRetry: true,
        userAction: UserAction.RETRY,
        userMessage: '登录失败，请重试或使用其他方式登录',
        technicalMessage: 'Internal error from Huawei account service.'
      };
      
    case ErrorCode.ERROR_CODE_USER_CANCEL:
      return {
        shouldRetry: false,
        userAction: UserAction.NONE,
        userMessage: '用户取消了授权',
        technicalMessage: 'User canceled the authorization operation.'
      };
      
    case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
      return {
        shouldRetry: true,
        userAction: UserAction.WAIT_AND_RETRY,
        userMessage: '系统服务异常，请稍后重试或使用其他方式登录',
        technicalMessage: 'System service exception. Service may be temporarily unavailable.'
      };
      
    case ErrorCode.ERROR_CODE_REQUEST_REFUSE:
      return {
        shouldRetry: false,
        userAction: UserAction.NONE,
        userMessage: '',
        technicalMessage: 'Duplicate request. Application should ignore this error.'
      };
      
    case ErrorCode.ERROR_CODE_FINGERPRINT_FAILED:
      return {
        shouldRetry: false,
        userAction: UserAction.CHECK_FINGERPRINT,
        userMessage: '应用指纹证书校验失败，请检查证书配置',
        technicalMessage: 'Failed to check the fingerprint of the app bundle.'
      };
      
    case ErrorCode.ERROR_CODE_INVALID_PARAM:
      return {
        shouldRetry: false,
        userAction: UserAction.CHECK_CLIENT_ID,
        userMessage: '参数无效，请检查Client ID配置',
        technicalMessage: 'Invalid input parameter value. Check Client ID configuration.'
      };
      
    case ErrorCode.ERROR_CODE_NOT_AUTHORIZED:
      return {
        shouldRetry: false,
        userAction: UserAction.LOGIN_HUAWEI_ID,
        userMessage: '应用未授权，请重新授权',
        technicalMessage: 'The application is not authorized.'
      };
      
    default:
      return {
        shouldRetry: false,
        userAction: UserAction.USE_OTHER_LOGIN,
        userMessage: '登录失败，请使用其他方式登录',
        technicalMessage: `Unknown error code: ${error.code}. Message: ${error.message}`
      };
  }
}

export function getUserFriendlyMessage(error: BusinessError): string {
  const result = handleSilentLoginError(error);
  return result.userMessage;
}

export function shouldRetryOperation(error: BusinessError): boolean {
  const result = handleSilentLoginError(error);
  return result.shouldRetry;
}

export function getRecommendedAction(error: BusinessError): UserAction {
  const result = handleSilentLoginError(error);
  return result.userAction;
}

export function logErrorDetails(error: BusinessError): void {
  const result = handleSilentLoginError(error);
  
  hilog.error(DOMAIN, TAG, '========== Error Details ==========');
  hilog.error(DOMAIN, TAG, `Error Code: ${error.code}`);
  hilog.error(DOMAIN, TAG, `Error Message: ${error.message}`);
  hilog.error(DOMAIN, TAG, `Technical Message: ${result.technicalMessage}`);
  hilog.error(DOMAIN, TAG, `User Message: ${result.userMessage}`);
  hilog.error(DOMAIN, TAG, `Should Retry: ${result.shouldRetry}`);
  hilog.error(DOMAIN, TAG, `Recommended Action: ${result.userAction}`);
  hilog.error(DOMAIN, TAG, '====================================');
}

export function handleServerError(httpStatusCode: number, subError: number): ErrorHandlingResult {
  hilog.error(DOMAIN, TAG, `Server error. HTTP Status: ${httpStatusCode}, Sub Error: ${subError}`);
  
  if (httpStatusCode === 400) {
    switch (subError) {
      case 20155:
        return {
          shouldRetry: true,
          userAction: UserAction.RETRY,
          userMessage: '授权码已过期，请重新登录',
          technicalMessage: 'Authorization code expired (5 minutes timeout).'
        };
        
      case 20156:
        return {
          shouldRetry: true,
          userAction: UserAction.RETRY,
          userMessage: '授权码已使用，请重新登录',
          technicalMessage: 'Authorization code already used. Code can only be used once.'
        };
        
      case 20158:
        return {
          shouldRetry: true,
          userAction: UserAction.RETRY,
          userMessage: '授权码已失效，请重新登录',
          technicalMessage: 'Authorization code invalidated due to user actions (e.g., password change).'
        };
        
      case 12304:
        return {
          shouldRetry: false,
          userAction: UserAction.CONTACT_SUPPORT,
          userMessage: 'Client Secret无效，请联系技术支持',
          technicalMessage: 'Invalid client_secret. Client ID and Client Secret mismatch.'
        };
        
      case 20002:
      case 20003:
        return {
          shouldRetry: false,
          userAction: UserAction.CHECK_CLIENT_ID,
          userMessage: 'Client ID格式错误或不存在',
          technicalMessage: 'Client ID format error or does not exist in system.'
        };
        
      default:
        return {
          shouldRetry: false,
          userAction: UserAction.CONTACT_SUPPORT,
          userMessage: '服务端参数错误，请联系技术支持',
          technicalMessage: `Server parameter error. Sub error: ${subError}`
        };
    }
  }
  
  if (httpStatusCode === 403) {
    return {
      shouldRetry: false,
      userAction: UserAction.CONTACT_SUPPORT,
      userMessage: '无权限访问，请检查网络安全策略',
      technicalMessage: 'Access forbidden. Network security policy may be blocking access.'
    };
  }
  
  if (httpStatusCode === 500 || httpStatusCode === 590) {
    return {
      shouldRetry: true,
      userAction: UserAction.WAIT_AND_RETRY,
      userMessage: '服务内部错误，请稍后重试',
      technicalMessage: 'Internal server error. Please retry later.'
    };
  }
  
  if (httpStatusCode === 502 || httpStatusCode === 504) {
    return {
      shouldRetry: true,
      userAction: UserAction.WAIT_AND_RETRY,
      userMessage: '网络连接异常，请稍后重试',
      technicalMessage: 'Network connection error. Please retry later.'
    };
  }
  
  if (httpStatusCode === 503) {
    return {
      shouldRetry: true,
      userAction: UserAction.WAIT_AND_RETRY,
      userMessage: '系统流控，请稍后重试',
      technicalMessage: 'System flow control triggered. Please retry later.'
    };
  }
  
  return {
    shouldRetry: false,
    userAction: UserAction.USE_OTHER_LOGIN,
    userMessage: '服务端错误，请使用其他方式登录',
    technicalMessage: `Unhandled server error. HTTP Status: ${httpStatusCode}, Sub Error: ${subError}`
  };
}