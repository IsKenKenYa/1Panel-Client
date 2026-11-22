import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class ResponseCache {
  private readonly cache: Map<string, rcp.Response> = new Map();
  private readonly maxAge: number = 60000;
  private readonly timestamps: Map<string, number> = new Map();
  
  getResponse(url: string): rcp.Response | undefined {
    const timestamp = this.timestamps.get(url);
    if (timestamp && Date.now() - timestamp < this.maxAge) {
      return this.cache.get(url);
    }
    
    this.cache.delete(url);
    this.timestamps.delete(url);
    return undefined;
  }
  
  setResponse(url: string, response: rcp.Response): void {
    this.cache.set(url, response);
    this.timestamps.set(url, Date.now());
    console.info(`Cached response for: ${url}`);
  }
  
  clearCache(): void {
    this.cache.clear();
    this.timestamps.clear();
    console.info('Cache cleared');
  }
}

class ResponseCachingInterceptor implements rcp.Interceptor {
  private readonly cache: ResponseCache;
  
  constructor(cache: ResponseCache) {
    this.cache = cache;
  }
  
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const url = context.request.url.href;
    
    const cachedResponse = this.cache.getResponse(url);
    if (cachedResponse) {
      console.info(`Using cached response for: ${url}`);
      return Promise.resolve(cachedResponse);
    }
    
    console.info(`Fetching fresh response for: ${url}`);
    const promise = next.handle(context);
    
    promise.then((resp: rcp.Response) => {
      if (resp.statusCode === 200) {
        this.cache.setResponse(url, resp);
      }
    }).catch((error: Error) => {
      console.error(`Request failed: ${error.message}`);
    });
    
    return promise;
  }
}

class LoggingInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const startTime = Date.now();
    const url = context.request.url.href;
    const method = context.request.method;
    
    console.info(`[${new Date().toISOString()}] Request started: ${method} ${url}`);
    
    try {
      const response = await next.handle(context);
      const duration = Date.now() - startTime;
      
      console.info(`[${new Date().toISOString()}] Request completed: ${response.statusCode} (${duration}ms)`);
      
      return response;
    } catch (error) {
      const duration = Date.now() - startTime;
      console.error(`[${new Date().toISOString()}] Request failed (${duration}ms): ${error}`);
      throw error;
    }
  }
}

class AuthenticationInterceptor implements rcp.Interceptor {
  private readonly token: string;
  
  constructor(token: string) {
    this.token = token;
  }
  
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    if (!context.request.headers) {
      context.request.headers = {};
    }
    
    context.request.headers['Authorization'] = `Bearer ${this.token}`;
    console.info('Added authentication header');
    
    return next.handle(context);
  }
}

class HttpInterceptorExample {
  private cache: ResponseCache;
  
  constructor() {
    this.cache = new ResponseCache();
  }
  
  async fetchWithCache(url: string): Promise<void> {
    const session = rcp.createSession({
      interceptors: [
        new LoggingInterceptor(),
        new ResponseCachingInterceptor(this.cache)
      ]
    });
    
    try {
      console.info('First request (will fetch from server)');
      const response1 = await session.get(url);
      console.info(`Response 1: ${response1.statusCode}`);
      
      console.info('Second request (will use cache)');
      const response2 = await session.get(url);
      console.info(`Response 2: ${response2.statusCode}`);
      
      console.info('Third request after cache expiry (will fetch from server)');
      await new Promise(resolve => setTimeout(resolve, 65000));
      const response3 = await session.get(url);
      console.info(`Response 3: ${response3.statusCode}`);
      
    } catch (error) {
      console.error(`Request failed: ${error}`);
    } finally {
      session.close();
    }
  }
  
  async fetchWithAuth(url: string, token: string): Promise<void> {
    const session = rcp.createSession({
      interceptors: [
        new LoggingInterceptor(),
        new AuthenticationInterceptor(token)
      ]
    });
    
    try {
      const response = await session.get(url);
      console.info(`Authenticated request: ${response.statusCode}`);
      
      if (response.statusCode === 401) {
        console.error('Authentication failed: Invalid token');
      } else if (response.statusCode === 200) {
        console.info('Authentication successful');
      }
      
    } catch (error) {
      console.error(`Authenticated request failed: ${error}`);
    } finally {
      session.close();
    }
  }
  
  async fetchWithMultipleInterceptors(url: string, token: string): Promise<void> {
    const session = rcp.createSession({
      interceptors: [
        new LoggingInterceptor(),
        new AuthenticationInterceptor(token),
        new ResponseCachingInterceptor(this.cache)
      ]
    });
    
    try {
      console.info('Request with multiple interceptors');
      const response = await session.get(url);
      console.info(`Multi-interceptor response: ${response.statusCode}`);
      
    } catch (error) {
      console.error(`Multi-interceptor request failed: ${error}`);
    } finally {
      session.close();
      this.cache.clearCache();
    }
  }
}

export async function main(): Promise<void> {
  const example = new HttpInterceptorExample();
  
  const apiUrl = 'https://www.example.com/api/data';
  
  await example.fetchWithCache(apiUrl);
  
  const authToken = 'your-access-token-here';
  await example.fetchWithAuth('https://www.example.com/api/protected', authToken);
  
  await example.fetchWithMultipleInterceptors(apiUrl, authToken);
}