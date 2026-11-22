import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = '[BarcodeGeneratePage]';
const DOMAIN = 0x0001;

@Entry
@Component
struct BarcodeGeneratePage {
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State inputContent: string = '华为';
  @State selectedType: number = scanCore.ScanType.QR_CODE;
  @State widthValue: number = 400;
  @State heightValue: number = 400;
  @State errorMessage: string = '';

  build() {
    Column() {
      Text('码图生成演示')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      TextInput({ placeholder: '请输入内容', text: this.inputContent })
        .width('80%')
        .height(40)
        .margin({ bottom: 15 })
        .onChange((value: string) => {
          this.inputContent = value;
        });

      Row() {
        Text('码类型：')
          .fontSize(16);
        
        Select([
          { value: 'QR Code', icon: '' },
          { value: 'EAN-13', icon: '' },
          { value: 'Code 128', icon: '' },
          { value: 'Data Matrix', icon: '' }
        ])
          .selected(this.selectedType === scanCore.ScanType.QR_CODE ? 0 : 
                    this.selectedType === scanCore.ScanType.EAN13_CODE ? 1 :
                    this.selectedType === scanCore.ScanType.CODE128_CODE ? 2 : 3)
          .value('QR Code')
          .width('60%')
          .onSelect((index: number) => {
            switch (index) {
              case 0:
                this.selectedType = scanCore.ScanType.QR_CODE;
                this.widthValue = 400;
                this.heightValue = 400;
                break;
              case 1:
                this.selectedType = scanCore.ScanType.EAN13_CODE;
                this.widthValue = 400;
                this.heightValue = 200;
                break;
              case 2:
                this.selectedType = scanCore.ScanType.CODE128_CODE;
                this.widthValue = 400;
                this.heightValue = 200;
                break;
              case 3:
                this.selectedType = scanCore.ScanType.DATAMATRIX_CODE;
                this.widthValue = 400;
                this.heightValue = 400;
                break;
            }
          });
      }
      .width('80%')
      .margin({ bottom: 15 });

      Row() {
        Text('宽度：')
          .fontSize(16);
        TextInput({ text: this.widthValue.toString() })
          .width('30%')
          .height(40)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.widthValue = parseInt(value) || 200;
          });
        
        Text('高度：')
          .fontSize(16)
          .margin({ left: 20 });
        TextInput({ text: this.heightValue.toString() })
          .width('30%')
          .height(40)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.heightValue = parseInt(value) || 200;
          });
      }
      .width('80%')
      .margin({ bottom: 20 });

      Button('生成码图')
        .width('60%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.generateBarcode();
        });

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ top: 10, bottom: 10 });
      }

      if (this.pixelMap) {
        Text('生成结果：')
          .fontSize(16)
          .margin({ top: 20 });
        
        Image(this.pixelMap)
          .width(this.widthValue > 300 ? 300 : this.widthValue)
          .height(this.heightValue > 300 ? 300 : this.heightValue)
          .objectFit(ImageFit.Contain)
          .margin({ top: 10 });
        
        Text(`尺寸: ${this.widthValue}x${this.heightValue}`)
          .fontSize(14)
          .fontColor(Color.Gray)
          .margin({ top: 5 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  private generateBarcode(): void {
    this.errorMessage = '';
    this.pixelMap = undefined;

    if (!this.inputContent || this.inputContent.length === 0) {
      this.errorMessage = '内容不能为空';
      return;
    }

    if (this.widthValue < 200 || this.widthValue > 4096) {
      this.errorMessage = '宽度必须在200-4096之间';
      return;
    }

    if (this.heightValue < 200 || this.heightValue > 4096) {
      this.errorMessage = '高度必须在200-4096之间';
      return;
    }

    if (this.selectedType === scanCore.ScanType.EAN13_CODE) {
      if (!/^\d{12}$/.test(this.inputContent)) {
        this.errorMessage = 'EAN-13内容必须是12位数字';
        return;
      }
      if (this.inputContent.startsWith('0')) {
        this.errorMessage = 'EAN-13内容首位不能为0';
        return;
      }
    }

    let options: generateBarcode.CreateOptions = {
      scanType: this.selectedType,
      height: this.heightValue,
      width: this.widthValue,
      margin: 1,
      backgroundColor: 0xFFFFFF,
      pixelMapColor: 0x000000
    };

    if (this.selectedType === scanCore.ScanType.QR_CODE) {
      options.level = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
    }

    generateBarcode.createBarcode(this.inputContent, options, (err: BusinessError, pixelMap: image.PixelMap) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `生成失败，错误码: ${err.code}, 消息: ${err.message}`);
        this.errorMessage = `错误码: ${err.code}, ${err.message}`;
        return;
      }
      hilog.info(DOMAIN, TAG, '成功生成码图');
      this.pixelMap = pixelMap;
    });
  }
}