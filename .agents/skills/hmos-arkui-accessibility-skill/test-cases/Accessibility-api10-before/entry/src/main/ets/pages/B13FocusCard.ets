@Entry
@Component
struct B13FocusCard {
  @State expanded: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B13 可聚焦卡片')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Column({ space: 8 }) {
        Text('张三')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('前端开发工程师 · 工号 1024')
          .fontSize(14)
          .fontColor('#666666')
        if (this.expanded) {
          Text('详细信息：负责 ArkUI 无障碍能力建设，联系方式 zhangsan@example.com')
            .fontSize(14)
            .fontColor('#666666')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding(16)
      .borderRadius(12)
      .backgroundColor('#f5f6f7')
      .width('85%')
      .onClick(() => {
        // 展开卡片详情
        this.expanded = !this.expanded;
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
