import { ifaa } from '@kit.OnlineAuthenticationKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * IFAA免密身份认证 - 身份认证示例
 * 
 * 功能：使用已开通的生物特征进行IFAA免密身份认证
 * 
 * 前置条件：
 * 1. 用户已开通IFAA认证（指纹或3D人脸）
 * 2. 设备联网
 * 3. 设备支持生物特征且支持ATL4认证可信等级
 * 4. 应用已申请ohos.permission.ACCESS_BIOMETRIC权限
 */

export class IfaaAuthExample {
  
  /**
   * 查询IFAA认证开通状态
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns boolean 是否已开通
   */
  queryRegistrationStatus(userToken: Uint8Array): boolean {
    try {
      let isRegistered: boolean = ifaa.queryStatusSync(userToken);
      console.info(`[IFAA] Registration status: ${isRegistered ? 'Registered' : 'Not registered'}`);
      return isRegistered;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Failed to query status. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 使用指纹进行IFAA免密认证
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns Promise<Uint8Array | null> 认证结果
   */
  async authenticateWithFingerprint(userToken: Uint8Array): Promise<Uint8Array | null> {
    console.info('[IFAA] Starting fingerprint authentication...');
    
    if (!this.queryRegistrationStatus(userToken)) {
      console.error('[IFAA] User not registered, please register first');
      return null;
    }
    
    try {
      let anonymousId: Uint8Array = ifaa.getAnonymousIdSync(userToken);
      console.info('[IFAA] Obtained anonymous ID');
      
      let mockSignedAuthData = this.fetchSignedAuthDataFromServer(anonymousId);
      
      let ifaaChallenge: Uint8Array = ifaa.preAuthSync();
      console.info('[IFAA] Obtained pre-auth challenge');
      
      let authParam: userAuth.AuthParam = {
        challenge: ifaaChallenge,
        authType: [userAuth.UserAuthType.FINGERPRINT],
        authTrustLevel: userAuth.AuthTrustLevel.ATL4
      };
      
      let userAuthInstance = userAuth.getUserAuthInstance(authParam, {title: 'IFAA指纹认证'});
      
      return new Promise<Uint8Array | null>((resolve) => {
        userAuthInstance.on('result', {
          onResult(result) {
            if (result.result === 0) {
              let authToken = result.token;
              console.info('[IFAA] User biometric auth successful');
              
              try {
                let authData = mockSignedAuthData;
                let authResult: Uint8Array = ifaa.authSync(authToken, authData);
                console.info('[IFAA] IFAA authentication successful');
                resolve(authResult);
              } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`[IFAA] Failed IFAA auth. Code: ${err.code}, message: ${err.message}`);
                resolve(null);
              }
            } else {
              console.error('[IFAA] User biometric auth failed');
              resolve(null);
            }
          }
        });
        
        userAuthInstance.start();
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Authentication failed. Code: ${err.code}, message: ${err.message}`);
      this.handleAuthError(err);
      return null;
    }
  }
  
  /**
   * 使用人脸进行IFAA免密认证
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns Promise<Uint8Array | null> 认证结果
   */
  async authenticateWithFace(userToken: Uint8Array): Promise<Uint8Array | null> {
    console.info('[IFAA] Starting face authentication...');
    
    if (!this.queryRegistrationStatus(userToken)) {
      console.error('[IFAA] User not registered, please register first');
      return null;
    }
    
    try {
      let anonymousId: Uint8Array = ifaa.getAnonymousIdSync(userToken);
      console.info('[IFAA] Obtained anonymous ID');
      
      let mockSignedAuthData = this.fetchSignedAuthDataFromServer(anonymousId);
      
      let ifaaChallenge: Uint8Array = ifaa.preAuthSync();
      console.info('[IFAA] Obtained pre-auth challenge');
      
      let authParam: userAuth.AuthParam = {
        challenge: ifaaChallenge,
        authType: [userAuth.UserAuthType.FACE],
        authTrustLevel: userAuth.AuthTrustLevel.ATL4
      };
      
      let userAuthInstance = userAuth.getUserAuthInstance(authParam, {title: 'IFAA人脸认证'});
      
      return new Promise<Uint8Array | null>((resolve) => {
        userAuthInstance.on('result', {
          onResult(result) {
            if (result.result === 0) {
              let authToken = result.token;
              console.info('[IFAA] User biometric auth successful');
              
              try {
                let authData = mockSignedAuthData;
                let authResult: Uint8Array = ifaa.authSync(authToken, authData);
                console.info('[IFAA] IFAA authentication successful');
                resolve(authResult);
              } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`[IFAA] Failed IFAA auth. Code: ${err.code}, message: ${err.message}`);
                resolve(null);
              }
            } else {
              console.error('[IFAA] User biometric auth failed');
              resolve(null);
            }
          }
        });
        
        userAuthInstance.start();
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Authentication failed. Code: ${err.code}, message: ${err.message}`);
      this.handleAuthError(err);
      return null;
    }
  }
  
  /**
   * 从IIFAA服务器获取签名后的认证数据（模拟）
   * 
   * 注意：实际开发中，开发者需要实现与IIFAA服务器的交互逻辑
   * 
   * @param anonymousId 匿名化ID
   * @returns Uint8Array 签名后的认证数据
   */
  private fetchSignedAuthDataFromServer(anonymousId: Uint8Array): Uint8Array {
    console.warn('[IFAA] Mock: In real implementation, fetch signed auth data from IIFAA server');
    return new Uint8Array([0]);
  }
  
  /**
   * 错误处理
   * 
   * @param error BusinessError对象
   */
  private handleAuthError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('[IFAA] Parameter error: Invalid TLV data or authToken');
        console.info('[IFAA] Solution: Verify data format and ensure authToken is valid');
        break;
      case 801:
        console.error('[IFAA] Device type error');
        console.info('[IFAA] Solution: Confirm device type is supported');
        break;
      case 1006100001:
        console.error('[IFAA] System interruption');
        console.info('[IFAA] Solution: Restart device and retry');
        break;
      case 1006100002:
        console.error('[IFAA] Service abnormal');
        console.info('[IFAA] Solution: Retry or restart device');
        break;
      default:
        console.error(`[IFAA] Unknown error: ${error.message}`);
    }
  }
}

async function main(): void {
  let example = new IfaaAuthExample();
  
  let userToken = new Uint8Array([0]);
  
  let result = await example.authenticateWithFingerprint(userToken);
  
  if (result) {
    console.info('[IFAA] Authentication completed successfully');
    console.info(`[IFAA] Auth result: ${result.length} bytes`);
  } else {
    console.error('[IFAA] Authentication failed');
  }
}

main();