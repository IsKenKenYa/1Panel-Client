import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class SppServerManager {
  serverNumber: number = -1;
  clientNumber: number = -1;
  isListening: boolean = false;
  
  constructor() {
    console.info('[SPP Server] 初始化服务端管理器');
  }
  
  public startListen(serviceName: string, uuid: string): void {
    if (this.serverNumber !== -1) {
      console.warn('[SPP Server] 已存在监听socket,请先删除');
      return;
    }
    
    let option: socket.SppOptions = {
      uuid: uuid,
      secure: false,
      type: socket.SppType.SPP_RFCOMM
    };
    
    console.info('[SPP Server] 创建监听socket: name=' + serviceName + ', uuid=' + uuid);
    
    socket.sppListen(serviceName, option, (err: BusinessError, num: number) => {
      if (err) {
        console.error('[SPP Server] 创建失败: code=' + err.code + ', message=' + err.message);
        this.handleServerError(err);
        return;
      } else {
        this.serverNumber = num;
        this.isListening = true;
        console.info('[SPP Server] 创建成功: serverNumber=' + this.serverNumber);
        this.acceptConnection();
      }
    });
  }
  
  private acceptConnection(): void {
    if (this.serverNumber === -1) {
      console.error('[SPP Server] 服务端socket未创建');
      return;
    }
    
    console.info('[SPP Server] 开始监听客户端连接');
    
    socket.sppAccept(this.serverNumber, (err: BusinessError, clientSocketId: number) => {
      if (err) {
        console.error('[SPP Server] 监听失败: code=' + err.code + ', message=' + err.message);
        return;
      } else {
        this.clientNumber = clientSocketId;
        console.info('[SPP Server] 客户端连接成功: clientNumber=' + this.clientNumber);
        this.onConnectionEstablished();
      }
    });
  }
  
  private onConnectionEstablished(): void {
    console.info('[SPP Server] 连接建立完成,开始数据传输');
    this.subscribeReceive();
  }
  
  public sendData(data: Uint8Array): boolean {
    if (this.clientNumber === -1) {
      console.error('[SPP Server] 客户端socket未连接');
      return false;
    }
    
    let arrayBuffer = new ArrayBuffer(data.length);
    let dataView = new Uint8Array(arrayBuffer);
    dataView.set(data);
    
    console.info('[SPP Server] 发送数据: length=' + data.length);
    
    try {
      socket.sppWrite(this.clientNumber, arrayBuffer);
      console.info('[SPP Server] 数据发送成功');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Server] 发送失败: code=' + error.code + ', message=' + error.message);
      this.handleWriteError(error);
      return false;
    }
  }
  
  private subscribeReceive(): void {
    if (this.clientNumber === -1) {
      console.error('[SPP Server] 客户端socket未连接');
      return;
    }
    
    console.info('[SPP Server] 订阅数据接收');
    
    let readCallback = (dataBuffer: ArrayBuffer) => {
      let data = new Uint8Array(dataBuffer);
      console.info('[SPP Server] 接收数据: length=' + data.byteLength + ', data=' + JSON.stringify(data));
      this.handleReceivedData(data);
    };
    
    try {
      socket.on('sppRead', this.clientNumber, readCallback);
      console.info('[SPP Server] 数据订阅成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Server] 订阅失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  private unsubscribeReceive(): void {
    if (this.clientNumber === -1) {
      console.error('[SPP Server] 客户端socket未连接');
      return;
    }
    
    console.info('[SPP Server] 取消数据订阅');
    
    try {
      socket.off('sppRead', this.clientNumber);
      console.info('[SPP Server] 取消订阅成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Server] 取消订阅失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  public disconnectClient(): void {
    if (this.clientNumber === -1) {
      console.warn('[SPP Server] 客户端未连接');
      return;
    }
    
    console.info('[SPP Server] 断开客户端连接');
    
    this.unsubscribeReceive();
    
    try {
      socket.sppCloseClientSocket(this.clientNumber);
      console.info('[SPP Server] 客户端连接已断开');
      this.clientNumber = -1;
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Server] 断开客户端失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  public closeServerSocket(): void {
    if (this.serverNumber === -1) {
      console.warn('[SPP Server] 服务端socket未创建');
      return;
    }
    
    console.info('[SPP Server] 删除服务端socket');
    
    if (this.clientNumber !== -1) {
      this.disconnectClient();
    }
    
    try {
      socket.sppCloseServerSocket(this.serverNumber);
      console.info('[SPP Server] 服务端socket已删除');
      this.serverNumber = -1;
      this.isListening = false;
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Server] 删除socket失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  private handleReceivedData(data: Uint8Array): void {
    console.info('[SPP Server] 处理接收数据');
  }
  
  private handleServerError(err: BusinessError): void {
    switch (err.code) {
      case 201:
        console.error('[SPP Server] 权限不足');
        break;
      case 2900003:
        console.error('[SPP Server] 蓝牙未开启');
        break;
      case 2900004:
        console.error('[SPP Server] Profile不支持');
        break;
      case 2900099:
        console.error('[SPP Server] 操作失败');
        break;
      default:
        console.error('[SPP Server] 未知错误');
    }
  }
  
  private handleWriteError(err: BusinessError): void {
    switch (err.code) {
      case 2901054:
        console.error('[SPP Server] IO错误');
        this.disconnectClient();
        this.acceptConnection();
        break;
      case 2900099:
        console.error('[SPP Server] 操作失败');
        break;
      default:
        console.error('[SPP Server] 未知错误');
    }
  }
}

let sppServerManager = new SppServerManager();
export default sppServerManager as SppServerManager;