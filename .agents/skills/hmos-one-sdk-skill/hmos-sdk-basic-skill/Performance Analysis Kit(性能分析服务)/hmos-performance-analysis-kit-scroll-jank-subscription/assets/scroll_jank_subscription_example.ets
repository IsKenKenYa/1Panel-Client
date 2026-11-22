import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ScrollJankSubscription';
const DOMAIN = 0xFF00;

export class ScrollJankSubscription {
  private watcherName: string = 'scrollJankWatcher';
  private isSubscribed: boolean = false;

  subscribe(): void {
    try {
      hilog.info(DOMAIN, TAG, '开始订阅滑动丢帧事件');
      
      const holder = hiAppEvent.addWatcher({
        name: this.watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.SCROLL_JANK]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          this.handleScrollJankEvent(domain, appEventGroups);
        }
      });

      if (holder === null) {
        hilog.error(DOMAIN, TAG, '订阅失败，请检查参数配置');
        this.isSubscribed = false;
        return;
      }

      this.isSubscribed = true;
      hilog.info(DOMAIN, TAG, '订阅成功，观察者名称: ' + this.watcherName);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, '订阅异常: code=' + err.code + ', message=' + err.message);
      this.handleSubscriptionError(err.code);
    }
  }

  unsubscribe(): void {
    if (!this.isSubscribed) {
      hilog.warn(DOMAIN, TAG, '当前未订阅滑动丢帧事件');
      return;
    }

    try {
      hiAppEvent.removeWatcher({
        name: this.watcherName
      });
      
      this.isSubscribed = false;
      hilog.info(DOMAIN, TAG, '已移除滑动丢帧事件订阅');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, '移除订阅失败: code=' + err.code + ', message=' + err.message);
    }
  }

  private handleScrollJankEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(DOMAIN, TAG, 'onReceive: domain=' + domain);

    for (const eventGroup of appEventGroups) {
      hilog.info(DOMAIN, TAG, 'eventName=' + eventGroup.name);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        this.processEventInfo(eventInfo);
      }
    }
  }

  private processEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(DOMAIN, TAG, 'eventInfo=' + JSON.stringify(eventInfo));
    
    const params = eventInfo.params as Record<string, Object>;
    
    const duration = params.duration as number;
    const maxAppFrametime = params.max_app_frametime as number;
    const maxAppSeqFrames = params.max_app_seq_frames as number;
    const maxRenderFrametime = params.max_render_frametime as number;
    const maxRenderSeqFrames = params.max_render_seq_frames as number;
    const totalAppFrames = params.total_app_frames as number;
    const totalAppMissedFrames = params.total_app_missed_frames as number;
    const totalRenderFrames = params.total_render_frames as number;
    const totalRenderMissedFrames = params.total_render_missed_frames as number;
    const externalLog = params.external_log as string[];
    const logOverLimit = params.log_over_limit as boolean;

    hilog.info(DOMAIN, TAG, '丢帧时长: ' + duration + 'ms');
    hilog.info(DOMAIN, TAG, '最大应用帧时间: ' + maxAppFrametime + 'ms');
    hilog.info(DOMAIN, TAG, '最大应用连续丢帧次数: ' + maxAppSeqFrames);
    hilog.info(DOMAIN, TAG, '最大渲染帧时间: ' + maxRenderFrametime + 'ms');
    hilog.info(DOMAIN, TAG, '最大渲染连续丢帧次数: ' + maxRenderSeqFrames);
    hilog.info(DOMAIN, TAG, '总应用帧数: ' + totalAppFrames);
    hilog.info(DOMAIN, TAG, '总应用丢帧次数: ' + totalAppMissedFrames);
    hilog.info(DOMAIN, TAG, '总渲染帧数: ' + totalRenderFrames);
    hilog.info(DOMAIN, TAG, '总渲染丢帧次数: ' + totalRenderMissedFrames);
    
    if (externalLog && externalLog.length > 0) {
      hilog.info(DOMAIN, TAG, '日志文件路径: ' + externalLog.join(','));
    }
    
    if (logOverLimit) {
      hilog.warn(DOMAIN, TAG, '日志文件大小超过限制，部分日志可能被丢弃');
    }

    this.analyzeJankPerformance(params);
  }

  private analyzeJankPerformance(params: Record<string, Object>): void {
    const duration = params.duration as number;
    const totalAppMissedFrames = params.total_app_missed_frames as number;
    const totalRenderMissedFrames = params.total_render_missed_frames as number;

    if (duration > 100) {
      hilog.warn(DOMAIN, TAG, '严重卡顿: 丢帧时长超过100ms，需重点优化');
    } else if (duration > 50) {
      hilog.warn(DOMAIN, TAG, '轻微卡顿: 丢帧时长超过50ms');
    }

    if (totalAppMissedFrames > 10) {
      hilog.warn(DOMAIN, TAG, '应用丢帧次数较多: ' + totalAppMissedFrames + '次');
    }

    if (totalRenderMissedFrames > 5) {
      hilog.warn(DOMAIN, TAG, '渲染丢帧次数较多: ' + totalRenderMissedFrames + '次');
    }
  }

  private handleSubscriptionError(errorCode: number): void {
    switch (errorCode) {
      case 401:
        hilog.error(DOMAIN, TAG, '参数错误，请检查观察者名称和事件过滤条件');
        break;
      case 11102001:
        hilog.error(DOMAIN, TAG, '观察者名称不合法，请检查名称格式');
        break;
      case 11102002:
        hilog.error(DOMAIN, TAG, '事件领域名称不合法');
        break;
      default:
        hilog.error(DOMAIN, TAG, '未知错误，请参考错误码文档');
        break;
    }
  }

  isSubscriptionActive(): boolean {
    return this.isSubscribed;
  }

  getWatcherName(): string {
    return this.watcherName;
  }
}