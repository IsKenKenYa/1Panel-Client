/**
 * 用户偏好完整功能示例
 * 功能：获取用户偏好设置 + 监听时制变化 + UI更新
 * 适用场景：国际化应用开发、时间显示、本地数字处理
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

// ==================== 数据结构定义 ====================

/**
 * 用户偏好数据结构
 */
export interface UserPreferences {
  usingLocalDigit: boolean;
  is24HourClock: boolean;
  timestamp: number;
}

/**
 * 时制变化回调函数类型
 */
export type TimeChangeCallback = (is24HourClock: boolean) => void;

// ==================== 状态管理 ====================

// 订阅者对象，用于管理和取消订阅
let timeSubscriber: commonEventManager.CommonEventSubscriber | null = null;

// 当前用户偏好状态（可扩展为响应式状态）
let currentPreferences: UserPreferences = {
  usingLocalDigit: false,
  is24HourClock: false,
  timestamp: 0
};

// ==================== 核心功能函数 ====================

/**
 * 初始化用户偏好管理器
 * 获取当前偏好设置并开始监听变化
 * @param timeChangeCallback - 时制变化回调（可选）
 */
export function initUserPreferencesManager(timeChangeCallback?: TimeChangeCallback): void {
  console.info('[UserPreferences] 初始化用户偏好管理器...');
  
  // 获取当前偏好设置
  currentPreferences = getUserPreferences();
  console.info('[UserPreferences] 当前偏好:', currentPreferences);
  
  // 开始监听时制变化
  subscribeTimeChange((is24HourClock: boolean) => {
    currentPreferences.is24HourClock = is24HourClock;
    currentPreferences.timestamp = Date.now();
    
    console.info('[UserPreferences] 时制已更新:', currentPreferences);
    
    // 执行回调
    if (timeChangeCallback) {
      timeChangeCallback(is24HourClock);
    }
  });
}

/**
 * 销毁用户偏好管理器
 * 取消监听并清理资源
 */
export function destroyUserPreferencesManager(): void {
  console.info('[UserPreferences] 销毁用户偏好管理器...');
  unsubscribeTimeChange();
  currentPreferences = {
    usingLocalDigit: false,
    is24HourClock: false,
    timestamp: 0
  };
}

/**
 * 获取当前用户偏好状态
 * @returns UserPreferences - 用户偏好对象
 */
export function getCurrentPreferences(): UserPreferences {
  return currentPreferences;
}

/**
 * 刷新用户偏好设置（手动更新）
 * @returns UserPreferences - 最新用户偏好对象
 */
export function refreshUserPreferences(): UserPreferences {
  console.info('[UserPreferences] 手动刷新用户偏好...');
  currentPreferences = getUserPreferences();
  return currentPreferences;
}

// ==================== 基础功能函数 ====================

/**
 * 获取系统是否使用本地数字
 * @returns boolean - true表示使用本地数字，false表示不使用
 */
function getLocalDigitStatus(): boolean {
  try {
    const usingLocalDigit: boolean = i18n.System.getUsingLocalDigit();
    console.info(`[UserPreferences] 系统本地数字: ${usingLocalDigit}`);
    return usingLocalDigit;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[UserPreferences] 获取本地数字失败: ${err.code} - ${err.message}`);
    return false;
  }
}

/**
 * 获取系统时制
 * @returns boolean - true表示24小时制，false表示12小时制
 */
function getTimeFormat(): boolean {
  try {
    const is24HourClock: boolean = i18n.System.is24HourClock();
    console.info(`[UserPreferences] 系统时制: ${is24HourClock ? '24小时制' : '12小时制'}`);
    return is24HourClock;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[UserPreferences] 获取时制失败: ${err.code} - ${err.message}`);
    return false;
  }
}

/**
 * 获取完整的用户偏好信息
 * @returns UserPreferences - 用户偏好对象
 */
function getUserPreferences(): UserPreferences {
  const usingLocalDigit = getLocalDigitStatus();
  const is24HourClock = getTimeFormat();
  
  return {
    usingLocalDigit: usingLocalDigit,
    is24HourClock: is24HourClock,
    timestamp: Date.now()
  };
}

// ==================== 监听功能函数 ====================

/**
 * 监听系统时制变化
 * @param callback - 时制变化时的回调函数
 */
function subscribeTimeChange(callback?: TimeChangeCallback): void {
  if (timeSubscriber !== null) {
    console.warn('[UserPreferences] 已存在订阅，先取消旧订阅');
    unsubscribeTimeChange();
  }
  
  try {
    const timeSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_TIME_CHANGED]
    };
    
    commonEventManager.createSubscriber(timeSubscribeInfo)
      .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
        console.info('[UserPreferences] 订阅者创建成功');
        timeSubscriber = commonEventSubscriber;
        
        commonEventManager.subscribe(timeSubscriber, (err, data) => {
          if (err) {
            console.error(`[UserPreferences] 订阅事件失败: ${err.code} - ${err.message}`);
            return;
          }
          
          // 仅处理时制变化（'24HourChange'）
          if (data.data !== undefined && data.data === '24HourChange') {
            const newIs24HourClock = i18n.System.is24HourClock();
            console.info(`[UserPreferences] 时制变化: ${newIs24HourClock ? '24小时制' : '12小时制'}`);
            
            if (callback) {
              callback(newIs24HourClock);
            }
          }
        });
      })
      .catch((err: BusinessError) => {
        console.error(`[UserPreferences] 创建订阅者失败: ${err.code} - ${err.message}`);
      });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[UserPreferences] 订阅异常: ${err.code} - ${err.message}`);
  }
}

/**
 * 取消监听系统时制变化
 */
function unsubscribeTimeChange(): void {
  if (timeSubscriber !== null) {
    try {
      commonEventManager.unsubscribe(timeSubscriber, (err) => {
        if (err) {
          console.error(`[UserPreferences] 取消订阅失败: ${err.code} - ${err.message}`);
        } else {
          console.info('[UserPreferences] 取消订阅成功');
          timeSubscriber = null;
        }
      });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[UserPreferences] 取消订阅异常: ${err.code} - ${err.message}`);
    }
  } else {
    console.warn('[UserPreferences] 订阅者不存在');
  }
}

/**
 * 检查订阅状态
 * @returns boolean - 是否已订阅
 */
export function isMonitoringActive(): boolean {
  return timeSubscriber !== null;
}

// ==================== 辅助功能函数 ====================

/**
 * 格式化时间显示（根据时制偏好）
 * @param date - Date对象
 * @returns string - 格式化后的时间字符串
 */
export function formatTimeByPreference(date: Date): string {
  const is24Hour = currentPreferences.is24HourClock;
  
  const hours = date.getHours();
  const minutes = date.getMinutes();
  
  if (is24Hour) {
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
  } else {
    const period = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours > 12 ? hours - 12 : hours;
    return `${displayHours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')} ${period}`;
  }
}

/**
 * 格式化数字显示（根据本地数字偏好）
 * @param number - 数字
 * @returns string - 格式化后的数字字符串（简化实现）
 */
export function formatNumberByPreference(number: number): string {
  if (currentPreferences.usingLocalDigit) {
    console.warn('[UserPreferences] 本地数字格式化需要特定语言环境支持');
    return number.toString();
  } else {
    return number.toString();
  }
}

// ==================== 使用示例 ====================

/**
 * 示例：完整的用户偏好管理流程
 */
function exampleCompleteUsage(): void {
  console.info('=== 用户偏好完整功能示例 ===');
  
  // 初始化管理器并监听变化
  initUserPreferencesManager((is24HourClock: boolean) => {
    console.info(`[示例] 时制回调触发: ${is24HourClock}`);
  });
  
  // 获取当前偏好
  const prefs = getCurrentPreferences();
  console.info(`[示例] 当前偏好: 本地数字=${prefs.usingLocalDigit}, 时制=${prefs.is24HourClock}`);
  
  // 格式化时间显示
  const now = new Date();
  const formattedTime = formatTimeByPreference(now);
  console.info(`[示例] 当前时间: ${formattedTime}`);
  
  // 手动刷新
  refreshUserPreferences();
  
  // 销毁管理器（在页面销毁时调用）
  setTimeout(() => {
    destroyUserPreferencesManager();
    console.info('[示例] 管理器已销毁');
  }, 5000);
}

// 导出示例函数
export { exampleCompleteUsage };