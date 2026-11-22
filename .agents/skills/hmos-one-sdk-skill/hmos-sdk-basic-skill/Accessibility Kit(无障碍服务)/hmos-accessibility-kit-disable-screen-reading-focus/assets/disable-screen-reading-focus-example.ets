/**
 * 禁用屏幕朗读焦点完整示例
 * 本示例演示如何设置装饰性控件的无障碍属性，使其在屏幕朗读模式下不获取焦点
 */

@Entry
@Component
struct DisableScreenReadingFocusExample {
  @State message: string = 'Broadcast';
  @State message1: string = 'No broadcast';

  build() {
    NavDestination() {
      Column() {
        // 示例1：功能性控件，可以被聚焦和朗读
        Row() {
          Text(this.message)
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Blue)
            .margin({ left: 40 })
        }
        .width('100%')
        .height('50%')

        // 示例2：装饰性控件，不被聚焦和朗读
        Row() {
          Text(this.message1)
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Grey)
            .margin({ left: 40 })
            .accessibilityLevel("no")  // 设置组件不可聚焦
        }
        .width('100%')
        .height('50%')
      }
      .height('100%')
    }
    .title('禁用屏幕朗读焦点示例')
  }
}

/**
 * 示例3：装饰性图标
 */
@Component
struct DecorativeIconExample {
  build() {
    Column() {
      // 功能性按钮
      Button('功能按钮')
        .width(200)
        .height(50)
        .margin({ bottom: 20 })

      // 装饰性图标，不朗读
      Image($r('app.media.decorative_icon'))
        .width(50)
        .height(50)
        .accessibilityLevel("no")  // 设置装饰性图标不可聚焦

      // 功能性文本
      Text('这是功能性文本')
        .fontSize(20)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 示例4：装饰性容器（包含多个子组件）
 */
@Component
struct DecorativeContainerExample {
  build() {
    Column() {
      // 功能性标题
      Text('页面标题')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 装饰性分隔线
      Divider()
        .width('80%')
        .color('#E0E0E0')
        .accessibilityLevel("no")  // 分隔线不朗读

      // 装饰性容器（包含多个装饰性元素）
      Row() {
        Image($r('app.media.decorative_icon1'))
          .width(30)
          .height(30)
        
        Image($r('app.media.decorative_icon2'))
          .width(30)
          .height(30)
        
        Text('装饰性文本')
          .fontSize(16)
          .fontColor('#999999')
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.Center)
      .accessibilityLevel("no-hide-descendants")  // 整个Row及其子组件不可聚焦

      // 功能性内容
      Text('功能性内容区域')
        .fontSize(20)
        .margin({ top: 30 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}

/**
 * 示例5：混合场景（装饰性和功能性组件混合）
 */
@Component
struct MixedContainerExample {
  build() {
    Column() {
      // 功能性标题
      Text('功能列表')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 混合容器
      Row() {
        // 装饰性图标，不朗读
        Image($r('app.media.decorative_icon'))
          .width(40)
          .height(40)
          .accessibilityLevel("no")

        // 功能性按钮，需要朗读
        Button('点击操作')
          .width(150)
          .height(40)
          .margin({ left: 20 })
          .accessibilityLevel("yes")  // 明确设置为可聚焦

        // 装饰性占位符
        Blank()
          .accessibilityLevel("no")  // 占位符不朗读
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20 })
      .accessibilityGroup(true)  // 设置为无障碍组，但不影响子组件的"yes"设置

      // 功能性按钮列表
      Column() {
        Button('功能按钮1')
          .width('90%')
          .height(50)
          .margin({ bottom: 10 })

        Button('功能按钮2')
          .width('90%')
          .height(50)
          .margin({ bottom: 10 })

        Button('功能按钮3')
          .width('90%')
          .height(50)
      }
      .width('100%')
      .margin({ top: 30 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}

/**
 * 示例6：完整页面示例
 */
@Entry
@Component
struct CompletePageExample {
  @State itemList: string[] = ['项目1', '项目2', '项目3', '项目4', '项目5'];

  build() {
    Column() {
      // 页面标题（功能性）
      Text('完整页面示例')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      // 装饰性分隔线
      Divider()
        .width('90%')
        .color('#CCCCCC')
        .accessibilityLevel("no")

      // 装饰性头部区域
      Row() {
        // 装饰性图标
        Image($r('app.media.header_icon'))
          .width(60)
          .height(60)
          .accessibilityLevel("no")

        // 装饰性副标题
        Text('装饰性副标题')
          .fontSize(18)
          .fontColor('#666666')
          .margin({ left: 15 })
      }
      .width('90%')
      .height(80)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 10 })
      .accessibilityGroup(true)
      .accessibilityLevel("no")  // 整个装饰性区域不朗读

      // 功能性列表
      List() {
        ForEach(this.itemList, (item: string) => {
          ListItem() {
            Row() {
              // 功能性文本
              Text(item)
                .fontSize(20)
                .width('70%')

              // 功能性按钮
              Button('详情')
                .width(80)
                .height(35)
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .padding({ left: 20, right: 20 })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 20 })

      // 装饰性底部区域
      Row() {
        // 装饰性图标
        Image($r('app.media.footer_icon1'))
          .width(30)
          .height(30)
          .accessibilityLevel("no")

        Blank()
          .width(20)
          .accessibilityLevel("no")

        Image($r('app.media.footer_icon2'))
          .width(30)
          .height(30)
          .accessibilityLevel("no")
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.Center)
      .backgroundImage($r('app.media.footer_background'))
      .accessibilityLevel("no-hide-descendants")  // 整个底部区域不朗读
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}