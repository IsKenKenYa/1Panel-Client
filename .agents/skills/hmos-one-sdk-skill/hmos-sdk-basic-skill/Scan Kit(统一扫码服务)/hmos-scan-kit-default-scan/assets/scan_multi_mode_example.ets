import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ScanMultiModeExample {
  @State scanResultText: string = '等待扫码...';
  @State detectedCodesCount: number = 0;

  build() {
    Column({ space: 10 }) {
      Text('多码识别示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text(this.scanResultText)
        .fontSize(16)
        .margin({ top: 10 })
        .maxLines(10);

      Button('启动多码识别(所有码类型)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startMultiModeScan();
        });

      Button('启动多码识别(仅QR码)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startMultiModeQRScan();
        });

      Button('启动多码识别(QR码和条形码)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startMultiModeMixedScan();
        });
    }
    .width('100%')
    .height('100%');
  }

  startMultiModeScan(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: false
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanError(error);
          return;
        }
        
        hilog.info(0x0001, '[ScanMultiModeExample]', 
          `多码识别成功,选择的码: ${JSON.stringify(result)}`);
        
        this.scanResultText = `多码识别成功!\n用户选择的码:\n类型: ${this.getScanTypeName(result.scanType)}\n内容: ${result.originalValue}`;
        
        if (result.scanCodeRect) {
          const rect = result.scanCodeRect;
          this.scanResultText += `\n位置: (${rect.left}, ${rect.top})`;
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  startMultiModeQRScan(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],
      enableMultiMode: true,
      enableAlbum: false
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanError(error);
          return;
        }
        
        hilog.info(0x0001, '[ScanMultiModeExample]', 
          `QR码多码识别成功: ${result.originalValue}`);
        
        this.scanResultText = `QR码多码识别成功!\n内容: ${result.originalValue}`;
        
        if (result.originalValue.startsWith('http://') || result.originalValue.startsWith('https://')) {
          this.scanResultText += '\n(URL链接)';
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  startMultiModeMixedScan(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE, scanCore.ScanType.ONE_D_CODE],
      enableMultiMode: true,
      enableAlbum: false
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanError(error);
          return;
        }
        
        hilog.info(0x0001, '[ScanMultiModeExample]', 
          `混合码多码识别成功: ${JSON.stringify(result)}`);
        
        this.scanResultText = `混合码多码识别成功!\n类型: ${this.getScanTypeName(result.scanType)}\n内容: ${result.originalValue}`;
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
        errorMsg = '参数错误: 多码识别不支持相册';
        break;
      case 1000500001:
        errorMsg = '扫码服务异常';
        break;
      case 1000500002:
        errorMsg = '用户取消了扫码';
        break;
      default:
        errorMsg = `扫码失败: ${error.message}`;
        break;
    }
    
    this.scanResultText = errorMsg;
    hilog.error(0x0001, '[ScanMultiModeExample]', errorMsg);
  }

  getScanTypeName(scanType: scanCore.ScanType): string {
    switch (scanType) {
      case scanCore.ScanType.QR_CODE:
        return 'QR码';
      case scanCore.ScanType.ONE_D_CODE:
        return '条形码';
      case scanCore.ScanType.TWO_D_CODE:
        return '二维码';
      default:
        return '其他码类型';
    }
  }
}