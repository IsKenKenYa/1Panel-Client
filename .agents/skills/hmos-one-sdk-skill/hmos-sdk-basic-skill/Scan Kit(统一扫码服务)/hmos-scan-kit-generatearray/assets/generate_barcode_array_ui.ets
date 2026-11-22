import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG: string = 'GenerateBarcodeUI';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct GenerateBarcodeArrayPage {
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State hexContent: string = '0177C10DD10F7768600202312110000063458FD14112345678FFFFD381012610b746365409210201b66636540ad0200020000000000110e617003201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006645fbec664358ECF657CB40693c92da';
  @State widthValue: number = 400;
  @State heightValue: number = 400;
  @State statusMessage: string = 'Ready to generate';

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text('Generate QR Code from Byte Array')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      TextInput({ placeholder: 'Input hex content', text: this.hexContent })
        .width('80%')
        .height(50)
        .onChange((value: string) => {
          this.hexContent = value;
        })
        .margin({ bottom: 10 })

      Row() {
        Text('Width: ')
          .fontSize(16)
        TextInput({ placeholder: 'Width', text: this.widthValue.toString() })
          .width(100)
          .height(40)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.widthValue = parseInt(value) || 400;
          })
        
        Text('  Height: ')
          .fontSize(16)
        TextInput({ placeholder: 'Height', text: this.heightValue.toString() })
          .width(100)
          .height(40)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.heightValue = parseInt(value) || 400;
          })
      }
      .margin({ bottom: 20 })

      Button('Generate QR Code')
        .width('60%')
        .height(50)
        .onClick(() => {
          this.generateBarcode();
        })
        .margin({ bottom: 20 })

      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(Color.Blue)
        .margin({ bottom: 20 })

      if (this.pixelMap) {
        Text('Generated QR Code:')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Image(this.pixelMap)
          .width(300)
          .height(300)
          .objectFit(ImageFit.Contain)
          .border({ width: 2, color: Color.Gray })
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  private async generateBarcode(): Promise<void> {
    this.statusMessage = 'Generating...';
    this.pixelMap = undefined;

    if (!this.validateHexContent()) {
      this.statusMessage = 'Invalid hex content format';
      return;
    }

    if (!this.validateDimensions()) {
      this.statusMessage = 'Invalid dimensions. Width/Height range: [200, 4096]';
      return;
    }

    try {
      const contentBuffer: ArrayBuffer = buffer.from(this.hexContent, 'hex').buffer;
      const bufferSize = contentBuffer.byteLength;

      if (bufferSize > 2048) {
        this.statusMessage = `Buffer size ${bufferSize} exceeds max limit 2048 bytes`;
        return;
      }

      const level = this.getErrorCorrectionLevel(bufferSize);

      const options: generateBarcode.CreateOptions = {
        scanType: scanCore.ScanType.QR_CODE,
        width: this.widthValue,
        height: this.heightValue,
        margin: 1,
        level: level,
        backgroundColor: 0xFFFFFF,
        pixelMapColor: 0x000000
      };

      const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
      this.pixelMap = pixelMap;
      this.statusMessage = `Success! Size: ${this.widthValue}x${this.heightValue}, Buffer: ${bufferSize} bytes, Level: ${level}`;
      hilog.info(DOMAIN, TAG, 'Succeeded in creating barCode from UI');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.statusMessage = `Error: Code ${err.code}, Message: ${err.message}`;
      hilog.error(DOMAIN, TAG, `Failed to createBarCode. Code: ${err.code}, message: ${err.message}`);
    }
  }

  private validateHexContent(): boolean {
    if (!this.hexContent || this.hexContent.length === 0) {
      return false;
    }
    
    const hexRegex = /^[0-9A-Fa-f]+$/;
    return hexRegex.test(this.hexContent);
  }

  private validateDimensions(): boolean {
    return this.widthValue >= 200 && this.widthValue <= 4096 &&
           this.heightValue >= 200 && this.heightValue <= 4096;
  }

  private getErrorCorrectionLevel(bufferSize: number): generateBarcode.ErrorCorrectionLevel {
    if (bufferSize <= 1024) {
      return generateBarcode.ErrorCorrectionLevel.LEVEL_H;
    } else if (bufferSize <= 1536) {
      return generateBarcode.ErrorCorrectionLevel.LEVEL_Q;
    } else if (bufferSize <= 2048) {
      return generateBarcode.ErrorCorrectionLevel.LEVEL_M;
    }
    return generateBarcode.ErrorCorrectionLevel.LEVEL_L;
  }
}