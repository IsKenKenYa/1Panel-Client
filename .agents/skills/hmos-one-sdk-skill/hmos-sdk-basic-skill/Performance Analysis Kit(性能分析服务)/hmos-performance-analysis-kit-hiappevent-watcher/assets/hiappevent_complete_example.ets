/**
 * HiAppEvent 完整应用示例
 * 演示事件订阅和打点的完整流程
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiAppEventComplete';
const DOMAIN = 0x0000;

@Entry
@Component
struct HiAppEventCompleteExample {
  private watcherExample: HiAppEventWatcherManager = new HiAppEventWatcherManager();
  private writeExample: HiAppEventWriteManager = new HiAppEventWriteManager();

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'Application appearing, initializing HiAppEvent');
    this.initHiAppEvent();
  }

  aboutToDisappear(): void {
    hilog.info(DOMAIN, TAG, 'Application disappearing, cleaning up HiAppEvent');
    this.cleanupHiAppEvent();
  }

  build() {
    Column({ space: 20 }) {
      Text('HiAppEvent 完整示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      Button('触发崩溃事件')
        .type(ButtonType.Capsule)
        .backgroundColor('#FF5733')
        .width('80%')
        .onClick(() => {
          this.triggerCrashEvent();
        })

      Button('写入按钮点击事件')
        .type(ButtonType.Capsule)
        .backgroundColor('#33C4FF')
        .width('80%')
        .onClick(() => {
          this.writeButtonClickEvent();
        })

      Button('写入性能统计事件')
        .type(ButtonType.Capsule)
        .backgroundColor('#33FF57')
        .width('80%')
        .onClick(() => {
          this.writePerformanceEvent();
        })

      Button('写入用户行为事件')
        .type(ButtonType.Capsule)
        .backgroundColor('#FF33F5')
        .width('80%')
        .onClick(() => {
          this.writeUserBehaviorEvent();
        })

      Button('配置打点功能')
        .type(ButtonType.Capsule)
        .backgroundColor('#F5FF33')
        .width('80%')
        .onClick(() => {
          this.configureHiAppEvent();
        })

      Button('清理打点数据')
        .type(ButtonType.Capsule)
        .backgroundColor('#858585')
        .width('80%')
        .onClick(() => {
          this.clearHiAppEventData();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 初始化 HiAppEvent
   */
  private initHiAppEvent(): void {
    this.configureHiAppEvent();
    this.watcherExample.initWatchers();
  }

  /**
   * 清理 HiAppEvent
   */
  private cleanupHiAppEvent(): void {
    this.watcherExample.cleanupWatchers();
  }

  /**
   * 配置 HiAppEvent
   */
  private configureHiAppEvent(): void {
    const config: hiAppEvent.ConfigOption = {
      disable: false,
      maxStorage: '10M'
    };
    hiAppEvent.configure(config);
    hilog.info(DOMAIN, TAG, 'HiAppEvent configured: maxStorage=10M, enabled=true');
  }

  /**
   * 清理打点数据
   */
  private clearHiAppEventData(): void {
    hiAppEvent.clearData();
    hilog.info(DOMAIN, TAG, 'HiAppEvent data cleared');
  }

  /**
   * 触发崩溃事件（用于测试）
   */
  private triggerCrashEvent(): void {
    hilog.info(DOMAIN, TAG, 'Triggering crash event for testing');
    try {
      let result: object = JSON.parse('');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Crash triggered: JSON parse error');
    }
  }

  /**
   * 写入按钮点击事件
   */
  private writeButtonClickEvent(): void {
    this.writeExample.writeButtonClickEvent('SubmitButton', Date.now());
  }

  /**
   * 写入性能统计事件
   */
  private writePerformanceEvent(): void {
    const startTime = Date.now();
    setTimeout(() => {
      const duration = Date.now() - startTime;
      this.writeExample.writePerformanceStatEvent('ui_render', duration, true);
    }, 100);
  }

  /**
   * 写入用户行为事件
   */
  private writeUserBehaviorEvent(): void {
    this.writeExample.writeUserBehaviorEvent('user123', 'button_click', Date.now());
  }
}

/**
 * 事件订阅管理器
 */
class HiAppEventWatcherManager {
  private crashWatcher: hiAppEvent.Watcher | null = null;
  private buttonClickWatcher: hiAppEvent.Watcher | null = null;
  private performanceWatcher: hiAppEvent.Watcher | null = null;

  /**
   * 初始化观察者
   */
  initWatchers(): void {
    this.subscribeCrashEvent();
    this.subscribeButtonClickEvent();
    this.subscribePerformanceEvent();
  }

  /**
   * 清理观察者
   */
  cleanupWatchers(): void {
    if (this.crashWatcher) {
      hiAppEvent.removeWatcher(this.crashWatcher);
      hilog.info(DOMAIN, TAG, 'Crash watcher removed');
    }
    if (this.buttonClickWatcher) {
      hiAppEvent.removeWatcher(this.buttonClickWatcher);
      hilog.info(DOMAIN, TAG, 'Button click watcher removed');
    }
    if (this.performanceWatcher) {
      hiAppEvent.removeWatcher(this.performanceWatcher);
      hilog.info(DOMAIN, TAG, 'Performance watcher removed');
    }
  }

  /**
   * 订阅崩溃事件（OnReceive 模式）
   */
  private subscribeCrashEvent(): void {
    this.crashWatcher = {
      name: 'AppCrashWatcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_CRASH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        hilog.info(DOMAIN, TAG, 'Crash event received');
        hilog.info(DOMAIN, TAG, `domain=${domain}`);
        
        for (const eventGroup of appEventGroups) {
          hilog.info(DOMAIN, TAG, `eventName=${eventGroup.name}`);
          for (const eventInfo of eventGroup.appEventInfos) {
            hilog.info(DOMAIN, TAG, `time=${eventInfo.params['time']}`);
            hilog.info(DOMAIN, TAG, `bundle_name=${eventInfo.params['bundle_name']}`);
            hilog.info(DOMAIN, TAG, `external_log=${eventInfo.params['external_log']}`);
          }
        }
      }
    };
    
    hiAppEvent.addWatcher(this.crashWatcher);
    hilog.info(DOMAIN, TAG, 'Crash event watcher added');
  }

  /**
   * 订阅按钮点击事件（OnTrigger 模式）
   */
  private subscribeButtonClickEvent(): void {
    this.buttonClickWatcher = {
      name: 'ButtonClickWatcher',
      appEventFilters: [
        {
          domain: 'button',
          names: ['click']
        }
      ],
      triggerCondition: {
        row: 1
      },
      onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
        if (holder == null) {
          hilog.error(DOMAIN, TAG, 'Holder is null');
          return;
        }
        
        hilog.info(DOMAIN, TAG, 'Button click event triggered');
        hilog.info(DOMAIN, TAG, `curRow=${curRow}, curSize=${curSize}`);
        
        let eventPkg: hiAppEvent.AppEventPackage | null = null;
        while ((eventPkg = holder.takeNext()) != null) {
          hilog.info(DOMAIN, TAG, `packageId=${eventPkg.packageId}`);
          for (const eventInfo of eventPkg.data) {
            hilog.info(DOMAIN, TAG, `eventInfo=${eventInfo}`);
          }
        }
      }
    };
    
    hiAppEvent.addWatcher(this.buttonClickWatcher);
    hilog.info(DOMAIN, TAG, 'Button click event watcher added');
  }

  /**
   * 订阅性能统计事件
   */
  private subscribePerformanceEvent(): void {
    this.performanceWatcher = {
      name: 'PerformanceWatcher',
      appEventFilters: [
        {
          domain: 'performance',
          names: ['operation_stat']
        }
      ],
      triggerCondition: {
        row: 5,
        size: 5000
      },
      onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
        if (holder == null) {
          hilog.error(DOMAIN, TAG, 'Holder is null');
          return;
        }
        
        hilog.info(DOMAIN, TAG, 'Performance events triggered');
        hilog.info(DOMAIN, TAG, `curRow=${curRow}, curSize=${curSize}`);
        
        let eventPkg: hiAppEvent.AppEventPackage | null = null;
        while ((eventPkg = holder.takeNext()) != null) {
          hilog.info(DOMAIN, TAG, `packageId=${eventPkg.packageId}`);
          for (const eventInfo of eventPkg.data) {
            hilog.info(DOMAIN, TAG, `eventInfo=${eventInfo}`);
          }
        }
      }
    };
    
    hiAppEvent.addWatcher(this.performanceWatcher);
    hilog.info(DOMAIN, TAG, 'Performance event watcher added');
  }
}

/**
 * 事件打点管理器
 */
class HiAppEventWriteManager {
  /**
   * 写入按钮点击事件
   */
  writeButtonClickEvent(buttonName: string, clickTime: number): void {
    const eventParams: Record<string, number | string> = {
      'clickTime': clickTime,
      'buttonName': buttonName,
      'clickCount': 1
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'button',
      name: 'click',
      eventType: hiAppEvent.EventType.BEHAVIOR,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, `Button click event written: ${buttonName}`);
      })
      .catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Write failed: ${err.code}, ${err.message}`);
      });
  }

  /**
   * 写入性能统计事件
   */
  writePerformanceStatEvent(operationName: string, duration: number, success: boolean): void {
    const eventParams: Record<string, number | boolean | string> = {
      'operation': operationName,
      'duration_ms': duration,
      'success': success,
      'timestamp': Date.now()
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'performance',
      name: 'operation_stat',
      eventType: hiAppEvent.EventType.STATISTIC,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, `Performance event written: ${operationName}`);
      })
      .catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Write failed: ${err.code}, ${err.message}`);
      });
  }

  /**
   * 写入用户行为事件
   */
  writeUserBehaviorEvent(userId: string, action: string, timestamp: number): void {
    const eventParams: Record<string, string | number> = {
      'user_id': userId,
      'action': action,
      'timestamp': timestamp
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'user_behavior',
      name: 'user_action',
      eventType: hiAppEvent.EventType.BEHAVIOR,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, `User behavior event written: ${action}`);
      })
      .catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Write failed: ${err.code}, ${err.message}`);
      });
  }
}