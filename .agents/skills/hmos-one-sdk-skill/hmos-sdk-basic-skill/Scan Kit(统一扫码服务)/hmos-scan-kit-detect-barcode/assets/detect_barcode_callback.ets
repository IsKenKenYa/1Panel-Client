import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct DetectBarcodeCallbackPage {
  @State message: string = '识别本地图片 - Callback方式';
  @State scanResult: string = '';

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Button('选择图片并识码')
        .backgroundColor('#0D9FFB')
        .fontSize(18)
        .fontColor($r('sys.color.comp_background_list_card'))
        .fontWeight(FontWeight.Normal)
        .align(Alignment.Center)
        .type(ButtonType.Capsule)
        .width('80%')
        .height(50)
        .margin({ top: 10, bottom: 10 })
        .onClick(() => {
          this.detectBarcodeWithCallback();
        });

      Text(this.scanResult)
        .fontSize(16)
        .margin({ top: 20 })
        .padding(10)
        .width('90%')
        .backgroundColor('#F0F0F0');
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start);
  }

  detectBarcodeWithCallback(): void {
    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    };

    let photoOption = new photoAccessHelper.PhotoSelectOptions();
    photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoOption.maxSelectNumber = 1;
    photoOption.isPhotoTakingSupported = false;
    photoOption.isEditSupported = false;

    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    
    photoPicker.select(photoOption).then((result: photoAccessHelper.PhotoSelectResult) => {
      if (!result || (result.photoUris && result.photoUris.length === 0)) {
        hilog.error(0x0001, '[DetectBarcode]', 'Failed to get PhotoSelectResult');
        this.scanResult = '未选择图片';
        return;
      }

      let inputImage: detectBarcode.InputImage = { uri: result.photoUris[0] };
      
      hilog.info(0x0001, '[DetectBarcode]', `Selected image uri: ${inputImage.uri}`);

      try {
        detectBarcode.decode(inputImage, options, 
          (error: BusinessError, scanResults: Array<scanBarcode.ScanResult>) => {
            if (error && error.code) {
              hilog.error(0x0001, '[DetectBarcode]', 
                `Failed to get ScanResult. Code: ${error.code}, message: ${error.message}`);
              this.handleError(error);
              return;
            }

            hilog.info(0x0001, '[DetectBarcode]', 
              `Succeeded in getting ScanResult, result is ${JSON.stringify(scanResults)}`);

            this.processScanResults(scanResults);
          });
      } catch (error) {
        let err = error as BusinessError;
        hilog.error(0x0001, '[DetectBarcode]', 
          `Failed to detectBarcode. Code: ${err.code}, message: ${err.message}`);
        this.handleError(err);
      }
    }).catch((error: BusinessError) => {
      hilog.error(0x0001, '[DetectBarcode]', 
        `Failed to select photo. Code: ${error.code}, message: ${error.message}`);
      this.scanResult = `选择图片失败: ${error.message}`;
    });
  }

  processScanResults(results: Array<scanBarcode.ScanResult>): void {
    if (results.length === 0) {
      this.scanResult = '未识别到码图';
      return;
    }

    let resultText = `识别到 ${results.length} 个码图:\n\n`;
    
    for (let i = 0; i < results.length; i++) {
      let result = results[i];
      resultText += `码图 ${i + 1}:\n`;
      resultText += `  类型: ${this.getScanTypeName(result.scanType)}\n`;
      resultText += `  内容: ${result.originalValue}\n`;
      
      if (result.scanCodeRect) {
        resultText += `  位置: 左上(${result.scanCodeRect.left}, ${result.scanCodeRect.top}), `;
        resultText += `右下(${result.scanCodeRect.right}, ${result.scanCodeRect.bottom})\n`;
      }
      resultText += '\n';
    }

    this.scanResult = resultText;
  }

  getScanTypeName(scanType: scanCore.ScanType): string {
    switch (scanType) {
      case scanCore.ScanType.QR_CODE:
        return 'QR Code';
      case scanCore.ScanType.CODE128_CODE:
        return 'Code 128';
      case scanCore.ScanType.EAN13_CODE:
        return 'EAN-13';
      case scanCore.ScanType.EAN8_CODE:
        return 'EAN-8';
      case scanCore.ScanType.UPC_A_CODE:
        return 'UPC-A';
      case scanCore.ScanType.UPC_E_CODE:
        return 'UPC-E';
      case scanCore.ScanType.CODE39_CODE:
        return 'Code 39';
      case scanCore.ScanType.CODE93_CODE:
        return 'Code 93';
      case scanCore.ScanType.CODABAR_CODE:
        return 'Codabar';
      case scanCore.ScanType.ITF14_CODE:
        return 'ITF-14';
      case scanCore.ScanType.PDF417_CODE:
        return 'PDF417';
      case scanCore.ScanType.DATAMATRIX_CODE:
        return 'Data Matrix';
      case scanCore.ScanType.AZTEC_CODE:
        return 'Aztec';
      case scanCore.ScanType.MULTIFUNCTIONAL_CODE:
        return 'Multifunctional Code';
      default:
        return 'Unknown';
    }
  }

  handleError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        this.scanResult = '参数错误: 请检查图片路径格式';
        break;
      case 1000500001:
        this.scanResult = '内部错误: 图片读取失败或无法识别码图';
        break;
      default:
        this.scanResult = `未知错误: ${error.message}`;
    }
  }
}