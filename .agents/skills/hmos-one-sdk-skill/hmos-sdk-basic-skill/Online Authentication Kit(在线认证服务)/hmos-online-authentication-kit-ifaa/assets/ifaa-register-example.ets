import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { userAuth } from '@kit.UserAuthenticationKit';

/**
 * IFAA免密身份认证 - 开通认证示例
 * 
 * 功能：为用户开通指纹或3D人脸的IFAA免密身份认证能力
 * 
 * 前置条件：
 * 1. 设备联网
 * 2. 设备支持生物特征（指纹/3D人脸）且支持ATL4认证可信等级
 * 3. 应用已申请ohos.permission.ACCESS_BIOMETRIC权限
 * 4. 应用已接入IIFAA联盟
 */

export class IfaaRegisterExample {
  
  /**
   * 检查设备是否支持ATL4认证可信等级
   */
  checkDeviceSupport(): boolean {
    try {
      userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
      console.info('[IFAA] Device supports ATL4 face authentication');
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Device does not support ATL4. Code: ${err?.code}, message: ${err?.message}`);
      return false;
    }
  }
  
  /**
   * 获取IFAA版本信息
   */
  getIfaaVersionInfo(): void {
    try {
      let apiVersion: number = ifaa.getVersionSync();
      console.info(`[IFAA] API version: ${apiVersion}`);
      
      let protocolVersion: Uint8Array = ifaa.getProtocolVersionSync();
      console.info('[IFAA] Protocol version obtained');
      
      let certTypes: Uint8Array = ifaa.getSupportedCertTypesSync();
      console.info('[IFAA] Supported certificate types obtained');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Failed to get version info. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  /**
   * 开通IFAA指纹认证
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns Promise<Uint8Array> 开通结果
   */
  async registerFingerprint(userToken: Uint8Array): Promise<Uint8Array | null> {
    console.info('[IFAA] Starting fingerprint registration...');
    
    try {
      let anonymousId: Uint8Array = ifaa.getAnonymousIdSync(userToken);
      console.info('[IFAA] Successfully obtained anonymous ID');
      
      let mockSignedRegisterData = this.fetchSignedRegisterDataFromServer(anonymousId);
      
      let registerData = mockSignedRegisterData;
      
      let registerPromise: Promise<Uint8Array> = ifaa.register(registerData);
      let registerResult = await registerPromise;
      
      console.info('[IFAA] Successfully registered fingerprint authentication');
      return registerResult;
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Failed to register. Code: ${err.code}, message: ${err.message}`);
      
      this.handleRegisterError(err);
      return null;
    }
  }
  
  /**
   * 开通IFAA人脸认证
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns Promise<Uint8Array> 开通结果
   */
  async registerFace(userToken: Uint8Array): Promise<Uint8Array | null> {
    console.info('[IFAA] Starting face registration...');
    
    try {
      let anonymousId: Uint8Array = ifaa.getAnonymousIdSync(userToken);
      console.info('[IFAA] Successfully obtained anonymous ID');
      
      let mockSignedRegisterData = this.fetchSignedRegisterDataFromServer(anonymousId);
      
      let registerData = mockSignedRegisterData;
      
      let registerPromise: Promise<Uint8Array> = ifaa.register(registerData);
      let registerResult = await registerPromise;
      
      console.info('[IFAA] Successfully registered face authentication');
      return registerResult;
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Failed to register. Code: ${err.code}, message: ${err.message}`);
      
      this.handleRegisterError(err);
      return null;
    }
  }
  
  /**
   * 从IIFAA服务器获取签名后的开通数据（模拟）
   * 
   * 注意：实际开发中，开发者需要实现与IIFAA服务器的交互逻辑
   * 
   * @param anonymousId 匿名化ID
   * @returns Uint8Array 签名后的开通数据
   */
  private fetchSignedRegisterDataFromServer(anonymousId: Uint8Array): Uint8Array {
    console.warn('[IFAA] Mock: In real implementation, fetch signed data from IIFAA server');
    return new Uint8Array([0]);
  }
  
  /**
   * 错误处理
   * 
   * @param error BusinessError对象
   */
  private handleRegisterError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('[IFAA] Parameter error: Invalid TLV data format');
        console.info('[IFAA] Solution: Verify TLV data conforms to IIFAA protocol');
        break;
      case 801:
        console.error('[IFAA] Device type error: Unsupported device');
        console.info('[IFAA] Solution: Confirm device is Phone/PC/2in1/Tablet');
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
  let example = new IfaaRegisterExample();
  
  if (!example.checkDeviceSupport()) {
    console.error('[IFAA] Device check failed, cannot proceed');
    return;
  }
  
  example.getIfaaVersionInfo();
  
  let userToken = new Uint8Array([0]);
  let result = await example.registerFingerprint(userToken);
  
  if (result) {
    console.info('[IFAA] Registration completed successfully');
  } else {
    console.error('[IFAA] Registration failed');
  }
}

main();