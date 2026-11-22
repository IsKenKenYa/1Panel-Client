import { socket } from '@kit.ConnectivityKit'
import { BusinessError } from '@kit.BasicServicesKit';

class SppServerManager {
  serverNumber: number = -1;
  clientNumber: number = -1;

  public startListen(): void {
    console.info('startListen');
    let option: socket.SppOptions = {
      uuid: '00009999-0000-1000-8000-00805F9B34FB',
      secure: false,
      type: socket.SppType.SPP_RFCOMM
    };
    socket.sppListen("demonstration", option, (err, num: number) => {
      if (err) {
        console.error('sppListen errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      } else {
        console.info('sppListen serverNumber: ' + num);
        this.serverNumber = num;
      }
    });
  }

  public accept() {
    console.info('accept ' + this.serverNumber);
    if (this.serverNumber == -1) {
      console.error('invalid serverNumber');
      return;
    }
    socket.sppAccept(this.serverNumber, (err, num: number) => {
      if (err) {
        console.error('accept errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      } else {
        console.info('accept clientNumber: ' + num);
        this.clientNumber = num;
      }
    });
  }

  public sendData() {
    console.info('sendData serverNumber: ' + this.serverNumber + ' clientNumber: ' + this.clientNumber);
    if (this.clientNumber == -1) {
      console.error('invalid clientNumber');
      return;
    }
    let arrayBuffer = new ArrayBuffer(2);
    let data = new Uint8Array(arrayBuffer);
    data[0] = 9;
    data[1] = 8;
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
    console.info('stopConnect');
    try {
      if (this.clientNumber == -1) {
        console.error('invalid clientNumber');
        return;
      }
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

  public closeSppServer() {
    console.info('closeSppServer');
    try {
      if (this.serverNumber == -1) {
        console.error('invalid serverNumber');
        return;
      }
      socket.sppCloseServerSocket(this.serverNumber);
    } catch (err) {
      console.error('sppCloseServerSocket errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }
}

let sppServerManager = new SppServerManager();
export default sppServerManager as SppServerManager;