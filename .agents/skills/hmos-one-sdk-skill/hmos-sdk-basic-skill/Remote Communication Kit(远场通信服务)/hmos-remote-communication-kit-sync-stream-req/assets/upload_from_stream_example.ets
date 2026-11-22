import { rcp } from '@kit.RemoteCommunicationKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

class FdReadStream implements rcp.ReadStream {
  readonly fd: number;
  constructor(fd: number) {
    this.fd = fd;
  }
  async read(buffer: ArrayBuffer): Promise<number> {
    return fileIo.read(this.fd, buffer);
  };
}

export function testUploadFromStream(uploadFilePath: string) {
  try {
    const session = rcp.createSession();
    const file = fileIo.openSync(uploadFilePath, fileIo.OpenMode.READ_ONLY);
    const fileStream = new rcp.UploadFromStream(new FdReadStream(file.fd));
    
    session.uploadFromStream('https://httpbin.org/anything', fileStream).then((resp) => {
      console.info(`testUploadFromStream response: ${JSON.stringify(resp)}`);
      if (resp && resp.statusCode === 200) {
        console.info(`testUploadFromStream succeeded.`);
      } else {
        console.error(`testUploadFromStream failed.`);
      }
      fileIo.closeSync(file.fd);
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`testUploadFromStream error code is ${err.code}, error data is ${err.data}`);
      fileIo.closeSync(file.fd);
      session.close();
    });
  } catch (err) {
    console.error(`testUploadFromStream error code is ${err.code}, error data is ${err.data}`);
  }
}

export function testUploadFromStreamWithUrl(uploadFilePath: string, uploadUrl: string) {
  try {
    const session = rcp.createSession();
    const file = fileIo.openSync(uploadFilePath, fileIo.OpenMode.READ_ONLY);
    const fileStream = new rcp.UploadFromStream(new FdReadStream(file.fd));
    
    session.uploadFromStream(uploadUrl, fileStream).then((resp) => {
      console.info(`testUploadFromStreamWithUrl response: ${JSON.stringify(resp)}`);
      if (resp && resp.statusCode === 200) {
        console.info(`testUploadFromStreamWithUrl succeeded.`);
      } else {
        console.error(`testUploadFromStreamWithUrl failed.`);
      }
      fileIo.closeSync(file.fd);
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`testUploadFromStreamWithUrl error code is ${err.code}, error data is ${err.data}`);
      fileIo.closeSync(file.fd);
      session.close();
    });
  } catch (err) {
    console.error(`testUploadFromStreamWithUrl error code is ${err.code}, error data is ${err.data}`);
  }
}