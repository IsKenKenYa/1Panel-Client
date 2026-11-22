@Entry
@Component
struct B16DefaultFocus {
  build() {
    Column({ space: 16 }) {
      Text('B16 商品搜索')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '请输入要搜索的商品' })
        .width('85%')
      List({ space: 8 }) {
        ListItem() {
          Text('商品 A - 已售 1024')
            .fontSize(16)
        }
        ListItem() {
          Text('商品 B - 已售 512')
            .fontSize(16)
        }
        ListItem() {
          Text('商品 C - 已售 256')
            .fontSize(16)
        }
      }
      .width('85%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
