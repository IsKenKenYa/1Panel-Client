// 完整示例：订阅ArkWeb抛滑丢帧事件
// 文件路径：entry/src/main/ets/entryability/EntryAbility.ets

import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { webIdToUrlMap } from '../pages/ArkWebPage';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', 'Ability onCreate');
    
    // 添加ArkWeb抛滑丢帧事件观察者
    this.setupWebFlingJankWatcher();
  }

  private setupWebFlingJankWatcher(): void {
    hiAppEvent.addWatcher({
      // 开发者可以自定义观察者名称，系统会使用名称来标识不同的观察者
      name: 'webJankWatcher',
      // 开发者可以订阅感兴趣的系统事件，此处是订阅了ArkWeb抛滑丢帧事件
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK]
        }
      ],
      // 开发者可以自行实现订阅实时回调函数，以便对订阅获取到的事件数据进行自定义处理
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
        
        for (const eventGroup of appEventGroups) {
          // 开发者可以根据事件集合中的事件名称区分不同的系统事件
          hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
          
          for (const eventInfo of eventGroup.appEventInfos) {
            try {
              // 开发者可以对事件集合中的事件数据进行自定义处理，此处是将事件数据打印在日志中
              hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
              hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
              
              // 开发者可以获取到开始抛滑事件的时间戳
              hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.start_time=${eventInfo.params['start_time']}`);
              
              // 开发者可以获取到抛滑动效持续的时间长度
              hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.duration=${eventInfo.params['duration']}`);
              
              // 开发者可以获取到发生卡顿的的web页面对应的Id
              hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.web_id=${eventInfo.params['web_id']}`);
              
              // 开发者可以获取抛滑阶段发生丢帧的最大时长
              hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.max_app_frame_time=${eventInfo.params['max_app_frame_time']}`);
              
              const webId: number = eventInfo.params['web_id'];
              // webIdToUrlMap是一个定义的变量，用于实现webId到url的映射，通过系统侧获取的web_id查询到发生丢帧的网页
              const currentUrl = webIdToUrlMap.get(webId);
              
              // 开发者可以获取到发生卡顿的页面
              hilog.info(0x0000, 'testTag', `HiAppEvent get currentUrl=${currentUrl}`);
              
              // 可以在这里添加自定义的事件处理逻辑
              this.handleJankEvent(eventInfo, currentUrl);
            } catch (error) {
              hilog.error(0x0000, 'testTag', `Error processing jank event: ${JSON.stringify(error)}`);
            }
          }
        }
      }
    });
  }

  // 自定义事件处理方法示例
  private handleJankEvent(eventInfo: any, url: string | undefined): void {
    const duration = eventInfo.params['duration'];
    const maxFrameTime = eventInfo.params['max_app_frame_time'];
    
    // 可以根据丢帧严重程度进行不同的处理
    if (maxFrameTime > 100) {
      hilog.warn(0x0000, 'testTag', `Severe jank detected on page: ${url}, max frame time: ${maxFrameTime}ms`);
      // 可以在这里添加上报逻辑、告警逻辑等
    } else {
      hilog.info(0x0000, 'testTag', `Minor jank detected on page: ${url}, max frame time: ${maxFrameTime}ms`);
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'testTag', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'testTag', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'testTag', 'Ability onBackground');
  }
}