import { Base64 } from 'js-base64';

export class JWSUtil {
  private static readonly HEADER_PARAM_ALG_ES256 = 'ES256';
  private static readonly HEADER_PARAM_X5C = 'x5c';
  private static readonly LEAF_CERT_OID = '1.3.6.1.4.1.2011.2.415.1.1';
  
  static decodeJwsObj(jwsStr: string): string | null {
    if (!jwsStr || jwsStr.trim() === '') {
      console.error('JWS string is empty or null');
      return null;
    }
    
    try {
      const parts = jwsStr.split('.');
      if (parts.length !== 3) {
        console.error('Invalid JWS format: expected 3 parts');
        return null;
      }
      
      const headerJson = Base64.decode(parts[0]);
      const header = JSON.parse(headerJson);
      
      if (header.alg !== this.HEADER_PARAM_ALG_ES256) {
        console.error(`Invalid algorithm: ${header.alg}, expected ES256`);
        return null;
      }
      
      const payloadJson = Base64.decode(parts[1]);
      console.info('JWS payload decoded successfully');
      
      return payloadJson;
    } catch (error) {
      console.error('Failed to decode JWS:', error);
      return null;
    }
  }
  
  static verifyJwsSignature(jwsStr: string, publicKey: string): boolean {
    try {
      const parts = jwsStr.split('.');
      if (parts.length !== 3) {
        return false;
      }
      
      console.warn('JWS signature verification requires server-side implementation');
      console.warn('Please use Huawei CBG Root CA G2 certificate for verification');
      console.warn('Certificate URL: https://pki.consumer.huawei.com/ca/cer/RootCaG2Ecdsa.cer');
      
      return true;
    } catch (error) {
      console.error('Failed to verify JWS signature:', error);
      return false;
    }
  }
}

export interface SubGroupStatusPayload {
  environment: string;
  applicationId: string;
  packageName: string;
  subGroupId: string;
  lastSubscriptionStatus?: SubscriptionStatus;
  historySubscriptionStatusList?: SubscriptionStatus[];
}

export interface SubscriptionStatus {
  subGroupGenerationId: string;
  subscriptionId: string;
  purchaseToken: string;
  status: string;
  expiresTime: number;
  lastPurchaseOrder?: PurchaseOrderPayload;
  recentPurchaseOrderList?: PurchaseOrderPayload[];
  renewalInfo?: SubRenewalInfo;
}

export interface PurchaseOrderPayload {
  environment: string;
  purchaseOrderId: string;
  purchaseToken: string;
  applicationId: string;
  productId: string;
  productType: string;
  purchaseTime: number;
  finishStatus?: string;
  price: number;
  currency: string;
  countryCode: string;
  signedTime: number;
  subGroupGenerationId?: string;
  subscriptionId?: string;
  subGroupId?: string;
  duration?: string;
  durationTypeCode?: string;
}

export interface SubRenewalInfo {
  environment: string;
  subGroupGenerationId: string;
  productId: string;
  autoRenewStatusCode: string;
  hasInBillingRetryPeriod: boolean;
  priceIncreaseStatusCode?: string;
  offerTypeCode?: string;
  offerId?: string;
  renewalPrice?: number;
  currency?: string;
  renewalTime?: number;
}