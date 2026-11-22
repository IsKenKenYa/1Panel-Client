import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const EXAMPLE_URL = 'https://example.com/api/data';
const EXAMPLE_INITIAL_URL = 'https://example.com/api/initial';
const EXAMPLE_FINAL_URL = 'https://example.com/api/final';

class InitialHttpInterceptor implements http.HttpInterceptor {
  interceptorType: http.InterceptorType = http.InterceptorType.INITIAL_REQUEST;
  result: boolean = true;
  
  constructor(interceptorType: http.InterceptorType, result: boolean) {
    this.interceptorType = interceptorType;
    this.result = result;
  }
  
  interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<http.ChainContinue> {
    hilog.info(0xFF00, 'InitialHttpInterceptor', `INITIAL_REQUEST, Original req: ${JSON.stringify(reqContext)}`);
    hilog.info(0xFF00, 'InitialHttpInterceptor', `INITIAL_REQUEST, Original rsp: ${JSON.stringify(rspContext)}`);
    
    reqContext.url = EXAMPLE_INITIAL_URL;
    reqContext.header = { 'content-type': 'text/plain' };
    reqContext.body = { 'context': 'INITIAL_REQUEST' };
    
    hilog.info(0xFF00, 'InitialHttpInterceptor', `INITIAL_REQUEST, Update req: ${JSON.stringify(reqContext)}`);
    return Promise.resolve(this.result);
  }
}

class NetworkHttpInterceptor implements http.HttpInterceptor {
  interceptorType: http.InterceptorType = http.InterceptorType.NETWORK_CONNECT;
  result: boolean = true;
  
  constructor(interceptorType: http.InterceptorType, result: boolean) {
    this.interceptorType = interceptorType;
    this.result = result;
  }
  
  interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<http.ChainContinue> {
    hilog.info(0xFF00, 'NetworkHttpInterceptor', `NETWORK_CONNECT, Original req: ${JSON.stringify(reqContext)}`);
    hilog.info(0xFF00, 'NetworkHttpInterceptor', `NETWORK_CONNECT, Original rsp: ${JSON.stringify(rspContext)}`);
    
    reqContext.url = EXAMPLE_URL;
    reqContext.header = { 'content-type': 'text/xml' };
    reqContext.body = { 'context': 'NETWORK_CONNECT' };
    
    hilog.info(0xFF00, 'NetworkHttpInterceptor', `NETWORK_CONNECT, Update req: ${JSON.stringify(reqContext)}`);
    return Promise.resolve(this.result);
  }
}

class CacheHttpInterceptor implements http.HttpInterceptor {
  interceptorType: http.InterceptorType = http.InterceptorType.CACHE_CHECKED;
  result: boolean = true;
  
  constructor(interceptorType: http.InterceptorType, result: boolean) {
    this.interceptorType = interceptorType;
    this.result = result;
  }
  
  interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<http.ChainContinue> {
    hilog.info(0xFF00, 'CacheHttpInterceptor', `CACHE_CHECKED, Original req: ${JSON.stringify(reqContext)}`);
    hilog.info(0xFF00, 'CacheHttpInterceptor', `CACHE_CHECKED, Original rsp: ${JSON.stringify(rspContext)}`);
    
    hilog.info(0xFF00, 'CacheHttpInterceptor', `CACHE_CHECKED, Cache found`);
    return Promise.resolve(this.result);
  }
}

class RedirectionHttpInterceptor implements http.HttpInterceptor {
  interceptorType: http.InterceptorType = http.InterceptorType.REDIRECTION;
  result: boolean = true;
  
  constructor(interceptorType: http.InterceptorType, result: boolean) {
    this.interceptorType = interceptorType;
    this.result = result;
  }
  
  interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<http.ChainContinue> {
    hilog.info(0xFF00, 'RedirectionHttpInterceptor', `REDIRECTION, Original req: ${JSON.stringify(reqContext)}`);
    hilog.info(0xFF00, 'RedirectionHttpInterceptor', `REDIRECTION, Original rsp: ${JSON.stringify(rspContext)}`);
    
    hilog.info(0xFF00, 'RedirectionHttpInterceptor', `REDIRECTION, Redirect URL updated`);
    return Promise.resolve(this.result);
  }
}

class FinalHttpInterceptor implements http.HttpInterceptor {
  interceptorType: http.InterceptorType = http.InterceptorType.FINAL_RESPONSE;
  result: boolean = true;
  
  constructor(interceptorType: http.InterceptorType, result: boolean) {
    this.interceptorType = interceptorType;
    this.result = result;
  }
  
  interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<http.ChainContinue> {
    hilog.info(0xFF00, 'FinalHttpInterceptor', `FINAL_RESPONSE, Original req: ${JSON.stringify(reqContext)}`);
    hilog.info(0xFF00, 'FinalHttpInterceptor', `FINAL_RESPONSE, Original rsp: ${JSON.stringify(rspContext)}`);
    
    reqContext.url = EXAMPLE_FINAL_URL;
    reqContext.header = { 'content-type': 'text/html' };
    reqContext.body = { 'context': 'FINAL_RESPONSE' };
    
    rspContext.result = 'FINAL_RESPONSE modified';
    rspContext.responseCode = 200;
    
    hilog.info(0xFF00, 'FinalHttpInterceptor', `FINAL_RESPONSE, Update req: ${JSON.stringify(reqContext)}`);
    hilog.info(0xFF00, 'FinalHttpInterceptor', `FINAL_RESPONSE, Update rsp: ${JSON.stringify(rspContext)}`);
    return Promise.resolve(this.result);
  }
}

@Entry
@Component
struct HttpInterceptorExample {
  build() {
    Column({ space: 10 }) {
      Button('发起带拦截器的HTTP请求')
        .onClick(() => {
          this.httpRequestWithInterceptor();
        })
      
      Button('发起带缓存拦截器的HTTP请求')
        .onClick(() => {
          this.httpRequestWithCacheInterceptor();
        })
      
      Button('发起带重定向拦截器的HTTP请求')
        .onClick(() => {
          this.httpRequestWithRedirectionInterceptor();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private httpRequestWithInterceptor(): void {
    let httpRequest = http.createHttp();
    
    let chain: http.HttpInterceptorChain = new http.HttpInterceptorChain();
    
    chain.addChain([
      new InitialHttpInterceptor(http.InterceptorType.INITIAL_REQUEST, true),
      new NetworkHttpInterceptor(http.InterceptorType.NETWORK_CONNECT, true),
      new FinalHttpInterceptor(http.InterceptorType.FINAL_RESPONSE, true)
    ]);
    
    chain.apply(httpRequest);
    
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: { 'content-type': 'text/html' } as Record<string, string>,
      extraData: { 'context': 'BODY' } as Record<string, string>,
    };
    
    httpRequest.request(EXAMPLE_URL, options, (err: BusinessError, res: http.HttpResponse) => {
      if (err) {
        hilog.error(0xFF00, 'HttpInterceptorExample', `request fail, error code: ${err.code}, msg: ${err.message}`);
      } else {
        hilog.info(0xFF00, 'HttpInterceptorExample', `res:${JSON.stringify(res)}`);
      }
      httpRequest.destroy();
    });
  }

  private httpRequestWithCacheInterceptor(): void {
    let httpRequest = http.createHttp();
    
    let chain: http.HttpInterceptorChain = new http.HttpInterceptorChain();
    
    chain.addChain([
      new InitialHttpInterceptor(http.InterceptorType.INITIAL_REQUEST, true),
      new CacheHttpInterceptor(http.InterceptorType.CACHE_CHECKED, true),
      new FinalHttpInterceptor(http.InterceptorType.FINAL_RESPONSE, true)
    ]);
    
    chain.apply(httpRequest);
    
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      usingCache: true,
      expectDataType: http.HttpDataType.STRING
    };
    
    httpRequest.request(EXAMPLE_URL, options, (err: BusinessError, res: http.HttpResponse) => {
      if (err) {
        hilog.error(0xFF00, 'HttpInterceptorExample', `request fail, error code: ${err.code}, msg: ${err.message}`);
      } else {
        hilog.info(0xFF00, 'HttpInterceptorExample', `res:${JSON.stringify(res)}`);
      }
      httpRequest.destroy();
    });
  }

  private httpRequestWithRedirectionInterceptor(): void {
    let httpRequest = http.createHttp();
    
    let chain: http.HttpInterceptorChain = new http.HttpInterceptorChain();
    
    chain.addChain([
      new InitialHttpInterceptor(http.InterceptorType.INITIAL_REQUEST, true),
      new NetworkHttpInterceptor(http.InterceptorType.NETWORK_CONNECT, true),
      new RedirectionHttpInterceptor(http.InterceptorType.REDIRECTION, true),
      new FinalHttpInterceptor(http.InterceptorType.FINAL_RESPONSE, true)
    ]);
    
    chain.apply(httpRequest);
    
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING
    };
    
    httpRequest.request(EXAMPLE_URL, options, (err: BusinessError, res: http.HttpResponse) => {
      if (err) {
        hilog.error(0xFF00, 'HttpInterceptorExample', `request fail, error code: ${err.code}, msg: ${err.message}`);
      } else {
        hilog.info(0xFF00, 'HttpInterceptorExample', `res:${JSON.stringify(res)}`);
      }
      httpRequest.destroy();
    });
  }
}