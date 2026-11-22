@Entry
@Component
struct B05DateGroup {
  build() {
    Column({ space: 24 }) {
      Text('B05 日期三段文本')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column() {
        Text('2026年')
          .fontSize(24)
        Text('1月27日')
          .fontSize(24)
        Text('星期二')
          .fontSize(24)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
