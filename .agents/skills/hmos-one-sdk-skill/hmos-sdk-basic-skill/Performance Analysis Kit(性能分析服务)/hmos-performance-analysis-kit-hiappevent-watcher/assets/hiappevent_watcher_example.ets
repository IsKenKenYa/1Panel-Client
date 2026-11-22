/**
 * HiAppEvent 事件订阅完整示例
 * 演示订阅系统崩溃事件和应用自定义事件
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiAppEventExample';
const DOMAIN = 0x0000;

export class HiAppEventWatcherExample {
  private crashWatcher: hiAppEvent.Watcher | null = null;
  private buttonClickWatcher: hiAppEvent.Watcher | null = null;

  /**
   * 初始化事件订阅
   */
  initEventWatchers(): void {
    this.subscribeCrashEvent();
    this.subscribeButtonClickEvent();
  }

  /**
   * 订阅系统崩溃事件（OnReceive 模式 - 实时回调）
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
        hilog.info(DOMAIN, TAG, 'Success to read crash event with onReceive callback');
        hilog.info(DOMAIN, TAG, `domain=${domain}`);
        
        for (const eventGroup of appEventGroups) {
          hilog.info(DOMAIN, TAG, `eventName=${eventGroup.name}`);
          for (const eventInfo of eventGroup.appEventInfos) {
            this.handleCrashEventInfo(eventInfo);
          }
        }
      }
    };

    try {
      hiAppEvent.addWatcher(this.crashWatcher);
      hilog.info(DOMAIN, TAG, 'Crash event watcher added successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to add crash watcher: code=${err.code}, message=${err.message}`);
    }
  }

  /**
   * 处理崩溃事件信息
   */
  private handleCrashEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(DOMAIN, TAG, `time=${JSON.stringify(eventInfo.params['time'])}`);
    hilog.info(DOMAIN, TAG, `bundle_name=${JSON.stringify(eventInfo.params['bundle_name'])}`);
    hilog.info(DOMAIN, TAG, `external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
    
    const externalLog = eventInfo.params['external_log'];
    if (externalLog && Array.isArray(externalLog)) {
      hilog.info(DOMAIN, TAG, `Crash log files: ${externalLog.length} files`);
      for (const logFile of externalLog) {
        hilog.info(DOMAIN, TAG, `Log file: ${logFile}`);
      }
    }
  }

  /**
   * 订阅按钮点击事件（OnTrigger 模式 - 批量回调）
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
        row: 10,
        size: 5000,
        timeOut: 2
      },
      onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
        if (holder == null) {
          hilog.error(DOMAIN, TAG, 'Holder is null, subscription failed');
          return;
        }
        
        hilog.info(DOMAIN, TAG, 'Success to read button events with onTrigger callback');
        hilog.info(DOMAIN, TAG, `curRow=${curRow}, curSize=${curSize}`);
        
        this.processEventPackages(holder);
      }
    };

    try {
      hiAppEvent.addWatcher(this.buttonClickWatcher);
      hilog.info(DOMAIN, TAG, 'Button click watcher added successfully');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to add button watcher: code=${err.code}, message=${err.message}`);
    }
  }

  /**
   * 处理事件包数据
   */
  private processEventPackages(holder: hiAppEvent.AppEventPackageHolder): void {
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder.takeNext()) != null) {
      hilog.info(DOMAIN, TAG, `PackageId=${eventPkg.packageId}`);
      hilog.info(DOMAIN, TAG, `Row=${eventPkg.row}, Size=${eventPkg.size}`);
      
      for (const eventInfo of eventPkg.data) {
        hilog.info(DOMAIN, TAG, `Event data: ${eventInfo}`);
      }
      
      if (eventPkg.appEventInfos && eventPkg.appEventInfos.length > 0) {
        for (const appEventInfo of eventPkg.appEventInfos) {
          hilog.info(DOMAIN, TAG, `Event domain: ${appEventInfo.domain}`);
          hilog.info(DOMAIN, TAG, `Event name: ${appEventInfo.name}`);
          hilog.info(DOMAIN, TAG, `Event type: ${appEventInfo.eventType}`);
        }
      }
    }
  }

  /**
   * 清理事件订阅
   */
  cleanupEventWatchers(): void {
    if (this.crashWatcher) {
      try {
        hiAppEvent.removeWatcher(this.crashWatcher);
        hilog.info(DOMAIN, TAG, 'Crash watcher removed successfully');
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        hilog.error(DOMAIN, TAG, `Failed to remove crash watcher: code=${err.code}`);
      }
    }

    if (this.buttonClickWatcher) {
      try {
        hiAppEvent.removeWatcher(this.buttonClickWatcher);
        hilog.info(DOMAIN, TAG, 'Button click watcher removed successfully');
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        hilog.error(DOMAIN, TAG, `Failed to remove button watcher: code=${err.code}`);
      }
    }
  }
}

/**
 * 手动获取订阅事件示例
 */
export class HiAppEventManualFetchExample {
  private holder: hiAppEvent.AppEventPackageHolder | null = null;

  /**
   * 初始化手动订阅
   */
  initManualSubscription(): void {
    this.holder = hiAppEvent.addWatcher({
      name: 'ManualFetchWatcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_CRASH, hiAppEvent.event.APP_FREEZE]
        }
      ]
    });

    if (this.holder) {
      hilog.info(DOMAIN, TAG, 'Manual fetch watcher added successfully');
      this.holder.setSize(1000);
    } else {
      hilog.error(DOMAIN, TAG, 'Failed to add manual fetch watcher');
    }
  }

  /**
   * 延时获取系统崩溃/冻屏事件
   * 系统捕获维测日志有耗时，建议延时重试
   */
  fetchSystemEventsWithDelay(): void {
    setTimeout(() => {
      if (this.holder == null) {
        hilog.error(DOMAIN, TAG, 'Holder is null');
        return;
      }

      let eventPkg: hiAppEvent.AppEventPackage | null = null;
      while ((eventPkg = this.holder.takeNext()) != null) {
        hilog.info(DOMAIN, TAG, `PackageId=${eventPkg.packageId}`);
        hilog.info(DOMAIN, TAG, `Row=${eventPkg.row}, Size=${eventPkg.size}`);
        
        for (const eventInfo of eventPkg.data) {
          hilog.info(DOMAIN, TAG, `Event data: ${eventInfo}`);
        }
      }
    }, 30000);
  }

  /**
   * 立即获取订阅事件
   */
  fetchEventsImmediately(): void {
    if (this.holder == null) {
      hilog.error(DOMAIN, TAG, 'Holder is null');
      return;
    }

    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = this.holder.takeNext()) != null) {
      hilog.info(DOMAIN, TAG, `PackageId=${eventPkg.packageId}`);
      hilog.info(DOMAIN, TAG, `Row=${eventPkg.row}, Size=${eventPkg.size}`);
      
      for (const eventInfo of eventPkg.data) {
        hilog.info(DOMAIN, TAG, `Event data: ${eventInfo}`);
      }
    }
  }
}

/**
 * 使用示例
 */
export function runHiAppEventWatcherExample(): void {
  const watcherExample = new HiAppEventWatcherExample();
  watcherExample.initEventWatchers();

  const manualFetchExample = new HiAppEventManualFetchExample();
  manualFetchExample.initManualSubscription();
  manualFetchExample.fetchSystemEventsWithDelay();
}