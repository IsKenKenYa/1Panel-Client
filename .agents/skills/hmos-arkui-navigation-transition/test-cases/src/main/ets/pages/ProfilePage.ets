@Component
export struct ProfilePage {
  @Consume pathStack: NavPathStack
  @State message: string = 'Profile Page'

  build() {
    NavDestination() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Text('User profile content goes here.')
          .fontSize(16)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title('Profile')
    .onBackPressed(() => {
      this.pathStack.pop()
      return true
    })
  }
}
