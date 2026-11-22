// 基础超时配置示例
// 本示例演示如何配置HTTP请求的基本超时参数

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义超时配置参数
const timeoutConfig: rcp.Timeout = {
  connectMs: 3000,  // 连接超时：3秒
  transferMs: 6000  // 传输超时：6秒
};

// 定义TransferConfiguration配置对象
const transferConfig: rcp.TransferConfiguration = {
  timeout: timeoutConfig,
  autoRedirect: true,     // 启用自动重定向
  maxAutoRedirects: 5     // 最大重定向次数：5次
};

// 定义SessionConfiguration，包含TransferConfiguration
const sessionConfig: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: transferConfig
  }
};

// 创建会话
const session = rcp.createSession(sessionConfig);

// 测试基础超时配置
async function testBasicTimeoutConfig(): Promise<void> {
  try {
    console.info('开始测试基础超时配置...');
    
    // 发起HTTP GET请求
    const response = await session.get('https://www.example.com');
    
    console.info(`请求成功，状态码: ${response.statusCode}`);
    console.info(`响应头: ${JSON.stringify(response.headers)}`);
    
    // 关闭会话释放资源
    session.close();
    console.info('会话已关闭，测试完成');
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`请求失败，错误码: ${err.code}`);
    console.error(`错误信息: ${err.data}`);
    
    // 异常时也要关闭会话
    session.close();
    console.info('会话已关闭（异常退出）');
  }
}

// 执行测试
testBasicTimeoutConfig();