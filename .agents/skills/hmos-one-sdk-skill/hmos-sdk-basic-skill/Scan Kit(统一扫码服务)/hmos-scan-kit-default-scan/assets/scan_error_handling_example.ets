import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ScanErrorHandlingExample {
  @State errorMessage: string = '';
  @State scanResultText: string = '等待扫码...';
  @State showManualInput: boolean = false;
  @State manualInputValue: string = '';

  build() {
    Column({ space: 10 }) {
      Text('错误处理示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text(this.scanResultText)
        .fontSize(16)
        .margin({ top: 10 })
        .maxLines(5);

      if (this.errorMessage !== '') {
        Text(`错误信息: ${this.errorMessage}`)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ top: 5 });
      }

      Button('启动扫码(完整错误处理)')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startScanWithErrorHandling();
        });

      Button('测试参数错误')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.testParameterError();
        });

      if (this.showManualInput) {
        TextInput({ placeholder: '手动输入码值', text: this.manualInputValue })
          .width('80%')
          .height(40)
          .onChange((value: string) => {
            this.manualInputValue = value;
          });

        Button('提交手动输入')
          .width('80%')
          .height(40)
          .onClick(() => {
            this.handleManualInput();
          });
      }
    }
    .width('100%')
    .height('100%');
  }

  startScanWithErrorHandling(): void {
    this.errorMessage = '';
    this.showManualInput = false;

    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      if (!context) {
        throw new Error('Context获取失败');
      }

      scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanErrorWithFallback(error);
          return;
        }
        
        this.scanResultText = `扫码成功!\n码内容: ${result.originalValue}`;
        hilog.info(0x0001, '[ScanErrorHandling]', 
          `扫码成功: ${JSON.stringify(result)}`);
        
        this.processScanResult(result);
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0001, '[ScanErrorHandling]', 
        `启动扫码异常: Code=${err.code}, Message=${err.message}`);
      this.handleScanErrorWithFallback(err);
    }
  }

  testParameterError(): void {
    this.errorMessage = '';
    
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      
      const invalidOptions: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableMultiMode: true,
        enableAlbum: true
      };

      scanBarcode.startScanForResult(context, invalidOptions, (error: BusinessError, result: scanBarcode.ScanResult) => {
        if (error) {
          this.handleScanErrorWithFallback(error);
        }
      });
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleScanErrorWithFallback(err);
    }
  }

  handleScanErrorWithFallback(error: BusinessError): void {
    hilog.error(0x0001, '[ScanErrorHandling]', 
      `扫码错误: Code=${error.code}, Message=${error.message}`);
    
    let errorMsg = '';
    
    switch (error.code) {
      case 401:
        errorMsg = '参数错误';
        this.errorMessage = '参数验证失败,请检查配置';
        hilog.error(0x0001, '[ScanErrorHandling]', 
          '参数错误: 可能是enableMultiMode和enableAlbum冲突(多码不支持相册)');
        break;
        
      case 1000500001:
        errorMsg = '内部错误';
        this.errorMessage = '扫码服务异常';
        this.showManualInput = true;
        hilog.error(0x0001, '[ScanErrorHandling]', 
          '内部错误: 提供手动输入作为降级方案');
        break;
        
      case 1000500002:
        errorMsg = '用户取消';
        this.errorMessage = '';
        this.scanResultText = '用户取消了扫码';
        hilog.info(0x0001, '[ScanErrorHandling]', '用户取消了扫码操作');
        return;
        
      default:
        errorMsg = '未知错误';
        this.errorMessage = `扫码失败: ${error.message}`;
        this.showManualInput = true;
        break;
    }
    
    this.scanResultText = errorMsg;
  }

  processScanResult(result: scanBarcode.ScanResult): void {
    const codeValue = result.originalValue;
    
    if (result.scanType === scanCore.ScanType.QR_CODE) {
      if (codeValue.startsWith('http://') || codeValue.startsWith('https://')) {
        hilog.info(0x0001, '[ScanErrorHandling]', '检测到URL,建议跳转页面');
        this.scanResultText += '\n(URL链接)';
      } else {
        hilog.info(0x0001, '[ScanErrorHandling]', 'QR码内容: 文本或数据');
      }
    } else {
      hilog.info(0x0001, '[ScanErrorHandling]', 
        `条形码类型: ${this.getScanTypeName(result.scanType)}`);
    }
    
    if (result.isGS1) {
      hilog.info(0x0001, '[ScanErrorHandling]', '码图携带GS1数据');
      this.scanResultText += '\n(GS1数据)';
    }
  }

  handleManualInput(): void {
    if (this.manualInputValue.trim() !== '') {
      hilog.info(0x0001, '[ScanErrorHandling]', 
        `用户手动输入: ${this.manualInputValue}`);
      
      this.scanResultText = `手动输入成功!\n输入内容: ${this.manualInputValue}`;
      this.errorMessage = '';
      this.showManualInput = false;
    } else {
      this.errorMessage = '请输入有效的码值';
    }
  }

  getScanTypeName(scanType: scanCore.ScanType): string {
    const typeNames: Record<number, string> = {
      11: 'QR码',
      7: 'EAN-8',
      8: 'EAN-13',
      5: 'CODE 128',
      100: '条形码',
      101: '二维码'
    };
    
    return typeNames[scanType] || '其他码类型';
  }
}