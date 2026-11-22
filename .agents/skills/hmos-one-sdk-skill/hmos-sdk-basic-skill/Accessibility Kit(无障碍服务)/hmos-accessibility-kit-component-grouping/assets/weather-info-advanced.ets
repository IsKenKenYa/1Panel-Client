/**
 * 天气信息组合组件扩展示例（API version 14+）
 * 演示accessibilityGroup14+的accessibilityPreferred功能
 * 场景：优先拼接无障碍文本进行播报
 */

@Entry
@Component
struct WeatherInfoAdvanced {
  build() {
    NavDestination() {
      Column() {
        // 示例1：不优先拼接无障碍文本（默认行为）
        Text('示例1：不优先拼接无障碍文本（默认）')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Column({ space: 10 }) {
          Text('123456')
            .focusable(true)
            .borderRadius(5)
            .accessibilityText('有accessibility有text优先读accessibility')
            .accessibilityLevel('yes')
          
          Button()
            .accessibilityLevel('yes')
            .accessibilityText('accessibility无text 读accessibility')
          
          Button('无accessibility有text 读text')
            .accessibilityLevel('yes')
          
          Button()
          
          Button('btn123')
            .accessibilityText('有accessibility有text btn123')
            .accessibilityLevel('yes')
          
          Button('btn123')
            .accessibilityLevel('yes')
        }
        .accessibilityGroup(true) // 默认不优先拼接accessibilityText
        .borderWidth(5)
        .width('100%')
        .height(200)
        .margin({ bottom: 30 })

        // 示例2：优先拼接无障碍文本（推荐）
        Text('示例2：优先拼接无障碍文本（推荐）')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Column({ space: 10 }) {
          Text('天气：晴')
            .focusable(true)
            .borderRadius(5)
            .accessibilityText('晴天') // 无障碍文本优先拼接
            .accessibilityLevel('yes')
          
          Button()
            .accessibilityLevel('yes')
            .accessibilityText('温度适宜') // 无障碍文本优先拼接
          
          Button('湿度60%')
            .accessibilityLevel('yes')
          
          Button()
          
          Button('风速5m/s')
            .accessibilityText('微风') // 无障碍文本优先拼接
            .accessibilityLevel('yes')
          
          Button('空气质量优')
            .accessibilityLevel('yes')
        }
        .accessibilityGroup(true, { accessibilityPreferred: true }) // 优先拼接accessibilityText
        .borderWidth(5)
        .width('100%')
        .height(200)
        .margin({ bottom: 30 })

        // 示例3：混合使用文本和无障碍文本
        Text('示例3：混合使用文本和无障碍文本')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Row() {
          Text('27 Dec 2023')
            .fontSize(32)
            .fontColor(Color.Blue)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 20 })
          
          Column()
            .backgroundColor(Color.Orange)
            .width(50)
            .height(50)
            .accessibilityText('晴天') // 无障碍文本
            .margin({ right: 20 })
          
          Text('28')
            .fontSize(20)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .accessibilityText('28度') // 无障碍文本覆盖原文本
        }
        .height(50)
        .margin({ bottom: 30 })
        .accessibilityGroup(true, { accessibilityPreferred: true })
        // 播报结果："27 Dec 2023 晴天 28度"（优先使用accessibilityText）

        // 示例4：复杂天气卡片
        Text('示例4：复杂天气卡片')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Column() {
          Row() {
            Text('北京')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .accessibilityText('北京市')
            
            Text('今天')
              .fontSize(18)
              .fontColor(Color.Gray)
              .accessibilityText('今日天气')
          }
          .margin({ bottom: 10 })
          
          Row() {
            Column()
              .backgroundColor(Color.Cyan)
              .width(80)
              .height(80)
              .accessibilityText('晴朗')
              .margin({ right: 20 })
            
            Text('25°C')
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .accessibilityText('25度')
            
            Column() {
              Text('湿度')
                .fontSize(14)
                .fontColor(Color.Gray)
              Text('65%')
                .fontSize(18)
                .accessibilityText('65百分之')
            }
            .margin({ left: 20 })
          }
        }
        .padding(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        .width('90%')
        .margin({ bottom: 30 })
        .accessibilityGroup(true, { accessibilityPreferred: true })
        // 播报结果："北京市 今日天气 晴朗 25度 65百分之"
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title('天气信息组合扩展示例')
  }
}