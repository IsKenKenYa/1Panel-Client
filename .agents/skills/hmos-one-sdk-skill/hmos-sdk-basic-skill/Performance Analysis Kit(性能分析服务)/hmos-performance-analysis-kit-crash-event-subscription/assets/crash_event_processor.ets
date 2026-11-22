import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CrashEventProcessor';
const DOMAIN = 0x0000;

export interface CrashEventSummary {
  crashType: string;
  crashTime: number;
  bundleName: string;
  bundleVersion: string;
  pid: number;
  uid: number;
  foreground: boolean;
  exceptionMessage: string;
  callStack: string[];
  logFiles: string[];
  customParams: Record<string, any>;
}

export interface JsErrorDetail {
  name: string;
  message: string;
  stack: string;
  threadName?: string;
}

export interface NativeCrashDetail {
  message: string;
  signal: {
    signo: number;
    code: number;
    address: string;
  };
  threadName?: string;
  tid: number;
  frames: Array<{
    file: string;
    symbol: string;
    buildId?: string;
    pc: string;
    offset?: number;
  }>;
}

export class CrashEventProcessor {
  static extractCrashSummary(eventInfo: hiAppEvent.AppEventInfo): CrashEventSummary {
    const crashType = eventInfo.params['crash_type'] as string;
    const crashTime = eventInfo.params['time'] as number;
    const bundleName = eventInfo.params['bundle_name'] as string;
    const bundleVersion = eventInfo.params['bundle_version'] as string;
    const pid = eventInfo.params['pid'] as number;
    const uid = eventInfo.params['uid'] as number;
    const foreground = eventInfo.params['foreground'] as boolean;
    const externalLog = eventInfo.params['external_log'] as string[];

    let exceptionMessage = '';
    let callStack: string[] = [];

    if (crashType === 'JsError') {
      const jsError = this.parseJsError(eventInfo.params['exception']);
      exceptionMessage = `${jsError.name}: ${jsError.message}`;
      callStack = this.parseJsStack(jsError.stack);
    } else if (crashType === 'NativeCrash') {
      const nativeCrash = this.parseNativeCrash(eventInfo.params['exception']);
      exceptionMessage = nativeCrash.message;
      callStack = nativeCrash.frames.map(frame => `${frame.symbol} at ${frame.file}:${frame.pc}`);
    }

    const customParams: Record<string, any> = {};
    const knownParams = [
      'time', 'crash_type', 'foreground', 'release_type', 'cpu_abi', 'app_running_unique_id',
      'bundle_version', 'bundle_name', 'pid', 'uid', 'uuid', 'exception', 'hilog',
      'process_life_time', 'memory', 'threads', 'external_log', 'log_over_limit',
      'process_name', 'page_switch_log'
    ];
    for (const key in eventInfo.params) {
      if (!knownParams.includes(key)) {
        customParams[key] = eventInfo.params[key];
      }
    }

    return {
      crashType,
      crashTime,
      bundleName,
      bundleVersion,
      pid,
      uid,
      foreground,
      exceptionMessage,
      callStack,
      logFiles: externalLog || [],
      customParams
    };
  }

  static parseJsError(exception: any): JsErrorDetail {
    return {
      name: exception.name || 'UnknownError',
      message: exception.message || 'No message',
      stack: exception.stack || '',
      threadName: exception.thread_name
    };
  }

  static parseNativeCrash(exception: any): NativeCrashDetail {
    return {
      message: exception.message || 'No message',
      signal: exception.signal || { signo: 0, code: 0, address: '0x0' },
      threadName: exception.thread_name,
      tid: exception.tid || 0,
      frames: exception.frames || []
    };
  }

  static parseJsStack(stack: string): string[] {
    if (!stack) return [];
    return stack.split('\n').filter(line => line.trim().length > 0);
  }

  static formatCrashReport(summary: CrashEventSummary): string {
    const lines: string[] = [];
    lines.push('=== Crash Event Report ===');
    lines.push(`Crash Type: ${summary.crashType}`);
    lines.push(`Time: ${new Date(summary.crashTime).toISOString()}`);
    lines.push(`App: ${summary.bundleName} (${summary.bundleVersion})`);
    lines.push(`Process: PID=${summary.pid}, UID=${summary.uid}`);
    lines.push(`Foreground: ${summary.foreground}`);
    lines.push('');
    lines.push('Exception:');
    lines.push(summary.exceptionMessage);
    lines.push('');
    lines.push('Call Stack:');
    summary.callStack.forEach((line, index) => {
      lines.push(`  ${index + 1}. ${line}`);
    });
    if (summary.logFiles.length > 0) {
      lines.push('');
      lines.push('Log Files:');
      summary.logFiles.forEach(file => {
        lines.push(`  - ${file}`);
      });
    }
    if (Object.keys(summary.customParams).length > 0) {
      lines.push('');
      lines.push('Custom Parameters:');
      for (const key in summary.customParams) {
        lines.push(`  ${key}: ${summary.customParams[key]}`);
      }
    }
    return lines.join('\n');
  }

  static logCrashSummary(summary: CrashEventSummary): void {
    hilog.error(DOMAIN, TAG, 'Crash Event Summary:');
    hilog.error(DOMAIN, TAG, `  Type: ${summary.crashType}`);
    hilog.error(DOMAIN, TAG, `  Time: ${summary.crashTime}`);
    hilog.error(DOMAIN, TAG, `  App: ${summary.bundleName}`);
    hilog.error(DOMAIN, TAG, `  Exception: ${summary.exceptionMessage}`);
    hilog.error(DOMAIN, TAG, `  Call Stack Lines: ${summary.callStack.length}`);
    hilog.error(DOMAIN, TAG, `  Log Files: ${summary.logFiles.length}`);
  }

  static checkLogOverLimit(eventInfo: hiAppEvent.AppEventInfo): boolean {
    const logOverLimit = eventInfo.params['log_over_limit'] as boolean;
    if (logOverLimit) {
      hilog.warn(DOMAIN, TAG, 'Crash log files exceed size limit (5MB). New logs may fail to write.');
      return true;
    }
    return false;
  }

  static extractMemoryInfo(eventInfo: hiAppEvent.AppEventInfo): {
    rss: number;
    sysFreeMem: number;
    sysAvailMem: number;
    sysTotalMem: number;
  } | null {
    const memory = eventInfo.params['memory'];
    if (!memory) return null;

    return {
      rss: memory['rss'] || 0,
      sysFreeMem: memory['sys_free_mem'] || 0,
      sysAvailMem: memory['sys_avail_mem'] || 0,
      sysTotalMem: memory['sys_total_mem'] || 0
    };
  }

  static extractProcessLifeTime(eventInfo: hiAppEvent.AppEventInfo): number | null {
    const processLifeTime = eventInfo.params['process_life_time'];
    if (processLifeTime === undefined) return null;
    return processLifeTime as number;
  }

  static extractPageSwitchLog(eventInfo: hiAppEvent.AppEventInfo): string | null {
    const pageSwitchLog = eventInfo.params['page_switch_log'];
    if (pageSwitchLog === undefined) return null;
    return pageSwitchLog as string;
  }
}