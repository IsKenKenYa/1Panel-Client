/**
 * 处理多网建议的完整示例代码
 * 演示如何根据系统建议发起或释放多网请求
 */
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 多网建议管理器
 */
export class MultiPathRecommendationManager {
  private isMultiPathActive: boolean = false;
  private recommendationCallback: (data: netHandover.MultiPathRecommendationInfo) => void;
  
  constructor() {
    // 初始化回调函数
    this.recommendationCallback = (data: netHandover.MultiPathRecommendationInfo) => {
      this.handleRecommendation(data);
    };
  }
  
  /**
   * 开始监听多网建议
   */
  public startListening(): void {
    try {
      netHandover.on('multiPathRecommendation', this.recommendationCallback);
      console.info('[MultiPathManager] Started listening to multiPath recommendations');
    } catch (err) {
      const error = err as BusinessError;
      console.error('[MultiPathManager] Failed to start listening: ' + error.message);
      this.handleError(error);
    }
  }
  
  /**
   * 停止监听多网建议
   */
  public stopListening(): void {
    try {
      netHandover.off('multiPathRecommendation');
      console.info('[MultiPathManager] Stopped listening to multiPath recommendations');
    } catch (err) {
      const error = err as BusinessError;
      console.error('[MultiPathManager] Failed to stop listening: ' + error.message);
    }
  }
  
  /**
   * 处理多网建议
   * @param data 多网建议信息
   */
  private handleRecommendation(data: netHandover.MultiPathRecommendationInfo): void {
    console.info('[MultiPathManager] Received recommendation: ' + JSON.stringify(data));
    
    // 根据建议动作执行相应操作
    if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
      // 系统建议发起多网请求
      this.requestMultiPath();
    } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
      // 系统建议释放多网请求
      this.releaseMultiPath();
    }
  }
  
  /**
   * 发起多网请求
   */
  private requestMultiPath(): void {
    if (this.isMultiPathActive) {
      console.info('[MultiPathManager] Multi-path is already active, skip requesting');
      return;
    }
    
    try {
      // 检查配额
      const quota = netHandover.getMultiPathQuotaStats();
      console.info('[MultiPathManager] Current quota - used: ' + quota.used.count + 
                   ', remaining: ' + quota.remaining.count);
      
      if (quota.remaining.count <= 0) {
        console.warn('[MultiPathManager] No remaining quota, cannot request multi-path');
        return;
      }
      
      // 发起多网请求
      netHandover.requestMultiPath((result: netHandover.MultiPathRequestResult) => {
        console.info('[MultiPathManager] MultiPath request result: ' + JSON.stringify(result));
        
        if (result.result === netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
          console.info('[MultiPathManager] Multi-path activated successfully');
          this.isMultiPathActive = true;
        } else {
          console.error('[MultiPathManager] Failed to activate multi-path, error: ' + result.result);
          this.isMultiPathActive = false;
        }
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error('[MultiPathManager] Failed to request multi-path: ' + error.message);
      this.handleError(error);
    }
  }
  
  /**
   * 释放多网请求
   */
  private releaseMultiPath(): void {
    if (!this.isMultiPathActive) {
      console.info('[MultiPathManager] Multi-path is not active, skip releasing');
      return;
    }
    
    try {
      netHandover.releaseMultiPath();
      console.info('[MultiPathManager] Multi-path released successfully');
      this.isMultiPathActive = false;
    } catch (err) {
      const error = err as BusinessError;
      console.error('[MultiPathManager] Failed to release multi-path: ' + error.message);
      this.handleError(error);
    }
  }
  
  /**
   * 获取多网状态
   */
  public getMultiPathStatus(): boolean {
    return this.isMultiPathActive;
  }
  
  /**
   * 错误处理
   * @param error 业务错误
   */
  private handleError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[MultiPathManager] Permission denied');
        break;
      case 401:
        console.error('[MultiPathManager] Invalid parameter');
        break;
      case 801:
        console.error('[MultiPathManager] API not supported');
        break;
      case 1013600001:
        console.error('[MultiPathManager] Internal error');
        break;
      case 1013600002:
        console.error('[MultiPathManager] System error');
        break;
      case 1013620000:
        console.error('[MultiPathManager] Multi-path not enabled');
        break;
      case 1013620001:
        console.error('[MultiPathManager] Multi-path already active');
        break;
      case 1013620002:
        console.error('[MultiPathManager] Multi-path request limit reached');
        break;
      case 1013620003:
        console.error('[MultiPathManager] Power consumption limit');
        break;
      case 1013620004:
        console.error('[MultiPathManager] Quota exhausted');
        break;
      default:
        console.error('[MultiPathManager] Unknown error: ' + error.message);
        break;
    }
  }
}

/**
 * 使用示例
 */
export function example(): void {
  const manager = new MultiPathRecommendationManager();
  
  // 开始监听多网建议
  manager.startListening();
  
  // 业务逻辑...
  // 在应用需要时检查多网状态
  setTimeout(() => {
    const isActive = manager.getMultiPathStatus();
    console.info('Multi-path status: ' + (isActive ? 'active' : 'inactive'));
  }, 5000);
  
  // 应用退出时停止监听
  setTimeout(() => {
    manager.stopListening();
  }, 10000);
}

// 主入口
if (require.main === module) {
  example();
}