// 主线程超时事件订阅错误处理示例
// 本示例演示常见错误的处理方法

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ErrorHandlingPage {
  
  // 错误码定义
  private readonly ERROR_CODE_401 = 401;           // 参数错误
  private readonly ERROR_CODE_11102001 = 11102001; // 观察者名称无效
  private readonly ERROR_CODE_11102002 = 11102002; // 事件领域无效
  private readonly ERROR_CODE_11102003 = 11102003; // row值无效
  private readonly ERROR_CODE_11102004 = 11102004; // size值无效
  private readonly ERROR_CODE_11102005 = 11102005; // timeout值无效
  
  // 测试：参数错误（未传入必填参数）
  testParameterError(): void {
    try {
      // 错误示例：name参数未传入（必填参数）
      hiAppEvent.addWatcher({
        // name: "testWatcher", // 注释掉name参数
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.MAIN_THREAD_JANK]
          }
        ]
      });
    } catch (error) {
      this.handleAddWatcherError(error as BusinessError);
    }
  }
  
  // 测试：观察者名称无效
  testInvalidWatcherName(): void {
    try {
      // 错误示例：名称包含无效字符（包含空格）
      hiAppEvent.addWatcher({
        name: "test watcher", // 包含空格，无效
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.MAIN_THREAD_JANK]
          }
        ]
      });
    } catch (error) {
      this.handleAddWatcherError(error as BusinessError);
    }
  }
  
  // 测试：观察者名称过长
  testWatcherNameTooLong(): void {
    try {
      // 错误示例：名称长度超过32个字符
      hiAppEvent.addWatcher({
        name: "thisIsAVeryLongWatcherNameThatExceedsTheMaximumAllowedLengthOfThirtyTwoCharacters",
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.MAIN_THREAD_JANK]
          }
        ]
      });
    } catch (error) {
      this.handleAddWatcherError(error as BusinessError);
    }
  }
  
  // 测试：事件领域无效
  testInvalidEventDomain(): void {
    try {
      // 错误示例：domain包含无效字符
      hiAppEvent.addWatcher({
        name: "testWatcher",
        appEventFilters: [
          {
            domain: "invalid domain!", // 包含空格和特殊字符
            names: [hiAppEvent.event.MAIN_THREAD_JANK]
          }
        ]
      });
    } catch (error) {
      this.handleAddWatcherError(error as BusinessError);
    }
  }
  
  // 统一的错误处理函数
  handleAddWatcherError(err: BusinessError): void {
    hilog.error(0x0000, 'ErrorHandling', `Error code: ${err.code}, message: ${err.message}`);
    
    switch (err.code) {
      case this.ERROR_CODE_401:
        hilog.error(0x0000, 'ErrorHandling', 
          'Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; ' +
          '2. Incorrect parameter types.');
        hilog.info(0x0000, 'ErrorHandling', 'Solution: Check if watcher name is provided and type is correct.');
        break;
        
      case this.ERROR_CODE_11102001:
        hilog.error(0x0000, 'ErrorHandling', 
          'Invalid watcher name. Possible causes: 1. Contain invalid characters; ' +
          '2. Length is invalid.');
        hilog.info(0x0000, 'ErrorHandling', 
          'Solution: Name must start with letter, contain only letters/numbers/underscores, ' +
          'end with letter/number, length <= 32.');
        break;
        
      case this.ERROR_CODE_11102002:
        hilog.error(0x0000, 'ErrorHandling', 
          'Invalid filtering event domain. Possible causes: 1. Contain invalid characters; ' +
          '2. Length is invalid.');
        hilog.info(0x0000, 'ErrorHandling', 
          'Solution: Use hiAppEvent.domain.OS for system events, or check custom domain format.');
        break;
        
      case this.ERROR_CODE_11102003:
        hilog.error(0x0000, 'ErrorHandling', 
          'Invalid row value. Possible caused by the row value is less than zero.');
        hilog.info(0x0000, 'ErrorHandling', 'Solution: Ensure triggerCondition.row is a positive integer.');
        break;
        
      case this.ERROR_CODE_11102004:
        hilog.error(0x0000, 'ErrorHandling', 
          'Invalid size value. Possible caused by the size value is less than zero.');
        hilog.info(0x0000, 'ErrorHandling', 'Solution: Ensure triggerCondition.size is a positive integer.');
        break;
        
      case this.ERROR_CODE_11102005:
        hilog.error(0x0000, 'ErrorHandling', 
          'Invalid timeout value. Possible caused by the timeout value is less than zero.');
        hilog.info(0x0000, 'ErrorHandling', 'Solution: Ensure triggerCondition.timeOut is a positive integer.');
        break;
        
      default:
        hilog.error(0x0000, 'ErrorHandling', `Unknown error code: ${err.code}`);
        hilog.info(0x0000, 'ErrorHandling', 'Solution: Check API documentation for this error code.');
    }
  }
  
  // 正确的订阅示例（对比错误示例）
  correctSubscriptionExample(): void {
    try {
      // 正确示例：所有参数符合规范
      hiAppEvent.addWatcher({
        name: "correctWatcher", // 名称符合规范
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS, // 使用系统领域常量
            names: [hiAppEvent.event.MAIN_THREAD_JANK]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.info(0x0000, 'CorrectExample', `Received event: domain=${domain}`);
        }
      });
      hilog.info(0x0000, 'ErrorHandling', 'Subscription successful with correct parameters.');
    } catch (error) {
      this.handleAddWatcherError(error as BusinessError);
    }
  }
  
  build() {
    Column() {
      Text('错误处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      Button('测试：参数错误（必填参数未指定）')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.testParameterError();
        });
      
      Button('测试：观察者名称无效（包含空格）')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.testInvalidWatcherName();
        });
      
      Button('测试：观察者名称过长')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.testWatcherNameTooLong();
        });
      
      Button('测试：事件领域无效')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.testInvalidEventDomain();
        });
      
      Button('正确的订阅示例')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .backgroundColor('#4CAF50')
        .onClick(() => {
          this.correctSubscriptionExample();
        });
    }
    .width('100%')
    .height('100%');
  }
}