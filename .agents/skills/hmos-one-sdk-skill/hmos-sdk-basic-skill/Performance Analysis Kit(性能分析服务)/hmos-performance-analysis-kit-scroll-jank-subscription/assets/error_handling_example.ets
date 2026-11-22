import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ScrollJankErrorHandling';
const DOMAIN = 0xFF00;

export class ScrollJankErrorHandling {

  testInvalidWatcherName(): void {
    hilog.info(DOMAIN, TAG, '测试非法观察者名称');
    
    const invalidNames: string[] = [
      '123watcher',
      'watcher_',
      'watcher-name',
      'watcher name',
      '',
      'a'.repeat(33)
    ];

    for (const name of invalidNames) {
      try {
        hiAppEvent.addWatcher({
          name: name,
          appEventFilters: [
            {
              domain: hiAppEvent.domain.OS,
              names: [hiAppEvent.event.SCROLL_JANK]
            }
          ]
        });
        hilog.error(DOMAIN, TAG, '测试失败: 非法名称 ' + name + ' 未被拦截');
      } catch (error) {
        const err = error as BusinessError;
        hilog.info(DOMAIN, TAG, '测试成功: 名称 ' + name + ' 被正确拦截, 错误码=' + err.code);
      }
    }
  }

  testMissingParameters(): void {
    hilog.info(DOMAIN, TAG, '测试参数缺失');
    
    try {
      hiAppEvent.addWatcher({
        name: undefined as any,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.SCROLL_JANK]
          }
        ]
      });
      hilog.error(DOMAIN, TAG, '测试失败: 缺少name参数未被拦截');
    } catch (error) {
      const err = error as BusinessError;
      hilog.info(DOMAIN, TAG, '测试成功: 缺少name参数被正确拦截, 错误码=' + err.code);
    }

    try {
      hiAppEvent.addWatcher({
        name: 'testWatcher'
      } as any);
      hilog.error(DOMAIN, TAG, '测试失败: 缺少appEventFilters未被拦截');
    } catch (error) {
      const err = error as BusinessError;
      hilog.info(DOMAIN, TAG, '测试成功: 缺少appEventFilters被正确拦截, 错误码=' + err.code);
    }
  }

  testInvalidDomain(): void {
    hilog.info(DOMAIN, TAG, '测试非法事件领域');
    
    try {
      hiAppEvent.addWatcher({
        name: 'testWatcher',
        appEventFilters: [
          {
            domain: 'invalid_domain_',
            names: [hiAppEvent.event.SCROLL_JANK]
          }
        ]
      });
      hilog.error(DOMAIN, TAG, '测试失败: 非法领域未被拦截');
    } catch (error) {
      const err = error as BusinessError;
      hilog.info(DOMAIN, TAG, '测试成功: 非法领域被正确拦截, 错误码=' + err.code);
    }
  }

  testCallbackError(): void {
    hilog.info(DOMAIN, TAG, '测试回调函数异常处理');
    
    try {
      hiAppEvent.addWatcher({
        name: 'errorCallbackWatcher',
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.SCROLL_JANK]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          throw new Error('模拟回调函数异常');
        }
      });
      
      hilog.info(DOMAIN, TAG, '订阅成功，等待事件触发测试回调异常处理');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, '订阅失败: ' + err.message);
    }
  }

  testRemoveWatcherInCallback(): void {
    hilog.info(DOMAIN, TAG, '测试在回调中移除观察者（不建议）');
    
    const watcherName = 'removeInCallbackWatcher';
    
    try {
      hiAppEvent.addWatcher({
        name: watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.SCROLL_JANK]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.warn(DOMAIN, TAG, '不建议在回调中移除观察者，会导致订阅失效');
          
          try {
            hiAppEvent.removeWatcher({
              name: watcherName
            });
            hilog.error(DOMAIN, TAG, '在回调中移除观察者成功，后续事件将无法接收');
          } catch (error) {
            const err = error as BusinessError;
            hilog.error(DOMAIN, TAG, '在回调中移除观察者失败: ' + err.message);
          }
        }
      });
      
      hilog.warn(DOMAIN, TAG, '订阅成功，但回调中移除观察者可能导致问题');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, '订阅失败: ' + err.message);
    }
  }

  testNullHolderHandling(): void {
    hilog.info(DOMAIN, TAG, '测试订阅失败返回null的处理');
    
    const holder = hiAppEvent.addWatcher({
      name: 'duplicateWatcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.SCROLL_JANK]
        }
      ]
    });

    if (holder === null) {
      hilog.error(DOMAIN, TAG, '订阅失败返回null，需检查参数配置');
    } else {
      hilog.info(DOMAIN, TAG, '订阅成功');
    }

    const holder2 = hiAppEvent.addWatcher({
      name: 'duplicateWatcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.SCROLL_JANK]
        }
      ]
    });

    if (holder2 === null) {
      hilog.info(DOMAIN, TAG, '重复订阅返回null（正常情况）');
    } else {
      hilog.warn(DOMAIN, TAG, '重复订阅返回holder，后一次订阅覆盖前一次');
    }
  }

  testEventProcessingError(): void {
    hilog.info(DOMAIN, TAG, '测试事件数据处理异常');
    
    hiAppEvent.addWatcher({
      name: 'processingErrorWatcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.SCROLL_JANK]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        try {
          for (const eventGroup of appEventGroups) {
            for (const eventInfo of eventGroup.appEventInfos) {
              this.processEventWithErrorHandling(eventInfo);
            }
          }
        } catch (error) {
          const err = error as BusinessError;
          hilog.error(DOMAIN, TAG, '事件处理异常: ' + err.message);
        }
      }
    });
  }

  private processEventWithErrorHandling(eventInfo: hiAppEvent.AppEventInfo): void {
    try {
      const params = eventInfo.params as Record<string, Object>;
      
      if (!params) {
        hilog.error(DOMAIN, TAG, '事件参数为空');
        return;
      }

      const duration = params.duration as number;
      if (duration === undefined || duration === null) {
        hilog.warn(DOMAIN, TAG, 'duration字段缺失或为空');
      } else {
        hilog.info(DOMAIN, TAG, '丢帧时长: ' + duration + 'ms');
      }

      const externalLog = params.external_log as string[];
      if (externalLog && externalLog.length > 0) {
        for (const logPath of externalLog) {
          if (logPath.startsWith('/data/storage/')) {
            hilog.info(DOMAIN, TAG, '日志文件路径: ' + logPath);
          } else {
            hilog.warn(DOMAIN, TAG, '日志文件路径异常: ' + logPath);
          }
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, '事件数据处理失败: ' + err.message);
      throw error;
    }
  }

  runAllTests(): void {
    hilog.info(DOMAIN, TAG, '开始运行所有错误处理测试');
    
    this.testInvalidWatcherName();
    this.testMissingParameters();
    this.testInvalidDomain();
    this.testCallbackError();
    this.testRemoveWatcherInCallback();
    this.testNullHolderHandling();
    this.testEventProcessingError();
    
    hilog.info(DOMAIN, TAG, '所有错误处理测试完成');
  }
}

export function demonstrateErrorHandling(): void {
  const errorHandling = new ScrollJankErrorHandling();
  errorHandling.runAllTests();
}