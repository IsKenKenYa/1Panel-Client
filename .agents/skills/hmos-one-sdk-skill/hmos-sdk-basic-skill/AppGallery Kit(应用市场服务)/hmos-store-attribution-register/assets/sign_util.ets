import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

export class SignUtil {
  static async getSign(signContent: string, privateKey: string): Promise<string> {
    try {
      const keyBlob: cryptoFramework.DataBlob = {
        data: new Uint8Array(Array.from(privateKey).map(c => c.charCodeAt(0)))
      };
      
      const asymKeyGenerator = cryptoFramework.createAsyKeyGenerator('ECC256');
      const keyPair = await asymKeyGenerator.convertKey(keyBlob, null);
      
      const signer = cryptoFramework.createSign('ECC256|SHA256');
      await signer.init(keyPair.priKey);
      
      const signDataBlob: cryptoFramework.DataBlob = {
        data: new Uint8Array(Array.from(signContent).map(c => c.charCodeAt(0)))
      };
      
      const signResult = await signer.sign(signDataBlob);
      const signBase64 = util.encodeBase64Sync(signResult.data);
      
      return signBase64;
    } catch (error) {
      console.error(`SignUtil.getSign error: ${error}`);
      throw new Error('Signature generation failed');
    }
  }
  
  static genSignContent(
    adTechId: string,
    campaignId: string,
    destinationId: string,
    mmpIds: string[],
    serviceTag: string,
    nonce: string,
    timestamp: number
  ): string {
    const mmpIdsStr = mmpIds.length > 0 ? mmpIds.join(',') : '';
    
    const signContent = `${adTechId}|${campaignId}|${destinationId}|${mmpIdsStr}|${serviceTag}|${nonce}|${timestamp}`;
    
    return signContent;
  }
  
  static validateSignature(signature: string): boolean {
    if (!signature || signature.length === 0) {
      return false;
    }
    
    if (signature.length > 800) {
      console.warn('Signature length exceeds 800 characters');
      return false;
    }
    
    return true;
  }
  
  static validateNonce(nonce: string): boolean {
    if (!nonce || nonce.length !== 32) {
      console.warn('Nonce must be exactly 32 characters');
      return false;
    }
    
    if (nonce.includes('-')) {
      console.warn('Nonce should not contain hyphens');
      return false;
    }
    
    return true;
  }
  
  static validateTimestamp(timestamp: number): boolean {
    const currentTime = Date.now();
    const diffMinutes = Math.abs(currentTime - timestamp) / (1000 * 60);
    
    if (diffMinutes > 10) {
      console.warn(`Timestamp deviation exceeds 10 minutes: ${diffMinutes} minutes`);
      return false;
    }
    
    return true;
  }
}