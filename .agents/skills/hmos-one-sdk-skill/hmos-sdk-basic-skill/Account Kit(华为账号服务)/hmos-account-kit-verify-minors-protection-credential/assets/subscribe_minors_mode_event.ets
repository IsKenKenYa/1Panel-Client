/**
 * 订阅未成年人模式事件示例
 * 
 * 功能说明：
 * 本示例展示如何订阅系统未成年人模式开启/关闭事件，及时响应系统状态变化。
 * 当系统未成年人模式切换时，应用自动调整内容展示和功能限制。
 * 
 * 使用场景：
 * - 应用跟随系统未成年人模式切换
 * - 实时更新内容展示策略
 * - 刷新缓存的状态信息
 * 
 * 注意事项：
 * - 订阅事件后，在应用退出时应取消订阅
 * - 事件触发时，建议刷新缓存的未成年人模式状态
 * - 避免在事件回调中执行耗时操作
 */

import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { commonEventManager, CommonEventManager } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';

const LOG_TAG = 'MinorsModeEvent';
const LOG_DOMAIN = 0x0000;

/**
 * 未成年人模式事件订阅示例组件
 */
@Entry
@Component
struct MinorsModeEventSubscriber {
  @State minorsModeEnabled: boolean = false;
  @State ageGroupText: string = '';
  @State eventMessage: string = '等待事件触发...';
  
  private minorsModeOnSubscriber: CommonEventManager.CommonEventSubscriber | null = null;
  private minorsModeOffSubscriber: CommonEventManager.CommonEventSubscriber | null = null;
  
  /**
   * 页面加载时订阅事件并查询初始状态
   */
  aboutToAppear() {
    // 查询初始状态
    this.queryMinorsProtectionStatus();
    
    // 订阅未成年人模式事件
    this.subscribeMinorsModeEvents();
  }
  
  /**
   * 页面退出时取消订阅
   */
  aboutToDisappear() {
    this.unsubscribeMinorsModeEvents();
  }
  
  /**
   * 查询未成年人模式状态
   */
  queryMinorsProtectionStatus(): void {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'Device does not support minors protection');
      return;
    }
    
    try {
      if (minorsProtection.supportMinorsMode()) {
        const info = minorsProtection.getMinorsProtectionInfoSync();
        this.minorsModeEnabled = info.minorsProtectionMode;
        
        if (this.minorsModeEnabled && info.ageGroup) {
          this.ageGroupText = `[${info.ageGroup.lowerAge}, ${info.ageGroup.upperAge})岁`;
        } else {
          this.ageGroupText = '';
        }
        
        hilog.info(LOG_DOMAIN, LOG_TAG, 
          `Status: enabled=${this.minorsModeEnabled}, ageGroup=${this.ageGroupText}`);
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 
        `Failed to query status: ${error.message}`);
    }
  }
  
  /**
   * 订阅未成年人模式开启/关闭事件
   */
  subscribeMinorsModeEvents(): void {
    try {
      // 创建订阅者配置
      const onConfig: CommonEventManager.CommonEventSubscribeInfo = {
        events: ['usual.event.MINORSMODE_ON']
      };
      
      const offConfig: CommonEventManager.CommonEventSubscribeInfo = {
        events: ['usual.event.MINORSMODE_OFF']
      };
      
      // 创建订阅者
      this.minorsModeOnSubscriber = commonEventManager.createCommonEventSubscriber(onConfig);
      this.minorsModeOffSubscriber = commonEventManager.createCommonEventSubscriber(offConfig);
      
      // 订阅未成年人模式开启事件
      if (this.minorsModeOnSubscriber) {
        commonEventManager.subscribeCommonEvent(
          this.minorsModeOnSubscriber,
          (err, data) => {
            if (err) {
              hilog.error(LOG_DOMAIN, LOG_TAG, 
                `Subscribe MINORSMODE_ON failed: ${err.message}`);
              return;
            }
            
            hilog.info(LOG_DOMAIN, LOG_TAG, 'Minors mode turned ON event received');
            this.eventMessage = '事件：未成年人模式已开启';
            
            // 刷新状态并更新应用
            this.onMinorsModeOn();
          }
        );
      }
      
      // 订阅未成年人模式关闭事件
      if (this.minorsModeOffSubscriber) {
        commonEventManager.subscribeCommonEvent(
          this.minorsModeOffSubscriber,
          (err, data) => {
            if (err) {
              hilog.error(LOG_DOMAIN, LOG_TAG, 
                `Subscribe MINORSMODE_OFF failed: ${err.message}`);
              return;
            }
            
            hilog.info(LOG_DOMAIN, LOG_TAG, 'Minors mode turned OFF event received');
            this.eventMessage = '事件：未成年人模式已关闭';
            
            // 刷新状态并更新应用
            this.onMinorsModeOff();
          }
        );
      }
      
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Minors mode events subscribed successfully');
    } catch (error) {
      const err = error as BusinessError<Object>;
      hilog.error(LOG_DOMAIN, LOG_TAG, 
        `Failed to subscribe events: ${err.message}`);
    }
  }
  
  /**
   * 取消订阅事件
   */
  unsubscribeMinorsModeEvents(): void {
    try {
      if (this.minorsModeOnSubscriber) {
        commonEventManager.unsubscribeCommonEvent(this.minorsModeOnSubscriber);
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Unsubscribed MINORSMODE_ON event');
      }
      
      if (this.minorsModeOffSubscriber) {
        commonEventManager.unsubscribeCommonEvent(this.minorsModeOffSubscriber);
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Unsubscribed MINORSMODE_OFF event');
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 
        `Failed to unsubscribe: ${error.message}`);
    }
  }
  
  /**
   * 未成年人模式开启事件处理
   */
  onMinorsModeOn(): void {
    // 刷新缓存的状态
    this.queryMinorsProtectionStatus();
    
    // 更新应用内容展示策略
    this.updateAppContentStrategy(true);
    
    // 显示提示
    this.showMinorsModeOnNotification();
  }
  
  /**
   * 未成年人模式关闭事件处理
   */
  onMinorsModeOff(): void {
    // 刷新缓存的状态
    this.queryMinorsProtectionStatus();
    
    // 更新应用内容展示策略
    this.updateAppContentStrategy(false);
    
    // 显示提示
    this.showMinorsModeOffNotification();
  }
  
  /**
   * 更新应用内容展示策略
   * 
   * @param enabled 未成年人模式是否开启
   */
  updateAppContentStrategy(enabled: boolean): void {
    if (enabled) {
      // 未成年人模式开启，展示适龄内容
      const info = minorsProtection.getMinorsProtectionInfoSync();
      const ageGroup = info.ageGroup;
      
      if (ageGroup) {
        this.adjustContentByAgeGroup(ageGroup.lowerAge, ageGroup.upperAge);
      }
    } else {
      // 未成年人模式关闭，展示正常内容
      this.showNormalContent();
    }
  }
  
  /**
   * 根据年龄段调整内容
   */
  adjustContentByAgeGroup(lowerAge: number, upperAge: number): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 
      `Adjusting content for age [${lowerAge}, ${upperAge})`);
    
    // 实际应用中，这里会根据年龄段调整：
    // 1. 内容推荐算法
    // 2. 搜索结果过滤
    // 3. 功能权限控制
    // 4. UI展示调整
    
    // 示例：根据年龄段设置不同的内容级别
    if (lowerAge < 3) {
      // 婴幼儿段
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting content for infants (0-3 years)');
    } else if (lowerAge < 8) {
      // 低龄段
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting content for young children (3-8 years)');
    } else if (lowerAge < 12) {
      // 中龄段
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting content for children (8-12 years)');
    } else if (lowerAge < 16) {
      // 青少年段
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting content for teenagers (12-16 years)');
    } else {
      // 青年段
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting content for young adults (16-18 years)');
    }
  }
  
  /**
   * 展示正常内容（无年龄限制）
   */
  showNormalContent(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Showing normal content without age restrictions');
    
    // 实际应用中，这里会恢复：
    // 1. 所有内容推荐
    // 2. 完整搜索功能
    // 3. 所有功能权限
    // 4. 正常UI展示
  }
  
  /**
   * 显示未成年人模式开启通知
   */
  showMinorsModeOnNotification(): void {
    // 可以使用Toast或AlertDialog提示用户
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Minors mode enabled, content adjusted');
  }
  
  /**
   * 显示未成年人模式关闭通知
   */
  showMinorsModeOffNotification(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Minors mode disabled, showing normal content');
  }
  
  build() {
    Column() {
      Text('未成年人模式事件订阅')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      // 当前状态
      Text(`当前状态: ${this.minorsModeEnabled ? '已开启' : '未开启'}`)
        .fontSize(18)
        .margin({ bottom: 10 });
      
      // 年龄段
      if (this.ageGroupText !== '') {
        Text(`年龄段: ${this.ageGroupText}`)
          .fontSize(18)
          .margin({ bottom: 10 });
      }
      
      // 事件消息
      Text(this.eventMessage)
        .fontSize(16)
        .fontColor(Color.Blue)
        .margin({ top: 20, bottom: 20 });
      
      // 刷新按钮
      Button('刷新状态')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.queryMinorsProtectionStatus();
        })
        .margin({ bottom: 20 });
      
      // 说明文字
      Text('应用会自动订阅系统未成年人模式切换事件')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 20 });
      
      Text('事件触发时会自动更新应用内容展示策略')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 10 });
    }
    .width('100%')
    .padding(20);
  }
}