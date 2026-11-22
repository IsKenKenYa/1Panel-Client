/**
 * HiAppEvent 事件打点示例
 * 演示应用自定义事件打点写入
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiAppEventWrite';
const DOMAIN = 0x0000;

export class HiAppEventWriteExample {
  /**
   * 写入用户行为事件（Promise 模式）
   */
  writeUserBehaviorEvent(userId: string, action: string, timestamp: number): void {
    const eventParams: Record<string, string | number> = {
      'user_id': userId,
      'action': action,
      'timestamp': timestamp,
      'page_name': 'HomePage',
      'device_type': 'Mobile'
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'user_behavior',
      name: hiAppEvent.event.USER_LOGIN,
      eventType: hiAppEvent.EventType.BEHAVIOR,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, 'User behavior event write success');
      })
      .catch((err: BusinessError) => {
        this.handleWriteError(err);
      });
  }

  /**
   * 写入按钮点击事件（Callback 模式）
   */
  writeButtonClickEvent(buttonName: string, clickTime: number): void {
    const eventParams: Record<string, number | string> = {
      'clickTime': clickTime,
      'buttonName': buttonName,
      'clickCount': 1
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'button',
      name: 'click',
      eventType: hiAppEvent.EventType.BEHAVIOR,
      params: eventParams
    };

    hiAppEvent.write(eventInfo, (err: BusinessError) => {
      if (err) {
        this.handleWriteError(err);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Button click event write success');
    });
  }

  /**
   * 写入性能统计事件
   */
  writePerformanceStatEvent(operationName: string, duration: number, success: boolean): void {
    const eventParams: Record<string, number | boolean | string> = {
      'operation': operationName,
      'duration_ms': duration,
      'success': success,
      'timestamp': Date.now()
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'performance',
      name: 'operation_stat',
      eventType: hiAppEvent.EventType.STATISTIC,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, `Performance stat event write success: ${operationName}`);
      })
      .catch((err: BusinessError) => {
        this.handleWriteError(err);
      });
  }

  /**
   * 写入故障事件
   */
  writeFaultEvent(errorType: string, errorMessage: string, stackTrace: string): void {
    const eventParams: Record<string, string> = {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace.substring(0, 1024),
      'timestamp': Date.now().toString()
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'fault',
      name: 'app_error',
      eventType: hiAppEvent.EventType.FAULT,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, `Fault event write success: ${errorType}`);
      })
      .catch((err: BusinessError) => {
        this.handleWriteError(err);
      });
  }

  /**
   * 写入安全事件
   */
  writeSecurityEvent(eventType: string, riskLevel: string, details: string): void {
    const eventParams: Record<string, string> = {
      'event_type': eventType,
      'risk_level': riskLevel,
      'details': details,
      'timestamp': Date.now().toString()
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'security',
      name: 'security_check',
      eventType: hiAppEvent.EventType.SECURITY,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, `Security event write success: ${eventType}`);
      })
      .catch((err: BusinessError) => {
        this.handleWriteError(err);
      });
  }

  /**
   * 批量写入事件
   */
  batchWriteUserEvents(events: Array<{userId: string, action: string, timestamp: number}>): void {
    for (const event of events) {
      const eventParams: Record<string, string | number> = {
        'user_id': event.userId,
        'action': event.action,
        'timestamp': event.timestamp
      };

      const eventInfo: hiAppEvent.AppEventInfo = {
        domain: 'user_behavior',
        name: 'user_action',
        eventType: hiAppEvent.EventType.BEHAVIOR,
        params: eventParams
      };

      hiAppEvent.write(eventInfo)
        .then(() => {
          hilog.info(DOMAIN, TAG, `Batch write success: ${event.action}`);
        })
        .catch((err: BusinessError) => {
          this.handleWriteError(err);
        });
    }
  }

  /**
   * 写入带数组参数的事件
   */
  writeEventWithArrayParams(eventName: string, items: string[]): void {
    const eventParams: Record<string, string[] | string> = {
      'event_name': eventName,
      'items': items.slice(0, 100),
      'timestamp': Date.now().toString()
    };

    const eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'data_collection',
      name: 'item_list',
      eventType: hiAppEvent.EventType.STATISTIC,
      params: eventParams
    };

    hiAppEvent.write(eventInfo)
      .then(() => {
        hilog.info(DOMAIN, TAG, `Event with array params write success: ${eventName}`);
      })
      .catch((err: BusinessError) => {
        this.handleWriteError(err);
      });
  }

  /**
   * 错误处理
   */
  private handleWriteError(err: BusinessError): void {
    hilog.error(DOMAIN, TAG, `Write failed: code=${err.code}, message=${err.message}`);
    
    switch (err.code) {
      case 11100001:
        hilog.error(DOMAIN, TAG, 'Function disabled, please enable in configure');
        break;
      case 11101001:
        hilog.error(DOMAIN, TAG, 'Invalid event domain');
        break;
      case 11101002:
        hilog.error(DOMAIN, TAG, 'Invalid event name');
        break;
      case 11101003:
        hilog.error(DOMAIN, TAG, 'Too many event parameters (max 32)');
        break;
      case 11101004:
        hilog.error(DOMAIN, TAG, 'Event parameter string too long (max 8KB)');
        break;
      case 11101005:
        hilog.error(DOMAIN, TAG, 'Invalid event parameter name');
        break;
      case 11101006:
        hilog.error(DOMAIN, TAG, 'Event parameter array too long (max 100 elements)');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${err.message}`);
    }
  }
}

/**
 * 使用示例
 */
export function runHiAppEventWriteExample(): void {
  const writeExample = new HiAppEventWriteExample();
  
  writeExample.writeUserBehaviorEvent('user123', 'login', Date.now());
  writeExample.writeButtonClickEvent('SubmitButton', 100);
  writeExample.writePerformanceStatEvent('database_query', 150, true);
  writeExample.writeFaultEvent('NetworkError', 'Connection timeout', 'stack_trace_here');
  writeExample.writeSecurityEvent('permission_check', 'low', 'No risk detected');
  writeExample.writeEventWithArrayParams('product_list', ['item1', 'item2', 'item3']);
  
  const batchEvents = [
    { userId: 'user1', action: 'click', timestamp: Date.now() },
    { userId: 'user2', action: 'view', timestamp: Date.now() },
    { userId: 'user3', action: 'purchase', timestamp: Date.now() }
  ];
  writeExample.batchWriteUserEvents(batchEvents);
}