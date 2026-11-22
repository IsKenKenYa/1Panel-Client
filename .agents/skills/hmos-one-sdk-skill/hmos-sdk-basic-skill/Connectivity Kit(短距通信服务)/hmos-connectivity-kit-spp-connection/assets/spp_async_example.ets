import { socket } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit';

class SppAsyncManager {
  clientNumber: number = -1;

  public async startConnectAsync(peerDevice: string): Promise<void> {
    let option: socket.SppOptions = {
      uuid: '00009999-0000-1000-8000-00805F9B34FB',
      secure: false,
      type: socket.SppType.SPP_RFCOMM
    };

    return new Promise<void>((resolve, reject) => {
      socket.sppConnect(peerDevice, option, (err, num: number) => {
        if (err) {
          console.error('sppConnect error: ' + (err as BusinessError).code);
          reject(err);
        } else {
          this.clientNumber = num;
          console.info('sppConnect success: ' + num);
          resolve();
        }
      });
    });
  }

  public async sendDataAsync(dataBuffer: ArrayBuffer): Promise<void> {
    if (this.clientNumber == -1) {
      throw new Error('invalid clientNumber');
    }

    try {
      await socket.sppWriteAsync(this.clientNumber, dataBuffer);
      console.info('sppWriteAsync success');
    } catch (err) {
      console.error('sppWriteAsync error: ' + (err as BusinessError).code);
      throw err;
    }
  }

  public async readDataAsync(): Promise<void> {
    if (this.clientNumber == -1) {
      throw new Error('invalid clientNumber');
    }

    let flag = true;
    try {
      while (flag) {
        let buffer = await socket.sppReadAsync(this.clientNumber);
        let data = new Uint8Array(buffer);
        if (data) {
          console.info('sppReadAsync success, length: ' + data.byteLength);
        }
      }
    } catch (err) {
      console.error('sppReadAsync error: ' + (err as BusinessError).code);
      socket.sppCloseClientSocket(this.clientNumber);
    }
  }

  public closeConnection(): void {
    if (this.clientNumber == -1) {
      console.error('invalid clientNumber');
      return;
    }

    try {
      socket.sppCloseClientSocket(this.clientNumber);
      console.info('connection closed');
    } catch (err) {
      console.error('close error: ' + (err as BusinessError).code);
    }
  }
}

async function asyncCommunicationExample() {
  let manager = new SppAsyncManager();
  let peerDevice = 'XX:XX:XX:XX:XX:XX';

  try {
    await manager.startConnectAsync(peerDevice);

    let arrayBuffer = new ArrayBuffer(2);
    let data = new Uint8Array(arrayBuffer);
    data[0] = 1;
    data[1] = 2;
    await manager.sendDataAsync(arrayBuffer);

    manager.readDataAsync();
  } catch (err) {
    console.error('async communication failed');
    manager.closeConnection();
  }
}

let sppAsyncManager = new SppAsyncManager();
export default sppAsyncManager as SppAsyncManager;