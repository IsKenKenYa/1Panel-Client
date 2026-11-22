import testNapi from 'libentry.so';
import { subscribeAppHiCollieEvent, unsubscribeAppHiCollieEvent } from '../example_subscribe.ets';

let watcher: hiAppEvent.Watcher;

@Entry
@Component
struct Index {
  @State message: string = 'HiCollie Event Test';
  @State subscribed: boolean = false;
  
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        Button("Subscribe APP_HICOLLIE")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
          .onClick(() => {
            if (!this.subscribed) {
              subscribeAppHiCollieEvent();
              this.subscribed = true;
            }
          })
        
        Button("Trigger Timeout Event")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
          .onClick(testNapi.TriggerTimeoutEvent)
        
        Button("Unsubscribe")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            if (this.subscribed) {
              unsubscribeAppHiCollieEvent(watcher);
              this.subscribed = false;
            }
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}