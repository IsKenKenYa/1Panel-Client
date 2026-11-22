/**
 * 基础HTTP请求示例
 * 展示GET和POST请求的标准用法
 */

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct HttpBasicRequest {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private readonly DOMAIN: number = 0x0000;
  private readonly TAG: string = 'HttpBasicRequest';

  build() {
    Column({ space: 10 }) {
      Button('发起GET请求')
        .onClick(() => {
          this.executeGetRequest();
        })
      
      Button('发起POST请求')
        .onClick(() => {
          this.executePostRequest();
        })
      
      Button('发起带Header的请求')
        .onClick(() => {
          this.executeRequestWithHeaders();
        })
      
      Button('发起带超时配置的请求')
        .onClick(() => {
          this.executeRequestWithTimeout();
        })
    }
    .width('100%')
    .padding(20)
  }

  /**
   * 发起GET请求示例
   */
  private executeGetRequest(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(
      'https://example.com/api/data',
      {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        usingCache: true,
        priority: 1,
        connectTimeout: 60000,
        readTimeout: 60000
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, `GET请求成功`);
          hilog.info(this.DOMAIN, this.TAG, `响应码: ${data.responseCode}`);
          hilog.info(this.DOMAIN, this.TAG, `响应内容: ${JSON.stringify(data.result)}`);
          hilog.info(this.DOMAIN, this.TAG, `响应头: ${JSON.stringify(data.header)}`);
        } else {
          hilog.error(this.DOMAIN, this.TAG, `GET请求失败: ${err.message}`);
          this.handleError(err);
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 发起POST请求示例
   */
  private executePostRequest(): void {
    let httpRequest = http.createHttp();
    
    const requestBody = {
      username: 'testuser',
      password: 'testpass123'
    };
    
    httpRequest.request(
      'https://example.com/api/login',
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: JSON.stringify(requestBody),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 60000,
        readTimeout: 60000
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, `POST请求成功`);
          hilog.info(this.DOMAIN, this.TAG, `响应码: ${data.responseCode}`);
          hilog.info(this.DOMAIN, this.TAG, `响应内容: ${data.result}`);
          
          if (data.responseCode === 200) {
            hilog.info(this.DOMAIN, this.TAG, '登录成功');
          } else if (data.responseCode === 401) {
            hilog.warn(this.DOMAIN, this.TAG, '认证失败');
          }
        } else {
          hilog.error(this.DOMAIN, this.TAG, `POST请求失败: ${err.message}`);
          this.handleError(err);
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 发起带自定义Header的请求示例
   */
  private executeRequestWithHeaders(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(
      'https://example.com/api/user/profile',
      {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': 'Bearer your_access_token_here',
          'User-Agent': 'HarmonyOS-App/1.0',
          'Accept-Language': 'zh-CN',
          'Custom-Header': 'custom-value'
        },
        expectDataType: http.HttpDataType.STRING
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, `带Header请求成功`);
          hilog.info(this.DOMAIN, this.TAG, `响应内容: ${JSON.stringify(data.result)}`);
        } else {
          hilog.error(this.DOMAIN, this.TAG, `请求失败: ${err.message}`);
          if (err.code === 401 || err.code === 2300094) {
            hilog.warn(this.DOMAIN, this.TAG, '认证失败,请检查Authorization头');
          }
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 发起带超时配置的请求示例
   */
  private executeRequestWithTimeout(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(
      'https://example.com/api/slow-response',
      {
        method: http.RequestMethod.GET,
        connectTimeout: 30000, // 连接超时30秒
        readTimeout: 90000, // 读取超时90秒
        expectDataType: http.HttpDataType.STRING
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, `请求成功(自定义超时配置)`);
          hilog.info(this.DOMAIN, this.TAG, `响应: ${JSON.stringify(data.result)}`);
        } else {
          if (err.code === 2300028) {
            hilog.error(this.DOMAIN, this.TAG, `请求超时: ${err.message}`);
            hilog.warn(this.DOMAIN, this.TAG, '建议增大超时时间或检查服务器响应速度');
          } else {
            hilog.error(this.DOMAIN, this.TAG, `请求失败: ${err.message}`);
          }
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 错误处理函数
   */
  private handleError(err: BusinessError): void {
    switch (err.code) {
      case 201:
        hilog.error(this.DOMAIN, this.TAG, '权限被拒绝,请声明INTERNET权限');
        break;
      case 401:
        hilog.error(this.DOMAIN, this.TAG, '参数错误,请检查URL格式');
        break;
      case 2300003:
        hilog.error(this.DOMAIN, this.TAG, 'URL格式无效');
        break;
      case 2300007:
        hilog.error(this.DOMAIN, this.TAG, '无法连接服务器');
        break;
      case 2300028:
        hilog.error(this.DOMAIN, this.TAG, '操作超时');
        break;
      default:
        hilog.error(this.DOMAIN, this.TAG, `未知错误: ${err.code} - ${err.message}`);
    }
  }
}