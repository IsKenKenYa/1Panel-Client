import { ScrollJankSubscription } from './scroll_jank_subscription_example';

@Entry
@Component
struct ListScrollTest {
  private subscription: ScrollJankSubscription = new ScrollJankSubscription();
  private data: number[] = Array.from({length: 100}, (_, i) => i);
  private simulateJank: boolean = false;

  aboutToAppear(): void {
    this.subscription.subscribe();
  }

  aboutToDisappear(): void {
    this.subscription.unsubscribe();
  }

  build() {
    Column() {
      Row() {
        Toggle({ type: ToggleType.Checkbox, isOn: this.simulateJank })
          .onChange((isOn: boolean) => {
            this.simulateJank = isOn;
          })
        Text('模拟卡顿')
          .fontSize(16)
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(10)
      .backgroundColor(0xF0F0F0)

      List({ space: 10 }) {
        ForEach(this.data, (item: number) => {
          ListItem() {
            Text('Item ' + item)
              .width('100%')
              .height(100)
              .fontSize(20)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .borderRadius(10)
              .backgroundColor(0x007DFF)
          }
        })
      }
      .width('100%')
      .height('80%')
      .onScrollIndex((firstIndex: number) => {
        if (this.simulateJank) {
          this.simulateScrollJank();
        }
      })
      .onScroll(() => {
        if (this.simulateJank) {
          this.simulateScrollJank();
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  private simulateScrollJank(): void {
    let i = 1;
    while (i < 20000) {
      console.log('模拟耗时操作: ' + i);
      i++;
    }
  }
}

@Entry
@Component
struct ScrollJankTestPage {
  private subscription: ScrollJankSubscription = new ScrollJankSubscription();

  build() {
    Column() {
      Text('滑动丢帧事件测试')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      Text('使用说明:')
        .fontSize(18)
        .margin({ bottom: 10 })

      Text('1. 快速滑动列表触发系统检测')
        .fontSize(16)
        .margin({ bottom: 5 })

      Text('2. 单次卡顿超过50ms会触发事件')
        .fontSize(16)
        .margin({ bottom: 5 })

      Text('3. 事件间隔5~35秒')
        .fontSize(16)
        .margin({ bottom: 5 })

      Text('4. 查看hilog日志获取事件数据')
        .fontSize(16)
        .margin({ bottom: 20 })

      Divider()

      ListScrollTest()
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}