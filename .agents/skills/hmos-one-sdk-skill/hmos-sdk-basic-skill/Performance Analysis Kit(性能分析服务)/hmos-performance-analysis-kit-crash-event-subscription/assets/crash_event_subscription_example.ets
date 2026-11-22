import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';

const TAG = 'CrashEventSubscription';
const DOMAIN = 0x0000;

export class CrashEventSubscriptionExample {
  private watcher: hiAppEvent.Watcher | null = null;
  private isSetupComplete: boolean = false;

  async setupCrashWatcher(): Promise<void> {
    try {
      await this.setCustomCrashParams();
      await this.configureCrashLog();
      await this.configurePageSwitchLog();
      this.addCrashWatcher();
      this.isSetupComplete = true;
      hilog.info(DOMAIN, TAG, 'Crash event watcher setup completed successfully.');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to setup crash watcher: ${error}`);
    }
  }

  private async setCustomCrashParams(): Promise<void> {
    let crashParams: Record<string, hiAppEvent.ParamType> = {
      'user_id': 'user_001',
      'operation_step': 'startup',
      'app_version': '1.0.0',
      'device_model': deviceInfo.model || 'unknown'
    };

    try {
      await hiAppEvent.setEventParam(
        crashParams,
        hiAppEvent.domain.OS,
        hiAppEvent.event.APP_CRASH
      );
      hilog.info(DOMAIN, TAG, 'Successfully set custom crash parameters.');
    } catch (err) {
      const error = err as BusinessError;
      this.handleSetEventParamError(error);
    }
  }

  private async configureCrashLog(): Promise<void> {
    if (deviceInfo.sdkApiVersion < 20) {
      hilog.info(DOMAIN, TAG, 'API version < 20, skip crash log configuration.');
      return;
    }

    let crashConfigParams: Record<string, hiAppEvent.ParamType> = {
      'extend_pc_lr_printing': true,
      'log_file_cutoff_sz_bytes': 1024000,
      'simplify_vma_printing': true
    };

    try {
      await hiAppEvent.setEventConfig(hiAppEvent.event.APP_CRASH, crashConfigParams);
      hilog.info(DOMAIN, TAG, 'Successfully configured crash log parameters.');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to configure crash log: code=${error.code}, message=${error.message}`);
    }
  }

  private async configurePageSwitchLog(): Promise<void> {
    if (deviceInfo.sdkApiVersion < 24) {
      hilog.info(DOMAIN, TAG, 'API version < 24, skip page switch log configuration.');
      return;
    }

    let switchLogPolicy: hiAppEvent.EventPolicy = {
      'appCrashPolicy': {
        'pageSwitchLogEnable': true
      }
    };

    try {
      await hiAppEvent.configEventPolicy(switchLogPolicy);
      hilog.info(DOMAIN, TAG, 'Successfully configured page switch log.');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to configure page switch log: code=${error.code}, message=${error.message}`);
    }
  }

  private addCrashWatcher(): void {
    this.watcher = {
      name: 'crashEventWatcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_CRASH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        this.handleCrashEvent(domain, appEventGroups);
      }
    };

    try {
      hiAppEvent.addWatcher(this.watcher);
      hilog.info(DOMAIN, TAG, 'Successfully added crash event watcher.');
    } catch (err) {
      const error = err as BusinessError;
      this.handleAddWatcherError(error);
    }
  }

  private handleCrashEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(DOMAIN, TAG, `Received crash event: domain=${domain}`);

    for (const eventGroup of appEventGroups) {
      hilog.info(DOMAIN, TAG, `Event group name: ${eventGroup.name}`);

      for (const eventInfo of eventGroup.appEventInfos) {
        this.processCrashEventData(eventInfo);
      }
    }
  }

  private processCrashEventData(eventInfo: hiAppEvent.AppEventInfo): void {
    const crashType = eventInfo.params['crash_type'] as string;
    const crashTime = eventInfo.params['time'] as number;
    const bundleName = eventInfo.params['bundle_name'] as string;
    const bundleVersion = eventInfo.params['bundle_version'] as string;
    const pid = eventInfo.params['pid'] as number;
    const uid = eventInfo.params['uid'] as number;
    const foreground = eventInfo.params['foreground'] as boolean;
    const exception = eventInfo.params['exception'];
    const externalLog = eventInfo.params['external_log'] as string[];
    const logOverLimit = eventInfo.params['log_over_limit'] as boolean;

    hilog.info(DOMAIN, TAG, `Crash type: ${crashType}`);
    hilog.info(DOMAIN, TAG, `Crash time: ${crashTime}`);
    hilog.info(DOMAIN, TAG, `Bundle name: ${bundleName}`);
    hilog.info(DOMAIN, TAG, `Bundle version: ${bundleVersion}`);
    hilog.info(DOMAIN, TAG, `PID: ${pid}, UID: ${uid}`);
    hilog.info(DOMAIN, TAG, `Foreground: ${foreground}`);
    hilog.error(DOMAIN, TAG, `Exception: ${JSON.stringify(exception)}`);
    hilog.info(DOMAIN, TAG, `External log files: ${JSON.stringify(externalLog)}`);
    hilog.info(DOMAIN, TAG, `Log over limit: ${logOverLimit}`);

    if (crashType === 'JsError') {
      this.handleJsError(exception);
    } else if (crashType === 'NativeCrash') {
      this.handleNativeCrash(exception, externalLog);
    }

    const customParams = ['user_id', 'operation_step', 'app_version', 'device_model'];
    for (const param of customParams) {
      if (eventInfo.params[param] !== undefined) {
        hilog.info(DOMAIN, TAG, `Custom param ${param}: ${eventInfo.params[param]}`);
      }
    }

    if (eventInfo.params['page_switch_log'] !== undefined) {
      hilog.info(DOMAIN, TAG, `Page switch log: ${JSON.stringify(eventInfo.params['page_switch_log'])}`);
    }
  }

  private handleJsError(exception: any): void {
    hilog.error(DOMAIN, TAG, `JsError name: ${exception.name}`);
    hilog.error(DOMAIN, TAG, `JsError message: ${exception.message}`);
    hilog.error(DOMAIN, TAG, `JsError stack: ${exception.stack}`);

    if (exception.thread_name !== undefined) {
      hilog.info(DOMAIN, TAG, `Thread name: ${exception.thread_name}`);
    }
  }

  private handleNativeCrash(exception: any, externalLog: string[]): void {
    hilog.error(DOMAIN, TAG, `NativeCrash message: ${exception.message}`);
    hilog.error(DOMAIN, TAG, `NativeCrash signal: ${JSON.stringify(exception.signal)}`);
    hilog.error(DOMAIN, TAG, `NativeCrash tid: ${exception.tid}`);

    if (exception.thread_name !== undefined) {
      hilog.info(DOMAIN, TAG, `Thread name: ${exception.thread_name}`);
    }

    if (exception.frames !== undefined) {
      hilog.info(DOMAIN, TAG, `Call stack frames count: ${exception.frames.length}`);
      for (const frame of exception.frames) {
        hilog.info(DOMAIN, TAG, `Frame: file=${frame.file}, symbol=${frame.symbol}, pc=${frame.pc}`);
      }
    }

    if (externalLog && externalLog.length > 0) {
      hilog.info(DOMAIN, TAG, `Crash log file count: ${externalLog.length}`);
      for (const logPath of externalLog) {
        hilog.info(DOMAIN, TAG, `Log file path: ${logPath}`);
      }
    }
  }

  private handleSetEventParamError(error: BusinessError): void {
    switch (error.code) {
      case 11100001:
        hilog.error(DOMAIN, TAG, 'Function disabled. Enable hiAppEvent first.');
        break;
      case 11101001:
        hilog.error(DOMAIN, TAG, 'Invalid event domain format.');
        break;
      case 11101002:
        hilog.error(DOMAIN, TAG, 'Invalid event name format.');
        break;
      case 11101004:
        hilog.error(DOMAIN, TAG, 'Invalid string length of event parameter.');
        break;
      case 11101005:
        hilog.error(DOMAIN, TAG, 'Invalid event parameter name.');
        break;
      case 11101007:
        hilog.error(DOMAIN, TAG, 'Number of parameter keys exceeds limit.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: code=${error.code}, message=${error.message}`);
    }
  }

  private handleAddWatcherError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error. Check watcher configuration.');
        break;
      case 11102001:
        hilog.error(DOMAIN, TAG, 'Invalid watcher name format.');
        break;
      case 11102002:
        hilog.error(DOMAIN, TAG, 'Invalid filtering event domain.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: code=${error.code}, message=${error.message}`);
    }
  }

  removeCrashWatcher(): void {
    if (this.watcher !== null) {
      try {
        hiAppEvent.removeWatcher(this.watcher);
        hilog.info(DOMAIN, TAG, 'Successfully removed crash event watcher.');
        this.watcher = null;
        this.isSetupComplete = false;
      } catch (err) {
        const error = err as BusinessError;
        hilog.error(DOMAIN, TAG, `Failed to remove watcher: code=${error.code}, message=${error.message}`);
      }
    }
  }

  isWatcherActive(): boolean {
    return this.isSetupComplete && this.watcher !== null;
  }
}

export function createCrashSubscription(): CrashEventSubscriptionExample {
  return new CrashEventSubscriptionExample();
}