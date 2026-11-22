import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

class MotionManager {
  private static instance: MotionManager;
  private operatingHandCallback: Callback<motion.OperatingHandStatus> | null = null;
  private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;
  private isOperatingHandSubscribed: boolean = false;
  private isHoldingHandSubscribed: boolean = false;
  
  private constructor() {}
  
  static getInstance(): MotionManager {
    if (!MotionManager.instance) {
      MotionManager.instance = new MotionManager();
    }
    return MotionManager.instance;
  }
  
  subscribeOperatingHand(callback: Callback<motion.OperatingHandStatus>): boolean {
    if (this.isOperatingHandSubscribed && this.operatingHandCallback) {
      console.warn('已订阅操作手，先取消旧订阅');
      this.unsubscribeOperatingHand();
    }
    
    this.operatingHandCallback = callback;
    
    try {
      motion.on('operatingHandChanged', callback);
      this.isOperatingHandSubscribed = true;
      console.info('订阅操作手成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('订阅操作手失败: ' + error.code);
      this.operatingHandCallback = null;
      return false;
    }
  }
  
  unsubscribeOperatingHand(): boolean {
    if (!this.isOperatingHandSubscribed) {
      console.warn('未订阅操作手');
      return true;
    }
    
    try {
      motion.off('operatingHandChanged');
      this.isOperatingHandSubscribed = false;
      this.operatingHandCallback = null;
      console.info('取消订阅操作手成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('取消订阅操作手失败: ' + error.code);
      return false;
    }
  }
  
  getLatestOperatingHandStatus(): motion.OperatingHandStatus | null {
    try {
      return motion.getRecentOperatingHandStatus();
    } catch (err) {
      let error = err as BusinessError;
      console.error('获取最新操作手状态失败: ' + error.code);
      return null;
    }
  }
  
  subscribeHoldingHand(callback: Callback<motion.HoldingHandStatus>): boolean {
    if (this.isHoldingHandSubscribed && this.holdingHandCallback) {
      console.warn('已订阅握持手，先取消旧订阅');
      this.unsubscribeHoldingHand();
    }
    
    this.holdingHandCallback = callback;
    
    try {
      motion.on('holdingHandChanged', callback);
      this.isHoldingHandSubscribed = true;
      console.info('订阅握持手成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('订阅握持手失败: ' + error.code);
      this.holdingHandCallback = null;
      return false;
    }
  }
  
  unsubscribeHoldingHand(): boolean {
    if (!this.isHoldingHandSubscribed) {
      console.warn('未订阅握持手');
      return true;
    }
    
    try {
      motion.off('holdingHandChanged');
      this.isHoldingHandSubscribed = false;
      this.holdingHandCallback = null;
      console.info('取消订阅握持手成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('取消订阅握持手失败: ' + error.code);
      return false;
    }
  }
  
  isSubscribed(): { operatingHand: boolean; holdingHand: boolean } {
    return {
      operatingHand: this.isOperatingHandSubscribed,
      holdingHand: this.isHoldingHandSubscribed
    };
  }
  
  cleanup(): void {
    this.unsubscribeOperatingHand();
    this.unsubscribeHoldingHand();
    console.info('清理所有订阅');
  }
}

export { MotionManager };

@Entry
@Component
struct GlobalSubscriptionExample {
  @StorageLink('operatingHand') operatingHand: number = motion.OperatingHandStatus.UNKNOWN_STATUS;
  @StorageLink('holdingHand') holdingHand: number = motion.HoldingHandStatus.UNKNOWN_STATUS;
  
  private motionManager: MotionManager = MotionManager.getInstance();
  
  aboutToAppear(): void {
    this.startGlobalSubscription();
  }
  
  aboutToDisappear(): void {
    this.motionManager.cleanup();
  }
  
  startGlobalSubscription(): void {
    const operatingHandCallback = (data: motion.OperatingHandStatus) => {
      AppStorage.setOrCreate('operatingHand', data);
      console.info('全局操作手状态更新: ' + data);
    };
    
    const holdingHandCallback = (data: motion.HoldingHandStatus) => {
      AppStorage.setOrCreate('holdingHand', data);
      console.info('全局握持手状态更新: ' + data);
    };
    
    this.motionManager.subscribeOperatingHand(operatingHandCallback);
    this.motionManager.subscribeHoldingHand(holdingHandCallback);
    
    const initialStatus = this.motionManager.getLatestOperatingHandStatus();
    if (initialStatus !== null) {
      AppStorage.setOrCreate('operatingHand', initialStatus);
    }
  }
  
  getOperatingHandText(): string {
    switch (this.operatingHand) {
      case motion.OperatingHandStatus.LEFT_HAND_OPERATED:
        return '左手操作';
      case motion.OperatingHandStatus.RIGHT_HAND_OPERATED:
        return '右手操作';
      default:
        return '未识别';
    }
  }
  
  getHoldingHandText(): string {
    switch (this.holdingHand) {
      case motion.HoldingHandStatus.LEFT_HAND_HELD:
        return '左手握持';
      case motion.HoldingHandStatus.RIGHT_HAND_HELD:
        return '右手握持';
      case motion.HoldingHandStatus.BOTH_HANDS_HELD:
        return '双手握持';
      case motion.HoldingHandStatus.NOT_HELD:
        return '未握持';
      default:
        return '未识别';
    }
  }
  
  build() {
    Column({ space: 20 }) {
      Text('全局订阅管理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      Text('使用单例模式管理全局订阅')
        .fontSize(16)
      
      Row({ space: 10 }) {
        Text('操作手状态: ')
          .fontSize(16)
        Text(this.getOperatingHandText())
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
      }
      
      Row({ space: 10 }) {
        Text('握持手状态: ')
          .fontSize(16)
        Text(this.getHoldingHandText())
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
      }
      
      Row({ space: 10 }) {
        Text('订阅状态: ')
          .fontSize(16)
        Text(JSON.stringify(this.motionManager.isSubscribed()))
          .fontSize(14)
      }
      
      Divider()
      
      Text('说明:')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      
      Text('1. 使用 MotionManager 单例管理订阅')
        .fontSize(14)
      
      Text('2. 状态通过 AppStorage 全局共享')
        .fontSize(14)
      
      Text('3. @StorageLink 自动同步状态更新')
        .fontSize(14)
      
      Text('4. 页面销毁时自动清理订阅')
        .fontSize(14)
      
      Text('5. 防止重复订阅和内存泄漏')
        .fontSize(14)
    }
    .width('100%')
    .padding(20)
  }
}