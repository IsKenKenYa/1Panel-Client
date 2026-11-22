import axios from 'axios';

const HUAWEI_TOKEN_URL = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';
const HUAWEI_AGEGANGE_URL = 'https://account-api.huawei.com/v1/user/realnameAgeRange';

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

interface AgeRangeResponse {
  ageRange: string;
}

export class RealNameAgeRangeServer {
  private clientId: string;
  private clientSecret: string;

  constructor(clientId: string, clientSecret: string) {
    this.clientId = clientId;
    this.clientSecret = clientSecret;
  }

  async getAccessToken(authorizationCode: string): Promise<TokenResponse> {
    try {
      const response = await axios.post(HUAWEI_TOKEN_URL, {
        grant_type: 'authorization_code',
        code: authorizationCode,
        client_id: this.clientId,
        client_secret: this.clientSecret
      }, {
        headers: { 'Content-Type': 'application/json' }
      });

      const data = response.data;
      console.log(`Access Token obtained, expires in ${data.expires_in} seconds`);
      
      return {
        access_token: data.access_token,
        refresh_token: data.refresh_token,
        expires_in: data.expires_in
      };
    } catch (error) {
      console.error('Failed to get Access Token:', error);
      throw error;
    }
  }

  async getRealNameAgeRange(accessToken: string): Promise<string> {
    try {
      const response = await axios.get(HUAWEI_AGEGANGE_URL, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      const data: AgeRangeResponse = response.data;
      console.log(`Age Range obtained: ${data.ageRange}`);
      
      return data.ageRange;
    } catch (error) {
      console.error('Failed to get Age Range:', error);
      throw error;
    }
  }

  async refreshAccessToken(refreshToken: string): Promise<string> {
    try {
      const response = await axios.post(HUAWEI_TOKEN_URL, {
        grant_type: 'refresh_token',
        refresh_token: refreshToken,
        client_id: this.clientId,
        client_secret: this.clientSecret
      }, {
        headers: { 'Content-Type': 'application/json' }
      });

      const data = response.data;
      console.log(`Access Token refreshed, expires in ${data.expires_in} seconds`);
      
      return data.access_token;
    } catch (error) {
      console.error('Failed to refresh Access Token:', error);
      throw error;
    }
  }

  async processAuthorizationCode(authorizationCode: string): Promise<string> {
    try {
      const tokenResponse = await this.getAccessToken(authorizationCode);
      const ageRange = await this.getRealNameAgeRange(tokenResponse.access_token);
      
      return ageRange;
    } catch (error) {
      console.error('Failed to process Authorization Code:', error);
      throw error;
    }
  }
}

export async function main(authorizationCode: string): Promise<void> {
  const clientId = 'YOUR_CLIENT_ID';
  const clientSecret = 'YOUR_CLIENT_SECRET';
  
  const server = new RealNameAgeRangeServer(clientId, clientSecret);
  
  try {
    const ageRange = await server.processAuthorizationCode(authorizationCode);
    console.log(`Final Age Range: ${ageRange}`);
  } catch (error) {
    console.error('Error in main process:', error);
  }
}