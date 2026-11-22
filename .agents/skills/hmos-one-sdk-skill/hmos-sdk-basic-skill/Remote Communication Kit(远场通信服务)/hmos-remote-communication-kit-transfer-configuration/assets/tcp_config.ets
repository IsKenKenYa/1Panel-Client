// TCP配置示例（需要API 6.0.0(20)及以上版本）
// 本示例演示如何配置TCP连接的保活参数和用户超时

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义TCP保活配置参数
const tcpConfig: rcp.TcpConfiguration = {
  keepIdleSec: 20,        // TCP保活空闲时间：20秒
                         // 取值范围：1-7200s，默认值：7200s
  keepCnt: 6,             // 保活探测次数：6次
                         // 取值范围：1-9次，默认值：9次
  keepIntervalSec: 30,    // 保活探测间隔：30秒
                         // 取值范围：1-75s，默认值：75s
  userTimeoutMs: 3000     // 用户超时：3秒
                         // 取值范围：1-3600000ms，默认值：与transferMs一致
};

// 定义TransferConfiguration，包含TCP配置
const transferConfig: rcp.TransferConfiguration = {
  timeout: {
    connectMs: 3000,
    transferMs: 6000
  },
  tcp: tcpConfig  // 将TCP配置添加到TransferConfiguration中
};

// 定义SessionConfiguration
const sessionConfig: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: transferConfig
  }
};

// 创建包含TCP配置的会话
const session = rcp.createSession(sessionConfig);

console.info('已创建包含TCP保活配置的会话');
console.info('TCP配置详情:');
console.info(`- 保活空闲时间: ${tcpConfig.keepIdleSec}秒`);
console.info(`- 保活探测次数: ${tcpConfig.keepCnt}次`);
console.info(`- 保活探测间隔: ${tcpConfig.keepIntervalSec}秒`);
console.info(`- 用户超时: ${tcpConfig.userTimeoutMs}毫秒`);

// 计算TCP保活总时间
const totalKeepAliveTime = tcpConfig.keepIdleSec + (tcpConfig.keepCnt + 1) * tcpConfig.keepIntervalSec;
console.info(`- TCP保活总时间: ${totalKeepAliveTime}秒（在服务器不回复探测报文的情况下）`);

// 测试TCP配置
async function testTcpConfig(): Promise<void> {
  try {
    console.info('开始测试TCP保活配置...');
    
    // 发起HTTP请求，TCP保活参数将生效
    const response = await session.get('https://www.example.com');
    
    console.info(`请求成功，状态码: ${response.statusCode}`);
    console.info('TCP保活配置已生效，连接参数已应用');
    
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
testTcpConfig();

// 注意事项：
// 1. TCP配置需要API 6.0.0(20)及以上版本
// 2. keepIdleSec、keepCnt、keepIntervalSec三个参数中至少需要设置一个，才会发送探测报文
// 3. 如果服务器一直不回复探测报文，TCP连接将在keepIdleSec + (keepCnt + 1) * keepIntervalSec秒后断开
// 4. 未设置的参数将使用文档中规定的默认值