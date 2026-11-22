import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * Wear Engine服务状态完整管理示例
 * 演示订阅、取消订阅、断开连接的完整流程
 */
class CompleteServiceStatusManager {
  private serviceDieCallback: () => void;
  private isSubscribed: boolean = false;
  private isConnected: boolean = true;

  constructor() {
    this.serviceDieCallback = () => {
      console.info('Service destruction event triggered');
      this.handleServiceDie();
    };
  }

  /**
   * 处理服务消亡事件
   */
  private handleServiceDie(): void {
    console.warn('Wear Engine service has been destroyed unexpectedly');
    this.isSubscribed = false;
    this.isConnected = false;
    
    // 提示用户服务已断开
    // 清理本地缓存
    // 重置状态变量
  }

  /**
   * 完整的服务状态管理流程
   * @returns 操作结果报告
   */
  public async manageServiceStatus(): Promise<{
    status: string;
    actionsPerformed: string[];
    apiUsed: string[];
    connectionStatus: string;
    callbacksRegistered: number;
  }> {
    const result = {
      status: 'success',
      actionsPerformed: [] as string[],
      apiUsed: [] as string[],
      connectionStatus: 'connected',
      callbacksRegistered: 0
    };

    // 步骤1：订阅服务消亡事件
    console.info('Step 1: Subscribe service die event');
    if (this.subscribeServiceDie()) {
      result.actionsPerformed.push('subscribed_service_die_event');
      result.apiUsed.push('wearEngine.on');
      result.callbacksRegistered = 1;
    } else {
      result.status = 'partial_failure';
      console.error('Subscription failed');
    }

    // 步骤2：验证订阅状态
    console.info('Step 2: Verify subscription status');
    if (this.isSubscribed) {
      console.info('Subscription verified successfully');
    }

    // 步骤3：取消订阅服务消亡事件
    console.info('Step 3: Unsubscribe service die event');
    if (this.unsubscribeServiceDie()) {
      result.actionsPerformed.push('unsubscribed_service_die_event');
      result.apiUsed.push('wearEngine.off');
      result.callbacksRegistered = 0;
    } else {
      result.status = 'partial_failure';
      console.error('Unsubscription failed');
    }

    // 步骤4：重新订阅（可选）
    console.info('Step 4: Re-subscribe if needed');
    if (!this.isSubscribed && this.subscribeServiceDie()) {
      result.actionsPerformed.push('re-subscribed_service_die_event');
      result.apiUsed.push('wearEngine.on');
      result.callbacksRegistered = 1;
    }

    // 步骤5：断开服务连接
    console.info('Step 5: Destroy service connection');
    if (await this.destroyConnection()) {
      result.actionsPerformed.push('destroyed_connection');
      result.apiUsed.push('wearEngine.destroy');
      result.connectionStatus = 'destroyed';
      result.callbacksRegistered = 0;
      this.isConnected = false;
    } else {
      result.status = 'partial_failure';
      console.error('Destroy failed');
    }

    return result;
  }

  /**
   * 订阅服务消亡事件
   */
  private subscribeServiceDie(): boolean {
    if (this.isSubscribed) {
      return true;
    }

    try {
      wearEngine.on('serviceDie', this.serviceDieCallback);
      this.isSubscribed = true;
      console.info('Succeeded in subscribing service destruction event');
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to subscribe. Code: ${err.code}, Message: ${err.message}`);
      
      if (err.code === 1008500012) {
        wearEngine.off('serviceDie');
        try {
          wearEngine.on('serviceDie', this.serviceDieCallback);
          this.isSubscribed = true;
          return true;
        } catch (retryError) {
          return false;
        }
      }
      
      return false;
    }
  }

  /**
   * 取消订阅服务消亡事件
   */
  private unsubscribeServiceDie(): boolean {
    if (!this.isSubscribed) {
      return true;
    }

    try {
      wearEngine.off('serviceDie', this.serviceDieCallback);
      this.isSubscribed = false;
      console.info('Succeeded in unsubscribing service destruction event');
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to unsubscribe. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }

  /**
   * 断开服务连接
   */
  private async destroyConnection(): Promise<boolean> {
    try {
      await wearEngine.destroy();
      this.isConnected = false;
      console.info('Succeeded in destroying wear engine channel');
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to destroy. Code: ${err.code}, Message: ${err.message}`);
      
      if (err.code === 1008509999) {
        await new Promise(resolve => setTimeout(resolve, 2000));
        try {
          await wearEngine.destroy();
          this.isConnected = false;
          return true;
        } catch (retryError) {
          return false;
        }
      }
      
      return false;
    }
  }

  /**
   * 获取当前状态
   */
  public getCurrentStatus(): {
    isSubscribed: boolean;
    isConnected: boolean;
  } {
    return {
      isSubscribed: this.isSubscribed,
      isConnected: this.isConnected
    };
  }
}

// 使用示例
@Entry
@Component
struct CompleteServiceStatusPage {
  private manager: CompleteServiceStatusManager = new CompleteServiceStatusManager();
  @State statusReport: string = '';

  build() {
    Column({ space: 20 }) {
      Button('执行完整服务状态管理流程')
        .onClick(async () => {
          const result = await this.manager.manageServiceStatus();
          this.statusReport = JSON.stringify(result, null, 2);
          console.info('Management result:', result);
        })

      Button('查看当前状态')
        .onClick(() => {
          const status = this.manager.getCurrentStatus();
          this.statusReport = `订阅状态: ${status.isSubscribed ? '已订阅' : '未订阅'}\n连接状态: ${status.isConnected ? '已连接' : '已断开'}`;
        })

      Text(this.statusReport)
        .fontSize(14)
        .maxLines(10)
    }
    .width('100%')
    .padding(20)
  }
}