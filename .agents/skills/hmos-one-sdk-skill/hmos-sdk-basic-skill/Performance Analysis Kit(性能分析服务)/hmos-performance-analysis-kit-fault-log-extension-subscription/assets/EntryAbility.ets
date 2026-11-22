import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'testTag', 'EntryAbility onCreate');

    hiAppEvent.addWatcher({
      name: 'EntryAbilityWatcherNormal',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_FREEZE, hiAppEvent.event.APP_CRASH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        hilog.info(0x0000, 'testTag', `Normal watcher onReceive: domain=${domain}`);
        for (const eventGroup of appEventGroups) {
          hilog.info(0x0000, 'testTag', `eventName=${eventGroup.name}`);
          for (const eventInfo of eventGroup.appEventInfos) {
            hilog.info(0x0000, 'testTag', `eventInfo=${JSON.stringify(eventInfo)}`);
          }
        }
      }
    });

    hiAppEvent.addWatcher({
      name: 'EntryAbilityWatcherExtension',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_FREEZE, hiAppEvent.event.APP_CRASH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      }
    });
  }

  onDestroy() {
    hilog.info(0x0000, 'testTag', 'EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(0x0000, 'testTag', 'EntryAbility onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load content. Cause: ' + JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading content.');
    });
  }
}