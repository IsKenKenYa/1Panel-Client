@Component
export struct FeedbackPage {
  @Consume pathStack: NavPathStack
  @State message: string = 'Feedback'

  build() {
    NavDestination() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        TextInput({ placeholder: 'Enter your feedback' })
          .width('80%')
          .margin({ bottom: 16 })

        Button('Submit')
          .onClick(() => {
            this.pathStack.pop()
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('Feedback')
    .onBackPressed(() => {
      this.pathStack.pop()
      return true
    })
  }
}
