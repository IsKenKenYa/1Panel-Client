/**
 * 监听系统时制变化示例
 * 功能：订阅和取消订阅系统时制变化事件
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

// 订阅者对象，用于管理和取消订阅
let timeSubscriber: commonEventManager.CommonEventSubscriber | null = null;

/**
 * 监听系统时制变化
 * @param callback - 时制变化时的回调函数
 */
export function subscribeTimeChange(callback?: TimeChangeCallback): void {
  try {
    const timeSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_TIME_CHANGED]
    };
    
    commonEventManager.createSubscriber(timeSubscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        console.info('[I18n] 创建时制变化订阅者成功');
        timeSubscriber = commonEventSubscriber;
        
        commonEventManager.subscribe(timeSubscriber, (err, data) => {
          if (err) {
            console.error(`[I18n] 订阅事件失败, 错误码: ${err.code}, 消息: ${err.message}`);
            return;
          }
          
          // 区分系统时间和系统时制变化
          if (data.data !== undefined && data.data === '24HourChange') {
            console.info('[I18n] 系统时制发生变化');
            
            const newIs24HourClock = i18n.System.is24HourClock();
            console.info(`[I18n] 新的时制设置: ${newIs24HourClock ? '24小时制' : '12小时制'}`);
            
            // 执行回调函数（如果提供）
            if (callback) {
              callback(newIs24HourClock);
            }
          }
        });
      })
      .catch((err: BusinessError) => {
        console.error(`[I18n] 创建订阅者失败, 错误码: ${err.code}, 消息: ${err.message}`);
        handleSubscribeError(err);
      });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[I18n] 监听时制变化异常, 错误码: ${err.code}, 消息: ${err.message}`);
    handleSubscribeError(err);
  }
}

/**
 * 取消监听系统时制变化
 */
export function unsubscribeTimeChange(): void {
  if (timeSubscriber !== null) {
    try {
      commonEventManager.unsubscribe(timeSubscriber, (err) => {
        if (err) {
          console.error(`[I18n] 取消订阅失败, 错误码: ${err.code}, 消息: ${err.message}`);
        } else {
          console.info('[I18n] 取消订阅成功');
          timeSubscriber = null;
        }
      });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[I18n] 取消订阅异常, 错误码: ${err.code}, 消息: ${err.message}`);
      handleSubscribeError(err);
    }
  } else {
    console.warn('[I18n] 订阅者不存在，无需取消订阅');
  }
}

/**
 * 检查订阅状态
 * @returns boolean - 是否已订阅
 */
export function isSubscribed(): boolean {
  return timeSubscriber !== null;
}

/**
 * 处理订阅相关错误
 * @param error - BusinessError错误对象
 */
function handleSubscribeError(error: BusinessError): void {
  switch (error.code) {
    case 16000050:
      console.error('[I18n] CommonEvent服务内部错误，建议重试');
      break;
    case 16000051:
      console.error('[I18n] 事件订阅失败，检查订阅信息配置');
      break;
    case 401:
      console.error('[I18n] 参数错误，检查订阅配置参数');
      break;
    default:
      console.error(`[I18n] 订阅异常: 错误码 ${error.code}, 消息: ${error.message}`);
  }
}

/**
 * 时制变化回调函数类型
 */
export type TimeChangeCallback = (is24HourClock: boolean) => void;

// 使用示例：监听时制变化并打印日志
function exampleSubscribe(): void {
  console.info('[I18n] 开始监听系统时制变化...');
  
  subscribeTimeChange((is24HourClock: boolean) => {
    console.info(`[I18n] 回调触发 - 新时制: ${is24HourClock ? '24小时制' : '12小时制'}`);
  });
}

// 使用示例：取消监听
function exampleUnsubscribe(): void {
  console.info('[I18n] 取消监听系统时制变化...');
  unsubscribeTimeChange();
}

// 导出示例函数供外部调用
export { exampleSubscribe, exampleUnsubscribe };