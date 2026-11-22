/**
 * 错误处理示例
 * 功能:演示如何处理Account Kit授权过程中可能出现的各种错误
 */

import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ErrorHandler';
const DOMAIN = 0x0000;

/**
 * 错误码定义
 */
export enum AuthorizationErrorCode {
  // 账号相关错误
  ACCOUNT_NOT_LOGGED_IN = 1001502001,
  APP_NOT_AUTHORIZED = 1001502002,
  
  // 网络和系统错误
  NETWORK_ERROR = 1001502005,
  INTERNAL_ERROR = 1001502009,
  SYSTEM_SERVICE_ERROR = 12300001,
  
  // 用户行为错误
  USER_CANCELLED = 1001502012,
  
  // 应用配置错误
  FINGERPRINT_CHECK_FAILED = 1001500001,
  DUPLICATE_REQUEST = 1001500002,
  SCOPE_UNSUPPORTED = 1001500003,
  ACCOUNT_UNSUPPORTED = 1001500004,
  REQUEST_RESTRICTED = 1001500005,
  
  // 参数错误
  PARAMETER_INVALID = 1001502003,
  SCOPE_OR_PERMISSION_NOT_REQUESTED = 1001502014,
  PARAM_CHECK_FAILED = 401
}

/**
 * 错误类型分类
 */
enum ErrorCategory {
  USER_ACTION,      // 用户行为(取消授权、未登录)
  NETWORK,          // 网络问题
  SYSTEM,           // 系统服务问题
  APP_CONFIG,       // 应用配置问题
  PARAM,            // 参数错误
  UNKNOWN           // 未知错误
}

/**
 * 错误处理策略
 */
interface ErrorHandlingStrategy {
  category: ErrorCategory;
  userMessage: string;
  action: string;
  shouldRetry: boolean;
  retryDelay?: number; // 重试延迟(毫秒)
}

/**
 * 错误处理器类
 */
class AuthorizationErrorHandler {
  private errorCount: Map<number, number> = new Map();
  private maxRetryCount: number = 3;
  
  /**
   * 处理授权错误
   * @param error BusinessError对象
   * @returns ErrorHandlingStrategy 错误处理策略
   */
  handleError(error: BusinessError): ErrorHandlingStrategy {
    hilog.error(DOMAIN, TAG, 'Authorization error occurred - Code: %d, Message: %s', 
      error.code, error.message);
    
    // 记录错误次数
    const count = this.errorCount.get(error.code) || 0;
    this.errorCount.set(error.code, count + 1);
    
    // 根据错误码确定处理策略
    const strategy = this.getStrategy(error.code);
    
    // 记录处理策略
    hilog.info(DOMAIN, TAG, 'Error handling strategy: Category=%d, Action=%s, Retry=%s', 
      strategy.category, strategy.action, strategy.shouldRetry);
    
    return strategy;
  }
  
  /**
   * 根据错误码获取处理策略
   * @param errorCode 错误码
   * @returns ErrorHandlingStrategy
   */
  private getStrategy(errorCode: number): ErrorHandlingStrategy {
    switch (errorCode) {
      // 用户行为错误
      case AuthorizationErrorCode.ACCOUNT_NOT_LOGGED_IN:
        return {
          category: ErrorCategory.USER_ACTION,
          userMessage: '请登录华为账号并重试',
          action: '提示用户登录账号',
          shouldRetry: true,
          retryDelay: 1000
        };
        
      case AuthorizationErrorCode.USER_CANCELLED:
        return {
          category: ErrorCategory.USER_ACTION,
          userMessage: '用户取消授权',
          action: '记录取消状态,不强制再次请求',
          shouldRetry: false
        };
        
      // 网络错误
      case AuthorizationErrorCode.NETWORK_ERROR:
        return {
          category: ErrorCategory.NETWORK,
          userMessage: '网络异常,请检查当前网络状态并重试',
          action: '检查网络连接,建议延迟重试',
          shouldRetry: true,
          retryDelay: 2000
        };
        
      // 系统服务错误
      case AuthorizationErrorCode.SYSTEM_SERVICE_ERROR:
        return {
          category: ErrorCategory.SYSTEM,
          userMessage: '系统服务异常,请稍后重试',
          action: '等待系统服务恢复,建议延迟重试',
          shouldRetry: true,
          retryDelay: 3000
        };
        
      case AuthorizationErrorCode.INTERNAL_ERROR:
        return {
          category: ErrorCategory.SYSTEM,
          userMessage: '内部错误,请稍后重试',
          action: '等待服务器恢复,建议延迟重试',
          shouldRetry: true,
          retryDelay: 3000
        };
        
      // 应用配置错误
      case AuthorizationErrorCode.FINGERPRINT_CHECK_FAILED:
        return {
          category: ErrorCategory.APP_CONFIG,
          userMessage: '应用配置错误,应用指纹证书校验失败',
          action: '检查签名和指纹配置,参考开发文档',
          shouldRetry: false // 配置问题,重试无效
        };
        
      case AuthorizationErrorCode.DUPLICATE_REQUEST:
        return {
          category: ErrorCategory.APP_CONFIG,
          userMessage: '重复请求',
          action: '应用无需处理,实现点击控制防止连续点击',
          shouldRetry: false
        };
        
      case AuthorizationErrorCode.SCOPE_UNSUPPORTED:
        return {
          category: ErrorCategory.APP_CONFIG,
          userMessage: '不支持该scopes或permissions',
          action: '检查scope参数,元服务需设置supportAtomicService=true',
          shouldRetry: false
        };
        
      case AuthorizationErrorCode.REQUEST_RESTRICTED:
        return {
          category: ErrorCategory.APP_CONFIG,
          userMessage: '该功能被限制调用',
          action: '检查账号权限申请情况',
          shouldRetry: false
        };
        
      // 参数错误
      case AuthorizationErrorCode.PARAMETER_INVALID:
        return {
          category: ErrorCategory.PARAM,
          userMessage: '参数错误',
          action: '检查scopes和permissions参数是否正确',
          shouldRetry: false
        };
        
      case AuthorizationErrorCode.PARAM_CHECK_FAILED:
        return {
          category: ErrorCategory.PARAM,
          userMessage: '参数检查失败',
          action: '检查Context参数是否正确传入',
          shouldRetry: false
        };
        
      case AuthorizationErrorCode.SCOPE_OR_PERMISSION_NOT_REQUESTED:
        return {
          category: ErrorCategory.PARAM,
          userMessage: '应用未申请scopes或permissions权限',
          action: '检查是否已完成开发准备中的权限申请',
          shouldRetry: false
        };
        
      // 未知错误
      default:
        return {
          category: ErrorCategory.UNKNOWN,
          userMessage: '获取用户信息失败,请稍后重试',
          action: '记录错误日志,建议用户稍后重试',
          shouldRetry: true,
          retryDelay: 5000
        };
    }
  }
  
  /**
   * 判断是否应该重试
   * @param errorCode 错误码
   * @returns boolean 是否应该重试
   */
  shouldRetry(errorCode: number): boolean {
    const count = this.errorCount.get(errorCode) || 0;
    const strategy = this.getStrategy(errorCode);
    
    // 达到最大重试次数则不再重试
    if (count >= this.maxRetryCount) {
      hilog.warn(DOMAIN, TAG, 'Max retry count reached for error %d', errorCode);
      return false;
    }
    
    return strategy.shouldRetry;
  }
  
  /**
   * 获取重试延迟时间
   * @param errorCode 错误码
   * @returns number 重试延迟(毫秒)
   */
  getRetryDelay(errorCode: number): number {
    const strategy = this.getStrategy(errorCode);
    return strategy.retryDelay || 1000;
  }
  
  /**
   * 清除错误计数
   */
  clearErrorCount(): void {
    this.errorCount.clear();
    hilog.info(DOMAIN, TAG, 'Error count cleared');
  }
  
  /**
   * 获取错误统计
   * @returns Map<number, number> 错误码和次数的映射
   */
  getErrorStatistics(): Map<number, number> {
    return this.errorCount;
  }
}

/**
 * 带重试机制的授权请求
 * @param authRequest 授权请求对象
 * @param maxRetries 最大重试次数
 * @returns Promise<authentication.AuthorizationWithHuaweiIDResponse>
 */
async function executeAuthorizationWithRetry(
  authRequest: authentication.AuthorizationWithHuaweiIDRequest,
  maxRetries: number = 3
): Promise<authentication.AuthorizationWithHuaweiIDResponse> {
  
  const errorHandler = new AuthorizationErrorHandler();
  const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
  
  let retryCount = 0;
  
  while (retryCount <= maxRetries) {
    try {
      hilog.info(DOMAIN, TAG, 'Executing authorization request, attempt %d', retryCount + 1);
      
      const data = await controller.executeRequest(authRequest);
      const response = data as authentication.AuthorizationWithHuaweiIDResponse;
      
      // 验证state
      if (response.state && authRequest.state !== response.state) {
        throw new Error('State verification failed');
      }
      
      // 成功,清除错误计数
      errorHandler.clearErrorCount();
      hilog.info(DOMAIN, TAG, 'Authorization succeeded after %d attempts', retryCount + 1);
      
      return response;
      
    } catch (error) {
      const err = error as BusinessError;
      const strategy = errorHandler.handleError(err);
      
      // 显示用户提示
      hilog.warn(DOMAIN, TAG, 'User message: %s', strategy.userMessage);
      
      // 判断是否应该重试
      if (!errorHandler.shouldRetry(err.code)) {
        hilog.error(DOMAIN, TAG, 'Error cannot be retried, stopping');
        throw error;
      }
      
      // 获取重试延迟
      const delay = errorHandler.getRetryDelay(err.code);
      hilog.info(DOMAIN, TAG, 'Will retry after %d ms', delay);
      
      // 延迟重试
      await new Promise(resolve => setTimeout(resolve, delay));
      
      retryCount++;
    }
  }
  
  // 达到最大重试次数仍然失败
  throw new Error('Authorization failed after maximum retries');
}

/**
 * 使用示例
 */
@Entry
@Component
struct ErrorHandlingExample {
  @State errorMessage: string = '';
  @State retryCount: number = 0;
  
  private errorHandler: AuthorizationErrorHandler = new AuthorizationErrorHandler();
  
  build() {
    Column() {
      Text('错误处理示例')
        .fontSize(24)
        .margin({ bottom: 20 })
      
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
          .margin({ bottom: 20 })
      }
      
      if (this.retryCount > 0) {
        Text('重试次数: ' + this.retryCount)
          .fontSize(14)
          .margin({ bottom: 10 })
      }
      
      Button('测试错误处理')
        .onClick(async () => {
          try {
            const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
            authRequest.scopes = ['profile'];
            authRequest.permissions = ['serviceauthcode'];
            authRequest.forceAuthorization = true;
            authRequest.state = util.generateRandomUUID();
            
            // 使用带重试的授权请求
            const response = await executeAuthorizationWithRetry(authRequest);
            
            this.errorMessage = '授权成功';
            this.retryCount = 0;
            
          } catch (error) {
            const err = error as BusinessError;
            const strategy = this.errorHandler.handleError(err);
            
            this.errorMessage = strategy.userMessage;
            this.retryCount = this.errorHandler.getErrorStatistics().get(err.code) || 0;
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 错误处理最佳实践:
 * 1. 根据错误码分类处理,提供用户友好的提示
 * 2. 实现智能重试机制,避免无限重试
 * 3. 记录错误统计,分析错误趋势
 * 4. 对于配置错误(如指纹校验失败),不重试而是引导用户检查配置
 * 5. 对于用户取消授权,不强制再次请求
 * 6. 对于网络错误和系统错误,提供延迟重试机制
 * 7. 实现点击控制,防止连续点击导致的重复请求
 */