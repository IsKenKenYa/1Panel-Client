/**
 * CPU高负载事件订阅完整示例
 * 功能：订阅CPU高负载事件，配置自定义策略，处理事件回调
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class CpuUsageHighWatcher {
  private watcherName: string = 'cpuWatcher';
  
  /**
   * 初始化CPU高负载事件订阅
   */
  public async init(): Promise<void> {
    // 步骤1：配置CPU高负载策略（可选）
    await this.configCpuPolicy();
    
    // 步骤2：订阅CPU高负载事件
    this.subscribeCpuEvent();
    
    hilog.info(0x0000, 'CpuWatcher', 'CPU usage high watcher initialized');
  }
  
  /**
   * 配置CPU高负载检测策略
   */
  private async configCpuPolicy(): Promise<void> {
    let policy: hiAppEvent.EventPolicy = {
      "cpuUsageHighPolicy": {
        "foregroundLoadThreshold": 10,   // 应用前台CPU负载异常阈值10%
        "backgroundLoadThreshold": 5,    // 应用后台CPU负载异常阈值5%
        "threadLoadThreshold": 50,       // 应用线程CPU负载异常阈值50%
        "perfLogCaptureCount": 3,        // 采样栈每日采集次数上限3次
        "threadLoadInterval": 30,        // 应用线程负载异常检测周期30秒
      }
    };
    
    try {
      await hiAppEvent.configEventPolicy(policy);
      hilog.info(0x0000, 'CpuWatcher', 'Successfully set CPU usage high event policy');
    } catch (err) {
      let error = err as BusinessError;
      hilog.error(0x0000, 'CpuWatcher', `Failed to set policy. Code: ${error?.code}, message: ${error?.message}`);
    }
  }
  
  /**
   * 订阅CPU高负载事件
   */
  private subscribeCpuEvent(): void {
    hiAppEvent.addWatcher({
      name: this.watcherName,
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.CPU_USAGE_HIGH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        this.handleCpuEvent(domain, appEventGroups);
      }
    });
    
    hilog.info(0x0000, 'CpuWatcher', 'CPU usage high event subscribed');
  }
  
  /**
   * 处理CPU高负载事件回调
   */
  private handleCpuEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(0x0000, 'CpuWatcher', `Received event from domain: ${domain}`);
    
    for (const eventGroup of appEventGroups) {
      if (eventGroup.name === hiAppEvent.event.CPU_USAGE_HIGH) {
        hilog.info(0x0000, 'CpuWatcher', `Event name: ${eventGroup.name}`);
        
        for (const eventInfo of eventGroup.appEventInfos) {
          this.parseCpuEventInfo(eventInfo);
        }
      }
    }
  }
  
  /**
   * 解析CPU高负载事件信息
   */
  private parseCpuEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    const params = eventInfo.params as Record<string, Object>;
    
    // 解析基本信息
    const usage = params['usage'] as number;
    const beginTime = params['begin_time'] as number;
    const endTime = params['end_time'] as number;
    const bundleName = params['bundle_name'] as string;
    const bundleVersion = params['bundle_version'] as string;
    const foreground = params['foreground'] as boolean;
    const faultType = params['fault_type'] as number;
    
    hilog.info(0x0000, 'CpuWatcher', `CPU usage: ${usage}%`);
    hilog.info(0x0000, 'CpuWatcher', `Bundle: ${bundleName} (${bundleVersion})`);
    hilog.info(0x0000, 'CpuWatcher', `Foreground: ${foreground}, Fault type: ${faultType}`);
    hilog.info(0x0000, 'CpuWatcher', `Time: ${beginTime} - ${endTime}`);
    
    // 解析线程信息
    const threads = params['threads'] as Array<Record<string, number | string>>;
    hilog.info(0x0000, 'CpuWatcher', `Thread count: ${threads.length}`);
    for (const thread of threads) {
      const threadName = thread['name'] as string;
      const tid = thread['tid'] as number;
      const threadUsage = thread['usage'] as number;
      hilog.info(0x0000, 'CpuWatcher', `Thread: ${threadName}, tid=${tid}, usage=${threadUsage}%`);
    }
    
    // 解析采样栈日志路径
    const externalLog = params['external_log'] as Array<string>;
    if (externalLog && externalLog.length > 0) {
      hilog.info(0x0000, 'CpuWatcher', `External log files: ${externalLog.length}`);
      for (const logPath of externalLog) {
        hilog.info(0x0000, 'CpuWatcher', `Log: ${logPath}`);
      }
    }
    
    // 解析日志限制标志
    const logOverLimit = params['log_over_limit'] as boolean;
    if (logOverLimit) {
      hilog.warn(0x0000, 'CpuWatcher', 'Log collection limit exceeded');
    }
  }
  
  /**
   * 移除CPU高负载事件订阅
   */
  public unsubscribe(): void {
    hiAppEvent.removeWatcher({
      name: this.watcherName
    });
    
    hilog.info(0x0000, 'CpuWatcher', 'CPU usage high event unsubscribed');
  }
}

// 使用示例
export function testCpuWatcher(): void {
  let watcher = new CpuUsageHighWatcher();
  
  // 初始化订阅
  watcher.init().then(() => {
    hilog.info(0x0000, 'TestTag', 'Watcher initialized successfully');
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'TestTag', `Init failed: ${err.message}`);
  });
  
  // 在需要取消订阅时调用
  // watcher.unsubscribe();
}