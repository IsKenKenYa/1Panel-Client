import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct TransliterationExample {
  @State inputText: string = '中国';
  @State outputText: string = '';
  @State transliteratorId: string = 'Any-Latn';

  build() {
    Column() {
      Text('文本音译示例')
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

      TextInput({ placeholder: '音译ID' })
        .text(this.transliteratorId)
        .onChange((value: string) => {
          this.transliteratorId = value;
        })
        .width('80%')
        .margin({ top: 10 });

      Button('执行音译')
        .onClick(() => {
          this.performTransliteration();
        })
        .margin({ top: 10 });

      Text(`音译结果: ${this.outputText}`)
        .fontSize(18)
        .margin({ top: 10 });

      Button('获取支持的音译ID')
        .onClick(() => {
          this.getAvailableIDs();
        })
        .margin({ top: 10 });

      Button('中文转拼音(带声调)')
        .onClick(() => {
          this.chineseToPinyinWithTone();
        })
        .margin({ top: 10 });

      Button('中文转拼音(去声调)')
        .onClick(() => {
          this.chineseToPinyinNoTone();
        })
        .margin({ top: 10 });

      Button('姓氏读音')
        .onClick(() => {
          this.surnameTransliteration();
        })
        .margin({ top: 10 });
    }
    .width('100%')
    .height('100%');
  }

  performTransliteration(): void {
    try {
      let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance(this.transliteratorId);
      this.outputText = transliterator.transform(this.inputText);
      console.log(`音译成功: '${this.inputText}' -> '${this.outputText}'`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.outputText = '音译失败';
    }
  }

  getAvailableIDs(): void {
    try {
      let ids: string[] = i18n.Transliterator.getAvailableIDs();
      console.log(`支持的音译ID数量: ${ids.length}`);
      console.log(`前10个ID: ${ids.slice(0, 10).join(', ')}`);
      this.outputText = `支持${ids.length}个音译ID`;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`获取音译ID列表失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.outputText = '获取失败';
    }
  }

  chineseToPinyinWithTone(): void {
    try {
      let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn');
      let words: string[] = ['中国', '美国', '德国', '法国', '日本', '韩国'];
      
      console.log('中文转拼音(带声调):');
      for (let word of words) {
        let pinyin: string = transliterator.transform(word);
        console.log(`  ${word} -> ${pinyin}`);
      }
      
      this.outputText = transliterator.transform(this.inputText);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.outputText = '音译失败';
    }
  }

  chineseToPinyinNoTone(): void {
    try {
      let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn;Latin-Ascii');
      let words: string[] = ['中国', '美国', '德国', '法国', '日本', '韩国'];
      
      console.log('中文转拼音(去声调):');
      for (let word of words) {
        let pinyin: string = transliterator.transform(word);
        console.log(`  ${word} -> ${pinyin}`);
      }
      
      this.outputText = transliterator.transform(this.inputText);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.outputText = '音译失败';
    }
  }

  surnameTransliteration(): void {
    try {
      let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Han-Latin/Names');
      let surnames: string[] = ['单老师', '长孙无忌', '欧阳修', '司马光'];
      
      console.log('姓氏读音音译:');
      for (let surname of surnames) {
        let pinyin: string = transliterator.transform(surname);
        console.log(`  ${surname} -> ${pinyin}`);
      }
      
      this.outputText = transliterator.transform(this.inputText);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.outputText = '音译失败';
    }
  }
}