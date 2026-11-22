@Entry
@Component
export struct MultidimensionalNestingExample {
  title: string = 'Multidimensional Nesting Accessibility';
  
  build() {
    NavDestination() {
      Column() {
        Text('Incorrect behavior:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({bottom: 12})
        
        Row(){
          Text('12:05')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({right: 20})
          Text('Beijing')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        .accessibilityText('Time Group')
        .height(50)
        .margin({bottom: 150})
        
        Text('Correct behavior:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({bottom: 12})
        
        Row(){
          Text('07:05')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({right: 20})
          Text('Moscow')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        .height(50)
        .accessibilityGroup(true)
        .accessibilityText('Time: 07:05, Location: Moscow')
        .accessibilityDescription('Weather card showing current time and location')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title(this.title)
  }
}