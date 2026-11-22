import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'RealNameAgeServer';
const DOMAIN = 0x0000;

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

interface AgeRangeResponse {
  ageRange: number;
  retCode: number;
}

interface ServerConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
}

export class RealNameAgeRangeServer {
  private config: ServerConfig;
  private accessToken: string = '';
  private refreshToken: string = '';

  constructor(config: ServerConfig) {
    this.config = config;
  }

  async getAccessToken(authorizationCode: string): Promise<TokenResponse> {
    const url = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';
    
    const requestBody = {
      grant_type: 'authorization_code',
      code: authorizationCode,
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      redirect_uri: this.config.redirectUri
    };

    hilog.info(DOMAIN, TAG, 'Requesting access token');

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        extraData: this.buildFormData(requestBody)
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as TokenResponse;
        this.accessToken = result.access_token;
        this.refreshToken = result.refresh_token;
        
        hilog.info(DOMAIN, TAG, `Access token obtained, expires in ${result.expires_in} seconds`);
        
        return result;
      } else {
        hilog.error(DOMAIN, TAG, `Token request failed: ${response.responseCode}`);
        throw new Error(`Token request failed: ${response.responseCode}`);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Network error: ${err.message}`);
      throw error;
    }
  }

  async getRealNameAgeRange(): Promise<number> {
    const url = 'https://account-api.huawei.com/rest.php?nsp_svc=HUAWEI_EXTERNAL_IDENTITY.getRealNameAgeRange';

    hilog.info(DOMAIN, TAG, 'Requesting age range');

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as AgeRangeResponse;
        
        if (result.retCode === 0) {
          hilog.info(DOMAIN, TAG, `Age range obtained: ${result.ageRange}`);
          return result.ageRange;
        } else {
          hilog.error(DOMAIN, TAG, `API returned error: ${result.retCode}`);
          throw new Error(`API error: ${result.retCode}`);
        }
      } else {
        hilog.error(DOMAIN, TAG, `Age range request failed: ${response.responseCode}`);
        throw new Error(`Request failed: ${response.responseCode}`);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Network error: ${err.message}`);
      throw error;
    }
  }

  async refreshAccessToken(): Promise<TokenResponse> {
    const url = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';
    
    const requestBody = {
      grant_type: 'refresh_token',
      refresh_token: this.refreshToken,
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret
    };

    hilog.info(DOMAIN, TAG, 'Refreshing access token');

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        extraData: this.buildFormData(requestBody)
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string) as TokenResponse;
        this.accessToken = result.access_token;
        
        if (result.refresh_token) {
          this.refreshToken = result.refresh_token;
        }
        
        hilog.info(DOMAIN, TAG, `Token refreshed successfully`);
        
        return result;
      } else {
        hilog.error(DOMAIN, TAG, `Token refresh failed: ${response.responseCode}`);
        throw new Error(`Token refresh failed: ${response.responseCode}`);
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Network error: ${err.message}`);
      throw error;
    }
  }

  async getAgeRangeWithRetry(authorizationCode: string, maxRetries: number = 3): Promise<number> {
    let retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        if (!this.accessToken) {
          await this.getAccessToken(authorizationCode);
        }
        
        return await this.getRealNameAgeRange();
        
      } catch (error) {
        const err = error as BusinessError;
        
        if (this.isTokenExpired(err)) {
          hilog.warn(DOMAIN, TAG, 'Token expired, refreshing...');
          await this.refreshAccessToken();
          retryCount++;
          continue;
        }
        
        hilog.error(DOMAIN, TAG, `Request failed: ${err.message}`);
        throw error;
      }
    }
    
    throw new Error('Max retries exceeded');
  }

  private isTokenExpired(error: BusinessError): boolean {
    return error.message?.includes('401') || error.message?.includes('403');
  }

  private buildFormData(data: Record<string, string>): string {
    return Object.entries(data)
      .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
      .join('&');
  }

  getStoredTokens(): { accessToken: string; refreshToken: string } {
    return {
      accessToken: this.accessToken,
      refreshToken: this.refreshToken
    };
  }
}

export function createServerInstance(clientId: string, clientSecret: string, redirectUri: string): RealNameAgeRangeServer {
  return new RealNameAgeRangeServer({
    clientId,
    clientSecret,
    redirectUri
  });
}

export function getAgeRangeDescription(ageRange: number): string {
  const ageRangeMap: Record<number, string> = {
    0: '0-17岁',
    1: '18-25岁',
    2: '26-35岁',
    3: '36-45岁',
    4: '46-55岁',
    5: '56岁以上'
  };
  
  return ageRangeMap[ageRange] || `未知年龄段(${ageRange})`;
}