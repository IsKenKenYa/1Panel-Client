/**
 * IFAA免密身份认证 - 认证示例
 * 
 * 本示例演示如何使用IFAA进行免密身份认证
 * 
 * 前置条件：
 * 1. 用户已开通IFAA免密认证（已调用register）
 * 2. 设备支持生物特征认证（指纹/3D人脸）
 * 3. 设备支持ATL4认证可信等级
 * 4. 设备处于联网状态
 * 5. 应用已申请ohos.permission.ACCESS_BIOMETRIC权限
 */

import { ifaa } from '@kit.OnlineAuthenticationKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 使用IFAA进行免密身份认证
 * 
 * @param userId 用户标识
 * @param authType 生物特征类型（FINGERPRINT/FACE）
 * @returns Promise<Uint8Array> 认证结果
 */
async function authenticateWithIFAA(
  userId: string,
  authType: userAuth.UserAuthType = userAuth.UserAuthType.FINGERPRINT
): Promise<Uint8Array> {
  console.info('[IFAA Auth] Starting authentication process');
  console.info(`[IFAA Auth] Auth type: ${authType === userAuth.UserAuthType.FINGERPRINT ? 'Fingerprint' : 'Face'}`);
  
  // 步骤1：构造用户标识TLV数据
  const userTokenTLV = constructUserTokenTLV(userId);
  
  // 步骤2：获取IFAA匿名化ID
  let anonymousId: Uint8Array;
  try {
    anonymousId = ifaa.getAnonymousIdSync(userTokenTLV);
    console.info('[IFAA Auth] Successfully obtained anonymous ID');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Auth] Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
  
  // 步骤3：从服务端获取认证数据
  const authDataTLV = await fetchAuthDataFromServer(anonymousId);
  
  // 步骤4：获取IFAA预认证challenge
  let ifaaChallenge: Uint8Array;
  try {
    ifaaChallenge = ifaa.preAuthSync();
    console.info('[IFAA Auth] Successfully obtained IFAA challenge');
    console.debug(`[IFAA Auth] Challenge length: ${ifaaChallenge.length}`);
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Auth] Failed to get IFAA challenge. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
  
  // 步骤5：构造用户认证参数
  const authParam: userAuth.AuthParam = {
    challenge: ifaaChallenge,
    authType: [authType],
    authTrustLevel: userAuth.AuthTrustLevel.ATL4
  };
  
  // 步骤6：调用用户认证模块进行生物特征认证
  return new Promise<Uint8Array>((resolve, reject) => {
    try {
      const userAuthInstance = userAuth.getUserAuthInstance(authParam, {
        title: 'IFAA免密认证',
        subtitle: '请使用已开通的生物特征进行认证'
      });
      
      // 监听认证结果
      userAuthInstance.on('result', {
        onResult(result) {
          console.info('[IFAA Auth] User authentication result received');
          console.info(`[IFAA Auth] Result code: ${result.result}`);
          
          if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
            // 生物特征认证成功
            const authToken = result.token;
            console.info('[IFAA Auth] Biometric authentication succeeded');
            
            // 步骤7：调用IFAA认证接口
            try {
              const authResult = ifaa.authSync(authToken, authDataTLV);
              console.info('[IFAA Auth] IFAA authentication succeeded');
              console.debug(`[IFAA Auth] Auth result length: ${authResult.length}`);
              
              // 处理认证结果
              handleAuthResult(authResult);
              
              resolve(authResult);
              
            } catch (error) {
              const err: BusinessError = error as BusinessError;
              console.error(`[IFAA Auth] IFAA auth failed. Code: ${err.code}, message: ${err.message}`);
              reject(err);
            }
            
          } else {
            // 生物特征认证失败
            console.error(`[IFAA Auth] Biometric authentication failed. Result: ${result.result}`);
            
            const authError = new Error(`Biometric auth failed with code ${result.result}`);
            reject(authError);
          }
        }
      });
      
      // 监听认证取消
      userAuthInstance.on('cancel', {
        onCancel() {
          console.warn('[IFAA Auth] User cancelled authentication');
          reject(new Error('User cancelled authentication'));
        }
      });
      
      // 启动认证
      userAuthInstance.start();
      console.info('[IFAA Auth] User authentication started');
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[IFAA Auth] Failed to start user auth. Code: ${err.code}, message: ${err.message}`);
      reject(err);
    }
  });
}

/**
 * 构造用户标识TLV数据（示例函数）
 */
function constructUserTokenTLV(userId: string): Uint8Array {
  const encoder = new TextEncoder();
  const userIdBytes = encoder.encode(userId);
  
  const tlvData = new Uint8Array(2 + userIdBytes.length);
  tlvData[0] = 0x01;
  tlvData[1] = userIdBytes.length;
  tlvData.set(userIdBytes, 2);
  
  return tlvData;
}

/**
 * 从服务端获取认证数据（示例函数）
 */
async function fetchAuthDataFromServer(anonymousId: Uint8Array): Promise<Uint8Array> {
  console.info('[IFAA Auth] Fetching auth data from server');
  
  await new Promise(resolve => setTimeout(resolve, 100));
  
  const mockAuthData = new Uint8Array([0x03, 0x01, 0x00]);
  
  console.debug(`[IFAA Auth] Received auth data, length: ${mockAuthData.length}`);
  return mockAuthData;
}

/**
 * 处理认证结果（示例函数）
 */
function handleAuthResult(authResult: Uint8Array): void {
  console.info('[IFAA Auth] Handling auth result');
  
  // 实际开发需：
  // 1. 将authResult发送给服务端验证
  // 2. 服务端返回认证成功/失败
  // 3. 应用执行后续业务逻辑（如免密登录、免密支付）
  
  console.info('[IFAA Auth] Authentication completed successfully');
}

/**
 * 使用指纹进行IFAA认证
 */
async function authenticateWithFingerprint(userId: string): Promise<Uint8Array> {
  return await authenticateWithIFAA(userId, userAuth.UserAuthType.FINGERPRINT);
}

/**
 * 使用人脸进行IFAA认证
 */
async function authenticateWithFace(userId: string): Promise<Uint8Array> {
  return await authenticateWithIFAA(userId, userAuth.UserAuthType.FACE);
}

/**
 * 主函数：执行认证流程
 */
async function main(): Promise<void> {
  const userId = 'user_123456';
  
  try {
    // 使用指纹认证
    const authResult = await authenticateWithFingerprint(userId);
    console.info('[IFAA Auth] Authentication succeeded');
    console.debug(`[IFAA Auth] Result: ${authResult}`);
    
  } catch (error) {
    console.error('[IFAA Auth] Authentication failed:', error);
    
    // 降级处理：引导用户使用其他认证方式
    console.warn('[IFAA Auth] Fallback: Please use password authentication');
  }
}

export {
  authenticateWithIFAA,
  authenticateWithFingerprint,
  authenticateWithFace,
  constructUserTokenTLV,
  fetchAuthDataFromServer,
  handleAuthResult
};

main();