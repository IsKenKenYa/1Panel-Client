@Entry
@Component
struct B15OverrideQuery {
  build() {
    Column({ space: 24 }) {
      Text('B15 已设置 text 与 description 的组件')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Button('提交订单')
        .accessibilityText('支付 99 元')
        .accessibilityDescription('单指双击即可提交订单并完成支付')
        .onClick(() => {
          // 提交订单并支付的核心逻辑
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
