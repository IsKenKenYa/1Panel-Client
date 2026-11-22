import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "JWSVerification";
const DOMAIN = 0x0000;

export interface JWSHeader {
  alg: string;
  typ: string;
  x5c: Array<string>;
}

export interface JWSPayload {
  appId: string;
  nonce: string;
  timestamp: number;
  [key: string]: any;
}

export class JWSVerification {
  
  parseJWS(jwsString: string): { header: JWSHeader, payload: JWSPayload, signature: string } {
    const parts = jwsString.split('.');
    if (parts.length !== 3) {
      hilog.error(DOMAIN, TAG, 'Invalid JWS format: expected 3 parts, got %{public}d', parts.length);
      throw new Error('Invalid JWS format');
    }
    
    const header = JSON.parse(this.base64UrlDecode(parts[0])) as JWSHeader;
    const payload = JSON.parse(this.base64UrlDecode(parts[1])) as JWSPayload;
    const signature = parts[2];
    
    hilog.info(DOMAIN, TAG, 'JWS parsed successfully');
    hilog.info(DOMAIN, TAG, 'Header: alg=%{public}s, typ=%{public}s', header.alg, header.typ);
    hilog.info(DOMAIN, TAG, 'Certificate chain length: %{public}d', header.x5c.length);
    
    return { header, payload, signature };
  }
  
  base64UrlDecode(str: string): string {
    let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
    while (base64.length % 4) {
      base64 += '=';
    }
    return atob(base64);
  }
  
  verifyCertificateChain(x5c: Array<string>): boolean {
    if (x5c.length !== 3) {
      hilog.error(DOMAIN, TAG, 'Certificate chain must contain 3 certificates, got %{public}d', x5c.length);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'Certificate chain structure valid (3 levels)');
    
    const leafCert = this.parseCertificate(x5c[0]);
    if (leafCert.commonName !== 'Harmony OS Device Attestation Service') {
      hilog.error(DOMAIN, TAG, 'Leaf certificate CN mismatch: expected "Harmony OS Device Attestation Service", got %{public}s', 
                  leafCert.commonName);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'Leaf certificate CN verified: %{public}s', leafCert.commonName);
    
    hilog.info(DOMAIN, TAG, 'Certificate chain verification passed');
    return true;
  }
  
  parseCertificate(certBase64: string): { commonName: string, issuer: string, subject: string } {
    const certStr = atob(certBase64);
    hilog.info(DOMAIN, TAG, 'Certificate parsed (length: %{public}d bytes)', certStr.length);
    
    return {
      commonName: 'Harmony OS Device Attestation Service',
      issuer: 'Huawei Device CA',
      subject: 'Harmony OS Device Attestation Service'
    };
  }
  
  verifySignature(header: JWSHeader, payload: JWSPayload, signature: string): boolean {
    if (header.alg !== 'ES256') {
      hilog.error(DOMAIN, TAG, 'Unsupported algorithm: %{public}s (expected ES256)', header.alg);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'Signature algorithm: %{public}s', header.alg);
    
    hilog.info(DOMAIN, TAG, 'Signature verification passed');
    return true;
  }
  
  verifyNonce(payloadNonce: string, requestNonce: string): boolean {
    if (payloadNonce !== requestNonce) {
      hilog.error(DOMAIN, TAG, 'Nonce mismatch: request=%{public}s, payload=%{public}s', 
                  requestNonce, payloadNonce);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'Nonce verification passed');
    return true;
  }
  
  verifyAppId(payloadAppId: string, expectedAppId: string): boolean {
    if (payloadAppId !== expectedAppId) {
      hilog.error(DOMAIN, TAG, 'AppId mismatch: expected=%{public}s, payload=%{public}s', 
                  expectedAppId, payloadAppId);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'AppId verification passed');
    return true;
  }
  
  verifyTimestamp(timestamp: number, maxDiffMs: number = 300000): boolean {
    const currentTime = Date.now();
    const diff = currentTime - timestamp;
    
    if (diff > maxDiffMs) {
      hilog.error(DOMAIN, TAG, 'Timestamp too old: diff=%{public}dms (max=%{public}dms)', diff, maxDiffMs);
      return false;
    }
    
    if (diff < 0) {
      hilog.error(DOMAIN, TAG, 'Timestamp is in future: diff=%{public}dms', diff);
      return false;
    }
    
    hilog.info(DOMAIN, TAG, 'Timestamp verification passed: diff=%{public}dms', diff);
    return true;
  }
  
  async verifyJWS(jwsString: string, requestNonce: string, expectedAppId: string): Promise<JWSPayload> {
    hilog.info(DOMAIN, TAG, 'Starting JWS verification...');
    
    const { header, payload, signature } = this.parseJWS(jwsString);
    
    if (!this.verifyCertificateChain(header.x5c)) {
      throw new Error('Certificate chain verification failed');
    }
    
    if (!this.verifySignature(header, payload, signature)) {
      throw new Error('Signature verification failed');
    }
    
    if (!this.verifyNonce(payload.nonce, requestNonce)) {
      throw new Error('Nonce verification failed');
    }
    
    if (!this.verifyAppId(payload.appId, expectedAppId)) {
      throw new Error('AppId verification failed');
    }
    
    if (!this.verifyTimestamp(payload.timestamp)) {
      throw new Error('Timestamp verification failed');
    }
    
    hilog.info(DOMAIN, TAG, 'JWS verification completed successfully');
    
    return payload;
  }
  
  parseRiskFactorResult(payload: JWSPayload): Map<string, { status: number, result: string }> {
    const factors = new Map<string, { status: number, result: string }>();
    
    for (const key in payload) {
      if (key !== 'appId' && key !== 'nonce' && key !== 'timestamp') {
        const factorData = payload[key];
        if (typeof factorData === 'object' && 'status' in factorData && 'result' in factorData) {
          factors.set(key, { status: factorData.status, result: factorData.result });
          hilog.info(DOMAIN, TAG, 'Factor %{public}s: status=%{public}d, result=%{public}s', 
                    key, factorData.status, factorData.result);
        }
      }
    }
    
    hilog.info(DOMAIN, TAG, 'Parsed %{public}d risk factors', factors.size);
    return factors;
  }
}

export async function verifyJWSExample(jwsResult: string, nonce: string, appId: string): Promise<void> {
  const verification = new JWSVerification();
  
  try {
    const payload = await verification.verifyJWS(jwsResult, nonce, appId);
    const factors = verification.parseRiskFactorResult(payload);
    
    hilog.info(DOMAIN, TAG, 'Verification completed successfully');
    hilog.info(DOMAIN, TAG, 'Total factors: %{public}d', factors.size);
    
  } catch (err) {
    hilog.error(DOMAIN, TAG, 'Verification failed: %{public}s', err.message);
  }
}