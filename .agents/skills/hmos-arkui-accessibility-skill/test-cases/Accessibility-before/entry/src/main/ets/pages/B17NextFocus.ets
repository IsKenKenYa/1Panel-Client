@Entry
@Component
struct B17NextFocus {
  build() {
    Column({ space: 16 }) {
      Text('B17 注册表单')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '姓名' })
        .width('85%')
      TextInput({ placeholder: '邮箱' })
        .width('85%')
      TextInput({ placeholder: '手机号' })
        .width('85%')
      Button('注册')
        .width('60%')
        .onClick(() => {
          // 注册核心逻辑
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
