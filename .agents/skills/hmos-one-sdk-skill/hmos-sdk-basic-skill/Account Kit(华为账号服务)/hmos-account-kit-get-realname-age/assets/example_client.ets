import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002
}

export class RealNameAgeRangeClient {
  private context: Object;

  constructor(context: Object) {
    this.context = context;
  }

  async requestAuthorization(): Promise<string | null> {
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    
    authRequest.scopes = ['realNameAgeRange'];
    authRequest.permissions = ['serviceauthcode'];
    authRequest.forceAuthorization = true;
    authRequest.state = util.generateRandomUUID();

    try {
      const controller = new authentication.AuthenticationController(this.context);
      const data = await controller.executeRequest(authRequest);
      
      const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
      
      const state = authorizationWithHuaweiIDResponse.state;
      if (state && authRequest.state !== state) {
        hilog.error(0x0000, 'RealNameAgeRange', `State mismatch. Expected: ${authRequest.state}, Received: ${state}`);
        return null;
      }

      hilog.info(0x0000, 'RealNameAgeRange', 'Authorization succeeded');
      
      const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse?.data;
      const authorizationCode = authorizationWithHuaweiIDCredential?.authorizationCode;
      
      if (authorizationCode) {
        hilog.info(0x0000, 'RealNameAgeRange', `Authorization Code obtained: ${authorizationCode.substring(0, 10)}...`);
        return authorizationCode;
      } else {
        hilog.error(0x0000, 'RealNameAgeRange', 'Authorization Code is null');
        return null;
      }
    } catch (error) {
      this.handleAuthError(error as BusinessError);
      return null;
    }
  }

  private handleAuthError(error: BusinessError): void {
    hilog.error(0x0000, 'RealNameAgeRange', `Authorization failed. Code: ${error.code}, Message: ${error.message}`);

    switch (error.code) {
      case ErrorCode.ERROR_CODE_LOGIN_OUT:
        hilog.info(0x0000, 'RealNameAgeRange', 'User not logged in. Please login and retry.');
        break;
      case ErrorCode.ERROR_CODE_NETWORK_ERROR:
        hilog.info(0x0000, 'RealNameAgeRange', 'Network error. Please check network status.');
        break;
      case ErrorCode.ERROR_CODE_USER_CANCEL:
        hilog.info(0x0000, 'RealNameAgeRange', 'User canceled authorization.');
        break;
      case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
        hilog.info(0x0000, 'RealNameAgeRange', 'System service exception. Please retry later.');
        break;
      case ErrorCode.ERROR_CODE_REQUEST_REFUSE:
        hilog.info(0x0000, 'RealNameAgeRange', 'Duplicate request detected.');
        break;
      default:
        hilog.info(0x0000, 'RealNameAgeRange', 'Unknown error. Please retry or use other method.');
        break;
    }
  }
}

export async function sendAuthorizationCodeToServer(authorizationCode: string): Promise<void> {
  hilog.info(0x0000, 'RealNameAgeRange', `Sending Authorization Code to server: ${authorizationCode.substring(0, 10)}...`);
}