import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG = 'BarcodeGeneratorArray';
const DOMAIN = 0x0001;

@Entry
@Component
struct BarcodeGeneratorArray {
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State errorMessage: string = '';
  @State byteLength: number = 0;

  build() {
    Column() {
      Text('QR Code from ArrayBuffer')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      if (this.pixelMap) {
        Image(this.pixelMap)
          .width(300)
          .height(300)
          .objectFit(ImageFit.Contain)
          .border({ width: 2, color: Color.Blue })
        
        Text(`Byte length: ${this.byteLength}`)
          .fontSize(14)
          .margin({ top: 10 })
      } else if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
          .textAlign(TextAlign.Center)
          .width('80%')
      } else {
        Text('Click button to generate barcode')
          .fontSize(16)
          .fontColor(Color.Gray)
      }

      Button('Generate QR Code')
        .width('80%')
        .height(50)
        .margin({ top: 30 })
        .onClick(() => {
          this.generateBarcodeFromArrayBuffer();
        });

      Button('Clear')
        .width('80%')
        .height(40)
        .margin({ top: 10 })
        .backgroundColor(Color.Gray)
        .onClick(() => {
          this.pixelMap = undefined;
          this.errorMessage = '';
          this.byteLength = 0;
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }

  private async generateBarcodeFromArrayBuffer(): Promise<void> {
    this.pixelMap = undefined;
    this.errorMessage = '';

    try {
      const hexString: string = 
        '0177C10DD10F7768600202312110000063458FD14112345678FFFFD381012610b746365409210201b66636540ad0200020000000000110e617003201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006645fbec664358ECF657CB40693c92da';
      
      const contentBuffer: ArrayBuffer = buffer.from(hexString, 'hex').buffer;
      this.byteLength = contentBuffer.byteLength;

      hilog.info(DOMAIN, TAG, `Generating QR Code with ${this.byteLength} bytes`);

      const options: generateBarcode.CreateOptions = {
        scanType: scanCore.ScanType.QR_CODE,
        width: 400,
        height: 400,
        margin: 1,
        level: generateBarcode.ErrorCorrectionLevel.LEVEL_H,
        backgroundColor: 0xFFFFFF,
        pixelMapColor: 0x000000
      };

      const result: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
      this.pixelMap = result;

      hilog.info(DOMAIN, TAG, 'Successfully generated barcode from ArrayBuffer');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.errorMessage = `Error ${err.code}: ${err.message}`;
      hilog.error(DOMAIN, TAG, `Failed: ${err.code}, ${err.message}`);
    }
  }
}