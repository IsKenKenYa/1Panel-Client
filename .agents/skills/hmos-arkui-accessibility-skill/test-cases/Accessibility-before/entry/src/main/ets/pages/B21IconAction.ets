@Entry
@Component
struct B21IconAction {
  @State liked: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('B21 点赞图标')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text('《无障碍设计实践指南》')
        .fontSize(16)
      Image($r('app.media.like'))
        .width(48)
        .height(48)
        .fillColor(this.liked ? Color.Red : Color.Gray)
        .onClick(() => {
          this.liked = !this.liked;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
