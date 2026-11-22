import { connection, socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NetworkSwitchExample';
const DOMAIN = 0x0000;

export class NetworkSwitchHandler {
  private netConnection: connection.NetConnection | null = null;
  private tcpSocket: socket.TCPSocket | null = null;
  private serverAddress: socket.NetAddress = {
    address: '192.168.1.100',
    port: 8080
  };

  async startNetworkMonitorAndReconnect(): Promise<void> {
    try {
      this.netConnection = connection.createNetConnection();

      this.netConnection.on('netAvailable', async (netHandle: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `Default network changed: netId=${netHandle.netId}`);
        await this.reconnectSocket();
      });

      this.netConnection.on('netLost', (netHandle: connection.NetHandle) => {
        hilog.warn(DOMAIN, TAG, `Network lost: netId=${netHandle.netId}`);
        this.closeSocket();
      });

      await new Promise<void>((resolve, reject) => {
        this.netConnection!.register((err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Register failed: ${JSON.stringify(err)}`);
            reject(err);
          } else {
            hilog.info(DOMAIN, TAG, 'Network monitor registered');
            resolve();
          }
        });
      });

      const initialNet = await connection.getDefaultNet();
      if (initialNet.netId !== 0) {
        await this.reconnectSocket();
      }

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Start monitor failed: ${JSON.stringify(error)}`);
    }
  }

  async stopNetworkMonitor(): Promise<void> {
    if (!this.netConnection) {
      return;
    }

    try {
      await new Promise<void>((resolve, reject) => {
        this.netConnection!.unregister((err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Unregister failed: ${JSON.stringify(err)}`);
            reject(err);
          } else {
            hilog.info(DOMAIN, TAG, 'Network monitor unregistered');
            resolve();
          }
        });
      });

      this.closeSocket();
      this.netConnection = null;

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Stop monitor failed: ${JSON.stringify(error)}`);
    }
  }

  private async reconnectSocket(): Promise<void> {
    try {
      this.closeSocket();

      this.tcpSocket = socket.constructTCPSocketInstance();

      const connectOptions: socket.TCPConnectOptions = {
        address: this.serverAddress,
        timeout: 6000
      };

      await this.tcpSocket.connect(connectOptions);
      hilog.info(DOMAIN, TAG, 'Socket connected successfully');

      await this.sendTestData();

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Socket reconnect failed: code=${err.code}, message=${err.message}`);
      
      await this.retryConnection(3);
    }
  }

  private async sendTestData(): Promise<void> {
    if (!this.tcpSocket) {
      return;
    }

    try {
      const sendOptions: socket.TCPSendOptions = {
        data: 'Hello, server!'
      };

      await this.tcpSocket.send(sendOptions);
      hilog.info(DOMAIN, TAG, 'Data sent successfully');

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Send data failed: code=${err.code}, message=${err.message}`);
    }
  }

  private closeSocket(): void {
    if (this.tcpSocket) {
      try {
        this.tcpSocket.close();
        hilog.info(DOMAIN, TAG, 'Socket closed');
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Close socket failed: ${JSON.stringify(error)}`);
      }
      this.tcpSocket = null;
    }
  }

  private async retryConnection(maxRetries: number): Promise<void> {
    for (let i = 0; i < maxRetries; i++) {
      hilog.info(DOMAIN, TAG, `Retrying connection (${i + 1}/${maxRetries})`);
      
      await new Promise(resolve => setTimeout(resolve, 2000));

      try {
        await this.reconnectSocket();
        hilog.info(DOMAIN, TAG, 'Retry connection succeeded');
        return;
      } catch (error) {
        hilog.error(DOMAIN, TAG, `Retry ${i + 1} failed`);
      }
    }

    hilog.error(DOMAIN, TAG, 'All retry attempts failed');
  }

  async checkNetworkBeforeConnect(): Promise<boolean> {
    try {
      const netHandle = connection.getDefaultNetSync();
      
      if (!netHandle || netHandle.netId === 0) {
        hilog.warn(DOMAIN, TAG, 'No network available, cannot connect');
        return false;
      }

      const capabilities = connection.getNetCapabilitiesSync(netHandle);
      const caps = capabilities.networkCap;

      if (caps?.includes(connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY)) {
        hilog.info(DOMAIN, TAG, 'Network is checking, please wait');
        return false;
      }

      if (!caps?.includes(connection.NetCap.NET_CAPABILITY_VALIDATED)) {
        hilog.warn(DOMAIN, TAG, 'Network not validated, connection may fail');
        return false;
      }

      hilog.info(DOMAIN, TAG, 'Network is validated, ready to connect');
      return true;

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Check network failed: ${JSON.stringify(error)}`);
      return false;
    }
  }
}

export async function main(): Promise<void> {
  const handler = new NetworkSwitchHandler();

  const isNetworkReady = await handler.checkNetworkBeforeConnect();
  if (!isNetworkReady) {
    hilog.error(DOMAIN, TAG, 'Network not ready, exit');
    return;
  }

  await handler.startNetworkMonitorAndReconnect();

  await new Promise(resolve => setTimeout(resolve, 30000));

  await handler.stopNetworkMonitor();
}