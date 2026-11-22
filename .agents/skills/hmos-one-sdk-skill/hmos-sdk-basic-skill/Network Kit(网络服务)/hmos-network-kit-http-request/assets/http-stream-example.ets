import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct HttpStreamExample {
  private httpRequest: http.HttpRequest | null = null;
  private receivedData: ArrayBuffer = new ArrayBuffer(0);

  build() {
    Column({ space: 10 }) {
      Button('下载文件（流式传输）')
        .onClick(() => {
          this.downloadFile();
        })
      
      Button('上传文件（流式传输）')
        .onClick(() => {
          this.uploadFileWithProgress();
        })
      
      Text(`已接收数据大小: ${this.receivedData.byteLength} bytes`)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private downloadFile(): void {
    this.httpRequest = http.createHttp();
    this.receivedData = new ArrayBuffer(0);

    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      const newRes = new ArrayBuffer(this.receivedData.byteLength + data.byteLength);
      const resView = new Uint8Array(newRes);
      resView.set(new Uint8Array(this.receivedData));
      resView.set(new Uint8Array(data), this.receivedData.byteLength);
      this.receivedData = newRes;
      hilog.info(0x0000, 'HttpStreamExample', `Received data length: ${this.receivedData.byteLength}`);
    });

    this.httpRequest.on('dataEnd', () => {
      hilog.info(0x0000, 'HttpStreamExample', 'Download completed');
      this.destroyRequest();
    });

    this.httpRequest.on('dataReceiveProgress', (data: http.DataReceiveProgressInfo) => {
      hilog.info(0x0000, 'HttpStreamExample', `Download progress: ${data.receiveSize}/${data.totalSize} bytes`);
    });

    const streamInfo: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      priority: 1,
      connectTimeout: 60000,
      readTimeout: 60000,
      usingProtocol: http.HttpProtocol.HTTP1_1
    };

    this.httpRequest.requestInStream('https://example.com/files/large-file.zip', streamInfo)
      .then((data: number) => {
        hilog.info(0x0000, 'HttpStreamExample', `requestInStream OK! ResponseCode: ${JSON.stringify(data)}`);
      })
      .catch((err: Error) => {
        hilog.error(0x0000, 'HttpStreamExample', `requestInStream ERROR: ${JSON.stringify(err)}`);
        this.destroyRequest();
      });
  }

  private uploadFileWithProgress(): void {
    this.httpRequest = http.createHttp();

    this.httpRequest.on('dataSendProgress', (data: http.DataSendProgressInfo) => {
      hilog.info(0x0000, 'HttpStreamExample', `Upload progress: ${data.sendSize}/${data.totalSize} bytes`);
    });

    this.httpRequest.on('dataEnd', () => {
      hilog.info(0x0000, 'HttpStreamExample', 'Upload completed');
      this.destroyRequest();
    });

    const streamInfo: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: 'large data to upload...',
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      priority: 1,
      connectTimeout: 60000,
      readTimeout: 60000,
      usingProtocol: http.HttpProtocol.HTTP1_1
    };

    this.httpRequest.requestInStream('https://example.com/api/upload-large', streamInfo)
      .then((data: number) => {
        hilog.info(0x0000, 'HttpStreamExample', `Upload requestInStream OK! ResponseCode: ${JSON.stringify(data)}`);
      })
      .catch((err: Error) => {
        hilog.error(0x0000, 'HttpStreamExample', `Upload requestInStream ERROR: ${JSON.stringify(err)}`);
        this.destroyRequest();
      });
  }

  private destroyRequest(): void {
    if (this.httpRequest) {
      this.httpRequest.off('dataReceive');
      this.httpRequest.off('dataSendProgress');
      this.httpRequest.off('dataReceiveProgress');
      this.httpRequest.off('dataEnd');
      this.httpRequest.destroy();
      this.httpRequest = null;
    }
  }
}