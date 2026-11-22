let storageUpdateRouter = new LocalStorage();
@Entry(storageUpdateRouter)
@Component
struct WidgetUpdateRouterCard {
  @LocalStorageProp('routerDetail') routerDetail: ResourceStr = $r('app.string.init');
  
  build() {
    Column() {
      Column() {
        Text(this.routerDetail)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .fontSize(14)
          .margin({ top: '8%', left: '10%', right: '10%' })
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
      }
      .width('100%')
      .height('50%')
      .alignItems(HorizontalAlign.Start)
      
      Row() {
        Button() {
          Text($r('app.string.JumpLabel'))
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
            action: 'router',
            abilityName: 'WidgetEventRouterEntryAbility',
            params: {
              routerDetail: 'RouterFromCard'
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
    .alignItems(HorizontalAlign.Start)
    .backgroundImage($r('app.media.CardEvent'))
    .backgroundImageSize(ImageSize.Cover)
  }
}