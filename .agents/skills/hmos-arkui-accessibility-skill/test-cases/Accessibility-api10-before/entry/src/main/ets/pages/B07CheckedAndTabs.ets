@Entry
@Component
struct B07CheckedAndTabs {
  @State isOn: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B07 开关与标签页')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Row({ space: 12 }) {
        Text('消息通知')
          .fontSize(16)
        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .onChange((value: boolean) => {
            this.isOn = value;
          })
      }

      Tabs() {
        TabContent() {
          Text('首页内容区域')
            .fontSize(16)
        }
        .tabBar('首页')

        TabContent() {
          Text('推荐内容区域')
            .fontSize(16)
        }
        .tabBar('推荐')

        TabContent() {
          Text('我的内容区域')
            .fontSize(16)
        }
        .tabBar('我的')
      }
      .width('90%')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
