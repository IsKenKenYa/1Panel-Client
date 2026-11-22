import { rcp } from '@kit.RemoteCommunicationKit';
import { networkSecurity } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 辅助函数：生成 ASN.1 格式的日期字符串
 */
function makeItTwoChar(s: string): string {
  if (s.length === 1) {
    return '0' + s;
  }
  return s;
}

function getASNDateString(): string {
  const date = new Date();
  let dateStr = date.getFullYear().toString().slice(2);
  dateStr += makeItTwoChar((date.getMonth() + 1).toString());
  dateStr += makeItTwoChar(date.getDate().toString());
  dateStr += makeItTwoChar(date.getHours().toString());
  dateStr += makeItTwoChar(date.getMinutes().toString());
  dateStr += makeItTwoChar(date.getSeconds().toString());
  return dateStr + 'Z';
}

/**
 * 自定义证书校验函数
 * 实现高级自定义校验逻辑
 */
async function ValidationRemoteServer(context: rcp.ValidationContext): Promise<boolean> {
  // 检查服务器是否返回证书
  let length = context.pemCerts.length;
  if (length <= 0) {
    console.error('Server did not return certificate');
    return Promise.reject('Server did not return certificate');
  }
  
  // 获取根证书（通常是证书链的最后一个）
  const firstCaBlob: networkSecurity.CertBlob = {
    type: networkSecurity.CertType.CERT_TYPE_PEM,
    data: context.pemCerts[length - 1]
  };
  
  // 使用系统默认 CA 验证根证书
  // 如果 certVerificationSync 的第二个参数未填写，则使用系统默认的 CA
  if (networkSecurity.certVerificationSync(firstCaBlob) !== 0) {
    console.error('Certificate verification failed: root certificate not trusted');
    return Promise.reject('Certificate verification failed');
  }
  
  // 校验证书日期是否有效
  for (const x of context.x509Certs) {
    let dateStr = getASNDateString();
    try {
      x.checkValidityWithDate(dateStr);
      console.info('Certificate date check passed');
    } catch (e) {
      console.error('Certificate date check failed:', e);
      return Promise.reject('Certificate date check failed');
    }
  }
  
  // 校验成功
  console.info('Custom validation succeeded');
  return Promise.resolve(true);
}

/**
 * 基础自定义证书校验示例
 */
async function testBasicCustomValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置自定义证书校验回调
  request.configuration = {
    security: {
      remoteValidation: ValidationRemoteServer
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Response statusCode: ' + JSON.stringify(response.statusCode));
    console.info('Response: ' + JSON.stringify(response.toString()));
  } catch (err) {
    const error = err as BusinessError;
    console.error('Request failed: error code is ' + error.code + ', error data is ' + error.data);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 自定义校验逻辑 - 检查证书主题
 */
async function ValidationWithSubjectCheck(context: rcp.ValidationContext): Promise<boolean> {
  // 基础校验
  let length = context.pemCerts.length;
  if (length <= 0) {
    return Promise.reject('Server did not return certificate');
  }
  
  // 使用系统 CA 验证
  const firstCaBlob: networkSecurity.CertBlob = {
    type: networkSecurity.CertType.CERT_TYPE_PEM,
    data: context.pemCerts[length - 1]
  };
  
  if (networkSecurity.certVerificationSync(firstCaBlob) !== 0) {
    return Promise.reject('Certificate verification failed');
  }
  
  // 日期校验
  for (const x of context.x509Certs) {
    let dateStr = getASNDateString();
    try {
      x.checkValidityWithDate(dateStr);
    } catch (e) {
      return Promise.reject('Certificate date check failed');
    }
  }
  
  // 自定义：检查证书主题（示例）
  // 注意：需要根据实际需求实现主题检查逻辑
  // for (const x of context.x509Certs) {
  //   const subject = x.getSubject();
  //   if (subject !== 'expected_subject') {
  //     return Promise.reject('Certificate subject mismatch');
  //   }
  // }
  
  return Promise.resolve(true);
}

/**
 * 带主题检查的自定义校验示例
 */
async function testSubjectCheckValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');
  
  request.configuration = {
    security: {
      remoteValidation: ValidationWithSubjectCheck
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Response statusCode: ' + JSON.stringify(response.statusCode));
  } catch (err) {
    const error = err as BusinessError;
    console.error('Request failed: error code is ' + error.code + ', error data is ' + error.data);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 结合其他安全配置的自定义校验示例
 */
async function testCombinedSecurityConfiguration(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');
  
  // 配置完整的安全设置（包含自定义校验）
  request.configuration = {
    security: {
      // 自定义证书校验
      remoteValidation: ValidationRemoteServer,
      
      // 证书锁定
      certificatePinning: {
        kind: 'public-key',
        publicKeyHash: 'iMMpIJdSf5VlClHaxZReyhaLxLsmZMMNAiA2pMR8/M4=', // 替换为实际哈希值
        hashAlgorithm: 'SHA-256'
      },
      
      // 客户端证书
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.pem',
        type: 'PEM',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key'
      }
    },
    
    // 超时配置
    transfer: {
      timeout: {
        connectMs: 5000,
        transferMs: 10000
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Combined security configuration test succeeded: ' + response.statusCode);
    console.info('Response: ' + JSON.stringify(response.toString()));
  } catch (err) {
    const error = err as BusinessError;
    console.error('Request failed: error code is ' + error.code + ', error data is ' + error.data);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 错误处理和降级方案示例
 */
async function testCustomValidationWithFallback(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com');
  
  // 配置自定义校验
  request.configuration = {
    security: {
      remoteValidation: ValidationRemoteServer
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('Custom validation succeeded: ' + response.statusCode);
    return response;
  } catch (err) {
    const error = err as BusinessError;
    
    // 自定义校验失败，降级到系统默认校验
    console.warn('Custom validation failed, falling back to system validation');
    
    // 重新配置使用系统默认校验
    request.configuration = {
      security: {
        remoteValidation: 'system'
      }
    };
    
    try {
      const fallbackResponse = await session.fetch(request);
      console.info('Fallback to system validation succeeded: ' + fallbackResponse.statusCode);
      return fallbackResponse;
    } catch (fallbackErr) {
      console.error('Fallback validation also failed:', fallbackErr);
      throw fallbackErr;
    }
  } finally {
    session.close();
  }
}

// 主函数
async function main(): Promise<void> {
  try {
    console.info('=== Testing basic custom validation ===');
    await testBasicCustomValidation();
    
    console.info('=== Testing subject check validation ===');
    await testSubjectCheckValidation();
    
    console.info('=== Testing combined security configuration ===');
    await testCombinedSecurityConfiguration();
    
    console.info('=== Testing custom validation with fallback ===');
    await testCustomValidationWithFallback();
  } catch (error) {
    console.error('Test failed:', error);
  }
}

main();