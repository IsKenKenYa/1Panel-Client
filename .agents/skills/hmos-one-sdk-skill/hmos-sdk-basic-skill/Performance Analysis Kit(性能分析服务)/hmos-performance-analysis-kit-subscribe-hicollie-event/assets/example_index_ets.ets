/**
 * ArkTS页面示例
 * 演示如何在UI页面触发任务执行超时事件
 */

import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  @State message: string = 'HiAppEvent订阅任务执行超时事件示例';

  build() {
    Column() {
      // 标题文本
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)

      // 触发超时事件按钮
      Button('触发任务执行超时事件')
        .type(ButtonType.Capsule)
        .margin({ top: 30 })
        .backgroundColor('#0D9FFB')
        .width('80%')
        .height('5%')
        .onClick(() => {
          console.info('Index: 点击按钮触发超时事件');
          testNapi.TestHiCollieTimerNdk();
        })

      // 说明文本
      Text('点击按钮后会执行耗时任务模拟超时场景')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 15 })
        .textAlign(TextAlign.Center)

      Text('超时后会生成APP_HICOLLIE系统事件')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 5 })
        .textAlign(TextAlign.Center)

      Text('观察者会订阅并处理该事件')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 5 })
        .textAlign(TextAlign.Center)

      // 查看日志提示
      Text('请在DevEco Studio Log窗口查看事件日志')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }
}