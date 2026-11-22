import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SysIntegrityCheckExample';
const DOMAIN = 0x0000;

interface IntegrityCheckResult {
  success: boolean;
  result?: string;
  errorCode?: number;
  errorMessage?: string;
}

export class SysIntegrityChecker {
  private static instance: SysIntegrityChecker;
  
  private constructor() {}
  
  static getInstance(): SysIntegrityChecker {
    if (!SysIntegrityChecker.instance) {
      SysIntegrityChecker.instance = new SysIntegrityChecker();
    }
    return SysIntegrityChecker.instance;
  }
  
  validateNonce(nonce: string): boolean {
    if (!nonce) {
      hilog.error(DOMAIN, TAG, 'Nonce is null or empty');
      return false;
    }
    
    if (nonce.length < 16 || nonce.length > 66) {
      hilog.error(DOMAIN, TAG, 
        'Invalid nonce length: %{public}d. Must be 16-66 bytes.', nonce.length);
      return false;
    }
    
    const base64Regex = /^[A-Za-z0-9+/=]+$/;
    if (!base64Regex.test(nonce)) {
      hilog.error(DOMAIN, TAG, 'Invalid nonce format. Must be base64 encoded.');
      return false;
    }
    
    return true;
  }
  
  getErrorMessage(errorCode: number): string {
    const errorMessages: Record<number, string> = {
      201: 'Permission denied. 请检查是否已开通安全检测服务。',
      401: 'Invalid parameters. 请检查nonce参数是否正确。',
      801: 'API is not supported. 当前设备不支持此API。',
      1010800001: 'Internal error. 内部错误，请稍后重试。',
      1010800002: 'The network is unreachable. 网络不可达，请检查网络连接。',
      1010800003: 'Access cloud server fail. 访问云服务失败，请稍后重试。',
      1010800005: 'The number of calls exceeds the parallel threshold. 并发调用超限。',
      1010800006: 'The invoking frequency exceeds the threshold. 调用频率超限。',
      1010800007: 'Operation timeout. 操作超时，请检查网络状况。',
      1010800008: 'The cloud service traffic exceeds the threshold. 云服务流量超限。'
    };
    
    return errorMessages[errorCode] || `Unknown error: ${errorCode}`;
  }
  
  async checkSystemIntegrity(nonce: string): Promise<IntegrityCheckResult> {
    if (!this.validateNonce(nonce)) {
      return {
        success: false,
        errorCode: 401,
        errorMessage: 'Invalid nonce. Must be 16-66 bytes and base64 encoded.'
      };
    }
    
    const req: safetyDetect.SysIntegrityRequest = { nonce };
    
    try {
      hilog.info(DOMAIN, TAG, 'Starting system integrity check...');
      const response: safetyDetect.SysIntegrityResponse = 
        await safetyDetect.checkSysIntegrity(req);
      
      hilog.info(DOMAIN, TAG, 'System integrity check succeeded.');
      return {
        success: true,
        result: response.result
      };
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 
        'System integrity check failed: %{public}d %{public}s', 
        e.code, e.message);
      
      return {
        success: false,
        errorCode: e.code,
        errorMessage: this.getErrorMessage(e.code)
      };
    }
  }
  
  async checkWithRetry(
    nonce: string, 
    maxRetries: number = 3, 
    retryDelay: number = 1000
  ): Promise<IntegrityCheckResult> {
    let lastResult: IntegrityCheckResult = {
      success: false,
      errorCode: -1,
      errorMessage: 'No attempt made'
    };
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      hilog.info(DOMAIN, TAG, 'Attempt %{public}d of %{public}d', attempt, maxRetries);
      
      lastResult = await this.checkSystemIntegrity(nonce);
      
      if (lastResult.success) {
        return lastResult;
      }
      
      if (lastResult.errorCode === 1010800005 || 
          lastResult.errorCode === 1010800006) {
        const delay = retryDelay * Math.pow(2, attempt - 1);
        hilog.info(DOMAIN, TAG, 
          'Rate limited. Waiting %{public}d ms before retry.', delay);
        await this.delay(delay);
      } else if (lastResult.errorCode !== 1010800002 && 
                 lastResult.errorCode !== 1010800003) {
        break;
      }
    }
    
    return lastResult;
  }
  
  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }
}

async function main(): Promise<void> {
  const checker = SysIntegrityChecker.getInstance();
  const nonce = 'imEe1PCRcjGkBCAhOCh6ImADztOZ8ygxlWRs';
  
  const result = await checker.checkWithRetry(nonce);
  
  if (result.success && result.result) {
    console.log('JWS Result:', result.result);
    console.log('Send this result to your server for verification.');
  } else {
    console.error('Check failed:', result.errorMessage);
  }
}

export { IntegrityCheckResult, SysIntegrityChecker };