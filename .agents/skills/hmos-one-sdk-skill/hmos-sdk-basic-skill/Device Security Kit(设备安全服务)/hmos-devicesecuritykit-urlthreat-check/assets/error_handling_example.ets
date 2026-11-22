import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "UrlThreatErrorHandler";
const DOMAIN = 0x0000;

export enum ErrorAction {
  RETRY,
  WAIT_AND_RETRY,
  ABORT,
  FALLBACK,
  NOTIFY_USER
}

export class UrlThreatErrorHandler {
  private retryCount: number = 0;
  private maxRetries: number = 3;
  
  async handleError(err: BusinessError, urls: string[]): Promise<ErrorAction> {
    hilog.error(DOMAIN, TAG, 'URL检测错误: %{public}d %{public}s', err.code, err.message);
    
    switch (err.code) {
      case 201:
        return this.handlePermissionDenied();
        
      case 401:
        return this.handleInvalidParameters(err.message);
        
      case 801:
        return this.handleApiNotSupported();
        
      case 1010800001:
        return this.handleInternalError(urls);
        
      case 1010800002:
        return this.handleNetworkUnreachable();
        
      case 1010800003:
        return this.handleCloudServerFail(urls);
        
      case 1010800005:
        return this.handleConcurrencyExceeded(urls);
        
      case 1010800006:
        return this.handleFrequencyExceeded();
        
      case 1010800007:
        return this.handleTimeout(urls);
        
      case 1010800008:
        return this.handleTrafficExceeded(urls);
        
      default:
        return this.handleUnknownError(err);
    }
  }
  
  private handlePermissionDenied(): ErrorAction {
    hilog.error(DOMAIN, TAG, '权限校验失败：未开通安全检测服务');
    console.log('请在AppGallery Connect开通"安全检测服务"并重新申请Profile');
    return ErrorAction.ABORT;
  }
  
  private handleInvalidParameters(message: string): ErrorAction {
    hilog.error(DOMAIN, TAG, '参数错误: %{public}s', message);
    console.log('请检查URL格式和数量限制');
    return ErrorAction.ABORT;
  }
  
  private handleApiNotSupported(): ErrorAction {
    hilog.error(DOMAIN, TAG, 'API不支持：设备版本过低');
    console.log('请升级系统到5.0.0(12)或更高版本');
    return ErrorAction.ABORT;
  }
  
  private handleInternalError(urls: string[]): ErrorAction {
    hilog.error(DOMAIN, TAG, '内部错误');
    this.retryCount++;
    
    if (this.retryCount <= this.maxRetries) {
      console.log(`正在重试 (${this.retryCount}/${this.maxRetries})...`);
      return ErrorAction.RETRY;
    }
    
    console.log('重试失败，请通过在线提单申请帮助');
    return ErrorAction.ABORT;
  }
  
  private handleNetworkUnreachable(): ErrorAction {
    hilog.error(DOMAIN, TAG, '设备网络异常');
    console.log('请检查网络连接');
    return ErrorAction.NOTIFY_USER;
  }
  
  private handleCloudServerFail(urls: string[]): ErrorAction {
    hilog.error(DOMAIN, TAG, '访问云端服务器失败');
    this.retryCount++;
    
    if (this.retryCount <= this.maxRetries) {
      console.log(`延迟3秒后重试 (${this.retryCount}/${this.maxRetries})...`);
      return ErrorAction.WAIT_AND_RETRY;
    }
    
    console.log('云服务不可用，使用降级方案');
    return ErrorAction.FALLBACK;
  }
  
  private handleConcurrencyExceeded(urls: string[]): ErrorAction {
    hilog.error(DOMAIN, TAG, '并发调用超限');
    console.log('延迟1秒后重试...');
    return ErrorAction.WAIT_AND_RETRY;
  }
  
  private handleFrequencyExceeded(): ErrorAction {
    hilog.error(DOMAIN, TAG, '调用频率超限');
    console.log('每天最多调用1万次，请明天再试');
    return ErrorAction.ABORT;
  }
  
  private handleTimeout(urls: string[]): ErrorAction {
    hilog.error(DOMAIN, TAG, '操作超时');
    this.retryCount++;
    
    if (this.retryCount <= this.maxRetries) {
      console.log(`延迟2秒后重试 (${this.retryCount}/${this.maxRetries})...`);
      return ErrorAction.WAIT_AND_RETRY;
    }
    
    console.log('操作持续超时，使用降级方案');
    return ErrorAction.FALLBACK;
  }
  
  private handleTrafficExceeded(urls: string[]): ErrorAction {
    hilog.error(DOMAIN, TAG, '云服务流量超限');
    this.retryCount++;
    
    if (this.retryCount <= this.maxRetries) {
      const delay = Math.pow(5, this.retryCount);
      console.log(`延迟${delay}秒后重试 (${this.retryCount}/${this.maxRetries})...`);
      return ErrorAction.WAIT_AND_RETRY;
    }
    
    console.log('云服务流量持续超限，使用降级方案');
    return ErrorAction.FALLBACK;
  }
  
  private handleUnknownError(err: BusinessError): ErrorAction {
    hilog.error(DOMAIN, TAG, '未知错误: %{public}d %{public}s', err.code, err.message);
    console.log(`错误码: ${err.code}`);
    console.log(`错误信息: ${err.message}`);
    return ErrorAction.ABORT;
  }
  
  resetRetryCount(): void {
    this.retryCount = 0;
  }
}

export async function checkUrlsWithErrorHandling(
  urls: string[],
  retryDelay: number = 3000
): Promise<safetyDetect.UrlCheckResponse | null> {
  const errorHandler = new UrlThreatErrorHandler();
  const req: safetyDetect.UrlCheckRequest = { urls };
  
  while (true) {
    try {
      const response = await safetyDetect.checkUrlThreat(req);
      errorHandler.resetRetryCount();
      return response;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      const action = await errorHandler.handleError(e, urls);
      
      switch (action) {
        case ErrorAction.RETRY:
          await sleep(1000);
          continue;
          
        case ErrorAction.WAIT_AND_RETRY:
          await sleep(retryDelay);
          continue;
          
        case ErrorAction.ABORT:
          return null;
          
        case ErrorAction.FALLBACK:
          console.log('使用本地黑名单进行降级检测');
          return null;
          
        case ErrorAction.NOTIFY_USER:
          console.log('请检查网络连接后重试');
          return null;
      }
    }
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}