// entry/src/main/ets/widget/pages/WidgetImageUpdateCard.ets
// ArkTS卡片图片刷新完整示例 - 卡片页面实现

let storageWidgetImageUpdate = new LocalStorage();

@Entry(storageWidgetImageUpdate)
@Component
struct WidgetImageUpdateCard {
  @LocalStorageProp('text') text: ResourceStr = $r('app.string.loading');
  @LocalStorageProp('loaded') loaded: boolean = false;
  @LocalStorageProp('imgName') imgName: ResourceStr = $r('app.string.imgName');
  
  build() {
    Column() {
      Column() {
        Text(this.text)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .fontSize(12)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .margin({ top: '8%', left: '10%' })
      }
      .width('100%')
      .height('50%')
      .alignItems(HorizontalAlign.Start)
      
      Row() {
        Button() {
          Text($r('app.string.update'))
            .fontColor('#45A6F4')
            .fontSize(12)
        }
        .width(120)
        .height(32)
        .margin({ top: '30%', bottom: '10%' })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: {
              info: 'refreshImage'
            }
          });
        })
      }
      .width('100%')
      .height('40%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundImage(this.loaded ? 'memory://' + this.imgName : $r('app.media.ImageDisp'))
    .backgroundImageSize(ImageSize.Cover)
  }
}