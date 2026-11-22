import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 响应缓存拦截器完整实现
 * 功能：缓存HTTP响应，支持过期时间检查，减少重复网络请求
 */

/**
 * 缓存配置选项
 */
export interface CacheOptions {
  maxCacheSize?: number;       // 最大缓存数量，默认100
  defaultTTL?: number;         // 默认过期时间（毫秒），默认3600000（1小时）
  enableSizeLimit?: boolean;   // 是否启用响应大小限制，默认true
  maxResponseSize?: number;    // 最大响应大小（字节），默认1048576（1MB）
}

/**
 * 缓存条目结构
 */
interface CacheEntry {
  response: rcp.Response;
  timestamp: number;
  ttl: number;
  size: number;
}

/**
 * 高级响应缓存类
 * 支持TTL过期检查、大小限制、缓存容量管理
 */
export class AdvancedResponseCache {
  private cache: Map<string, CacheEntry> = new Map();
  private options: CacheOptions;
  private totalSize: number = 0;

  constructor(options?: CacheOptions) {
    this.options = {
      maxCacheSize: options?.maxCacheSize || 100,
      defaultTTL: options?.defaultTTL || 3600000, // 1小时
      enableSizeLimit: options?.enableSizeLimit || true,
      maxResponseSize: options?.maxResponseSize || 1048576 // 1MB
    };
    console.info('[AdvancedResponseCache] Cache initialized with options:', JSON.stringify(this.options));
  }

  /**
   * 获取缓存响应
   * @param url 请求URL
   * @returns 缓存的响应或undefined
   */
  getResponse(url: string): rcp.Response | undefined {
    const entry = this.cache.get(url);
    
    if (!entry) {
      console.info(`[AdvancedResponseCache] No cache found for: ${url}`);
      return undefined;
    }

    // 检查是否过期
    const now = Date.now();
    if (now - entry.timestamp > entry.ttl) {
      console.info(`[AdvancedResponseCache] Cache expired for: ${url}`);
      this.removeEntry(url);
      return undefined;
    }

    console.info(`[AdvancedResponseCache] Cache hit for: ${url}, age=${Math.floor((now - entry.timestamp) / 1000)}s`);
    return entry.response;
  }

  /**
   * 设置缓存响应
   * @param url 请求URL
   * @param response 响应对象
   * @param ttl 过期时间（可选）
   */
  setResponse(url: string, response: rcp.Response, ttl?: number): boolean {
    // 计算响应大小（估算）
    const size = this.calculateResponseSize(response);

    // 检查响应大小限制
    if (this.options.enableSizeLimit && size > this.options.maxResponseSize) {
      console.warn(`[AdvancedResponseCache] Response too large to cache: ${url}, size=${size} bytes`);
      return false;
    }

    // 检查缓存容量，必要时清理旧缓存
    if (this.cache.size >= this.options.maxCacheSize) {
      console.info('[AdvancedResponseCache] Cache full, removing oldest entries');
      this.evictOldestEntries(Math.floor(this.options.maxCacheSize * 0.2)); // 清理20%
    }

    // 创建缓存条目
    const entry: CacheEntry = {
      response: response,
      timestamp: Date.now(),
      ttl: ttl || this.options.defaultTTL,
      size: size
    };

    this.cache.set(url, entry);
    this.totalSize += size;

    console.info(`[AdvancedResponseCache] Cached: ${url}, ttl=${entry.ttl}ms, size=${size} bytes`);
    console.info(`[AdvancedResponseCache] Cache stats: entries=${this.cache.size}, totalSize=${this.totalSize} bytes`);
    return true;
  }

  /**
   * 移除缓存条目
   * @param url 请求URL
   */
  removeEntry(url: string): void {
    const entry = this.cache.get(url);
    if (entry) {
      this.totalSize -= entry.size;
      this.cache.delete(url);
      console.info(`[AdvancedResponseCache] Removed cache for: ${url}`);
    }
  }

  /**
   * 清理最旧的缓存条目
   * @param count 要清理的数量
   */
  private evictOldestEntries(count: number): void {
    const entries = Array.from(this.cache.entries())
      .sort((a, b) => a[1].timestamp - b[1].timestamp);

    const toRemove = entries.slice(0, count);
    for (const [url, entry] of toRemove) {
      this.removeEntry(url);
    }

    console.info(`[AdvancedResponseCache] Evicted ${toRemove.length} oldest entries`);
  }

  /**
   * 计算响应大小（估算）
   * @param response 响应对象
   * @returns 估算的字节大小
   */
  private calculateResponseSize(response: rcp.Response): number {
    let size = 0;

    // 估算headers大小
    if (response.headers) {
      for (const [key, value] of Object.entries(response.headers)) {
        size += key.length + (typeof value === 'string' ? value.length : 50);
      }
    }

    // 估算body大小（如果存在）
    if (response.body) {
      if (typeof response.body === 'string') {
        size += response.body.length;
      } else if (response.body instanceof ArrayBuffer) {
        size += response.body.byteLength;
      } else {
        size += 100; // 未知类型，估算100字节
      }
    }

    return size;
  }

  /**
   * 清空所有缓存
   */
  clearCache(): void {
    const oldSize = this.cache.size;
    this.cache.clear();
    this.totalSize = 0;
    console.info(`[AdvancedResponseCache] Cache cleared, removed ${oldSize} entries`);
  }

  /**
   * 获取缓存统计信息
   */
  getStats(): { entryCount: number; totalSize: number; oldestEntryAge: number } {
    let oldestTimestamp = Date.now();
    
    for (const entry of this.cache.values()) {
      if (entry.timestamp < oldestTimestamp) {
        oldestTimestamp = entry.timestamp;
      }
    }

    return {
      entryCount: this.cache.size,
      totalSize: this.totalSize,
      oldestEntryAge: Math.floor((Date.now() - oldestTimestamp) / 1000)
    };
  }
}

/**
 * 高级缓存拦截器
 * 支持TTL、大小限制、容量管理
 */
export class AdvancedCachingInterceptor implements rcp.Interceptor {
  private readonly cache: AdvancedResponseCache;

  constructor(cache: AdvancedResponseCache) {
    this.cache = cache;
  }

  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const requestUrl = context.request.url.href;

    try {
      // 检查缓存
      const cachedResponse = this.cache.getResponse(requestUrl);
      if (cachedResponse) {
        console.info(`[AdvancedCachingInterceptor] Returning cached response for: ${requestUrl}`);
        
        // 标记响应来自缓存（可选）
        if (!cachedResponse.headers) {
          cachedResponse.headers = {};
        }
        cachedResponse.headers['x-cache-status'] = 'HIT';
        
        return Promise.resolve(cachedResponse);
      }

      // 缓存未命中，发起请求
      console.info(`[AdvancedCachingInterceptor] Cache miss, making request for: ${requestUrl}`);
      const response = await next.handle(context);

      // 尝试缓存响应
      // 根据响应状态码决定是否缓存（只缓存成功的响应）
      if (response.statusCode >= 200 && response.statusCode < 300) {
        const cached = this.cache.setResponse(requestUrl, response);
        if (!cached) {
          console.warn(`[AdvancedCachingInterceptor] Failed to cache response for: ${requestUrl}`);
        }
      } else {
        console.info(`[AdvancedCachingInterceptor] Not caching response with status: ${response.statusCode}`);
      }

      // 标记响应未来自缓存
      if (!response.headers) {
        response.headers = {};
      }
      response.headers['x-cache-status'] = 'MISS';

      return response;
    } catch (error) {
      console.error(`[AdvancedCachingInterceptor] Error for ${requestUrl}:`, error);
      throw error;
    }
  }
}

/**
 * 创建带高级缓存拦截器的Session
 * @param cacheOptions 缓存配置选项
 * @returns Session对象
 */
export function createSessionWithAdvancedCache(cacheOptions?: CacheOptions): rcp.Session {
  const cache = new AdvancedResponseCache(cacheOptions);
  
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [new AdvancedCachingInterceptor(cache)]
  };

  const session = rcp.createSession(sessionConfig);
  console.info('Session created with advanced cache interceptor');
  console.info('Cache options:', JSON.stringify(cacheOptions));
  
  return session;
}

/**
 * 高级缓存使用示例
 */
export async function advancedCacheExample(): Promise<void> {
  console.info('=== Advanced Cache Interceptor Example ===');

  // 配置缓存：最大50个条目，TTL 30分钟，最大响应大小5MB
  const cacheOptions: CacheOptions = {
    maxCacheSize: 50,
    defaultTTL: 1800000, // 30分钟
    maxResponseSize: 5242880 // 5MB
  };

  const session = createSessionWithAdvancedCache(cacheOptions);

  try {
    // 第一次请求：缓存未命中
    console.info('--- First Request (Cache Miss) ---');
    const url1 = 'https://www.example.com/api/data';
    const response1 = await session.get(url1);
    console.info(`Response 1: status=${response1.statusCode}, cache-status=${response1.headers['x-cache-status']}`);

    // 第二次请求：缓存命中
    console.info('--- Second Request (Cache Hit) ---');
    const response2 = await session.get(url1);
    console.info(`Response 2: status=${response2.statusCode}, cache-status=${response2.headers['x-cache-status']}`);

    // 等待一段时间，测试过期
    console.info('--- Waiting for cache to expire (simulated) ---');
    // 实际测试中可以等待真实时间或调整TTL
    // 这里仅演示逻辑，实际需要等待或修改缓存时间戳

    // 新的请求URL
    console.info('--- Request Different URL ---');
    const url2 = 'https://www.example.com/api/other';
    const response3 = await session.get(url2);
    console.info(`Response 3: status=${response3.statusCode}, cache-status=${response3.headers['x-cache-status']}`);

  } catch (error) {
    const businessError = error as BusinessError;
    console.error('Request failed:', businessError.code, businessError.message);
  } finally {
    session.close();
    console.info('Session closed');
  }
}

/**
 * 缓存统计信息示例
 */
export async function cacheStatisticsExample(): Promise<void> {
  const cache = new AdvancedResponseCache({
    maxCacheSize: 20,
    defaultTTL: 600000 // 10分钟
  });

  const interceptor = new AdvancedCachingInterceptor(cache);
  const session = rcp.createSession({ interceptors: [interceptor] });

  try {
    // 发送多个请求填充缓存
    const urls = [
      'https://www.example.com/api/1',
      'https://www.example.com/api/2',
      'https://www.example.com/api/3',
      'https://www.example.com/api/4',
      'https://www.example.com/api/5'
    ];

    for (const url of urls) {
      await session.get(url);
    }

    // 获取缓存统计信息
    const stats = cache.getStats();
    console.info('=== Cache Statistics ===');
    console.info(`Entry count: ${stats.entryCount}`);
    console.info(`Total size: ${stats.totalSize} bytes`);
    console.info(`Oldest entry age: ${stats.oldestEntryAge} seconds`);

  } catch (error) {
    console.error('Cache statistics example failed:', error);
  } finally {
    session.close();
    cache.clearCache();
  }
}

/**
 * 手动控制缓存过期时间示例
 */
export async function manualTTLEExample(): Promise<void> {
  const cache = new AdvancedResponseCache({ defaultTTL: 3600000 }); // 默认1小时
  
  const session = rcp.createSession({
    interceptors: [new AdvancedCachingInterceptor(cache)]
  });

  try {
    const url = 'https://www.example.com/short-lived-data';
    
    // 第一次请求并缓存（使用默认TTL）
    const response1 = await session.get(url);
    console.info('Response 1 cached with default TTL (1 hour)');

    // 手动设置更短的TTL（例如5分钟）
    // 注意：这需要在拦截器内部实现自定义TTL逻辑
    // 这里仅演示概念，实际需要在拦截器中添加额外参数传递机制

    console.info('TTL management example completed');

  } catch (error) {
    console.error('Manual TTL example failed:', error);
  } finally {
    session.close();
    cache.clearCache();
  }
}