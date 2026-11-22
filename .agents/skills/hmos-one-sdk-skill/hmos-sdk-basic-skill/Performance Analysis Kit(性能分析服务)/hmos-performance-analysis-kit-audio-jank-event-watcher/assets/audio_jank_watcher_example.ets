import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { audio } from '@kit.AudioKit';

const TAG = 'AudioJankWatcher';
const DOMAIN = 0x0000;

let g_invalidCount = 0;
let audioRenderer: audio.AudioRenderer | undefined = undefined;

export class AudioJankEventWatcher {
  private watcherName: string = "audioJankWatcher";
  private isWatching: boolean = false;

  startWatching() {
    if (this.isWatching) {
      hilog.warn(DOMAIN, TAG, 'Watcher already started');
      return;
    }

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
          this.handleEvent(domain, appEventGroups);
        }
      });
      
      this.isWatching = true;
      hilog.info(DOMAIN, TAG, `Watcher started successfully: ${this.watcherName}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to start watcher: ${JSON.stringify(error)}`);
    }
  }

  stopWatching() {
    if (!this.isWatching) {
      hilog.warn(DOMAIN, TAG, 'Watcher not started');
      return;
    }

    try {
      hiAppEvent.removeWatcher({
        name: this.watcherName
      });
      
      this.isWatching = false;
      hilog.info(DOMAIN, TAG, `Watcher stopped successfully: ${this.watcherName}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to stop watcher: ${JSON.stringify(error)}`);
    }
  }

  private handleEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) {
    hilog.info(DOMAIN, TAG, `Received event, domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(DOMAIN, TAG, `Event name: ${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(DOMAIN, TAG, `Event info: ${JSON.stringify(eventInfo)}`);
        
        if (eventInfo.name === hiAppEvent.event.AUDIO_JANK_FRAME) {
          const params = eventInfo.params as Record<string, Object>;
          this.processAudioJankEvent(params);
        }
      }
    }
  }

  private processAudioJankEvent(params: Record<string, Object>) {
    const bundleName = params['bundle_name'] as string;
    const bundleVersion = params['bundle_version'] as string;
    const maxFrameTime = params['max_frame_time'] as number;
    const happenTime = params['happen_time'] as number;
    
    hilog.info(DOMAIN, TAG, `Audio jank detected:`);
    hilog.info(DOMAIN, TAG, `  Bundle: ${bundleName} v${bundleVersion}`);
    hilog.info(DOMAIN, TAG, `  Max frame time: ${maxFrameTime}ms`);
    hilog.info(DOMAIN, TAG, `  Happen time: ${happenTime}`);
  }
}

function normalCallback(buffer: ArrayBuffer): audio.AudioDataCallbackResult {
  if (g_invalidCount > 0) {
    g_invalidCount--;
    return audio.AudioDataCallbackResult.INVALID;
  }
  return audio.AudioDataCallbackResult.VALID;
}

export async function setupAudioRenderer(options: audio.AudioRendererOptions) {
  try {
    audioRenderer = await audio.createAudioRenderer(options);
    
    if (audioRenderer) {
      audioRenderer.on('writeData', normalCallback);
      hilog.info(DOMAIN, TAG, 'AudioRenderer created successfully');
    }
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Failed to create AudioRenderer: ${JSON.stringify(error)}`);
  }
}

export function triggerJank(count: number) {
  g_invalidCount = count;
  hilog.info(DOMAIN, TAG, `Triggering jank with ${count} invalid returns`);
}

export function cleanup() {
  if (audioRenderer) {
    audioRenderer.off('writeData');
    audioRenderer = undefined;
  }
}

export const audioJankWatcher = new AudioJankEventWatcher();

export const audioRendererOptions: audio.AudioRendererOptions = {
  audioStreamInfo: {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_2,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  },
  audioRendererInfo: {
    usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
    rendererFlags: 0
  }
};