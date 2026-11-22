import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 服务消亡事件订阅管理示例
 * 演示如何订阅和取消订阅Wear Engine服务消亡事件
 */
class ServiceDieSubscriptionManager {
  private serviceDieCallback: () => void;
  private isSubscribed: boolean = false;

  constructor() {
    // 定义服务消亡回调函数
    this.serviceDieCallback = () => {
      console.info('Service destruction event triggered');
      this.handleServiceDie();
    };
  }

  /**
   * 处理服务消亡事件
   */
  private handleServiceDie(): void {
    console.warn('Wear Engine service has been destroyed');
    this.isSubscribed = false;
    
    // 在此处添加服务断开后的处理逻辑
    // 例如：提示用户、清理缓存、重置状态等
  }

  /**
   * 订阅服务消亡事件
   * @returns 是否订阅成功
   */
  public subscribeServiceDie(): boolean {
    if (this.isSubscribed) {
      console.warn('Already subscribed to service die event');
      return true;
    }

    try {
      wearEngine.on('serviceDie', this.serviceDieCallback);
      this.isSubscribed = true;
      console.info('Succeeded in subscribing service destruction event');
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to subscribe service destruction event. Code: ${err.code}, Message: ${err.message}`);
      
      // 错误处理分支
      switch (err.code) {
        case 401:
          console.error('Parameter error: check callback type');
          break;
        case 1008500012:
          console.error('Too many callbacks of the same type');
          // 降级处理：先取消所有订阅，再重新订阅
          this.unsubscribeAllServiceDie();
          try {
            wearEngine.on('serviceDie', this.serviceDieCallback);
            this.isSubscribed = true;
            return true;
          } catch (retryError) {
            console.error('Retry subscription failed');
            return false;
          }
        case 1008509999:
          console.error('Internal error, retry after delay');
          // 延时重试
          setTimeout(() => {
            this.subscribeServiceDie();
          }, 3000);
          return false;
        default:
          console.error(`Unknown error: ${err.message}`);
          return false;
      }
      
      return false;
    }
  }

  /**
   * 取消订阅服务消亡事件（指定回调）
   * @returns 是否取消成功
   */
  public unsubscribeServiceDie(): boolean {
    if (!this.isSubscribed) {
      console.warn('Not subscribed to service die event');
      return true;
    }

    try {
      wearEngine.off('serviceDie', this.serviceDieCallback);
      this.isSubscribed = false;
      console.info('Succeeded in unsubscribing service destruction event');
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to unsubscribe service destruction event. Code: ${err.code}, Message: ${err.message}`);
      
      switch (err.code) {
        case 401:
          console.error('Parameter error: callback object mismatch');
          break;
        case 1008509999:
          console.error('Internal error');
          break;
        default:
          console.error(`Unknown error: ${err.message}`);
      }
      
      return false;
    }
  }

  /**
   * 取消订阅所有服务消亡事件
   */
  public unsubscribeAllServiceDie(): void {
    try {
      wearEngine.off('serviceDie');
      this.isSubscribed = false;
      console.info('Succeeded in unsubscribing all service destruction events');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to unsubscribe all events. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  /**
   * 获取当前订阅状态
   */
  public getSubscriptionStatus(): boolean {
    return this.isSubscribed;
  }
}

// 使用示例
@Entry
@Component
struct ServiceDieSubscriptionPage {
  private manager: ServiceDieSubscriptionManager = new ServiceDieSubscriptionManager();

  build() {
    Column({ space: 20 }) {
      Button('订阅服务消亡事件')
        .onClick(() => {
          const success = this.manager.subscribeServiceDie();
          if (success) {
            console.info('订阅成功');
          } else {
            console.error('订阅失败');
          }
        })

      Button('取消订阅服务消亡事件')
        .onClick(() => {
          const success = this.manager.unsubscribeServiceDie();
          if (success) {
            console.info('取消订阅成功');
          } else {
            console.error('取消订阅失败');
          }
        })

      Text(`订阅状态: ${this.manager.getSubscriptionStatus() ? '已订阅' : '未订阅'}`)
    }
    .width('100%')
    .padding(20)
  }
}