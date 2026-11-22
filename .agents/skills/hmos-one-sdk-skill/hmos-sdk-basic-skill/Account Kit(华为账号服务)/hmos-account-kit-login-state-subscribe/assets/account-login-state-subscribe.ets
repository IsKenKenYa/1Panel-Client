/**
 * 订阅华为账号登录/登出事件完整示例
 * 功能：订阅账号登录和登出事件，处理事件回调
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

const LOG_TAG = 'AccountLoginState';
const LOG_DOMAIN = 0x0000;

// 订阅者信息配置
const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [
    commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN,
    commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT
  ]
};

// 定义订阅者对象（必须定义在全局作用域）
let subscriber: commonEventManager.CommonEventSubscriber | null = null;

// 账号状态管理
interface AccountState {
  isLoggedIn: boolean;
  lastEventTime: number;
  eventData: commonEventManager.CommonEventData | null;
}

let accountState: AccountState = {
  isLoggedIn: false,
  lastEventTime: 0,
  eventData: null
};

/**
 * 初始化账号事件订阅
 * 在应用前台启动时调用
 */
export function initAccountEventSubscription(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Initializing account event subscription.');
  
  try {
    // 创建订阅者
    commonEventManager.createSubscriber(subscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        subscriber = commonEventSubscriber;
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Subscriber created successfully.');
        
        // 订阅公共事件
        subscribeToAccountEvents();
      })
      .catch((err: BusinessError) => {
        hilog.error(LOG_DOMAIN, LOG_TAG, 
          `Failed to create subscriber. Code: ${err.code}, message: ${err.message}`);
        handleSubscriptionError(err);
      });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG, 
      `Exception during subscriber creation. Code: ${err.code}, message: ${err.message}`);
  }
}

/**
 * 订阅账号事件
 */
function subscribeToAccountEvents(): void {
  if (!subscriber) {
    hilog.error(LOG_DOMAIN, LOG_TAG, 'Subscriber is null, cannot subscribe.');
    return;
  }
  
  try {
    commonEventManager.subscribe(subscriber, 
      (error: BusinessError, data: commonEventManager.CommonEventData) => {
        if (error) {
          hilog.error(LOG_DOMAIN, LOG_TAG,
            `Failed to subscribe. Code: ${error.code}, message: ${error.message}`);
          handleSubscriptionError(error);
          return;
        }
        
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Successfully subscribed to account events.');
        processAccountEvent(data);
      });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG, 
      `Exception during subscription. Code: ${err.code}, message: ${err.message}`);
  }
}

/**
 * 处理账号事件
 */
function processAccountEvent(data: commonEventManager.CommonEventData): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, `Received event: ${data.event}`);
  
  // 更新账号状态
  accountState.lastEventTime = Date.now();
  accountState.eventData = data;
  
  // 处理登录事件
  if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
    accountState.isLoggedIn = true;
    handleAccountLoginEvent(data);
  }
  
  // 处理登出事件
  if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
    accountState.isLoggedIn = false;
    handleAccountLogoutEvent(data);
  }
}

/**
 * 处理账号登录事件
 */
function handleAccountLoginEvent(data: commonEventManager.CommonEventData): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Account login event received.');
  
  // 执行登录后业务逻辑
  onAccountLoginSuccess(data);
  
  // 示例：更新UI、同步用户数据、启动服务
  updateUIForLoggedInState();
  syncUserDataAfterLogin();
  startLoggedInServices();
}

/**
 * 处理账号登出事件
 */
function handleAccountLogoutEvent(data: commonEventManager.CommonEventData): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Account logout event received.');
  
  // 执行登出后业务逻辑
  onAccountLogoutSuccess(data);
  
  // 示例：清理数据、停止服务、更新UI
  clearUserDataAfterLogout();
  stopLoggedInServices();
  updateUIForLoggedOutState();
}

/**
 * 登录成功回调（可自定义）
 */
function onAccountLoginSuccess(data: commonEventManager.CommonEventData): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Executing login success callback.');
  // 开发者可在此添加自定义业务逻辑
}

/**
 * 登出成功回调（可自定义）
 */
function onAccountLogoutSuccess(data: commonEventManager.CommonEventData): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Executing logout success callback.');
  // 开发者可在此添加自定义业务逻辑
}

/**
 * 更新UI为登录状态
 */
function updateUIForLoggedInState(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Updating UI for logged in state.');
  // 示例：显示用户信息、启用登录后功能
}

/**
 * 更新UI为登出状态
 */
function updateUIForLoggedOutState(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Updating UI for logged out state.');
  // 示例：隐藏用户信息、禁用登录后功能
}

/**
 * 登录后同步用户数据
 */
function syncUserDataAfterLogin(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Syncing user data after login.');
  // 示例：从服务器同步用户数据
}

/**
 * 登出后清理用户数据
 */
function clearUserDataAfterLogout(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Clearing user data after logout.');
  // 示例：清除本地缓存的用户数据
}

/**
 * 启动登录后服务
 */
function startLoggedInServices(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Starting services for logged in user.');
  // 示例：启动推送服务、数据同步服务等
}

/**
 * 停止登录后服务
 */
function stopLoggedInServices(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Stopping services for logged out user.');
  // 示例：停止推送服务、数据同步服务等
}

/**
 * 处理订阅错误
 */
function handleSubscriptionError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Parameter error. Check subscription info.');
      break;
    case 801:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Capability not supported on this device.');
      break;
    case 1500007:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to send message to common event service.');
      // 尝试重新订阅
      retrySubscription();
      break;
    case 1500008:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to initialize common event service.');
      break;
    case 1500010:
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Subscriber count exceeded system limit.');
      break;
    default:
      hilog.error(LOG_DOMAIN, LOG_TAG, `Unknown error: ${error.code}`);
  }
}

/**
 * 重试订阅
 */
function retrySubscription(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Retrying subscription after delay.');
  setTimeout(() => {
    initAccountEventSubscription();
  }, 3000);
}

/**
 * 取消订阅账号事件
 * 在应用退出或不需要监听时调用
 */
export function unsubscribeAccountEvents(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Unsubscribing account events.');
  
  if (!subscriber) {
    hilog.warn(LOG_DOMAIN, LOG_TAG, 'Subscriber is null, nothing to unsubscribe.');
    return;
  }
  
  try {
    commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
      if (err) {
        hilog.error(LOG_DOMAIN, LOG_TAG,
          `Failed to unsubscribe. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      
      // 清理订阅者对象，避免内存泄漏
      subscriber = null;
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Successfully unsubscribed.');
      
      // 重置账号状态
      accountState.isLoggedIn = false;
      accountState.eventData = null;
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG,
      `Exception during unsubscription. Code: ${err.code}, message: ${err.message}`);
  }
}

/**
 * 获取当前账号状态
 */
export function getAccountState(): AccountState {
  return accountState;
}

/**
 * 检查是否已登录
 */
export function isAccountLoggedIn(): boolean {
  return accountState.isLoggedIn;
}

/**
 * 使用示例
 * 
 * 在页面组件中使用：
 * 
 * @Entry
 * @Component
 * struct MainPage {
 *   aboutToAppear() {
 *     // 页面显示时初始化订阅
 *     initAccountEventSubscription();
 *   }
 *   
 *   aboutToDisappear() {
 *     // 页面消失时取消订阅
 *     unsubscribeAccountEvents();
 *   }
 *   
 *   build() {
 *     Column() {
 *       if (isAccountLoggedIn()) {
 *         Text('已登录')
 *       } else {
 *         Text('未登录')
 *       }
 *     }
 *   }
 * }
 */