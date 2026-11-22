/**
 * 获取用户偏好设置示例
 * 功能：获取系统本地数字和时制设置
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 获取系统是否使用本地数字
 * @returns boolean - true表示使用本地数字，false表示不使用
 */
export function getLocalDigitStatus(): boolean {
  try {
    const usingLocalDigit: boolean = i18n.System.getUsingLocalDigit();
    console.info(`[I18n] 系统当前是否使用本地数字: ${usingLocalDigit}`);
    return usingLocalDigit;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[I18n] 获取本地数字状态失败, 错误码: ${err.code}, 消息: ${err.message}`);
    handleI18nError(err);
    return false;
  }
}

/**
 * 获取系统时制（12小时制或24小时制）
 * @returns boolean - true表示24小时制，false表示12小时制
 */
export function getTimeFormat(): boolean {
  try {
    const is24HourClock: boolean = i18n.System.is24HourClock();
    console.info(`[I18n] 系统当前是否为24小时制: ${is24HourClock}`);
    return is24HourClock;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[I18n] 获取系统时制失败, 错误码: ${err.code}, 消息: ${err.message}`);
    handleI18nError(err);
    return false;
  }
}

/**
 * 获取完整的用户偏好信息
 * @returns UserPreferences - 用户偏好对象
 */
export function getUserPreferences(): UserPreferences {
  const usingLocalDigit = getLocalDigitStatus();
  const is24HourClock = getTimeFormat();
  
  return {
    usingLocalDigit: usingLocalDigit,
    is24HourClock: is24HourClock,
    timestamp: Date.now()
  };
}

/**
 * 统一错误处理函数
 * @param error - BusinessError错误对象
 */
function handleI18nError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('[I18n] 参数错误: 必填参数未指定或参数类型错误');
      break;
    case 890001:
      console.error('[I18n] 无效参数: 参数验证失败');
      break;
    default:
      console.error(`[I18n] 未知错误: 错误码 ${error.code}, 消息: ${error.message}`);
  }
}

/**
 * 用户偏好数据结构
 */
export interface UserPreferences {
  usingLocalDigit: boolean;
  is24HourClock: boolean;
  timestamp: number;
}

// 使用示例
function exampleUsage(): void {
  console.info('[I18n] 开始获取用户偏好设置...');
  
  const preferences = getUserPreferences();
  
  console.info(`[I18n] 本地数字状态: ${preferences.usingLocalDigit}`);
  console.info(`[I18n] 时制: ${preferences.is24HourClock ? '24小时制' : '12小时制'}`);
  console.info(`[I18n] 获取时间: ${new Date(preferences.timestamp).toLocaleString()}`);
}

// 导出示例函数供外部调用
export { exampleUsage };