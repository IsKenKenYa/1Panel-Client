import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG = 'TrafficCardBarcode';
const DOMAIN = 0x0001;

@Entry
@Component
struct TrafficCardBarcode {
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State cardInfo: string = '';

  build() {
    Column() {
      Text('Traffic Card QR Code Generator')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      TextInput({ placeholder: 'Enter card data (hex string)' })
        .width('90%')
        .height(60)
        .margin({ bottom: 20 })
        .onChange((value: string) => {
          this.cardInfo = value;
        });

      if (this.pixelMap) {
        Image(this.pixelMap)
          .width(280)
          .height(280)
          .objectFit(ImageFit.Contain)
      }

      Row() {
        Button('Generate')
          .width('40%')
          .height(50)
          .onClick(() => {
            this.generateTrafficCardBarcode();
          });

        Button('Demo Data')
          .width('40%')
          .height(50)
          .backgroundColor(Color.Orange)
          .onClick(() => {
            this.loadDemoData();
          });
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private loadDemoData(): void {
    this.cardInfo = 
      '0177C10DD10F7768600202312110000063458FD14112345678FFFFD381012610b746365409210201b66636540ad0200020000000000110e617003201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006645fbec664358ECF657CB40693c92da';
  }

  private async generateTrafficCardBarcode(): Promise<void> {
    if (!this.cardInfo || this.cardInfo.length === 0) {
      hilog.error(DOMAIN, TAG, 'No card data provided');
      return;
    }

    try {
      const contentBuffer: ArrayBuffer = buffer.from(this.cardInfo, 'hex').buffer;
      
      const options: generateBarcode.CreateOptions = {
        scanType: scanCore.ScanType.QR_CODE,
        width: 350,
        height: 350,
        margin: 2,
        level: generateBarcode.ErrorCorrectionLevel.LEVEL_H
      };

      this.pixelMap = await generateBarcode.createBarcode(contentBuffer, options);
      hilog.info(DOMAIN, TAG, 'Traffic card barcode generated successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error: ${err.code} - ${err.message}`);
    }
  }
}