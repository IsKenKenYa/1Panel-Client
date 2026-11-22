@Entry
@Component
struct WidgetCard {
  build() {
    Row() {
      Column() {
        Text($r('app.string.liveform_click1'))
          .fontSize($r('app.float.font_size'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')
    }
    .height('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'message',
        abilityName: 'EntryFormAbility',
        params: {
          message: 'requestOverflow'
        }
      });
    })
  }
}