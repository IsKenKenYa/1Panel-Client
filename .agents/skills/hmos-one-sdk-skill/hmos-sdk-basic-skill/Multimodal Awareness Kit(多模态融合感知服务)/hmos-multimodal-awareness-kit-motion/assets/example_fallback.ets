import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

class MotionAwarenessFallback {
  private useFallback: boolean = false;
  private retryCount: number = 0;
  private maxRetries: number = 3;
  
  async initialize(): Promise<void> {
    try {
      const testCallback = (data: motion.OperatingHandStatus) => {
        console.info('设备支持操作手感知');
      };
      
      motion.on('operatingHandChanged', testCallback);
      motion.off('operatingHandChanged');
      
      this.useFallback = false;
      this.retryCount = 0;
      console.info('初始化成功，使用motion感知能力');
      
    } catch (err) {
      let error = err as BusinessError;
      
      if (error.code === 801 || error.code === 201) {
        this.useFallback = true;
        console.warn('启用降级方案: ' + (error.code === 801 ? '设备不支持' : '权限不足'));
      } else {
        console.error('初始化失败: ' + error.code);
        this.useFallback = true;
      }
    }
  }
  
  isFallbackMode(): boolean {
    return this.useFallback;
  }
  
  getOperatingHandStatus(): number {
    if (this.useFallback) {
      console.warn('降级模式: 返回默认值 UNKNOWN_STATUS');
      return motion.OperatingHandStatus.UNKNOWN_STATUS;
    }
    
    try {
      const status = motion.getRecentOperatingHandStatus();
      console.info('获取最新状态成功: ' + status);
      return status;
    } catch (err) {
      let error = err as BusinessError;
      console.error('获取状态失败: ' + error.code);
      
      if (error.code === 801) {
        this.useFallback = true;
        console.warn('设备不支持，切换到降级模式');
      }
      
      return motion.OperatingHandStatus.UNKNOWN_STATUS;
    }
  }
  
  subscribeOperatingHand(callback: Callback<motion.OperatingHandStatus>): boolean {
    if (this.useFallback) {
      console.warn('降级模式: 不执行订阅');
      return false;
    }
    
    try {
      motion.on('operatingHandChanged', callback);
      this.retryCount = 0;
      console.info('订阅成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('订阅失败: ' + error.code);
      
      this.handleSubscribeError(error);
      
      if (error.code === 31500001 || error.code === 31500002) {
        return this.retrySubscribe(callback);
      }
      
      return false;
    }
  }
  
  unsubscribeOperatingHand(): boolean {
    if (this.useFallback) {
      console.warn('降级模式: 无需取消订阅');
      return true;
    }
    
    try {
      motion.off('operatingHandChanged');
      console.info('取消订阅成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('取消订阅失败: ' + error.code);
      return false;
    }
  }
  
  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('权限不足');
        this.useFallback = true;
        break;
      case 401:
        console.error('参数错误');
        break;
      case 801:
        console.error('设备不支持');
        this.useFallback = true;
        break;
      case 31500001:
        console.warn('服务异常，准备重试');
        break;
      case 31500002:
        console.warn('订阅失败，准备重试');
        break;
      default:
        console.error('未知错误');
        this.useFallback = true;
    }
  }
  
  private retrySubscribe(callback: Callback<motion.OperatingHandStatus>): boolean {
    if (this.retryCount >= this.maxRetries) {
      console.error('重试次数超过限制，启用降级方案');
      this.useFallback = true;
      return false;
    }
    
    this.retryCount++;
    console.warn(`第 ${this.retryCount} 次重试订阅...`);
    
    setTimeout(() => {
      this.subscribeOperatingHand(callback);
    }, 1000);
    
    return false;
  }
  
  getErrorMessage(): string {
    if (this.useFallback) {
      return '设备不支持或权限不足，已启用降级方案';
    }
    return '';
  }
}

export { MotionAwarenessFallback };