import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

export function subscribeAppHiCollieEvent(): void {
  const watcher: hiAppEvent.Watcher = {
    name: "hicollieWatcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_HICOLLIE]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      hilog.info(0x0000, 'HiCollieWatcher', `Received event: domain=${domain}`);
      
      for (const eventGroup of appEventGroups) {
        hilog.info(0x0000, 'HiCollieWatcher', `Event name: ${eventGroup.name}`);
        
        for (const eventInfo of eventGroup.appEventInfos) {
          const params = eventInfo.params;
          
          hilog.info(0x0000, 'HiCollieWatcher', `Event Info:`);
          hilog.info(0x0000, 'HiCollieWatcher', `  domain: ${eventInfo.domain}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  name: ${eventInfo.name}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  eventType: ${eventInfo.eventType}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  time: ${params['time']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  foreground: ${params['foreground']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  bundle_version: ${params['bundle_version']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  process_name: ${params['process_name']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  pid: ${params['pid']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  uid: ${params['uid']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  uuid: ${params['uuid']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  exception: ${params['exception']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  memory: ${JSON.stringify(params['memory'])}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  external_log: ${JSON.stringify(params['external_log'])}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  log_over_limit: ${params['log_over_limit']}`);
          hilog.info(0x0000, 'HiCollieWatcher', `  external_callback_log: ${params['external_callback_log']}`);
          
          if (params['hilog'] && Array.isArray(params['hilog'])) {
            hilog.info(0x0000, 'HiCollieWatcher', `  hilog count: ${params['hilog'].length}`);
          }
          
          if (params['peer_binder'] && Array.isArray(params['peer_binder'])) {
            hilog.info(0x0000, 'HiCollieWatcher', `  peer_binder count: ${params['peer_binder'].length}`);
          }
        }
      }
    }
  };
  
  const holder = hiAppEvent.addWatcher(watcher);
  if (holder === null) {
    hilog.error(0x0000, 'HiCollieWatcher', 'Failed to add watcher');
    return;
  }
  
  hilog.info(0x0000, 'HiCollieWatcher', 'Successfully subscribed to APP_HICOLLIE events');
}

export function unsubscribeAppHiCollieEvent(watcher: hiAppEvent.Watcher): void {
  hiAppEvent.removeWatcher(watcher);
  hilog.info(0x0000, 'HiCollieWatcher', 'Successfully unsubscribed from APP_HICOLLIE events');
}