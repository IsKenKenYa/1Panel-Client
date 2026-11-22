import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * IFAA免密身份认证 - 注销认证示例
 * 
 * 功能：注销已开通的生物特征IFAA免密身份认证能力
 * 
 * 前置条件：
 * 1. 用户已开通IFAA认证
 * 2. 设备联网
 * 3. 应用已申请ohos.permission.ACCESS_BIOMETRIC权限
 */

export class IfaaDeregisterExample {
  
  /**
   * 注销IFAA认证
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns boolean 注销是否成功
   */
  deregister(userToken: Uint8Array): boolean {
    console.info('[IFAA] Starting deregistration...');
    
    try {
      let anonymousId: Uint8Array = ifaa.getAnonymousIdSync(userToken);
      console.info('[IFAA] Successfully obtained anonymous ID');
      
      let mockSignedDeregisterData = this.fetchSignedDeregisterDataFromServer(anonymousId);
      
      let deregisterData = mockSignedDeregisterData;
      
      ifaa.deregisterSync(deregisterData);
      console.info('[IFAA] Successfully deregistered IFAA authentication');
      
      return this.verifyDeregistration(userToken);
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Failed to deregister. Code: ${err.code}, message: ${err.message}`);
      
      this.handleDeregisterError(err);
      return false;
    }
  }
  
  /**
   * 验证注销是否成功
   * 
   * @param userToken 用户标识（TLV格式的Uint8Array）
   * @returns boolean 是否已注销
   */
  private verifyDeregistration(userToken: Uint8Array): boolean {
    try {
      let isRegistered: boolean = ifaa.queryStatusSync(userToken);
      
      if (!isRegistered) {
        console.info('[IFAA] Verification: Successfully deregistered');
        return true;
      } else {
        console.warn('[IFAA] Verification: Still registered, deregistration may be delayed');
        return false;
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[IFAA] Failed to verify deregistration. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 从IIFAA服务器获取签名后的注销数据（模拟）
   * 
   * 注意：实际开发中，开发者需要实现与IIFAA服务器的交互逻辑
   * 
   * @param anonymousId 匿名化ID
   * @returns Uint8Array 签名后的注销数据
   */
  private fetchSignedDeregisterDataFromServer(anonymousId: Uint8Array): Uint8Array {
    console.warn('[IFAA] Mock: In real implementation, fetch signed deregister data from IIFAA server');
    return new Uint8Array([0]);
  }
  
  /**
   * 错误处理
   * 
   * @param error BusinessError对象
   */
  private handleDeregisterError(error: BusinessError): void {
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

function main(): void {
  let example = new IfaaDeregisterExample();
  
  let userToken = new Uint8Array([0]);
  
  let success = example.deregister(userToken);
  
  if (success) {
    console.info('[IFAA] Deregistration completed successfully');
  } else {
    console.error('[IFAA] Deregistration failed or verification failed');
  }
}

main();