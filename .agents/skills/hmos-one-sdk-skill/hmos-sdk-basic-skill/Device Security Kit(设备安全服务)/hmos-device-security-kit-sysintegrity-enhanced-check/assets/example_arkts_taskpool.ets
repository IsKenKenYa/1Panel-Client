/**
 * 系统完整性增强检测 - TaskPool示例
 * 该示例展示如何在HarmonyOS中使用TaskPool在后台线程执行系统完整性增强检测
 */

import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';
import taskpool from '@ohos.taskpool';

const TAG = "SysIntegrityEnhancedCheck_TaskPool";
const DOMAIN = 0x0000;

/**
 * 系统完整性增强检测任务函数
 * 必须使用@Concurrent装饰器标记，以便在TaskPool中执行
 * 
 * @param nonce 从服务器获取的随机nonce值（16-66字节的base64字符串）
 * @returns JWS格式的检测结果字符串
 */
@Concurrent
async function integrityCheckTask(nonce: string): Promise<string> {
  try {
    hilog.info(DOMAIN, TAG, 'Start integrity check in TaskPool');
    
    if (!nonce || nonce.length < 16 || nonce.length > 66) {
      hilog.error(DOMAIN, TAG, 'Invalid nonce: length must be 16-66 bytes');
      throw new Error('Invalid nonce length');
    }
    
    const request: safetyDetect.SysIntegrityRequest = {
      nonce: nonce
    };
    
    const response: safetyDetect.SysIntegrityResponse = 
      await safetyDetect.checkSysIntegrityEnhanced(request);
    
    hilog.info(DOMAIN, TAG, 'Integrity check succeeded');
    
    return response.result;
    
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 
      'Integrity check failed: code=%{public}d, msg=%{public}s', 
      error.code, error.message);
    throw error;
  }
}

/**
 * 从服务器获取nonce值
 * 实际应用中应从应用服务器获取随机生成的nonce
 * 
 * @returns nonce字符串
 */
async function getNonceFromServer(): Promise<string> {
  try {
    hilog.info(DOMAIN, TAG, 'Fetching nonce from server');
    
    const response = await fetch('https://your-server.com/api/get-nonce', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        deviceId: 'device-id-placeholder'
      })
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch nonce from server');
    }
    
    const data = await response.json();
    const nonce = data.nonce;
    
    if (!nonce || nonce.length < 16 || nonce.length > 66) {
      throw new Error('Invalid nonce received from server');
    }
    
    hilog.info(DOMAIN, TAG, 'Nonce fetched successfully');
    return nonce;
    
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Failed to get nonce: %{public}s', err.message);
    throw err;
  }
}

/**
 * 将检测结果发送到服务器验证
 * 
 * @param jwsResult JWS格式的检测结果
 * @param nonce 对应的nonce值
 */
async function sendResultToServerForVerification(
  jwsResult: string, 
  nonce: string
): Promise<void> {
  try {
    hilog.info(DOMAIN, TAG, 'Sending result to server for verification');
    
    const response = await fetch('https://your-server.com/api/verify-integrity', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        jwsResult: jwsResult,
        nonce: nonce,
        timestamp: Date.now()
      })
    });
    
    if (!response.ok) {
      throw new Error('Server verification failed');
    }
    
    const data = await response.json();
    
    if (data.isValid) {
      hilog.info(DOMAIN, TAG, 'Server verification succeeded');
      handleVerificationResult(data);
    } else {
      hilog.error(DOMAIN, TAG, 'Server verification failed: %{public}s', data.error);
      handleVerificationFailure(data);
    }
    
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Failed to send result to server: %{public}s', err.message);
    throw err;
  }
}

/**
 * 处理验证成功的结果
 * 
 * @param verificationResult 服务器验证结果
 */
function handleVerificationResult(verificationResult: any): void {
  const payload = verificationResult.payload;
  
  if (payload.basicIntegrity) {
    hilog.info(DOMAIN, TAG, 'Device integrity check passed');
  } else {
    hilog.warn(DOMAIN, TAG, 'Device integrity check failed');
    
    if (payload.detail && Array.isArray(payload.detail)) {
      for (const risk of payload.detail) {
        hilog.warn(DOMAIN, TAG, 'Risk detected: %{public}s', risk);
      }
    }
  }
}

/**
 * 处理验证失败
 * 
 * @param errorResult 错误信息
 */
function handleVerificationFailure(errorResult: any): void {
  hilog.error(DOMAIN, TAG, 'Verification failed: %{public}s', errorResult.error);
}

/**
 * 主执行函数 - 在TaskPool中执行系统完整性增强检测
 * 
 * 使用示例：
 * ```typescript
 * @Entry
 * @Component
 * struct MainPage {
 *   async onPageShow() {
 *     await executeIntegrityCheck();
 *   }
 *   
 *   build() {
 *     Column() {
 *       Text('Device Security Check')
 *     }
 *   }
 * }
 * ```
 */
export async function executeIntegrityCheck(): Promise<void> {
  try {
    hilog.info(DOMAIN, TAG, '=== Starting integrity check process ===');
    
    const nonce = await getNonceFromServer();
    hilog.info(DOMAIN, TAG, 'Nonce obtained: %{public}s', nonce);
    
    const jwsResult = await taskpool.execute(integrityCheckTask, nonce) as string;
    hilog.info(DOMAIN, TAG, 'JWS result obtained');
    
    await sendResultToServerForVerification(jwsResult, nonce);
    
    hilog.info(DOMAIN, TAG, '=== Integrity check process completed ===');
    
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Integrity check process failed: %{public}s', err.message);
    
    handleIntegrityCheckError(err as BusinessError);
  }
}

/**
 * 错误处理函数
 * 
 * @param error BusinessError对象
 */
function handleIntegrityCheckError(error: BusinessError): void {
  switch (error.code) {
    case 801:
      hilog.error(DOMAIN, TAG, 'API not supported');
      showToast('您的设备不支持此功能');
      break;
      
    case 1010800001:
      hilog.error(DOMAIN, TAG, 'Internal error');
      showToast('检测服务暂时不可用，请稍后重试');
      break;
      
    case 1010800002:
      hilog.error(DOMAIN, TAG, 'Network unreachable');
      showToast('请检查网络连接');
      break;
      
    case 1010800003:
      hilog.error(DOMAIN, TAG, 'Access cloud server failed');
      showToast('服务暂时不可用，请稍后重试');
      break;
      
    case 1010800005:
      hilog.error(DOMAIN, TAG, 'Parallel calls exceed threshold');
      showToast('系统繁忙，请稍后重试');
      break;
      
    case 1010800006:
      hilog.error(DOMAIN, TAG, 'Invoking frequency exceeds threshold');
      showToast('操作过于频繁，请稍后再试');
      break;
      
    case 1010800007:
      hilog.error(DOMAIN, TAG, 'Operation timeout');
      showToast('检测超时，请重试');
      break;
      
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d', error.code);
      showToast('检测失败，请稍后重试');
      break;
  }
}

/**
 * Toast提示函数（示例）
 * 实际应用中应使用系统的Toast组件
 * 
 * @param message 提示消息
 */
function showToast(message: string): void {
  hilog.info(DOMAIN, TAG, 'Toast: %{public}s', message);
}

/**
 * 延迟函数
 * 
 * @param ms 延迟毫秒数
 */
function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * 降级到本地检测
 * 当增强检测不可用时，可降级到本地检测
 */
export async function fallbackToLocalCheck(): Promise<void> {
  try {
    hilog.info(DOMAIN, TAG, 'Fallback to local integrity check');
    
    const result = await safetyDetect.checkSysIntegrityOnLocal();
    
    hilog.info(DOMAIN, TAG, 'Local check result: %{public}s', result);
    
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Local check also failed');
  }
}

/**
 * 带重试机制的完整性检测
 * 
 * @param maxRetries 最大重试次数
 * @param retryDelay 重试延迟（毫秒）
 */
export async function executeIntegrityCheckWithRetry(
  maxRetries: number = 3,
  retryDelay: number = 1000
): Promise<void> {
  let retryCount = 0;
  
  while (retryCount < maxRetries) {
    try {
      await executeIntegrityCheck();
      return;
      
    } catch (err) {
      retryCount++;
      
      if (retryCount < maxRetries) {
        hilog.warn(DOMAIN, TAG, 
          'Retry %{public}d/%{public}d after %{public}dms', 
          retryCount, maxRetries, retryDelay);
        await delay(retryDelay);
      } else {
        hilog.error(DOMAIN, TAG, 'Max retries reached');
        throw err;
      }
    }
  }
}

/**
 * 在组件中使用的示例
 * 
 * 示例代码：
 * ```typescript
 * import { executeIntegrityCheck, executeIntegrityCheckWithRetry } from './example_arkts_taskpool.ets';
 * 
 * @Entry
 * @Component
 * struct SecurityCheckPage {
 *   @State message: string = '准备检测设备安全状态';
 *   @State isChecking: boolean = false;
 *   
 *   async startCheck() {
 *     this.isChecking = true;
 *     this.message = '正在检测...';
 *     
 *     try {
 *       await executeIntegrityCheckWithRetry(3, 1000);
 *       this.message = '检测完成';
 *     } catch (err) {
 *       this.message = '检测失败，请重试';
 *     }
 *     
 *     this.isChecking = false;
 *   }
 *   
 *   build() {
 *     Column() {
 *       Text(this.message)
 *         .fontSize(20)
 *       
 *       Button('开始检测')
 *         .enabled(!this.isChecking)
 *         .onClick(() => {
 *           this.startCheck();
 *         })
 *     }
 *     .width('100%')
 *     .height('100%')
 *   }
 * }
 * ```
 */