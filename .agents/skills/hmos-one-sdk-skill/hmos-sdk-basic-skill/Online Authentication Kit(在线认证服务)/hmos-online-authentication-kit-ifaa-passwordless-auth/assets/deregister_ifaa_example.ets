/**
 * IFAA免密身份认证 - 注销示例
 * 
 * 本示例演示如何注销用户的IFAA免密身份认证能力
 * 
 * 前置条件：
 * 1. 用户已开通IFAA免密认证
 * 2. 设备处于联网状态
 * 3. 应用已接入IIFAA联盟
 */

import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 注销IFAA免密身份认证
 * 
 * @param userId 用户标识
 * @returns Promise<void> 注销结果
 */
async function deregisterIFAA(userId: string): Promise<void> {
  console.info('[IFAA Deregister] Starting deregistration process');
  
  // 步骤1：查询开通状态
  const isRegistered = queryIFAAStatus(userId);
  
  if (!isRegistered) {
    console.warn('[IFAA Deregister] User has not registered IFAA');
    return;
  }
  
  // 步骤2：构造用户标识TLV数据
  const userTokenTLV = constructUserTokenTLV(userId);
  
  // 步骤3：获取IFAA匿名化ID
  let anonymousId: Uint8Array;
  try {
    anonymousId = ifaa.getAnonymousIdSync(userTokenTLV);
    console.info('[IFAA Deregister] Successfully obtained anonymous ID');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Deregister] Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
  
  // 步骤4：从服务端获取签名后的注销数据
  const deregisterDataTLV = await fetchDeregisterDataFromServer(anonymousId);
  
  // 步骤5：调用deregisterSync接口注销IFAA
  try {
    ifaa.deregisterSync(deregisterDataTLV);
    console.info('[IFAA Deregister] Deregistration succeeded');
    
    // 步骤6：通知服务端注销完成
    await notifyDeregisterCompleteToServer();
    
    console.info('[IFAA Deregister] Deregistration process completed');
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Deregister] Deregistration failed. Code: ${err.code}, message: ${err.message}`);
    
    // 错误处理
    if (err.code === 401) {
      console.error('[IFAA Deregister] Parameter error: Invalid TLV data format');
    } else if (err.code === 801) {
      console.error('[IFAA Deregister] Device type error: Device does not support IFAA');
    } else if (err.code === 1006100001) {
      console.error('[IFAA Deregister] System interruption: System exception occurred');
    } else if (err.code === 1006100002) {
      console.error('[IFAA Deregister] Service abnormal: IFAA service is abnormal');
    }
    
    throw error;
  }
}

/**
 * 查询IFAA开通状态
 * 
 * @param userId 用户标识
 * @returns boolean true=已开通, false=未开通
 */
function queryIFAAStatus(userId: string): boolean {
  console.info('[IFAA Deregister] Querying registration status');
  
  const userTokenTLV = constructUserTokenTLV(userId);
  
  try {
    const status: boolean = ifaa.queryStatusSync(userTokenTLV);
    
    if (status) {
      console.info('[IFAA Deregister] IFAA is registered');
    } else {
      console.info('[IFAA Deregister] IFAA is deregistered');
    }
    
    return status;
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Deregister] Failed to query status. Code: ${err.code}, message: ${err.message}`);
    return false;
  }
}

/**
 * 构造用户标识TLV数据
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
 * 从服务端获取签名后的注销数据
 */
async function fetchDeregisterDataFromServer(anonymousId: Uint8Array): Promise<Uint8Array> {
  console.info('[IFAA Deregister] Fetching deregister data from server');
  
  await new Promise(resolve => setTimeout(resolve, 100));
  
  const mockDeregisterData = new Uint8Array([0x04, 0x01, 0x00]);
  
  console.debug(`[IFAA Deregister] Received deregister data, length: ${mockDeregisterData.length}`);
  return mockDeregisterData;
}

/**
 * 通知服务端注销完成
 */
async function notifyDeregisterCompleteToServer(): Promise<void> {
  console.info('[IFAA Deregister] Notifying server about deregistration');
  
  await new Promise(resolve => setTimeout(resolve, 100));
  
  console.info('[IFAA Deregister] Server notification completed');
}

/**
 * 主函数
 */
async function main(): Promise<void> {
  const userId = 'user_123456';
  
  try {
    await deregisterIFAA(userId);
    console.info('[IFAA Deregister] Process completed');
  } catch (error) {
    console.error('[IFAA Deregister] Process failed:', error);
  }
}

export {
  deregisterIFAA,
  queryIFAAStatus,
  constructUserTokenTLV,
  fetchDeregisterDataFromServer,
  notifyDeregisterCompleteToServer
};

main();