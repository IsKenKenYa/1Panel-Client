@Entry
@Component
struct B20HoverText {
  @State message: string = '待检查';

  build() {
    Column({ space: 24 }) {
      Text('B20 触摸改文案')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 8 }) {
        Text('质检工位 03')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text(this.message)
          .fontSize(20)
          .fontColor('#007dfe')
      }
      .padding(24)
      .borderRadius(12)
      .backgroundColor('#f0f6ff')
      .onClick(() => {
        // 单击标记检查完成的核心逻辑
        this.message = '已检查完成';
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
