import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { buffer, util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct MainThreadJankWatcherExample {
  private watcherName: string = "mainThreadJankWatcher";

  aboutToAppear() {
    this.addMainThreadJankWatcher();
  }

  aboutToDisappear() {
    this.removeMainThreadJankWatcher();
  }

  addMainThreadJankWatcher() {
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
          hilog.info(0x0000, 'MainThreadJank', `Received event: domain=${domain}`);
          for (const eventGroup of appEventGroups) {
            hilog.info(0x0000, 'MainThreadJank', `Event name: ${eventGroup.name}`);
            for (const eventInfo of eventGroup.appEventInfos) {
              this.processEventInfo(eventInfo);
            }
          }
        }
      });
      hilog.info(0x0000, 'MainThreadJank', 'Watcher added successfully');
    } catch (error) {
      hilog.error(0x0000, 'MainThreadJank', `Failed to add watcher: code=${error.code}, message=${error.message}`);
    }
  }

  processEventInfo(eventInfo: hiAppEvent.AppEventInfo) {
    hilog.info(0x0000, 'MainThreadJank', `Event domain: ${eventInfo.domain}`);
    hilog.info(0x0000, 'MainThreadJank', `Event name: ${eventInfo.name}`);
    hilog.info(0x0000, 'MainThreadJank', `Event type: ${eventInfo.eventType}`);

    hilog.info(0x0000, 'MainThreadJank', `Time: ${eventInfo.params['time']}`);
    hilog.info(0x0000, 'MainThreadJank', `Bundle version: ${eventInfo.params['bundle_version']}`);
    hilog.info(0x0000, 'MainThreadJank', `Bundle name: ${eventInfo.params['bundle_name']}`);
    hilog.info(0x0000, 'MainThreadJank', `PID: ${eventInfo.params['pid']}`);
    hilog.info(0x0000, 'MainThreadJank', `UID: ${eventInfo.params['uid']}`);
    hilog.info(0x0000, 'MainThreadJank', `Begin time: ${eventInfo.params['begin_time']}`);
    hilog.info(0x0000, 'MainThreadJank', `End time: ${eventInfo.params['end_time']}`);
    hilog.info(0x0000, 'MainThreadJank', `Log over limit: ${eventInfo.params['log_over_limit']}`);

    if (eventInfo.params['app_start_jiffies_time']) {
      hilog.info(0x0000, 'MainThreadJank', `App start jiffies time: ${JSON.stringify(eventInfo.params['app_start_jiffies_time'])}`);
    }

    if (eventInfo.params['heaviest_stack']) {
      hilog.info(0x0000, 'MainThreadJank', `Heaviest stack: ${eventInfo.params['heaviest_stack']}`);
    }

    if (eventInfo.params['external_log']) {
      let logPath: string = String(eventInfo.params['external_log']);
      hilog.info(0x0000, 'MainThreadJank', `External log: ${logPath}`);
      this.moveLogFile(logPath);
    }
  }

  moveLogFile(sourcePath: string) {
    try {
      let targetPath: string = "";
      if (sourcePath.endsWith(".txt")) {
        targetPath = "/data/storage/el2/base/mainThreadJank.txt";
      } else if (sourcePath.endsWith(".trace")) {
        targetPath = "/data/storage/el2/base/mainThreadJank.trace";
      } else {
        hilog.warn(0x0000, 'MainThreadJank', `Unknown log file format: ${sourcePath}`);
        return;
      }

      fileIo.copyFileSync(sourcePath, targetPath);
      hilog.info(0x0000, 'MainThreadJank', `Log file moved to: ${targetPath}`);
    } catch (error) {
      hilog.error(0x0000, 'MainThreadJank', `Failed to move log file: code=${error.code}, message=${error.message}`);
    }
  }

  setCustomSamplingParams() {
    let params: Record<string, hiAppEvent.ParamType> = {
      "log_type": "1",
      "sample_interval": "100",
      "ignore_startup_time": "11",
      "sample_count": "21",
      "report_times_per_app": "3"
    };

    hiAppEvent.setEventConfig(hiAppEvent.event.MAIN_THREAD_JANK, params).then(() => {
      hilog.info(0x0000, 'MainThreadJank', 'Custom sampling parameters set successfully');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'MainThreadJank', `Failed to set parameters: code=${err.code}, message=${err.message}`);
    });
  }

  removeMainThreadJankWatcher() {
    try {
      let watcher: hiAppEvent.Watcher = {
        name: this.watcherName
      };
      hiAppEvent.removeWatcher(watcher);
      hilog.info(0x0000, 'MainThreadJank', 'Watcher removed successfully');
    } catch (error) {
      hilog.error(0x0000, 'MainThreadJank', `Failed to remove watcher: code=${error.code}, message=${error.message}`);
    }
  }

  simulateMainThreadTimeout(duration: number) {
    let startTime = Date.now();
    while (Date.now() - startTime <= duration) {}
    hilog.info(0x0000, 'MainThreadJank', `Simulated timeout: ${duration}ms`);
  }

  build() {
    RelativeContainer() {
      Column() {
        Text('Main Thread Jank Watcher Example')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin(20);

        Button("Add Watcher", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .onClick(() => {
            this.addMainThreadJankWatcher();
          });

        Button("Set Custom Params", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .onClick(() => {
            this.setCustomSamplingParams();
          });

        Button("Simulate 150ms Timeout", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .onClick(() => {
            this.simulateMainThreadTimeout(150);
          });

        Button("Simulate 350ms Timeout", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .onClick(() => {
            this.simulateMainThreadTimeout(350);
          });

        Button("Simulate 500ms Timeout", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .onClick(() => {
            this.simulateMainThreadTimeout(500);
          });

        Button("Remove Watcher", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .onClick(() => {
            this.removeMainThreadJankWatcher();
          });
      }
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}