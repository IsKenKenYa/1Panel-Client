import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;
const TAG = 'AppKilledMonitor';

export class AppKilledEventSubscriber {
  private watcherName: string = 'appKilledWatcher';
  private isSubscribed: boolean = false;

  subscribe(): boolean {
    if (this.isSubscribed) {
      hilog.warn(DOMAIN, TAG, 'Already subscribed to APP_KILLED events');
      return true;
    }

    try {
      const holder = hiAppEvent.addWatcher({
        name: this.watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_KILLED]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          this.handleAppKilledEvent(domain, appEventGroups);
        }
      });

      if (holder === null) {
        hilog.error(DOMAIN, TAG, 'Failed to add watcher, returned null');
        return false;
      }

      this.isSubscribed = true;
      hilog.info(DOMAIN, TAG, `Successfully subscribed to APP_KILLED events`);
      return true;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Subscription error: code=${err.code}, message=${err.message}`);
      this.handleSubscriptionError(err.code);
      return false;
    }
  }

  unsubscribe(): void {
    if (!this.isSubscribed) {
      hilog.warn(DOMAIN, TAG, 'Not subscribed to APP_KILLED events');
      return;
    }

    try {
      hiAppEvent.removeWatcher({
        name: this.watcherName
      });
      this.isSubscribed = false;
      hilog.info(DOMAIN, TAG, `Successfully unsubscribed from APP_KILLED events`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Unsubscription error: code=${err.code}, message=${err.message}`);
    }
  }

  private handleAppKilledEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(DOMAIN, TAG, `Received app killed event, domain=${domain}`);

    for (const eventGroup of appEventGroups) {
      hilog.info(DOMAIN, TAG, `Event name: ${eventGroup.name}`);

      for (const eventInfo of eventGroup.appEventInfos) {
        const params = eventInfo.params;
        const time = params['time'] || 0;
        const reason = params['reason'] || 'Unknown';
        const foreground = params['foreground'] || false;

        hilog.info(DOMAIN, TAG, `Event time: ${time}`);
        hilog.info(DOMAIN, TAG, `Kill reason: ${reason}`);
        hilog.info(DOMAIN, TAG, `Foreground state: ${foreground}`);

        if (params['app_running_unique_id']) {
          hilog.info(DOMAIN, TAG, `App unique ID: ${params['app_running_unique_id']}`);
        }

        if (params['bundle_version']) {
          hilog.info(DOMAIN, TAG, `Bundle version: ${params['bundle_version']}`);
        }

        this.classifyKillReason(reason, params);
      }
    }
  }

  private classifyKillReason(reason: string, params: Record<string, any>): void {
    if (reason.includes('Memory') || reason.includes('Leak') || reason === 'OomKiller') {
      hilog.warn(DOMAIN, TAG, `Memory issue detected: ${reason}`);
      this.logMemoryIssue(reason, params);
    } else if (reason.startsWith('ResourceLeak')) {
      hilog.error(DOMAIN, TAG, `Resource leak detected: ${reason}`);
      this.logResourceLeak(reason, params);
    } else if (reason.includes('CPU') || reason.includes('Highload')) {
      hilog.warn(DOMAIN, TAG, `CPU overload detected: ${reason}`);
      this.logCPUHighload(reason, params);
    } else if (reason.includes('Timeout') || reason.includes('Block')) {
      hilog.warn(DOMAIN, TAG, `Lifecycle timeout detected: ${reason}`);
      this.logLifecycleIssue(reason, params);
    } else if (reason === 'UserRequest' || reason === 'Uninstall') {
      hilog.info(DOMAIN, TAG, `User initiated termination: ${reason}`);
    } else {
      hilog.info(DOMAIN, TAG, `Other termination reason: ${reason}`);
    }
  }

  private logMemoryIssue(reason: string, params: Record<string, any>): void {
    const memoryLog = {
      timestamp: params['time'],
      reason: reason,
      foreground: params['foreground'],
      suggestion: 'Check memory usage and optimize memory allocation'
    };
    hilog.info(DOMAIN, TAG, `Memory log: ${JSON.stringify(memoryLog)}`);
  }

  private logResourceLeak(reason: string, params: Record<string, any>): void {
    const leakType = reason.replace('ResourceLeak(', '').replace(')', '');
    const leakLog = {
      timestamp: params['time'],
      leakType: leakType,
      foreground: params['foreground'],
      suggestion: `Check ${leakType} usage and release unused resources`
    };
    hilog.error(DOMAIN, TAG, `Leak log: ${JSON.stringify(leakLog)}`);
  }

  private logCPUHighload(reason: string, params: Record<string, any>): void {
    const cpuLog = {
      timestamp: params['time'],
      reason: reason,
      foreground: params['foreground'],
      suggestion: 'Check CPU usage and optimize performance'
    };
    hilog.warn(DOMAIN, TAG, `CPU log: ${JSON.stringify(cpuLog)}`);
  }

  private logLifecycleIssue(reason: string, params: Record<string, any>): void {
    const lifecycleLog = {
      timestamp: params['time'],
      reason: reason,
      foreground: params['foreground'],
      suggestion: 'Check lifecycle timeout and optimize response time'
    };
    hilog.warn(DOMAIN, TAG, `Lifecycle log: ${JSON.stringify(lifecycleLog)}`);
  }

  private handleSubscriptionError(errorCode: number): void {
    switch (errorCode) {
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error, check watcher configuration');
        break;
      case 11102001:
        hilog.error(DOMAIN, TAG, 'Invalid watcher name format');
        break;
      case 11102002:
        hilog.error(DOMAIN, TAG, 'Invalid event domain format');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${errorCode}`);
    }
  }
}

export function createAppKilledSubscriber(): AppKilledEventSubscriber {
  return new AppKilledEventSubscriber();
}