import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const HTTP_SERVER_POST: string = 'https://example.org/anything';

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

export { SendingPauseByTimeout, getSendPausedEvents, getSendResumedEvents };