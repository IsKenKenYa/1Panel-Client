/**
 * HiAppEvent订阅任务执行超时事件示例
 * API: hiAppEvent.addWatcher, hiAppEvent.removeWatcher
 * 事件: APP_HICOLLIE (任务执行超时事件)
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 创建事件观察者并订阅任务执行超时事件
 */
export function subscribeHiCollieEvent(): void {
  const watcher: hiAppEvent.Watcher = {
    // 观察者名称（唯一标识）
    name: "hicollie_watcher",
    
    // 事件过滤条件：订阅任务执行超时事件
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,          // 系统事件领域
        names: [hiAppEvent.event.APP_HICOLLIE] // 任务执行超时事件
      }
    ],
    
    // 实时回调函数
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      hilog.info(0x0000, 'HiCollieWatcher', `onReceive triggered, domain=${domain}`);
      
      // 处理事件组
      for (const eventGroup of appEventGroups) {
        hilog.info(0x0000, 'HiCollieWatcher', `Event group: ${eventGroup.name}`);
        
        // 处理单个事件
        for (const eventInfo of eventGroup.appEventInfos) {
          parseAndLogEventInfo(eventInfo);
        }
      }
    }
  };
  
  // 添加观察者订阅事件
  try {
    const holder = hiAppEvent.addWatcher(watcher);
    if (holder) {
      hilog.info(0x0000, 'HiCollieWatcher', 'Successfully subscribed to APP_HICOLLIE event');
    } else {
      hilog.error(0x0000, 'HiCollieWatcher', 'Failed to subscribe, addWatcher returned null');
    }
  } catch (error) {
    hilog.error(0x0000, 'HiCollieWatcher', `Subscription error: ${error.message}`);
  }
}

/**
 * 解析并记录事件详细信息
 */
function parseAndLogEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
  // 基本信息
  hilog.info(0x0000, 'HiCollieWatcher', `--- Event Info ---`);
  hilog.info(0x0000, 'HiCollieWatcher', `Domain: ${eventInfo.domain}`);
  hilog.info(0x0000, 'HiCollieWatcher', `Name: ${eventInfo.name}`);
  hilog.info(0x0000, 'HiCollieWatcher', `Type: ${eventInfo.eventType}`);
  
  // 使用可选链安全访问params字段
  const params = eventInfo.params;
  
  // 时间戳
  if (params?.['time']) {
    hilog.info(0x0000, 'HiCollieWatcher', `Time: ${params['time']}`);
  }
  
  // 前台/后台状态
  if (params?.['foreground']) {
    hilog.info(0x0000, 'HiCollieWatcher', `Foreground: ${params['foreground']}`);
  }
  
  // 应用版本信息
  if (params?.['bundle_version']) {
    hilog.info(0x0000, 'HiCollieWatcher', `Bundle Version: ${params['bundle_version']}`);
  }
  
  // 进程信息
  if (params?.['process_name']) {
    hilog.info(0x0000, 'HiCollieWatcher', `Process Name: ${params['process_name']}`);
  }
  
  if (params?.['pid']) {
    hilog.info(0x0000, 'HiCollieWatcher', `PID: ${params['pid']}`);
  }
  
  if (params?.['uid']) {
    hilog.info(0x0000, 'HiCollieWatcher', `UID: ${params['uid']}`);
  }
  
  // UUID
  if (params?.['uuid']) {
    hilog.info(0x0000, 'HiCollieWatcher', `UUID: ${params['uuid']}`);
  }
  
  // 异常信息
  const exception = params?.['exception'];
  if (exception) {
    hilog.info(0x0000, 'HiCollieWatcher', `Exception: ${JSON.stringify(exception)}`);
  }
  
  // HiLog日志
  const hilogData = params?.['hilog'];
  if (hilogData && Array.isArray(hilogData)) {
    hilog.info(0x0000, 'HiCollieWatcher', `HiLog Count: ${hilogData.length}`);
    // 可选：输出每条日志
    for (let i = 0; i < Math.min(5, hilogData.length); i++) {
      hilog.info(0x0000, 'HiCollieWatcher', `HiLog[${i}]: ${hilogData[i]}`);
    }
  }
  
  // Peer Binder信息
  const peerBinder = params?.['peer_binder'];
  if (peerBinder && Array.isArray(peerBinder)) {
    hilog.info(0x0000, 'HiCollieWatcher', `Peer Binder Count: ${peerBinder.length}`);
  }
  
  // 内存信息
  const memory = params?.['memory'];
  if (memory) {
    hilog.info(0x0000, 'HiCollieWatcher', `Memory Info: ${JSON.stringify(memory)}`);
    if (typeof memory === 'object') {
      const memObj = memory as Record<string, number>;
      hilog.info(0x0000, 'HiCollieWatcher', `RSS: ${memObj['rss'] || 'N/A'}`);
      hilog.info(0x0000, 'HiCollieWatcher', `PSS: ${memObj['pss'] || 'N/A'}`);
      hilog.info(0x0000, 'HiCollieWatcher', `VSS: ${memObj['vss'] || 'N/A'}`);
    }
  }
  
  // 外部日志文件路径
  const externalLog = params?.['external_log'];
  if (externalLog && Array.isArray(externalLog)) {
    hilog.info(0x0000, 'HiCollieWatcher', `External Log Files: ${JSON.stringify(externalLog)}`);
  }
  
  // 日志超限标记
  if (params?.['log_over_limit']) {
    hilog.info(0x0000, 'HiCollieWatcher', `Log Over Limit: ${params['log_over_limit']}`);
  }
  
  // 外部回调日志
  const externalCallbackLog = params?.['external_callback_log'];
  if (externalCallbackLog) {
    hilog.info(0x0000, 'HiCollieWatcher', `External Callback Log: ${externalCallbackLog}`);
  }
  
  hilog.info(0x0000, 'HiCollieWatcher', `--- End Event Info ---`);
}

/**
 * 移除事件观察者取消订阅
 */
export function unsubscribeHiCollieEvent(): void {
  const watcher: hiAppEvent.Watcher = {
    name: "hicollie_watcher"
  };
  
  try {
    hiAppEvent.removeWatcher(watcher);
    hilog.info(0x0000, 'HiCollieWatcher', 'Successfully removed watcher');
  } catch (error) {
    hilog.error(0x0000, 'HiCollieWatcher', `Remove watcher error: ${error.message}`);
  }
}

/**
 * 完整示例：在EntryAbility中使用
 */
export class HiCollieEventSubscriber {
  private watcher: hiAppEvent.Watcher | null = null;
  
  /**
   * 初始化订阅（在应用启动时调用）
   */
  init(): void {
    this.watcher = {
      name: "hicollie_watcher_main",
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_HICOLLIE]
        }
      ],
      onReceive: this.handleEvent.bind(this)
    };
    
    hiAppEvent.addWatcher(this.watcher);
    hilog.info(0x0000, 'HiCollieSubscriber', 'Initialized');
  }
  
  /**
   * 事件处理回调
   */
  private handleEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(0x0000, 'HiCollieSubscriber', `Received event from domain: ${domain}`);
    
    for (const group of appEventGroups) {
      if (group.name === hiAppEvent.event.APP_HICOLLIE) {
        this.processHiCollieEvent(group.appEventInfos);
      }
    }
  }
  
  /**
   * 处理任务执行超时事件
   */
  private processHiCollieEvent(events: Array<hiAppEvent.AppEventInfo>): void {
    for (const event of events) {
      const pid = event.params?.['pid'];
      const processName = event.params?.['process_name'];
      
      hilog.warn(0x0000, 'HiCollieSubscriber', 
        `Task execution timeout detected in process ${processName} (PID: ${pid})`);
      
      // 可执行后续处理逻辑：
      // 1. 保存事件到本地数据库
      // 2. 上报异常到后台服务器
      // 3. 发送通知给开发团队
    }
  }
  
  /**
   * 清理订阅（在应用退出时调用）
   */
  cleanup(): void {
    if (this.watcher) {
      hiAppEvent.removeWatcher(this.watcher);
      this.watcher = null;
      hilog.info(0x0000, 'HiCollieSubscriber', 'Cleaned up');
    }
  }
}