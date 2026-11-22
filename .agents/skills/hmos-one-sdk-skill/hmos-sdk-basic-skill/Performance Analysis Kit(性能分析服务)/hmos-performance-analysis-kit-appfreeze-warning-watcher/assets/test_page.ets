import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { FreezeWatcherManager } from './appfreeze_watcher_example.ets';

@Entry
@Component
struct FreezeTestPage {
  private freezeWatcherManager: FreezeWatcherManager = new FreezeWatcherManager();

  aboutToAppear(): void {
    this.freezeWatcherManager.addFreezeWatcher();
  }

  aboutToDisappear(): void {
    this.freezeWatcherManager.removeFreezeWatcher();
  }

  build() {
    Column({ space: 20 }) {
      Text('应用冻屏告警测试页面')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })

      Text('点击下方按钮触发冻屏告警事件')
        .fontSize(16)
        .margin({ bottom: 20 })

      Button('触发冻屏告警（阻塞6.5秒）')
        .width('80%')
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.triggerFreezeWarning();
        })

      Button('检查订阅状态')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.checkWatcherStatus();
        })

      Button('重新订阅')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.freezeWatcherManager.removeFreezeWatcher();
          this.freezeWatcherManager.addFreezeWatcher();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
  }

  private triggerFreezeWarning(): void {
    hilog.info(0x0000, 'freezeTag', 'Start blocking main thread for 6.5 seconds');

    const startTime = Date.now();
    while (Date.now() - startTime <= 6500) {
    }

    hilog.info(0x0000, 'freezeTag', 'Main thread blocking ended');
    hilog.info(0x0000, 'freezeTag', 'Please wait about 1 minute for freeze event callback');
  }

  private checkWatcherStatus(): void {
    const isWatching = this.freezeWatcherManager.getWatchingStatus();
    if (isWatching) {
      hilog.info(0x0000, 'freezeTag', 'Watcher is active');
    } else {
      hilog.warn(0x0000, 'freezeTag', 'Watcher is not active');
    }
  }
}