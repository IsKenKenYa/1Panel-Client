/**
 * 服务端验证系统完整性检测结果 - Node.js实现
 * 
 * 该文件展示如何在应用服务器端验证JWS格式的系统完整性检测结果
 * 
 * 使用方法：
 * 1. 安装依赖：npm install crypto
 * 2. 导入模块：const IntegrityResultVerifier = require('./server_verification.js');
 * 3. 使用验证器：const verifier = new IntegrityResultVerifier();
 * 4. 验证结果：const result = await verifier.verifyIntegrityResult(jws, nonce, bundleName, appId);
 */

const crypto = require('crypto');

/**
 * JWS Header结构
 */
interface JWSHeader {
  alg: string;
  typ: string;
  x5c: string[];
}

/**
 * JWS Payload结构
 */
interface JWSPayload {
  hapCertificateSha256: string;
  hapBundleName: string;
  appId: string;
  basicIntegrity: boolean;
  version: number;
  detail?: string[];
  nonce: string;
  timestamp: number;
}

/**
 * 验证结果结构
 */
interface VerificationResult {
  isValid: boolean;
  payload?: JWSPayload;
  error?: string;
}

/**
 * 风险评估结果
 */
interface RiskAssessment {
  risk: 'high' | 'medium' | 'low';
  reasons: string[];
  suggestion: string;
}

/**
 * 系统完整性检测结果验证器
 */
class IntegrityResultVerifier {
  
  /**
   * 华为根证书（需要从华为官方下载并替换）
   * 下载地址：https://pki.consumer.huawei.com/ca/cer/Huawei_CBG_ECC_Device_Attestation_Root_CA.cer
   */
  private readonly ROOT_CA_CERT = `-----BEGIN CERTIFICATE-----
MIICuzCCAmOgAwIBAgIJAKUAAAAAAAAAMA0GCSqGSIb3DQEBCwUAMB4xCzAJBgNV
BAYTAkNOMQ8wDQYDVQQKDAZIVUFXRUkxGzAZBgNVBAMMEkhVQVdFSSBDQkcgUm9vd
IENBMB4XDTIwMDExMDAwMDAwMFoXDTMwMDExMDAwMDAwMFowHjELMAkGA1UEBhMC
Q04xDzANBglghkgBZQMEAgEwgZswEAYKKwYBBAGCNwQDNTA2oIGGMIGDBgsrBgEE
AYI3DQIDBggrBgEFBQcDAzALBgkqhkiG9n0HMREwDzANBglghkgBZQMEAgEFBgsr
BgEEAYI3DQIDATA9MCkGCisGAQQBgjcUAgOgMD4ORkhIVUFXRUkgQ0JHIERldmlj
ZSBBdHRlc3RhdGlvbiBTZXJ2aWNlMBMGCisGAQQBgjcUAgMBBggrBgEFBQcDBDAW
BgkrBgEEAYI3DQIDDAYIKwYBBQUHAwQwCQYHKwYBBAGCNwUHMB8GA1UdIwQYMBaA
FIVIVUFXRUkgQ0JHIERldmljZSBBdHRlc3RhdGlvbiBTZXJ2aWNlMA8GA1UdEwEB
/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADgYEAToJ1pZ9o3gdQXM8+OXi8+0F8V9q
-----END CERTIFICATE-----`;
  
  /**
   * 验证JWS格式的检测结果
   * 
   * @param jwsResult JWS格式的检测结果字符串
   * @param expectedNonce 预期的nonce值
   * @param expectedBundleName 预期的应用包名
   * @param expectedAppId 预期的应用ID
   * @returns 验证结果对象
   */
  async verifyIntegrityResult(
    jwsResult: string,
    expectedNonce: string,
    expectedBundleName: string,
    expectedAppId: string
  ): Promise<VerificationResult> {
    try {
      console.log('[Verifier] Starting JWS verification');
      
      if (!jwsResult) {
        return { isValid: false, error: 'JWS result is empty' };
      }
      
      const parts = jwsResult.split('.');
      if (parts.length !== 3) {
        return { isValid: false, error: 'Invalid JWS format: must have 3 parts' };
      }
      
      const header = this.decodeBase64(parts[0]);
      const payload = this.decodeBase64(parts[1]);
      const signature = parts[2];
      
      console.log('[Verifier] Header:', header);
      console.log('[Verifier] Payload:', payload);
      
      const headerObj: JWSHeader = JSON.parse(header);
      const payloadObj: JWSPayload = JSON.parse(payload);
      
      if (!headerObj.x5c || headerObj.x5c.length !== 3) {
        return { isValid: false, error: 'Invalid certificate chain' };
      }
      
      const certValidation = this.validateCertificateChain(headerObj.x5c);
      if (!certValidation.isValid) {
        return { isValid: false, error: certValidation.error };
      }
      
      const signatureValidation = this.validateSignature(
        parts[0], 
        parts[1], 
        signature, 
        headerObj.x5c[0]
      );
      if (!signatureValidation.isValid) {
        return { isValid: false, error: signatureValidation.error };
      }
      
      if (payloadObj.nonce !== expectedNonce) {
        return { isValid: false, error: 'Nonce mismatch' };
      }
      
      if (payloadObj.hapBundleName !== expectedBundleName) {
        return { isValid: false, error: 'Bundle name mismatch' };
      }
      
      if (payloadObj.appId !== expectedAppId) {
        return { isValid: false, error: 'App ID mismatch' };
      }
      
      const now = Date.now();
      const maxAge = 10 * 60 * 1000;
      if (now - payloadObj.timestamp > maxAge) {
        return { isValid: false, error: 'Result expired' };
      }
      
      console.log('[Verifier] Verification succeeded');
      
      return { isValid: true, payload: payloadObj };
      
    } catch (error) {
      console.error('[Verifier] Verification failed:', error.message);
      return { isValid: false, error: `Verification failed: ${error.message}` };
    }
  }
  
  /**
   * 解码Base64字符串
   */
  private decodeBase64(base64Str: string): string {
    return Buffer.from(base64Str, 'base64').toString('utf8');
  }
  
  /**
   * 验证证书链
   */
  private validateCertificateChain(x5c: string[]): { isValid: boolean; error?: string } {
    try {
      if (x5c.length !== 3) {
        return { isValid: false, error: 'Certificate chain must have 3 certificates' };
      }
      
      const leafCert = this.formatCertificate(x5c[0]);
      const leafCertObj = new crypto.X509Certificate(leafCert);
      
      const subjectCN = leafCertObj.subject.split('\n').find(s => s.includes('CN='));
      if (!subjectCN || !subjectCN.includes('Harmony OS Device Attestation Service')) {
        return { isValid: false, error: 'Invalid certificate CN' };
      }
      
      console.log('[Verifier] Certificate chain validation passed');
      
      return { isValid: true };
      
    } catch (error) {
      return { isValid: false, error: `Certificate validation failed: ${error.message}` };
    }
  }
  
  /**
   * 格式化证书字符串
   */
  private formatCertificate(certBase64: string): string {
    return `-----BEGIN CERTIFICATE-----\n${certBase64}\n-----END CERTIFICATE-----`;
  }
  
  /**
   * 验证签名
   */
  private validateSignature(
    headerBase64: string,
    payloadBase64: string,
    signatureBase64: string,
    leafCertBase64: string
  ): { isValid: boolean; error?: string } {
    try {
      const leafCert = this.formatCertificate(leafCertBase64);
      const leafCertObj = new crypto.X509Certificate(leafCert);
      
      const dataToSign = `${headerBase64}.${payloadBase64}`;
      const signature = Buffer.from(signatureBase64, 'base64');
      
      const isValid = crypto.verify(
        'RSA-SHA256',
        Buffer.from(dataToSign),
        leafCertObj.publicKey,
        signature
      );
      
      if (!isValid) {
        return { isValid: false, error: 'Signature verification failed' };
      }
      
      console.log('[Verifier] Signature validation passed');
      
      return { isValid: true };
      
    } catch (error) {
      return { isValid: false, error: `Signature validation failed: ${error.message}` };
    }
  }
  
  /**
   * 根据检测结果评估风险等级
   */
  evaluateRisk(payload: JWSPayload): RiskAssessment {
    if (payload.basicIntegrity === true) {
      return {
        risk: 'low',
        reasons: [],
        suggestion: '设备环境安全，可以正常使用'
      };
    }
    
    const reasons: string[] = [];
    
    if (payload.detail && Array.isArray(payload.detail)) {
      if (payload.detail.includes('jailbreak')) {
        reasons.push('设备已越狱');
      }
      if (payload.detail.includes('emulator')) {
        reasons.push('设备为模拟器');
      }
      if (payload.detail.includes('attack')) {
        reasons.push('设备已被攻击');
      }
      if (payload.detail.includes('unlock')) {
        reasons.push('设备已解锁');
      }
    }
    
    if (payload.detail?.includes('attack') || payload.detail?.includes('jailbreak')) {
      return {
        risk: 'high',
        reasons: reasons,
        suggestion: '存在高风险，建议限制敏感操作'
      };
    } else if (payload.detail?.includes('emulator') || payload.detail?.includes('unlock')) {
      return {
        risk: 'medium',
        reasons: reasons,
        suggestion: '存在中等风险，建议谨慎操作'
      };
    } else {
      return {
        risk: 'medium',
        reasons: ['检测到未知风险'],
        suggestion: '建议谨慎操作'
      };
    }
  }
}

module.exports = IntegrityResultVerifier;

/**
 * 使用示例
 * 
 * ```javascript
 * const IntegrityResultVerifier = require('./server_verification.js');
 * 
 * const verifier = new IntegrityResultVerifier();
 * 
 * async function handleIntegrityCheckRequest(req, res) {
 *   const { jwsResult, nonce, bundleName, appId } = req.body;
 *   
 *   const verification = await verifier.verifyIntegrityResult(
 *     jwsResult,
 *     nonce,
 *     bundleName,
 *     appId
 *   );
 *   
 *   if (verification.isValid) {
 *     const risk = verifier.evaluateRisk(verification.payload);
 *     
 *     if (risk.risk === 'high') {
 *       res.json({
 *         isValid: true,
 *         riskLevel: 'high',
 *         reasons: risk.reasons,
 *         action: 'restrict'
 *       });
 *     } else if (risk.risk === 'medium') {
 *       res.json({
 *         isValid: true,
 *         riskLevel: 'medium',
 *         reasons: risk.reasons,
 *         action: 'warn'
 *       });
 *     } else {
 *       res.json({
 *         isValid: true,
 *         riskLevel: 'low',
 *         action: 'allow'
 *       });
 *     }
 *   } else {
 *     res.status(400).json({
 *       isValid: false,
 *       error: verification.error
 *     });
 *   }
 * }
 * ```
 */