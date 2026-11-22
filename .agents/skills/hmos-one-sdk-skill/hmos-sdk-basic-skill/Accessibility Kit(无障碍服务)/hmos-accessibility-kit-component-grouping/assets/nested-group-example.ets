/**
 * 嵌套分组示例
 * 演示多层组合场景的处理方法
 * 注意：建议避免三层以上的嵌套，本示例仅用于演示边界场景
 */

@Entry
@Component
struct NestedGroupExample {
  build() {
    NavDestination() {
      Column() {
        // 示例1：双层嵌套（推荐）
        Text('示例1：双层嵌套（推荐）')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Column() {
          // 第一层分组：日期组
          Row() {
            Text('2023年')
              .fontSize(20)
              .margin({ right: 10 })
            Text('12月')
              .fontSize(20)
              .margin({ right: 10 })
            Text('27日')
              .fontSize(20)
          }
          .accessibilityGroup(true)
          .accessibilityText('2023年12月27日')
          .margin({ bottom: 10 })
          
          // 第二层分组：天气组
          Row() {
            Column()
              .backgroundColor(Color.Yellow)
              .width(40)
              .height(40)
              .accessibilityText('晴天')
              .margin({ right: 15 })
            
            Text('25°C')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
            
            Column() {
              Text('湿度')
                .fontSize(14)
              Text('65%')
                .fontSize(16)
            }
            .margin({ left: 15 })
          }
          .accessibilityGroup(true)
          .accessibilityText('晴天，25度，湿度65%')
        }
        .accessibilityGroup(true) // 最外层分组
        .accessibilityText('天气信息：2023年12月27日，晴天，25度，湿度65%')
        .padding(15)
        .backgroundColor('#F0F0F0')
        .borderRadius(10)
        .width('90%')
        .margin({ bottom: 30 })

        // 示例2：三层嵌套（边界场景，谨慎使用）
        Text('示例2：三层嵌套（边界场景）')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Column() {
          // 第一层：城市信息
          Row() {
            Text('北京')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
            Text('华北地区')
              .fontSize(16)
              .fontColor(Color.Gray)
          }
          .accessibilityGroup(true)
          .accessibilityText('北京，华北地区')
          .margin({ bottom: 10 })
          
          // 第二层：天气详情
          Column() {
            Row() {
              Column()
                .backgroundColor(Color.Cyan)
                .width(60)
                .height(60)
                .accessibilityText('晴朗')
                .margin({ right: 20 })
              
              Text('25°C')
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
            }
            .accessibilityGroup(true)
            .accessibilityText('晴朗，25度')
            .margin({ bottom: 10 })
            
            // 第三层：详细信息（谨慎使用三层嵌套）
            Row() {
              Text('湿度：65%')
                .fontSize(16)
                .margin({ right: 20 })
              Text('风速：5m/s')
                .fontSize(16)
                .margin({ right: 20 })
              Text('气压：1013hPa')
                .fontSize(16)
            }
            .accessibilityGroup(true)
            .accessibilityText('湿度65%，风速5米每秒，气压1013')
          }
          .accessibilityGroup(true)
          .accessibilityText('天气详情：晴朗25度，湿度65%，风速5米每秒，气压1013')
        }
        .accessibilityGroup(true)
        .accessibilityText('北京华北地区天气：晴朗25度，湿度65%，风速5米每秒，气压1013')
        .padding(15)
        .backgroundColor('#E8E8E8')
        .borderRadius(10)
        .width('90%')
        .margin({ bottom: 30 })

        // 示例3：避免过度嵌套的替代方案
        Text('示例3：避免过度嵌套的替代方案')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Column() {
          // 方案1：使用列表组件代替多层分组
          List() {
            ListItem() {
              Row() {
                Text('城市：北京')
                  .fontSize(18)
                Text('地区：华北')
                  .fontSize(18)
                  .fontColor(Color.Gray)
              }
              .accessibilityGroup(true)
              .accessibilityText('城市北京，华北地区')
              .width('100%')
            }
            
            ListItem() {
              Row() {
                Column()
                  .backgroundColor(Color.Yellow)
                  .width(50)
                  .height(50)
                  .accessibilityText('晴')
                Text('温度：25°C')
                  .fontSize(18)
                  .margin({ left: 20 })
              }
              .accessibilityGroup(true)
              .accessibilityText('晴天，温度25度')
              .width('100%')
            }
            
            ListItem() {
              Row() {
                Text('湿度：65%')
                  .fontSize(18)
                Text('风速：5m/s')
                  .fontSize(18)
                  .margin({ left: 20 })
                Text('气压：1013hPa')
                  .fontSize(18)
                  .margin({ left: 20 })
              }
              .accessibilityGroup(true)
              .accessibilityText('湿度65%，风速5米每秒，气压1013')
              .width('100%')
            }
          }
          .width('90%')
          .height(180)
          .backgroundColor('#F5F5F5')
          .borderRadius(10)
          
          // 方案2：扁平化结构
          Text('扁平化结构示例：')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20, bottom: 10 })
          
          Row() {
            Column()
              .backgroundColor(Color.Orange)
              .width(50)
              .height(50)
              .accessibilityText('晴')
            Text('北京 25°C')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 20 })
          }
          .accessibilityGroup(true)
          .accessibilityText('北京天气：晴天，25度')
          .padding(15)
          .backgroundColor('#D8D8D8')
          .borderRadius(10)
          .width('90%')
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title('嵌套分组示例')
  }
}