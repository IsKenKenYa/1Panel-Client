/**
 * 订阅华为账号的登录/登出事件 - 带降级方案的完整示例代码
 * 
 * 功能说明：
 * 本示例展示如何订阅华为账号登录/登出广播事件，并提供降级方案。
 * 当订阅失败或事件未触发时，使用getHuaweiIDState接口主动查询账号状态。
 * 
 * 适用场景：
 * - 订阅失败需要降级处理的场景
 * - 事件未触发需要主动查询的场景
 * - 系统服务异常需要备用方案的场景
 * 
 * 注意事项：
 * 1. getHuaweiIDState需要API version 12+支持
 * 2. 需要通过华为账号登录接口获取UnionID或OpenID
 * 3. 需要导入@kit.AccountKit模块
 * 4. getHuaweiIDState为异步接口，使用Promise回调
 * 
 * API版本要求：
 * - commonEventManager: API version 9+
 * - authentication.getHuaweiIDState: API version 12+
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import { authentication } from '@kit.AccountKit';

// 常量定义
const TAG = 'AccountLoginStateFallback';
const DOMAIN = 0x0000;

// 订阅者信息配置
const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [
    commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN,
    commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT
  ]
};

// 定义订阅者（全局作用域，避免生命周期问题）
let subscriber: commonEventManager.CommonEventSubscriber | null = null;

// 应用状态标志
let isSubscribed: boolean = false;
let isFallbackActive: boolean = false;

/**
 * 主方案：创建订阅者并订阅事件
 */
async function initAccountStateMonitor(): Promise<void> {
  hilog.info(DOMAIN, TAG, 'Initializing account state monitor...');
  
  try {
    // 尝试创建订阅者
    subscriber = await commonEventManager.createSubscriber(subscribeInfo);
    hilog.info(DOMAIN, TAG, 'Succeeded in creating subscriber.');
    
    // 尝试订阅事件
    await commonEventManager.subscribeToEvent(subscriber, 
      (data: commonEventManager.CommonEventData) => {
        hilog.info(DOMAIN, TAG, `Received common event: ${data.event}`);
        
        // 处理事件
        handleCommonEvent(data);
      });
    
    hilog.info(DOMAIN, TAG, 'Succeeded to subscribe.');
    isSubscribed = true;
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, 
      `Failed to initialize monitor. Code: ${err.code}, message: ${err.message}`);
    
    // 启用降级方案
    enableFallbackMethod(err);
  }
}

/**
 * 降级方案：使用getHuaweiIDState主动查询账号状态
 * 
 * 说明：
 * 当订阅失败或事件未触发时，使用getHuaweiIDState接口主动查询账号登录状态。
 * 可定时查询或在关键业务节点查询。
 * 
 * 参数：
 * - unionId: string：UnionID（通过华为账号登录接口获取）
 */
async function queryAccountState(unionId: string): Promise<void> {
  hilog.info(DOMAIN, TAG, 'Querying account state using getHuaweiIDState...');
  
  const stateRequest: authentication.StateRequest = {
    idType: authentication.IdType.UNION_ID,
    idValue: unionId
  };
  
  try {
    const data: authentication.StateResult = 
      await new authentication.HuaweiIDProvider().getHuaweiIDState(stateRequest);
    
    hilog.info(DOMAIN, TAG, `Succeeded in getting huaweiIdState. State: ${data.state}`);
    
    // 根据状态执行业务逻辑
    if (data.state) {
      // 账号已登录
      handleAccountLogin();
    } else {
      // 账号已登出
      handleAccountLogout();
    }
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, 
      `Failed to get huaweiIdState. Code: ${err.code}, message: ${err.message}`);
    
    // 处理getHuaweiIDState错误
    handleGetHuaweiIDStateError(err);
  }
}

/**
 * 启用降级方案
 * 
 * 说明：
 * 当主方案（订阅事件）失败时，启用降级方案（主动查询）。
 * 
 * 参数：
 * - error: BusinessError：主方案失败的错误对象
 */
function enableFallbackMethod(error: BusinessError): void {
  hilog.warn(DOMAIN, TAG, 'Enabling fallback method due to subscribe failure.');
  
  isFallbackActive = true;
  isSubscribed = false;
  
  // 根据错误类型提示用户
  switch (error.code) {
    case 801:
      // 能力不支持，建议使用主动查询
      hilog.warn(DOMAIN, TAG, 
        'Capability not supported. Using fallback method: manual query.');
      break;
    case 1500007:
      // 发送消息失败，建议稍后重试订阅或使用主动查询
      hilog.warn(DOMAIN, TAG, 
        'Failed to send message. Using fallback method: manual query.');
      break;
    case 1500008:
      // 初始化失败，建议检查系统状态或使用主动查询
      hilog.warn(DOMAIN, TAG, 
        'Failed to initialize service. Using fallback method: manual query.');
      break;
    case 1500010:
      // 订阅者数量超限，建议使用主动查询
      hilog.warn(DOMAIN, TAG, 
        'Subscriber count exceeded. Using fallback method: manual query.');
      break;
    default:
      hilog.warn(DOMAIN, TAG, 
        'Unknown error. Using fallback method: manual query.');
  }
  
  // 提示用户使用主动查询方式
  showFallbackMethodTip();
}

/**
 * 定时查询账号状态（降级方案）
 * 
 * 说明：
 * 在降级方案启用后，可定时查询账号状态，替代订阅事件。
 * 
 * 参数：
 * - unionId: string：UnionID
 * - intervalMs: number：查询间隔（毫秒），默认60000（1分钟）
 */
function startPeriodicQuery(unionId: string, intervalMs: number = 60000): void {
  hilog.info(DOMAIN, TAG, 
    `Starting periodic account state query. Interval: ${intervalMs}ms`);
  
  // 立即查询一次
  queryAccountState(unionId);
  
  // 定时查询
  const timer = setInterval(() => {
    if (isFallbackActive && !isSubscribed) {
      queryAccountState(unionId);
    } else {
      // 订阅成功，停止定时查询
      clearInterval(timer);
      hilog.info(DOMAIN, TAG, 'Subscription restored, stopping periodic query.');
    }
  }, intervalMs);
}

/**
 * 尝试恢复主方案（重新订阅）
 * 
 * 说明：
 * 在降级方案启用后，可尝试重新订阅事件，恢复主方案。
 */
async function retrySubscription(): Promise<void> {
  hilog.info(DOMAIN, TAG, 'Retrying subscription to restore main method...');
  
  try {
    // 重新创建订阅者
    subscriber = await commonEventManager.createSubscriber(subscribeInfo);
    
    // 重新订阅
    await commonEventManager.subscribeToEvent(subscriber, 
      (data: commonEventManager.CommonEventData) => {
        handleCommonEvent(data);
      });
    
    hilog.info(DOMAIN, TAG, 'Succeeded to restore subscription.');
    
    // 更新状态标志
    isSubscribed = true;
    isFallbackActive = false;
    
    // 提示用户订阅恢复
    showSubscriptionRestoredTip();
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, 
      `Failed to retry subscription. Code: ${err.code}, message: ${err.message}`);
    
    // 继续使用降级方案
    hilog.warn(DOMAIN, TAG, 'Continuing with fallback method.');
  }
}

/**
 * 处理公共事件
 * 
 * 参数：
 * - data: CommonEventData：公共事件数据
 */
function handleCommonEvent(data: commonEventManager.CommonEventData): void {
  hilog.info(DOMAIN, TAG, `Handling common event: ${data.event}`);
  
  if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
    handleAccountLogin();
  }
  
  if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
    handleAccountLogout();
  }
}

/**
 * 处理账号登录逻辑
 */
function handleAccountLogin(): void {
  hilog.info(DOMAIN, TAG, 'Handling account login logic.');
  updateLoginUIState(true);
  syncAccountInfoToBackend();
}

/**
 * 处理账号登出逻辑
 */
function handleAccountLogout(): void {
  hilog.info(DOMAIN, TAG, 'Handling account logout logic.');
  updateLoginUIState(false);
  clearUserData();
}

/**
 * 更新登录UI状态
 */
function updateLoginUIState(isLoggedIn: boolean): void {
  hilog.info(DOMAIN, TAG, `Updating login UI state: ${isLoggedIn}`);
}

/**
 * 同步账号信息到后端
 */
function syncAccountInfoToBackend(): void {
  hilog.info(DOMAIN, TAG, 'Syncing account info to backend.');
}

/**
 * 清除用户数据
 */
function clearUserData(): void {
  hilog.info(DOMAIN, TAG, 'Clearing user data.');
}

/**
 * 处理getHuaweiIDState错误
 * 
 * 参数：
 * - error: BusinessError：错误对象
 */
function handleGetHuaweiIDStateError(error: BusinessError): void {
  hilog.error(DOMAIN, TAG, 
    `getHuaweiIDState error. Code: ${error.code}, message: ${error.message}`);
  
  switch (error.code) {
    case 12300001:
      // 系统服务异常
      hilog.error(DOMAIN, TAG, 
        'System service works abnormally. Please retry later.');
      showSystemErrorTip();
      break;
    case 1001502001:
      // 用户未登录华为账号
      hilog.error(DOMAIN, TAG, 'User has not logged in with HUAWEI ID.');
      showUserNotLoggedInTip();
      break;
    case 1001502003:
      // 输入参数值无效
      hilog.error(DOMAIN, TAG, 'Invalid input parameter value.');
      break;
    case 1001502005:
      // 网络错误
      hilog.error(DOMAIN, TAG, 'Network error. Please check network status.');
      showNetworkErrorTip();
      break;
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error occurred.');
  }
}

/**
 * 取消订阅公共事件
 */
function unsubscribeEvents(): void {
  if (!subscriber) {
    hilog.warn(DOMAIN, TAG, 'Subscriber is null, no need to unsubscribe.');
    return;
  }
  
  try {
    commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN, TAG,
          `Failed to unsubscribe. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      
      subscriber = null;
      isSubscribed = false;
      hilog.info(DOMAIN, TAG, 'Succeeded in unsubscribing.');
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, 
      `Failed to unsubscribe. Code: ${err.code}, message: ${err.message}`);
  }
}

/**
 * UI提示函数
 */
function showFallbackMethodTip(): void {
  hilog.info(DOMAIN, TAG, 
    'Fallback method enabled: Use manual query to check account state.');
}

function showSubscriptionRestoredTip(): void {
  hilog.info(DOMAIN, TAG, 'Subscription restored successfully.');
}

function showSystemErrorTip(): void {
  hilog.error(DOMAIN, TAG, 'System service error. Please retry later.');
}

function showUserNotLoggedInTip(): void {
  hilog.warn(DOMAIN, TAG, 'Please login with HUAWEI ID first.');
}

function showNetworkErrorTip(): void {
  hilog.error(DOMAIN, TAG, 'Network error. Please check network connection.');
}

/**
 * 页面入口组件示例（带降级方案）
 */
@Entry
@Component
struct AccountLoginStateFallbackPage {
  
  // UnionID示例（实际应通过华为账号登录接口获取）
  private unionId: string = '<your_union_id_here>';
  
  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'Page about to appear.');
    
    // 初始化账号状态监控（包含降级方案）
    initAccountStateMonitor();
  }
  
  aboutToDisappear(): void {
    hilog.info(DOMAIN, TAG, 'Page about to disappear.');
    unsubscribeEvents();
  }
  
  build() {
    Column() {
      Text('Account Login State with Fallback')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
      
      Text('This page demonstrates subscription with fallback method.')
        .fontSize(16)
        .margin({ bottom: 20 })
      
      // 显示当前状态
      Text(`Subscription Status: ${isSubscribed ? 'Active' : 'Inactive'}`)
        .fontSize(14)
        .margin({ bottom: 10 })
      
      Text(`Fallback Status: ${isFallbackActive ? 'Active' : 'Inactive'}`)
        .fontSize(14)
        .margin({ bottom: 10 })
      
      // 主方案按钮
      Button('Initialize Monitor')
        .fontSize(16)
        .margin({ top: 20 })
        .onClick(() => {
          initAccountStateMonitor();
        })
      
      // 降级方案按钮：主动查询
      Button('Query Account State')
        .fontSize(16)
        .margin({ top: 10 })
        .onClick(() => {
          if (this.unionId) {
            queryAccountState(this.unionId);
          } else {
            hilog.warn(DOMAIN, TAG, 'UnionID is required for query.');
          }
        })
      
      // 降级方案按钮：启动定时查询
      Button('Start Periodic Query')
        .fontSize(16)
        .margin({ top: 10 })
        .onClick(() => {
          if (this.unionId) {
            startPeriodicQuery(this.unionId);
          } else {
            hilog.warn(DOMAIN, TAG, 'UnionID is required for periodic query.');
          }
        })
      
      // 恢复主方案按钮
      Button('Retry Subscription')
        .fontSize(16)
        .margin({ top: 10 })
        .onClick(() => {
          retrySubscription();
        })
      
      // 取消订阅按钮
      Button('Unsubscribe')
        .fontSize(16)
        .margin({ top: 10 })
        .onClick(() => {
          unsubscribeEvents();
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}