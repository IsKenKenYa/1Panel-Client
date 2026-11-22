@Entry
@Component
struct B06DecorHeader {
  build() {
    Column({ space: 24 }) {
      Text('B06 装饰图标与三方容器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Row({ space: 12 }) {
        Image($r('app.media.decor'))
          .width(120)
          .height(24)
        Text('页面标题')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('90%')

      Button('返回')
        .fontSize(14)
        .width(96)
        .onClick(() => {
          // 返回上一页逻辑
        })

      Column({ space: 8 }) {
        Image($r('app.media.decor'))
          .width(200)
          .height(40)
        Text('三方推广位标题')
          .fontSize(16)
        Text('点击进入三方活动页面')
          .fontSize(12)
          .fontColor('#666666')
      }
      .padding(12)
      .borderRadius(12)
      .backgroundColor('#f5f5f5')
      .width('90%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
