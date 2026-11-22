import { postCardAction } from '@ohos.app.form.formBindingData';

const TAG: string = 'TransparentWidgetCard';

@Entry
@Component
export struct TransparentWidgetCard {
  readonly title: string = '透明卡片示例';
  readonly actionType: string = 'router';
  readonly abilityName: string = 'EntryAbility';
  readonly message: string = 'transparent_widget_click';
  readonly fullWidthPercent: string = '100%';
  readonly fullHeightPercent: string = '100%';
  
  @LocalStorageProp('textColor') @Watch('onTextColorChange') textColor: string = '#FFFFFFFF';
  @LocalStorageProp('temperature') temperature: string = '22°C';
  @LocalStorageProp('time') currentTime: string = '14:30';
  
  build() {
    Stack() {
      Column() {
        Text(this.title)
          .fontSize('24vp')
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textColor)
          .margin({ bottom: '16vp' })
        
        Row() {
          Text(this.temperature)
            .fontSize('32vp')
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textColor)
            .margin({ right: '16vp' })
          
          Text(this.currentTime)
            .fontSize('20vp')
            .fontColor(this.textColor)
            .opacity(0.8)
        }
        .margin({ top: '8vp' })
        
        Button('刷新')
          .fontSize('16vp')
          .fontColor(this.textColor)
          .backgroundColor('rgba(255, 255, 255, 0.2)')
          .margin({ top: '16vp' })
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: {
                'method': 'refresh',
                'formId': 'current'
              }
            });
          })
      }
      .width(this.fullWidthPercent)
      .height(this.fullHeightPercent)
      .padding('16vp')
    }
    .width(this.fullWidthPercent)
    .height(this.fullHeightPercent)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      postCardAction(this, {
        action: this.actionType,
        abilityName: this.abilityName,
        params: {
          message: this.message
        }
      });
    })
  }
  
  private onTextColorChange(): void {
    console.info(TAG, `Text color changed to: ${this.textColor}`);
  }
}