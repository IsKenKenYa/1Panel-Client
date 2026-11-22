import { FaultLogExtensionAbility, hilog, hiAppEvent } from '@kit.PerformanceAnalysisKit';

export default class MyFaultLogExtensionAbility extends FaultLogExtensionAbility {
  onConnect() {
    hilog.info(0x0000, 'testTag', 'FaultLogExtensionAbility onConnect');
  }

  onDisconnect() {
    hilog.info(0x0000, 'testTag', 'FaultLogExtensionAbility onDisconnect');
  }

  onFaultReportReady() {
    hilog.info(0x0000, 'testTag', 'FaultLogExtensionAbility onFaultReportReady');
    
    hiAppEvent.addWatcher({
      name: 'EntryAbilityWatcherExtension',
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_FREEZE, hiAppEvent.event.APP_CRASH]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
        for (const eventGroup of appEventGroups) {
          hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
          for (const eventInfo of eventGroup.appEventInfos) {
            if (eventInfo.name === hiAppEvent.event.APP_FREEZE) {
              this.processFreezeEvent(eventInfo);
            } else if (eventInfo.name === hiAppEvent.event.APP_CRASH) {
              this.processCrashEvent(eventInfo);
            }
          }
        }
      }
    });
  }

  private processFreezeEvent(eventInfo: hiAppEvent.AppEventInfo) {
    hilog.info(0x0000, 'testTag', `Process APP_FREEZE event`);
    hilog.info(0x0000, 'testTag', `Time: ${eventInfo.params['time']}`);
    hilog.info(0x0000, 'testTag', `Foreground: ${eventInfo.params['foreground']}`);
    hilog.info(0x0000, 'testTag', `Bundle: ${eventInfo.params['bundle_name']}`);
    hilog.info(0x0000, 'testTag', `Process: ${eventInfo.params['process_name']}`);
    hilog.info(0x0000, 'testTag', `PID: ${eventInfo.params['pid']}`);
    hilog.info(0x0000, 'testTag', `Exception: ${JSON.stringify(eventInfo.params['exception'])}`);
  }

  private processCrashEvent(eventInfo: hiAppEvent.AppEventInfo) {
    hilog.info(0x0000, 'testTag', `Process APP_CRASH event`);
    hilog.info(0x0000, 'testTag', `Time: ${eventInfo.params['time']}`);
    hilog.info(0x0000, 'testTag', `Bundle: ${eventInfo.params['bundle_name']}`);
    hilog.info(0x0000, 'testTag', `Process: ${eventInfo.params['process_name']}`);
    hilog.info(0x0000, 'testTag', `PID: ${eventInfo.params['pid']}`);
    hilog.info(0x0000, 'testTag', `Exception: ${JSON.stringify(eventInfo.params['exception'])}`);
  }
}