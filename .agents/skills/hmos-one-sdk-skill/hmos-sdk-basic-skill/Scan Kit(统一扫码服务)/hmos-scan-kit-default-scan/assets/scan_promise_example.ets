import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ScanPromiseExample {
  @State scanResultText: string = '等待扫码...';

  build() {
    Column({ space: 10 }) {
      Text('默认界面扫码 - Promise方式')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text(this.scanResultText)
        .fontSize(16)
        .margin({ top: 10 })
        .maxLines(5);

      Button('启动扫码(全部码类型)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanAllTypes();
        });

      Button('启动扫码(仅QR码)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanQRCode();
        });

      Button('启动扫码(多码识别)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanMultiMode();
        });
    }
    .width('100%')
    .height('100%');
  }

  async startScanAllTypes(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      const result = await scanBarcode.startScanForResult(context, options);
      
      hilog.info(0x0001, '[ScanPromiseExample]', 
        `扫码成功: type=${result.scanType}, value=${result.originalValue}`);
      
      this.scanResultText = `扫码成功!\n码类型: ${this.getScanTypeName(result.scanType)}\n码内容: ${result.originalValue}`;
      
      if (result.scanCodeRect) {
        hilog.info(0x0001, '[ScanPromiseExample]', 
          `码位置: left=${result.scanCodeRect.left}, top=${result.scanCodeRect.top}`);
      }
      
      if (result.source !== undefined) {
        const sourceName = result.source === scanCore.ScanSource.CAMERA ? '相机' : '相册';
        this.scanResultText += `\n扫码来源: ${sourceName}`;
      }
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0001, '[ScanPromiseExample]', 
        `扫码失败: Code=${err.code}, Message=${err.message}`);
      this.handleScanError(err);
    }
  }

  async startScanQRCode(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      const result = await scanBarcode.startScanForResult(context, options);
      
      hilog.info(0x0001, '[ScanPromiseExample]', 
        `QR码扫码成功: ${result.originalValue}`);
      
      this.scanResultText = `QR码扫码成功!\n码内容: ${result.originalValue}`;
      
      if (result.originalValue.startsWith('http://') || result.originalValue.startsWith('https://')) {
        this.scanResultText += '\n(检测到URL链接)';
      }
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  async startScanMultiMode(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: false
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      const result = await scanBarcode.startScanForResult(context, options);
      
      hilog.info(0x0001, '[ScanPromiseExample]', 
        `多码识别成功: ${result.originalValue}`);
      
      this.scanResultText = `多码识别成功!\n码类型: ${this.getScanTypeName(result.scanType)}\n码内容: ${result.originalValue}`;
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanError(err);
    }
  }

  handleScanError(error: BusinessError): void {
    let errorMsg = '';
    
    switch (error.code) {
      case 401:
        errorMsg = '参数错误: 请检查扫码配置';
        break;
      case 1000500001:
        errorMsg = '扫码服务异常: 请稍后重试';
        break;
      case 1000500002:
        errorMsg = '用户取消了扫码';
        break;
      default:
        errorMsg = `扫码失败: ${error.message}`;
        break;
    }
    
    this.scanResultText = errorMsg;
    hilog.error(0x0001, '[ScanPromiseExample]', errorMsg);
  }

  getScanTypeName(scanType: scanCore.ScanType): string {
    switch (scanType) {
      case scanCore.ScanType.QR_CODE:
        return 'QR码';
      case scanCore.ScanType.EAN13_CODE:
        return 'EAN-13';
      case scanCore.ScanType.CODE128_CODE:
        return 'CODE 128';
      case scanCore.ScanType.ONE_D_CODE:
        return '条形码';
      case scanCore.ScanType.TWO_D_CODE:
        return '二维码';
      default:
        return '其他码类型';
    }
  }
}