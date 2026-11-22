let storageUpdateCall = new LocalStorage();
@Entry(storageUpdateCall)
@Component
struct WidgetUpdateCallCard {
  @LocalStorageProp('formId') formId: string = '12400633174999288';
  @LocalStorageProp('calleeDetail') calleeDetail: ResourceStr = $r('app.string.init');
  
  build() {
    Column() {
      Column() {
        Text(this.calleeDetail)
          .fontColor('#FFFFFF')
          .opacity(0.9)
          .fontSize(14)
          .margin({ top: '8%', left: '10%' })
      }
      .width('100%')
      .height('50%')
      .alignItems(HorizontalAlign.Start)
      
      Row() {
        Button() {
          Text($r('app.string.CalleeJumpLabel'))
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
            action: 'call',
            abilityName: 'WidgetCalleeEntryAbility',
            params: {
              method: 'funA',
              formId: this.formId,
              calleeDetail: 'CallFrom'
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