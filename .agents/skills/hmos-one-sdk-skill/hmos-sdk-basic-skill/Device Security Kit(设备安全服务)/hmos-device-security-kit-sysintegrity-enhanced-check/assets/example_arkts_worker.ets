/**
 * 系统完整性增强检测 - Worker示例
 * 该示例展示如何在HarmonyOS中使用Worker在后台线程执行系统完整性增强检测
 */

import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';
import worker from '@ohos.worker';

const TAG = "SysIntegrityEnhancedCheck_Worker";
const DOMAIN = 0x0000;

/**
 * Worker脚本 - 在后台线程执行完整性检测
 * 
 * 在Worker线程中执行的代码示例：
 * worker_script.js 内容如下：
 */

const workerScript = `
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';

const TAG = "Worker_IntegrityCheck";

async function checkIntegrity(nonce) {
  try {
    const request = {
      nonce: nonce
    };
    
    const response = await safetyDetect.checkSysIntegrityEnhanced(request);
    
    return {
      success: true,
      result: response.result
    };
    
  } catch (err) {
    const error = err;
    return {
      success: false,
      errorCode: error.code,
      errorMessage: error.message
    };
  }
}

WorkerPort.onmessage = async function(e) {
  const data = e.data;
  
  if (data.action === 'checkIntegrity') {
    const result = await checkIntegrity(data.nonce);
    WorkerPort.postMessage(result);
  }
};
`;

/**
 * 创建并管理Worker执行完整性检测
 */
export class IntegrityCheckWorkerManager {
  private workerInstance: worker.ThreadWorker | null = null;
  private TAG = "IntegrityCheckWorkerManager";
  private DOMAIN = 0x0000;
  
  /**
   * 初始化Worker
   * 注意：Worker脚本文件需要单独创建并放置在workers目录下
   */
  async initWorker(): Promise<void> {
    try {
      hilog.info(this.DOMAIN, this.TAG, 'Initializing Worker');
      
      this.workerInstance = new worker.ThreadWorker('workers/integrity_check_worker.js');
      
      this.workerInstance.onmessage = (e: worker.MessageEvents) => {
        this.handleWorkerMessage(e.data);
      };
      
      this.workerInstance.onerror = (err: ErrorEvent) => {
        hilog.error(this.DOMAIN, this.TAG, 
          'Worker error: %{public}s', err.message);
        this.handleWorkerError(err);
      };
      
      hilog.info(this.DOMAIN, this.TAG, 'Worker initialized');
      
    } catch (err) {
      hilog.error(this.DOMAIN, this.TAG, 
        'Failed to init worker: %{public}s', err.message);
      throw err;
    }
  }
  
  /**
   * 执行完整性检测
   * 
   * @param nonce nonce值
   * @returns Promise，返回检测结果
   */
  async executeCheck(nonce: string): Promise<string> {
    if (!this.workerInstance) {
      await this.initWorker();
    }
    
    return new Promise((resolve, reject) => {
      hilog.info(this.DOMAIN, this.TAG, 'Sending check request to Worker');
      
      const messageHandler = (e: worker.MessageEvents) => {
        const result = e.data;
        
        if (result.success) {
          hilog.info(this.DOMAIN, this.TAG, 'Worker check succeeded');
          resolve(result.result);
        } else {
          hilog.error(this.DOMAIN, this.TAG, 
            'Worker check failed: %{public}d', result.errorCode);
          reject(new Error(result.errorMessage));
        }
        
        this.workerInstance!.offmessage(messageHandler);
      };
      
      this.workerInstance!.onmessage = messageHandler;
      
      this.workerInstance!.postMessage({
        action: 'checkIntegrity',
        nonce: nonce
      });
    });
  }
  
  /**
   * 处理Worker返回的消息
   * 
   * @param data Worker返回的数据
   */
  private handleWorkerMessage(data: any): void {
    hilog.info(this.DOMAIN, this.TAG, 
      'Received message from Worker: %{public}s', JSON.stringify(data));
  }
  
  /**
   * 处理Worker错误
   * 
   * @param err ErrorEvent
   */
  private handleWorkerError(err: ErrorEvent): void {
    hilog.error(this.DOMAIN, this.TAG, 
      'Worker error: %{public}s', err.message);
    
    this.terminateWorker();
  }
  
  /**
   * 终止Worker
   */
  terminateWorker(): void {
    if (this.workerInstance) {
      hilog.info(this.DOMAIN, this.TAG, 'Terminating Worker');
      this.workerInstance.terminate();
      this.workerInstance = null;
    }
  }
}

/**
 * 使用Worker执行完整性检测的完整流程
 */
export async function executeIntegrityCheckWithWorker(): Promise<void> {
  const workerManager = new IntegrityCheckWorkerManager();
  
  try {
    hilog.info(DOMAIN, TAG, '=== Starting Worker-based integrity check ===');
    
    const nonce = await getNonceFromServer();
    hilog.info(DOMAIN, TAG, 'Nonce obtained');
    
    const jwsResult = await workerManager.executeCheck(nonce);
    hilog.info(DOMAIN, TAG, 'JWS result obtained from Worker');
    
    await sendResultToServerForVerification(jwsResult, nonce);
    
    hilog.info(DOMAIN, TAG, '=== Integrity check completed ===');
    
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Worker-based check failed: %{public}s', err.message);
    handleIntegrityCheckError(err as BusinessError);
    
  } finally {
    workerManager.terminateWorker();
  }
}

/**
 * 从服务器获取nonce
 */
async function getNonceFromServer(): Promise<string> {
  hilog.info(DOMAIN, TAG, 'Fetching nonce from server');
  
  const nonce = 'imEe1PCRcjGkBCAhOCh6ImADztOZ8ygxlWRs';
  
  if (!nonce || nonce.length < 16 || nonce.length > 66) {
    throw new Error('Invalid nonce');
  }
  
  return nonce;
}

/**
 * 发送结果到服务器验证
 */
async function sendResultToServerForVerification(
  jwsResult: string, 
  nonce: string
): Promise<void> {
  hilog.info(DOMAIN, TAG, 'Sending result to server');
}

/**
 * 错误处理
 */
function handleIntegrityCheckError(error: BusinessError): void {
  switch (error.code) {
    case 801:
      showToast('设备不支持此功能');
      break;
    case 1010800002:
      showToast('请检查网络连接');
      break;
    default:
      showToast('检测失败，请稍后重试');
      break;
  }
}

/**
 * Toast提示
 */
function showToast(message: string): void {
  hilog.info(DOMAIN, TAG, 'Toast: %{public}s', message);
}

/**
 * Worker脚本文件示例（workers/integrity_check_worker.js）
 * 
 * 创建workers目录并放置以下内容：
 * 
 * ```javascript
 * import { safetyDetect } from '@kit.DeviceSecurityKit';
 * import { BusinessError } from '@ohos.base';
 * import worker from '@ohos.worker';
 * 
 * const workerPort = worker.workerPort;
 * 
 * async function checkSysIntegrityEnhanced(nonce) {
 *   try {
 *     const request = {
 *       nonce: nonce
 *     };
 *     
 *     const response = await safetyDetect.checkSysIntegrityEnhanced(request);
 *     
 *     workerPort.postMessage({
 *       success: true,
 *       result: response.result
 *     });
 *     
 *   } catch (err) {
 *     const error = err;
 *     workerPort.postMessage({
 *       success: false,
 *       errorCode: error.code,
 *       errorMessage: error.message
 *     });
 *   }
 * }
 * 
 * workerPort.onmessage = function(e) {
 *   const data = e.data;
 *   
 *   if (data.action === 'checkIntegrity') {
 *     checkSysIntegrityEnhanced(data.nonce);
 *   }
 * };
 * ```
 */

/**
 * 在组件中使用Worker的示例
 * 
 * ```typescript
 * import { executeIntegrityCheckWithWorker } from './example_arkts_worker.ets';
 * 
 * @Entry
 * @Component
 * struct SecurityPage {
 *   @State message: string = '准备检测';
 *   
 *   async onAppear() {
 *     try {
 *       await executeIntegrityCheckWithWorker();
 *       this.message = '检测完成';
 *     } catch (err) {
 *       this.message = '检测失败';
 *     }
 *   }
 *   
 *   build() {
 *     Column() {
 *       Text(this.message)
 *     }
 *   }
 * }
 * ```
 */