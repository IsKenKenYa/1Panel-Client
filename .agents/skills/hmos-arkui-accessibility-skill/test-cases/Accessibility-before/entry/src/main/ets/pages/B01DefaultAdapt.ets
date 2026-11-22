@Entry
@Component
struct B01DefaultAdapt {
  build() {
    Column({ space: 24 }) {
      Text('设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text('当前版本：1.0.0')
        .fontSize(16)
        .fontColor('#666666')
      Button('保存设置')
        .width('60%')
        .onClick(() => {
          // 保存设置的核心逻辑
        })
      Button('恢复默认')
        .width('60%')
        .backgroundColor('#f0f0f0')
        .fontColor('#333333')
        .onClick(() => {
          // 恢复默认设置的核心逻辑
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
