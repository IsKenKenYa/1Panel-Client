import { UIAbility } from '@kit.AbilityKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: any, launchParam: any): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');

    // 添加事件观察者订阅应用冻屏告警事件
    this.setupAppFreezeWatcher();
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', err.message);
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

  // 设置应用冻屏告警事件观察者
  private setupAppFreezeWatcher(): void {
    try {
      hiAppEvent.addWatcher({
        // 开发者可以自定义观察者名称,系统会使用名称来标识不同的观察者
        name: "freezeWatcher",
        // 订阅感兴趣的系统事件,此处订阅应用冻屏告警事件
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_FREEZE]
          }
        ],
        // 实现订阅实时回调函数,对事件数据进行自定义处理
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.info(0x0000, 'freezeWatcher', `HiAppEvent onReceive: domain=${domain}`);
          
          for (const eventGroup of appEventGroups) {
            // 根据事件集合中的事件名称区分不同系统事件
            hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventName=${eventGroup.name}`);
            
            for (const eventInfo of eventGroup.appEventInfos) {
              // 处理冻屏告警事件数据
              this.handleFreezeEvent(eventInfo);
            }
          }
        }
      });
      
      hilog.info(0x0000, 'freezeWatcher', 'App freeze watcher setup successfully');
    } catch (error) {
      hilog.error(0x0000, 'freezeWatcher', `Failed to setup freeze watcher: code=${error.code}, message=${error.message}`);
    }
  }

  // 处理冻屏告警事件数据
  private handleFreezeEvent(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.name=${eventInfo.name}`);
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);

    // 获取冻屏告警事件发生的时间戳
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.time=${eventInfo.params['time']}`);
    
    // 获取冻屏告警事件发生时应用的前台/后台状态
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.foreground=${eventInfo.params['foreground']}`);
    
    // 获取冻屏告警事件发生时应用的唯一关联id
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.app_running_unique_id=${eventInfo.params['app_running_unique_id']}`);
    
    // 获取冻屏告警事件发生时应用的版本信息
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.bundle_version_code=${eventInfo.params['bundle_version_code']}`);
    
    // 获取冻屏告警事件发生时应用的包名
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.bundle_name=${eventInfo.params['bundle_name']}`);
    
    // 获取冻屏告警事件发生时应用的进程名称
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.process_name=${eventInfo.params['process_name']}`);
    
    // 获取冻屏告警事件发生时应用的进程id
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.pid=${eventInfo.params['pid']}`);
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.uid=${eventInfo.params['uid']}`);
    
    // 获取冻屏告警事件发生的异常类型、异常原因
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.exception=${JSON.stringify(eventInfo.params['exception'])}`);
    
    // 获取冻屏告警事件发生时日志信息
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.hilog.size=${eventInfo.params['hilog'].length}`);
    
    // 获取冻屏告警事件发生时主线程未处理消息
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.event_handler.size=${eventInfo.params['event_handler'].length}`);
    
    // 获取冻屏告警事件发生时同步binder调用信息
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.peer_binder.size=${eventInfo.params['peer_binder'].length}`);
    
    // 获取冻屏告警事件发生时全量线程调用栈
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.threads.size=${eventInfo.params['threads'].length}`);
    
    // 获取冻屏告警事件发生时内存信息
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.memory=${JSON.stringify(eventInfo.params['memory'])}`);
    
    // 获取冻屏告警事件的故障进程存活时间
    hilog.info(0x0000, 'freezeWatcher', `HiAppEvent eventInfo.params.process_life_time=${eventInfo.params['process_life_time']}`);
  }
}