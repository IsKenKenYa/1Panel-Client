@Entry
@Component
export struct IncorrectBehaviorExample {
  title: string = 'Incorrect Accessibility Behavior';
  
  build() {
    NavDestination() {
      Column() {
        Text('Example 1: Parent and children all accessible')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({bottom: 12})
        
        Row() {
          Text('12:05')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
          Text('Beijing')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
        }
        .accessibilityText('Time Group')
        .height(50)
        .margin({bottom: 30})
        
        Text('Example 2: Overlapping accessibility texts')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({bottom: 12})
        
        Row() {
          Text('Weather: Sunny')
            .fontSize(18)
            .accessibilityText('Today weather')
          Text('Temperature: 25°C')
            .fontSize(18)
            .accessibilityText('Current temperature')
        }
        .accessibilityText('Weather Info')
        .height(50)
        .margin({bottom: 30})
        
        Text('Example 3: Deeply nested components')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({bottom: 12})
        
        Column() {
          Row() {
            Text('Item 1')
              .fontSize(14)
            Text('Item 2')
              .fontSize(14)
          }
          Row() {
            Text('Item 3')
              .fontSize(14)
            Text('Item 4')
              .fontSize(14)
          }
        }
        .accessibilityText('Container')
        .height(100)
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title(this.title)
  }
}