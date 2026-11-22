@Entry
@Component
struct Index {
  build() {
    RelativeContainer() {
      Column() {
        Text('App Freeze Warning Test')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
        
        Button("Trigger App Freeze Warning", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            const t = Date.now();
            while (Date.now() - t <= 6500) {}
          })
        
        Text('Click button to trigger app freeze (6.5 seconds)')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 10 })
      }
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}