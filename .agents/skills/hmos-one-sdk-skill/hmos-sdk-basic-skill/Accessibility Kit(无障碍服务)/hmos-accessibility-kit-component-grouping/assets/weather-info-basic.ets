/**
 * 天气信息组合组件示例（API version 10+）
 * 演示如何使用accessibilityGroup将多个组件组合为一个无障碍焦点
 * 场景：日期、天气图标、温度组合为一个天气信息焦点
 */

@Entry
@Component
struct WeatherInfoBasic {
  build() {
    NavDestination() {
      Column() {
        // 示例1：未组合的独立组件（不推荐）
        Text('示例1：未组合的独立组件（不推荐）')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Row() {
          // 每个组件独立获焦和朗读，造成信息冗余
          Text('23 Dec 2023')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({ right: 20 })
          
          Column()
            .backgroundColor(Color.Blue)
            .width(50)
            .height(50)
            .accessibilityText('Snow')
            .margin({ right: 20 })
          
          Text('-1')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        .height(50)
        .margin({ bottom: 30 })

        // 示例2：组合后的组件（推荐）
        Text('示例2：组合后的组件（推荐）')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Row() {
          // 设置accessibilityGroup(true)后，整个Row为一个焦点
          // 子组件无法独立获焦，朗读时合并播报所有文本
          Text('24 Dec 2023')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({ right: 20 })
          
          Column()
            .backgroundColor(Color.Yellow)
            .width(50)
            .height(50)
            .accessibilityText('Sunny')
            .margin({ right: 20 })
          
          Text('-7')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        .height(50)
        .margin({ bottom: 30 })
        .accessibilityGroup(true) // 启用无障碍分组

        // 示例3：自定义播报内容
        Text('示例3：自定义播报内容')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Row() {
          Text('25 Dec 2023')
            .fontSize(32)
            .fontColor(Color.Orange)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 20 })
          
          Column()
            .backgroundColor(Color.Cyan)
            .width(50)
            .height(50)
            .accessibilityText('Cloudy')
            .margin({ right: 20 })
          
          Text('15')
            .fontSize(20)
            .fontColor(Color.Purple)
            .fontWeight(FontWeight.Bold)
        }
        .height(50)
        .margin({ bottom: 30 })
        .accessibilityGroup(true)
        .accessibilityText('12月25日，多云，15度') // 自定义播报内容

        // 示例4：部分子组件保持独立焦点
        Text('示例4：部分子组件保持独立焦点')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Row() {
          Text('26 Dec 2023')
            .fontSize(32)
            .fontColor(Color.Pink)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 20 })
          
          Column()
            .backgroundColor(Color.Magenta)
            .width(50)
            .height(50)
            .accessibilityText('Rainy')
            .margin({ right: 20 })
          
          Text('20')
            .fontSize(20)
            .fontColor(Color.Brown)
            .fontWeight(FontWeight.Bold)
          
          // 重要操作按钮保持独立焦点
          Button('详情')
            .fontSize(14)
            .margin({ left: 20 })
            .accessibilityLevel('yes') // 不受分组约束，可独立获焦
        }
        .height(50)
        .accessibilityGroup(true)
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title('天气信息组合示例')
  }
}