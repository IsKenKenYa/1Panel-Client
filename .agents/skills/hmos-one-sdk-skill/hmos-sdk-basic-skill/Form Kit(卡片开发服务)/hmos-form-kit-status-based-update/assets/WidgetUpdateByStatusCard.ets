let storageUpdateByStatus = new LocalStorage();
@Entry(storageUpdateByStatus)
@Component
struct WidgetUpdateByStatusCard {
  @LocalStorageProp('textA') textA: Resource = $r('app.string.to_be_refreshed');
  @LocalStorageProp('textB') textB: Resource = $r('app.string.to_be_refreshed');
  @State selectA: boolean = false;
  @State selectB: boolean = false;

  build() {
    Column() {
      Column() {
        Row() {
          Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
            .padding(0)
            .select(false)
            .margin({ left: 26 })
            .onChange((value: boolean) => {
              this.selectA = value;
              postCardAction(this, {
                action: 'message',
                params: {
                  selectA: JSON.stringify(value)
                }
              });
            })
          Text($r('app.string.status_a'))
            .fontColor('#000000')
            .opacity(0.9)
            .fontSize(14)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding(0)
        .justifyContent(FlexAlign.Start)

        Row() {
          Checkbox({ name: 'checkbox2', group: 'checkboxGroup' })
            .padding(0)
            .select(false)
            .margin({ left: 26 })
            .onChange((value: boolean) => {
              this.selectB = value;
              postCardAction(this, {
                action: 'message',
                params: {
                  selectB: JSON.stringify(value)
                }
              });
            })
          Text($r('app.string.status_b'))
            .fontColor('#000000')
            .opacity(0.9)
            .fontSize(14)
            .margin({ left: 8 })
        }
        .width('100%')
        .position({ y: 32 })
        .padding(0)
        .justifyContent(FlexAlign.Start)
      }
      .position({ y: 12 })

      Column() {
        Row() {
          Text($r('app.string.status_a'))
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
          Text(this.textA)
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
        }
        .margin({ top: '12px', left: 26, right: '26px' })

        Row() {
          Text($r('app.string.status_b'))
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
          Text(this.textB)
            .fontColor('#000000')
            .opacity(0.4)
            .fontSize(12)
        }
        .margin({
          top: '12px',
          bottom: '21px',
          left: 26,
          right: '26px'
        })
      }
      .margin({ top: 80 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundImage($r('app.media.CardUpdateByStatus'))
    .backgroundImageSize(ImageSize.Cover)
  }
}