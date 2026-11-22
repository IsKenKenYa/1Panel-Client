/**
 * 响应头过滤拦截器完整示例
 * 功能：过滤响应头，只保留指定的headers字段
 * 适用场景：敏感信息移除、响应数据简化、隐私保护
 */

import { rcp } from '@kit.RemoteCommunicationKit';

/**
 * 响应头过滤拦截器
 * 过滤响应头，只保留content-range等指定字段
 */
export class ResponseHeaderRemoveInterceptor implements rcp.Interceptor {
  private readonly allowedHeaders: string[];
  
  /**
   * 构造函数
   * @param allowedHeaders 允许保留的响应头字段列表（默认只保留content-range）
   */
  constructor(allowedHeaders: string[] = ['content-range']) {
    this.allowedHeaders = allowedHeaders;
  }
  
  /**
   * 拦截响应并过滤headers
   * @param context 请求上下文
   * @param next 下一个请求处理器
   * @returns Promise<Response> 过滤后的响应对象
   */
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      console.info('[ResponseHeaderRemoveInterceptor]: Processing request');
      
      // 先执行请求获取原始响应
      const originalResponse = await next.handle(context);
      
      console.info('[ResponseHeaderRemoveInterceptor]: Response received');
      console.info(`  Original headers count: ${Object.keys(originalResponse.headers).length}`);
      
      // 构建过滤后的响应对象
      const filteredHeaders: Record<string, string | string[] | undefined> = {};
      
      // 只保留允许的headers字段
      for (const allowedHeader of this.allowedHeaders) {
        if (originalResponse.headers[allowedHeader]) {
          filteredHeaders[allowedHeader] = originalResponse.headers[allowedHeader];
          console.info(`  Preserved header: ${allowedHeader}`);
        }
      }
      
      // 创建新的响应对象（保留其他必需字段）
      const filteredResponse: rcp.Response = {
        request: originalResponse.request,
        statusCode: originalResponse.statusCode,
        httpVersion: originalResponse.httpVersion,
        headers: filteredHeaders,
        effectiveUrl: originalResponse.effectiveUrl,
        timeInfo: originalResponse.timeInfo,
        toJSON: () => {
          return {
            statusCode: originalResponse.statusCode,
            headers: filteredHeaders,
            effectiveUrl: originalResponse.effectiveUrl
          };
        }
      };
      
      console.info('[ResponseHeaderRemoveInterceptor]: Headers filtered');
      console.info(`  Filtered headers count: ${Object.keys(filteredHeaders).length}`);
      console.info(`  Removed headers: ${Object.keys(originalResponse.headers).filter(h => !this.allowedHeaders.includes(h)).join(', ')}`);
      
      return filteredResponse;
      
    } catch (error) {
      console.error('[ResponseHeaderRemoveInterceptor]: Error occurred:', error);
      
      // 降级处理：返回原始响应
      console.warn('[ResponseHeaderRemoveInterceptor]: Fallback: returning original response');
      const response = await next.handle(context);
      return response;
    }
  }
}

/**
 * 高级响应头过滤拦截器
 * 支持正则表达式匹配和黑名单模式
 */
export class AdvancedResponseHeaderInterceptor implements rcp.Interceptor {
  private readonly mode: 'whitelist' | 'blacklist';
  private readonly headerPatterns: string[];
  
  /**
   * 构造函数
   * @param mode 过滤模式：whitelist（白名单保留）或 blacklist（黑名单移除）
   * @param headerPatterns header字段名列表或正则表达式
   */
  constructor(mode: 'whitelist' | 'blacklist', headerPatterns: string[]) {
    this.mode = mode;
    this.headerPatterns = headerPatterns;
  }
  
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      const response = await next.handle(context);
      
      const filteredHeaders: Record<string, string | string[] | undefined> = {};
      const originalHeaders = response.headers;
      
      if (this.mode === 'whitelist') {
        // 白名单模式：只保留匹配的headers
        for (const [key, value] of Object.entries(originalHeaders)) {
          if (this.headerPatterns.some(pattern => key.match(pattern))) {
            filteredHeaders[key] = value;
          }
        }
      } else {
        // 黑名单模式：移除匹配的headers
        for (const [key, value] of Object.entries(originalHeaders)) {
          if (!this.headerPatterns.some(pattern => key.match(pattern))) {
            filteredHeaders[key] = value;
          }
        }
      }
      
      return {
        request: response.request,
        statusCode: response.statusCode,
        httpVersion: response.httpVersion,
        headers: filteredHeaders,
        effectiveUrl: response.effectiveUrl,
        timeInfo: response.timeInfo,
        toJSON: () => null
      };
      
    } catch (error) {
      console.error('[AdvancedResponseHeaderInterceptor]: Error:', error);
      const response = await next.handle(context);
      return response;
    }
  }
}

/**
 * 完整使用示例
 */
export async function responseHeaderRemoveInterceptorExample() {
  // 配置Session
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [
      new ResponseHeaderRemoveInterceptor(['content-range', 'content-type', 'etag'])
    ],
    requestConfiguration: {
      tracing: {
        verbose: true
      }
    }
  };
  
  const session = rcp.createSession(sessionConfig);
  
  try {
    // 发送请求
    const requestUrl = 'https://example.com/api/resource';
    console.info(`[Example]: Sending request to ${requestUrl}`);
    
    const response = await session.get(requestUrl);
    
    console.info('[Example]: Response received');
    console.info(`  Status code: ${response.statusCode}`);
    console.info(`  Headers: ${JSON.stringify(response.headers, null, 2)}`);
    
    // 验证headers过滤结果
    const headersKeys = Object.keys(response.headers);
    console.info(`  Headers count: ${headersKeys.length}`);
    console.info(`  Header fields: ${headersKeys.join(', ')}`);
    
    return response;
    
  } catch (error) {
    console.error('[Example]: Request failed:', error);
    throw error;
    
  } finally {
    session.close();
    console.info('[Example]: Session closed');
  }
}

/**
 * 黑名单模式示例
 */
export async function blacklistHeaderInterceptorExample() {
  // 使用黑名单模式移除敏感headers
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [
      new AdvancedResponseHeaderInterceptor('blacklist', [
        'x-auth-token',
        'x-session-id',
        'authorization'
      ])
    ]
  };
  
  const session = rcp.createSession(sessionConfig);
  
  try {
    const response = await session.get('https://example.com/api/data');
    
    console.info('[Example]: Blacklist interceptor applied');
    console.info(`  Headers: ${JSON.stringify(response.headers)}`);
    
    // 验证敏感headers已被移除
    const sensitiveHeaders = ['x-auth-token', 'x-session-id', 'authorization'];
    for (const header of sensitiveHeaders) {
      if (!response.headers[header]) {
        console.info(`  ✓ Sensitive header '${header}' removed`);
      } else {
        console.warn(`  ✗ Sensitive header '${header}' still present`);
      }
    }
    
    return response;
    
  } finally {
    session.close();
  }
}

/**
 * 测试用例验证函数
 */
export async function testResponseHeaderRemoveInterceptor() {
  console.info('[Test]: Starting ResponseHeaderRemoveInterceptor test');
  
  try {
    const response = await responseHeaderRemoveInterceptorExample();
    
    // 验证headers数量减少
    const headersCount = Object.keys(response.headers).length;
    if (headersCount <= 3) {
      console.info(`[Test]: ✓ Headers filtered successfully (${headersCount} headers preserved)`);
    } else {
      console.warn(`[Test]: ✗ Too many headers preserved (${headersCount})`);
    }
    
    // 验证指定的headers存在
    const expectedHeaders = ['content-range', 'content-type', 'etag'];
    for (const header of expectedHeaders) {
      if (response.headers[header] !== undefined) {
        console.info(`[Test]: ✓ Expected header '${header}' preserved`);
      } else {
        console.warn(`[Test]: Header '${header}' not found in response`);
      }
    }
    
    console.info('[Test]: Test completed successfully');
    return response;
    
  } catch (error) {
    console.error('[Test]: Test failed:', error);
    throw error;
  }
}