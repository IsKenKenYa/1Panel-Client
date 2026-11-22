@Entry
@Component
struct B22ProductCard {
  build() {
    Column({ space: 24 }) {
      Text('B22 商品卡片')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 6 }) {
        Text('华为手机')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('¥4999')
          .fontSize(20)
          .fontColor('#e84030')
        Text('已售 1024 件')
          .fontSize(14)
          .fontColor('#666666')
      }
      .padding(16)
      .borderRadius(12)
      .backgroundColor('#f5f6f7')
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        // 进入商品详情核心逻辑
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
