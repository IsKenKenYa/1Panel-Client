import jwt from 'jsonwebtoken';

export class JWSUtil {
  private static readonly LEAF_CERT_OID = '1.3.6.1.4.1.2011.2.415.1.1';
  private static readonly HEADER_PARAM_X5C = 'x5c';
  private static readonly HEADER_PARAM_ALG_ES256 = 'ES256';
  
  static decodeJwsObj(jwsStr: string): string {
    if (!jwsStr || jwsStr.trim().length === 0) {
      throw new Error('JWS string is empty or null');
    }
    
    const decodedJWT = jwt.decode(jwsStr, { complete: true });
    
    if (!decodedJWT || typeof decodedJWT === 'string') {
      throw new Error('Failed to decode JWS');
    }
    
    const header = decodedJWT.header as any;
    const payload = decodedJWT.payload;
    
    if (header.alg !== this.HEADER_PARAM_ALG_ES256) {
      throw new Error(`Algorithm must be ES256, got ${header.alg}`);
    }
    
    const x5cChain = header[this.HEADER_PARAM_X5C];
    if (!x5cChain || !Array.isArray(x5cChain)) {
      throw new Error('x5c certificate chain not found in header');
    }
    
    console.info('[JWS验签] 解码成功，算法: ES256');
    
    return JSON.stringify(payload);
  }
  
  static async verifyJws(jwsStr: string, publicKey: string): Promise<boolean> {
    try {
      jwt.verify(jwsStr, publicKey, { algorithms: ['ES256'] });
      console.info('[JWS验签] 验签成功');
      return true;
    } catch (error) {
      console.error('[JWS验签] 验签失败:', error);
      return false;
    }
  }
  
  static extractPayload(jwsStr: string): any {
    const payloadStr = this.decodeJwsObj(jwsStr);
    return JSON.parse(payloadStr);
  }
}