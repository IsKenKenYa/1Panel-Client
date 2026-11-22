// entry/src/main/ets/form/ErrorHandlingDemo.ets
// 卡片刷新错误处理和降级策略完整示例

import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'FormErrorHandler';
const DOMAIN_NUMBER: number = 0xFF00;

/**
 * 卡片刷新管理器
 * 提供完整的错误处理和降级策略
 */
class FormRefreshManager {
  private formCache: Map<string, Record<string, string>> = new Map();
  
  /**
   * 主刷新策略：优先使用最新数据
   */
  async primaryRefresh(formId: string): Promise<void> {
    try {
      // 1. 获取最新数据（从网络或数据库）
      const latestData = await this.fetchLatestData(formId);
      
      // 2. 创建FormBindingData
      const formData = formBindingData.createFormBindingData(latestData);
      
      // 3. 更新卡片
      await formProvider.updateForm(formId, formData);
      
      // 4. 缓存成功数据
      this.cacheFormData(formId, latestData);
      
      hilog.info(DOMAIN_NUMBER, TAG, `Primary refresh success for formId: ${formId}`);
      
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.warn(DOMAIN_NUMBER, TAG, 
        `Primary refresh failed: ${businessError.code} - ${businessError.message}`);
      
      // 执行降级策略
      await this.fallbackRefresh(formId, businessError);
    }
  }

  /**
   * 降级刷新策略
   */
  private async fallbackRefresh(formId: string, error: BusinessError): Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, `Executing fallback strategy for formId: ${formId}`);
    
    // 根据错误类型选择不同的降级策略
    switch (error.code) {
      case 401: // 参数错误
        hilog.error(DOMAIN_NUMBER, TAG, 'Parameter error, cannot fallback');
        throw error;
      
      case 16501001: // formId不存在
        hilog.error(DOMAIN_NUMBER, TAG, 'FormId does not exist, skip refresh');
        throw error;
      
      case 16500050: // IPC连接错误
        await this.ipcFallback(formId);
        break;
      
      case 16500060: // 服务连接错误
        await this.serviceFallback(formId);
        break;
      
      case 16501000: // 内部功能错误
        await this.internalErrorFallback(formId);
        break;
      
      default:
        await this.genericFallback(formId);
        break;
    }
  }

  /**
   * IPC连接错误降级策略
   */
  private async ipcFallback(formId: string): Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, 'IPC fallback: using cached data');
    
    try {
      // 方案1：使用缓存数据
      const cachedData = this.getCachedFormData(formId);
      if (cachedData) {
        const formData = formBindingData.createFormBindingData(cachedData);
        await formProvider.updateForm(formId, formData);
        hilog.info(DOMAIN_NUMBER, TAG, 'IPC fallback success with cached data');
        return;
      }
      
      // 方案2：等待后重试
      await this.delay(2000);
      await this.retryRefresh(formId, 3);
      
    } catch (fallbackError) {
      hilog.error(DOMAIN_NUMBER, TAG, `IPC fallback failed: ${fallbackError}`);
      await this.finalFallback(formId);
    }
  }

  /**
   * 服务连接错误降级策略
   */
  private async serviceFallback(formId: string): Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, 'Service fallback: using default data');
    
    const defaultData: Record<string, string> = {
      'title': 'Service Unavailable',
      'detail': 'Please try again later',
      'status': 'error'
    };
    
    try {
      const formData = formBindingData.createFormBindingData(defaultData);
      await formProvider.updateForm(formId, formData);
      hilog.info(DOMAIN_NUMBER, TAG, 'Service fallback success with default data');
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Service fallback failed: ${error}`);
      // 无法降级，记录日志
    }
  }

  /**
   * 内部功能错误降级策略
   */
  private async internalErrorFallback(formId: string): Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, 'Internal error fallback: retry with delay');
    
    try {
      // 延迟5秒后重试
      await this.delay(5000);
      await this.retryRefresh(formId, 2);
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Internal error fallback failed: ${error}`);
      await this.finalFallback(formId);
    }
  }

  /**
   * 通用降级策略
   */
  private async genericFallback(formId: string): Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, 'Generic fallback: using cached data then default');
    
    try {
      // 尝试使用缓存
      const cachedData = this.getCachedFormData(formId);
      if (cachedData) {
        const formData = formBindingData.createFormBindingData(cachedData);
        await formProvider.updateForm(formId, formData);
        hilog.info(DOMAIN_NUMBER, TAG, 'Generic fallback success with cached data');
        return;
      }
      
      // 使用默认数据
      await this.finalFallback(formId);
      
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Generic fallback failed: ${error}`);
    }
  }

  /**
   * 最终降级方案：使用默认数据
   */
  private async finalFallback(formId: string): Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, 'Final fallback: using default minimal data');
    
    const minimalData: Record<string, string> = {
      'title': 'Loading...',
      'detail': 'Data temporarily unavailable'
    };
    
    try {
      const formData = formBindingData.createFormBindingData(minimalData);
      await formProvider.updateForm(formId, formData);
      hilog.info(DOMAIN_NUMBER, TAG, 'Final fallback success');
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Final fallback failed: ${error}`);
      // 无法继续降级，放弃刷新
    }
  }

  /**
   * 重试刷新
   */
  private async retryRefresh(formId: string, maxRetries: number): Promise<void> {
    for (let i = 0; i < maxRetries; i++) {
      try {
        hilog.info(DOMAIN_NUMBER, TAG, `Retry refresh attempt ${i + 1}/${maxRetries}`);
        
        const latestData = await this.fetchLatestData(formId);
        const formData = formBindingData.createFormBindingData(latestData);
        await formProvider.updateForm(formId, formData);
        
        hilog.info(DOMAIN_NUMBER, TAG, `Retry refresh success on attempt ${i + 1}`);
        return;
        
      } catch (error) {
        hilog.warn(DOMAIN_NUMBER, TAG, `Retry attempt ${i + 1} failed: ${error}`);
        
        if (i === maxRetries - 1) {
          throw error;
        }
        
        // 延迟后继续重试
        await this.delay(1000);
      }
    }
  }

  /**
   * 获取最新数据（模拟实现）
   */
  private async fetchLatestData(formId: string): Promise<Record<string, string>> {
    // 实际应用中应从网络API或本地数据库获取
    // 这里模拟数据获取过程
    
    const success = Math.random() > 0.3; // 70%成功率
    
    if (success) {
      return {
        'title': 'Weather Update',
        'detail': 'Partly cloudy',
        'temperature': `${Math.floor(Math.random() * 10 + 20)}c`,
        'updateTime': new Date().toLocaleTimeString()
      };
    } else {
      throw new Error('Network error');
    }
  }

  /**
   * 缓存卡片数据
   */
  private cacheFormData(formId: string, data: Record<string, string>): void {
    this.formCache.set(formId, data);
    hilog.info(DOMAIN_NUMBER, TAG, `Cached data for formId: ${formId}`);
  }

  /**
   * 获取缓存数据
   */
  private getCachedFormData(formId: string): Record<string, string> | null {
    const cachedData = this.formCache.get(formId);
    if (cachedData) {
      hilog.info(DOMAIN_NUMBER, TAG, `Retrieved cached data for formId: ${formId}`);
      return cachedData;
    }
    return null;
  }

  /**
   * 延迟函数
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// 使用示例
const refreshManager = new FormRefreshManager();

// 在FormExtensionAbility中使用
async function handleFormRefresh(formId: string): void {
  try {
    await refreshManager.primaryRefresh(formId);
  } catch (error) {
    hilog.error(DOMAIN_NUMBER, TAG, `All refresh strategies failed for formId: ${formId}`);
    // 记录失败日志，等待下次刷新机会
  }
}

// 批量刷新错误处理示例
async function batchRefreshWithErrorHandling(formIds: string[]): Promise<Map<string, boolean>> {
  const results = new Map<string, boolean>();
  
  for (let formId of formIds) {
    try {
      await refreshManager.primaryRefresh(formId);
      results.set(formId, true);
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Batch refresh failed for formId: ${formId}`);
      results.set(formId, false);
      // 继续处理其他卡片
    }
  }
  
  return results;
}