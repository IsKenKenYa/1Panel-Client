@Entry
@Component
struct B19NextFocusSkipChild {
  build() {
    Column({ space: 16 }) {
      Text('B19 下一焦点跳过子节点')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '搜索' })
        .width('85%')
      Column({ space: 8 }) {
        Text('会员卡片')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Button('领取会员权益')
          .fontSize(14)
        Text('会员有效期至 2027-12-31')
          .fontSize(14)
          .fontColor('#666666')
      }
      .padding(16)
      .borderRadius(12)
      .backgroundColor('#f5f6f7')
      .width('85%')
      .alignItems(HorizontalAlign.Start)
      Button('下一步')
        .width('60%')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
