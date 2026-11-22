// Index页面 - 跳转到Web页面
// 文件路径：entry/src/main/ets/pages/Index.ets

import { router } from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('ArkWeb丢帧事件测试')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })

      Text('点击按钮跳转到Web页面，滑动页面触发丢帧事件')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 40 })

      // 按钮跳转到易出现滑动丢帧的web场景，触发ArkWeb抛滑丢帧事件
      Button('ArkWebFlingJank ArkTs')
        .type(ButtonType.Capsule)
        .margin({ top: 20 })
        .backgroundColor('#0D9FFB')
        .width('80%')
        .height('5%')
        .fontSize(16)
        .onClick(() => {
          hilog.info(0x0000, 'IndexTag', 'Navigate to ArkWebPage');
          router.pushUrl({ url: 'pages/ArkWebPage' })
            .then(() => {
              hilog.info(0x0000, 'IndexTag', 'Succeeded in navigating to ArkWebPage');
            })
            .catch((error) => {
              hilog.error(0x0000, 'IndexTag', `Failed to navigate: ${JSON.stringify(error)}`);
            });
        })

      // 说明文本
      Column() {
        Text('使用说明：')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 40, bottom: 10 })

        Text('1. 点击上方按钮跳转到Web页面')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        Text('2. 在Web页面中滑动内容')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        Text('3. 当发生卡顿50ms及以上时，触发丢帧事件')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        Text('4. 在Log窗口查看事件数据')
          .fontSize(12)
          .fontColor('#999999')
      }
      .margin({ top: 20 })
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}