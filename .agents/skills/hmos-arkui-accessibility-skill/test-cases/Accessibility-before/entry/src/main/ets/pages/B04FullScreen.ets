@Entry
@Component
struct B04FullScreen {
  build() {
    Column({ space: 24 }) {
      Text('B04 全屏按钮')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Button()
        .background(Color.Blue)
        .width(120)
        .height(48)
        .onClick(() => {
          // 全屏逻辑
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
