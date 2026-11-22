@Component
export struct DetailPage {
  @Consume pathStack: NavPathStack
  @State message: string = 'Detail Page'

  build() {
    NavDestination() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text('This is the detail page content.')
          .fontSize(16)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('Detail')
    .onBackPressed(() => {
      this.pathStack.pop()
      return true
    })
  }
}

