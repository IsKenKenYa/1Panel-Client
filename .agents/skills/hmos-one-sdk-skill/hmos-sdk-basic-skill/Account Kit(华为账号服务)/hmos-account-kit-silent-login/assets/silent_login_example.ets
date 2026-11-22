/**
 * 静默登录完整示例
 * 
 * 本示例展示如何实现华为账号静默登录功能
 * 功能：在用户已登录华为账号的情况下，无需用户交互即可获取Authorization Code和用户身份标识
 */

import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

// 日志标签
const TAG = 'SilentLoginExample';
const DOMAIN = 0x0000;

/**
 * 错误码枚举
 */
export enum ErrorCode {
  // 账号未登录
  ERROR_CODE_LOGIN_OUT = 1001502001,
  // 网络错误
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  // 内部错误
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  // 用户取消授权
  ERROR_CODE_USER_CANCEL = 1001502012,
  // 系统服务异常
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  // 重复请求
  ERROR_CODE_REQUEST_REFUSE = 1001500002
}

/**
 * 静默登录结果
 */
export interface SilentLoginResult {
  success: boolean;
  authorizationCode?: string;
  idToken?: string;
  unionId?: string;
  openId?: string;
  errorCode?: number;
  errorMsg?: string;
}

/**
 * 执行静默登录
 * 
 * @returns Promise<SilentLoginResult> 静默登录结果
 */
export async function performSilentLogin(): Promise<SilentLoginResult> {
  hilog.info(DOMAIN, TAG, 'Starting silent login...');
  
  try {
    // 步骤1：创建华为账号提供者实例
    const huaweiIdProvider = new authentication.HuaweiIDProvider();
    
    // 步骤2：创建登录请求对象
    const loginRequest = huaweiIdProvider.createLoginWithHuaweiIDRequest();
    
    // 步骤3：设置静默登录参数
    loginRequest.forceLogin = false; // 关键参数：false表示静默登录
    loginRequest.state = util.generateRandomUUID(); // 用于一致性校验，防止跨站攻击
    loginRequest.nonce = util.generateRandomUUID(); // 用于防重放攻击
    loginRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;
    
    hilog.info(DOMAIN, TAG, `Login request created with state: ${loginRequest.state}`);
    
    // 步骤4：创建认证控制器
    const controller = new authentication.AuthenticationController();
    
    // 步骤5：执行登录请求
    const response = await controller.executeRequest(loginRequest);
    
    // 步骤6：类型转换为LoginWithHuaweiIDResponse
    const loginWithHuaweiIDResponse = response as authentication.LoginWithHuaweiIDResponse;
    
    // 步骤7：校验state参数一致性（防止跨站攻击）
    const responseState = loginWithHuaweiIDResponse.state;
    if (responseState && loginRequest.state !== responseState) {
      hilog.error(DOMAIN, TAG, `State mismatch: expected ${loginRequest.state}, got ${responseState}`);
      return {
        success: false,
        errorCode: -1,
        errorMsg: 'State validation failed'
      };
    }
    
    hilog.info(DOMAIN, TAG, 'Silent login succeeded');
    
    // 步骤8：获取登录凭证
    const credential = loginWithHuaweiIDResponse.data;
    if (!credential) {
      hilog.error(DOMAIN, TAG, 'No credential data in response');
      return {
        success: false,
        errorCode: -2,
        errorMsg: 'No credential data'
      };
    }
    
    // 步骤9：提取关键信息
    const authorizationCode = credential.authorizationCode;
    const idToken = credential.idToken;
    const unionId = credential.unionId;
    const openId = credential.openId;
    
    hilog.info(DOMAIN, TAG, `Authorization Code: ${authorizationCode?.substring(0, 20)}...`);
    hilog.info(DOMAIN, TAG, `UnionID: ${unionId}`);
    hilog.info(DOMAIN, TAG, `OpenID: ${openId}`);
    
    // 步骤10：返回成功结果
    return {
      success: true,
      authorizationCode: authorizationCode,
      idToken: idToken,
      unionId: unionId,
      openId: openId
    };
    
  } catch (error) {
    const businessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Silent login failed: ${businessError.code}, ${businessError.message}`);
    
    return {
      success: false,
      errorCode: businessError.code,
      errorMsg: businessError.message
    };
  }
}

/**
 * 处理静默登录错误
 * 
 * @param errorCode 错误码
 * @param errorMsg 错误消息
 * @returns string 用户友好的错误提示
 */
export function handleSilentLoginError(errorCode: number, errorMsg: string): string {
  let userMessage = '';
  
  switch (errorCode) {
    case ErrorCode.ERROR_CODE_LOGIN_OUT:
      userMessage = '您未登录华为账号，请先登录华为账号或使用其他方式登录';
      break;
      
    case ErrorCode.ERROR_CODE_NETWORK_ERROR:
      userMessage = '网络连接失败，请检查网络状态后重试';
      break;
      
    case ErrorCode.ERROR_CODE_INTERNAL_ERROR:
      userMessage = '登录失败，请稍后重试或使用其他方式登录';
      break;
      
    case ErrorCode.ERROR_CODE_USER_CANCEL:
      userMessage = '您取消了授权，需要授权才能继续使用';
      break;
      
    case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
      userMessage = '系统服务异常，请稍后重试';
      break;
      
    case ErrorCode.ERROR_CODE_REQUEST_REFUSE:
      userMessage = '重复请求，请稍后重试';
      break;
      
    default:
      userMessage = `登录失败：${errorMsg}`;
  }
  
  return userMessage;
}

/**
 * 完整的静默登录流程（带错误处理和重试）
 * 
 * @param maxRetries 最大重试次数（网络错误时）
 * @returns Promise<SilentLoginResult> 静默登录结果
 */
export async function performSilentLoginWithRetry(maxRetries: number = 3): Promise<SilentLoginResult> {
  let retryCount = 0;
  
  while (retryCount <= maxRetries) {
    const result = await performSilentLogin();
    
    if (result.success) {
      return result;
    }
    
    // 网络错误时重试
    if (result.errorCode === ErrorCode.ERROR_CODE_NETWORK_ERROR && retryCount < maxRetries) {
      retryCount++;
      hilog.warn(DOMAIN, TAG, `Network error, retrying... (${retryCount}/${maxRetries})`);
      
      // 等待2秒后重试
      await new Promise<void>((resolve) => {
        setTimeout(() => resolve(), 2000);
      });
      
      continue;
    }
    
    // 其他错误直接返回
    return result;
  }
  
  return {
    success: false,
    errorCode: ErrorCode.ERROR_CODE_NETWORK_ERROR,
    errorMsg: 'Network error after maximum retries'
  };
}

/**
 * 检查华为账号登录状态
 * 
 * @param unionId 用户UnionID（可选）
 * @returns Promise<boolean> 是否已登录
 */
export async function checkHuaweiIDLoginState(unionId?: string): Promise<boolean> {
  try {
    const huaweiIdProvider = new authentication.HuaweiIDProvider();
    
    // 如果有UnionID，使用getHuaweiIDState接口检查
    if (unionId) {
      const stateRequest: authentication.StateRequest = {
        idType: authentication.IdType.UNION_ID,
        idValue: unionId
      };
      
      const stateResult = await huaweiIdProvider.getHuaweiIDState(stateRequest);
      hilog.info(DOMAIN, TAG, `Huawei ID state: ${stateResult.state}`);
      
      return stateResult.state === authentication.LoginState.LOGGED_IN;
    }
    
    // 没有UnionID时，尝试静默登录来判断
    const loginRequest = huaweiIdProvider.createLoginWithHuaweiIDRequest();
    loginRequest.forceLogin = false;
    
    const controller = new authentication.AuthenticationController();
    
    try {
      await controller.executeRequest(loginRequest);
      return true;
    } catch (error) {
      const businessError = error as BusinessError;
      if (businessError.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
        return false;
      }
      throw error;
    }
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Failed to check login state');
    return false;
  }
}

/**
 * 使用示例
 */
export async function silentLoginExample(): Promise<void> {
  hilog.info(DOMAIN, TAG, '=== 静默登录示例 ===');
  
  // 示例1：检查登录状态
  const isLoggedIn = await checkHuaweiIDLoginState();
  hilog.info(DOMAIN, TAG, `Huawei ID login state: ${isLoggedIn}`);
  
  if (!isLoggedIn) {
    hilog.warn(DOMAIN, TAG, '华为账号未登录，无法执行静默登录');
    return;
  }
  
  // 示例2：执行静默登录（带重试）
  const result = await performSilentLoginWithRetry(3);
  
  if (result.success) {
    hilog.info(DOMAIN, TAG, '静默登录成功！');
    hilog.info(DOMAIN, TAG, `Authorization Code: ${result.authorizationCode}`);
    hilog.info(DOMAIN, TAG, `UnionID: ${result.unionId}`);
    hilog.info(DOMAIN, TAG, `OpenID: ${result.openId}`);
    
    // 将Authorization Code发送到服务端处理
    // await sendAuthorizationCodeToServer(result.authorizationCode);
  } else {
    const errorMsg = handleSilentLoginError(result.errorCode!, result.errorMsg!);
    hilog.error(DOMAIN, TAG, errorMsg);
  }
}

/**
 * 应用入口调用示例
 */
export function initSilentLogin(): void {
  // 在应用启动时执行静默登录
  silentLoginExample().then(() => {
    hilog.info(DOMAIN, TAG, 'Silent login initialization completed');
  }).catch((error: Error) => {
    hilog.error(DOMAIN, TAG, `Silent login initialization failed: ${error.message}`);
  });
}