@Entry
@Component
struct WidgetCard {
  @State weatherInfo: string = '晴天 25°C';
  @State updateTime: string = '10:30';
  @State humidity: string = '65%';
  @State airQuality: string = '良好';

  build() {
    Column() {
      Row() {
        Text('天气')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
        
        Blank()
        
        Text(this.updateTime)
          .fontSize(10)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8 })
      
      Column() {
        Text(this.weatherInfo)
          .fontSize(20)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8 })
        
        Row() {
          Column() {
            Text('湿度')
              .fontSize(10)
              .fontColor('#AAAAAA')
            Text(this.humidity)
              .fontSize(12)
              .fontColor('#FFFFFF')
              .margin({ top: 2 })
          }
          .margin({ right: 16 })
          
          Column() {
            Text('空气质量')
              .fontSize(10)
              .fontColor('#AAAAAA')
            Text(this.airQuality)
              .fontSize(12)
              .fontColor('#FFFFFF')
              .margin({ top: 2 })
          }
        }
        .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      Text('更新')
        .fontSize(10)
        .fontColor('#CCCCCC')
        .padding({ bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1A1A1A')
    .borderRadius(16)
  }
}