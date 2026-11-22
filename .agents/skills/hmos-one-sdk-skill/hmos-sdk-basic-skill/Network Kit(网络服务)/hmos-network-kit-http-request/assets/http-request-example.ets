import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct HttpRequestExample {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private httpRequest: http.HttpRequest | null = null;

  build() {
    Column({ space: 10 }) {
      Button('发起HTTP GET请求')
        .onClick(() => {
          this.httpGetRequest();
        })
      
      Button('发起HTTP POST请求')
        .onClick(() => {
          this.httpPostRequest();
        })
      
      Button('上传文件')
        .onClick(() => {
          this.uploadFile();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private httpGetRequest(): void {
    this.httpRequest = http.createHttp();
    
    this.httpRequest.on('headersReceive', (header: Object) => {
      hilog.info(0x0000, 'HttpRequestExample', `header: ${JSON.stringify(header)}`);
    });

    this.httpRequest.request('https://example.com/api/data', {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      usingCache: true,
      priority: 1,
      connectTimeout: 60000,
      readTimeout: 60000,
      usingProtocol: http.HttpProtocol.HTTP1_1
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        hilog.info(0x0000, 'HttpRequestExample', `Result: ${JSON.stringify(data.result)}`);
        hilog.info(0x0000, 'HttpRequestExample', `code: ${JSON.stringify(data.responseCode)}`);
        hilog.info(0x0000, 'HttpRequestExample', `header: ${JSON.stringify(data.header)}`);
        hilog.info(0x0000, 'HttpRequestExample', `cookies: ${JSON.stringify(data.cookies)}`);
      } else {
        hilog.error(0x0000, 'HttpRequestExample', `error: ${JSON.stringify(err)}`);
      }
      
      this.httpRequest?.off('headersReceive');
      this.httpRequest?.destroy();
      this.httpRequest = null;
    });
  }

  private httpPostRequest(): void {
    this.httpRequest = http.createHttp();
    
    this.httpRequest.on('headersReceive', (header: Object) => {
      hilog.info(0x0000, 'HttpRequestExample', `header: ${JSON.stringify(header)}`);
    });

    this.httpRequest.request('https://example.com/api/upload', {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify({
        username: 'user123',
        password: 'password123'
      }),
      expectDataType: http.HttpDataType.STRING,
      usingCache: true,
      priority: 1,
      connectTimeout: 60000,
      readTimeout: 60000,
      usingProtocol: http.HttpProtocol.HTTP1_1
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        hilog.info(0x0000, 'HttpRequestExample', `Result: ${JSON.stringify(data.result)}`);
        hilog.info(0x0000, 'HttpRequestExample', `code: ${JSON.stringify(data.responseCode)}`);
      } else {
        hilog.error(0x0000, 'HttpRequestExample', `error: ${JSON.stringify(err)}`);
      }
      
      this.httpRequest?.off('headersReceive');
      this.httpRequest?.destroy();
      this.httpRequest = null;
    });
  }

  private uploadFile(): void {
    this.httpRequest = http.createHttp();
    
    this.httpRequest.on('headersReceive', (header: Object) => {
      hilog.info(0x0000, 'HttpRequestExample', `header: ${JSON.stringify(header)}`);
    });

    this.httpRequest.request('https://example.com/api/upload', {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'multipart/form-data'
      },
      multiFormDataList: [
        {
          name: 'file',
          contentType: 'text/plain',
          filePath: `${this.context.filesDir}/example.txt`,
          remoteFileName: 'example.txt'
        },
        {
          name: 'description',
          contentType: 'text/plain',
          data: 'This is an example file'
        }
      ],
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 60000,
      readTimeout: 60000
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        hilog.info(0x0000, 'HttpRequestExample', `Upload Result: ${JSON.stringify(data.result)}`);
        hilog.info(0x0000, 'HttpRequestExample', `Upload code: ${JSON.stringify(data.responseCode)}`);
      } else {
        hilog.error(0x0000, 'HttpRequestExample', `Upload error: ${JSON.stringify(err)}`);
      }
      
      this.httpRequest?.off('headersReceive');
      this.httpRequest?.destroy();
      this.httpRequest = null;
    });
  }
}