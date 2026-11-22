/**
 * 获取收货地址错误处理示例代码
 * 
 * 本示例演示如何处理获取收货地址过程中可能出现的各种错误
 * 
 * 错误码说明：
 * - 401: 参数错误
 * - 1008100001: 内部错误
 * - 1008100002: 网络不可用
 * - 1008100003: 用户未登录华为账号
 * - 1008100004: 应用指纹证书校验失败
 * - 1008100005: 应用未申请对应permissions权限
 * - 1008100006: 用户未完成操作就退出
 * - 1008100007: 已登录账号不支持收货地址管理服务
 */

import { shippingAddress } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ShippingAddressErrorHandler';
const DOMAIN = 0x0000;

/**
 * 错误处理工具类
 */
export class ShippingAddressErrorHandler {
  
  /**
   * 处理chooseAddress API的所有错误
   * 
   * @param error BusinessError对象
   * @returns 错误处理结果对象
   */
  static handleChooseAddressError(error: BusinessError): ErrorHandleResult {
    const result: ErrorHandleResult = {
      errorCode: error.code,
      errorMessage: error.message,
      userMessage: '',
      needRetry: false,
      action: ErrorAction.NONE
    };

    switch (error.code) {
      case 401:
        result.userMessage = '参数错误，请检查调用方式是否正确';
        result.needRetry = false;
        result.action = ErrorAction.SHOW_ALERT;
        hilog.error(DOMAIN, TAG, 'Parameter error. Please check context parameter.');
        break;

      case 1008100001:
        result.userMessage = '内部错误，请重启设备后重试';
        result.needRetry = true;
        result.action = ErrorAction.RESTART_DEVICE;
        hilog.error(DOMAIN, TAG, 'Internal error. Please restart device and retry.');
        break;

      case 1008100002:
        result.userMessage = '网络不可用，请检查网络连接';
        result.needRetry = true;
        result.action = ErrorAction.CHECK_NETWORK;
        hilog.error(DOMAIN, TAG, 'Network unavailable. Please check network connection.');
        break;

      case 1008100003:
        result.userMessage = '用户未登录华为账号，请先登录';
        result.needRetry = false;
        result.action = ErrorAction.GUIDE_LOGIN;
        hilog.error(DOMAIN, TAG, 'User not logged in. Please guide user to login.');
        break;

      case 1008100004:
        result.userMessage = '应用指纹证书校验失败，请联系开发者';
        result.needRetry = false;
        result.action = ErrorAction.CHECK_CONFIG;
        hilog.error(DOMAIN, TAG, 'App fingerprint check failed. Check Client ID and fingerprint certificate.');
        break;

      case 1008100005:
        result.userMessage = '应用未申请获取收货地址权限，请联系开发者';
        result.needRetry = false;
        result.action = ErrorAction.CHECK_PERMISSION;
        hilog.error(DOMAIN, TAG, 'App does not have required permissions. Please apply for permission in AGC.');
        break;

      case 1008100006:
        result.userMessage = '用户取消了操作';
        result.needRetry = false;
        result.action = ErrorAction.USER_CANCEL;
        hilog.info(DOMAIN, TAG, 'User canceled the operation. No need to handle.');
        break;

      case 1008100007:
        result.userMessage = '当前账号不支持收货地址服务，请使用中国境内账号';
        result.needRetry = false;
        result.action = ErrorAction.CHANGE_ACCOUNT;
        hilog.error(DOMAIN, TAG, 'Logged account does not support shipping address service.');
        break;

      default:
        result.userMessage = `未知错误：${error.code}`;
        result.needRetry = false;
        result.action = ErrorAction.SHOW_ALERT;
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}, ${error.message}`);
        break;
    }

    return result;
  }

  /**
   * 执行错误处理动作
   * 
   * @param result 错误处理结果对象
   */
  static executeErrorAction(result: ErrorHandleResult): void {
    switch (result.action) {
      case ErrorAction.SHOW_ALERT:
        AlertDialog.show({
          title: '获取地址失败',
          message: result.userMessage,
          confirm: {
            value: '确定',
            action: () => {}
          }
        });
        break;

      case ErrorAction.GUIDE_LOGIN:
        // 引导用户登录华为账号
        AlertDialog.show({
          title: '需要登录',
          message: '请先登录华为账号后再选择收货地址\n\n您可以在系统设置中登录华为账号',
          confirm: {
            value: '去设置',
            action: () => {
              // 引导用户到系统设置登录
              // 实际应用中可调用LoginWithHuaweiIDRequest(forceLogin: true)拉起登录页面
              hilog.info(DOMAIN, TAG, 'Guide user to login in system settings.');
            }
          },
          cancel: {
            value: '取消',
            action: () => {}
          }
        });
        break;

      case ErrorAction.CHECK_NETWORK:
        AlertDialog.show({
          title: '网络不可用',
          message: '请检查网络连接后再重试',
          confirm: {
            value: '重试',
            action: () => {
              hilog.info(DOMAIN, TAG, 'User choose to retry after network check.');
            }
          },
          cancel: {
            value: '取消',
            action: () => {}
          }
        });
        break;

      case ErrorAction.CHANGE_ACCOUNT:
        AlertDialog.show({
          title: '账号不支持',
          message: '当前账号不支持收货地址服务\n\n请使用中国境内（不含港澳台）注册的华为账号',
          confirm: {
            value: '知道了',
            action: () => {
              hilog.info(DOMAIN, TAG, 'Guide user to change account.');
            }
          }
        });
        break;

      case ErrorAction.USER_CANCEL:
        // 用户取消操作，应用无需特殊处理
        hilog.info(DOMAIN, TAG, 'User canceled operation, no special handling needed.');
        break;

      case ErrorAction.CHECK_CONFIG:
        // 配置错误，开发者需要处理
        hilog.error(DOMAIN, TAG, 'Configuration error, developer needs to check Client ID and fingerprint.');
        break;

      case ErrorAction.CHECK_PERMISSION:
        // 权限未申请，开发者需要处理
        hilog.error(DOMAIN, TAG, 'Permission not applied, developer needs to apply in AGC.');
        break;

      case ErrorAction.RESTART_DEVICE:
        AlertDialog.show({
          title: '内部错误',
          message: '发生内部错误，请重启设备后重试\n\n如问题持续，请联系客服',
          confirm: {
            value: '知道了',
            action: () => {
              hilog.info(DOMAIN, TAG, 'Guide user to restart device.');
            }
          }
        });
        break;

      case ErrorAction.NONE:
        // 无需处理
        break;
    }
  }
}

/**
 * 错误处理结果对象
 */
export interface ErrorHandleResult {
  errorCode: number;         // 错误码
  errorMessage: string;      // 错误消息（英文）
  userMessage: string;       // 用户提示消息（中文）
  needRetry: boolean;        // 是否需要重试
  action: ErrorAction;       // 处理动作
}

/**
 * 错误处理动作枚举
 */
export enum ErrorAction {
  NONE,              // 无需处理
  SHOW_ALERT,        // 显示提示对话框
  GUIDE_LOGIN,       // 引导用户登录
  CHECK_NETWORK,     // 检查网络
  CHANGE_ACCOUNT,    // 更换账号
  USER_CANCEL,       // 用户取消（无需处理）
  CHECK_CONFIG,      // 检查配置（开发者处理）
  CHECK_PERMISSION,  // 检查权限（开发者处理）
  RESTART_DEVICE     // 重启设备
}

/**
 * 使用示例
 */
@Entry
@Component
struct ErrorHandlingExample {
  build() {
    Column({ space: 20 }) {
      Button('测试错误处理')
        .onClick(() => {
          this.testErrorHandling();
        });
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }

  /**
   * 测试错误处理流程
   */
  private async testErrorHandling(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      const addressInfo = await shippingAddress.chooseAddress(context);
      hilog.info(DOMAIN, TAG, 'Address chosen successfully.');
    } catch (error) {
      const err = error as BusinessError;
      
      // 使用错误处理工具类处理错误
      const result = ShippingAddressErrorHandler.handleChooseAddressError(err);
      
      // 记录错误信息
      hilog.error(DOMAIN, TAG, `Error handled: ${result.errorCode} - ${result.errorMessage}`);
      
      // 执行错误处理动作
      ShippingAddressErrorHandler.executeErrorAction(result);
    }
  }
}