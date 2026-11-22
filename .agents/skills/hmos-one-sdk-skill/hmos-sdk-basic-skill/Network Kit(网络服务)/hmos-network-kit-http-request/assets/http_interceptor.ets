/**
 * HTTP拦截器示例
 * 展示如何在HTTP请求-响应生命周期中插入自定义逻辑
 */

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct HttpInterceptor {
  private readonly DOMAIN: number = 0x0000;
  private readonly TAG: string = 'HttpInterceptor';
  private readonly EXAMPLE_URL: string = 'https://example.com/api/data';
  private readonly EXAMPLE_INITIAL_URL: string = 'https://example.com/api/initial';
  private readonly EXAMPLE_FINAL_URL: string = 'https://example.com/api/final';

  build() {
    Column({ space: 15 }) {
      Text('HTTP拦截器示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      
      Button('使用拦截器发起请求')
        .onClick(() => {
          this.requestWithInterceptor();
        })
      
      Button('使用多个拦截器')
        .onClick(() => {
          this.requestWithMultipleInterceptors();
        })
      
      Button('拦截器缓存检查')
        .onClick(() => {
          this.requestWithCacheInterceptor();
        })
      
      Button('拦截器重定向处理')
        .onClick(() => {
          this.requestWithRedirectInterceptor();
        })
    }
    .width('100%')
    .padding(20)
  }

  /**
   * 使用拦截器发起请求示例
   */
  private requestWithInterceptor(): void {
    let httpRequest = http.createHttp();
    
    // 创建拦截器链
    let chain = new http.HttpInterceptorChain();
    
    // 定义初始请求拦截器
    class InitialInterceptor implements http.HttpInterceptor {
      interceptorType: http.InterceptorType = http.InterceptorType.INITIAL_REQUEST;
      
      interceptorHandle(
        reqContext: http.HttpRequestContext, 
        rspContext: http.HttpResponse
      ): Promise<boolean> {
        hilog.info(0x0000, 'Interceptor', 'INITIAL_REQUEST拦截器触发');
        
        // 修改请求URL
        reqContext.url = 'https://example.com/api/modified';
        
        // 添加自定义Header
        reqContext.header = {
          ...reqContext.header,
          'X-Custom-Header': 'Interceptor-Added',
          'X-Request-Time': new Date().toISOString()
        };
        
        // 修改请求体
        reqContext.body = {
          ...reqContext.body,
          interceptorMark: 'INITIAL_REQUEST'
        };
        
        hilog.info(0x0000, 'Interceptor', `修改后的请求: ${JSON.stringify(reqContext)}`);
        
        // 返回true继续请求流程
        return Promise.resolve(true);
      }
    }
    
    // 将拦截器加入拦截器链
    chain.addChain([new InitialInterceptor()]);
    
    // 将拦截器链附加到HttpRequest对象
    chain.apply(httpRequest);
    
    // 发起请求
    httpRequest.request(
      this.EXAMPLE_URL,
      {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ original: 'data' })
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, `拦截器请求成功`);
          hilog.info(this.DOMAIN, this.TAG, `响应码: ${data.responseCode}`);
          hilog.info(this.DOMAIN, this.TAG, `响应内容: ${data.result}`);
        } else {
          hilog.error(this.DOMAIN, this.TAG, `请求失败: ${err.message}`);
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 使用多个拦截器示例
   */
  private requestWithMultipleInterceptors(): void {
    let httpRequest = http.createHttp();
    let chain = new http.HttpInterceptorChain();
    
    // 定义初始请求拦截器
    class InitialInterceptor implements http.HttpInterceptor {
      interceptorType = http.InterceptorType.INITIAL_REQUEST;
      
      interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<boolean> {
        hilog.info(0x0000, 'MultiInterceptor', 'INITIAL_REQUEST拦截器');
        
        reqContext.header = {
          ...reqContext.header,
          'X-Interceptor-1': 'Initial'
        };
        
        return Promise.resolve(true);
      }
    }
    
    // 定义网络连接拦截器
    class NetworkInterceptor implements http.HttpInterceptor {
      interceptorType = http.InterceptorType.NETWORK_CONNECT;
      
      interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<boolean> {
        hilog.info(0x0000, 'MultiInterceptor', 'NETWORK_CONNECT拦截器');
        
        // 记录网络连接开始时间
        const startTime = Date.now();
        hilog.info(0x0000, 'MultiInterceptor', `网络连接开始时间: ${startTime}`);
        
        reqContext.header = {
          ...reqContext.header,
          'X-Interceptor-2': 'Network',
          'X-Connect-Time': startTime.toString()
        };
        
        return Promise.resolve(true);
      }
    }
    
    // 定义最终响应拦截器
    class FinalInterceptor implements http.HttpInterceptor {
      interceptorType = http.InterceptorType.FINAL_RESPONSE;
      
      interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<boolean> {
        hilog.info(0x0000, 'MultiInterceptor', 'FINAL_RESPONSE拦截器');
        
        // 处理响应数据
        hilog.info(0x0000, 'MultiInterceptor', `最终响应: ${JSON.stringify(rspContext)}`);
        
        // 记录响应时间
        const endTime = Date.now();
        hilog.info(0x0000, 'MultiInterceptor', `请求结束时间: ${endTime}`);
        
        // 可以修改响应内容(仅当返回false时有效)
        // rspContext.result = 'Modified by interceptor';
        
        return Promise.resolve(true);
      }
    }
    
    // 将多个拦截器加入拦截器链
    chain.addChain([
      new InitialInterceptor(),
      new NetworkInterceptor(),
      new FinalInterceptor()
    ]);
    
    chain.apply(httpRequest);
    
    httpRequest.request(
      this.EXAMPLE_URL,
      {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, '多拦截器请求成功');
        } else {
          hilog.error(this.DOMAIN, this.TAG, `请求失败: ${err.message}`);
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 使用缓存拦截器示例
   */
  private requestWithCacheInterceptor(): void {
    let httpRequest = http.createHttp();
    let chain = new http.HttpInterceptorChain();
    
    // 定义缓存检查拦截器
    class CacheInterceptor implements http.HttpInterceptor {
      interceptorType = http.InterceptorType.CACHE_CHECKED;
      private cachedData: string = '';
      
      interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<boolean> {
        hilog.info(0x0000, 'CacheInterceptor', 'CACHE_CHECKED拦截器触发');
        
        // 检查是否有缓存数据
        if (this.cachedData) {
          hilog.info(0x0000, 'CacheInterceptor', '命中缓存,直接返回缓存数据');
          
          // 返回false表示使用缓存数据,跳过网络请求
          rspContext.result = this.cachedData;
          rspContext.responseCode = 200;
          rspContext.header = { 'X-Cache': 'HIT' };
          
          return Promise.resolve(false);
        }
        
        hilog.info(0x0000, 'CacheInterceptor', '未命中缓存,继续网络请求');
        
        // 返回true继续网络请求
        return Promise.resolve(true);
      }
      
      // 更新缓存
      updateCache(data: string): void {
        this.cachedData = data;
        hilog.info(0x0000, 'CacheInterceptor', '缓存已更新');
      }
    }
    
    const cacheInterceptor = new CacheInterceptor();
    chain.addChain([cacheInterceptor]);
    chain.apply(httpRequest);
    
    httpRequest.request(
      this.EXAMPLE_URL,
      {
        method: http.RequestMethod.GET,
        usingCache: true,
        expectDataType: http.HttpDataType.STRING
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, `缓存拦截器请求成功`);
          
          // 更新缓存(如果是从网络获取的数据)
          if (data.header && !data.header['X-Cache']) {
            cacheInterceptor.updateCache(data.result as string);
          }
        } else {
          hilog.error(this.DOMAIN, this.TAG, `请求失败: ${err.message}`);
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 使用重定向拦截器示例
   */
  private requestWithRedirectInterceptor(): void {
    let httpRequest = http.createHttp();
    let chain = new http.HttpInterceptorChain();
    
    // 定义重定向拦截器
    class RedirectInterceptor implements http.HttpInterceptor {
      interceptorType = http.InterceptorType.REDIRECTION;
      redirectCount: number = 0;
      
      interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<boolean> {
        hilog.info(0x0000, 'RedirectInterceptor', 'REDIRECTION拦截器触发');
        
        this.redirectCount++;
        hilog.info(0x0000, 'RedirectInterceptor', `重定向次数: ${this.redirectCount}`);
        
        // 检查重定向次数是否超过限制
        if (this.redirectCount > 3) {
          hilog.warn(0x0000, 'RedirectInterceptor', '重定向次数过多,终止请求');
          
          // 返回false终止重定向
          rspContext.responseCode = 310;
          rspContext.result = 'Too many redirects';
          
          return Promise.resolve(false);
        }
        
        // 修改重定向URL
        const newUrl = this.handleRedirect(reqContext.url, rspContext);
        if (newUrl) {
          reqContext.url = newUrl;
          hilog.info(0x0000, 'RedirectInterceptor', `重定向到新URL: ${newUrl}`);
        }
        
        // 返回true继续重定向流程
        return Promise.resolve(true);
      }
      
      private handleRedirect(originalUrl: string, response: http.HttpResponse): string | null {
        // 根据响应头中的Location字段处理重定向
        if (response.header && response.header['Location']) {
          return response.header['Location'];
        }
        return null;
      }
    }
    
    chain.addChain([new RedirectInterceptor()]);
    chain.apply(httpRequest);
    
    httpRequest.request(
      this.EXAMPLE_URL,
      {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, `重定向拦截器请求成功,最终响应码: ${data.responseCode}`);
        } else {
          hilog.error(this.DOMAIN, this.TAG, `请求失败: ${err.message}`);
          if (err.code === 2300047) {
            hilog.warn(this.DOMAIN, this.TAG, '重定向次数达到最大值');
          }
        }
        httpRequest.destroy();
      }
    );
  }
}