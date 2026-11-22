import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "RiskFactorsExample";
const DOMAIN = 0x0000;

export class RiskFactorsQueryExample {
  private nonce: string = '';
  
  async queryRiskFactors(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting risk factors query...');
      
      const nonce = this.generateNonce();
      const request: safetyDetect.RiskFactorRequest = {
        nonce: nonce,
        queries: [
          { factor: safetyDetect.RiskFactorType.HDC_DEBUG_STATE },
          { factor: safetyDetect.RiskFactorType.IS_DEVELOPER_MODE },
          { factor: safetyDetect.RiskFactorType.ODID_RESET_CNT },
          { factor: safetyDetect.RiskFactorType.IS_VPN_STATUS },
          { factor: safetyDetect.RiskFactorType.SIM_CNT }
        ]
      };
      
      hilog.info(DOMAIN, TAG, 'Nonce: %{public}s', nonce);
      hilog.info(DOMAIN, TAG, 'Query factors: %{public}d', request.queries.length);
      
      const response: safetyDetect.RiskFactorResponse = await safetyDetect.queryRiskFactors(request);
      
      hilog.info(DOMAIN, TAG, 'Query succeeded, JWS result length: %{public}d', response.result.length);
      
      await this.processJWSResult(response.result, nonce);
      
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      hilog.error(DOMAIN, TAG, 'Query failed: %{public}d %{public}s', e.code, e.message);
      this.handleError(e);
    }
  }
  
  private generateNonce(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let nonce = '';
    for (let i = 0; i < 32; i++) {
      nonce += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    this.nonce = nonce;
    return nonce;
  }
  
  private async processJWSResult(jwsResult: string, requestNonce: string): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Processing JWS result...');
    
    const parts = jwsResult.split('.');
    if (parts.length !== 3) {
      hilog.error(DOMAIN, TAG, 'Invalid JWS format');
      return;
    }
    
    try {
      const header = JSON.parse(this.base64UrlDecode(parts[0]));
      const payload = JSON.parse(this.base64UrlDecode(parts[1]));
      
      hilog.info(DOMAIN, TAG, 'Header alg: %{public}s', header.alg);
      hilog.info(DOMAIN, TAG, 'Header typ: %{public}s', header.typ);
      hilog.info(DOMAIN, TAG, 'Certificate chain length: %{public}d', header.x5c.length);
      
      hilog.info(DOMAIN, TAG, 'Payload nonce: %{public}s', payload.nonce);
      hilog.info(DOMAIN, TAG, 'Payload appId: %{public}s', payload.appId);
      hilog.info(DOMAIN, TAG, 'Payload timestamp: %{public}d', payload.timestamp);
      
      if (payload.nonce !== requestNonce) {
        hilog.error(DOMAIN, TAG, 'Nonce mismatch! Request: %{public}s, Response: %{public}s', 
                    requestNonce, payload.nonce);
        return;
      }
      
      hilog.info(DOMAIN, TAG, 'Nonce verification passed');
      
      for (const key in payload) {
        if (key !== 'appId' && key !== 'nonce' && key !== 'timestamp') {
          const factorData = payload[key];
          hilog.info(DOMAIN, TAG, 'Factor %{public}s: status=%{public}d, result=%{public}s', 
                    key, factorData.status, factorData.result);
        }
      }
      
    } catch (parseErr) {
      hilog.error(DOMAIN, TAG, 'JWS parse error: %{public}s', parseErr.message);
    }
  }
  
  private base64UrlDecode(str: string): string {
    let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
    while (base64.length % 4) {
      base64 += '=';
    }
    return atob(base64);
  }
  
  private handleError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied. Check service activation and profile.');
        break;
      case 401:
        hilog.error(DOMAIN, TAG, 'Invalid parameters. Check nonce length and format.');
        break;
      case 801:
        hilog.error(DOMAIN, TAG, 'API not supported. Update API version to >= 26.0.0.');
        break;
      case 1010800001:
        hilog.error(DOMAIN, TAG, 'Internal error. Try again later.');
        break;
      case 1010800002:
        hilog.error(DOMAIN, TAG, 'Network unreachable. Check network connection.');
        break;
      case 1010800003:
        hilog.error(DOMAIN, TAG, 'Cloud server access failed. Try again later.');
        break;
      case 1010800005:
        hilog.error(DOMAIN, TAG, 'Concurrent calls exceeded limit (max 10). Wait for other calls to complete.');
        break;
      case 1010800006:
        hilog.error(DOMAIN, TAG, 'Frequency exceeded limit (max 5/min, 20/day). Try again later.');
        break;
      case 1010800007:
        hilog.error(DOMAIN, TAG, 'Operation timeout. Check network status.');
        break;
      case 1010800008:
        hilog.error(DOMAIN, TAG, 'Cloud service traffic exceeded. Try again later.');
        break;
      default:
        hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d %{public}s', error.code, error.message);
        break;
    }
  }
}

async function main(): Promise<void> {
  const example = new RiskFactorsQueryExample();
  await example.queryRiskFactors();
}

main();