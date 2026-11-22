import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';

const LOG_DOMAIN = 0x0000;
const LOG_TAG = 'HiAppEvent';
const WATCHER_NAME = 'crashEventWatcher';

export class CrashEventWatcher {
  private watcher: hiAppEvent.Watcher | null = null;
  private holder: hiAppEvent.AppEventPackageHolder | null = null;

  async setup(): Promise<void> {
    try {
      await this.setCrashEventParams();
      await this.setCrashLogConfig();
      await this.setPageSwitchLogPolicy();
      this.addWatcher();
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG, `Setup failed: code=${error.code}, message=${error.message}`);
    }
  }

  private async setCrashEventParams(): Promise<void> {
    try {
      const crashParams: Record<string, hiAppEvent.ParamType> = {
        'test_data': 100,
        'user_id': 'user123',
        'session_id': 'session456'
      };

      await hiAppEvent.setEventParam(crashParams, hiAppEvent.domain.OS, hiAppEvent.event.APP_CRASH);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Success to set crash event params');
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to set event param: code=${error.code}, message=${error.message}`);
    }
  }

  private async setCrashLogConfig(): Promise<void> {
    if (deviceInfo.sdkApiVersion >= 20) {
      try {
        const crashConfigParams: Record<string, hiAppEvent.ParamType> = {
          'extend_pc_lr_printing': true,
          'log_file_cutoff_sz_bytes': 1024000,
          'simplify_vma_printing': true
        };

        await hiAppEvent.setEventConfig(hiAppEvent.event.APP_CRASH, crashConfigParams);
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Success to set crash log config');
      } catch (err) {
        const error: BusinessError = err as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to set event config: code=${error.code}, message=${error.message}`);
      }
    } else {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'API version < 20, skip crash log config');
    }
  }

  private async setPageSwitchLogPolicy(): Promise<void> {
    if (deviceInfo.sdkApiVersion >= 24) {
      try {
        const switchLogPolicy: hiAppEvent.EventPolicy = {
          'appCrashPolicy': {
            'pageSwitchLogEnable': true
          }
        };

        await hiAppEvent.configEventPolicy(switchLogPolicy);
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Success to config page switch log policy');
      } catch (err) {
        const error: BusinessError = err as BusinessError;
        hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to config event policy: code=${error.code}, message=${error.message}`);
      }
    } else {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'API version < 24, skip page switch log config');
    }
  }

  private addWatcher(): void {
    this.watcher = {
      name: WATCHER_NAME,
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_CRASH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        this.onReceive(domain, appEventGroups);
      }
    };

    this.holder = hiAppEvent.addWatcher(this.watcher);
    if (this.holder === null) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Failed to add watcher');
    } else {
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Success to add watcher');
    }
  }

  private onReceive(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, `onReceive: domain=${domain}`);

    for (const eventGroup of appEventGroups) {
      hilog.info(LOG_DOMAIN, LOG_TAG, `eventName=${eventGroup.name}`);

      for (const eventInfo of eventGroup.appEventInfos) {
        this.processCrashEvent(eventInfo);
      }
    }
  }

  private processCrashEvent(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, `domain=${eventInfo.domain}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `name=${eventInfo.name}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `eventType=${eventInfo.eventType}`);

    const params = eventInfo.params;

    hilog.info(LOG_DOMAIN, LOG_TAG, `time=${params['time']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `crash_type=${params['crash_type']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `foreground=${params['foreground']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `release_type=${params['release_type']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `cpu_abi=${params['cpu_abi']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `app_running_unique_id=${params['app_running_unique_id']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `bundle_version=${params['bundle_version']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `bundle_name=${params['bundle_name']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `pid=${params['pid']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `uid=${params['uid']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `uuid=${params['uuid']}`);

    hilog.info(LOG_DOMAIN, LOG_TAG, `exception=${JSON.stringify(params['exception'])}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `hilog.size=${params['hilog'].length}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `process_life_time=${params['process_life_time']}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `memory=${JSON.stringify(params['memory'])}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `external_log=${JSON.stringify(params['external_log'])}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `log_over_limit=${params['log_over_limit']}`);

    if (params['page_switch_log'] !== undefined) {
      hilog.info(LOG_DOMAIN, LOG_TAG, `page_switch_log=${JSON.stringify(params['page_switch_log'])}`);
    }

    if (params['test_data'] !== undefined) {
      hilog.info(LOG_DOMAIN, LOG_TAG, `test_data=${params['test_data']}`);
    }
  }

  removeWatcher(): void {
    if (this.watcher !== null) {
      hiAppEvent.removeWatcher(this.watcher);
      hilog.info(LOG_DOMAIN, LOG_TAG, 'Watcher removed');
      this.watcher = null;
      this.holder = null;
    }
  }
}

export function triggerJsErrorCrash(): void {
  JSON.parse('');
}

export async function setupCrashWatcher(): Promise<void> {
  const watcher = new CrashEventWatcher();
  await watcher.setup();
}