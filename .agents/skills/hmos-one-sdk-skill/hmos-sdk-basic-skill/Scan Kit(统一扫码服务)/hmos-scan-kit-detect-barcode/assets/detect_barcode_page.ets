import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct DetectBarcodeCompletePage {
  @State message: string = '本地图片识码';
  @State scanResultText: string = '点击按钮选择图片并识别码图';
  @State isLoading: boolean = false;
  @State selectedImageUri: string = '';
  @State scanResults: Array<scanBarcode.ScanResult> = [];

  build() {
    Column() {
      Text(this.message)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 });

      Column() {
        Button('选择图片')
          .backgroundColor('#0D9FFB')
          .fontSize(20)
          .fontColor($r('sys.color.comp_background_list_card'))
          .fontWeight(FontWeight.Normal)
          .align(Alignment.Center)
          .type(ButtonType.Capsule)
          .width('85%')
          .height(50)
          .margin({ top: 10, bottom: 10 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.selectImage();
          });

        Button('识别码图')
          .backgroundColor(this.selectedImageUri ? '#0D9FFB' : '#CCCCCC')
          .fontSize(20)
          .fontColor($r('sys.color.comp_background_list_card'))
          .fontWeight(FontWeight.Normal)
          .align(Alignment.Center)
          .type(ButtonType.Capsule)
          .width('85%')
          .height(50)
          .margin({ top: 10, bottom: 10 })
          .enabled(!this.isLoading && this.selectedImageUri !== '')
          .onClick(() => {
            this.detectBarcode();
          });

        if (this.isLoading) {
          LoadingProgress()
            .color('#0D9FFB')
            .width(40)
            .height(40)
            .margin({ top: 20 });
        }

        Text('识码配置:')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 });

        Row() {
          Checkbox({ name: 'multiMode', group: 'options' })
            .select(true)
            .onChange((value: boolean) => {
              this.updateOptions('enableMultiMode', value);
            });
          Text('多码识别模式')
            .fontSize(16)
            .margin({ left: 10 });
        }
        .width('85%')
        .margin({ top: 10 });

        Row() {
          Checkbox({ name: 'album', group: 'options' })
            .select(true)
            .onChange((value: boolean) => {
              this.updateOptions('enableAlbum', value);
            });
          Text('启用相册')
            .fontSize(16)
            .margin({ left: 10 });
        }
        .width('85%')
        .margin({ top: 10 });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center);

      Scroll() {
        Column() {
          Text(this.scanResultText)
            .fontSize(16)
            .padding(15)
            .width('90%')
            .backgroundColor('#F5F5F5')
            .borderRadius(10);

          if (this.scanResults.length > 0) {
            ForEach(this.scanResults, (result: scanBarcode.ScanResult, index: number) => {
              Column() {
                Text(`码图 ${index + 1}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 10, bottom: 5 });

                Text(`类型: ${this.getScanTypeName(result.scanType)}`)
                  .fontSize(16)
                  .margin({ top: 5 });

                Text(`内容: ${result.originalValue}`)
                  .fontSize(16)
                  .margin({ top: 5 });

                if (result.scanCodeRect) {
                  Text(`位置: (${result.scanCodeRect.left}, ${result.scanCodeRect.top}) - (${result.scanCodeRect.right}, ${result.scanCodeRect.bottom})`)
                    .fontSize(14)
                    .margin({ top: 5 });
                }
              }
              .width('90%')
              .padding(15)
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
              .margin({ top: 10 });
            });
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .height('40%')
      .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F0F0')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Start);
  }

  private options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],
    enableMultiMode: true,
    enableAlbum: true
  };

  updateOptions(key: string, value: boolean): void {
    if (key === 'enableMultiMode') {
      this.options.enableMultiMode = value;
    } else if (key === 'enableAlbum') {
      this.options.enableAlbum = value;
    }
    hilog.info(0x0001, '[DetectBarcode]', `Options updated: ${JSON.stringify(this.options)}`);
  }

  async selectImage(): Promise<void> {
    this.isLoading = true;
    this.scanResultText = '正在选择图片...';

    let photoOption = new photoAccessHelper.PhotoSelectOptions();
    photoOption.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    photoOption.maxSelectNumber = 1;
    photoOption.isPhotoTakingSupported = false;
    photoOption.isEditSupported = false;

    let photoPicker = new photoAccessHelper.PhotoViewPicker();

    try {
      let result = await photoPicker.select(photoOption);

      if (!result || (result.photoUris && result.photoUris.length === 0)) {
        hilog.error(0x0001, '[DetectBarcode]', 'Failed to get PhotoSelectResult');
        this.scanResultText = '未选择图片';
        this.isLoading = false;
        return;
      }

      this.selectedImageUri = result.photoUris[0];
      hilog.info(0x0001, '[DetectBarcode]', `Selected image uri: ${this.selectedImageUri}`);
      this.scanResultText = `已选择图片: ${this.selectedImageUri}`;
      this.isLoading = false;

    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0001, '[DetectBarcode]', 
        `Failed to select photo. Code: ${err.code}, message: ${err.message}`);
      this.scanResultText = `选择图片失败: ${err.message}`;
      this.isLoading = false;
    }
  }

  async detectBarcode(): Promise<void> {
    if (!this.selectedImageUri) {
      this.scanResultText = '请先选择图片';
      return;
    }

    this.isLoading = true;
    this.scanResultText = '正在识别码图...';
    this.scanResults = [];

    let inputImage: detectBarcode.InputImage = { uri: this.selectedImageUri };

    try {
      let results = await detectBarcode.decode(inputImage, this.options);

      hilog.info(0x0001, '[DetectBarcode]', 
        `Succeeded in getting ScanResult, result is ${JSON.stringify(results)}`);

      this.scanResults = results;
      
      if (results.length === 0) {
        this.scanResultText = '未识别到码图，请选择包含清晰码图的图片';
      } else {
        this.scanResultText = `成功识别到 ${results.length} 个码图`;
      }

      this.isLoading = false;

    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0001, '[DetectBarcode]', 
        `Failed to detect barcode. Code: ${err.code}, message: ${err.message}`);
      this.handleError(err);
      this.isLoading = false;
    }
  }

  getScanTypeName(scanType: scanCore.ScanType): string {
    switch (scanType) {
      case scanCore.ScanType.QR_CODE:
        return 'QR Code (二维码)';
      case scanCore.ScanType.CODE128_CODE:
        return 'Code 128 (条形码)';
      case scanCore.ScanType.EAN13_CODE:
        return 'EAN-13 (条形码)';
      case scanCore.ScanType.EAN8_CODE:
        return 'EAN-8 (条形码)';
      case scanCore.ScanType.UPC_A_CODE:
        return 'UPC-A (条形码)';
      case scanCore.ScanType.UPC_E_CODE:
        return 'UPC-E (条形码)';
      case scanCore.ScanType.CODE39_CODE:
        return 'Code 39 (条形码)';
      case scanCore.ScanType.CODE93_CODE:
        return 'Code 93 (条形码)';
      case scanCore.ScanType.CODABAR_CODE:
        return 'Codabar (条形码)';
      case scanCore.ScanType.ITF14_CODE:
        return 'ITF-14 (条形码)';
      case scanCore.ScanType.PDF417_CODE:
        return 'PDF417 (二维码)';
      case scanCore.ScanType.DATAMATRIX_CODE:
        return 'Data Matrix (二维码)';
      case scanCore.ScanType.AZTEC_CODE:
        return 'Aztec (二维码)';
      case scanCore.ScanType.MULTIFUNCTIONAL_CODE:
        return 'Multifunctional Code (多功能码)';
      default:
        return 'Unknown (未知)';
    }
  }

  handleError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        this.scanResultText = '参数错误: 图片路径格式不正确，请重新选择图片';
        break;
      case 1000500001:
        this.scanResultText = '内部错误: 图片读取失败或码图无法识别，请尝试其他图片';
        break;
      default:
        this.scanResultText = `未知错误 (${error.code}): ${error.message}`;
    }
  }
}