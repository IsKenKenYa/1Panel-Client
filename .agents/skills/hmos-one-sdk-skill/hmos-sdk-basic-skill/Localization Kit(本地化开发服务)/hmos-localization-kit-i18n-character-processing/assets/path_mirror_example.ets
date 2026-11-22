import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct PathMirrorExample {
  @State inputPath: string = 'data/out/tmp';
  @State delimiter: string = '/';
  @State localeText: string = 'ar';
  @State mirroredPath: string = '';

  build() {
    Column() {
      Text('文件路径镜像示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      TextInput({ placeholder: '输入路径' })
        .text(this.inputPath)
        .onChange((value: string) => {
          this.inputPath = value;
        })
        .width('80%')
        .margin({ top: 10 });

      TextInput({ placeholder: '分隔符' })
        .text(this.delimiter)
        .onChange((value: string) => {
          this.delimiter = value;
        })
        .width('80%')
        .margin({ top: 10 });

      TextInput({ placeholder: '语言代码' })
        .text(this.localeText)
        .onChange((value: string) => {
          this.localeText = value;
        })
        .width('80%')
        .margin({ top: 10 });

      Button('执行路径镜像')
        .onClick(() => {
          this.mirrorPath();
        })
        .margin({ top: 10 });

      Text(`镜像路径: ${this.mirroredPath}`)
        .fontSize(18)
        .margin({ top: 10 });

      Button('测试RTL语言')
        .onClick(() => {
          this.testRTLLanguages();
        })
        .margin({ top: 10 });

      Button('测试LTR语言')
        .onClick(() => {
          this.testLTRLanguages();
        })
        .margin({ top: 10 });

      Button('判断语言RTL属性')
        .onClick(() => {
          this.checkLanguageRTL();
        })
        .margin({ top: 10 });
    }
    .width('100%')
    .height('100%');
  }

  mirrorPath(): void {
    try {
      let locale: Intl.Locale = new Intl.Locale(this.localeText);
      this.mirroredPath = i18n.I18NUtil.getUnicodeWrappedFilePath(this.inputPath, this.delimiter, locale);
      
      console.log(`路径镜像: '${this.inputPath}' -> '${this.mirroredPath}'`);
      console.log(`语言: ${this.localeText}, 分隔符: '${this.delimiter}'`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`路径镜像失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.mirroredPath = '镜像失败';
    }
  }

  testRTLLanguages(): void {
    try {
      console.log('=== RTL语言路径镜像测试 ===');
      
      let rtlLanguages: string[] = ['ar', 'he', 'fa', 'ur'];
      let path: string = 'data/out/tmp';
      let delimiter: string = '/';

      for (let lang of rtlLanguages) {
        let locale: Intl.Locale = new Intl.Locale(lang);
        let mirrored: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, locale);
        let isRTL: boolean = i18n.isRTL(`${lang}-XX`);
        
        console.log(`语言: ${lang}`);
        console.log(`  RTL: ${isRTL}`);
        console.log(`  原路径: '${path}'`);
        console.log(`  镜像: '${mirrored}'`);
      }

      this.localeText = 'ar';
      this.mirrorPath();
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`RTL语言测试失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.mirroredPath = '测试失败';
    }
  }

  testLTRLanguages(): void {
    try {
      console.log('=== LTR语言路径测试 ===');
      
      let ltrLanguages: string[] = ['zh', 'en', 'ja', 'ko', 'fr', 'de'];
      let path: string = 'data/out/tmp';
      let delimiter: string = '/';

      for (let lang of ltrLanguages) {
        let locale: Intl.Locale = new Intl.Locale(lang);
        let result: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, locale);
        let isRTL: boolean = i18n.isRTL(`${lang}-XX`);
        
        console.log(`语言: ${lang}`);
        console.log(`  RTL: ${isRTL}`);
        console.log(`  原路径: '${path}'`);
        console.log(`  结果: '${result}'`);
      }

      this.localeText = 'zh';
      this.mirrorPath();
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`LTR语言测试失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.mirroredPath = '测试失败';
    }
  }

  checkLanguageRTL(): void {
    try {
      console.log('=== 判断语言RTL属性 ===');
      
      let languages: string[] = ['zh-CN', 'en-US', 'ar-EG', 'he-IL', 'fa-IR', 'ur-PK', 'ja-JP'];

      for (let lang of languages) {
        let isRTL: boolean = i18n.isRTL(lang);
        console.log(`语言: ${lang}, RTL: ${isRTL}`);
      }

      let isCurrentRTL: boolean = i18n.isRTL(this.localeText);
      this.mirroredPath = `语言${this.localeText}的RTL属性: ${isCurrentRTL}`;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`判断RTL属性失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.mirroredPath = '判断失败';
    }
  }
}