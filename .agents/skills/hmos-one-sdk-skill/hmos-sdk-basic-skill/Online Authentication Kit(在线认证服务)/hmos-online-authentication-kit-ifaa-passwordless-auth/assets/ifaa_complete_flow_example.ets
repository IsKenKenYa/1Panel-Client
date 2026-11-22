/**
 * IFAA免密身份认证 - 完整流程示例
 * 
 * 本示例演示IFAA免密身份认证的完整生命周期：
 * 1. 查询设备能力
 * 2. 查询开通状态
 * 3. 开通IFAA（如果未开通）
 * 4. 认证IFAA
 * 5. 注销IFAA
 */

import { ifaa } from '@kit.OnlineAuthenticationKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * IFAA完整流程管理器
 */
class IFAAFlowManager {
  private userId: string;
  
  constructor(userId: string) {
    this.userId = userId;
    console.info('[IFAA Flow] Flow manager initialized for user:', userId);
  }
  
  /**
   * 执行完整IFAA流程
   */
  async executeFullFlow(): Promise<void> {
    console.info('[IFAA Flow] === Starting Full IFAA Flow ===');
    
    try {
      // 步骤1：检查设备能力
      console.info('\n[Step 1] Checking device capability...');
      const deviceReady = await this.checkDeviceCapability();
      if (!deviceReady) {
        console.error('[IFAA Flow] Device not ready, flow aborted');
        return;
      }
      
      // 步骤2：查询开通状态
      console.info('\n[Step 2] Querying registration status...');
      const isRegistered = this.queryStatus();
      
      if (!isRegistered) {
        // 步骤3：开通IFAA
        console.info('\n[Step 3] Registering IFAA...');
        await this.register();
        console.info('[IFAA Flow] Registration completed');
      } else {
        console.info('[IFAA Flow] User already registered, skip registration');
      }
      
      // 步骤4：认证IFAA
      console.info('\n[Step 4] Authenticating with IFAA...');
      const authResult = await this.authenticate();
      console.info('[IFAA Flow] Authentication succeeded');
      console.debug('[IFAA Flow] Auth result:', authResult);
      
      // 步骤5：注销IFAA
      console.info('\n[Step 5] Deregistering IFAA...');
      await this.deregister();
      console.info('[IFAA Flow] Deregistration completed');
      
      console.info('\n[IFAA Flow] === Full Flow Completed Successfully ===');
      
    } catch (error) {
      console.error('[IFAA Flow] Flow failed:', error);
      
      // 降级处理
      this.handleFallback(error);
    }
  }
  
  /**
   * 检查设备能力
   */
  private async checkDeviceCapability(): Promise<boolean> {
    console.info('[IFAA Flow] Checking device capability');
    
    try {
      // 检查指纹支持
      userAuth.getAvailableStatus(userAuth.UserAuthType.FINGERPRINT, userAuth.AuthTrustLevel.ATL4);
      console.info('[IFAA Flow] Device supports fingerprint ATL4');
      
      // 检查人脸支持
      userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
      console.info('[IFAA Flow] Device supports face ATL4');
      
      // 检查IFAA版本
      const version = ifaa.getVersionSync();
      console.info(`[IFAA Flow] IFAA version: ${version}`);
      
      return true;
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[IFAA Flow] Device capability check failed. Code: ${err?.code}`);
      return false;
    }
  }
  
  /**
   * 查询开通状态
   */
  private queryStatus(): boolean {
    console.info('[IFAA Flow] Querying IFAA status');
    
    const userToken = this.constructUserToken();
    
    try {
      const status = ifaa.queryStatusSync(userToken);
      
      if (status) {
        console.info('[IFAA Flow] User is registered');
      } else {
        console.info('[IFAA Flow] User is not registered');
      }
      
      return status;
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[IFAA Flow] Query failed. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 开通IFAA
   */
  private async register(): Promise<void> {
    console.info('[IFAA Flow] Registering IFAA');
    
    const userToken = this.constructUserToken();
    
    // 获取匿名化ID
    const anonymousId = ifaa.getAnonymousIdSync(userToken);
    console.info('[IFAA Flow] Obtained anonymous ID');
    
    // 从服务端获取开通数据
    const registerData = await this.fetchRegisterData(anonymousId);
    
    // 调用register接口
    try {
      const registerResult = await ifaa.register(registerData);
      console.info('[IFAA Flow] Registration succeeded');
      
      // 处理结果
      await this.handleRegisterResult(registerResult);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[IFAA Flow] Registration failed. Code: ${err.code}`);
      throw error;
    }
  }
  
  /**
   * 认证IFAA
   */
  private async authenticate(): Promise<Uint8Array> {
    console.info('[IFAA Flow] Authenticating with IFAA');
    
    const userToken = this.constructUserToken();
    
    // 获取匿名化ID
    const anonymousId = ifaa.getAnonymousIdSync(userToken);
    console.info('[IFAA Flow] Obtained anonymous ID');
    
    // 从服务端获取认证数据
    const authData = await this.fetchAuthData(anonymousId);
    
    // 获取预认证challenge
    const challenge = ifaa.preAuthSync();
    console.info('[IFAA Flow] Obtained challenge');
    
    // 构造认证参数
    const authParam: userAuth.AuthParam = {
      challenge: challenge,
      authType: [userAuth.UserAuthType.FINGERPRINT],
      authTrustLevel: userAuth.AuthTrustLevel.ATL4
    };
    
    // 执行生物特征认证和IFAA认证
    return new Promise<Uint8Array>((resolve, reject) => {
      const userAuthInstance = userAuth.getUserAuthInstance(authParam, {
        title: 'IFAA免密认证'
      });
      
      userAuthInstance.on('result', {
        onResult(result) {
          if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
            console.info('[IFAA Flow] Biometric auth succeeded');
            
            try {
              const authResult = ifaa.authSync(result.token, authData);
              console.info('[IFAA Flow] IFAA auth succeeded');
              resolve(authResult);
              
            } catch (error) {
              const err = error as BusinessError;
              console.error(`[IFAA Flow] IFAA auth failed. Code: ${err.code}`);
              reject(err);
            }
          } else {
            console.error('[IFAA Flow] Biometric auth failed');
            reject(new Error('Biometric auth failed'));
          }
        }
      });
      
      userAuthInstance.start();
    });
  }
  
  /**
   * 注销IFAA
   */
  private async deregister(): Promise<void> {
    console.info('[IFAA Flow] Deregistering IFAA');
    
    const userToken = this.constructUserToken();
    
    // 获取匿名化ID
    const anonymousId = ifaa.getAnonymousIdSync(userToken);
    console.info('[IFAA Flow] Obtained anonymous ID');
    
    // 从服务端获取注销数据
    const deregisterData = await this.fetchDeregisterData(anonymousId);
    
    // 调用deregister接口
    try {
      ifaa.deregisterSync(deregisterData);
      console.info('[IFAA Flow] Deregistration succeeded');
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[IFAA Flow] Deregistration failed. Code: ${err.code}`);
      throw error;
    }
  }
  
  /**
   * 构造用户标识TLV
   */
  private constructUserToken(): Uint8Array {
    const encoder = new TextEncoder();
    const userIdBytes = encoder.encode(this.userId);
    
    const tlvData = new Uint8Array(2 + userIdBytes.length);
    tlvData[0] = 0x01;
    tlvData[1] = userIdBytes.length;
    tlvData.set(userIdBytes, 2);
    
    return tlvData;
  }
  
  /**
   * 从服务端获取开通数据（模拟）
   */
  private async fetchRegisterData(anonymousId: Uint8Array): Promise<Uint8Array> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return new Uint8Array([0x02, 0x01, 0x00]);
  }
  
  /**
   * 从服务端获取认证数据（模拟）
   */
  private async fetchAuthData(anonymousId: Uint8Array): Promise<Uint8Array> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return new Uint8Array([0x03, 0x01, 0x00]);
  }
  
  /**
   * 从服务端获取注销数据（模拟）
   */
  private async fetchDeregisterData(anonymousId: Uint8Array): Promise<Uint8Array> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return new Uint8Array([0x04, 0x01, 0x00]);
  }
  
  /**
   * 处理开通结果（模拟）
   */
  private async handleRegisterResult(registerResult: Uint8Array): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 50));
    console.info('[IFAA Flow] Register result handled');
  }
  
  /**
   * 降级处理
   */
  private handleFallback(error: any): void {
    console.warn('[IFAA Flow] Fallback activated');
    console.warn('[IFAA Flow] Error:', error);
    console.warn('[IFAA Flow] Please use alternative authentication method');
  }
}

/**
 * 主函数
 */
async function main(): Promise<void> {
  const userId = 'user_123456';
  
  const flowManager = new IFAAFlowManager(userId);
  await flowManager.executeFullFlow();
}

export { IFAAFlowManager };

main();