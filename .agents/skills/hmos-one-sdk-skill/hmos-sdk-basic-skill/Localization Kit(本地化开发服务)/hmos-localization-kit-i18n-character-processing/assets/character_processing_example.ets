import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct CharacterProcessingExample {
  @State message: string = '字符处理示例';

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Button('字符属性判断')
        .onClick(() => {
          this.characterPropertiesExample();
        })
        .margin({ top: 10 });

      Button('文本音译')
        .onClick(() => {
          this.transliterationExample();
        })
        .margin({ top: 10 });

      Button('文本标准化')
        .onClick(() => {
          this.normalizationExample();
        })
        .margin({ top: 10 });

      Button('换行点获取')
        .onClick(() => {
          this.lineBreakExample();
        })
        .margin({ top: 10 });

      Button('路径镜像')
        .onClick(() => {
          this.pathMirrorExample();
        })
        .margin({ top: 10 });
    }
    .width('100%')
    .height('100%');
  }

  characterPropertiesExample(): void {
    console.log('=== 字符属性判断示例 ===');
    
    try {
      let isDigit: boolean = i18n.Unicode.isDigit('1');
      console.log(`字符'1'是否为数字: ${isDigit}`);

      let isRTL: boolean = i18n.Unicode.isRTL('a');
      console.log(`字符'a'是否为RTL字符: ${isRTL}`);

      let isIdeograph: boolean = i18n.Unicode.isIdeograph('华');
      console.log(`字符'华'是否为表意文字: ${isIdeograph}`);

      let unicodeType: string = i18n.Unicode.getType('a');
      console.log(`字符'a'的Unicode类别: ${unicodeType}`);

      let isLetter: boolean = i18n.Unicode.isLetter('A');
      console.log(`字符'A'是否为字母: ${isLetter}`);

      let isLowerCase: boolean = i18n.Unicode.isLowerCase('a');
      console.log(`字符'a'是否为小写字母: ${isLowerCase}`);

      let isUpperCase: boolean = i18n.Unicode.isUpperCase('A');
      console.log(`字符'A'是否为大写字母: ${isUpperCase}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`字符属性判断失败, 错误码: ${err.code}, 消息: ${err.message}`);
    }
  }

  transliterationExample(): void {
    console.log('=== 文本音译示例 ===');
    
    try {
      let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn');
      let translatedText: string = transliterator.transform('中国');
      console.log(`'中国'音译为(带声调): ${translatedText}`);

      let toneLessTransliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn;Latin-Ascii');
      let toneLessText: string = toneLessTransliterator.transform('中国');
      console.log(`'中国'去声调音译为: ${toneLessText}`);

      let nameTransliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Han-Latin/Names');
      let nameText: string = nameTransliterator.transform('单老师');
      console.log(`'单老师'姓氏读音音译为: ${nameText}`);

      let ids: string[] = i18n.Transliterator.getAvailableIDs();
      console.log(`支持的音译ID数量: ${ids.length}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`文本音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
    }
  }

  normalizationExample(): void {
    console.log('=== 文本标准化示例 ===');
    
    try {
      let normalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFC);
      let normalizedText: string = normalizer.normalize('\u1E9B\u0323');
      console.log(`NFC标准化结果: ${normalizedText}`);

      let nfdNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFD);
      let nfdText: string = nfdNormalizer.normalize('\u1E9B\u0323');
      console.log(`NFD标准化结果: ${nfdText}`);

      let nfkcNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKC);
      let nfkcText: string = nfkcNormalizer.normalize('\u1E9B\u0323');
      console.log(`NFKC标准化结果: ${nfkcText}`);

      let nfkdNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKD);
      let nfkdText: string = nfkdNormalizer.normalize('\u1E9B\u0323');
      console.log(`NFKD标准化结果: ${nfkdText}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`文本标准化失败, 错误码: ${err.code}, 消息: ${err.message}`);
    }
  }

  lineBreakExample(): void {
    console.log('=== 换行点获取示例 ===');
    
    try {
      let iterator: i18n.BreakIterator = i18n.getLineInstance('en-GB');
      iterator.setLineBreakText('Apple is my favorite fruit.');

      let firstPos: number = iterator.first();
      console.log(`起始位置: ${firstPos}`);

      let nextPos: number = iterator.next(2);
      console.log(`移动2个换行点后的位置: ${nextPos}`);

      let currentPos: number = iterator.current();
      console.log(`当前位置: ${currentPos}`);

      let isBoundary: boolean = iterator.isBoundary(9);
      console.log(`位置9是否为换行点: ${isBoundary}`);

      let breakText: string = iterator.getLineBreakText();
      console.log(`处理的文本: ${breakText}`);

      console.log('遍历所有换行点:');
      let pos: number = iterator.first();
      while (pos !== -1) {
        pos = iterator.next();
        if (pos !== -1) {
          console.log(`换行点位置: ${pos}`);
        }
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`换行点获取失败, 错误码: ${err.code}, 消息: ${err.message}`);
    }
  }

  pathMirrorExample(): void {
    console.log('=== 文件路径镜像示例 ===');
    
    try {
      let path: string = 'data/out/tmp';
      let delimiter: string = '/';

      let localeAr: Intl.Locale = new Intl.Locale('ar');
      let mirrorPath: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeAr);
      console.log(`阿拉伯语路径镜像: ${mirrorPath}`);

      let localeZh: Intl.Locale = new Intl.Locale('zh');
      let unMirrorPath: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeZh);
      console.log(`中文路径: ${unMirrorPath}`);

      let isArRTL: boolean = i18n.isRTL('ar-EG');
      console.log(`阿拉伯语是否为RTL语言: ${isArRTL}`);

      let isZhRTL: boolean = i18n.isRTL('zh-CN');
      console.log(`中文是否为RTL语言: ${isZhRTL}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`路径镜像失败, 错误码: ${err.code}, 消息: ${err.message}`);
    }
  }
}