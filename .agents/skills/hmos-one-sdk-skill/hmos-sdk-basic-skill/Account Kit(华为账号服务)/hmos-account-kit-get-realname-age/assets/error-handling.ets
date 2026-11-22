import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ErrorHandler';
const DOMAIN = 0x0000;

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_PERMISSION_DENIED = 1001502014,
  ERROR_CODE_CERT_VERIFY_FAILED = 1001500001,
  ERROR_CODE_APP_NOT_AUTHORIZED = 1001502002
}

export class ErrorHandler {
  private errorMessages: Map<number, string>;
  private recoveryActions: Map<number, () => void>;

  constructor() {
    this.errorMessages = new Map([
      [ErrorCode.ERROR_CODE_LOGIN_OUT, '用户未登录华为账号'],
      [ErrorCode.ERROR_CODE_NETWORK_ERROR, '网络连接异常'],
      [ErrorCode.ERROR_CODE_USER_CANCEL, '用户取消授权'],
      [ErrorCode.ERROR_CODE_SYSTEM_SERVICE, '系统服务异常'],
      [ErrorCode.ERROR_CODE_PERMISSION_DENIED, '应用权限不足'],
      [ErrorCode.ERROR_CODE_REQUEST_REFUSE, '重复请求'],
      [ErrorCode.ERROR_CODE_CERT_VERIFY_FAILED, '应用证书校验失败'],
      [ErrorCode.ERROR_CODE_APP_NOT_AUTHORIZED, '应用未获得授权']
    ]);

    this.recoveryActions = new Map();
  }

  handleError(error: BusinessError): void {
    const errorMessage = this.errorMessages.get(error.code) || `未知错误: ${error.code}`;
    
    hilog.error(DOMAIN, TAG, `Error occurred: ${errorMessage}`);
    hilog.error(DOMAIN, TAG, `Error details: ${error.message}`);
    
    const recoveryAction = this.recoveryActions.get(error.code);
    if (recoveryAction) {
      hilog.info(DOMAIN, TAG, 'Executing recovery action');
      recoveryAction();
    }
    
    this.showUserMessage(errorMessage);
  }

  setRecoveryAction(errorCode: number, action: () => void): void {
    this.recoveryActions.set(errorCode, action);
  }

  getErrorMessage(errorCode: number): string {
    return this.errorMessages.get(errorCode) || `错误码: ${errorCode}`;
  }

  isUserRecoverable(errorCode: number): boolean {
    const recoverableErrors = [
      ErrorCode.ERROR_CODE_LOGIN_OUT,
      ErrorCode.ERROR_CODE_NETWORK_ERROR,
      ErrorCode.ERROR_CODE_PERMISSION_DENIED,
      ErrorCode.ERROR_CODE_CERT_VERIFY_FAILED
    ];
    
    return recoverableErrors.includes(errorCode);
  }

  shouldRetry(errorCode: number): boolean {
    const retryableErrors = [
      ErrorCode.ERROR_CODE_NETWORK_ERROR,
      ErrorCode.ERROR_CODE_SYSTEM_SERVICE
    ];
    
    return retryableErrors.includes(errorCode);
  }

  private showUserMessage(message: string): void {
    hilog.error(DOMAIN, TAG, `User message: ${message}`);
  }
}

export function handleClientError(error: BusinessError): void {
  const handler = new ErrorHandler();
  handler.handleError(error);
}

export function handleServerError(error: BusinessError): void {
  hilog.error(DOMAIN, TAG, `Server error: ${error.code}, ${error.message}`);
  
  if (error.message?.includes('401') || error.message?.includes('403')) {
    hilog.warn(DOMAIN, TAG, 'Token expired or invalid');
  } else if (error.message?.includes('400')) {
    hilog.error(DOMAIN, TAG, 'Invalid request parameters');
  } else if (error.message?.includes('500')) {
    hilog.error(DOMAIN, TAG, 'Server internal error');
  }
}

export function createErrorDialog(errorCode: number): string {
  const handler = new ErrorHandler();
  const message = handler.getErrorMessage(errorCode);
  
  let recoveryHint = '';
  
  if (handler.isUserRecoverable(errorCode)) {
    switch (errorCode) {
      case ErrorCode.ERROR_CODE_LOGIN_OUT:
        recoveryHint = '请登录华为账号后重试';
        break;
      case ErrorCode.ERROR_CODE_NETWORK_ERROR:
        recoveryHint = '请检查网络连接后重试';
        break;
      case ErrorCode.ERROR_CODE_PERMISSION_DENIED:
        recoveryHint = '请联系应用开发者配置权限';
        break;
      case ErrorCode.ERROR_CODE_CERT_VERIFY_FAILED:
        recoveryHint = '请检查应用签名配置';
        break;
    }
  }
  
  return `${message}\n${recoveryHint}`;
}

export function logError(context: string, error: BusinessError): void {
  hilog.error(DOMAIN, TAG, `[${context}] Error: ${error.code} - ${error.message}`);
}

export function shouldIgnoreError(errorCode: number): boolean {
  return errorCode === ErrorCode.ERROR_CODE_REQUEST_REFUSE;
}

export function isCriticalError(errorCode: number): boolean {
  const criticalErrors = [
    ErrorCode.ERROR_CODE_CERT_VERIFY_FAILED,
    ErrorCode.ERROR_CODE_SYSTEM_SERVICE
  ];
  
  return criticalErrors.includes(errorCode);
}