import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'AudioJankEvent';
const DOMAIN = 0x0000;

let g_invalidCount = 0;

export class AudioJankEventWatcher {
  private watcherName: string = 'audioJankWatcher';
  private audioRenderer: audio.AudioRenderer | null = null;

  initWatcher(): void {
    try {
      hiAppEvent.addWatcher({
        name: this.watcherName,
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,
            names: [hiAppEvent.event.AUDIO_JANK_FRAME]
          }
        ],
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          hilog.info(DOMAIN, TAG, `onReceive: domain=${domain}`);
          for (const eventGroup of appEventGroups) {
            hilog.info(DOMAIN, TAG, `eventName=${eventGroup.name}`);
            for (const eventInfo of eventGroup.appEventInfos) {
              this.processEventInfo(eventInfo);
            }
          }
        }
      });
      hilog.info(DOMAIN, TAG, 'Audio jank event watcher initialized successfully');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to add watcher: code=${err.code}, message=${err.message}`);
    }
  }

  processEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    const params = eventInfo.params as Record<string, string | number>;
    hilog.info(DOMAIN, TAG, `Event domain: ${eventInfo.domain}`);
    hilog.info(DOMAIN, TAG, `Event name: ${eventInfo.name}`);
    hilog.info(DOMAIN, TAG, `Bundle name: ${params.bundle_name}`);
    hilog.info(DOMAIN, TAG, `Bundle version: ${params.bundle_version}`);
    hilog.info(DOMAIN, TAG, `Fault type: ${params.fault_type}`);
    hilog.info(DOMAIN, TAG, `Happen time: ${params.happen_time}`);
    hilog.info(DOMAIN, TAG, `Max frame time: ${params.max_frame_time}ms`);
    hilog.info(DOMAIN, TAG, `Event timestamp: ${params.time}`);
  }

  createAudioRenderer(audioRendererInfo: audio.AudioRendererInfo): void {
    const audioRendererOptions: audio.AudioRendererOptions = {
      rendererInfo: audioRendererInfo,
      rendererCallbacks: {
        writeDataCallback: this.writeDataCallback.bind(this)
      }
    };

    audio.createAudioRenderer(audioRendererOptions, (err: BusinessError, renderer: audio.AudioRenderer) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Failed to create AudioRenderer: ${err.message}`);
        return;
      }
      this.audioRenderer = renderer;
      hilog.info(DOMAIN, TAG, 'AudioRenderer created successfully');
      this.audioRenderer.on('writeData', this.writeDataCallback.bind(this));
    });
  }

  writeDataCallback(buffer: ArrayBuffer): audio.AudioDataCallbackResult {
    if (g_invalidCount > 0) {
      g_invalidCount--;
      hilog.warn(DOMAIN, TAG, `Returning INVALID, remaining count: ${g_invalidCount}`);
      return audio.AudioDataCallbackResult.INVALID;
    }
    return audio.AudioDataCallbackResult.VALID;
  }

  triggerJank(count: number): void {
    g_invalidCount = count;
    hilog.info(DOMAIN, TAG, `Jank triggered with count: ${count}`);
  }

  removeWatcher(): void {
    try {
      const watcher: hiAppEvent.Watcher = {
        name: this.watcherName
      };
      hiAppEvent.removeWatcher(watcher);
      hilog.info(DOMAIN, TAG, 'Audio jank event watcher removed successfully');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to remove watcher: code=${err.code}, message=${err.message}`);
    }
  }

  destroyAudioRenderer(): void {
    if (this.audioRenderer) {
      this.audioRenderer.off('writeData');
      this.audioRenderer.release();
      this.audioRenderer = null;
      hilog.info(DOMAIN, TAG, 'AudioRenderer destroyed');
    }
  }
}

export function initAudioJankWatcher(): AudioJankEventWatcher {
  const watcher = new AudioJankEventWatcher();
  watcher.initWatcher();
  return watcher;
}