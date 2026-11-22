import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ScanAlbumExample {
  @State scanResultText: string = '等待扫码...';

  build() {
    Column({ space: 10 }) {
      Text('相册扫码示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text(this.scanResultText)
        .fontSize(16)
        .margin({ top: 10 })
        .maxLines(5);

      Button('启动扫码(开启相册)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanWithAlbum();
        });

      Button('启动扫码(仅相册)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanAlbumOnly();
        });

      Button('启动扫码(关闭相册)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanNoAlbum();
        });
    }
    .width('100%')
    .height('100%');
  }

  startScanWithAlbum(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanError(error);
          return;
        }
        
        hilog.info(0x0001, '[ScanAlbumExample]', 
          `扫码成功: ${JSON.stringify(result)}`);
        
        this.scanResultText = `扫码成功!\n码类型: ${this.getScanTypeName(result.scanType)}\n码内容: ${result.originalValue}`;
        
        if (result.source !== undefined) {
          const sourceName = result.source === scanCore.ScanSource.CAMERA ? '相机' : '相册';
          this.scanResultText += `\n扫码来源: ${sourceName}`;
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  startScanAlbumOnly(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanError(error);
          return;
        }
        
        if (result.source === scanCore.ScanSource.PHOTO) {
          hilog.info(0x0001, '[ScanAlbumExample]', 
            `相册扫码成功: ${result.originalValue}`);
          
          this.scanResultText = `相册扫码成功!\n码内容: ${result.originalValue}`;
        } else {
          hilog.info(0x0001, '[ScanAlbumExample]', 
            `相机扫码成功: ${result.originalValue}`);
          
          this.scanResultText = `相机扫码成功!\n码内容: ${result.originalValue}`;
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  startScanNoAlbum(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: false,
      enableAlbum: false
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanError(error);
          return;
        }
        
        hilog.info(0x0001, '[ScanAlbumExample]', 
          `扫码成功(仅相机): ${JSON.stringify(result)}`);
        
        this.scanResultText = `扫码成功(仅相机)!\n码内容: ${result.originalValue}`;
        
        if (result.source !== undefined && result.source !== scanCore.ScanSource.CAMERA) {
          hilog.warn(0x0001, '[ScanAlbumExample]', '异常: 相册已关闭但来源不是相机');
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  handleScanError(error: BusinessError): void {
    let errorMsg = '';
    
    switch (error.code) {
      case 401:
        errorMsg = '参数错误: 相册扫码不支持多码识别';
        break;
      case 1000500001:
        errorMsg = '扫码服务异常';
        break;
      case 1000500002:
        errorMsg = '用户取消了扫码或未选择照片';
        break;
      default:
        errorMsg = `扫码失败: ${error.message}`;
        break;
    }
    
    this.scanResultText = errorMsg;
    hilog.error(0x0001, '[ScanAlbumExample]', errorMsg);
  }

  getScanTypeName(scanType: scanCore.ScanType): string {
    switch (scanType) {
      case scanCore.ScanType.QR_CODE:
        return 'QR码';
      case scanCore.ScanType.ONE_D_CODE:
        return '条形码';
      default:
        return '其他码类型';
    }
  }
}