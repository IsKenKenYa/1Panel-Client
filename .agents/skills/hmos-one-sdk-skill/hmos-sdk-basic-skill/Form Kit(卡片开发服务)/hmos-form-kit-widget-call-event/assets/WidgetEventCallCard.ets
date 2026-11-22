// src/main/ets/widgeteventcall/pages/WidgetEventCallCard.ets
import { hilog } from '@kit.PerformanceAnalysisKit';

let storageEventCall = new LocalStorage();
const TAG: string = 'WidgetEventCallCard';
const DOMAIN_NUMBER: number = 0xFF00;

@Entry(storageEventCall)
@Component
struct WidgetEventCallCard {
  @LocalStorageProp('formId') formId: string = '12400633174999288';
  @LocalStorageProp('title') title: string = '卡片控制';
  
  build() {
    RelativeContainer() {
      Text(this.title)
        .id('title__')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .margin({ top: 20 })
      
      Button('播放')
        .id('play__')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('80%')
        .height(40)
        .backgroundColor('#007DFF')
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .margin({ top: 60 })
        .onClick(() => {
          try {
            postCardAction(this, {
              action: 'call',
              abilityName: 'WidgetEventCallEntryAbility',
              params: {
                formId: this.formId,
                method: 'play'
              }
            });
            hilog.info(DOMAIN_NUMBER, TAG, 'Play button clicked');
          } catch (error) {
            hilog.error(DOMAIN_NUMBER, TAG, `Play action failed: ${error.message}`);
          }
        })
      
      Button('暂停')
        .id('pause__')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('80%')
        .height(40)
        .backgroundColor('#007DFF')
        .alignRules({
          top: { anchor: 'play__', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .margin({ top: 10 })
        .onClick(() => {
          try {
            postCardAction(this, {
              action: 'call',
              abilityName: 'WidgetEventCallEntryAbility',
              params: {
                formId: this.formId,
                method: 'pause'
              }
            });
            hilog.info(DOMAIN_NUMBER, TAG, 'Pause button clicked');
          } catch (error) {
            hilog.error(DOMAIN_NUMBER, TAG, `Pause action failed: ${error.message}`);
          }
        })
      
      Button('下一首')
        .id('next__')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .width('80%')
        .height(40)
        .backgroundColor('#007DFF')
        .alignRules({
          top: { anchor: 'pause__', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .margin({ top: 10 })
        .onClick(() => {
          try {
            postCardAction(this, {
              action: 'call',
              abilityName: 'WidgetEventCallEntryAbility',
              params: {
                formId: this.formId,
                method: 'next',
                songIndex: 1
              }
            });
            hilog.info(DOMAIN_NUMBER, TAG, 'Next button clicked');
          } catch (error) {
            hilog.error(DOMAIN_NUMBER, TAG, `Next action failed: ${error.message}`);
          }
        })
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F1F3F5')
  }
}