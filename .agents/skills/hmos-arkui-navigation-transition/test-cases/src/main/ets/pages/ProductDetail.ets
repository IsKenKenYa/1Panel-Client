@Component
export struct ProductDetail {
  @Consume pathStack: NavPathStack
  @State message: string = 'Product Detail'
  @State scaleValue: number = 1
  @State opacityValue: number = 1

  build() {
    NavDestination() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })
          .scale({ x: this.scaleValue, y: this.scaleValue })
          .opacity(this.opacityValue)

        Text('Product information content.')
          .fontSize(16)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('Product')
    .onBackPressed(() => {
      this.pathStack.pop()
      return true
    })
  }
}
