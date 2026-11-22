import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "LocalSysIntegrityCheck";
const DOMAIN = 0x0000;

export interface IntegrityResult {
  basicIntegrity: boolean;
  detail?: string[];
}

export class LocalSysIntegrityChecker {
  private static instance: LocalSysIntegrityChecker;
  
  private constructor() {}
  
  static getInstance(): LocalSysIntegrityChecker {
    if (!LocalSysIntegrityChecker.instance) {
      LocalSysIntegrityChecker.instance = new LocalSysIntegrityChecker();
    }
    return LocalSysIntegrityChecker.instance;
  }
  
  async checkIntegrity(): Promise<IntegrityResult> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting local system integrity check...');
      
      const result: string = await safetyDetect.checkSysIntegrityOnLocal();
      
      hilog.info(DOMAIN, TAG, 'Integrity check succeeded: %{public}s', result);
      
      const integrityResult: IntegrityResult = JSON.parse(result);
      
      if (!integrityResult.basicIntegrity) {
        hilog.warn(DOMAIN, TAG, 'Device integrity check failed. Risks: %{public}s',
          JSON.stringify(integrityResult.detail));
        this.handleRisk(integrityResult.detail || []);
      } else {
        hilog.info(DOMAIN, TAG, 'Device integrity check passed.');
      }
      
      return integrityResult;
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Integrity check failed: %{public}d %{public}s',
        e.code, e.message);
      throw this.handleError(e.code, e.message);
    }
  }
  
  async checkIntegrityWithRetry(maxRetries: number = 3): Promise<IntegrityResult> {
    let lastError: Error | null = null;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await this.checkIntegrity();
      } catch (err) {
        lastError = err as Error;
        const e = err as BusinessError;
        
        if (e.code === 801 || e.code === 1010800004) {
          hilog.error(DOMAIN, TAG, 'Non-retriable error: %{public}d', e.code);
          throw err;
        }
        
        if (i < maxRetries - 1) {
          const delay = Math.pow(2, i) * 1000;
          hilog.warn(DOMAIN, TAG, 'Retrying in %{public}d ms (attempt %{public}d/%{public}d)',
            delay, i + 1, maxRetries);
          await this.sleep(delay);
        }
      }
    }
    
    throw lastError;
  }
  
  private handleRisk(risks: string[]): void {
    const riskMessages: { [key: string]: string } = {
      'jailbreak': '设备已被越狱',
      'emulator': '设备为模拟器',
      'attack': '设备被攻击',
      'unlock': '设备被解锁'
    };
    
    const messages = risks.map(risk => riskMessages[risk] || risk).join('、');
    hilog.warn(DOMAIN, TAG, 
      '您的设备疑似存在风险或运行在不安全环境中，请谨慎使用此功能。风险项：%{public}s', 
      messages);
  }
  
  private handleError(code: number, message: string): Error {
    const errorMessages: { [key: number]: string } = {
      801: 'API is not supported on this device',
      1010800001: 'Internal error occurred',
      1010800004: 'Security detection service is not enabled',
      1010800005: 'Too many concurrent calls',
      1010800006: 'Calling frequency exceeds threshold',
      1010800007: 'Operation timeout'
    };
    
    const errorMsg = errorMessages[code] || `Unknown error: ${message}`;
    hilog.error(DOMAIN, TAG, 'Error %{public}d: %{public}s', code, errorMsg);
    
    return new Error(`[${code}] ${errorMsg}`);
  }
  
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export async function checkLocalSystemIntegrity(): Promise<IntegrityResult> {
  const checker = LocalSysIntegrityChecker.getInstance();
  return await checker.checkIntegrity();
}

export async function checkLocalSystemIntegrityWithRetry(maxRetries?: number): Promise<IntegrityResult> {
  const checker = LocalSysIntegrityChecker.getInstance();
  return await checker.checkIntegrityWithRetry(maxRetries);
}