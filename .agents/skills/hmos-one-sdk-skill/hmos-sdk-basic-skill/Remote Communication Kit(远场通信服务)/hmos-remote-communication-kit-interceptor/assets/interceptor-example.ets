import { rcp } from '@kit.RemoteCommunicationKit';
import { url } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 网络质量提供者（模拟网络状态）
 */
export class NetworkQualityProvider {
  isNetworkFast: boolean = true;

  public constructor(isNetworkFast: boolean) {
    this.isNetworkFast = isNetworkFast;
  }
}

/**
 * 响应缓存类
 */
export class ResponseCache {
  private readonly cache: Record<string, rcp.Response> = {};

  getResponse(url: string): rcp.Response | undefined {
    return this.cache[url];
  }

  setResponse(url: string, response: rcp.Response): void {
    this.cache[url] = response;
  }

  clearCache(): void {
    this.cache = {};
  }
}

/**
 * 请求URL修改拦截器
 * 功能：在网络质量不佳时，修改请求URL以获取更小的资源
 */
export class RequestUrlChangeInterceptor implements rcp.Interceptor {
  private readonly networkQualityProvider: NetworkQualityProvider;

  constructor(networkQualityProvider: NetworkQualityProvider) {
    this.networkQualityProvider = networkQualityProvider;
  }

  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      // 检查是否为GET请求且网络质量不佳
      if (context.request.method === 'GET' && !this.networkQualityProvider.isNetworkFast) {
        console.info('[RequestUrlChangeInterceptor]: Slow network detected');

        // 解析URL并修改路径名
        const parts = context.request.url.pathname.split('.');
        if (parts.length === 2) {
          const changed = url.URL.parseURL(context.request.url.href);
          changed.pathname = parts[0] + '_small.' + parts[1];
          console.info(`[RequestUrlChangeInterceptor]: Replace URL from '${context.request.url.href}' to '${changed}'`);
          
          // 更新请求URL
          context.request.url = changed;
        }
      } else {
        console.info('[RequestUrlChangeInterceptor]: Network is fast, no modification needed');
      }

      // 调用下一个拦截器或发起实际请求
      return next.handle(context);
    } catch (error) {
      console.error('[RequestUrlChangeInterceptor]: Error occurred:', error);
      throw error;
    }
  }
}

/**
 * 响应头修改拦截器
 * 功能：移除不必要的响应头，只保留content-range
 */
export class ResponseHeaderRemoveInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      // 先调用下一个拦截器或发起请求，获取原始响应
      const response = await next.handle(context);

      // 创建新的响应对象，只保留特定的响应头
      const toReturn: rcp.Response = {
        request: response.request,
        statusCode: response.statusCode,
        httpVersion: response.httpVersion,
        headers: {
          'content-range': response.headers['content-range']
        },
        effectiveUrl: response.effectiveUrl,
        timeInfo: response.timeInfo,
        toJSON: () => null
      };

      console.info('[ResponseHeaderRemoveInterceptor]: Response headers modified, only content-range retained');
      return toReturn;
    } catch (error) {
      console.error('[ResponseHeaderRemoveInterceptor]: Error occurred:', error);
      throw error;
    }
  }
}

/**
 * 响应缓存拦截器
 * 功能：缓存HTTP响应，减少重复请求
 */
export class ResponseCachingInterceptor implements rcp.Interceptor {
  private readonly cache: ResponseCache;

  constructor(cache: ResponseCache) {
    this.cache = cache;
  }

  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      const requestUrl = context.request.url.href;

      // 检查缓存中是否已有响应
      const cachedResponse = this.cache.getResponse(requestUrl);
      if (cachedResponse) {
        console.info(`[ResponseCachingInterceptor]: Returning cached response for ${requestUrl}`);
        return Promise.resolve(cachedResponse);
      }

      // 缓存中没有，发起实际请求
      console.info(`[ResponseCachingInterceptor]: No cache found, making request for ${requestUrl}`);
      const promise = next.handle(context);

      // 将响应缓存起来
      promise.then((resp) => {
        this.cache.setResponse(requestUrl, resp);
        console.info(`[ResponseCachingInterceptor]: Response cached for ${requestUrl}`);
      });

      return promise;
    } catch (error) {
      console.error('[ResponseCachingInterceptor]: Error occurred:', error);
      throw error;
    }
  }
}

/**
 * 创建带拦截器的Session
 * @param networkStateSimulator 网络质量模拟器
 * @returns Session对象
 */
export function createSessionWithInterceptors(networkStateSimulator: NetworkQualityProvider): rcp.Session {
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [
      new RequestUrlChangeInterceptor(networkStateSimulator),
      new ResponseHeaderRemoveInterceptor()
    ],
    requestConfiguration: {
      security: {
        tlsOptions: {
          tlsVersion: 'TlsV1.3'
        }
      }
    }
  };

  const session = rcp.createSession(sessionConfig);
  console.info('Session created with interceptors');
  return session;
}

/**
 * 创建带缓存拦截器的Session
 * @param cache 响应缓存对象
 * @returns Session对象
 */
export function createSessionWithCacheInterceptor(cache: ResponseCache): rcp.Session {
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [new ResponseCachingInterceptor(cache)]
  };

  const session = rcp.createSession(sessionConfig);
  console.info('Session created with cache interceptor');
  return session;
}

/**
 * 使用拦截器发起HTTP请求（网络质量优化场景）
 */
export async function httpRequestWithInterceptor(): Promise<void> {
  // 模拟网络质量不佳
  const networkStateSimulator = new NetworkQualityProvider(false);

  // 创建带拦截器的Session
  const session = createSessionWithInterceptors(networkStateSimulator);

  try {
    // 发送GET请求（会被拦截器修改URL）
    const response = await session.get('http://example.com/image.jpg');
    console.info('Request succeeded, status code:', response.statusCode);
    console.info('Response headers:', JSON.stringify(response.headers));

    // 发送POST请求
    const request = new rcp.Request('http://example.com/api', 'POST');
    request.body = 'request body data';
    const postResponse = await session.fetch(request);
    console.info('POST request succeeded, status code:', postResponse.statusCode);

  } catch (error) {
    const businessError = error as BusinessError;
    console.error('Request failed, error code:', businessError.code);
    console.error('Error message:', businessError.message);
  } finally {
    // 关闭Session释放资源
    session.close();
    console.info('Session closed');
  }
}

/**
 * 使用缓存拦截器发起HTTP请求
 */
export async function httpRequestWithCacheInterceptor(): Promise<void> {
  const cache = new ResponseCache();
  const session = createSessionWithCacheInterceptor(cache);

  try {
    // 第一次请求，会被缓存
    console.info('Making first request...');
    const response1 = await session.get('https://www.example.com/data');
    console.info('First request succeeded, status code:', response1.statusCode);

    // 第二次请求，会从缓存返回
    console.info('Making second request (should be cached)...');
    const request = new rcp.Request('https://www.example.com/data', 'GET');
    const response2 = await session.fetch(request);
    console.info('Second request succeeded (from cache), status code:', response2.statusCode);

  } catch (error) {
    const businessError = error as BusinessError;
    console.error('Request failed, error code:', businessError.code);
    console.error('Error message:', businessError.message);
  } finally {
    session.close();
    console.info('Session closed');
    cache.clearCache();
    console.info('Cache cleared');
  }
}

/**
 * 错误处理和降级示例
 */
export async function handleInterceptorError(): Promise<void> {
  const session = rcp.createSession({
    interceptors: [new RequestUrlChangeInterceptor(new NetworkQualityProvider(true))]
  });

  try {
    const response = await session.get('http://example.com/data');

    // 检查响应状态码
    if (response.statusCode >= 200 && response.statusCode < 300) {
      console.info('Request succeeded with status:', response.statusCode);
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      console.warn('Client error, status code:', response.statusCode);
    } else if (response.statusCode >= 500) {
      console.error('Server error, status code:', response.statusCode);
    }

  } catch (error) {
    const businessError = error as BusinessError;

    // 根据错误码处理
    switch (businessError.code) {
      case 401:
        console.error('Parameter error, check interceptor configuration');
        break;
      case 1007900001:
        console.error('Network error, check network connection');
        // 降级方案：使用默认网络配置
        await fallbackWithoutInterceptor();
        break;
      case 1007900994:
        console.error('Session limit reached, close unused sessions');
        break;
      default:
        console.error('Unknown error:', businessError.code, businessError.message);
    }
  } finally {
    session.close();
    console.info('Session closed');
  }
}

/**
 * 降级方案：使用不带拦截器的Session
 */
async function fallbackWithoutInterceptor(): Promise<void> {
  try {
    console.info('Fallback: Creating session without interceptors');
    const fallbackSession = rcp.createSession();

    const response = await fallbackSession.get('http://example.com/fallback');
    console.info('Fallback request succeeded, status code:', response.statusCode);

    fallbackSession.close();
  } catch (error) {
    console.error('Fallback also failed:', error);
  }
}

/**
 * 完整的拦截器使用示例
 * 包含：创建拦截器、配置Session、发送请求、处理响应、错误处理、资源释放
 */
export async function completeInterceptorExample(): Promise<void> {
  console.info('=== Starting Complete Interceptor Example ===');

  // 1. 创建网络质量模拟器
  const networkProvider = new NetworkQualityProvider(false);
  console.info('Network quality set to: slow');

  // 2. 创建缓存对象
  const cache = new ResponseCache();

  // 3. 创建Session并配置拦截器链
  const session = rcp.createSession({
    interceptors: [
      new RequestUrlChangeInterceptor(networkProvider),
      new ResponseCachingInterceptor(cache),
      new ResponseHeaderRemoveInterceptor()
    ]
  });
  console.info('Session created with 3 interceptors');

  try {
    // 4. 发送第一个请求
    console.info('--- Sending first request ---');
    const url1 = 'http://example.com/image.jpg';
    const response1 = await session.get(url1);
    console.info(`Response 1: status=${response1.statusCode}, headers=${JSON.stringify(response1.headers)}`);

    // 5. 发送第二个请求（会被缓存拦截器拦截）
    console.info('--- Sending second request (should hit cache) ---');
    const response2 = await session.get(url1);
    console.info(`Response 2: status=${response2.statusCode} (from cache)`);

    // 6. 发送POST请求
    console.info('--- Sending POST request ---');
    const postRequest = new rcp.Request('http://example.com/api/upload', 'POST');
    postRequest.body = 'upload data';
    const response3 = await session.fetch(postRequest);
    console.info(`Response 3: status=${response3.statusCode}`);

  } catch (error) {
    const businessError = error as BusinessError;
    console.error('=== Error Occurred ===');
    console.error(`Error code: ${businessError.code}`);
    console.error(`Error message: ${businessError.message}`);

    // 降级处理
    if (businessError.code === 1007900001) {
      console.info('Attempting fallback without interceptors...');
      await fallbackWithoutInterceptor();
    }
  } finally {
    // 7. 清理资源
    session.close();
    cache.clearCache();
    console.info('=== Session closed and cache cleared ===');
  }
}