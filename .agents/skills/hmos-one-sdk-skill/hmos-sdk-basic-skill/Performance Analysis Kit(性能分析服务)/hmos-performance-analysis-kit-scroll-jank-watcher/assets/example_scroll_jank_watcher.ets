/**
 * 订阅滑动丢帧事件完整示例代码
 * 功能：演示如何使用hiAppEvent订阅系统滑动丢帧事件（SCROLL_JANK）
 * API版本：API version 12+
 * Kit：PerformanceAnalysisKit
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ScrollJankWatcher';
const DOMAIN = 0x0000;

/**
 * 滑动丢帧事件观察者管理类
 * 提供订阅、处理、移除滑动丢帧事件的完整功能
 */
export class ScrollJankWatcherManager {
  private watcherName: string = 'scrollJankWatcher';
  private isWatching: boolean = false;
  private eventCount: number = 0;
  private watcher: hiAppEvent.Watcher;

  constructor(name?: string) {
    if (name) {
      this.watcherName = name;
    }

    // 初始化观察者对象
    this.watcher = {
      name: this.watcherName,
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.SCROLL_JANK]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        this.handleEvent(domain, appEventGroups);
      }
    };
  }

  /**
   * 添加滑动丢帧事件观察者
   * @returns 订阅是否成功
   */
  addWatcher(): boolean {
    if (this.isWatching) {
      hilog.warn(DOMAIN, TAG, 'Watcher already added, skip duplicate subscription');
      return true;
    }

    try {
      const holder = hiAppEvent.addWatcher(this.watcher);

      if (holder === null) {
        hilog.error(DOMAIN, TAG, 'Failed to add watcher: holder is null');
        return false;
      }

      this.isWatching = true;
      hilog.info(DOMAIN, TAG, `Watcher added successfully: name=${this.watcherName}`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to add watcher: code=${err.code}, message=${err.message}`);
      this.handleAddError(err.code);
      return false;
    }
  }

  /**
   * 移除滑动丢帧事件观察者
   */
  removeWatcher(): void {
    if (!this.isWatching) {
      hilog.warn(DOMAIN, TAG, 'Watcher not added, skip removal');
      return;
    }

    try {
      hiAppEvent.removeWatcher(this.watcher);
      this.isWatching = false;
      hilog.info(DOMAIN, TAG, `Watcher removed successfully: name=${this.watcherName}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to remove watcher: code=${err.code}, message=${err.message}`);
    }
  }

  /**
   * 处理接收到的滑动丢帧事件
   * @param domain 事件领域
   * @param appEventGroups 事件组数组
   */
  private handleEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(DOMAIN, TAG, `Received event: domain=${domain}`);

    for (const eventGroup of appEventGroups) {
      hilog.info(DOMAIN, TAG, `Event group: name=${eventGroup.name}, count=${eventGroup.appEventInfos.length}`);

      for (const eventInfo of eventGroup.appEventInfos) {
        this.processEventInfo(eventInfo);
      }
    }
  }

  /**
   * 处理单个事件信息
   * @param eventInfo 事件信息对象
   */
  private processEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    try {
      this.eventCount++;

      // 序列化事件数据（用于日志输出）
      const eventJson = JSON.stringify(eventInfo);
      hilog.info(DOMAIN, TAG, `Event ${this.eventCount}: ${eventJson}`);

      // 解析事件参数
      const params = eventInfo.params as Record<string, any>;
      const bundleName = params['bundle_name'] as string;
      const bundleVersion = params['bundle_version'] as string;
      const abilityName = params['ability_name'] as string;
      const beginTime = params['begin_time'] as number;
      const duration = params['duration'] as number;
      const totalAppFrames = params['total_app_frames'] as number;
      const totalAppMissedFrames = params['total_app_missed_frames'] as number;
      const totalRenderFrames = params['total_render_frames'] as number;
      const totalRenderMissedFrames = params['total_render_missed_frames'] as number;
      const maxAppFrametime = params['max_app_frametime'] as number;
      const maxRenderFrametime = params['max_render_frametime'] as number;
      const externalLog = params['external_log'] as Array<string>;

      // 输出关键性能指标
      hilog.warn(DOMAIN, TAG,
        `Scroll jank detected: app=${bundleName}, version=${bundleVersion}, ability=${abilityName}`);
      hilog.warn(DOMAIN, TAG,
        `Duration=${duration}ms, begin_time=${beginTime}`);
      hilog.warn(DOMAIN, TAG,
        `App frames: total=${totalAppFrames}, missed=${totalAppMissedFrames}, max_time=${maxAppFrametime}ms`);
      hilog.warn(DOMAIN, TAG,
        `Render frames: total=${totalRenderFrames}, missed=${totalRenderMissedFrames}, max_time=${maxRenderFrametime}ms`);

      // 处理维测日志路径
      if (externalLog && externalLog.length > 0) {
        hilog.info(DOMAIN, TAG, `External log files: ${externalLog.length}`);
        for (const logPath of externalLog) {
          hilog.info(DOMAIN, TAG, `Log path: ${logPath}`);
        }
      }

      // 生成分析报告
      this.generateReport(params);

    } catch (parseError) {
      const err = parseError as Error;
      hilog.error(DOMAIN, TAG, `Failed to process event: ${err.message}`);
    }
  }

  /**
   * 生成性能分析报告
   * @param params 事件参数
   */
  private generateReport(params: Record<string, any>): void {
    const duration = params['duration'] as number;
    const appMissedFrames = params['total_app_missed_frames'] as number;
    const renderMissedFrames = params['total_render_missed_frames'] as number;

    let severity: string = 'LOW';
    if (duration > 100) {
      severity = 'HIGH';
    } else if (duration > 50) {
      severity = 'MEDIUM';
    }

    hilog.info(DOMAIN, TAG, `Performance Analysis Report:`);
    hilog.info(DOMAIN, TAG, `- Severity: ${severity}`);
    hilog.info(DOMAIN, TAG, `- Duration: ${duration}ms`);
    hilog.info(DOMAIN, TAG, `- App missed frames: ${appMissedFrames}`);
    hilog.info(DOMAIN, TAG, `- Render missed frames: ${renderMissedFrames}`);

    if (severity === 'HIGH') {
      hilog.error(DOMAIN, TAG, 'Critical performance issue detected! Consider optimizing scroll logic.');
    } else if (severity === 'MEDIUM') {
      hilog.warn(DOMAIN, TAG, 'Performance warning: review scroll event handlers.');
    } else {
      hilog.info(DOMAIN, TAG, 'Minor performance issue: acceptable for current usage.');
    }
  }

  /**
   * 处理添加观察者时的错误
   * @param errorCode 错误码
   */
  private handleAddError(errorCode: number): void {
    switch (errorCode) {
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error: check watcher name and event filter format');
        break;
      case 11102001:
        hilog.error(DOMAIN, TAG, 'Invalid watcher name: must start with letter, only contain letters/numbers/underscore, max 32 chars');
        break;
      case 11102002:
        hilog.error(DOMAIN, TAG, 'Invalid event domain: use hiAppEvent.domain.OS');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error code: ${errorCode}`);
    }
  }

  /**
   * 获取事件统计信息
   * @returns 统计数据对象
   */
  getStatistics(): { isWatching: boolean; eventCount: number; watcherName: string } {
    return {
      isWatching: this.isWatching,
      eventCount: this.eventCount,
      watcherName: this.watcherName
    };
  }

  /**
   * 重置事件计数
   */
  resetEventCount(): void {
    this.eventCount = 0;
    hilog.info(DOMAIN, TAG, 'Event count reset to 0');
  }
}

/**
 * 在Ability中使用滑动丢帧观察者的示例
 */
export function setupScrollJankWatcherInAbility(): void {
  const manager = new ScrollJankWatcherManager('abilityWatcher');

  // 添加观察者
  const success = manager.addWatcher();
  if (success) {
    hilog.info(DOMAIN, TAG, 'Setup completed: watcher active');
  } else {
    hilog.error(DOMAIN, TAG, 'Setup failed: watcher inactive');
  }
}

/**
 * 快速订阅示例（简化版）
 */
export function quickSubscribeScrollJank(): void {
  hiAppEvent.addWatcher({
    name: 'quickWatcher',
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.SCROLL_JANK]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      hilog.info(DOMAIN, 'QuickWatcher', `Event received: domain=${domain}`);
      for (const group of appEventGroups) {
        for (const info of group.appEventInfos) {
          hilog.info(DOMAIN, 'QuickWatcher', `Event: ${JSON.stringify(info)}`);
        }
      }
    }
  });
}

/**
 * 使用示例
 */
// 示例1：使用管理类
const watcherManager = new ScrollJankWatcherManager();
watcherManager.addWatcher();
// 在应用销毁时调用：watcherManager.removeWatcher();

// 示例2：快速订阅
quickSubscribeScrollJank();

// 示例3：在Ability中设置
setupScrollJankWatcherInAbility();