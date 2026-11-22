/**
 * 拦截器Session完整配置示例
 * 功能：综合展示多种拦截器的配置和使用
 * 适用场景：生产环境中的完整拦截器解决方案
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { url } from '@kit.ArkTS';

// 导入各个拦截器类
import { NetworkQualityProvider, RequestUrlChangeInterceptor } from './request-url-change-interceptor.ets';
import { ResponseHeaderRemoveInterceptor, AdvancedResponseHeaderInterceptor } from './response-header-remove-interceptor.ets';
import { ResponseCache, ResponseCachingInterceptor } from './response-caching-interceptor.ets';

/**
 * 拦截器配置选项
 */
export interface InterceptorConfigOptions {
  enableNetworkAdaptation: boolean;    // 启用网络自适应拦截器
  enableResponseCache: boolean;         // 启用响应缓存拦截器
  enableHeaderFilter: boolean;          // 启用响应头过滤拦截器
  enableSecurityFilter: boolean;        // 启用安全headers过滤
  maxCacheSize: number;                 // 最大缓存数量
  cacheExpiryMs: number;                // 缓存过期时间（毫秒）
  allowedHeaders: string[];             // 允许保留的headers
  blockedHeaders: string[];             // 需要移除的headers
}

/**
 * 默认拦截器配置
 */
const DEFAULT_CONFIG: InterceptorConfigOptions = {
  enableNetworkAdaptation: true,
  enableResponseCache: true,
  enableHeaderFilter: true,
  enableSecurityFilter: true,
  maxCacheSize: 50,
  cacheExpiryMs: 60000,
  allowedHeaders: ['content-type', 'etag', 'last-modified'],
  blockedHeaders: ['x-auth-token', 'authorization']
};

/**
 * 创建完整的拦截器Session
 * @param config 拦截器配置选项
 * @param networkQualityProvider 网络质量提供者（可选）
 * @returns 配置好的Session对象和缓存管理器
 */
export function createFullInterceptorSession(
  config: Partial<InterceptorConfigOptions> = {},
  networkQualityProvider?: NetworkQualityProvider
): { session: rcp.Session; cache: ResponseCache | null } {
  
  // 合并默认配置和用户配置
  const finalConfig: InterceptorConfigOptions = { ...DEFAULT_CONFIG, ...config };
  
  // 准备拦截器数组
  const interceptors: rcp.Interceptor[] = [];
  
  // 1. 添加网络自适应拦截器
  if (finalConfig.enableNetworkAdaptation && networkQualityProvider) {
    interceptors.push(new RequestUrlChangeInterceptor(networkQualityProvider));
    console.info('[SessionFactory]: Network adaptation interceptor added');
  }
  
  // 2. 添加响应缓存拦截器
  let cache: ResponseCache | null = null;
  if (finalConfig.enableResponseCache) {
    cache = new ResponseCache(finalConfig.maxCacheSize, finalConfig.cacheExpiryMs);
    interceptors.push(new ResponseCachingInterceptor(cache));
    console.info('[SessionFactory]: Response caching interceptor added');
    console.info(`  Cache size: ${finalConfig.maxCacheSize}, expiry: ${finalConfig.cacheExpiryMs}ms`);
  }
  
  // 3. 添加响应头过滤拦截器（白名单模式）
  if (finalConfig.enableHeaderFilter) {
    interceptors.push(new ResponseHeaderRemoveInterceptor(finalConfig.allowedHeaders));
    console.info('[SessionFactory]: Header filter interceptor added');
    console.info(`  Allowed headers: ${finalConfig.allowedHeaders.join(', ')}`);
  }
  
  // 4. 添加安全headers过滤拦截器（黑名单模式）
  if (finalConfig.enableSecurityFilter && finalConfig.blockedHeaders.length > 0) {
    interceptors.push(new AdvancedResponseHeaderInterceptor('blacklist', finalConfig.blockedHeaders));
    console.info('[SessionFactory]: Security header filter added');
    console.info(`  Blocked headers: ${finalConfig.blockedHeaders.join(', ')}`);
  }
  
  // 创建SessionConfiguration
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: interceptors,
    requestConfiguration: {
      transfer: {
        timeout: {
          connectMs: 10000,
          transferMs: 30000
        },
        autoRedirect: true,
        maxAutoRedirects: 5
      },
      tracing: {
        verbose: true,
        collectTimeInfo: true
      },
      security: {
        tlsOptions: {
          tlsVersion: 'TlsV1.3'
        }
      }
    }
  };
  
  // 创建Session
  const session = rcp.createSession(sessionConfig);
  
  console.info('[SessionFactory]: Session created with interceptors');
  console.info(`  Total interceptors: ${interceptors.length}`);
  
  return { session, cache };
}

/**
 * 完整拦截器Session使用示例
 */
export async function fullInterceptorSessionExample() {
  // 创建网络质量提供者
  const networkQualityProvider = new NetworkQualityProvider(true);
  
  // 创建完整拦截器Session
  const { session, cache } = createFullInterceptorSession(
    {
      enableNetworkAdaptation: true,
      enableResponseCache: true,
      enableHeaderFilter: true,
      enableSecurityFilter: true,
      maxCacheSize: 30,
      cacheExpiryMs: 30000
    },
    networkQualityProvider
  );
  
  try {
    const requestUrl = 'https://example.com/api/images/photo.jpg';
    
    console.info('[Example]: Sending request with full interceptor chain');
    console.info(`  URL: ${requestUrl}`);
    
    // 发送请求
    const response = await session.get(requestUrl);
    
    console.info('[Example]: Request completed');
    console.info(`  Status code: ${response.statusCode}`);
    console.info(`  Effective URL: ${response.effectiveUrl}`);
    console.info(`  Headers: ${JSON.stringify(response.headers)}`);
    
    if (response.timeInfo) {
      console.info(`  Total time: ${response.timeInfo.totalTimeMs}ms`);
    }
    
    // 查看缓存统计（如果缓存启用）
    if (cache) {
      const stats = cache.getStats();
      console.info(`  Cache stats: ${stats.total}/${stats.maxSize} entries`);
    }
    
    // 模拟网络质量变化
    console.info('[Example]: Simulating network quality change to slow');
    networkQualityProvider.updateNetworkQuality(false);
    
    // 发送第二次请求（拦截器会修改URL）
    const response2 = await session.get(requestUrl);
    console.info('[Example]: Second request completed');
    console.info(`  Effective URL: ${response2.effectiveUrl}`);
    
    // 验证URL修改（如果网络自适应拦截器启用）
    if (response2.effectiveUrl && response2.effectiveUrl.includes('_small')) {
      console.info('[Example]: ✓ URL modified by network adaptation interceptor');
    }
    
    return { response, response2, cache };
    
  } catch (error) {
    console.error('[Example]: Request failed:', error);
    throw error;
    
  } finally {
    // 关闭Session
    session.close();
    console.info('[Example]: Session closed');
    
    // 清空缓存
    if (cache) {
      cache.clearAll();
      console.info('[Example]: Cache cleared');
    }
  }
}

/**
 * 多拦截器链执行顺序验证示例
 */
export async function interceptorChainOrderExample() {
  /**
   * 日志记录拦截器（用于验证执行顺序）
   */
  class LoggingInterceptor implements rcp.Interceptor {
    private readonly name: string;
    
    constructor(name: string) {
      this.name = name;
    }
    
    async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
      console.info(`[${this.name}]: Request phase - before next.handle()`);
      
      const response = await next.handle(context);
      
      console.info(`[${this.name}]: Response phase - after next.handle()`);
      
      return response;
    }
  }
  
  // 创建拦截器链：A -> B -> C
  const interceptors: rcp.Interceptor[] = [
    new LoggingInterceptor('Interceptor-A'),
    new LoggingInterceptor('Interceptor-B'),
    new LoggingInterceptor('Interceptor-C')
  ];
  
  const sessionConfig: rcp.SessionConfiguration = { interceptors };
  const session = rcp.createSession(sessionConfig);
  
  try {
    console.info('[ChainOrder]: Sending request to verify interceptor execution order');
    
    const response = await session.get('https://example.com/test');
    
    console.info('[ChainOrder]: Request completed');
    console.info('[ChainOrder]: Expected execution order:');
    console.info('  Request phase: A -> B -> C');
    console.info('  Response phase: C -> B -> A');
    
    return response;
    
  } finally {
    session.close();
  }
}

/**
 * 生产环境完整示例
 */
export async function productionInterceptorExample() {
  // 生产环境配置
  const config: Partial<InterceptorConfigOptions> = {
    enableNetworkAdaptation: true,
    enableResponseCache: true,
    enableHeaderFilter: true,
    enableSecurityFilter: true,
    maxCacheSize: 100,
    cacheExpiryMs: 120000, // 2分钟
    allowedHeaders: ['content-type', 'etag', 'last-modified', 'cache-control'],
    blockedHeaders: ['x-auth-token', 'authorization', 'x-api-key']
  };
  
  // 创建网络质量监控（实际应用中应接入真实网络监控）
  const networkMonitor = new NetworkQualityProvider(true);
  
  // 定期更新网络质量（模拟）
  setInterval(() => {
    // 实际应用中应调用真实的网络质量检测API
    const isNetworkFast = Math.random() > 0.3; // 模拟网络质量变化
    networkMonitor.updateNetworkQuality(isNetworkFast);
  }, 10000);
  
  // 创建Session
  const { session, cache } = createFullInterceptorSession(config, networkMonitor);
  
  try {
    // API请求列表
    const apiEndpoints = [
      'https://api.example.com/v1/users',
      'https://api.example.com/v1/products',
      'https://api.example.com/v1/orders'
    ];
    
    console.info('[Production]: Starting API requests');
    
    // 批量请求API
    const results: rcp.Response[] = [];
    for (const endpoint of apiEndpoints) {
      try {
        const response = await session.get(endpoint);
        console.info(`  ✓ ${endpoint} - Status: ${response.statusCode}`);
        results.push(response);
      } catch (error) {
        console.error(`  ✗ ${endpoint} - Error: ${error.message}`);
      }
    }
    
    // 查看缓存统计
    if (cache) {
      const stats = cache.getStats();
      console.info(`[Production]: Cache stats: ${stats.total}/${stats.maxSize} cached responses`);
      console.info(`  Cached URLs: ${stats.urls.join(', ')}`);
    }
    
    return { results, cache };
    
  } finally {
    session.close();
    if (cache) {
      cache.clearAll();
    }
  }
}

/**
 * 测试用例验证函数
 */
export async function testFullInterceptorSession() {
  console.info('[Test]: Starting full interceptor session test');
  
  try {
    const result = await fullInterceptorSessionExample();
    
    // 验证拦截器链执行成功
    if (result.response && result.response.statusCode) {
      console.info('[Test]: ✓ Interceptor chain executed successfully');
    } else {
      console.warn('[Test]: ✗ Interceptor chain execution failed');
    }
    
    // 验证缓存功能
    if (result.cache) {
      const stats = result.cache.getStats();
      if (stats.total > 0) {
        console.info(`[Test]: ✓ Cache working (${stats.total} entries)`);
      } else {
        console.warn('[Test]: ✗ Cache not working');
      }
    }
    
    console.info('[Test]: Test completed successfully');
    
  } catch (error) {
    console.error('[Test]: Test failed:', error);
    throw error;
  }
}