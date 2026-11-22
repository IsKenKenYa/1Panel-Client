import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'QuickPhoneNumberVerification';
const DOMAIN = 0x0000;

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_FINGERPRINT_FAILED = 1001500001,
  ERROR_CODE_PERMISSION_NOT_APPLIED = 1001502014
}

export interface PhoneNumberResult {
  authorizationCode: string;
  openID?: string;
  unionID?: string;
  state: string;
}

export class QuickPhoneNumberClient {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  async requestPhoneNumberAuthorization(): Promise<PhoneNumberResult> {
    try {
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      
      authRequest.scopes = ['phone'];
      authRequest.permissions = ['serviceauthcode'];
      authRequest.forceAuthorization = true;
      authRequest.state = util.generateRandomUUID();
      authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;

      hilog.info(DOMAIN, TAG, 'Starting phone number authorization request');

      const controller = new authentication.AuthenticationController(this.context);
      const data = await controller.executeRequest(authRequest);
      
      const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
      const state = authorizationWithHuaweiIDResponse.state;

      if (state && authRequest.state !== state) {
        hilog.error(DOMAIN, TAG, `State verification failed. Request state: ${authRequest.state}, Response state: ${state}`);
        throw new Error('State verification failed, possible cross-site attack');
      }

      hilog.info(DOMAIN, TAG, 'Authorization succeeded');

      const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse?.data;
      
      if (!authorizationWithHuaweiIDCredential) {
        throw new Error('No credential data returned');
      }

      const authorizationCode = authorizationWithHuaweiIDCredential?.authorizationCode;
      
      if (!authorizationCode) {
        throw new Error('Authorization Code not obtained');
      }

      hilog.info(DOMAIN, TAG, `Authorization Code obtained: ${authorizationCode.substring(0, 20)}...`);

      return {
        authorizationCode: authorizationCode,
        openID: authorizationWithHuaweiIDCredential.openID,
        unionID: authorizationWithHuaweiIDCredential.unionID,
        state: state || ''
      };

    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Authorization failed. Code: ${businessError.code}, Message: ${businessError.message}`);
      this.handleAuthorizationError(businessError);
      throw error;
    }
  }

  private handleAuthorizationError(error: BusinessError): void {
    switch (error.code) {
      case ErrorCode.ERROR_CODE_LOGIN_OUT:
        hilog.error(DOMAIN, TAG, 'User not logged in to Huawei account');
        break;
      case ErrorCode.ERROR_CODE_NETWORK_ERROR:
        hilog.error(DOMAIN, TAG, 'Network error occurred');
        break;
      case ErrorCode.ERROR_CODE_USER_CANCEL:
        hilog.warn(DOMAIN, TAG, 'User cancelled authorization');
        break;
      case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
        hilog.error(DOMAIN, TAG, 'System service exception');
        break;
      case ErrorCode.ERROR_CODE_REQUEST_REFUSE:
        hilog.warn(DOMAIN, TAG, 'Duplicate request, application should not handle');
        break;
      case ErrorCode.ERROR_CODE_FINGERPRINT_FAILED:
        hilog.error(DOMAIN, TAG, 'Application fingerprint verification failed');
        break;
      case ErrorCode.ERROR_CODE_PERMISSION_NOT_APPLIED:
        hilog.error(DOMAIN, TAG, 'Phone scope permission not applied');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}`);
    }
  }

  getStateVerificationResult(requestState: string, responseState: string): boolean {
    if (!responseState) {
      hilog.warn(DOMAIN, TAG, 'Response state is empty');
      return false;
    }
    
    if (requestState !== responseState) {
      hilog.error(DOMAIN, TAG, `State mismatch. Request: ${requestState}, Response: ${responseState}`);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'State verification passed');
    return true;
  }
}

export async function quickPhoneNumberVerificationExample(context: common.Context): Promise<void> {
  const client = new QuickPhoneNumberClient(context);
  
  try {
    const result = await client.requestPhoneNumberAuthorization();
    
    hilog.info(DOMAIN, TAG, '=== Phone Number Authorization Result ===');
    hilog.info(DOMAIN, TAG, `Authorization Code: ${result.authorizationCode}`);
    hilog.info(DOMAIN, TAG, `OpenID: ${result.openID || 'N/A'}`);
    hilog.info(DOMAIN, TAG, `UnionID: ${result.unionID || 'N/A'}`);
    hilog.info(DOMAIN, TAG, `State: ${result.state}`);
    
    hilog.info(DOMAIN, TAG, 'Send Authorization Code to server for phone number retrieval');
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Quick phone number verification failed');
  }
}