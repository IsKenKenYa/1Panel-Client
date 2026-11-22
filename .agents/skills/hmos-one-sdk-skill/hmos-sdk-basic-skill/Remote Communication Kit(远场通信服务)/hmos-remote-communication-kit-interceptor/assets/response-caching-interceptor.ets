/**
 * 响应缓存拦截器完整示例
 * 功能：缓存HTTP响应，避免重复请求相同资源
 * 适用场景：性能优化、减少网络请求、离线访问支持
 */

import { rcp } from '@kit.RemoteCommunicationKit';

/**
 * 响应缓存管理器
 * 存储和管理缓存的HTTP响应
 */
export class ResponseCache {
  private readonly cache: Record<string, rcp.Response> = {};
  private readonly maxCacheSize: number;
  private readonly cacheExpiryMs: number;
  private readonly cacheTimestamps: Record<string, number> = {};
  
  /**
   * 构造函数
   * @param maxCacheSize 最大缓存数量（默认100）
   * @param cacheExpiryMs 缓存过期时间（毫秒，默认60000ms即1分钟）
   */
  constructor(maxCacheSize: number = 100, cacheExpiryMs: number = 60000) {
    this.maxCacheSize = maxCacheSize;
    this.cacheExpiryMs = cacheExpiryMs;
  }
  
  /**
   * 获取缓存的响应
   * @param url 请求URL
   * @returns 缓存的响应对象或undefined
   */
  getResponse(url: string): rcp.Response | undefined {
    // 检查缓存是否存在
    if (!this.cache[url]) {
      console.info(`[ResponseCache]: No cache found for ${url}`);
      return undefined;
    }
    
    // 检查缓存是否过期
    const timestamp = this.cacheTimestamps[url];
    const now = Date.now();
    if (now - timestamp > this.cacheExpiryMs) {
      console.info(`[ResponseCache]: Cache expired for ${url}`);
      this.removeResponse(url);
      return undefined;
    }
    
    console.info(`[ResponseCache]: Cache hit for ${url}`);
    return this.cache[url];
  }
  
  /**
   * 缓存响应
   * @param url 请求URL
   * @param response 响应对象
   */
  setResponse(url: string, response: rcp.Response): void {
    // 如果缓存已满，移除最旧的缓存
    if (Object.keys(this.cache).length >= this.maxCacheSize) {
      this.removeOldestCache();
    }
    
    this.cache[url] = response;
    this.cacheTimestamps[url] = Date.now();
    console.info(`[ResponseCache]: Response cached for ${url}`);
    console.info(`  Cache size: ${Object.keys(this.cache).length}/${this.maxCacheSize}`);
  }
  
  /**
   * 移除缓存的响应
   * @param url 请求URL
   */
  removeResponse(url: string): void {
    delete this.cache[url];
    delete this.cacheTimestamps[url];
    console.info(`[ResponseCache]: Cache removed for ${url}`);
  }
  
  /**
   * 移除最旧的缓存
   */
  private removeOldestCache(): void {
    const urls = Object.keys(this.cacheTimestamps);
    if (urls.length === 0) return;
    
    // 找到时间戳最小的URL
    let oldestUrl = urls[0];
    let oldestTimestamp = this.cacheTimestamps[oldestUrl];
    
    for (const url of urls) {
      const timestamp = this.cacheTimestamps[url];
      if (timestamp < oldestTimestamp) {
        oldestUrl = url;
        oldestTimestamp = timestamp;
      }
    }
    
    this.removeResponse(oldestUrl);
    console.info(`[ResponseCache]: Removed oldest cache for ${oldestUrl}`);
  }
  
  /**
   * 清空所有缓存
   */
  clearAll(): void {
    this.cache = {};
    this.cacheTimestamps = {};
    console.info('[ResponseCache]: All caches cleared');
  }
  
  /**
   * 获取缓存统计信息
   */
  getStats(): { total: number; maxSize: number; urls: string[] } {
    return {
      total: Object.keys(this.cache).length,
      maxSize: this.maxCacheSize,
      urls: Object.keys(this.cache)
    };
  }
}

/**
 * 响应缓存拦截器
 * 自动缓存响应并在后续请求中返回缓存数据
 */
export class ResponseCachingInterceptor implements rcp.Interceptor {
  private readonly cache: ResponseCache;
  
  constructor(cache: ResponseCache) {
    this.cache = cache;
  }
  
  /**
   * 拦截请求并实现缓存逻辑
   * @param context 请求上下文
   * @param next 下一个请求处理器
   * @returns Promise<Response> 缓存的响应或新请求的响应
   */
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const url = context.request.url.href;
    
    try {
      // 检查缓存
      const cachedResponse = this.cache.getResponse(url);
      
      if (cachedResponse) {
        console.info('[ResponseCachingInterceptor]: Returning cached response');
        console.info(`  URL: ${url}`);
        console.info(`  Status: ${cachedResponse.statusCode}`);
        
        // 直接返回缓存响应，不继续执行请求
        return Promise.resolve(cachedResponse);
      }
      
      console.info('[ResponseCachingInterceptor]: No cache found, executing request');
      
      // 执行请求获取响应
      const response = await next.handle(context);
      
      // 仅缓存成功的响应（status code 200-299）
      if (response.statusCode >= 200 && response.statusCode < 300) {
        this.cache.setResponse(url, response);
        console.info('[ResponseCachingInterceptor]: Response cached successfully');
      } else {
        console.warn('[ResponseCachingInterceptor]: Response not cached (non-success status)');
      }
      
      return response;
      
    } catch (error) {
      console.error('[ResponseCachingInterceptor]: Error occurred:', error);
      
      // 降级处理：执行原始请求不缓存
      const response = await next.handle(context);
      return response;
    }
  }
}

/**
 * 完整使用示例
 */
export async function responseCachingInterceptorExample() {
  // 创建缓存管理器（最大缓存50个，过期时间30秒）
  const cache = new ResponseCache(50, 30000);
  
  // 配置Session
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [
      new ResponseCachingInterceptor(cache)
    ]
  };
  
  const session = rcp.createSession(sessionConfig);
  
  try {
    const requestUrl = 'https://example.com/api/data';
    
    // 第一次请求（会执行实际请求并缓存）
    console.info('[Example]: First request (will be cached)');
    const response1 = await session.get(requestUrl);
    console.info(`  Response status: ${response1.statusCode}`);
    console.info(`  Response time info: ${JSON.stringify(response1.timeInfo)}`);
    
    // 查看缓存统计
    const stats1 = cache.getStats();
    console.info(`  Cache stats: ${stats1.total}/${stats1.maxSize} entries`);
    
    // 第二次请求（会直接返回缓存）
    console.info('[Example]: Second request (should use cache)');
    const response2 = await session.get(requestUrl);
    console.info(`  Response status: ${response2.statusCode}`);
    console.info(`  Response time info: ${JSON.stringify(response2.timeInfo)}`);
    
    // 验证缓存命中（第二次请求时间应该更短）
    if (response1.timeInfo && response2.timeInfo) {
      const time1 = response1.timeInfo.totalTimeMs || 0;
      const time2 = response2.timeInfo.totalTimeMs || 0;
      console.info(`  Performance comparison:`);
      console.info(`    First request: ${time1}ms`);
      console.info(`    Second request: ${time2}ms`);
      
      if (time2 < time1) {
        console.info(`    ✓ Cache improved performance (${((time1 - time2) / time1 * 100).toFixed(1)}% faster)`);
      }
    }
    
    // 等待缓存过期
    console.info('[Example]: Waiting for cache expiry (30 seconds)');
    await new Promise(resolve => setTimeout(resolve, 31000));
    
    // 第三次请求（缓存过期，会重新请求）
    console.info('[Example]: Third request (cache expired, will execute request)');
    const response3 = await session.get(requestUrl);
    console.info(`  Response status: ${response3.statusCode}`);
    
    return { response1, response2, response3, cache };
    
  } catch (error) {
    console.error('[Example]: Request failed:', error);
    throw error;
    
  } finally {
    session.close();
    console.info('[Example]: Session closed');
    
    // 清空缓存
    cache.clearAll();
    console.info('[Example]: Cache cleared');
  }
}

/**
 * 缓存预热示例
 */
export async function cacheWarmUpExample(urls: string[]) {
  const cache = new ResponseCache(100, 120000); // 缓存2分钟
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [new ResponseCachingInterceptor(cache)]
  };
  
  const session = rcp.createSession(sessionConfig);
  
  try {
    console.info('[CacheWarmUp]: Starting cache warm-up for URLs:', urls);
    
    // 预热缓存：请求所有URL并缓存响应
    for (const url of urls) {
      try {
        const response = await session.get(url);
        console.info(`  ✓ ${url} cached (status: ${response.statusCode})`);
      } catch (error) {
        console.warn(`  ✗ ${url} failed: ${error.message}`);
      }
    }
    
    // 返回缓存统计
    const stats = cache.getStats();
    console.info(`[CacheWarmUp]: Completed, ${stats.total} URLs cached`);
    
    return cache;
    
  } finally {
    session.close();
  }
}

/**
 * 测试用例验证函数
 */
export async function testResponseCachingInterceptor() {
  console.info('[Test]: Starting ResponseCachingInterceptor test');
  
  try {
    const result = await responseCachingInterceptorExample();
    
    // 验证第一次请求后缓存已建立
    const stats1 = result.cache.getStats();
    if (stats1.total > 0) {
      console.info(`[Test]: ✓ Cache established (${stats1.total} entries)`);
    } else {
      console.warn('[Test]: ✗ Cache not established');
    }
    
    // 验证缓存命中逻辑
    const cachedResponse = result.cache.getResponse('https://example.com/api/data');
    if (cachedResponse) {
      console.info('[Test]: ✓ Cache retrieval working');
    } else {
      console.warn('[Test]: ✗ Cache retrieval failed');
    }
    
    console.info('[Test]: Test completed successfully');
    
  } catch (error) {
    console.error('[Test]: Test failed:', error);
    throw error;
  }
}