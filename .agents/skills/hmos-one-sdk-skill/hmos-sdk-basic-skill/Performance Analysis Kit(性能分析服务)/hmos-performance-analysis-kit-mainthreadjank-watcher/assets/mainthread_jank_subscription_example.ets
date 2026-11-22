// 主线程超时事件订阅完整示例
// 本示例演示如何使用HiAppEvent订阅主线程超时事件

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { buffer, util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct MainPage {
  private watcherName: string = "mainthreadJankWatcher";

  aboutToAppear() {
    // 在页面加载时添加订阅
    this.addMainThreadJankWatcher();
  }

  aboutToDisappear() {
    // 在页面卸载时移除订阅
    this.removeMainThreadJankWatcher();
  }

  // 添加主线程超时事件观察者
  addMainThreadJankWatcher(): void {
    try {
      hiAppEvent.addWatcher({
        name: this.watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.MAIN_THREAD_JANK]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.info(0x0000, 'MainThreadJank', `onReceive: domain=${domain}`);
          for (const eventGroup of appEventGroups) {
            hilog.info(0x0000, 'MainThreadJank', `eventName=${eventGroup.name}`);
            for (const eventInfo of eventGroup.appEventInfos) {
              this.processMainThreadJankEvent(eventInfo);
            }
          }
        }
      });
      hilog.info(0x0000, 'MainThreadJank', 'Watcher added successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'MainThreadJank', `Failed to add watcher: ${err.message}`);
    }
  }

  // 处理主线程超时事件
  processMainThreadJankEvent(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(0x0000, 'MainThreadJank', `domain=${eventInfo.domain}`);
    hilog.info(0x0000, 'MainThreadJank', `name=${eventInfo.name}`);
    hilog.info(0x0000, 'MainThreadJank', `eventType=${eventInfo.eventType}`);
    
    // 获取事件时间戳
    const time: number = eventInfo.params['time'] as number;
    hilog.info(0x0000, 'MainThreadJank', `time=${time}`);
    
    // 获取应用信息
    const bundleVersion: string = eventInfo.params['bundle_version'] as string;
    const bundleName: string = eventInfo.params['bundle_name'] as string;
    const pid: number = eventInfo.params['pid'] as number;
    const uid: number = eventInfo.params['uid'] as number;
    hilog.info(0x0000, 'MainThreadJank', `bundle_version=${bundleVersion}`);
    hilog.info(0x0000, 'MainThreadJank', `bundle_name=${bundleName}`);
    hilog.info(0x0000, 'MainThreadJank', `pid=${pid}, uid=${uid}`);
    
    // 获取超时时间范围
    const beginTime: number = eventInfo.params['begin_time'] as number;
    const endTime: number = eventInfo.params['end_time'] as number;
    hilog.info(0x0000, 'MainThreadJank', `begin_time=${beginTime}`);
    hilog.info(0x0000, 'MainThreadJank', `end_time=${endTime}`);
    
    // 获取调用栈信息（采样栈）
    const appStartJiffiesTime: string = JSON.stringify(eventInfo.params['app_start_jiffies_time']);
    const heaviestStack: string = eventInfo.params['heaviest_stack'] as string;
    hilog.info(0x0000, 'MainThreadJank', `app_start_jiffies_time=${appStartJiffiesTime}`);
    hilog.info(0x0000, 'MainThreadJank', `heaviest_stack=${heaviestStack}`);
    
    // 获取日志文件
    const externalLog: string[] = eventInfo.params['external_log'] as string[];
    hilog.info(0x0000, 'MainThreadJank', `external_log=${JSON.stringify(externalLog)}`);
    
    // 移动日志文件到自定义目录
    if (externalLog && externalLog.length > 0) {
      this.moveLogFile(externalLog[0]);
    }
  }

  // 移动日志文件
  moveLogFile(sourcePath: string): void {
    try {
      let targetPath: string = "";
      if (sourcePath.endsWith(".txt")) {
        targetPath = "/data/storage/el2/base/mainThreadJank.txt";
      } else if (sourcePath.endsWith(".trace")) {
        targetPath = "/data/storage/el2/base/mainThreadJank.trace";
      }
      
      if (targetPath) {
        fileIo.copyFileSync(sourcePath, targetPath);
        hilog.info(0x0000, 'MainThreadJank', `Log file moved to ${targetPath}`);
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'MainThreadJank', `Failed to move log file: ${err.message}`);
    }
  }

  // 移除观察者
  removeMainThreadJankWatcher(): void {
    try {
      let watcher: hiAppEvent.Watcher = {
        name: this.watcherName
      };
      hiAppEvent.removeWatcher(watcher);
      hilog.info(0x0000, 'MainThreadJank', 'Watcher removed successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'MainThreadJank', `Failed to remove watcher: ${err.message}`);
    }
  }

  build() {
    Column() {
      Text('主线程超时事件订阅示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      Button('触发350ms超时')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          let t = Date.now();
          while (Date.now() - t <= 350) {}
        });
      
      Button('触发500ms超时')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          let t = Date.now();
          while (Date.now() - t <= 500) {}
        });
    }
    .width('100%')
    .height('100%');
  }
}