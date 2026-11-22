/**
 * 降级方案示例
 * 演示如何在网络不稳定时使用不同策略的降级处理
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 超时配置级别
 * 从正常到极端情况，逐步增加超时时间
 */
const TIMEOUT_CONFIGS = [
  { name: '正常', config: { connectMs: 3000, transferMs: 6000 } },
  { name: '延长', config: { connectMs: 10000, transferMs: 15000 } },
  { name: '最大', config: { connectMs: 30000, transferMs: 60000 } }
];

/**
 * 超时降级策略
 * 当请求失败时，逐步尝试更长的超时时间
 */
async function requestWithTimeoutFallback(url: string): Promise<rcp.Response> {
  for (let i = 0; i < TIMEOUT_CONFIGS.length; i++) {
    const level = TIMEOUT_CONFIGS[i];
    
    console.info(`使用 ${level.name} 超时配置尝试请求...`);
    console.info(`connectMs: ${level.config.connectMs}, transferMs: ${level.config.transferMs}`);
    
    // 创建Session，使用当前级别的超时配置
    const session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: level.config
        }
      }
    });
    
    try {
      // 尝试发起请求
      const response = await session.get(url);
      console.info(`使用 ${level.name} 配置请求成功`);
      
      // 成功则关闭Session并返回
      session.close();
      return response;
      
    } catch (error) {
      const err = error as BusinessError;
      console.warn(`${level.name} 配置请求失败: 错误码 ${err.code}`);
      
      // 关闭当前Session
      session.close();
      
      // 如果是最后一次尝试，抛出错误
      if (i === TIMEOUT_CONFIGS.length - 1) {
        console.error('所有超时配置级别的尝试都失败');
        throw err;
      }
      
      // 否则继续尝试下一级别
      console.info('尝试下一级别的超时配置...');
    }
  }
  
  // 理论上不会执行到这里
  throw new Error('Unexpected error in fallback logic');
}

/**
 * 网络路径降级策略
 * 先尝试自动路径，失败后尝试蜂窝网络（需要权限）
 */
async function requestWithPathFallback(url: string): Promise<rcp.Response> {
  const pathConfigs = [
    { name: '自动路径', pathPreference: undefined },
    { name: '蜂窝网络', pathPreference: 'cellular' as rcp.PathPreference }
  ];
  
  for (const config of pathConfigs) {
    console.info(`使用 ${config.name} 尝试请求...`);
    
    const session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: { connectMs: 5000, transferMs: 10000 },
          pathPreference: config.pathPreference
        }
      }
    });
    
    try {
      const response = await session.get(url);
      console.info(`使用 ${config.name} 请求成功`);
      session.close();
      return response;
      
    } catch (error) {
      const err = error as BusinessError;
      console.warn(`${config.name} 请求失败: ${err.code}`);
      session.close();
      
      // 如果是最后一次尝试
      if (config === pathConfigs[pathConfigs.length - 1]) {
        throw err;
      }
    }
  }
  
  throw new Error('All path fallback attempts failed');
}

/**
 * HTTP协议版本降级策略
 * 先尝试HTTP/3，失败后降级到HTTP/2，最后HTTP/1.1
 */
async function requestWithProtocolFallback(url: string): Promise<rcp.Response> {
  const protocolConfigs = [
    { name: 'HTTP/3', assumesHTTP3Capable: true },
    { name: 'HTTP/2或HTTP/1.1', assumesHTTP3Capable: false }
  ];
  
  for (const config of protocolConfigs) {
    console.info(`尝试使用 ${config.name} 协议...`);
    
    const session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: { connectMs: 5000, transferMs: 10000 },
          assumesHTTP3Capable: config.assumesHTTP3Capable
        }
      }
    });
    
    try {
      const response = await session.get(url);
      console.info(`${config.name} 请求成功`);
      
      // 检查实际使用的HTTP版本
      if (response.httpVersion) {
        console.info(`实际使用HTTP版本: ${response.httpVersion}`);
      }
      
      session.close();
      return response;
      
    } catch (error) {
      const err = error as BusinessError;
      
      // HTTP/3特定错误
      if (err.code === 1007900095) {
        console.warn('HTTP/3错误，降级到HTTP/2或HTTP/1.1');
      } else {
        console.warn(`${config.name} 失败: ${err.code}`);
      }
      
      session.close();
      
      if (config === protocolConfigs[protocolConfigs.length - 1]) {
        throw err;
      }
    }
  }
  
  throw new Error('All protocol fallback attempts failed');
}

/**
 * 组合降级策略
 * 综合使用超时、重试和超时降级
 */
async function requestWithCombinedFallback(url: string): Promise<rcp.Response> {
  const RETRYABLE_ERRORS = [1007900006, 1007900007, 1007900028, 1007900035];
  
  // 对于每个超时级别，尝试重试
  for (let timeoutLevel = 0; timeoutLevel < TIMEOUT_CONFIGS.length; timeoutLevel++) {
    const level = TIMEOUT_CONFIGS[timeoutLevel];
    console.info(`超时级别 ${timeoutLevel + 1}: ${level.name}`);
    
    const session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: level.config
        }
      }
    });
    
    // 在当前超时级别下，最多重试3次
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        console.info(`超时级别 ${timeoutLevel + 1}, 第 ${attempt} 次尝试`);
        const response = await session.get(url);
        console.info('请求成功');
        session.close();
        return response;
        
      } catch (error) {
        const err = error as BusinessError;
        console.warn(`失败: 错误码 ${err.code}`);
        
        // 不可重试错误，直接抛出
        if (!RETRYABLE_ERRORS.includes(err.code)) {
          session.close();
          throw err;
        }
        
        // 如果当前超时级别的重试次数未达到，继续重试
        if (attempt < 3) {
          const waitTime = attempt * 1000;
          console.info(`等待 ${waitTime}ms 后重试...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
        }
      }
    }
    
    // 当前超时级别的所有重试都失败，关闭Session
    session.close();
    
    // 如果不是最后一个超时级别，继续尝试下一级别
    if (timeoutLevel < TIMEOUT_CONFIGS.length - 1) {
      console.info('当前超时级别所有尝试失败，尝试下一级别...');
    }
  }
  
  console.error('所有超时级别和重试尝试都失败');
  throw new Error('All combined fallback attempts failed');
}

/**
 * 完整的降级方案封装类
 */
class ResilientHttpClient {
  private url: string;
  
  constructor(url: string) {
    this.url = url;
  }
  
  /**
   * 执行请求（包含所有降级策略）
   */
  async request(): Promise<rcp.Response> {
    try {
      // 优先尝试组合降级策略
      return await requestWithCombinedFallback(this.url);
      
    } catch (error) {
      const err = error as BusinessError;
      
      // 如果组合策略失败，尝试其他降级方案
      console.warn('组合降级策略失败，尝试路径降级...');
      
      try {
        return await requestWithPathFallback(this.url);
      } catch (pathError) {
        console.warn('路径降级失败，尝试协议降级...');
        
        try {
          return await requestWithProtocolFallback(this.url);
        } catch (protocolError) {
          console.error('所有降级策略都失败');
          throw protocolError;
        }
      }
    }
  }
}

/**
 * 主函数入口
 */
@Entry
@Component
struct FallbackExample {
  build() {
    Column() {
      Button('超时降级示例')
        .onClick(async () => {
          try {
            const response = await requestWithTimeoutFallback('https://www.example.com');
            console.info('请求成功');
          } catch (error) {
            console.error('请求失败');
          }
        })
        .margin(10);
      
      Button('路径降级示例')
        .onClick(async () => {
          try {
            const response = await requestWithPathFallback('https://www.example.com');
            console.info('请求成功');
          } catch (error) {
            console.error('请求失败');
          }
        })
        .margin(10);
      
      Button('协议降级示例')
        .onClick(async () => {
          try {
            const response = await requestWithProtocolFallback('https://www.example.com');
            console.info('请求成功');
          } catch (error) {
            console.error('请求失败');
          }
        })
        .margin(10);
      
      Button('组合降级示例')
        .onClick(async () => {
          try {
            const response = await requestWithCombinedFallback('https://www.example.com');
            console.info('请求成功');
          } catch (error) {
            console.error('请求失败');
          }
        })
        .margin(10);
      
      Button('封装类示例')
        .onClick(async () => {
          const client = new ResilientHttpClient('https://www.example.com');
          try {
            const response = await client.request();
            console.info('请求成功');
          } catch (error) {
            console.error('请求失败');
          }
        })
        .margin(10);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}