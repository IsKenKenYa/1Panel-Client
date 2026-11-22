/**
 * HarmonyOS 订阅系统未成年人模式事件示例
 * 
 * 功能说明：
 * 1. 创建订阅者订阅公共事件
 * 2. 处理未成年人模式开启/关闭事件
 * 3. 取消订阅公共事件
 * 4. 错误处理和降级方案
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

const TAG = 'MinorsModeEventSubscription';
const DOMAIN = 0x0000;

// 订阅者对象（需要在全局定义）
let subscriber: commonEventManager.CommonEventSubscriber | null = null;

/**
 * 订阅系统未成年人模式公共事件
 */
export function subscribeMinorsModeEvents(): void {
  hilog.info(DOMAIN, TAG, 'Starting to subscribe minors mode events');
  
  // 定义订阅事件列表
  const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [
      commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON,  // 未成年人模式开启事件
      commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF  // 未成年人模式关闭事件
    ]
  };
  
  // 创建订阅者
  commonEventManager.createSubscriber(subscribeInfo)
    .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
      // 重要：必须将订阅者对象暂存，用于后续事件回调
      subscriber = commonEventSubscriber;
      
      hilog.info(DOMAIN, TAG, 'Subscriber created successfully');
      
      // 订阅公共事件
      commonEventManager.subscribe(subscriber, onEventReceived);
      
      hilog.info(DOMAIN, TAG, 'Successfully subscribed to minors mode events');
    })
    .catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `Failed to create subscriber. Code: ${error.code}, message: ${error.message}`);
      handleSubscriptionError(error);
    });
}

/**
 * 事件接收回调函数
 */
function onEventReceived(error: BusinessError, data: commonEventManager.CommonEventData): void {
  if (error) {
    hilog.error(DOMAIN, TAG, `Error in event callback. Code: ${error.code}, message: ${error.message}`);
    handleSubscriptionError(error);
    return;
  }
  
  hilog.info(DOMAIN, TAG, `Received event: ${data.event}`);
  hilog.info(DOMAIN, TAG, `Event data: ${JSON.stringify(data)}`);
  
  // 根据事件类型处理
  if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON) {
    handleMinorsModeOnEvent(data);
  } else if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF) {
    handleMinorsModeOffEvent(data);
  } else {
    hilog.warn(DOMAIN, TAG, `Unknown event received: ${data.event}`);
  }
}

/**
 * 处理未成年人模式开启事件
 */
function handleMinorsModeOnEvent(data: commonEventManager.CommonEventData): void {
  hilog.info(DOMAIN, TAG, 'Minors mode turned on');
  
  // 业务逻辑处理：
  // 1. 调用getMinorsProtectionInfoSync获取年龄段信息
  // 2. 根据年龄段刷新内容展示
  // 3. 更新缓存状态
  // 4. 开启应用的未成年人模式
  
  // 示例：通知应用其他模块
  notifyMinorsModeChanged(true);
  
  // 示例：刷新UI
  refreshUIForMinorsMode(true);
}

/**
 * 处理未成年人模式关闭事件
 */
function handleMinorsModeOffEvent(data: commonEventManager.CommonEventData): void {
  hilog.info(DOMAIN, TAG, 'Minors mode turned off');
  
  // 业务逻辑处理：
  // 1. 清空缓存的未成年人模式状态和年龄段信息
  // 2. 关闭应用的未成年人模式
  // 3. 展示内容不做限制
  // 4. 刷新应用UI
  
  // 示例：通知应用其他模块
  notifyMinorsModeChanged(false);
  
  // 示例：刷新UI
  refreshUIForMinorsMode(false);
}

/**
 * 取消订阅公共事件
 */
export function unsubscribeMinorsModeEvents(): void {
  if (!subscriber) {
    hilog.warn(DOMAIN, TAG, 'No subscriber to unsubscribe');
    return;
  }
  
  hilog.info(DOMAIN, TAG, 'Starting to unsubscribe minors mode events');
  
  commonEventManager.unsubscribe(subscriber)
    .then(() => {
      hilog.info(DOMAIN, TAG, 'Successfully unsubscribed from minors mode events');
      subscriber = null;
    })
    .catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `Failed to unsubscribe. Code: ${error.code}, message: ${error.message}`);
      handleSubscriptionError(error);
    });
}

/**
 * 订阅错误处理
 */
function handleSubscriptionError(error: BusinessError): void {
  switch (error.code) {
    case 1500004:  // 发送失败
      hilog.error(DOMAIN, TAG, 'Failed to send common event');
      // 可以尝试重新订阅
      setTimeout(() => {
        subscribeMinorsModeEvents();
      }, 1000);
      break;
    case 1500005:  // 订阅失败
      hilog.error(DOMAIN, TAG, 'Failed to subscribe common event');
      // 检查订阅信息配置
      break;
    case 1500007:  // 服务未启动
      hilog.error(DOMAIN, TAG, 'Common event service not started');
      // 等待服务启动后重新订阅
      break;
    case 1500008:  // 取消订阅失败
      hilog.error(DOMAIN, TAG, 'Failed to unsubscribe common event');
      // 强制清空订阅者对象
      subscriber = null;
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown subscription error: ${error.code}`);
  }
}

/**
 * 通知应用其他模块（示例）
 */
function notifyMinorsModeChanged(isOn: boolean): void {
  // 使用AppStorage或PersistentStorage通知其他组件
  // AppStorage.setOrCreate('minorsModeStatus', isOn);
  hilog.info(DOMAIN, TAG, `Notifying other modules: minors mode is ${isOn ? 'on' : 'off'}`);
}

/**
 * 刷新UI（示例）
 */
function refreshUIForMinorsMode(isOn: boolean): void {
  // 触发UI重新渲染
  // 可以使用@StorageLink或@StorageProp监听状态变化
  hilog.info(DOMAIN, TAG, `Refreshing UI for minors mode: ${isOn ? 'on' : 'off'}`);
}

/**
 * 使用示例 - 在UIAbility生命周期中调用
 */
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';

export default class MinorsModeAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'MinorsModeAbility onCreate');
    
    // 立即订阅事件
    subscribeMinorsModeEvents();
  }
  
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'MinorsModeAbility onDestroy');
    
    // 取消订阅
    unsubscribeMinorsModeEvents();
  }
}

/**
 * 使用示例 - 在页面组件中监听状态变化
 */
import { Component } from '@kit.ArkUI';

@Entry
@Component
struct MinorsModeListenerPage {
  // 使用@StorageLink监听未成年人模式状态
  @StorageLink('minorsModeStatus') minorsModeStatus: boolean = false;
  
  aboutToAppear(): void {
    // 页面加载时订阅事件（如果尚未订阅）
    // 注意：最好在Ability生命周期中订阅，避免重复订阅
  }
  
  build() {
    Column() {
      Text('未成年人模式监听示例')
        .fontSize(24)
        .margin({ top: 20 })
      
      Text(`当前状态: ${this.minorsModeStatus ? '已开启' : '已关闭'}`)
        .fontSize(20)
        .margin({ top: 10 })
      
      // 根据状态显示不同内容
      if (this.minorsModeStatus) {
        Text('未成年人模式已开启，内容已分级')
          .fontSize(16)
          .fontColor('#FF0000')
      } else {
        Text('未成年人模式已关闭，内容无限制')
          .fontSize(16)
          .fontColor('#00FF00')
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}