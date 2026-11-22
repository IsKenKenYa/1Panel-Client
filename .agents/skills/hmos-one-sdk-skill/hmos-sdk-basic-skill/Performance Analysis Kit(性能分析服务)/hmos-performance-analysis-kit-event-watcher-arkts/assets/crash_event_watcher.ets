import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchType: AbilityConstant.LaunchType): void {
    hilog.info(0x0000, 'testTag', 'Ability onCreate');

    hiAppEvent.addWatcher({
      name: 'AppCrashWatcher',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_CRASH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        hilog.info(0x0000, 'testTag', 'HiAppEvent success to read event with onReceive callback');
        hilog.info(0x0000, 'testTag', `domain=${domain}`);
        
        for (const eventGroup of appEventGroups) {
          hilog.info(0x0000, 'testTag', `eventName=${eventGroup.name}`);
          
          for (const eventInfo of eventGroup.appEventInfos) {
            hilog.info(0x0000, 'testTag', `time=${JSON.stringify(eventInfo.params['time'])}`);
            hilog.info(0x0000, 'testTag', `bundle_name=${JSON.stringify(eventInfo.params['bundle_name'])}`);
            hilog.info(0x0000, 'testTag', `external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
          }
        }
      }
    });

    hilog.info(0x0000, 'testTag', 'Crash watcher added successfully');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', 'Ability onDestroy');
    
    let watcher: hiAppEvent.Watcher = {
      name: 'AppCrashWatcher'
    };
    hiAppEvent.removeWatcher(watcher);
    hilog.info(0x0000, 'testTag', 'Crash watcher removed successfully');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load content. Cause: %{public}s', err.message);
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading content');
    });
  }
}