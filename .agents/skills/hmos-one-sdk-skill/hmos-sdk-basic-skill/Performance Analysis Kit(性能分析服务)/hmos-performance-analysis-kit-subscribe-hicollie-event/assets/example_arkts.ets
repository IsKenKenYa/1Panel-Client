import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('HiCollie事件订阅示例')
        .fontSize(24)
        .margin({ top: 20 })
      
      Button('注册观察者R')
        .onClick(() => {
          testNapi.RegisterAppHicollieWatcherR();
        })
        .margin({ top: 20 })
      
      Button('注册观察者T')
        .onClick(() => {
          testNapi.RegisterAppHicollieWatcherT();
        })
        .margin({ top: 20 })
      
      Button('触发任务超时事件')
        .onClick(() => {
          testNapi.TestHiCollieTimerNdk();
        })
        .margin({ top: 20 })
      
      Button('移除观察者')
        .onClick(() => {
          testNapi.RemoveWatcher();
        })
        .margin({ top: 20 })
      
      Button('销毁观察者')
        .onClick(() => {
          testNapi.DestroyWatcher();
        })
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
  }
}

export default class EntryAbility {
  onCreate(want, launchParam) {
    testNapi.RegisterAppHicollieWatcherR();
    testNapi.RegisterAppHicollieWatcherT();
  }
  
  onDestroy() {
    testNapi.RemoveWatcher();
    testNapi.DestroyWatcher();
  }
}