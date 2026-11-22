/**
 * 取消订阅示例
 * 功能：演示如何正确取消订阅账号事件
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

const LOG_TAG = 'UnsubscribeExample';
const LOG_DOMAIN = 0x0000;

// 订阅者引用
let subscriber: commonEventManager.CommonEventSubscriber | null = null;

/**
 * 基础取消订阅
 */
export function basicUnsubscribe(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Executing basic unsubscribe.');
  
  if (!subscriber) {
    hilog.warn(LOG_DOMAIN, LOG_TAG, 'Subscriber already null.');
    return;
  }
  
  commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
    if (err) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 
        `Unsubscribe failed. Code: ${err.code}, message: ${err.message}`);
      return;
    }
    
    subscriber = null;
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Unsubscribe successful.');
  });
}

/**
 * 安全取消订阅（带异常捕获）
 */
export function safeUnsubscribe(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Executing safe unsubscribe with exception handling.');
  
  if (!subscriber) {
    hilog.warn(LOG_DOMAIN, LOG_TAG, 'Subscriber is null, skipping unsubscribe.');
    return;
  }
  
  try {
    commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
      if (err) {
        handleUnsubscribeError(err);
        return;
      }
      
      cleanupAfterUnsubscribe();
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG, 
      `Exception during unsubscribe. Code: ${err.code}, message: ${err.message}`);
  }
}

/**
 * 处理取消订阅错误
 */
function handleUnsubscribeError(error: BusinessError): void {
  hilog.error(LOG_DOMAIN, LOG_TAG, `Handling unsubscribe error: ${error.code}`);
  
  switch (error.code) {
    case 401:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Invalid subscriber parameter.');
      // 强制清理引用
      subscriber = null;
      break;
      
    case 801:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Capability not supported.');
      subscriber = null;
      break;
      
    case 1500007:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Service communication failed.');
      // 服务异常，稍后重试
      retryUnsubscribe();
      break;
      
    case 1500008:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Service initialization failed.');
      subscriber = null;
      break;
      
    default:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Unknown error.');
      subscriber = null;
  }
}

/**
 * 取消订阅后清理
 */
function cleanupAfterUnsubscribe(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Cleaning up after unsubscribe.');
  
  // 1. 清理订阅者引用
  subscriber = null;
  
  // 2. 清理相关状态
  clearSubscriptionState();
  
  // 3. 通知相关组件
  notifyUnsubscribeComplete();
  
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Cleanup complete.');
}

/**
 * 清理订阅状态
 */
function clearSubscriptionState(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Clearing subscription state.');
  // 实际应用中可清理全局状态管理器中的订阅状态
}

/**
 * 通知取消订阅完成
 */
function notifyUnsubscribeComplete(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Notifying unsubscribe completion.');
  // 实际应用中可发送事件或更新UI
}

/**
 * 重试取消订阅
 */
function retryUnsubscribe(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Scheduling unsubscribe retry.');
  
  setTimeout(() => {
    if (subscriber) {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Retrying unsubscribe.');
      safeUnsubscribe();
    }
  }, 2000);
}

/**
 * 带确认的取消订阅
 */
export function unsubscribeWithConfirmation(callback: (success: boolean) => void): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Executing unsubscribe with confirmation callback.');
  
  if (!subscriber) {
    hilog.warn(LOG_DOMAIN, LOG_TAG, 'No active subscriber.');
    callback(false);
    return;
  }
  
  try {
    commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
      if (err) {
        hilog.error(LOG_DOMAIN, LOG_TAG, 
          `Unsubscribe failed. Code: ${err.code}, message: ${err.message}`);
        subscriber = null;
        callback(false);
        return;
      }
      
      subscriber = null;
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Unsubscribe successful with confirmation.');
      callback(true);
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG, `Exception: ${err.message}`);
    subscriber = null;
    callback(false);
  }
}

/**
 * 强制取消订阅
 * 用于清理无效订阅者
 */
export function forceUnsubscribe(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Executing force unsubscribe.');
  
  // 直接清理引用，不调用API
  if (subscriber) {
    subscriber = null;
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Subscriber reference forcefully cleared.');
  }
  
  clearSubscriptionState();
}

/**
 * 批量取消订阅
 * 用于取消多个订阅者
 */
export function batchUnsubscribe(subscribers: commonEventManager.CommonEventSubscriber[]): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, `Batch unsubscribing ${subscribers.length} subscribers.`);
  
  subscribers.forEach((sub, index) => {
    try {
      commonEventManager.unsubscribe(sub, (err: BusinessError) => {
        if (err) {
          hilog.error(LOG_DOMAIN, LOG_TAG, 
            `Failed to unsubscribe #${index}. Code: ${err.code}`);
        } else {
          hilog.info(LOG_DOMAIN, LOG_TAG, `Successfully unsubscribed #${index}`);
        }
      });
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Exception for subscriber #${index}`);
    }
  });
}

/**
 * 检查订阅状态
 */
export function checkSubscriptionStatus(): boolean {
  const isActive = subscriber !== null;
  hilog.info(LOG_DOMAIN, LOG_TAG, `Subscription active: ${isActive}`);
  return isActive;
}

/**
 * 页面生命周期中使用示例
 * 
 * @Entry
 * @Component
 * struct MyPage {
 *   private isSubscribed: boolean = false;
 *   
 *   aboutToAppear() {
 *     // 初始化订阅
 *     this.isSubscribed = true;
 *   }
 *   
 *   aboutToDisappear() {
 *     // 页面销毁时取消订阅
 *     if (this.isSubscribed) {
 *       unsubscribeWithConfirmation((success) => {
 *         this.isSubscribed = !success;
 *       });
 *     }
 *   }
 *   
 *   build() {
 *     Column() {
 *       Button('取消订阅')
 *         .onClick(() => {
 *           safeUnsubscribe();
 *         })
 *     }
 *   }
 * }
 */