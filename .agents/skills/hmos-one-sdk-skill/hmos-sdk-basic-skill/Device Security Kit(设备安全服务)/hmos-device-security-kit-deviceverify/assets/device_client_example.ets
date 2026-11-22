import { deviceCertificate } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';

const TAG = 'DeviceVerifyExample';
const DOMAIN = 0x0000;
const SERVER_URL = 'https://your-server.com/api/deviceVerify';

export class DeviceVerifyClient {
  private maxRetryCount: number = 3;
  private retryDelay: number = 1000;

  async getDeviceToken(): Promise<string> {
    hilog.info(DOMAIN, TAG, 'Getting device token...');
    
    try {
      const token = await deviceCertificate.getDeviceToken();
      hilog.info(DOMAIN, TAG, 'Succeeded in getting deviceToken');
      return token;
    } catch (err) {
      let error: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'getDeviceToken failed! Code: %{public}d, Message: %{public}s',
                  error.code, error.message);
      throw error;
    }
  }

  async getDeviceTokenWithRetry(): Promise<string> {
    for (let i = 0; i < this.maxRetryCount; i++) {
      try {
        const token = await this.getDeviceToken();
        return token;
      } catch (error) {
        const businessError = error as BusinessError;
        hilog.warn(DOMAIN, TAG, `Retry ${i + 1}/${this.maxRetryCount} failed`);
        
        if (businessError.code === 1003300006) {
          await this.delay(this.retryDelay);
        } else {
          throw error;
        }
      }
    }
    
    throw new Error('Failed to get deviceToken after max retries');
  }

  async sendTokenToServer(deviceToken: string): Promise<string> {
    hilog.info(DOMAIN, TAG, 'Sending deviceToken to server...');
    
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        SERVER_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: {
            deviceToken: deviceToken,
            timestamp: Date.now()
          },
          connectTimeout: 10000,
          readTimeout: 10000
        }
      );
      
      hilog.info(DOMAIN, TAG, 'Server response: %{public}s', response.result);
      return response.result as string;
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to send token to server: %{public}s', error.message);
      throw error;
    }
  }

  async handleNewUserCoupon(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Handling new user coupon...');
    
    try {
      const deviceToken = await this.getDeviceTokenWithRetry();
      const serverResponse = await this.sendTokenToServer(deviceToken);
      
      const responseObj = JSON.parse(serverResponse);
      if (responseObj.bit1 === false) {
        hilog.info(DOMAIN, TAG, 'User has not received coupon, granting coupon...');
        await this.grantCoupon(deviceToken);
      } else {
        hilog.info(DOMAIN, TAG, 'User has already received coupon on this device');
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'Fallback to alternative method');
      await this.alternativeRiskControlMethod();
    }
  }

  async grantCoupon(deviceToken: string): Promise<void> {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `${SERVER_URL}/grantCoupon`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: {
            deviceToken: deviceToken,
            couponType: 'new_user',
            timestamp: Date.now()
          }
        }
      );
      
      hilog.info(DOMAIN, TAG, 'Coupon granted successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to grant coupon: %{public}s', error.message);
    }
  }

  async alternativeRiskControlMethod(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Using alternative risk control method');
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

export async function main(): Promise<void> {
  const client = new DeviceVerifyClient();
  
  try {
    await client.handleNewUserCoupon();
    hilog.info(DOMAIN, TAG, 'Device verify completed successfully');
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Device verify failed: %{public}s', error.message);
  }
}

main();