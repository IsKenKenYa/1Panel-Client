import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export class JWSUtil {
  private static readonly IAP_PUBLIC_KEY = 'YOUR_IAP_PUBLIC_KEY_HERE';

  static decodeJwsObj(jwsStr: string): string {
    try {
      const parts = jwsStr.split('.');
      if (parts.length !== 3) {
        throw new Error('Invalid JWS format');
      }

      const header = this.base64Decode(parts[0]);
      const payload = this.base64Decode(parts[1]);
      const signature = parts[2];

      const headerObj = JSON.parse(header);
      console.info('JWS Header:', headerObj);

      const isValid = this.verifySignature(parts[0] + '.' + parts[1], signature);
      if (!isValid) {
        throw new Error('Invalid JWS signature');
      }

      return payload;
    } catch (error) {
      console.error('Failed to decode JWS:', error);
      throw error;
    }
  }

  private static base64Decode(str: string): string {
    const base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    let i = 0;
    
    str = str.replace(/[^A-Za-z0-9\+\/]/g, '');
    
    while (i < str.length) {
      const c1 = base64Chars.indexOf(str.charAt(i++));
      const c2 = base64Chars.indexOf(str.charAt(i++));
      const c3 = base64Chars.indexOf(str.charAt(i++));
      const c4 = base64Chars.indexOf(str.charAt(i++));

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

  private static async verifySignature(data: string, signature: string): Promise<boolean> {
    try {
      const pubKeyBlob: cryptoFramework.DataBlob = {
        data: new Uint8Array(Array.from(this.base64Decode(this.IAP_PUBLIC_KEY)).map(c => c.charCodeAt(0)))
      };

      const keyGenerator = cryptoFramework.createAsyKeyGenerator('RSA1024');
      const pubKey = await keyGenerator.convertKey(pubKeyBlob, null);

      const verifier = cryptoFramework.createSignature('RSA1024|PKCS1|SHA256');
      await verifier.init(pubKey);

      const dataBlob: cryptoFramework.DataBlob = {
        data: new Uint8Array(Array.from(data).map(c => c.charCodeAt(0)))
      };

      const signBlob: cryptoFramework.DataBlob = {
        data: new Uint8Array(Array.from(this.base64Decode(signature)).map(c => c.charCodeAt(0)))
      };

      const isValid = await verifier.verify(dataBlob, signBlob);
      return isValid;
    } catch (error) {
      console.error('Failed to verify signature:', error);
      return false;
    }
  }

  static setPublicKey(publicKey: string): void {
    this.IAP_PUBLIC_KEY = publicKey;
  }
}