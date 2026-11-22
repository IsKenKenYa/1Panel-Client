import { socket } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit';

class SppClientManager {
  clientNumber: number = -1;

  public startConnect(peerDevice: string): void {
    let option: socket.SppOptions = {
      uuid: '00009999-0000-1000-8000-00805F9B34FB',
      secure: false,
      type: socket.SppType.SPP_RFCOMM
    };
    console.info('startConnect ' + peerDevice);
    socket.sppConnect(peerDevice, option, (err, num: number) => {
      if (err) {
        console.error('startConnect errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      } else {
        console.info('startConnect clientNumber: ' + num);
        this.clientNumber = num;
      }
    });
    console.info('startConnect after ' + peerDevice);
  }

  public sendData() {
    console.info('sendData ' + this.clientNumber);
    if (this.clientNumber == -1) {
      console.error('invalid clientNumber');
      return;
    }
    let arrayBuffer = new ArrayBuffer(2);
    let data = new Uint8Array(arrayBuffer);
    data[0] = 3;
    data[1] = 4;
    try {
      socket.sppWrite(this.clientNumber, arrayBuffer);
    } catch (err) {
      console.error('sppWrite errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  read = (dataBuffer: ArrayBuffer) => {
    let data = new Uint8Array(dataBuffer);
    console.info('client data: ' + JSON.stringify(data));
  };

  public readData() {
    try {
      if (this.clientNumber == -1) {
        console.error('invalid clientNumber');
        return;
      }
      socket.on('sppRead', this.clientNumber, this.read);
    } catch (err) {
      console.error('readData errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public stopConnect() {
    console.info('closeSppClient ' + this.clientNumber);
    if (this.clientNumber == -1) {
      console.error('invalid clientNumber');
      return;
    }
    try {
      socket.off('sppRead', this.clientNumber, this.read);
    } catch (err) {
      console.error('off sppRead errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    try {
      socket.sppCloseClientSocket(this.clientNumber);
    } catch (err) {
      console.error('stopConnect errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}

let sppClientManager = new SppClientManager();
export default sppClientManager as SppClientManager;