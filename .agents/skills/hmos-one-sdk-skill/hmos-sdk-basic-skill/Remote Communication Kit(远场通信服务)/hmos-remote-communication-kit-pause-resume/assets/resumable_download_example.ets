import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

let session: rcp.Session | null = rcp.createSession();
const kHttpServerAddress = 'http://www.example.com/fetch';
const request = new rcp.Request(kHttpServerAddress, 'GET');
let totalSize = 0;
let lastTransferPosition = 0;

async function getTotalSize(): Promise<number> {
  request.transferRange = { from: 0, to: 1 };
  try {
    let rep = await session?.fetch(request);
    if (rep) {
      let contentRange = rep.headers['content-range'];
      let sizeStr = contentRange ? contentRange.substring(contentRange.indexOf('/') + 1, contentRange.length) : '0';
      totalSize = Number(sizeStr);
    }
  } catch (err) {
    console.error(`getTotalSize error code is ${err.code}, error data is ${err.data}`);
  }
  console.info(`getTotalSize totalSize: ${totalSize.toString()}`);
  return totalSize;
}

function downloadTransfer(from: number, to: number) {
  request.transferRange = { from: from, to: to };
  session?.fetch(request).then((rep) => {
    if (rep.body) {
      console.info(`Response succeeded: ${JSON.stringify(rep.headers)}`);
      lastTransferPosition += rep.body.byteLength;
      if (lastTransferPosition < totalSize) {
        const nextTo = Math.min(lastTransferPosition + 100, totalSize);
        downloadTransfer(lastTransferPosition, nextTo);
      } else {
        console.info('Response succeeded, completed.');
      }
    }
  }).catch((err: BusinessError) => {
    console.error(`Continue transfer error: code is ${err.code}, message is ${err.message}`);
  });
}

async function startDownload() {
  if (!session) {
    session = rcp.createSession();
  }
  lastTransferPosition = 0;
  totalSize = await getTotalSize();
  const nextTo = Math.min(lastTransferPosition + 100, totalSize);
  downloadTransfer(lastTransferPosition, nextTo);
}

function pauseDownload() {
  session?.cancel(request);
}

function resumeDownload() {
  const nextTo = Math.min(lastTransferPosition + 100, totalSize);
  downloadTransfer(lastTransferPosition, nextTo);
}

function stopDownload() {
  session?.cancel(request);
  session?.close();
  session = null;
}

export { startDownload, pauseDownload, resumeDownload, stopDownload, getTotalSize };