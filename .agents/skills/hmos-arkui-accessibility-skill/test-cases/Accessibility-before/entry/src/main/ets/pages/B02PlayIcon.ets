@Entry
@Component
struct B02PlayIcon {
  build() {
    Column({ space: 24 }) {
      Text('B02 无文本播放图标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column() {
        Image($r('app.media.play'))
          .width(60)
          .height(60)
          .onClick(() => {
            // 播放音频、视频的核心逻辑
          })
      }
      .backgroundColor('#f1f2f3')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
