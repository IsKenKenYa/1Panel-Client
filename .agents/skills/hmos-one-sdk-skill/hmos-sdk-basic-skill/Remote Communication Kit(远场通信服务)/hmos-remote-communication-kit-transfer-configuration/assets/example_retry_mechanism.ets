/**
 * 超时重试机制示例
 * 演示如何实现HTTP请求的超时自动重试
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 可重试的错误码列表
 * 这些错误可能是临时性问题，可以通过重试解决
 */
const RETRYABLE_ERRORS = [
  1007900006,  // 域名解析失败
  1007900005,  // 代理服务器域名解析失败
  1007900007,  // 无法连接到服务器
  1007900028,  // 操作超时
  1007900035   // SSL连接错误
];

/**
 * 递归重试函数
 * @param url 请求URL
 * @param session RCP会话对象
 * @param retryCount 最大重试次数
 * @param attempt 当前尝试次数（从1开始）
 * @returns Promise<rcp.Response>
 */
async function retryRequest(
  url: string,
  session: rcp.Session,
  retryCount: number,
  attempt: number
): Promise<rcp.Response> {
  try {
    // 发起GET请求
    const response = await session.get(url);
    
    // 请求成功，返回响应
    console.info(`请求成功（尝试 ${attempt}）: 状态码 ${response.statusCode}`);
    return Promise.resolve(response);
    
  } catch (error) {
    const err = error as BusinessError;
    
    // 判断是否为可重试错误
    if (RETRYABLE_ERRORS.includes(err.code)) {
      // 检查是否达到最大重试次数
      if (attempt < retryCount) {
        console.warn(`请求失败（错误码 ${err.code}），正在重试... 尝试 ${attempt}/${retryCount}`);
        
        // 可选：添加重试间隔（避免立即重试）
        // await new Promise(resolve => setTimeout(resolve, 1000 * attempt)); // 指数退避
        
        // 递归调用进行重试
        return retryRequest(url, session, retryCount, attempt + 1);
      } else {
        // 达到最大重试次数，返回错误
        console.error(`已达到最大重试次数 (${retryCount})，请求最终失败`);
        return Promise.reject(err);
      }
    } else {
      // 不可重试的错误，直接返回
      console.error(`遇到不可重试的错误: ${err.code}`);
      return Promise.reject(err);
    }
  }
}

/**
 * 基本重试示例
 */
async function basicRetryExample(): Promise<void> {
  // 定义会话配置
  const sessionConfig: rcp.SessionConfiguration = {
    requestConfiguration: {
      transfer: {
        timeout: {
          connectMs: 3000,
          transferMs: 6000
        }
      }
    }
  };
  
  // 创建会话
  const session = rcp.createSession(sessionConfig);
  
  // 定义请求参数
  const url = 'https://www.example.com';
  const retryCount = 3;  // 最大重试次数
  const attempt = 1;     // 当前尝试次数
  
  try {
    // 调用重试函数
    const response = await retryRequest(url, session, retryCount, attempt);
    
    // 处理响应
    console.info('请求最终成功');
    console.info(`状态码: ${response.statusCode}`);
    
    if (response.body) {
      const decoder = new TextDecoder('utf-8');
      const bodyText = decoder.decode(response.body);
      console.info(`响应内容: ${bodyText.substring(0, 100)}...`);
    }
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`请求最终失败: 错误码 ${err.code}, 消息: ${err.message}`);
    
    // 根据错误码提供解决建议
    switch (err.code) {
      case 1007900006:
        console.error('建议: 检查URL格式或DNS配置');
        break;
      case 1007900007:
        console.error('建议: 检查网络连接和服务器可用性');
        break;
      case 1007900028:
        console.error('建议: 增加超时时间或检查网络稳定性');
        break;
      case 1007900035:
        console.error('建议: 检查TLS版本和加密套件配置');
        break;
      default:
        console.error('建议: 查看错误码详情并针对性处理');
    }
    
  } finally {
    // 关闭Session
    session.close();
    console.info('Session已关闭');
  }
}

/**
 * 完整的HTTP请求封装类（包含重试机制）
 */
class HttpClientWithRetry {
  private session: rcp.Session;
  private maxRetryCount: number;
  
  /**
   * 构造函数
   * @param timeout 超时配置
   * @param retryCount 最大重试次数
   */
  constructor(timeout: { connectMs: number; transferMs: number }, retryCount: number = 3) {
    this.maxRetryCount = retryCount;
    
    const sessionConfig: rcp.SessionConfiguration = {
      requestConfiguration: {
        transfer: {
          timeout: timeout
        }
      }
    };
    
    this.session = rcp.createSession(sessionConfig);
  }
  
  /**
   * 发起GET请求（带重试）
   * @param url 请求URL
   * @returns Promise<rcp.Response>
   */
  async get(url: string): Promise<rcp.Response> {
    return this.requestWithRetry(url, () => this.session.get(url));
  }
  
  /**
   * 发起POST请求（带重试）
   * @param url 请求URL
   * @param content 请求内容
   * @returns Promise<rcp.Response>
   */
  async post(url: string, content: rcp.RequestContent): Promise<rcp.Response> {
    return this.requestWithRetry(url, () => this.session.post(url, content));
  }
  
  /**
   * 通用的重试逻辑
   * @param url 请求URL
   * @param requestFn 请求函数
   * @returns Promise<rcp.Response>
   */
  private async requestWithRetry(
    url: string,
    requestFn: () => Promise<rcp.Response>
  ): Promise<rcp.Response> {
    let lastError: BusinessError | null = null;
    
    for (let attempt = 1; attempt <= this.maxRetryCount; attempt++) {
      try {
        console.info(`尝试发起请求 (第 ${attempt} 次): ${url}`);
        const response = await requestFn();
        console.info(`请求成功 (第 ${attempt} 次)`);
        return response;
        
      } catch (error) {
        const err = error as BusinessError;
        lastError = err;
        
        console.warn(`第 ${attempt} 次尝试失败: 错误码 ${err.code}`);
        
        if (!RETRYABLE_ERRORS.includes(err.code)) {
          console.error('遇到不可重试错误，立即返回');
          throw err;
        }
        
        if (attempt < this.maxRetryCount) {
          // 指数退避：等待时间随重试次数增加
          const waitTime = Math.pow(2, attempt) * 1000; // 1秒、2秒、4秒
          console.info(`等待 ${waitTime}ms 后重试...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
        }
      }
    }
    
    // 所有尝试都失败
    console.error(`所有 ${this.maxRetryCount} 次尝试都失败`);
    throw lastError!;
  }
  
  /**
   * 关闭客户端，释放资源
   */
  close(): void {
    this.session.close();
    console.info('HttpClient已关闭');
  }
}

/**
 * 使用封装类的示例
 */
async function httpClientClassExample(): Promise<void> {
  // 创建HTTP客户端（超时配置 + 重试次数）
  const client = new HttpClientWithRetry(
    { connectMs: 3000, transferMs: 6000 },
    3  // 最大重试3次
  );
  
  try {
    // 发起GET请求（自动重试）
    const response = await client.get('https://www.example.com/api/data');
    
    console.info(`最终请求成功: ${response.statusCode}`);
    
    // 处理响应数据
    if (response.body) {
      const decoder = new TextDecoder('utf-8');
      const data = JSON.parse(decoder.decode(response.body));
      console.info('数据:', data);
    }
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`请求失败: ${err.code} - ${err.message}`);
    
  } finally {
    // 关闭客户端
    client.close();
  }
}

/**
 * 主函数入口
 */
@Entry
@Component
struct RetryMechanismExample {
  build() {
    Column() {
      Button('基本重试示例')
        .onClick(() => {
          basicRetryExample();
        })
        .margin(10);
      
      Button('封装类示例')
        .onClick(() => {
          httpClientClassExample();
        })
        .margin(10);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}