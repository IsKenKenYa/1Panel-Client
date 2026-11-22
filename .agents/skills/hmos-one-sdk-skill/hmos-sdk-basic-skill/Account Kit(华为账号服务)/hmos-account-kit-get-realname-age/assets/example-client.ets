import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'RealNameAgeRange';
const DOMAIN = 0x0000;

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_PERMISSION_DENIED = 1001502014
}

export interface AgeRangeResult {
  status: 'success' | 'failed';
  authorizationCode?: string;
  errorMessage?: string;
}

export class RealNameAgeRangeClient {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async requestAuthorization(): Promise<AgeRangeResult> {
    try {
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      
      authRequest.scopes = ['realNameAgeRange'];
      authRequest.permissions = ['serviceauthcode'];
      authRequest.forceAuthorization = true;
      authRequest.state = util.generateRandomUUID();
      authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;

      hilog.info(DOMAIN, TAG, 'Starting authorization request');
      hilog.info(DOMAIN, TAG, `Request state: ${authRequest.state}`);

      const controller = new authentication.AuthenticationController(this.context);
      const response = await controller.executeRequest(authRequest);
      
      const authResponse = response as authentication.AuthorizationWithHuaweiIDResponse;
      
      const state = authResponse.state;
      if (state && authRequest.state !== state) {
        hilog.error(DOMAIN, TAG, `State mismatch. Request: ${authRequest.state}, Response: ${state}`);
        return {
          status: 'failed',
          errorMessage: 'State验证失败，可能存在跨站攻击'
        };
      }

      const credential = authResponse.data;
      const authorizationCode = credential?.authorizationCode;

      if (!authorizationCode) {
        hilog.error(DOMAIN, TAG, 'Authorization code is empty');
        return {
          status: 'failed',
          errorMessage: '未获取到Authorization Code'
        };
      }

      hilog.info(DOMAIN, TAG, 'Authorization succeeded');
      hilog.info(DOMAIN, TAG, `Authorization code length: ${authorizationCode.length}`);

      return {
        status: 'success',
        authorizationCode: authorizationCode
      };

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Authorization failed: ${err.code}, ${err.message}`);
      
      return {
        status: 'failed',
        errorMessage: this.getErrorMessage(err.code)
      };
    }
  }

  private getErrorMessage(errorCode: number): string {
    switch (errorCode) {
      case ErrorCode.ERROR_CODE_LOGIN_OUT:
        return '用户未登录华为账号，请先登录';
      case ErrorCode.ERROR_CODE_NETWORK_ERROR:
        return '网络连接失败，请检查网络状态';
      case ErrorCode.ERROR_CODE_USER_CANCEL:
        return '用户取消授权';
      case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
        return '系统服务异常，请稍后重试';
      case ErrorCode.ERROR_CODE_PERMISSION_DENIED:
        return '应用未申请年龄段权限，请联系开发者';
      case ErrorCode.ERROR_CODE_REQUEST_REFUSE:
        return '重复请求，请勿重复操作';
      default:
        return `授权失败: ${errorCode}`;
    }
  }
}

export async function getRealNameAgeRangeClient(context: Context): Promise<AgeRangeResult> {
  const client = new RealNameAgeRangeClient(context);
  return await client.requestAuthorization();
}

export function showErrorDialog(message: string): void {
  hilog.error(DOMAIN, TAG, `Error: ${message}`);
}

export function showSuccessDialog(authorizationCode: string): void {
  hilog.info(DOMAIN, TAG, 'Success: Authorization code obtained');
}