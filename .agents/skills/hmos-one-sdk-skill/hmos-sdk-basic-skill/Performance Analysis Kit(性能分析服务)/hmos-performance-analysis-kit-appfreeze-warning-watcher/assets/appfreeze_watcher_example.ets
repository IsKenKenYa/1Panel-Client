import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

export class FreezeWatcherManager {
  private watcherName: string = 'freezeWatcher';
  private isWatching: boolean = false;

  addFreezeWatcher(): void {
    try {
      const holder = hiAppEvent.addWatcher({
        name: this.watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.APP_FREEZE]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.info(0x0000, 'freezeTag', `onReceive triggered, domain=${domain}`);
          this.handleFreezeEvent(domain, appEventGroups);
        }
      });

      if (holder === null) {
        hilog.error(0x0000, 'freezeTag', 'Failed to add freeze watcher');
        this.isWatching = false;
      } else {
        hilog.info(0x0000, 'freezeTag', 'Freeze watcher added successfully');
        this.isWatching = true;
      }
    } catch (error) {
      hilog.error(0x0000, 'freezeTag', `Error adding watcher: ${error.code}, ${error.message}`);
      this.isWatching = false;
    }
  }

  removeFreezeWatcher(): void {
    if (!this.isWatching) {
      hilog.warn(0x0000, 'freezeTag', 'Watcher not active, no need to remove');
      return;
    }

    try {
      const watcher: hiAppEvent.Watcher = {
        name: this.watcherName
      };
      hiAppEvent.removeWatcher(watcher);
      hilog.info(0x0000, 'freezeTag', 'Freeze watcher removed successfully');
      this.isWatching = false;
    } catch (error) {
      hilog.error(0x0000, 'freezeTag', `Error removing watcher: ${error.code}, ${error.message}`);
    }
  }

  private handleFreezeEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'freezeTag', `Event group name: ${eventGroup.name}`);

      for (const eventInfo of eventGroup.appEventInfos) {
        this.logFreezeEventInfo(eventInfo);
      }
    }
  }

  private logFreezeEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(0x0000, 'freezeTag', `Event domain: ${eventInfo.domain}`);
    hilog.info(0x0000, 'freezeTag', `Event name: ${eventInfo.name}`);
    hilog.info(0x0000, 'freezeTag', `Event type: ${eventInfo.eventType}`);

    const params = eventInfo.params;

    if (params['time'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Freeze time: ${params['time']}`);
    }

    if (params['foreground'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Foreground state: ${params['foreground']}`);
    }

    if (params['app_running_unique_id'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `App unique ID: ${params['app_running_unique_id']}`);
    }

    if (params['bundle_version'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Bundle version: ${params['bundle_version']}`);
    }

    if (params['bundle_version_code'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Bundle version code: ${params['bundle_version_code']}`);
    }

    if (params['bundle_name'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Bundle name: ${params['bundle_name']}`);
    }

    if (params['process_name'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Process name: ${params['process_name']}`);
    }

    if (params['pid'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Process ID: ${params['pid']}`);
    }

    if (params['uid'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `User ID: ${params['uid']}`);
    }

    if (params['exception'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Exception: ${JSON.stringify(params['exception'])}`);
    }

    if (params['hilog'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Hilog size: ${params['hilog'].length}`);
    }

    if (params['event_handler'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Event handler size: ${params['event_handler'].length}`);
    }

    if (params['peer_binder'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Peer binder size: ${params['peer_binder'].length}`);
    }

    if (params['threads'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Threads size: ${params['threads'].length}`);
    }

    if (params['memory'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Memory: ${JSON.stringify(params['memory'])}`);
    }

    if (params['process_life_time'] !== undefined) {
      hilog.info(0x0000, 'freezeTag', `Process life time: ${params['process_life_time']}`);
    }
  }

  getWatchingStatus(): boolean {
    return this.isWatching;
  }
}