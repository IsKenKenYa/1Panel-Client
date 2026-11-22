/**
 * 地址越界事件订阅完整示例
 * 用于演示如何订阅ADDRESS_SANITIZER系统事件
 * 
 * 功能：
 * 1. 配置页面切换日志（API 24+）
 * 2. 添加观察者订阅地址越界事件
 * 3. 实时接收并处理事件回调
 * 4. 解析事件详情并记录日志
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';

/**
 * 配置地址越界日志策略
 * 仅在API version 24+支持页面切换日志
 */
function configureAddressSanitizerPolicy(): void {
  // 校验API版本
  if (deviceInfo.sdkApiVersion >= 24) {
    // 配置页面切换日志策略
    let switchLogPolicy: hiAppEvent.EventPolicy = {
      "addressSanitizerPolicy": {
        "pageSwitchLogEnable": true  // 启用页面切换日志记录
      }
    };
    
    // 调用配置接口
    hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
      hilog.info(0x0000, 'AddressSanitizer', 'Success to config event policy with page switch log.');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'AddressSanitizer', 
        `Failed to config event policy. Code: ${err.code}, Message: ${err.message}`);
    });
  } else {
    hilog.warn(0x0000, 'AddressSanitizer', 
      `API version ${deviceInfo.sdkApiVersion} < 24, page switch log not supported.`);
  }
}

/**
 * 处理地址越界事件回调
 * 解析事件详情并记录日志
 */
function handleAddressSanitizerEvent(
  domain: string, 
  appEventGroups: Array<hiAppEvent.AppEventGroup>
): void {
  hilog.info(0x0000, 'AddressSanitizer', `Received event. Domain: ${domain}`);
  
  // 遍历事件组
  for (const eventGroup of appEventGroups) {
    hilog.info(0x0000, 'AddressSanitizer', `Event name: ${eventGroup.name}`);
    
    // 遍历事件信息
    for (const eventInfo of eventGroup.appEventInfos) {
      try {
        // 记录基本信息
        hilog.info(0x0000, 'AddressSanitizer', `Domain: ${eventInfo.domain}`);
        hilog.info(0x0000, 'AddressSanitizer', `Name: ${eventInfo.name}`);
        hilog.info(0x0000, 'AddressSanitizer', `Type: ${eventInfo.eventType}`);
        
        // 记录时间信息
        hilog.info(0x0000, 'AddressSanitizer', 
          `Time: ${eventInfo.params['time']}`);
        
        // 记录应用信息
        hilog.info(0x0000, 'AddressSanitizer', 
          `Bundle name: ${eventInfo.params['bundle_name']}`);
        hilog.info(0x0000, 'AddressSanitizer', 
          `Bundle version: ${eventInfo.params['bundle_version']}`);
        
        // 记录进程信息
        hilog.info(0x0000, 'AddressSanitizer', 
          `PID: ${eventInfo.params['pid']}`);
        hilog.info(0x0000, 'AddressSanitizer', 
          `UID: ${eventInfo.params['uid']}`);
        
        // 记录错误类型
        const errorType = eventInfo.params['type'] as string;
        hilog.info(0x0000, 'AddressSanitizer', `Error type: ${errorType}`);
        
        // 记录日志文件路径
        const externalLog = eventInfo.params['external_log'] as Array<string>;
        hilog.info(0x0000, 'AddressSanitizer', 
          `External log files: ${JSON.stringify(externalLog)}`);
        
        // 记录日志是否超限
        const logOverLimit = eventInfo.params['log_over_limit'] as boolean;
        hilog.info(0x0000, 'AddressSanitizer', 
          `Log over limit: ${logOverLimit}`);
        
        // 记录页面切换日志（API 24+）
        if (deviceInfo.sdkApiVersion >= 24) {
          const pageSwitchLog = eventInfo.params['page_switch_log'];
          if (pageSwitchLog) {
            hilog.info(0x0000, 'AddressSanitizer', 
              `Page switch log: ${JSON.stringify(pageSwitchLog)}`);
          }
        }
        
        // 根据错误类型输出详细信息
        if (errorType.includes('overflow')) {
          hilog.error(0x0000, 'AddressSanitizer', 
            'Buffer overflow detected. Check array bounds.');
        } else if (errorType.includes('use-after-free')) {
          hilog.error(0x0000, 'AddressSanitizer', 
            'Use-after-free detected. Check memory lifecycle.');
        }
        
      } catch (error) {
        hilog.error(0x0000, 'AddressSanitizer', 
          `Error processing event: ${JSON.stringify(error)}`);
      }
    }
  }
}

/**
 * 添加观察者订阅地址越界事件
 */
function subscribeAddressSanitizerEvent(): void {
  // 定义观察者配置
  const watcher: hiAppEvent.Watcher = {
    name: "address_sanitizer_watcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.ADDRESS_SANITIZER]
      }
    ],
    onReceive: handleAddressSanitizerEvent
  };
  
  // 添加观察者
  try {
    hiAppEvent.addWatcher(watcher);
    hilog.info(0x0000, 'AddressSanitizer', 
      'Successfully added watcher for ADDRESS_SANITIZER event.');
  } catch (error) {
    hilog.error(0x0000, 'AddressSanitizer', 
      `Failed to add watcher: ${JSON.stringify(error)}`);
  }
}

/**
 * 移除观察者取消订阅
 */
function unsubscribeAddressSanitizerEvent(): void {
  const watcher: hiAppEvent.Watcher = {
    name: "address_sanitizer_watcher"
  };
  
  try {
    hiAppEvent.removeWatcher(watcher);
    hilog.info(0x0000, 'AddressSanitizer', 
      'Successfully removed watcher.');
  } catch (error) {
    hilog.error(0x0000, 'AddressSanitizer', 
      `Failed to remove watcher: ${JSON.stringify(error)}`);
  }
}

/**
 * 主入口：在应用启动时订阅事件
 */
export function initializeAddressSanitizerWatcher(): void {
  hilog.info(0x0000, 'AddressSanitizer', 
    'Initializing ADDRESS_SANITIZER watcher...');
  
  // 配置日志策略
  configureAddressSanitizerPolicy();
  
  // 订阅事件
  subscribeAddressSanitizerEvent();
  
  hilog.info(0x0000, 'AddressSanitizer', 
    'ADDRESS_SANITIZER watcher initialized successfully.');
}

/**
 * 清理：在应用退出时取消订阅
 */
export function cleanupAddressSanitizerWatcher(): void {
  hilog.info(0x0000, 'AddressSanitizer', 
    'Cleaning up ADDRESS_SANITIZER watcher...');
  
  unsubscribeAddressSanitizerEvent();
  
  hilog.info(0x0000, 'AddressSanitizer', 
    'ADDRESS_SANITIZER watcher cleaned up successfully.');
}