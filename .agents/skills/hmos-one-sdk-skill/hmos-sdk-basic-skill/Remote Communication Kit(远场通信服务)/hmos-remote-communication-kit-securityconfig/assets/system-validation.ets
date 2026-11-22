import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 使用系统默认证书校验服务端证书
 * 推荐用于大多数场景
 */
async function testSystemValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置使用系统默认 CA 证书校验
  request.configuration = {
    security: {
      remoteValidation: 'system'
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
 * 跳过证书校验（仅用于开发测试）
 * ⚠️ 警告：不推荐在生产环境使用！
 */
async function testSkipValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://example.com'); // 请替换为实际的 HTTPS 网址
  
  // 配置跳过证书校验（仅用于测试环境）
  request.configuration = {
    security: {
      remoteValidation: 'skip' // ⚠️ 安全警告：仅用于测试
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response statusCode: ${JSON.stringify(response.statusCode)}`);
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
    console.info('=== Testing system validation ===');
    await testSystemValidation();
    
    // 仅在测试环境使用跳过校验
    // console.info('=== Testing skip validation (DEV ONLY) ===');
    // await testSkipValidation();
  } catch (error) {
    console.error('Test failed:', error);
  }
}

main();