import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class SppClientManager {
  clientNumber: number = -1;
  isConnected: boolean = false;
  
  constructor() {
    console.info('[SPP Client] 初始化客户端管理器');
  }
  
  public startConnect(peerDevice: string, uuid: string): void {
    if (this.clientNumber !== -1) {
      console.warn('[SPP Client] 已存在连接,请先断开');
      return;
    }
    
    if (!peerDevice || peerDevice.length === 0) {
      console.error('[SPP Client] 设备地址为空');
      return;
    }
    
    let option: socket.SppOptions = {
      uuid: uuid,
      secure: false,
      type: socket.SppType.SPP_RFCOMM
    };
    
    console.info('[SPP Client] 开始连接: device=' + peerDevice + ', uuid=' + uuid);
    
    socket.sppConnect(peerDevice, option, (err: BusinessError, num: number) => {
      if (err) {
        console.error('[SPP Client] 连接失败: code=' + err.code + ', message=' + err.message);
        this.handleConnectionError(err);
        return;
      } else {
        this.clientNumber = num;
        this.isConnected = true;
        console.info('[SPP Client] 连接成功: clientNumber=' + this.clientNumber);
      }
    });
  }
  
  public sendData(data: Uint8Array): boolean {
    if (this.clientNumber === -1) {
      console.error('[SPP Client] socket ID无效');
      return false;
    }
    
    if (!this.isConnected) {
      console.error('[SPP Client] 连接未建立');
      return false;
    }
    
    let arrayBuffer = new ArrayBuffer(data.length);
    let dataView = new Uint8Array(arrayBuffer);
    dataView.set(data);
    
    console.info('[SPP Client] 发送数据: length=' + data.length);
    
    try {
      socket.sppWrite(this.clientNumber, arrayBuffer);
      console.info('[SPP Client] 数据发送成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Client] 发送失败: code=' + error.code + ', message=' + error.message);
      this.handleWriteError(error);
      return false;
    }
  }
  
  public subscribeReceive(): void {
    if (this.clientNumber === -1) {
      console.error('[SPP Client] socket ID无效');
      return;
    }
    
    console.info('[SPP Client] 订阅数据接收');
    
    let readCallback = (dataBuffer: ArrayBuffer) => {
      let data = new Uint8Array(dataBuffer);
      console.info('[SPP Client] 接收数据: length=' + data.byteLength + ', data=' + JSON.stringify(data));
      this.handleReceivedData(data);
    };
    
    try {
      socket.on('sppRead', this.clientNumber, readCallback);
      console.info('[SPP Client] 数据订阅成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Client] 订阅失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  public unsubscribeReceive(): void {
    if (this.clientNumber === -1) {
      console.error('[SPP Client] socket ID无效');
      return;
    }
    
    console.info('[SPP Client] 取消数据订阅');
    
    try {
      socket.off('sppRead', this.clientNumber);
      console.info('[SPP Client] 取消订阅成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Client] 取消订阅失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  public disconnect(): void {
    if (this.clientNumber === -1) {
      console.warn('[SPP Client] socket未创建,无需断开');
      return;
    }
    
    console.info('[SPP Client] 开始断开连接');
    
    this.unsubscribeReceive();
    
    try {
      socket.sppCloseClientSocket(this.clientNumber);
      console.info('[SPP Client] 连接已断开');
      this.clientNumber = -1;
      this.isConnected = false;
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Client] 断开连接失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  private handleReceivedData(data: Uint8Array): void {
    console.info('[SPP Client] 处理接收数据');
  }
  
  private handleConnectionError(err: BusinessError): void {
    switch (err.code) {
      case 201:
        console.error('[SPP Client] 权限不足');
        break;
      case 2900003:
        console.error('[SPP Client] 蓝牙未开启');
        break;
      case 2900004:
        console.error('[SPP Client] Profile不支持');
        break;
      case 2900099:
        console.error('[SPP Client] 操作失败');
        break;
      default:
        console.error('[SPP Client] 未知错误');
    }
  }
  
  private handleWriteError(err: BusinessError): void {
    switch (err.code) {
      case 2901054:
        console.error('[SPP Client] IO错误');
        this.reconnect();
        break;
      case 2900099:
        console.error('[SPP Client] 操作失败');
        break;
      default:
        console.error('[SPP Client] 未知错误');
    }
  }
  
  private reconnect(): void {
    console.warn('[SPP Client] 执行降级方案:尝试重新连接');
    this.disconnect();
  }
}

let sppClientManager = new SppClientManager();
export default sppClientManager as SppClientManager;