@Entry
@Component
struct B03SubmitOrder {
  build() {
    Column({ space: 24 }) {
      Text('B03 有文本的提交订单按钮')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 8 }) {
        Text('商品：无线蓝牙耳机 x1')
          .fontSize(16)
        Text('合计：99 元')
          .fontSize(16)
          .fontColor('#e84030')
      }
      .alignItems(HorizontalAlign.Start)
      Button('提交订单')
        .width('60%')
        .onClick(() => {
          // 提交订单并支付的核心逻辑
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
