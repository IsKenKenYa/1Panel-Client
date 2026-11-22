import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

const HTTP_SERVER_POST: string = 'https://example.org/anything';
const HTTP_SERVER_DOWNLOAD: string = 'http://www.example.com/fetch';

interface StringifiedDebugInfo {
  type: rcp.DebugEvent;
  data: string;
}

type DebugInfoSource = undefined | rcp.DebugInfo[] | rcp.Response;

function debugInfoStringify(infoSource: DebugInfoSource): StringifiedDebugInfo[] {
  const debugInfo = Array.isArray(infoSource)
    ? (infoSource as rcp.DebugInfo[])
    : (infoSource as rcp.Response).debugInfo;
  if (!debugInfo) {
    return [];
  }
  const decoder = util.TextDecoder.create('utf-8');
  return debugInfo.map((i: rcp.DebugInfo): StringifiedDebugInfo => {
    return {
      type: i.type,
      data: decoder.decodeToString(new Uint8Array(i.data)).trim(),
    };
  });
}

function getSendPausedEvents(debugInfo: DebugInfoSource): StringifiedDebugInfo[] {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Pause sending'));
}

function getSendResumedEvents(debugInfo: DebugInfoSource): StringifiedDebugInfo[] {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Resume sending'));
}

class ResumableDownloader {
  private session: rcp.Session | null = null;
  private request: rcp.Request;
  private totalSize: number = 0;
  private lastTransferPosition: number = 0;
  private isPaused: boolean = false;
  
  constructor(url: string) {
    this.request = new rcp.Request(url, 'GET');
  }
  
  async getTotalSize(): Promise<number> {
    this.request.transferRange = { from: 0, to: 1 };
    try {
      let rep = await this.session?.fetch(this.request);
      if (rep) {
        let contentRange = rep.headers['content-range'];
        let sizeStr = contentRange ? contentRange.substring(contentRange.indexOf('/') + 1, contentRange.length) : '0';
        this.totalSize = Number(sizeStr);
      }
    } catch (err) {
      console.error(`getTotalSize error code is ${err.code}, error data is ${err.data}`);
    }
    return this.totalSize;
  }
  
  downloadTransfer(from: number, to: number) {
    if (this.isPaused) {
      console.info('Download is paused, skipping this transfer');
      return;
    }
    
    this.request.transferRange = { from: from, to: to };
    this.session?.fetch(this.request).then((rep) => {
      if (rep.body) {
        console.info(`Response succeeded: ${JSON.stringify(rep.headers)}`);
        this.lastTransferPosition += rep.body.byteLength;
        
        if (this.lastTransferPosition < this.totalSize) {
          const nextTo = Math.min(this.lastTransferPosition + 100, this.totalSize);
          this.downloadTransfer(this.lastTransferPosition, nextTo);
        } else {
          console.info('Download completed successfully');
        }
      }
    }).catch((err: BusinessError) => {
      console.error(`Continue transfer error: code is ${err.code}, message is ${err.message}`);
    });
  }
  
  async start() {
    if (!this.session) {
      this.session = rcp.createSession();
    }
    this.lastTransferPosition = 0;
    this.isPaused = false;
    this.totalSize = await this.getTotalSize();
    const nextTo = Math.min(this.lastTransferPosition + 100, this.totalSize);
    this.downloadTransfer(this.lastTransferPosition, nextTo);
  }
  
  pause() {
    this.isPaused = true;
    this.session?.cancel(this.request);
    console.info(`Download paused at position: ${this.lastTransferPosition}`);
  }
  
  resume() {
    this.isPaused = false;
    const nextTo = Math.min(this.lastTransferPosition + 100, this.totalSize);
    this.downloadTransfer(this.lastTransferPosition, nextTo);
    console.info('Download resumed');
  }
  
  stop() {
    this.isPaused = true;
    this.session?.cancel(this.request);
    this.session?.close();
    this.session = null;
    console.info('Download stopped and session closed');
  }
  
  getStatus() {
    return {
      totalSize: this.totalSize,
      transferred: this.lastTransferPosition,
      isPaused: this.isPaused,
      progress: (this.lastTransferPosition / this.totalSize) * 100
    };
  }
}

const SendingPauseByTimeout = async (done: Function): Promise<void> => {
  const session = rcp.createSession();
  const request = new rcp.Request(HTTP_SERVER_POST);
  
  const sendPolicy: rcp.SendingPausePolicy = {
    kind: 'timeout',
    timeoutMs: 1,
  };
  
  const pausePolicy: rcp.PausePolicy = {
    sending: sendPolicy,
  };
  
  request.configuration = {
    transfer: {
      pausePolicy: pausePolicy,
    },
    tracing: {
      infoToCollect: {
        textual: true,
      },
    },
  };
  
  const data = 'TestData';
  request.headers = {
    'Content-Length': data.length.toString(),
  };
  
  let isReadCompleted = false;
  request.method = 'POST';
  
  request.content = (maxSize) => {
    if (isReadCompleted) {
      return new ArrayBuffer(0);
    }
    isReadCompleted = true;
    const buffer = new ArrayBuffer(data.length);
    util.TextEncoder.create('utf-8').encodeIntoUint8Array(data, new Uint8Array(buffer));
    return buffer;
  };
  
  try {
    const response = await session.fetch(request);
    
    const pausedEvents = getSendPausedEvents(response);
    const resumedEvents = getSendResumedEvents(response);
    
    console.info(`Paused events count: ${pausedEvents.length}`);
    console.info(`Resumed events count: ${resumedEvents.length}`);
    
    session.close();
    done();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Error: code is ${err.code}, message is ${err.message}`);
    session.close();
  }
}

async function completeExample() {
  const downloader = new ResumableDownloader(HTTP_SERVER_DOWNLOAD);
  
  await downloader.start();
  
  setTimeout(() => {
    downloader.pause();
    console.info('Download paused after 2 seconds');
    
    setTimeout(() => {
      downloader.resume();
      console.info('Download resumed after 1 second');
      
      setTimeout(() => {
        const status = downloader.getStatus();
        console.info(`Download status: ${JSON.stringify(status)}`);
        downloader.stop();
      }, 3000);
    }, 1000);
  }, 2000);
}

export { 
  SendingPauseByTimeout, 
  ResumableDownloader, 
  completeExample,
  getSendPausedEvents,
  getSendResumedEvents 
};