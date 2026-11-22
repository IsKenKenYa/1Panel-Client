import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ErrorHandler';
const DOMAIN = 0x0000;

export enum MinorsProtectionErrorCode {
  PARAM_ERROR = 401,
  INTERNAL_ERROR = 1001502009,
  MINORS_MODE_NOT_ENABLED = 1009900002,
  USER_CANCELED = 1009900003,
  MINORS_MODE_ALREADY_ON = 1009900005,
  MINORS_MODE_ALREADY_OFF = 1009900006,
  UNSUPPORTED_ACCOUNT = 1009900007,
  SERVICE_NOT_AVAILABLE = 1009900011
}

export interface ErrorHandlerResult {
  handled: boolean;
  userMessage: string;
  shouldRetry: boolean;
  logLevel: 'info' | 'warn' | 'error';
}

export class MinorsProtectionErrorHandler {
  private errorCount: Map<number, number> = new Map();

  handleError(error: BusinessError<Object>): ErrorHandlerResult {
    const errorCode = error.code;
    this.incrementErrorCount(errorCode);

    hilog.error(DOMAIN, TAG, 
      `Error occurred: code=${errorCode}, message=${error.message}`);

    const result = this.processError(errorCode, error.message);
    
    hilog.info(DOMAIN, TAG, 
      `Error handled: userMessage=${result.userMessage}, shouldRetry=${result.shouldRetry}`);

    return result;
  }

  private processError(errorCode: number, errorMessage: string): ErrorHandlerResult {
    switch (errorCode) {
      case MinorsProtectionErrorCode.PARAM_ERROR:
        return this.handleParamError(errorMessage);
      
      case MinorsProtectionErrorCode.INTERNAL_ERROR:
        return this.handleInternalError(errorMessage);
      
      case MinorsProtectionErrorCode.MINORS_MODE_NOT_ENABLED:
        return this.handleMinorsModeNotEnabled(errorMessage);
      
      case MinorsProtectionErrorCode.USER_CANCELED:
        return this.handleUserCanceled(errorMessage);
      
      case MinorsProtectionErrorCode.MINORS_MODE_ALREADY_ON:
        return this.handleMinorsModeAlreadyOn(errorMessage);
      
      case MinorsProtectionErrorCode.MINORS_MODE_ALREADY_OFF:
        return this.handleMinorsModeAlreadyOff(errorMessage);
      
      case MinorsProtectionErrorCode.UNSUPPORTED_ACCOUNT:
        return this.handleUnsupportedAccount(errorMessage);
      
      case MinorsProtectionErrorCode.SERVICE_NOT_AVAILABLE:
        return this.handleServiceNotAvailable(errorMessage);
      
      default:
        return this.handleUnknownError(errorCode, errorMessage);
    }
  }

  private handleParamError(message: string): ErrorHandlerResult {
    return {
      handled: true,
      userMessage: '参数错误，请检查调用方式是否正确',
      shouldRetry: false,
      logLevel: 'error'
    };
  }

  private handleInternalError(message: string): ErrorHandlerResult {
    const count = this.getErrorCount(MinorsProtectionErrorCode.INTERNAL_ERROR);
    const shouldRetry = count < 3;

    return {
      handled: true,
      userMessage: shouldRetry 
        ? '内部错误，请重启设备后重试' 
        : '内部错误持续发生，请联系客服',
      shouldRetry,
      logLevel: 'error'
    };
  }

  private handleMinorsModeNotEnabled(message: string): ErrorHandlerResult {
    return {
      handled: true,
      userMessage: '未成年人模式未开启，请先开启未成年人模式',
      shouldRetry: false,
      logLevel: 'warn'
    };
  }

  private handleUserCanceled(message: string): ErrorHandlerResult {
    return {
      handled: true,
      userMessage: '用户取消了操作',
      shouldRetry: false,
      logLevel: 'info'
    };
  }

  private handleMinorsModeAlreadyOn(message: string): ErrorHandlerResult {
    return {
      handled: true,
      userMessage: '未成年人模式已经开启',
      shouldRetry: false,
      logLevel: 'info'
    };
  }

  private handleMinorsModeAlreadyOff(message: string): ErrorHandlerResult {
    return {
      handled: true,
      userMessage: '未成年人模式已经关闭',
      shouldRetry: false,
      logLevel: 'info'
    };
  }

  private handleUnsupportedAccount(message: string): ErrorHandlerResult {
    return {
      handled: true,
      userMessage: '当前账号不支持此功能，请登录中国境内华为账号',
      shouldRetry: false,
      logLevel: 'warn'
    };
  }

  private handleServiceNotAvailable(message: string): ErrorHandlerResult {
    return {
      handled: true,
      userMessage: '服务不可用，可能处于隐私空间，请退出后重试',
      shouldRetry: false,
      logLevel: 'warn'
    };
  }

  private handleUnknownError(code: number, message: string): ErrorHandlerResult {
    hilog.error(DOMAIN, TAG, `Unknown error code: ${code}`);
    
    return {
      handled: false,
      userMessage: `未知错误(${code}): ${message}`,
      shouldRetry: false,
      logLevel: 'error'
    };
  }

  private incrementErrorCount(errorCode: number) {
    const count = this.errorCount.get(errorCode) || 0;
    this.errorCount.set(errorCode, count + 1);
  }

  private getErrorCount(errorCode: number): number {
    return this.errorCount.get(errorCode) || 0;
  }

  clearErrorCount() {
    this.errorCount.clear();
    hilog.info(DOMAIN, TAG, 'Error count cleared');
  }

  getErrorStatistics(): Map<number, number> {
    return new Map(this.errorCount);
  }
}

export function createErrorHandler(): MinorsProtectionErrorHandler {
  return new MinorsProtectionErrorHandler();
}