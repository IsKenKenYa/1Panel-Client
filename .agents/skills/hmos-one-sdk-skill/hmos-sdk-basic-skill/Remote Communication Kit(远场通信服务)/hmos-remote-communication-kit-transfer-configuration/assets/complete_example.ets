// 完整示例：TransferConfiguration定制数据传输
// 本示例演示完整的TransferConfiguration配置和使用流程

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 完整的TransferConfiguration配置示例
function createCompleteTransferConfig(): rcp.TransferConfiguration {
  // 定义超时配置
  const timeoutConfig: rcp.Timeout = {
    connectMs: 5000,   // 连接超时：5秒
    transferMs: 10000  // 传输超时：10秒
  };
  
  // 定义TCP配置（API 6.0.0及以上）
  const tcpConfig: rcp.TcpConfiguration = {
    keepIdleSec: 20,
    keepCnt: 6,
    keepIntervalSec: 30,
    userTimeoutMs: 3000
  };
  
  // 定义完整的TransferConfiguration
  const transferConfig: rcp.TransferConfiguration = {
    timeout: timeoutConfig,
    autoRedirect: true,           // 启用自动重定向
    maxAutoRedirects: 5,          // 最大重定向次数：5次
    assumesHTTP3Capable: false,   // 不启用HTTP/3功能
    pathPreference: 'auto',       // 自动选择网络路径
    tcp: tcpConfig                // TCP配置
  };
  
  return transferConfig;
}

// 创建会话并应用完整配置
function createSessionWithFullConfig(): rcp.Session {
  const transferConfig = createCompleteTransferConfig();
  
  const sessionConfig: rcp.SessionConfiguration = {
    requestConfiguration: {
      transfer: transferConfig
    },
    baseAddress: 'https://api.example.com',
    headers: {
      'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
      'Content-Type': 'application/json'
    }
  };
  
  const session = rcp.createSession(sessionConfig);
  
  console.info('已创建包含完整配置的会话');
  console.info('配置详情:');
  console.info(`- 连接超时: ${transferConfig.timeout?.connectMs}毫秒`);
  console.info(`- 传输超时: ${transferConfig.timeout?.transferMs}毫秒`);
  console.info(`- 自动重定向: ${transferConfig.autoRedirect}`);
  console.info(`- 最大重定向次数: ${transferConfig.maxAutoRedirects}`);
  
  return session;
}

// 定义带重试的请求函数
async function requestWithRetry(
  session: rcp.Session,
  url: string,
  maxRetry: number = 3
): Promise<rcp.Response> {
  let attempt = 0;
  
  while (attempt <= maxRetry) {
    try {
      attempt++;
      console.info(`正在发起第${attempt}次请求: ${url}`);
      
      const response = await session.get(url);
      
      console.info(`第${attempt}次请求成功，状态码: ${response.statusCode}`);
      return response;
      
    } catch (e) {
      const error = e as BusinessError;
      console.error(`第${attempt}次请求失败，错误码: ${error.code}`);
      
      // 可重试的错误码
      const retryableErrors = [
        1007900006,  // 域名解析失败
        1007900007,  // 无法连接服务器
        1007900028   // 操作超时
      ];
      
      if (retryableErrors.includes(error.code) && attempt <= maxRetry) {
        console.info(`将在200ms后重试...`);
        await new Promise(resolve => setTimeout(resolve, 200));
        continue;
      } else {
        console.error(`请求最终失败，不再重试`);
        throw error;
      }
    }
  }
  
  throw new Error('超出最大重试次数');
}

// 处理响应数据
function handleResponse(response: rcp.Response): void {
  console.info('开始处理响应数据...');
  console.info(`状态码: ${response.statusCode}`);
  console.info(`响应头: ${JSON.stringify(response.headers, null, 2)}`);
  
  // 检查状态码
  if (response.statusCode === 200) {
    console.info('请求成功，开始处理响应体');
    
    if (response.body) {
      console.info(`响应体长度: ${response.body.byteLength}字节`);
      // 可以进一步处理响应体数据
      // 例如：解析JSON、保存文件等
    }
  } else if (response.statusCode >= 400) {
    console.error(`服务器返回错误，状态码: ${response.statusCode}`);
  }
}

// 错误处理和降级
function handleRequestError(error: BusinessError): void {
  console.error('请求错误处理...');
  
  switch (error.code) {
    case 1007900006:  // 域名解析失败
      console.warn('降级方案：使用备用URL或检查网络连接');
      break;
      
    case 1007900007:  // 无法连接服务器
      console.warn('降级方案：检查服务器状态或使用备用服务器');
      break;
      
    case 1007900028:  // 操作超时
      console.warn('降级方案：增加超时时间或减少数据量');
      break;
      
    case 1007900035:  // SSL连接错误
      console.warn('降级方案：检查证书配置或TLS版本');
      break;
      
    default:
      console.warn('未知错误，记录错误日志并通知用户');
  }
}

// 完整的测试流程
async function testCompleteFlow(): Promise<void> {
  console.info('=== 开始完整TransferConfiguration测试流程 ===');
  
  let session: rcp.Session | null = null;
  
  try {
    // 1. 创建会话
    session = createSessionWithFullConfig();
    
    // 2. 发起请求（带重试机制）
    const response = await requestWithRetry(session, 'https://www.example.com', 3);
    
    // 3. 处理响应
    handleResponse(response);
    
    console.info('=== 测试流程成功完成 ===');
    
  } catch (error) {
    const err = error as BusinessError;
    console.error('=== 测试流程异常退出 ===');
    console.error(`错误码: ${err.code}`);
    console.error(`错误信息: ${err.data}`);
    
    // 错误处理和降级
    handleRequestError(err);
    
  } finally {
    // 4. 关闭会话释放资源（无论成功或失败都要执行）
    if (session) {
      session.close();
      console.info('会话已关闭，资源已释放');
    }
  }
}

// 执行完整测试
testCompleteFlow();