import { connection } from '@kit.NetworkKit';
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NetworkAutoReconnect';
const DOMAIN = 0x0000;

export class NetworkAutoReconnect {
  private netConnection: connection.NetConnection | null = null;
  private tcpSocket: socket.TCPSocket | null = null;
  private serverAddress: string = '';
  private serverPort: number = 0;
  private connectionTimeout: number = 6000;
  
  constructor(serverAddress: string, serverPort: number, timeout?: number) {
    this.serverAddress = serverAddress;
    this.serverPort = serverPort;
    if (timeout) {
      this.connectionTimeout = timeout;
    }
  }
  
  startAutoReconnect(): void {
    this.netConnection = connection.createNetConnection();
    
    this.setupNetworkListener();
    
    this.netConnection.register((error: BusinessError) => {
      if (error) {
        hilog.error(DOMAIN, TAG, `Register failed: ${JSON.stringify(error)}`);
      } else {
        hilog.info(DOMAIN, TAG, 'Register success, monitoring default network changes');
        this.createSocket();
      }
    });
  }
  
  private setupNetworkListener(): void {
    if (!this.netConnection) return;
    
    this.netConnection.on('netAvailable', (netHandle: connection.NetHandle) => {
      hilog.info(DOMAIN, TAG, `Default network changed to NetId: ${netHandle.netId}`);
      this.reconnectSocket();
    });
    
    this.netConnection.on('netLost', (netHandle: connection.NetHandle) => {
      hilog.info(DOMAIN, TAG, `Default network lost, NetId: ${netHandle.netId}`);
      this.handleNetworkLost();
    });
  }
  
  private createSocket(): void {
    this.tcpSocket = socket.constructTCPSocketInstance();
    hilog.info(DOMAIN, TAG, 'TCP socket created');
  }
  
  private reconnectSocket(): void {
    if (this.tcpSocket) {
      this.tcpSocket.close((err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Close old socket failed: ${JSON.stringify(err)}`);
        }
      });
    }
    
    this.createSocket();
    this.connectSocket();
  }
  
  private connectSocket(): void {
    if (!this.tcpSocket) {
      hilog.error(DOMAIN, TAG, 'Socket not created');
      return;
    }
    
    const netAddress: socket.NetAddress = {
      address: this.serverAddress,
      port: this.serverPort,
    };
    
    const tcpConnectOptions: socket.TCPConnectOptions = {
      address: netAddress,
      timeout: this.connectionTimeout,
    };
    
    this.tcpSocket.connect(tcpConnectOptions, (err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Connect failed: Code ${err.code}, Message: ${err.message}`);
        this.handleConnectionFailed(err);
        return;
      }
      
      hilog.info(DOMAIN, TAG, `Socket connected to ${this.serverAddress}:${this.serverPort}`);
      this.onConnectionEstablished();
    });
  }
  
  private handleNetworkLost(): void {
    if (this.tcpSocket) {
      this.tcpSocket.close((err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Close socket failed: ${JSON.stringify(err)}`);
        }
      });
    }
    this.onConnectionLost();
  }
  
  private handleConnectionFailed(error: BusinessError): void {
    hilog.error(DOMAIN, TAG, `Connection failed, will retry when network available`);
    this.onConnectionFailed(error);
  }
  
  stopAutoReconnect(): void {
    if (this.tcpSocket) {
      this.tcpSocket.close((err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Close socket failed: ${JSON.stringify(err)}`);
        }
      });
      this.tcpSocket = null;
    }
    
    if (this.netConnection) {
      this.netConnection.unregister((err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Unregister failed: ${JSON.stringify(err)}`);
        } else {
          hilog.info(DOMAIN, TAG, 'Unregister success');
        }
      });
      this.netConnection = null;
    }
  }
  
  sendData(data: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.tcpSocket) {
        reject(new Error('Socket not connected'));
        return;
      }
      
      const tcpSendOptions: socket.TCPSendOptions = {
        data: data,
      };
      
      this.tcpSocket.send(tcpSendOptions, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Send failed: ${JSON.stringify(err)}`);
          reject(err);
        } else {
          hilog.info(DOMAIN, TAG, `Data sent: ${data}`);
          resolve();
        }
      });
    });
  }
  
  protected onConnectionEstablished(): void {
    console.log('Connection established');
  }
  
  protected onConnectionLost(): void {
    console.log('Connection lost');
  }
  
  protected onConnectionFailed(error: BusinessError): void {
    console.log(`Connection failed: ${error.message}`);
  }
}

export function createAutoReconnectManager(serverAddress: string, serverPort: number): NetworkAutoReconnect {
  return new NetworkAutoReconnect(serverAddress, serverPort);
}

export async function testAutoReconnect(): Promise<void> {
  const manager = createAutoReconnectManager('192.168.1.100', 8080);
  
  manager.startAutoReconnect();
  
  await delay(5000);
  
  await manager.sendData('Hello, server!');
  
  await delay(3000);
  
  manager.stopAutoReconnect();
}

function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}