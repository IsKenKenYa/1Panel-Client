/**
 * 获取AAID示例代码（Callback方式）
 * 本示例演示如何使用Callback方式获取和删除AAID
 */

import { AAID } from '@kit.PushKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'AAID_Callback_Example';

/**
 * 获取AAID（Callback方式）
 * @param callback 回调函数，参数为错误对象和AAID字符串
 */
function getAAIDWithCallback(callback: (err: BusinessError | null, aaid?: string) => void): void {
  try {
    hilog.info(DOMAIN, TAG, 'Starting to get AAID with callback');
    
    AAID.getAAID((err: BusinessError, data: string) => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'Failed to get AAID: %{public}d %{public}s', err.code, err.message);
        callback(err);
      } else {
        hilog.info(DOMAIN, TAG, 'Succeeded in getting AAID: %{public}s', data);
        
        // 验证AAID格式
        if (data && data.length === 36) {
          callback(null, data);
        } else {
          const error: BusinessError = {
            code: -1,
            name: 'InvalidFormat',
            message: 'Invalid AAID format'
          } as BusinessError;
          callback(error);
        }
      }
    });
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Exception in getAAID: %{public}d %{public}s', e.code, e.message);
    callback(e);
  }
}

/**
 * 删除AAID（Callback方式）
 * @param callback 回调函数，参数为错误对象
 */
function deleteAAIDWithCallback(callback: (err: BusinessError | null) => void): void {
  try {
    hilog.info(DOMAIN, TAG, 'Starting to delete AAID with callback');
    
    AAID.deleteAAID((err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'Failed to delete AAID: %{public}d %{public}s', err.code, err.message);
        callback(err);
      } else {
        hilog.info(DOMAIN, TAG, 'Succeeded in deleting AAID');
        callback(null);
      }
    });
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'Exception in deleteAAID: %{public}d %{public}s', e.code, e.message);
    callback(e);
  }
}

/**
 * 错误处理封装
 * @param error BusinessError对象
 */
function handleAAIDError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error: %{public}s', error.message);
      break;
    case 1000900001:
      hilog.error(DOMAIN, TAG, 'System internal error: %{public}s', error.message);
      break;
    case 1000900006:
      hilog.error(DOMAIN, TAG, 'Failed to connect to AAID service: %{public}s', error.message);
      break;
    case 1000900007:
      hilog.error(DOMAIN, TAG, 'Internal error of AAID service: %{public}s', error.message);
      break;
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d %{public}s', error.code, error.message);
      break;
  }
}

// 主函数示例
function main(): void {
  // 示例1：获取AAID
  hilog.info(DOMAIN, TAG, '=== Example 1: Get AAID ===');
  getAAIDWithCallback((err, aaid) => {
    if (err) {
      handleAAIDError(err);
      return;
    }
    
    hilog.info(DOMAIN, TAG, 'AAID: %{public}s, length: %{public}d', aaid!, aaid!.length);
    
    // 示例2：删除AAID
    hilog.info(DOMAIN, TAG, '=== Example 2: Delete AAID ===');
    deleteAAIDWithCallback((deleteErr) => {
      if (deleteErr) {
        handleAAIDError(deleteErr);
        return;
      }
      
      // 示例3：删除后重新获取
      hilog.info(DOMAIN, TAG, '=== Example 3: Get AAID after deletion ===');
      getAAIDWithCallback((newErr, newAaid) => {
        if (newErr) {
          handleAAIDError(newErr);
          return;
        }
        
        hilog.info(DOMAIN, TAG, 'New AAID: %{public}s', newAaid!);
        
        // 验证AAID已改变
        if (aaid !== newAaid) {
          hilog.info(DOMAIN, TAG, 'AAID changed after deletion (expected behavior)');
        }
      });
    });
  });
}

// 导出函数供外部使用
export { getAAIDWithCallback, deleteAAIDWithCallback, handleAAIDError };

// 执行主函数
main();