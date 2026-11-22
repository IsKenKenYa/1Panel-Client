/**
 * 请求URL修改拦截器完整示例
 * 功能：根据网络质量自适应修改请求URL，请求低分辨率资源
 * 适用场景：网络质量不佳时提升用户体验
 */

import { rcp } from '@kit.RemoteCommunicationKit';
import { url } from '@kit.ArkTS';

/**
 * 网络质量提供者
 * 模拟网络质量状态（实际应用中应根据真实网络检测结果）
 */
export class NetworkQualityProvider {
  isNetworkFast: boolean = true;
  
  constructor(isNetworkFast: boolean) {
    this.isNetworkFast = isNetworkFast;
  }
  
  /**
   * 更新网络质量状态
   * @param isFast 网络是否快速
   */
  updateNetworkQuality(isFast: boolean): void {
    this.isNetworkFast = isFast;
    console.info(`[NetworkQualityProvider]: Network quality updated to ${isFast ? 'fast' : 'slow'}`);
  }
}

/**
 * 请求URL修改拦截器
 * 网络质量不佳时自动请求低分辨率资源
 */
export class RequestUrlChangeInterceptor implements rcp.Interceptor {
  private readonly networkQualityProvider: NetworkQualityProvider;
  
  constructor(networkQualityProvider: NetworkQualityProvider) {
    this.networkQualityProvider = networkQualityProvider;
  }
  
  /**
   * 拦截请求并修改URL
   * @param context 请求上下文
   * @param next 下一个请求处理器
   * @returns Promise<Response> 响应对象
   */
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      // 仅处理GET请求且网络质量不佳的情况
      if (context.request.method === 'GET' && !this.networkQualityProvider.isNetworkFast) {
        console.info('[RequestUrlChangeInterceptor]: Slow network detected, attempting URL modification');
        
        // 解析URL路径
        const pathname = context.request.url.pathname;
        const parts = pathname.split('.');
        
        // 如果路径包含文件扩展名（如image.jpg），修改为低分辨率版本（image_small.jpg）
        if (parts.length === 2) {
          const changedUrl = url.URL.parseURL(context.request.url.href);
          changedUrl.pathname = parts[0] + '_small.' + parts[1];
          
          const originalUrl = context.request.url.href;
          const modifiedUrl = changedUrl.href;
          
          console.info(`[RequestUrlChangeInterceptor]: URL changed`);
          console.info(`  Original: ${originalUrl}`);
          console.info(`  Modified: ${modifiedUrl}`);
          
          // 更新请求URL
          context.request.url = changedUrl;
          
          // 记录修改信息（可用于界面显示）
          AppStorage.setOrCreate('InterceptorLog', 
            `[RequestUrlChangeInterceptor]: URL modified from '${originalUrl}' to '${modifiedUrl}'`);
        } else {
          console.info('[RequestUrlChangeInterceptor]: URL format not suitable for modification');
        }
      } else {
        console.info('[RequestUrlChangeInterceptor]: Network is fast or non-GET request, no modification');
      }
      
      // 继续拦截器链执行
      return next.handle(context);
      
    } catch (error) {
      console.error('[RequestUrlChangeInterceptor]: Error occurred during interception:', error);
      
      // 降级处理：保持原始URL继续执行
      console.warn('[RequestUrlChangeInterceptor]: Fallback: continuing with original URL');
      return next.handle(context);
    }
  }
}

/**
 * 完整使用示例
 */
export async function requestUrlChangeInterceptorExample() {
  // 创建网络质量提供者（模拟慢速网络）
  const networkQualityProvider = new NetworkQualityProvider(false);
  
  // 配置Session
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [
      new RequestUrlChangeInterceptor(networkQualityProvider)
    ],
    requestConfiguration: {
      transfer: {
        timeout: {
          connectMs: 5000,
          transferMs: 10000
        }
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
  
  try {
    // 发送图片请求（拦截器会自动修改为低分辨率版本）
    const imageUrl = 'https://example.com/images/photo.jpg';
    console.info(`[Example]: Sending request to ${imageUrl}`);
    
    const response = await session.get(imageUrl);
    
    console.info('[Example]: Request completed');
    console.info(`  Status code: ${response.statusCode}`);
    console.info(`  Effective URL: ${response.effectiveUrl}`);
    console.info(`  Response headers: ${JSON.stringify(response.headers)}`);
    
    // 检查拦截器日志
    const interceptorLog = AppStorage.get('InterceptorLog') as string;
    if (interceptorLog) {
      console.info(`[Example]: Interceptor log: ${interceptorLog}`);
    }
    
    // 模拟网络质量改善
    console.info('[Example]: Simulating network quality improvement');
    networkQualityProvider.updateNetworkQuality(true);
    
    // 再次发送请求（此时拦截器不会修改URL）
    const response2 = await session.get(imageUrl);
    console.info('[Example]: Second request completed (no URL modification)');
    console.info(`  Effective URL: ${response2.effectiveUrl}`);
    
    return { response1: response, response2: response2 };
    
  } catch (error) {
    console.error('[Example]: Request failed:', error);
    throw error;
    
  } finally {
    // 关闭Session释放资源
    session.close();
    console.info('[Example]: Session closed');
  }
}

/**
 * 测试用例验证函数
 */
export async function testRequestUrlChangeInterceptor() {
  console.info('[Test]: Starting RequestUrlChangeInterceptor test');
  
  try {
    const result = await requestUrlChangeInterceptorExample();
    
    // 验证第一次请求URL被修改
    const effectiveUrl1 = result.response1.effectiveUrl;
    if (effectiveUrl1 && effectiveUrl1.includes('_small')) {
      console.info('[Test]: ✓ URL modification verified');
    } else {
      console.warn('[Test]: ✗ URL modification not detected');
    }
    
    // 验证第二次请求URL未被修改
    const effectiveUrl2 = result.response2.effectiveUrl;
    if (effectiveUrl2 && !effectiveUrl2.includes('_small')) {
      console.info('[Test]: ✓ Original URL preserved when network is fast');
    } else {
      console.warn('[Test]: ✗ URL modification unexpected when network is fast');
    }
    
    console.info('[Test]: Test completed successfully');
    
  } catch (error) {
    console.error('[Test]: Test failed:', error);
    throw error;
  }
}