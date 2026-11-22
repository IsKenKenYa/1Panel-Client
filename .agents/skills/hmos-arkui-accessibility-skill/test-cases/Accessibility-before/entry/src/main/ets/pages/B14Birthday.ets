@Entry
@Component
struct B14Birthday {
  build() {
    Column({ space: 24 }) {
      Text('B14 生日三段文本')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 4 }) {
        Text('2010年')
          .fontSize(24)
        Text('8月')
          .fontSize(24)
        Text('15日')
          .fontSize(24)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
