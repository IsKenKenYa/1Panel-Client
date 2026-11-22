@Entry
@Component
struct Player {
  @State isPlaying: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B12 播放器页面')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(this.isPlaying ? '正在播放' : '已暂停')
        .fontSize(16)
        .fontColor('#666666')
      Image($r('app.media.play'))
        .id('playIcon')
        .width(64)
        .height(64)
        .borderRadius(32)
        .backgroundColor('#f0f0f0')
        .margin({ top: 24 })
        .onClick(() => {
          this.isPlaying = !this.isPlaying;
          // 播放/暂停切换的核心逻辑
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
