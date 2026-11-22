import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * IFAA免密身份认证 - 状态查询示例
 * 
 * 功能：查询IFAA免密认证的开通状态和获取相关信息
 */

export class IfaaQueryExample {
  
  /**
   * 查询IFAA认证开通状态（同步）
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns boolean 是否已开通
   */
  queryRegistrationStatusSync(userToken: Uint8Array): boolean {
    try {
      let isRegistered: boolean = ifaa.queryStatusSync(userToken);
      console.info(`[IFAA Query] Registration status (sync): ${isRegistered ? 'Registered' : 'Not registered'}`);
      return isRegistered;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA Query] Failed to query status (sync). Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 查询IFAA认证开通状态（异步Promise）
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns Promise<boolean> 是否已开通
   */
  async queryRegistrationStatusPromise(userToken: Uint8Array): Promise<boolean> {
    try {
      let isRegistered: boolean = await ifaa.queryStatus(userToken);
      console.info(`[IFAA Query] Registration status (promise): ${isRegistered ? 'Registered' : 'Not registered'}`);
      return isRegistered;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA Query] Failed to query status (promise). Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 查询IFAA认证开通状态（异步Callback）
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @param callback 回调函数
   */
  queryRegistrationStatusCallback(userToken: Uint8Array, callback: (err: BusinessError | null, isRegistered: boolean) => void): void {
    ifaa.queryStatus(userToken, (err: BusinessError, isRegistered: boolean) => {
      if (err) {
        console.error(`[IFAA Query] Failed to query status (callback). Code: ${err.code}, message: ${err.message}`);
        callback(err, false);
      } else {
        console.info(`[IFAA Query] Registration status (callback): ${isRegistered ? 'Registered' : 'Not registered'}`);
        callback(null, isRegistered);
      }
    });
  }
  
  /**
   * 获取IFAA接口版本号
   * 
   * @returns number 接口版本号
   */
  getApiVersion(): number {
    try {
      let version: number = ifaa.getVersionSync();
      console.info(`[IFAA Query] API version: ${version}`);
      return version;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA Query] Failed to get API version. Code: ${err.code}, message: ${err.message}`);
      return -1;
    }
  }
  
  /**
   * 获取IFAA协议版本号
   * 
   * @returns Uint8Array 协议版本号
   */
  getProtocolVersion(): Uint8Array | null {
    try {
      let version: Uint8Array = ifaa.getProtocolVersionSync();
      console.info('[IFAA Query] Protocol version obtained');
      return version;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA Query] Failed to get protocol version. Code: ${err.code}, message: ${err.message}`);
      return null;
    }
  }
  
  /**
   * 获取支持的证书格式
   * 
   * @returns Uint8Array 支持的证书格式
   */
  getSupportedCertTypes(): Uint8Array | null {
    try {
      let certTypes: Uint8Array = ifaa.getSupportedCertTypesSync();
      console.info('[IFAA Query] Supported certificate types obtained');
      return certTypes;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA Query] Failed to get cert types. Code: ${err.code}, message: ${err.message}`);
      return null;
    }
  }
  
  /**
   * 获取匿名化ID（同步）
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns Uint8Array | null 匿名化ID
   */
  getAnonymousIdSync(userToken: Uint8Array): Uint8Array | null {
    try {
      let anonymousId: Uint8Array = ifaa.getAnonymousIdSync(userToken);
      console.info('[IFAA Query] Successfully obtained anonymous ID (sync)');
      return anonymousId;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA Query] Failed to get anonymous ID (sync). Code: ${err.code}, message: ${err.message}`);
      return null;
    }
  }
  
  /**
   * 获取预认证参数（同步）
   * 
   * @returns Uint8Array | null 预认证参数（包含challenge）
   */
  getPreAuthParams(): Uint8Array | null {
    try {
      let preAuthResult: Uint8Array = ifaa.preAuthSync();
      console.info('[IFAA Query] Successfully obtained pre-auth params');
      return preAuthResult;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA Query] Failed to get pre-auth params. Code: ${err.code}, message: ${err.message}`);
      return null;
    }
  }
  
  /**
   * 综合信息查询
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   */
  queryAllInfo(userToken: Uint8Array): void {
    console.info('[IFAA Query] Starting comprehensive query...');
    
    let apiVersion = this.getApiVersion();
    let protocolVersion = this.getProtocolVersion();
    let certTypes = this.getSupportedCertTypes();
    let isRegistered = this.queryRegistrationStatusSync(userToken);
    let anonymousId = this.getAnonymousIdSync(userToken);
    
    console.info('[IFAA Query] === Query Results ===');
    console.info(`[IFAA Query] API Version: ${apiVersion}`);
    console.info(`[IFAA Query] Protocol Version: ${protocolVersion ? 'Obtained' : 'Failed'}`);
    console.info(`[IFAA Query] Certificate Types: ${certTypes ? 'Obtained' : 'Failed'}`);
    console.info(`[IFAA Query] Registration Status: ${isRegistered ? 'Registered' : 'Not registered'}`);
    console.info(`[IFAA Query] Anonymous ID: ${anonymousId ? 'Obtained' : 'Failed'}`);
    console.info('[IFAA Query] === Query Complete ===');
  }
}

function main(): void {
  let example = new IfaaQueryExample();
  
  let userToken = new Uint8Array([0]);
  
  example.queryAllInfo(userToken);
  
  example.queryRegistrationStatusCallback(userToken, (err, isRegistered) => {
    if (!err) {
      console.info(`[IFAA Query] Callback result: ${isRegistered ? 'Registered' : 'Not registered'}`);
    }
  });
}

main();