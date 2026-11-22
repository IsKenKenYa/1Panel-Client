/**
 * Wear Engine服务连接状态管理完整示例
 * 功能:订阅监听服务断联事件、取消监听、主动断开连接
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * Wear Engine服务管理器
 */
export class WearEngineServiceManager {
  private serviceDieCallback: () => void;
  private isSubscribed: boolean = false;

  constructor() {
    // 定义服务断联回调函数
    this.serviceDieCallback = () => {
      this.handleServiceDied();
    };
  }

  /**
   * 订阅监听服务断联事件
   */
  subscribeServiceDie(): void {
    if (this.isSubscribed) {
      console.warn('ServiceDie event already subscribed');
      return;
    }

    try {
      wearEngine.on('serviceDie', this.serviceDieCallback);
      this.isSubscribed = true;
      console.info('Succeeded in subscribing the service destruction event');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to subscribe serviceDie event. Code: ${err.code}, Message: ${err.message}`);
      this.handleSubscriptionError(err);
    }
  }

  /**
   * 取消订阅监听服务断联事件
   */
  unsubscribeServiceDie(): void {
    if (!this.isSubscribed) {
      console.warn('ServiceDie event not subscribed');
      return;
    }

    try {
      wearEngine.off('serviceDie', this.serviceDieCallback);
      this.isSubscribed = false;
      console.info('Succeeded in unsubscribing the service destruction event');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to unsubscribe serviceDie event. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  /**
   * 取消所有服务断联事件订阅
   */
  unsubscribeAllServiceDie(): void {
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
   * 主动断开与Wear Engine服务的连接
   */
  async destroyService(): Promise<void> {
    try {
      await wearEngine.destroy();
      this.isSubscribed = false;
      console.info('Succeeded in destroying wear engine channel');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to destroy wear engine channel. Code: ${err.code}, Message: ${err.message}`);
      throw err;
    }
  }

  /**
   * 处理服务断联事件
   */
  private handleServiceDied(): void {
    console.warn('Wear Engine service died unexpectedly');
    this.isSubscribed = false;
    
    // 通知应用层处理服务断开
    this.notifyServiceDisconnected();
    
    // 可选:尝试重新连接
    this.attemptReconnect();
  }

  /**
   * 通知服务已断开
   */
  private notifyServiceDisconnected(): void {
    // 在这里添加通知逻辑
    // 例如:发送事件到UI层、更新应用状态等
    console.info('Service disconnected notification sent');
  }

  /**
   * 尝试重新连接服务
   */
  private async attemptReconnect(): Promise<void> {
    try {
      // 通过调用任意接口触发自动重连
      // 这里使用获取设备列表作为示例
      const deviceClient = wearEngine.getDeviceClient(getContext());
      const devices = await deviceClient.getConnectedDevices();
      console.info(`Service reconnected, found ${devices.length} devices`);
      
      // 重新订阅服务断联事件
      this.subscribeServiceDie();
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to reconnect service. Code: ${err.code}, Message: ${err.message}`);
    }
  }

  /**
   * 处理订阅错误
   */
  private handleSubscriptionError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error: check callback function');
        break;
      case 1008500012:
        console.error('Too many callbacks registered, unsubscribe unnecessary ones first');
        // 尝试取消所有订阅后重新订阅
        this.unsubscribeAllServiceDie();
        setTimeout(() => this.subscribeServiceDie(), 1000);
        break;
      case 1008509999:
        console.error('Internal error, check app configuration');
        break;
      default:
        console.error(`Unknown error: ${error.code}`);
    }
  }

  /**
   * 获取当前订阅状态
   */
  getSubscriptionStatus(): boolean {
    return this.isSubscribed;
  }
}

/**
 * 使用示例
 */
export function exampleUsage(): void {
  const serviceManager = new WearEngineServiceManager();

  // 场景1:应用启动时订阅服务断联事件
  console.info('=== Scenario 1: Subscribe on app start ===');
  serviceManager.subscribeServiceDie();

  // 场景2:检查订阅状态
  console.info(`Subscription status: ${serviceManager.getSubscriptionStatus()}`);

  // 场景3:应用退出时取消订阅
  setTimeout(() => {
    console.info('=== Scenario 3: Unsubscribe on app exit ===');
    serviceManager.unsubscribeServiceDie();
  }, 5000);

  // 场景4:主动断开服务连接(如切换用户场景)
  setTimeout(async () => {
    console.info('=== Scenario 4: Destroy service ===');
    try {
      await serviceManager.destroyService();
      console.info('Service destroyed successfully');
    } catch (error) {
      console.error('Failed to destroy service');
    }
  }, 10000);
}

/**
 * 测试场景示例
 */
export class WearEngineServiceTest {
  /**
   * 正向测试:正常订阅和取消流程
   */
  static testNormalFlow(): void {
    console.info('Test: Normal subscription flow');
    const manager = new WearEngineServiceManager();
    
    manager.subscribeServiceDie();
    if (manager.getSubscriptionStatus()) {
      console.info('✓ Subscription successful');
    }
    
    manager.unsubscribeServiceDie();
    if (!manager.getSubscriptionStatus()) {
      console.info('✓ Unsubscription successful');
    }
  }

  /**
   * 边界测试:多次订阅取消
   */
  static testMultipleSubscribe(): void {
    console.info('Test: Multiple subscribe/unsubscribe');
    const manager = new WearEngineServiceManager();
    
    // 第一次订阅
    manager.subscribeServiceDie();
    
    // 第二次订阅(应该被拒绝)
    manager.subscribeServiceDie();
    
    // 取消订阅
    manager.unsubscribeServiceDie();
    
    // 再次订阅
    manager.subscribeServiceDie();
    
    console.info('✓ Multiple subscription test completed');
  }

  /**
   * 异常测试:无效回调函数
   */
  static testInvalidCallback(): void {
    console.info('Test: Invalid callback function');
    try {
      // 直接使用wearEngine.on测试无效参数
      wearEngine.on('serviceDie', null as any);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      if (err.code === 401) {
        console.info('✓ Invalid callback detected correctly');
      }
    }
  }
}