@Entry
@Component
struct OperationErrorExample {
  @State connectionState: string = 'Connection interrupted'
  @State isError: boolean = true
  
  build() {
    NavDestination() {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Row() {
            Text('Connection state').fontSize(30)
          }
          Row() {
            Radio({ value: 'Radio1', group: 'radioGroup' })
              .checked(this.isError)
              .radioStyle({
                checkedBackgroundColor: Color.Red
              })
              .height(50)
              .width(50)
              .onChange((isChecked: boolean) => {
                console.info('Radio1 status is: ' + isChecked)
                this.isError = isChecked
              })
            Text(this.connectionState)
              .fontColor(Color.Red)
              .fontSize(20)
          }
          .width('80%')
          .accessibilityGroup(true)
          .accessibilityText('Connection error: ' + this.connectionState + ', please check network settings')
          .accessibilityDescription('This is a network connection error indicator')
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }.title('Operation Error Scenario')
  }
}