// 超时重试机制示例
// 本示例演示如何实现HTTP请求的超时重试逻辑

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义会话配置，包含超时设置
const sessionConfig: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: {
      timeout: {
        connectMs: 3000,  // 连接超时：3秒
        transferMs: 6000  // 传输超时：6秒
      }
    }
  }
};

// 创建会话
const session = rcp.createSession(sessionConfig);

// 定义异步重试函数
async function retryRequest(
  url: string,
  retryCount: number,
  attempt: number
): Promise<rcp.Response> {
  try {
    // 尝试发起HTTP GET请求
    console.info(`正在发起第${attempt}次请求...`);
    const response = await session.get(url);
    
    console.info(`第${attempt}次请求成功`);
    return Promise.resolve(response);
    
  } catch (e) {
    const error = e as BusinessError;
    console.error(`第${attempt}次请求失败，错误码: ${error.code}`);
    
    // 定义需要重试的错误码列表
    const retryErrorCodes = [
      1007900006,  // 域名解析失败
      1007900005,  // 代理域名解析失败
      1007900007,  // 无法连接到服务器
      1007900035   // SSL连接错误
    ];
    
    // 检查是否为可重试的错误
    if (retryErrorCodes.includes(error.code)) {
      // 检查是否达到最大重试次数
      if (attempt < retryCount) {
        console.info(`将在100ms后进行第${attempt + 1}次重试...`);
        
        // 等待100ms后重试（避免立即重试）
        await new Promise(resolve => setTimeout(resolve, 100));
        
        // 递归调用，增加尝试次数
        return retryRequest(url, retryCount, attempt + 1);
      } else {
        console.error(`已达到最大重试次数${retryCount}，请求最终失败`);
        return Promise.reject(error);
      }
    } else {
      // 其他错误直接返回，不进行重试
      console.error(`遇到不可重试的错误，直接返回错误`);
      return Promise.reject(error);
    }
  }
}

// 测试超时重试机制
async function testRetryMechanism(): Promise<void> {
  try {
    console.info('开始测试超时重试机制...');
    
    const URL = 'https://www.example.com';
    const retryCount = 3;  // 最大重试次数：3次
    const attempt = 1;     // 当前尝试次数：第1次
    
    // 发起带重试机制的请求
    const response = await retryRequest(URL, retryCount, attempt);
    
    console.info(`请求最终成功，状态码: ${response.statusCode}`);
    
    // 关闭会话释放资源
    session.close();
    console.info('会话已关闭，测试完成');
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`测试失败，错误码: ${err.code}`);
    console.error(`错误信息: ${err.data}`);
    
    // 异常时也要关闭会话
    session.close();
    console.info('会话已关闭（异常退出）');
  }
}

// 执行测试
testRetryMechanism();