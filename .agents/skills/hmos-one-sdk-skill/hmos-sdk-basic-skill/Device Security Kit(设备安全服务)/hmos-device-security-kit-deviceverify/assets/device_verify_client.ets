import { deviceCertificate } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';

const TAG = "DeviceVerifyDemo";
const DOMAIN = 0x0000;

export class DeviceVerifyClient {
  private deviceToken: string | null = null;
  
  async initialize(): Promise<boolean> {
    try {
      this.deviceToken = await this.getDeviceToken();
      return this.deviceToken !== null;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize: %{public}s', error);
      return false;
    }
  }
  
  async getDeviceToken(): Promise<string | null> {
    try {
      const token = await deviceCertificate.getDeviceToken();
      hilog.info(DOMAIN, TAG, 'Succeeded in getting deviceToken');
      this.deviceToken = token;
      return token;
    } catch (err) {
      let error: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Failed to get deviceToken: %{public}d %{public}s', 
                  error.code, error.message);
      this.handleTokenError(error);
      return null;
    }
  }
  
  async sendDeviceTokenToServer(serverUrl: string, action: string): Promise<any> {
    if (!this.deviceToken) {
      hilog.error(DOMAIN, TAG, 'DeviceToken is null, please initialize first');
      return null;
    }
    
    const httpRequest = http.createHttp();
    
    try {
      const response = await httpRequest.request(
        serverUrl,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: {
            deviceToken: this.deviceToken,
            action: action,
            timestamp: Date.now()
          },
          connectTimeout: 50000,
          readTimeout: 50000
        }
      );
      
      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        hilog.info(DOMAIN, TAG, 'Server response: %{public}s', result.message);
        return result;
      } else {
        hilog.error(DOMAIN, TAG, 'Server returned error: %{public}d', response.responseCode);
        return null;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to send token to server: %{public}s', error);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }
  
  private handleTokenError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied');
        hilog.error(DOMAIN, TAG, 'Please add ohos.permission.GET_DEVICE_CERTIFICATE in module.json5');
        break;
      case 1003300005:
        hilog.error(DOMAIN, TAG, 'Internal error occurred');
        hilog.info(DOMAIN, TAG, 'Please retry later or use alternative verification method');
        break;
      case 1003300006:
        hilog.error(DOMAIN, TAG, 'Network error occurred');
        hilog.info(DOMAIN, TAG, 'Please check network connection and retry');
        break;
      default:
        hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d', error.code);
        break;
    }
  }
  
  getStoredToken(): string | null {
    return this.deviceToken;
  }
}

export async function claimNewUserPackage(userId: string): Promise<boolean> {
  const client = new DeviceVerifyClient();
  const initialized = await client.initialize();
  
  if (!initialized) {
    hilog.error(DOMAIN, TAG, 'Failed to get deviceToken');
    return false;
  }
  
  const result = await client.sendDeviceTokenToServer(
    'https://your-server.com/api/claimPackage',
    'claimNewUserPackage'
  );
  
  if (result && result.success) {
    hilog.info(DOMAIN, TAG, 'Successfully claimed new user package');
    return true;
  }
  
  hilog.error(DOMAIN, TAG, 'Failed to claim package: %{public}s', result?.message);
  return false;
}