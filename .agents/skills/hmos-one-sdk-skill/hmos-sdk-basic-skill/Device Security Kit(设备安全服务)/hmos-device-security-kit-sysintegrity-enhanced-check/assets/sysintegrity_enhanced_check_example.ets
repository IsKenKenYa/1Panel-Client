import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "SysIntegrityEnhanced";
const DOMAIN = 0x0000;

export class SysIntegrityEnhancedChecker {
  private nonceGenerator: NonceGenerator;
  
  constructor() {
    this.nonceGenerator = new NonceGenerator();
  }
  
  async performEnhancedCheck(): Promise<IntegrityCheckResult> {
    try {
      const nonce = this.nonceGenerator.generateNonce();
      hilog.info(DOMAIN, TAG, `Generated nonce: ${nonce}`);
      
      const req: safetyDetect.SysIntegrityRequest = {
        nonce: nonce
      };
      
      hilog.info(DOMAIN, TAG, 'Starting enhanced system integrity check...');
      const response: safetyDetect.SysIntegrityResponse = await safetyDetect.checkSysIntegrityEnhanced(req);
      
      hilog.info(DOMAIN, TAG, `Enhanced check succeeded. JWS result length: ${response.result.length}`);
      
      return {
        success: true,
        jws: response.result,
        nonce: nonce
      };
    } catch (error) {
      const e: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Enhanced check failed. Code: ${e.code}, Message: ${e.message}`);
      
      return {
        success: false,
        errorCode: e.code,
        errorMessage: e.message
      };
    }
  }
  
  handleError(errorCode: number): string {
    const errorMessages: Record<number, string> = {
      201: '权限被拒绝，请检查权限配置',
      401: '参数无效，请检查nonce长度和编码',
      801: 'API不支持，请检查API版本≥6.0.0(20)',
      1010800001: '内部错误，请稍后重试',
      1010800002: '网络不可达，请检查网络连接',
      1010800003: '访问云服务器失败，请稍后重试',
      1010800004: '验证能力失败，请检查设备能力',
      1010800005: '超过并发阈值，请降低并发数',
      1010800006: '超过调用频率阈值，请降低调用频率',
      1010800007: '操作超时，请稍后重试',
      1010800008: '云服务流量超限，请等待或联系客服'
    };
    
    return errorMessages[errorCode] || '未知错误';
  }
}

class NonceGenerator {
  generateNonce(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const length = Math.floor(Math.random() * 50) + 16;
    let nonce = '';
    
    for (let i = 0; i < length; i++) {
      nonce += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    
    return nonce;
  }
}

export interface IntegrityCheckResult {
  success: boolean;
  jws?: string;
  nonce?: string;
  errorCode?: number;
  errorMessage?: string;
}

export async function checkSysIntegrityEnhancedWithRetry(maxRetries: number = 3): Promise<IntegrityCheckResult> {
  const checker = new SysIntegrityEnhancedChecker();
  
  for (let i = 0; i < maxRetries; i++) {
    hilog.info(DOMAIN, TAG, `Attempt ${i + 1} of ${maxRetries}`);
    
    const result = await checker.performEnhancedCheck();
    
    if (result.success) {
      return result;
    }
    
    if (result.errorCode === 1010800005 || result.errorCode === 1010800006) {
      hilog.warn(DOMAIN, TAG, 'Rate limit exceeded, waiting before retry...');
      await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
      continue;
    }
    
    if (result.errorCode === 1010800002 || result.errorCode === 1010800003) {
      hilog.warn(DOMAIN, TAG, 'Network issue, waiting before retry...');
      await new Promise(resolve => setTimeout(resolve, 2000 * (i + 1)));
      continue;
    }
    
    return result;
  }
  
  return {
    success: false,
    errorCode: -1,
    errorMessage: 'Max retries exceeded'
  };
}