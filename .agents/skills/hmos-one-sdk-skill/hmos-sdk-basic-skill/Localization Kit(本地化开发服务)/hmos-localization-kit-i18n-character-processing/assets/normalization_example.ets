import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct NormalizationExample {
  @State inputText: string = '\u1E9B\u0323';
  @State normalizedText: string = '';
  @State selectedMode: string = 'NFC';

  build() {
    Column() {
      Text('文本标准化示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      TextInput({ placeholder: '输入文本' })
        .text(this.inputText)
        .onChange((value: string) => {
          this.inputText = value;
        })
        .width('80%')
        .margin({ top: 10 });

      Radio({ value: 'NFC', group: 'normalizationMode' })
        .text('NFC范式')
        .checked(this.selectedMode === 'NFC')
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedMode = 'NFC';
            this.normalizeText();
          }
        })
        .margin({ top: 10 });

      Radio({ value: 'NFD', group: 'normalizationMode' })
        .text('NFD范式')
        .checked(this.selectedMode === 'NFD')
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedMode = 'NFD';
            this.normalizeText();
          }
        })
        .margin({ top: 10 });

      Radio({ value: 'NFKC', group: 'normalizationMode' })
        .text('NFKC范式')
        .checked(this.selectedMode === 'NFKC')
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedMode = 'NFKC';
            this.normalizeText();
          }
        })
        .margin({ top: 10 });

      Radio({ value: 'NFKD', group: 'normalizationMode' })
        .text('NFKD范式')
        .checked(this.selectedMode === 'NFKD')
        .onChange((isChecked: boolean) => {
          if (isChecked) {
            this.selectedMode = 'NFKD';
            this.normalizeText();
          }
        })
        .margin({ top: 10 });

      Text(`标准化结果: ${this.normalizedText}`)
        .fontSize(18)
        .margin({ top: 10 });

      Button('执行标准化')
        .onClick(() => {
          this.normalizeText();
        })
        .margin({ top: 10 });

      Button('对比所有范式')
        .onClick(() => {
          this.compareAllModes();
        })
        .margin({ top: 10 });

      Button('说明')
        .onClick(() => {
          this.showNormalizationInfo();
        })
        .margin({ top: 10 });
    }
    .width('100%')
    .height('100%');
  }

  normalizeText(): void {
    try {
      let mode: i18n.NormalizerMode;
      
      switch (this.selectedMode) {
        case 'NFC':
          mode = i18n.NormalizerMode.NFC;
          break;
        case 'NFD':
          mode = i18n.NormalizerMode.NFD;
          break;
        case 'NFKC':
          mode = i18n.NormalizerMode.NFKC;
          break;
        case 'NFKD':
          mode = i18n.NormalizerMode.NFKD;
          break;
        default:
          mode = i18n.NormalizerMode.NFC;
      }

      let normalizer: i18n.Normalizer = i18n.Normalizer.getInstance(mode);
      this.normalizedText = normalizer.normalize(this.inputText);
      
      console.log(`标准化成功(${this.selectedMode}): '${this.inputText}' -> '${this.normalizedText}'`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`标准化失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.normalizedText = '标准化失败';
    }
  }

  compareAllModes(): void {
    try {
      console.log('=== 对比所有标准化范式 ===');
      console.log(`原始文本: ${this.inputText}`);

      let nfcNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFC);
      let nfcText: string = nfcNormalizer.normalize(this.inputText);
      console.log(`NFC: ${nfcText}`);

      let nfdNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFD);
      let nfdText: string = nfdNormalizer.normalize(this.inputText);
      console.log(`NFD: ${nfdText}`);

      let nfkcNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKC);
      let nfkcText: string = nfkcNormalizer.normalize(this.inputText);
      console.log(`NFKC: ${nfkcText}`);

      let nfkdNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKD);
      let nfkdText: string = nfkdNormalizer.normalize(this.inputText);
      console.log(`NFKD: ${nfkdText}`);

      this.normalizedText = `NFC:${nfcText} NFD:${nfdText} NFKC:${nfkcText} NFKD:${nfkdText}`;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`标准化对比失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.normalizedText = '对比失败';
    }
  }

  showNormalizationInfo(): void {
    console.log('=== Unicode标准化范式说明 ===');
    console.log('NFC (Normalization Form C): 组合形式,适合显示和存储');
    console.log('NFD (Normalization Form D): 分解形式,适合内部处理和比较');
    console.log('NFKC (Normalization Form KC): 兼容性组合形式,兼容性更好');
    console.log('NFKD (Normalization Form KD): 兼容性分解形式,兼容性更好');
    console.log('详细说明参考: https://www.unicode.org/reports/tr15/#Norm_Forms');
  }
}