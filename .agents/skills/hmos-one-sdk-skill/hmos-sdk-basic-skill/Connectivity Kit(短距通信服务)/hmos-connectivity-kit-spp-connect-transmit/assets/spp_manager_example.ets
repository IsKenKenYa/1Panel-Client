import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class SppManager {
  private serverNumber: number = -1;
  private clientNumber: number = -1;
  private mode: 'client' | 'server' | 'none' = 'none';
  private isConnected: boolean = false;
  private dataReceiveCallback?: (data: Uint8Array) => void;
  
  constructor() {
    console.info('[SPP Manager] 初始化SPP管理器');
  }
  
  public initializeClient(peerDevice: string, uuid: string): Promise<number> {
    return new Promise((resolve, reject) => {
      if (this.mode !== 'none') {
        reject(new Error('已存在连接,请先清理'));
        return;
      }
      
      let option: socket.SppOptions = {
        uuid: uuid,
        secure: false,
        type: socket.SppType.SPP_RFCOMM
      };
      
      console.info('[SPP Manager] 初始化客户端: device=' + peerDevice);
      
      socket.sppConnect(peerDevice, option, (err: BusinessError, num: number) => {
        if (err) {
          console.error('[SPP Manager] 客户端连接失败: ' + err.message);
          reject(err);
        } else {
          this.clientNumber = num;
          this.mode = 'client';
          this.isConnected = true;
          console.info('[SPP Manager] 客户端连接成功: socketId=' + num);
          resolve(num);
        }
      });
    });
  }
  
  public initializeServer(serviceName: string, uuid: string): Promise<number> {
    return new Promise((resolve, reject) => {
      if (this.mode !== 'none') {
        reject(new Error('已存在监听socket,请先清理'));
        return;
      }
      
      let option: socket.SppOptions = {
        uuid: uuid,
        secure: false,
        type: socket.SppType.SPP_RFCOMM
      };
      
      console.info('[SPP Manager] 初始化服务端: name=' + serviceName);
      
      socket.sppListen(serviceName, option, (err: BusinessError, num: number) => {
        if (err) {
          console.error('[SPP Manager] 服务端创建失败: ' + err.message);
          reject(err);
        } else {
          this.serverNumber = num;
          this.mode = 'server';
          console.info('[SPP Manager] 服务端创建成功: socketId=' + num);
          this.waitForClientConnection();
          resolve(num);
        }
      });
    });
  }
  
  private waitForClientConnection(): void {
    if (this.serverNumber === -1) {
      console.error('[SPP Manager] 服务端socket无效');
      return;
    }
    
    console.info('[SPP Manager] 等待客户端连接');
    
    socket.sppAccept(this.serverNumber, (err: BusinessError, clientSocketId: number) => {
      if (err) {
        console.error('[SPP Manager] 客户端连接监听失败: ' + err.message);
      } else {
        this.clientNumber = clientSocketId;
        this.isConnected = true;
        console.info('[SPP Manager] 客户端已连接: clientSocketId=' + clientSocketId);
      }
    });
  }
  
  public sendData(data: Uint8Array): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.isConnected || this.clientNumber === -1) {
        reject(new Error('连接未建立'));
        return;
      }
      
      let arrayBuffer = new ArrayBuffer(data.length);
      let dataView = new Uint8Array(arrayBuffer);
      dataView.set(data);
      
      console.info('[SPP Manager] 发送数据: length=' + data.length);
      
      try {
        socket.sppWrite(this.clientNumber, arrayBuffer);
        console.info('[SPP Manager] 数据发送成功');
        resolve();
      } catch (err) {
        let error = err as BusinessError;
        console.error('[SPP Manager] 数据发送失败: ' + error.message);
        reject(error);
      }
    });
  }
  
  public setDataReceiveCallback(callback: (data: Uint8Array) => void): void {
    this.dataReceiveCallback = callback;
    console.info('[SPP Manager] 设置数据接收回调');
    
    if (this.clientNumber !== -1) {
      this.subscribeDataReceive();
    }
  }
  
  private subscribeDataReceive(): void {
    if (this.clientNumber === -1) {
      console.error('[SPP Manager] socket ID无效');
      return;
    }
    
    let readCallback = (dataBuffer: ArrayBuffer) => {
      let data = new Uint8Array(dataBuffer);
      console.info('[SPP Manager] 接收数据: length=' + data.byteLength);
      if (this.dataReceiveCallback) {
        this.dataReceiveCallback(data);
      }
    };
    
    try {
      socket.on('sppRead', this.clientNumber, readCallback);
      console.info('[SPP Manager] 数据订阅成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP Manager] 数据订阅失败: ' + error.message);
    }
  }
  
  public disconnect(): Promise<void> {
    return new Promise((resolve, reject) => {
      console.info('[SPP Manager] 开始清理连接');
      
      try {
        if (this.clientNumber !== -1) {
          socket.off('sppRead', this.clientNumber);
          socket.sppCloseClientSocket(this.clientNumber);
          this.clientNumber = -1;
          this.isConnected = false;
          console.info('[SPP Manager] 客户端连接已关闭');
        }
        
        if (this.serverNumber !== -1) {
          socket.sppCloseServerSocket(this.serverNumber);
          this.serverNumber = -1;
          console.info('[SPP Manager] 服务端socket已删除');
        }
        
        this.mode = 'none';
        console.info('[SPP Manager] 连接清理完成');
        resolve();
      } catch (err) {
        let error = err as BusinessError;
        console.error('[SPP Manager] 连接清理失败: ' + error.message);
        reject(error);
      }
    });
  }
  
  public getMode(): string {
    return this.mode;
  }
  
  public isConnectedStatus(): boolean {
    return this.isConnected;
  }
  
  public getClientSocketId(): number {
    return this.clientNumber;
  }
  
  public getServerSocketId(): number {
    return this.serverNumber;
  }
}

let sppManager = new SppManager();
export default sppManager as SppManager;