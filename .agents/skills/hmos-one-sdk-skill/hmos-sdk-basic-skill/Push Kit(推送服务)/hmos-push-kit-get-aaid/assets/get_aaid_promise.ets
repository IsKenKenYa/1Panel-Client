/**
 * 获取AAID示例代码（Promise方式）
 * 本示例演示如何使用Promise方式获取和删除AAID
 */

import { AAID } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AAID_Example';

/**
 * 获取AAID（Promise方式）
 * @returns Promise<string> AAID字符串，长度为36位
 * @throws BusinessError 如果获取失败
 */
async function getAAID(): Promise<string> {
  try {
    hilog.info(DOMAIN, TAG, 'Starting to get AAID');
    
    const aaid: string = await AAID.getAAID();
    
    hilog.info(DOMAIN, TAG, 'Succeeded in getting AAID: %{public}s', aaid);
    
    // 验证AAID格式
    if (aaid && aaid.length === 36) {
      return aaid;
    } else {
      throw new Error('Invalid AAID format');
    }
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to get AAID: %{public}d %{public}s', e.code, e.message);
    throw e;
  }
}

/**
 * 删除AAID（Promise方式）
 * @returns Promise<void>
 * @throws BusinessError 如果删除失败
 */
async function deleteAAID(): Promise<void> {
  try {
    hilog.info(DOMAIN, TAG, 'Starting to delete AAID');
    
    await AAID.deleteAAID();
    
    hilog.info(DOMAIN, TAG, 'Succeeded in deleting AAID');
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Failed to delete AAID: %{public}d %{public}s', e.code, e.message);
    throw e;
  }
}

/**
 * 带重试机制的获取AAID
 * @param maxRetries 最大重试次数，默认3次
 * @param retryDelay 重试延迟（毫秒），默认1000ms
 * @returns Promise<string> AAID字符串
 */
async function getAAIDWithRetry(maxRetries: number = 3, retryDelay: number = 1000): Promise<string> {
  let lastError: BusinessError | null = null;
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      const aaid = await AAID.getAAID();
      hilog.info(DOMAIN, TAG, 'Succeeded in getting AAID on attempt %{public}d', i + 1);
      return aaid;
    } catch (err) {
      lastError = err as BusinessError;
      hilog.warn(DOMAIN, TAG, 'Retry %{public}d/%{public}d failed: %{public}s', 
                 i + 1, maxRetries, lastError.message);
      
      // 如果是参数错误，不需要重试
      if (lastError.code === 401) {
        hilog.error(DOMAIN, TAG, 'Parameter error, aborting retry');
        throw lastError;
      }
      
      // 等待后重试
      if (i < maxRetries - 1) {
        await new Promise<void>(resolve => setTimeout(resolve, retryDelay));
      }
    }
  }
  
  // 所有重试失败
  hilog.error(DOMAIN, TAG, 'All %{public}d retries failed', maxRetries);
  throw lastError!;
}

/**
 * 错误处理封装
 * @param error BusinessError对象
 */
function handleAAIDError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error: %{public}s', error.message);
      // 检查参数类型和必填项
      break;
    case 1000900001:
      hilog.error(DOMAIN, TAG, 'System internal error: %{public}s', error.message);
      // 建议重试
      break;
    case 1000900006:
      hilog.error(DOMAIN, TAG, 'Failed to connect to AAID service: %{public}s', error.message);
      // 检查PushService状态，稍后重试
      break;
    case 1000900007:
      hilog.error(DOMAIN, TAG, 'Internal error of AAID service: %{public}s', error.message);
      // 服务内部错误，建议稍后重试
      break;
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d %{public}s', error.code, error.message);
      // 处理其他错误
      break;
  }
}

// 主函数示例
async function main(): Promise<void> {
  try {
    // 示例1：获取AAID
    hilog.info(DOMAIN, TAG, '=== Example 1: Get AAID ===');
    const aaid = await getAAID();
    hilog.info(DOMAIN, TAG, 'AAID: %{public}s, length: %{public}d', aaid, aaid.length);
    
    // 示例2：删除AAID
    hilog.info(DOMAIN, TAG, '=== Example 2: Delete AAID ===');
    await deleteAAID();
    
    // 示例3：删除后重新获取
    hilog.info(DOMAIN, TAG, '=== Example 3: Get AAID after deletion ===');
    const newAaid = await getAAID();
    hilog.info(DOMAIN, TAG, 'New AAID: %{public}s', newAaid);
    
    // 验证AAID已改变
    if (aaid !== newAaid) {
      hilog.info(DOMAIN, TAG, 'AAID changed after deletion (expected behavior)');
    }
    
    // 示例4：带重试机制的获取
    hilog.info(DOMAIN, TAG, '=== Example 4: Get AAID with retry ===');
    const aaidWithRetry = await getAAIDWithRetry(3, 1000);
    hilog.info(DOMAIN, TAG, 'AAID with retry: %{public}s', aaidWithRetry);
    
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    handleAAIDError(e);
  }
}

// 导出函数供外部使用
export { getAAID, deleteAAID, getAAIDWithRetry, handleAAIDError };

// 执行主函数
main();