import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  build() {
    RelativeContainer() {
      Column() {
        Text('应用冻屏告警事件测试')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin(20)
        
        Button("触发冻屏告警事件", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            // 在按钮点击函数中构造冻屏场景,触发应用冻屏告警事件
            hilog.info(0x0000, 'testTag', 'Triggering freeze event...');
            const t = Date.now();
            while (Date.now() - t <= 6500) {}
            hilog.info(0x0000, 'testTag', 'Freeze event triggered');
          })
        
        Button("移除冻屏观察者", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            // 移除冻屏观察者取消订阅
            this.removeFreezeWatcher();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
    .width('100%')
  }

  // 移除冻屏观察者
  private removeFreezeWatcher(): void {
    try {
      let watcher: hiAppEvent.Watcher = {
        name: "freezeWatcher",
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_FREEZE]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          // 回调函数
        }
      };
      
      hiAppEvent.removeWatcher(watcher);
      hilog.info(0x0000, 'testTag', 'Freeze watcher removed successfully');
    } catch (error) {
      hilog.error(0x0000, 'testTag', `Failed to remove freeze watcher: code=${error.code}, message=${error.message}`);
    }
  }
}