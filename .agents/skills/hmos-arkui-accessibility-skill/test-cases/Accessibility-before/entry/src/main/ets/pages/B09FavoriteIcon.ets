@Entry
@Component
struct B09FavoriteIcon {
  @State isFavorite: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B09 无文字收藏图标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text('蓝牙音箱 Hi-Fi 版')
        .fontSize(18)
      Image($r('app.media.favorite'))
        .width(48)
        .height(48)
        .fillColor(this.isFavorite ? Color.Orange : Color.Gray)
        .onClick(() => {
          this.isFavorite = !this.isFavorite;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
