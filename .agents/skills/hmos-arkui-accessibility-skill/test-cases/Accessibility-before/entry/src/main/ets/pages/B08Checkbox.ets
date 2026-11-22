@Entry
@Component
struct B08Checkbox {
  build() {
    Column({ space: 20 }) {
      Text('B08 复选框')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Row({ space: 8 }) {
        Checkbox({ name: 'agree', group: 'licenseGroup' })
          .width(24)
          .height(24)
        Text('我已阅读并同意用户协议')
          .fontSize(16)
      }
      Row({ space: 8 }) {
        Checkbox({ name: 'subscribe', group: 'licenseGroup' })
          .width(24)
          .height(24)
        Text('订阅产品动态消息')
          .fontSize(16)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
