import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 配置 PEM 格式的客户端证书
 */
async function testPEMClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置 PEM 格式的客户端证书
  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.pem', // 替换为实际路径
        type: 'PEM',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key', // 私钥文件路径（可选）
        keyPassword: 'keyPassword' // 私钥密码（可选）
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 配置 DER 格式的客户端证书
 */
async function testDERClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置 DER 格式的客户端证书
  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.der', // 替换为实际路径
        type: 'DER',
        key: '/data/storage/el1/bundle/entry/resources/resfile/cert.key', // 私钥文件路径（可选）
        keyPassword: 'keyPassword' // 私钥密码（可选）
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 配置 P12 格式的客户端证书
 * P12 证书已包含私钥，不需要单独配置 key
 */
async function testP12ClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置 P12 格式的客户端证书
  request.configuration = {
    security: {
      certificate: {
        filePath: '/data/storage/el1/bundle/entry/resources/resfile/cert.p12', // 替换为实际路径
        type: 'P12',
        keyPassword: '1234' // P12 证书密码（必须）
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

/**
 * 使用字符串内容配置客户端证书
 */
async function testContentClientCertificate(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  const certContent = '-----BEGIN CERTIFICATE-----\n...' // 替换为实际的证书内容
  const keyContent = '-----BEGIN PRIVATE KEY-----\n...' // 替换为实际的私钥内容
  
  // 配置使用字符串内容的客户端证书
  request.configuration = {
    security: {
      certificate: {
        content: certContent,
        type: 'PEM',
        key: keyContent, // 私钥内容（可选）
        keyPassword: 'keyPassword' // 私钥密码（可选）
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
    console.info(`Response: ${JSON.stringify(response.toString())}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed: error code is ${error.code}, error data is ${error.data}`);
    throw error;
  } finally {
    session.close();
  }
}

// 主函数
async function main(): Promise<void> {
  try {
    console.info('=== Testing PEM client certificate ===');
    await testPEMClientCertificate();
    
    console.info('=== Testing DER client certificate ===');
    await testDERClientCertificate();
    
    console.info('=== Testing P12 client certificate ===');
    await testP12ClientCertificate();
    
    console.info('=== Testing content client certificate ===');
    await testContentClientCertificate();
  } catch (error) {
    console.error('Test failed:', error);
  }
}

main();