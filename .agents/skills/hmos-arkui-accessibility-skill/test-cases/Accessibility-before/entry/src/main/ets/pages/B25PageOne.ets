import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct B25PageOne {
  @StorageLink('b25Content') content: string = 'Text1';

  build() {
    Column({ space: 24 }) {
      Button('change content')
        .onClick(() => {
          this.content = '';
        })

      Button('go to next page').fontSize(30)
        .onClick(() => {
          this.getUIContext().getRouter().pushUrl({ url: 'pages/B25PageTwo' }, (err: Error) => {
            if (err) {
              hilog.error(0x0000, 'test', 'pushUrl failed. Cause: %{public}s', JSON.stringify(err));
            }
          });
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
