@Component
export struct NewsDetail {
  @Consume pathStack: NavPathStack
  @State message: string = 'News Detail'

  build() {
    NavDestination() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text('News article content goes here.')
          .fontSize(16)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('News')
    .onBackPressed(() => {
      this.pathStack.pop()
      return true
    })
  }
}