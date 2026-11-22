/**
 * IFAA免密身份认证 - 状态查询示例
 * 
 * 本示例演示如何查询IFAA免密认证的开通状态
 */

import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 查询IFAA开通状态
 * 
 * @param userId 用户标识
 * @returns IFAAStatus 开通状态信息
 */
interface IFAAStatus {
  registered: boolean;
  userId: string;
  timestamp: Date;
  errorCode?: number;
  errorMessage?: string;
}

function queryIFAAStatus(userId: string): IFAAStatus {
  console.info('[IFAA Query] Querying registration status for user:', userId);
  
  const result: IFAAStatus = {
    registered: false,
    userId: userId,
    timestamp: new Date()
  };
  
  const userTokenTLV = constructUserTokenTLV(userId);
  
  try {
    const status: boolean = ifaa.queryStatusSync(userTokenTLV);
    
    result.registered = status;
    
    if (status) {
      console.info('[IFAA Query] User has registered IFAA');
    } else {
      console.info('[IFAA Query] User has not registered IFAA');
    }
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Query] Query failed. Code: ${err.code}, message: ${err.message}`);
    
    result.errorCode = err.code;
    result.errorMessage = err.message;
  }
  
  return result;
}

/**
 * 查询IFAA版本信息
 * 
 * @returns number IFAA接口版本号
 */
function queryIFAAVersion(): number {
  console.info('[IFAA Query] Querying IFAA version');
  
  try {
    const version: number = ifaa.getVersionSync();
    console.info(`[IFAA Query] IFAA version: ${version}`);
    return version;
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Query] Failed to get version. Code: ${err.code}, message: ${err.message}`);
    return -1;
  }
}

/**
 * 查询IFAA协议版本
 * 
 * @returns Uint8Array 协议版本号
 */
function queryIFAAProtocolVersion(): Uint8Array {
  console.info('[IFAA Query] Querying IFAA protocol version');
  
  try {
    const protocolVersion: Uint8Array = ifaa.getProtocolVersionSync();
    console.info('[IFAA Query] Protocol version obtained');
    console.debug(`[IFAA Query] Protocol version length: ${protocolVersion.length}`);
    return protocolVersion;
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Query] Failed to get protocol version. Code: ${err.code}, message: ${err.message}`);
    return new Uint8Array(0);
  }
}

/**
 * 查询IFAA支持的证书格式
 * 
 * @returns Uint8Array 支持的证书格式
 */
function querySupportedCertTypes(): Uint8Array {
  console.info('[IFAA Query] Querying supported certificate types');
  
  try {
    const certTypes: Uint8Array = ifaa.getSupportedCertTypesSync();
    console.info('[IFAA Query] Supported certificate types obtained');
    console.debug(`[IFAA Query] Certificate types length: ${certTypes.length}`);
    return certTypes;
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`[IFAA Query] Failed to get cert types. Code: ${err.code}, message: ${err.message}`);
    return new Uint8Array(0);
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
 * 执行完整状态查询
 */
function performFullStatusQuery(userId: string): void {
  console.info('[IFAA Query] Performing full status query');
  
  const status = queryIFAAStatus(userId);
  const version = queryIFAAVersion();
  const protocolVersion = queryIFAAProtocolVersion();
  const certTypes = querySupportedCertTypes();
  
  console.info('[IFAA Query] Full query results:');
  console.info(`  - Registered: ${status.registered}`);
  console.info(`  - Version: ${version}`);
  console.info(`  - Protocol Version: length=${protocolVersion.length}`);
  console.info(`  - Certificate Types: length=${certTypes.length}`);
}

/**
 * 主函数
 */
function main(): void {
  const userId = 'user_123456';
  
  console.info('=== IFAA Status Query Example ===');
  
  performFullStatusQuery(userId);
  
  console.info('=== Query Complete ===');
}

export {
  queryIFAAStatus,
  queryIFAAVersion,
  queryIFAAProtocolVersion,
  querySupportedCertTypes,
  performFullStatusQuery,
  IFAAStatus
};

main();