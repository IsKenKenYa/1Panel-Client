@Entry
@Component
struct B23ThemeList {
  @State selectedIndex: number = 0;
  private themes: string[] = ['浅色模式', '深色模式', '跟随系统'];

  build() {
    Column({ space: 24 }) {
      Text('B23 主题单选列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      List({ space: 8 }) {
        ForEach(this.themes, (theme: string, index: number) => {
          ListItem() {
            Row({ space: 12 }) {
              Text(theme)
                .fontSize(16)
                .layoutWeight(1)
              if (this.selectedIndex === index) {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#007dfe')
              }
            }
            .padding(14)
            .borderRadius(10)
            .backgroundColor(this.selectedIndex === index ? '#eef5ff' : '#f5f6f7')
            .onClick(() => {
              this.selectedIndex = index;
            })
          }
        }, (theme: string) => theme)
      }
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
