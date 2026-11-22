/**
 * HTTP流式传输示例
 * 展示大文件上传下载和进度监控
 */

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fs } from '@kit.CoreFileKit';

@Entry
@Component
struct HttpStreamRequest {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private readonly DOMAIN: number = 0x0000;
  private readonly TAG: string = 'HttpStreamRequest';
  
  @State downloadProgress: string = '下载进度: 0%';
  @State uploadProgress: string = '上传进度: 0%';
  @State downloadedSize: number = 0;
  @State totalSize: number = 0;

  build() {
    Column({ space: 15 }) {
      Text('HTTP流式传输示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      
      Button('下载大文件(流式)')
        .onClick(() => {
          this.downloadLargeFile();
        })
      
      Text(this.downloadProgress)
        .fontSize(16)
      
      Text(`已下载: ${this.downloadedSize} / ${this.totalSize} bytes`)
        .fontSize(14)
      
      Divider()
      
      Button('上传大文件(流式)')
        .onClick(() => {
          this.uploadLargeFile();
        })
      
      Text(this.uploadProgress)
        .fontSize(16)
      
      Button('取消下载')
        .onClick(() => {
          this.cancelDownload();
        })
    }
    .width('100%')
    .padding(20)
  }

  /**
   * 流式下载大文件示例
   */
  private downloadLargeFile(): void {
    let httpRequest = http.createHttp();
    let receivedData: ArrayBuffer = new ArrayBuffer(0);
    
    // 订阅数据接收事件 - 分块接收数据
    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      // 拼接接收到的数据
      const newData = new ArrayBuffer(receivedData.byteLength + data.byteLength);
      const newView = new Uint8Array(newData);
      newView.set(new Uint8Array(receivedData));
      newView.set(new Uint8Array(data), receivedData.byteLength);
      receivedData = newData;
      
      hilog.info(this.DOMAIN, this.TAG, `已接收数据: ${receivedData.byteLength} bytes`);
    });
    
    // 订阅数据接收完毕事件
    httpRequest.on('dataEnd', () => {
      hilog.info(this.DOMAIN, this.TAG, '数据接收完成');
      
      // 保存文件到本地
      const savePath = `${this.context.filesDir}/downloaded_file.zip`;
      try {
        const file = fs.openSync(savePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
        fs.writeSync(file.fd, receivedData);
        fs.closeSync(file);
        hilog.info(this.DOMAIN, this.TAG, `文件已保存到: ${savePath}`);
      } catch (error) {
        hilog.error(this.DOMAIN, this.TAG, `文件保存失败: ${error}`);
      }
      
      this.destroyStreamRequest(httpRequest);
    });
    
    // 订阅下载进度事件
    httpRequest.on('dataReceiveProgress', (progressInfo: http.DataReceiveProgressInfo) => {
      this.downloadedSize = progressInfo.receiveSize;
      this.totalSize = progressInfo.totalSize;
      
      const percentage = Math.round((progressInfo.receiveSize / progressInfo.totalSize) * 100);
      this.downloadProgress = `下载进度: ${percentage}%`;
      
      hilog.info(this.DOMAIN, this.TAG, 
        `下载进度: ${progressInfo.receiveSize}/${progressInfo.totalSize} bytes (${percentage}%)`);
    });
    
    // 发起流式请求
    httpRequest.requestInStream(
      'https://example.com/large-file.zip',
      {
        method: http.RequestMethod.GET,
        readTimeout: 180000 // 大文件下载建议增大超时时间(180秒)
      }
    )
    .then((responseCode: number) => {
      hilog.info(this.DOMAIN, this.TAG, `流式下载请求成功,响应码: ${responseCode}`);
      
      if (responseCode !== 200) {
        hilog.warn(this.DOMAIN, this.TAG, `服务器响应异常: ${responseCode}`);
      }
    })
    .catch((error: Error) => {
      hilog.error(this.DOMAIN, this.TAG, `流式下载失败: ${error.message}`);
      this.destroyStreamRequest(httpRequest);
    });
  }

  /**
   * 流式上传大文件示例
   */
  private uploadLargeFile(): void {
    let httpRequest = http.createHttp();
    
    // 读取本地文件
    const filePath = `${this.context.filesDir}/upload_file.zip`;
    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(filePath);
      const fileSize = stat.size;
      const fileData = new ArrayBuffer(fileSize);
      fs.readSync(file.fd, fileData);
      fs.closeSync(file);
      
      hilog.info(this.DOMAIN, this.TAG, `准备上传文件: ${filePath}, 大小: ${fileSize} bytes`);
      
      // 订阅上传进度事件
      httpRequest.on('dataSendProgress', (progressInfo: http.DataSendProgressInfo) => {
        const percentage = Math.round((progressInfo.sendSize / progressInfo.totalSize) * 100);
        this.uploadProgress = `上传进度: ${percentage}%`;
        
        hilog.info(this.DOMAIN, this.TAG, 
          `上传进度: ${progressInfo.sendSize}/${progressInfo.totalSize} bytes (${percentage}%)`);
      });
      
      // 发起流式上传请求
      httpRequest.requestInStream(
        'https://example.com/upload',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': fileSize.toString()
          },
          extraData: fileData,
          readTimeout: 180000,
          connectTimeout: 60000
        }
      )
      .then((responseCode: number) => {
        hilog.info(this.DOMAIN, this.TAG, `流式上传成功,响应码: ${responseCode}`);
        
        if (responseCode === 200) {
          hilog.info(this.DOMAIN, this.TAG, '文件上传成功');
        } else {
          hilog.warn(this.DOMAIN, this.TAG, `服务器响应异常: ${responseCode}`);
        }
        
        this.destroyStreamRequest(httpRequest);
      })
      .catch((error: Error) => {
        hilog.error(this.DOMAIN, this.TAG, `流式上传失败: ${error.message}`);
        this.destroyStreamRequest(httpRequest);
      });
      
    } catch (error) {
      hilog.error(this.DOMAIN, this.TAG, `文件读取失败: ${error}`);
    }
  }

  /**
   * 取消下载
   */
  private cancelDownload(): void {
    hilog.warn(this.DOMAIN, this.TAG, '用户取消下载');
    // 需要保存httpRequest对象引用以便调用destroy()
  }

  /**
   * 销毁流式请求并取消订阅
   */
  private destroyStreamRequest(httpRequest: http.HttpRequest): void {
    httpRequest.off('dataReceive');
    httpRequest.off('dataEnd');
    httpRequest.off('dataReceiveProgress');
    httpRequest.off('dataSendProgress');
    httpRequest.destroy();
    
    hilog.info(this.DOMAIN, this.TAG, '流式请求已销毁');
  }
}