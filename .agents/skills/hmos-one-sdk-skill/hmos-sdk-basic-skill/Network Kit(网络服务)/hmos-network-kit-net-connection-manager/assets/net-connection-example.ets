import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NetConnectionExample';
const DOMAIN = 0x0000;

export class NetConnectionExample {
  private netConnection: connection.NetConnection | null = null;

  async startMonitoringDefaultNetwork(): Promise<void> {
    try {
      this.netConnection = connection.createNetConnection();
      
      this.netConnection.on('netAvailable', (data: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `Network available: netId=${data.netId}`);
        this.onNetworkAvailable(data);
      });

      this.netConnection.on('netUnavailable', () => {
        hilog.info(DOMAIN, TAG, 'Network unavailable');
        this.onNetworkUnavailable();
      });

      this.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
        hilog.info(DOMAIN, TAG, `Network capabilities changed: ${JSON.stringify(data)}`);
      });

      this.netConnection.on('netLost', (data: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `Network lost: netId=${data.netId}`);
        this.onNetworkLost(data);
      });

      await new Promise<void>((resolve, reject) => {
        this.netConnection!.register((err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Register failed: ${JSON.stringify(err)}`);
            reject(err);
          } else {
            hilog.info(DOMAIN, TAG, 'Register success');
            resolve();
          }
        });
      });

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Start monitoring failed: ${JSON.stringify(error)}`);
    }
  }

  async stopMonitoring(): Promise<void> {
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
            hilog.info(DOMAIN, TAG, 'Unregister success');
            resolve();
          }
        });
      });
      this.netConnection = null;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Stop monitoring failed: ${JSON.stringify(error)}`);
    }
  }

  async getDefaultNetworkInfo(): Promise<void> {
    try {
      const netHandle = await connection.getDefaultNet();
      
      if (netHandle.netId === 0) {
        hilog.warn(DOMAIN, TAG, 'No default network available');
        return;
      }

      hilog.info(DOMAIN, TAG, `Default network: netId=${netHandle.netId}`);

      const capabilities = await connection.getNetCapabilities(netHandle);
      hilog.info(DOMAIN, TAG, `Network capabilities: ${JSON.stringify(capabilities)}`);

      const properties = await connection.getConnectionProperties(netHandle);
      hilog.info(DOMAIN, TAG, `Connection properties: ${JSON.stringify(properties)}`);

      this.parseNetworkType(capabilities);
      this.parseNetworkCapabilities(capabilities);

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Get default network failed: code=${err.code}, message=${err.message}`);
    }
  }

  getDefaultNetworkInfoSync(): void {
    try {
      const netHandle = connection.getDefaultNetSync();
      
      if (!netHandle || netHandle.netId === 0) {
        hilog.warn(DOMAIN, TAG, 'No default network available');
        return;
      }

      const capabilities = connection.getNetCapabilitiesSync(netHandle);
      hilog.info(DOMAIN, TAG, `Default network (sync): ${JSON.stringify(capabilities)}`);

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Get default network (sync) failed: code=${err.code}`);
    }
  }

  async getAllNetworksInfo(): Promise<void> {
    try {
      const netHandles = await connection.getAllNets();
      hilog.info(DOMAIN, TAG, `All active networks: ${JSON.stringify(netHandles)}`);

      for (const netHandle of netHandles) {
        const capabilities = await connection.getNetCapabilities(netHandle);
        hilog.info(DOMAIN, TAG, `NetId=${netHandle.netId}, Capabilities=${JSON.stringify(capabilities)}`);

        const properties = await connection.getConnectionProperties(netHandle);
        hilog.info(DOMAIN, TAG, `NetId=${netHandle.netId}, Properties=${JSON.stringify(properties)}`);
      }

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Get all networks failed: code=${err.code}, message=${err.message}`);
    }
  }

  checkNetworkConnectivity(): boolean {
    try {
      const netHandle = connection.getDefaultNetSync();
      
      if (!netHandle || netHandle.netId === 0) {
        hilog.warn(DOMAIN, TAG, 'No default network available');
        return false;
      }

      const capabilities = connection.getNetCapabilitiesSync(netHandle);
      const caps = capabilities.networkCap;

      if (caps?.includes(connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY)) {
        hilog.info(DOMAIN, TAG, 'Network is checking connectivity');
        return false;
      }

      if (caps?.includes(connection.NetCap.NET_CAPABILITY_VALIDATED)) {
        hilog.info(DOMAIN, TAG, 'Network is validated, can access internet');
        return true;
      }

      hilog.info(DOMAIN, TAG, 'Network is not validated');
      return false;

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Check network connectivity failed: code=${err.code}`);
      return false;
    }
  }

  async resolveDomain(domain: string): Promise<connection.NetAddress[]> {
    try {
      const addresses = await connection.getAddressesByName(domain);
      hilog.info(DOMAIN, TAG, `DNS resolution for ${domain}: ${JSON.stringify(addresses)}`);
      
      for (const address of addresses) {
        hilog.info(DOMAIN, TAG, `IP: ${address.address}, Family: ${address.family}`);
      }

      return addresses;

    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `DNS resolution failed: code=${err.code}, message=${err.message}`);
      return [];
    }
  }

  private onNetworkAvailable(netHandle: connection.NetHandle): void {
    hilog.info(DOMAIN, TAG, `Network became available: netId=${netHandle.netId}`);
  }

  private onNetworkUnavailable(): void {
    hilog.warn(DOMAIN, TAG, 'Network became unavailable');
  }

  private onNetworkLost(netHandle: connection.NetHandle): void {
    hilog.warn(DOMAIN, TAG, `Network lost: netId=${netHandle.netId}`);
  }

  private parseNetworkType(capabilities: connection.NetCapabilities): void {
    for (const bearerType of capabilities.bearerTypes) {
      switch (bearerType) {
        case 0:
          hilog.info(DOMAIN, TAG, 'Network type: BEARER_CELLULAR (蜂窝网络)');
          break;
        case 1:
          hilog.info(DOMAIN, TAG, 'Network type: BEARER_WIFI (Wi-Fi网络)');
          break;
        case 3:
          hilog.info(DOMAIN, TAG, 'Network type: BEARER_ETHERNET (以太网)');
          break;
        default:
          hilog.info(DOMAIN, TAG, `Network type: Unknown (${bearerType})`);
      }
    }
  }

  private parseNetworkCapabilities(capabilities: connection.NetCapabilities): void {
    for (const cap of capabilities.networkCap) {
      switch (cap) {
        case 0:
          hilog.info(DOMAIN, TAG, 'Capability: NET_CAPABILITY_MMS (可访问MMSC)');
          break;
        case 11:
          hilog.info(DOMAIN, TAG, 'Capability: NET_CAPABILITY_NOT_METERED (流量不计费)');
          break;
        case 12:
          hilog.info(DOMAIN, TAG, 'Capability: NET_CAPABILITY_INTERNET (可访问Internet)');
          break;
        case 15:
          hilog.info(DOMAIN, TAG, 'Capability: NET_CAPABILITY_NOT_VPN (不使用VPN)');
          break;
        case 16:
          hilog.info(DOMAIN, TAG, 'Capability: NET_CAPABILITY_VALIDATED (连通性验证成功)');
          break;
        default:
          hilog.info(DOMAIN, TAG, `Capability: Unknown (${cap})`);
      }
    }
  }
}

export async function main(): Promise<void> {
  const example = new NetConnectionExample();

  await example.startMonitoringDefaultNetwork();
  
  await example.getDefaultNetworkInfo();
  example.getDefaultNetworkInfoSync();
  
  await example.getAllNetworksInfo();
  
  const isConnected = example.checkNetworkConnectivity();
  hilog.info(DOMAIN, TAG, `Network connectivity: ${isConnected}`);

  await example.resolveDomain('www.example.com');

  await example.stopMonitoring();
}