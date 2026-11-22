import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct LineBreakExample {
  @State inputText: string = 'Apple is my favorite fruit.';
  @State selectedLocale: string = 'en-GB';
  @State breakPointsText: string = '';
  @State currentPositionText: string = '';

  build() {
    Column() {
      Text('换行点获取示例')
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

      TextInput({ placeholder: '区域ID' })
        .text(this.selectedLocale)
        .onChange((value: string) => {
          this.selectedLocale = value;
        })
        .width('80%')
        .margin({ top: 10 });

      Button('获取所有换行点')
        .onClick(() => {
          this.getAllBreakPoints();
        })
        .margin({ top: 10 });

      Text(`换行点列表: ${this.breakPointsText}`)
        .fontSize(16)
        .margin({ top: 10 });

      Button('当前位置操作')
        .onClick(() => {
          this.positionOperations();
        })
        .margin({ top: 10 });

      Text(`当前位置信息: ${this.currentPositionText}`)
        .fontSize(16)
        .margin({ top: 10 });

      Button('判断换行点')
        .onClick(() => {
          this.checkBoundary();
        })
        .margin({ top: 10 });

      Button('中文文本换行')
        .onClick(() => {
          this.chineseLineBreak();
        })
        .margin({ top: 10 });
    }
    .width('100%')
    .height('100%');
  }

  getAllBreakPoints(): void {
    try {
      let iterator: i18n.BreakIterator = i18n.getLineInstance(this.selectedLocale);
      iterator.setLineBreakText(this.inputText);

      let breakPoints: number[] = [];
      let pos: number = iterator.first();

      while (pos !== -1) {
        breakPoints.push(pos);
        pos = iterator.next();
      }

      this.breakPointsText = breakPoints.join(', ');
      console.log(`文本: '${this.inputText}'`);
      console.log(`换行点: ${this.breakPointsText}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`获取换行点失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.breakPointsText = '获取失败';
    }
  }

  positionOperations(): void {
    try {
      let iterator: i18n.BreakIterator = i18n.getLineInstance(this.selectedLocale);
      iterator.setLineBreakText(this.inputText);

      let info: string[] = [];

      let firstPos: number = iterator.first();
      info.push(`起始位置: ${firstPos}`);

      let nextPos: number = iterator.next(2);
      info.push(`移动2个换行点后: ${nextPos}`);

      let currentPos: number = iterator.current();
      info.push(`当前位置: ${currentPos}`);

      let prevPos: number = iterator.previous();
      info.push(`前一个换行点: ${prevPos}`);

      let lastPos: number = iterator.last();
      info.push(`最后一个换行点: ${lastPos}`);

      this.currentPositionText = info.join('; ');
      console.log(`位置操作: ${this.currentPositionText}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`位置操作失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.currentPositionText = '操作失败';
    }
  }

  checkBoundary(): void {
    try {
      let iterator: i18n.BreakIterator = i18n.getLineInstance(this.selectedLocale);
      iterator.setLineBreakText(this.inputText);

      let testPositions: number[] = [0, 5, 6, 9, 12, 20, 27];

      console.log('=== 判断各位置是否为换行点 ===');
      for (let pos of testPositions) {
        let isBoundary: boolean = iterator.isBoundary(pos);
        let charAtPos: string = pos < this.inputText.length ? this.inputText.charAt(pos) : 'END';
        console.log(`位置${pos}(字符'${charAtPos}'): ${isBoundary}`);
      }

      this.currentPositionText = '已判断各位置';
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`判断换行点失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.currentPositionText = '判断失败';
    }
  }

  chineseLineBreak(): void {
    try {
      let chineseText: string = '这是一个中文文本换行示例。我们需要找到所有的换行点。';
      let iterator: i18n.BreakIterator = i18n.getLineInstance('zh-CN');
      iterator.setLineBreakText(chineseText);

      let breakPoints: number[] = [];
      let pos: number = iterator.first();

      console.log('=== 中文文本换行点 ===');
      console.log(`文本: '${chineseText}'`);

      while (pos !== -1) {
        breakPoints.push(pos);
        if (pos < chineseText.length) {
          let char: string = chineseText.charAt(pos);
          console.log(`换行点${pos}: 字符'${char}'`);
        }
        pos = iterator.next();
      }

      this.breakPointsText = breakPoints.join(', ');
      this.inputText = chineseText;
      this.selectedLocale = 'zh-CN';
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`中文换行点获取失败, 错误码: ${err.code}, 消息: ${err.message}`);
      this.breakPointsText = '获取失败';
    }
  }
}