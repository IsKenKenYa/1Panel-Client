import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'SilentLogin';
const DOMAIN = 0x0000;

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_FINGERPRINT_FAILED = 1001500001,
  ERROR_CODE_INVALID_PARAM = 1001502003
}

export interface SilentLoginResult {
  authorizationCode: string | null;
  unionID: string | null;
  openID: string | null;
  idToken: string | null;
  success: boolean;
  errorCode?: number;
  errorMessage?: string;
}

function handleSilentLoginError(error: BusinessError): void {
  hilog.error(DOMAIN, TAG, `Silent login failed. Code: ${error.code}, message: ${error.message}`);
  
  switch (error.code) {
    case ErrorCode.ERROR_CODE_LOGIN_OUT:
      hilog.warn(DOMAIN, TAG, 'User not logged in with HUAWEI ID.');
      break;
    case ErrorCode.ERROR_CODE_NETWORK_ERROR:
      hilog.error(DOMAIN, TAG, 'Network error. Please check network connection.');
      break;
    case ErrorCode.ERROR_CODE_INTERNAL_ERROR:
      hilog.error(DOMAIN, TAG, 'Internal error. Please retry or use other login method.');
      break;
    case ErrorCode.ERROR_CODE_USER_CANCEL:
      hilog.info(DOMAIN, TAG, 'User canceled authorization.');
      break;
    case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
      hilog.error(DOMAIN, TAG, 'System service exception. Please retry later.');
      break;
    case ErrorCode.ERROR_CODE_REQUEST_REFUSE:
      hilog.info(DOMAIN, TAG, 'Duplicate request. Application can ignore this.');
      break;
    case ErrorCode.ERROR_CODE_FINGERPRINT_FAILED:
      hilog.error(DOMAIN, TAG, 'App fingerprint verification failed. Please check fingerprint configuration.');
      break;
    case ErrorCode.ERROR_CODE_INVALID_PARAM:
      hilog.error(DOMAIN, TAG, 'Invalid input parameter. Please check Client ID configuration.');
      break;
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error. Please use other login method.');
      break;
  }
}

export async function performSilentLogin(): Promise<SilentLoginResult> {
  try {
    hilog.info(DOMAIN, TAG, 'Starting silent login...');
    
    const loginRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
    loginRequest.forceLogin = false;
    loginRequest.state = util.generateRandomUUID();
    loginRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;
    
    const controller = new authentication.AuthenticationController();
    const response = await controller.executeRequest(loginRequest) as authentication.LoginWithHuaweiIDResponse;
    
    const state = response.state;
    if (state && loginRequest.state !== state) {
      hilog.error(DOMAIN, TAG, `State mismatch. Request state: ${loginRequest.state}, Response state: ${state}`);
      return {
        authorizationCode: null,
        unionID: null,
        openID: null,
        idToken: null,
        success: false,
        errorCode: -1,
        errorMessage: 'State mismatch, possible CSRF attack'
      };
    }
    
    const credential = response?.data;
    const authorizationCode = credential?.authorizationCode || null;
    const unionID = credential?.unionID || null;
    const openID = credential?.openID || null;
    const idToken = credential?.idToken || null;
    
    hilog.info(DOMAIN, TAG, 'Silent login succeeded.');
    hilog.info(DOMAIN, TAG, `UnionID: ${unionID}`);
    hilog.info(DOMAIN, TAG, `OpenID: ${openID}`);
    hilog.info(DOMAIN, TAG, `Authorization Code length: ${authorizationCode?.length || 0}`);
    
    return {
      authorizationCode,
      unionID,
      openID,
      idToken,
      success: true
    };
  } catch (error) {
    const err = error as BusinessError;
    handleSilentLoginError(err);
    
    return {
      authorizationCode: null,
      unionID: null,
      openID: null,
      idToken: null,
      success: false,
      errorCode: err.code,
      errorMessage: err.message
    };
  }
}

export async function sendAuthorizationCodeToServer(authorizationCode: string): Promise<{ success: boolean; unionID?: string; sessionID?: string }> {
  if (!authorizationCode) {
    hilog.error(DOMAIN, TAG, 'Authorization code is null or empty.');
    return { success: false };
  }
  
  hilog.info(DOMAIN, TAG, 'Sending authorization code to server...');
  
  try {
    const response = await fetch('https://your-server.com/api/auth/silent-login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        authorizationCode: authorizationCode
      })
    });
    
    if (!response.ok) {
      hilog.error(DOMAIN, TAG, `Server request failed. Status: ${response.status}`);
      return { success: false };
    }
    
    const data = await response.json();
    hilog.info(DOMAIN, TAG, 'Server response received.');
    
    return {
      success: true,
      unionID: data.unionID,
      sessionID: data.sessionID
    };
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Server request error: ${error}`);
    return { success: false };
  }
}

export async function completeSilentLoginFlow(): Promise<boolean> {
  hilog.info(DOMAIN, TAG, 'Starting complete silent login flow...');
  
  const loginResult = await performSilentLogin();
  
  if (!loginResult.success || !loginResult.authorizationCode) {
    hilog.error(DOMAIN, TAG, 'Silent login failed or authorization code is null.');
    return false;
  }
  
  const serverResult = await sendAuthorizationCodeToServer(loginResult.authorizationCode);
  
  if (!serverResult.success) {
    hilog.error(DOMAIN, TAG, 'Server processing failed.');
    return false;
  }
  
  hilog.info(DOMAIN, TAG, 'Silent login flow completed successfully.');
  hilog.info(DOMAIN, TAG, `User UnionID from server: ${serverResult.unionID}`);
  
  if (loginResult.unionID && serverResult.unionID && loginResult.unionID !== serverResult.unionID) {
    hilog.warn(DOMAIN, TAG, 'UnionID mismatch between client and server.');
  }
  
  return true;
}

export async function checkUserExistsByUnionID(unionID: string): Promise<boolean> {
  if (!unionID) {
    hilog.error(DOMAIN, TAG, 'UnionID is null or empty.');
    return false;
  }
  
  hilog.info(DOMAIN, TAG, `Checking if user exists with UnionID: ${unionID}`);
  
  try {
    const response = await fetch(`https://your-server.com/api/users/check?unionID=${unionID}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      hilog.error(DOMAIN, TAG, `User check failed. Status: ${response.status}`);
      return false;
    }
    
    const data = await response.json();
    return data.exists === true;
  } catch (error) {
    hilog.error(DOMAIN, TAG, `User check error: ${error}`);
    return false;
  }
}