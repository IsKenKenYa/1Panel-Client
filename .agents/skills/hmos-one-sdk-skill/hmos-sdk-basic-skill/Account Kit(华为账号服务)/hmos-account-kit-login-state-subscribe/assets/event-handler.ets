/**
 * 事件处理示例
 * 功能：演示如何处理账号登录/登出事件的各种场景
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

const LOG_TAG = 'EventHandler';
const LOG_DOMAIN = 0x0000;

/**
 * 事件处理器接口
 */
interface AccountEventHandler {
  onLogin: (data: commonEventManager.CommonEventData) => void;
  onLogout: (data: commonEventManager.CommonEventData) => void;
  onError: (error: BusinessError) => void;
}

/**
 * 默认事件处理器
 */
const defaultHandler: AccountEventHandler = {
  onLogin: (data: commonEventManager.CommonEventData) => {
    hilog.info(LOG_DOMAIN, LOG_TAG, `Login event data: ${JSON.stringify(data)}`);
  },
  onLogout: (data: commonEventManager.CommonEventData) => {
    hilog.info(LOG_DOMAIN, LOG_TAG, `Logout event data: ${JSON.stringify(data)}`);
  },
  onError: (error: BusinessError) => {
    hilog.error(LOG_DOMAIN, LOG_TAG, `Error: ${error.code} - ${error.message}`);
  }
};

/**
 * 创建事件处理器
 */
export function createAccountEventHandler(customHandler?: Partial<AccountEventHandler>): AccountEventHandler {
  return {
    onLogin: customHandler?.onLogin || defaultHandler.onLogin,
    onLogout: customHandler?.onLogout || defaultHandler.onLogout,
    onError: customHandler?.onError || defaultHandler.onError
  };
}

/**
 * 处理事件数据
 */
export function processEventData(data: commonEventManager.CommonEventData, handler: AccountEventHandler): void {
  // 验证事件数据
  if (!data || !data.event) {
    hilog.warn(LOG_DOMAIN, LOG_TAG, 'Invalid event data received.');
    return;
  }
  
  hilog.info(LOG_DOMAIN, LOG_TAG, `Processing event: ${data.event}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event code: ${data.code}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event data: ${data.data}`);
  
  // 分发事件到对应处理器
  if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
    handler.onLogin(data);
  } else if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
    handler.onLogout(data);
  } else {
    hilog.warn(LOG_DOMAIN, LOG_TAG, `Unknown event type: ${data.event}`);
  }
}

/**
 * 登录事件详细处理示例
 */
export function handleLoginEventDetailed(data: commonEventManager.CommonEventData): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, '=== Login Event Detailed Processing ===');
  
  // 1. 记录事件时间戳
  const eventTime = Date.now();
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event received at: ${new Date(eventTime).toISOString()}`);
  
  // 2. 提取事件参数
  const eventId = data.event;
  const eventCode = data.code || 0;
  const eventDataStr = data.data || '';
  
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event ID: ${eventId}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Code: ${eventCode}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Data: ${eventDataStr}`);
  
  // 3. 执行业务逻辑
  updateLoginState(true);
  notifyLoginSuccess();
  startLoginSession();
}

/**
 * 登出事件详细处理示例
 */
export function handleLogoutEventDetailed(data: commonEventManager.CommonEventData): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, '=== Logout Event Detailed Processing ===');
  
  // 1. 记录事件时间戳
  const eventTime = Date.now();
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event received at: ${new Date(eventTime).toISOString()}`);
  
  // 2. 提取事件参数
  const eventId = data.event;
  const eventCode = data.code || 0;
  const eventDataStr = data.data || '';
  
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event ID: ${eventId}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Code: ${eventCode}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Data: ${eventDataStr}`);
  
  // 3. 执行业务逻辑
  updateLoginState(false);
  notifyLogoutSuccess();
  endLoginSession();
}

/**
 * 更新登录状态
 */
function updateLoginState(isLoggedIn: boolean): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, `Updating login state to: ${isLoggedIn}`);
  // 实际应用中可更新全局状态管理器
}

/**
 * 通知登录成功
 */
function notifyLoginSuccess(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Notifying login success.');
  // 实际应用中可发送通知或更新UI
}

/**
 * 通知登出成功
 */
function notifyLogoutSuccess(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Notifying logout success.');
  // 实际应用中可发送通知或更新UI
}

/**
 * 启动登录会话
 */
function startLoginSession(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Starting login session.');
  // 实际应用中可启动需要登录的服务
}

/**
 * 结束登录会话
 */
function endLoginSession(): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, 'Ending login session.');
  // 实际应用中可停止需要登录的服务
}

/**
 * 错误处理示例
 */
export function handleEventError(error: BusinessError): void {
  hilog.error(LOG_DOMAIN, LOG_TAG, `=== Error Handling ===`);
  hilog.error(LOG_DOMAIN, LOG_TAG, `Error code: ${error.code}`);
  hilog.error(LOG_DOMAIN, LOG_TAG, `Error message: ${error.message}`);
  
  // 根据错误码执行不同处理
  switch (error.code) {
    case 401:
      handleParameterError(error);
      break;
    case 1500007:
      handleServiceError(error);
      break;
    case 1500010:
      handleLimitError(error);
      break;
    default:
      handleUnknownError(error);
  }
}

/**
 * 处理参数错误
 */
function handleParameterError(error: BusinessError): void {
  hilog.error(LOG_DOMAIN, LOG_TAG, 'Parameter error detected.');
  hilog.error(LOG_DOMAIN, LOG_TAG, 'Possible causes: missing required params or invalid types.');
  // 建议：检查订阅信息配置
}

/**
 * 处理服务错误
 */
function handleServiceError(error: BusinessError): void {
  hilog.error(LOG_DOMAIN, LOG_TAG, 'Service communication error.');
  hilog.error(LOG_DOMAIN, LOG_TAG, 'Common event service may be unavailable.');
  // 建议：等待服务恢复后重试
}

/**
 * 处理限制错误
 */
function handleLimitError(error: BusinessError): void {
  hilog.error(LOG_DOMAIN, LOG_TAG, 'System limit exceeded.');
  hilog.error(LOG_DOMAIN, LOG_TAG, 'Too many subscribers registered.');
  // 建议：取消其他订阅或等待资源释放
}

/**
 * 处理未知错误
 */
function handleUnknownError(error: BusinessError): void {
  hilog.error(LOG_DOMAIN, LOG_TAG, 'Unknown error encountered.');
  hilog.error(LOG_DOMAIN, LOG_TAG, 'Please check system logs for more details.');
  // 建议：记录详细日志以便分析
}

/**
 * 使用示例
 * 
 * const handler = createAccountEventHandler({
 *   onLogin: (data) => {
 *     console.log('Custom login handler');
 *   },
 *   onLogout: (data) => {
 *     console.log('Custom logout handler');
 *   }
 * });
 */