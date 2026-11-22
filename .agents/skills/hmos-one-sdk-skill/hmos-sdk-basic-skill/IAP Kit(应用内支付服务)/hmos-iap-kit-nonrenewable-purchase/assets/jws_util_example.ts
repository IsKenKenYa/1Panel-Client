import crypto from 'crypto';

export class JWSUtil {
  private static publicKey: string = '';

  static setPublicKey(key: string): void {
    JWSUtil.publicKey = key;
  }

  static decodeJwsObj(jws: string): string {
    const parts = jws.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid JWS format: must have 3 parts');
    }

    const header = parts[0];
    const payload = parts[1];
    const signature = parts[2];

    const headerJson = JWSUtil.base64Decode(header);
    const headerObj = JSON.parse(headerJson);

    if (headerObj.alg !== 'RS256') {
      throw new Error(`Unsupported algorithm: ${headerObj.alg}`);
    }

    const payloadJson = JWSUtil.base64Decode(payload);

    const isValid = JWSUtil.verifySignature(header, payload, signature);
    if (!isValid) {
      throw new Error('JWS signature verification failed');
    }

    return payloadJson;
  }

  static base64Decode(str: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    let i = 0;

    str = str.replace(/[^A-Za-z0-9+/]/g, '');

    while (i < str.length) {
      const c1 = chars.indexOf(str.charAt(i++));
      const c2 = chars.indexOf(str.charAt(i++));
      const c3 = chars.indexOf(str.charAt(i++));
      const c4 = chars.indexOf(str.charAt(i++));

      const b1 = (c1 << 2) | (c2 >> 4);
      const b2 = ((c2 & 15) << 4) | (c3 >> 2);
      const b3 = ((c3 & 3) << 6) | c4;

      result += String.fromCharCode(b1);
      if (c3 !== 64) {
        result += String.fromCharCode(b2);
      }
      if (c4 !== 64) {
        result += String.fromCharCode(b3);
      }
    }

    return decodeURIComponent(escape(result));
  }

  static verifySignature(header: string, payload: string, signature: string): boolean {
    if (!JWSUtil.publicKey) {
      console.warn('Public key not set, skipping signature verification');
      return true;
    }

    try {
      const signingInput = `${header}.${payload}`;
      const signatureBuffer = Buffer.from(signature, 'base64');

      const verify = crypto.createVerify('RSA-SHA256');
      verify.update(signingInput);
      verify.end();

      const publicKeyObj = crypto.createPublicKey({
        key: JWSUtil.publicKey,
        format: 'pem',
        type: 'spki'
      });

      return verify.verify(publicKeyObj, signatureBuffer);
    } catch (err) {
      console.error('Signature verification error:', err);
      return false;
    }
  }

  static base64Encode(str: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    let i = 0;

    const bytes = unescape(encodeURIComponent(str));

    while (i < bytes.length) {
      const b1 = bytes.charCodeAt(i++);
      const b2 = i < bytes.length ? bytes.charCodeAt(i++) : 0;
      const b3 = i < bytes.length ? bytes.charCodeAt(i++) : 0;

      const c1 = b1 >> 2;
      const c2 = ((b1 & 3) << 4) | (b2 >> 4);
      const c3 = ((b2 & 15) << 2) | (b3 >> 6);
      const c4 = b3 & 63;

      result += chars.charAt(c1) + chars.charAt(c2);
      result += i - 2 < bytes.length ? chars.charAt(c3) : '=';
      result += i - 1 < bytes.length ? chars.charAt(c4) : '=';
    }

    return result;
  }
}

export default JWSUtil;