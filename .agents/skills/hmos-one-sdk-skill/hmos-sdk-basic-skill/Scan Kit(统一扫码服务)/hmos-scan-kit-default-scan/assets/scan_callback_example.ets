import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ScanCallbackExample {
  @State scanResultText: string = '等待扫码...';

  build() {
    Column({ space: 10 }) {
      Text('默认界面扫码 - Callback方式')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text(this.scanResultText)
        .fontSize(16)
        .margin({ top: 10 })
        .maxLines(5);

      Button('启动扫码(默认参数)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanDefault();
        });

      Button('启动扫码(带配置)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanWithOptions();
        });

      Button('启动扫码(仅条形码)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanBarcodeOnly();
        });
    }
    .width('100%')
    .height('100%');
  }

  startScanDefault(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      scanBarcode.startScanForResult(context, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          hilog.error(0x0001, '[ScanCallbackExample]', 
            `扫码失败: Code=${error.code}, Message=${error.message}`);
          this.handleScanError(error);
          return;
        }
        
        hilog.info(0x0001, '[ScanCallbackExample]', 
          `扫码成功: ${JSON.stringify(result)}`);
        
        this.scanResultText = `扫码成功!\n码类型: ${this.getScanTypeName(result.scanType)}\n码内容: ${result.originalValue}`;
        
        if (result.isGS1) {
          this.scanResultText += '\n(携带GS1数据)';
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0001, '[ScanCallbackExample]', 
        `启动扫码失败: Code=${err.code}, Message=${err.message}`);
      this.scanResultText = `启动扫码失败: ${err.message}`;
    }
  }

  startScanWithOptions(): void {
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
        
        hilog.info(0x0001, '[ScanCallbackExample]', 
          `带配置扫码成功: ${JSON.stringify(result)}`);
        
        this.scanResultText = `扫码成功!\n码类型: ${this.getScanTypeName(result.scanType)}\n码内容: ${result.originalValue}`;
        
        if (result.scanCodeRect) {
          const rect = result.scanCodeRect;
          this.scanResultText += `\n码位置: (${rect.left}, ${rect.top})`;
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  startScanBarcodeOnly(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ONE_D_CODE],
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
        
        hilog.info(0x0001, '[ScanCallbackExample]', 
          `条形码扫码成功: ${result.originalValue}`);
        
        this.scanResultText = `条形码扫码成功!\n码内容: ${result.originalValue}`;
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
        errorMsg = '参数错误';
        break;
      case 1000500001:
        errorMsg = '内部错误';
        break;
      case 1000500002:
        errorMsg = '用户取消扫码';
        break;
      default:
        errorMsg = `扫码失败(Code: ${error.code})`;
        break;
    }
    
    this.scanResultText = errorMsg;
    hilog.error(0x0001, '[ScanCallbackExample]', errorMsg);
  }

  getScanTypeName(scanType: scanCore.ScanType): string {
    const typeMap: Map<scanCore.ScanType, string> = new Map([
      [scanCore.ScanType.QR_CODE, 'QR码'],
      [scanCore.ScanType.EAN13_CODE, 'EAN-13'],
      [scanCore.ScanType.EAN8_CODE, 'EAN-8'],
      [scanCore.ScanType.CODE128_CODE, 'CODE 128'],
      [scanCore.ScanType.CODE39_CODE, 'CODE 39'],
      [scanCore.ScanType.ONE_D_CODE, '条形码'],
      [scanCore.ScanType.TWO_D_CODE, '二维码']
    ]);
    
    return typeMap.get(scanType) || '其他码类型';
  }
}