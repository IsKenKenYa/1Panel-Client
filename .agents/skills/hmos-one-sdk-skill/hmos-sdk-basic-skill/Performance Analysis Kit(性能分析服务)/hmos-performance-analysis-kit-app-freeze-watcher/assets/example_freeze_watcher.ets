/**
 * 应用冻屏事件订阅完整示例代码
 * 本示例演示如何使用HiAppEvent订阅应用冻屏事件(APP_FREEZE)
 * 
 * 功能说明:
 * 1. 导入必要的依赖模块
 * 2. 设置应用冻屏事件的自定义参数
 * 3. 配置页面切换日志(API version >= 24)
 * 4. 添加应用冻屏事件观察者
 * 5. 处理冻屏事件回调数据
 * 6. 提取冻屏事件的各项参数字段
 */

import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 定义观察者名称(需符合命名规范)
const WATCHER_NAME: string = "freezeWatcher";

// 定义日志标签
const LOG_DOMAIN: number = 0x0000;
const LOG_TAG: string = 'FreezeWatcher';

/**
 * 主入口函数
 * 在应用启动时调用,初始化冻屏事件订阅
 */
export function initFreezeWatcher(): void {
  try {
    // 步骤1: 设置事件自定义参数
    setEventCustomParams();
    
    // 步骤2: 配置页面切换日志(API version >= 24)
    if (deviceInfo.sdkApiVersion >= 24) {
      configPageSwitchLog();
    }
    
    // 步骤3: 添加冻屏事件观察者
    addFreezeWatcher();
    
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Freeze watcher initialized successfully');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to initialize freeze watcher: code=${err.code}, message=${err.message}`);
  }
}

/**
 * 设置应用冻屏事件的自定义参数
 * 自定义参数会在冻屏事件发生时附加到事件参数中
 */
function setEventCustomParams(): void {
  // 定义自定义参数对象
  let params: Record<string, hiAppEvent.ParamType> = {
    "test_data": 100,
    "custom_key": "custom_value",
    "app_version": "1.0.0",
    "user_id": "12345",
  };
  
  // 设置应用冻屏事件的自定义参数
  hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.APP_FREEZE).then(() => {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Success to set event custom params');
  }).catch((err: BusinessError) => {
    hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to set event params: code=${err.code}, message=${err.message}`);
  });
}

/**
 * 配置页面切换日志
 * 仅API version 24及以后版本支持
 */
function configPageSwitchLog(): void {
  // 配置页面切换日志策略
  let switchLogPolicy: hiAppEvent.EventPolicy = {
    "appFreezePolicy": {
      "pageSwitchLogEnable": true
    }
  };
  
  // 设置应用冻屏日志配置参数
  hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Success to config page switch log policy');
  }).catch((err: BusinessError) => {
    hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to config event policy: code=${err.code}, message=${err.message}`);
  });
}

/**
 * 添加应用冻屏事件观察者
 * 订阅APP_FREEZE事件并实现回调函数
 */
function addFreezeWatcher(): void {
  // 添加应用冻屏事件观察者
  hiAppEvent.addWatcher({
    // 观察者名称,用于唯一标识观察者
    name: WATCHER_NAME,
    // 订阅过滤条件,订阅应用冻屏事件
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_FREEZE]
      }
    ],
    // 订阅实时回调函数,监听到事件后实时回调
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      hilog.info(LOG_DOMAIN, LOG_TAG, `Received freeze event: domain=${domain}`);
      
      // 处理事件组
      for (const eventGroup of appEventGroups) {
        hilog.info(LOG_DOMAIN, LOG_TAG, `Event group: name=${eventGroup.name}`);
        
        // 处理事件对象
        for (const eventInfo of eventGroup.appEventInfos) {
          processFreezeEvent(eventInfo);
        }
      }
    }
  });
}

/**
 * 处理应用冻屏事件数据
 * 提取并记录冻屏事件的各项参数字段
 * 
 * @param eventInfo 冻屏事件信息对象
 */
function processFreezeEvent(eventInfo: hiAppEvent.AppEventInfo): void {
  hilog.info(LOG_DOMAIN, LOG_TAG, '=== Processing Freeze Event ===');
  
  // 获取事件基本信息
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Domain: ${eventInfo.domain}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Name: ${eventInfo.name}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Type: ${eventInfo.eventType}`);
  
  // 获取时间戳
  const timestamp = eventInfo.params['time'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Timestamp: ${timestamp}`);
  
  // 获取前后台状态
  const foreground = eventInfo.params['foreground'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Foreground: ${foreground}`);
  
  // 获取应用唯一关联ID
  const appRunningUniqueId = eventInfo.params['app_running_unique_id'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `App Running Unique ID: ${appRunningUniqueId}`);
  
  // 获取应用版本信息
  const bundleVersion = eventInfo.params['bundle_version'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Bundle Version: ${bundleVersion}`);
  
  // 获取应用包名
  const bundleName = eventInfo.params['bundle_name'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Bundle Name: ${bundleName}`);
  
  // 获取进程名称
  const processName = eventInfo.params['process_name'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Process Name: ${processName}`);
  
  // 获取进程ID
  const pid = eventInfo.params['pid'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `PID: ${pid}`);
  
  // 获取用户ID
  const uid = eventInfo.params['uid'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `UID: ${uid}`);
  
  // 获取UUID
  const uuid = eventInfo.params['uuid'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `UUID: ${uuid}`);
  
  // 获取异常信息
  const exception = eventInfo.params['exception'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Exception: ${JSON.stringify(exception)}`);
  
  // 解析异常类型和原因
  if (exception && typeof exception === 'object') {
    const exceptionName = exception['name'];
    const exceptionMessage = exception['message'];
    hilog.info(LOG_DOMAIN, LOG_TAG, `Exception Name: ${exceptionName}`);
    hilog.info(LOG_DOMAIN, LOG_TAG, `Exception Message: ${exceptionMessage}`);
  }
  
  // 获取日志信息
  const hilogData = eventInfo.params['hilog'];
  if (Array.isArray(hilogData)) {
    hilog.info(LOG_DOMAIN, LOG_TAG, `Hilog Size: ${hilogData.length}`);
  }
  
  // 获取主线程未处理消息
  const eventHandler = eventInfo.params['event_handler'];
  if (Array.isArray(eventHandler)) {
    hilog.info(LOG_DOMAIN, LOG_TAG, `Event Handler Size: ${eventHandler.length}`);
  }
  
  const eventHandlerSize3s = eventInfo.params['event_handler_size_3s'];
  const eventHandlerSize6s = eventInfo.params['event_handler_size_6s'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Handler Size 3s: ${eventHandlerSize3s}`);
  hilog.info(LOG_DOMAIN, LOG_TAG, `Event Handler Size 6s: ${eventHandlerSize6s}`);
  
  // 获取同步binder调用信息
  const peerBinder = eventInfo.params['peer_binder'];
  if (Array.isArray(peerBinder)) {
    hilog.info(LOG_DOMAIN, LOG_TAG, `Peer Binder Size: ${peerBinder.length}`);
  }
  
  // 获取全量线程调用栈
  const threads = eventInfo.params['threads'];
  if (Array.isArray(threads)) {
    hilog.info(LOG_DOMAIN, LOG_TAG, `Threads Size: ${threads.length}`);
  }
  
  // 获取内存信息
  const memory = eventInfo.params['memory'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Memory: ${JSON.stringify(memory)}`);
  
  // 获取故障日志文件路径
  const externalLog = eventInfo.params['external_log'];
  if (Array.isArray(externalLog)) {
    hilog.info(LOG_DOMAIN, LOG_TAG, `External Log: ${JSON.stringify(externalLog)}`);
    // 可以进一步读取日志文件内容
    for (const logPath of externalLog) {
      hilog.info(LOG_DOMAIN, LOG_TAG, `Log File Path: ${logPath}`);
    }
  }
  
  const logOverLimit = eventInfo.params['log_over_limit'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Log Over Limit: ${logOverLimit}`);
  
  // 获取自定义参数
  const testData = eventInfo.params['test_data'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Custom Test Data: ${testData}`);
  
  const customKey = eventInfo.params['custom_key'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Custom Key: ${customKey}`);
  
  // 获取进程存活时间
  const processLifeTime = eventInfo.params['process_life_time'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `Process Life Time: ${processLifeTime}`);
  
  // 获取回调日志信息
  const externalCallbackLog = eventInfo.params['external_callback_log'];
  hilog.info(LOG_DOMAIN, LOG_TAG, `External Callback Log: ${externalCallbackLog}`);
  
  // 获取页面切换日志
  const pageSwitchLog = eventInfo.params['page_switch_log'];
  if (pageSwitchLog) {
    hilog.info(LOG_DOMAIN, LOG_TAG, `Page Switch Log: ${JSON.stringify(pageSwitchLog)}`);
  }
  
  hilog.info(LOG_DOMAIN, LOG_TAG, '=== Freeze Event Processed ===');
}

/**
 * 移除应用冻屏事件观察者
 * 用于取消订阅冻屏事件
 */
export function removeFreezeWatcher(): void {
  try {
    let watcher: hiAppEvent.Watcher = {
      name: WATCHER_NAME,
    };
    
    hiAppEvent.removeWatcher(watcher);
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Freeze watcher removed successfully');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to remove freeze watcher: code=${err.code}, message=${err.message}`);
  }
}

/**
 * 触发应用冻屏事件(仅用于测试)
 * 警告:此函数会阻塞主线程,仅用于测试场景
 */
export function triggerFreezeForTest(): void {
  hilog.warn(LOG_DOMAIN, LOG_TAG, 'Triggering freeze event for test only!');
  
  // 构造应用冻屏场景:主线程阻塞15秒
  setTimeout(() => {
    let startTime = Date.now();
    while (Date.now() - startTime <= 15000) {
      // 主线程阻塞,触发冻屏事件
    }
  }, 5000);
}

/**
 * 获取冻屏日志文件内容(示例)
 * 
 * @param logPath 日志文件路径
 * @returns 日志文件内容(需要根据实际情况实现)
 */
export function readFreezeLogFile(logPath: string): string {
  // 注意:需要根据实际情况实现文件读取逻辑
  // 这里仅提供示例代码框架
  hilog.info(LOG_DOMAIN, LOG_TAG, `Reading freeze log file: ${logPath}`);
  
  // 实际实现可能需要使用文件API读取日志内容
  // 例如:使用@kit.CoreFileKit中的文件读取接口
  
  return "Log file content placeholder";
}

/**
 * 解析冻屏异常类型
 * 根据exception.name字段判断冻屏的具体类型
 * 
 * @param exceptionName 异常名称
 * @returns 异常类型描述
 */
export function parseFreezeExceptionType(exceptionName: string): string {
  const exceptionTypes: Record<string, string> = {
    'THREAD_BLOCK_3S': '主线程阻塞3秒',
    'THREAD_BLOCK_6S': '主线程阻塞6秒',
    'APP_NOT_RESPONSE': '应用无响应',
  };
  
  return exceptionTypes[exceptionName] || `未知异常类型: ${exceptionName}`;
}

/**
 * 导出冻屏事件处理结果(可选)
 * 用于上报或保存冻屏事件信息
 */
export interface FreezeEventResult {
  timestamp: number;
  bundleName: string;
  processName: string;
  pid: number;
  uid: number;
  exceptionName: string;
  exceptionMessage: string;
  foreground: boolean;
  logFilePath: string;
  customParams: Record<string, hiAppEvent.ParamType>;
}

/**
 * 构造冻屏事件结果对象
 * 
 * @param eventInfo 冻屏事件信息
 * @returns 冻屏事件结果对象
 */
export function buildFreezeEventResult(eventInfo: hiAppEvent.AppEventInfo): FreezeEventResult {
  const exception = eventInfo.params['exception'];
  const externalLog = eventInfo.params['external_log'];
  
  return {
    timestamp: eventInfo.params['time'],
    bundleName: eventInfo.params['bundle_name'],
    processName: eventInfo.params['process_name'],
    pid: eventInfo.params['pid'],
    uid: eventInfo.params['uid'],
    exceptionName: exception?.['name'] || 'Unknown',
    exceptionMessage: exception?.['message'] || 'Unknown',
    foreground: eventInfo.params['foreground'],
    logFilePath: Array.isArray(externalLog) && externalLog.length > 0 ? externalLog[0] : '',
    customParams: {
      'test_data': eventInfo.params['test_data'],
      'custom_key': eventInfo.params['custom_key'],
    },
  };
}