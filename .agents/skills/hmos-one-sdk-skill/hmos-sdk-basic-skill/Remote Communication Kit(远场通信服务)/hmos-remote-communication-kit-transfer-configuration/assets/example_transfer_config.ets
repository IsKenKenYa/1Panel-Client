/**
 * TransferConfiguration基本示例
 * 演示如何配置HTTP请求的超时参数
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 基本的超时配置示例
 */
async function basicTransferConfigExample(): Promise<void> {
  // 步骤1：定义会话配置，包含TransferConfiguration
  const sessionConfig: rcp.SessionConfiguration = {
    requestConfiguration: {
      transfer: {
        // 配置自动重定向
        autoRedirect: true,
        
        // 配置超时参数
        timeout: {
          connectMs: 3000,  // 连接超时：3秒
          transferMs: 6000  // 传输超时：6秒
        },
        
        // 配置HTTP/3支持（可选）
        assumesHTTP3Capable: false,
        
        // 配置网络路径偏好（可选）
        // pathPreference: 'cellular' // 使用蜂窝网络
      }
    }
  };
  
  // 步骤2：创建会话
  const session = rcp.createSession(sessionConfig);
  
  try {
    // 步骤3：发起HTTP请求
    const url = 'https://www.example.com';
    const response = await session.get(url);
    
    // 步骤4：处理响应
    console.info(`请求成功，状态码: ${response.statusCode}`);
    
    if (response.body) {
      const bodyLength = response.body.byteLength;
      console.info(`响应体大小: ${bodyLength} bytes`);
      
      // 将响应体转换为字符串（如果是文本数据）
      const decoder = new TextDecoder('utf-8');
      const bodyText = decoder.decode(response.body);
      console.info(`响应内容: ${bodyText.substring(0, 100)}...`);
    }
    
    // 检查响应头
    if (response.headers) {
      const contentType = response.headers['content-type'];
      console.info(`Content-Type: ${contentType}`);
    }
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`请求失败: 错误码 ${err.code}, 消息: ${err.message}`);
    
    // 根据错误码进行特定处理
    if (err.code === 1007900028) {
      console.error('操作超时，建议检查网络连接或增加超时时间');
    } else if (err.code === 1007900006) {
      console.error('域名解析失败，请检查URL或DNS配置');
    } else if (err.code === 1007900007) {
      console.error('无法连接到服务器，请检查网络连接');
    }
    
  } finally {
    // 步骤5：关闭Session，释放资源
    session.close();
    console.info('Session已关闭');
  }
}

/**
 * 配置TCP连接保活参数（从API版本6.0.0(20)开始）
 */
async function tcpConfigurationExample(): Promise<void> {
  const sessionConfig: rcp.SessionConfiguration = {
    requestConfiguration: {
      transfer: {
        timeout: {
          connectMs: 5000,
          transferMs: 10000,
          inactivityMs: 30000  // 不活动超时：30秒
        },
        
        // TCP连接保活配置
        tcp: {
          keepIdleSec: 20,       // 空闲20秒后开始探测
          keepIntervalSec: 30,   // 探测间隔30秒
          keepCnt: 6,            // 探测次数6次
          userTimeoutMs: 3000    // 用户超时3秒
        }
      }
    }
  };
  
  const session = rcp.createSession(sessionConfig);
  
  try {
    // 长连接请求示例
    const response = await session.get('https://www.example.com/api/long-polling');
    console.info('长连接请求成功');
    
  } finally {
    session.close();
  }
}

/**
 * 在Request级别配置TransferConfiguration（覆盖Session配置）
 */
async function requestLevelConfigExample(): Promise<void> {
  // Session级别的默认配置
  const session = rcp.createSession({
    requestConfiguration: {
      transfer: {
        timeout: {
          connectMs: 5000,
          transferMs: 10000
        }
      }
    }
  });
  
  try {
    // 创建Request对象，并配置特定请求的超时参数
    const request = new rcp.Request('https://www.example.com/api/urgent', 'GET');
    
    // Request级别的配置会覆盖Session级别的配置
    request.configuration = {
      transfer: {
        timeout: {
          connectMs: 1000,   // 更短的连接超时：1秒
          transferMs: 2000   // 更短的传输超时：2秒
        }
      }
    };
    
    // 使用fetch方法发送请求
    const response = await session.fetch(request);
    console.info(`紧急请求完成，状态码: ${response.statusCode}`);
    
  } finally {
    session.close();
  }
}

/**
 * 主函数入口
 */
@Entry
@Component
struct TransferConfigExample {
  build() {
    Column() {
      Button('基本超时配置示例')
        .onClick(() => {
          basicTransferConfigExample();
        })
        .margin(10);
      
      Button('TCP保活配置示例')
        .onClick(() => {
          tcpConfigurationExample();
        })
        .margin(10);
      
      Button('Request级别配置示例')
        .onClick(() => {
          requestLevelConfigExample();
        })
        .margin(10);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}