import { rcp } from '@kit.RemoteCommunicationKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

class FdWriteStream implements rcp.WriteStream {
  readonly fd: number;
  
  constructor(fd: number) {
    this.fd = fd;
  }
  
  async write(buffer: ArrayBuffer): Promise<number | void> {
    return fileIo.write(this.fd, buffer);
  }
}

export function testDownloadToStream(downloadToPath: string) {
  try {
    const session = rcp.createSession();
    
    const file = fileIo.openSync(downloadToPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    
    const fileStream = { kind: 'stream', stream: new FdWriteStream(file.fd) } as rcp.DownloadToStream
    
    session.downloadToStream('https://httpbin.org/bytes/10000', fileStream)
      .then((resp) => {
        console.info(`testDownloadToStream response: ${JSON.stringify(resp)}`);
        if (resp && resp.statusCode === 200) {
          console.info(`testDownloadToStream succeeded.`);
        } else {
          console.error(`testDownloadToStream failed.`);
        }
        
        fileIo.close(file.fd);
        session.close();
      })
      .catch((err: BusinessError) => {
        console.error(`testDownloadToStream error code is ${err.code}, error data is ${err.data}`);
        fileIo.close(file.fd);
        session.close();
      })
  } catch (err) {
    console.error(`testDownloadToStream error code is ${err.code}, error data is ${err.data}`);
  }
}