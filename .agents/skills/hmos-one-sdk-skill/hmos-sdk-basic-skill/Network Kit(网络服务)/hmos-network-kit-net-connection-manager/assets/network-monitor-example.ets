import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NetworkMonitorExample';
const DOMAIN = 0x0000;

export class NetworkMonitorExample {
  private wifiConnection: connection.NetConnection | null = null;
  private cellularConnection: connection.NetConnection | null = null;
  private defaultConnection: connection.NetConnection | null = null;

  async startWifiMonitoring(timeout: number = 10000): Promise<void> {
    try {
      const netSpecifier: connection.NetSpecifier = {
        netCapabilities: {
          bearerTypes: [connection.NetBearType.BEARER_WIFI],
          networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET]
        }
      };

      this.wifiConnection = connection.createNetConnection(netSpecifier, timeout);

      this.wifiConnection.on('netAvailable', (data: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `WiFi network available: netId=${data.netId}`);
      });

      this.wifiConnection.on('netUnavailable', () => {
        hilog.warn(DOMAIN, TAG, 'WiFi network unavailable (timeout)');
      });

      this.wifiConnection.on('netLost', (data: connection.NetHandle) => {
        hilog.warn(DOMAIN, TAG, `WiFi network lost: netId=${data.netId}`);
      });

      await new Promise<void>((resolve, reject) => {
        this.wifiConnection!.register((err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `WiFi register failed: ${JSON.stringify(err)}`);
            reject(err);
          } else {
            hilog.info(DOMAIN, TAG, 'WiFi monitoring started');
            resolve();
          }
        });
      });

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Start WiFi monitoring failed: ${JSON.stringify(error)}`);
    }
  }

  async startCellularMonitoring(timeout: number = 5000): Promise<void> {
    try {
      const netSpecifier: connection.NetSpecifier = {
        netCapabilities: {
          bearerTypes: [connection.NetBearType.BEARER_CELLULAR],
          networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET]
        }
      };

      this.cellularConnection = connection.createNetConnection(netSpecifier, timeout);

      this.cellularConnection.on('netAvailable', (data: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `Cellular network available: netId=${data.netId}`);
      });

      this.cellularConnection.on('netUnavailable', () => {
        hilog.warn(DOMAIN, TAG, 'Cellular network unavailable');
      });

      await new Promise<void>((resolve, reject) => {
        this.cellularConnection!.register((err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Cellular register failed: ${JSON.stringify(err)}`);
            reject(err);
          } else {
            hilog.info(DOMAIN, TAG, 'Cellular monitoring started');
            resolve();
          }
        });
      });

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Start cellular monitoring failed: ${JSON.stringify(error)}`);
    }
  }

  async startDefaultNetworkMonitoring(): Promise<void> {
    try {
      this.defaultConnection = connection.createNetConnection();

      this.defaultConnection.on('netAvailable', (data: connection.NetHandle) => {
        hilog.info(DOMAIN, TAG, `Default network changed: netId=${data.netId}`);
        this.logNetworkDetails(data);
      });

      this.defaultConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
        hilog.info(DOMAIN, TAG, `Default network capabilities changed: ${JSON.stringify(data)}`);
      });

      this.defaultConnection.on('netConnectionPropertiesChange', (data: connection.NetConnectionPropertyInfo) => {
        hilog.info(DOMAIN, TAG, `Default network properties changed: ${JSON.stringify(data)}`);
      });

      this.defaultConnection.on('netLost', (data: connection.NetHandle) => {
        hilog.warn(DOMAIN, TAG, `Default network lost: netId=${data.netId}`);
      });

      await new Promise<void>((resolve, reject) => {
        this.defaultConnection!.register((err: BusinessError) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Default network register failed: ${JSON.stringify(err)}`);
            reject(err);
          } else {
            hilog.info(DOMAIN, TAG, 'Default network monitoring started');
            resolve();
          }
        });
      });

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Start default network monitoring failed: ${JSON.stringify(error)}`);
    }
  }

  async stopAllMonitoring(): Promise<void> {
    const connections = [
      { conn: this.wifiConnection, name: 'WiFi' },
      { conn: this.cellularConnection, name: 'Cellular' },
      { conn: this.defaultConnection, name: 'Default' }
    ];

    for (const item of connections) {
      if (item.conn) {
        try {
          await new Promise<void>((resolve, reject) => {
            item.conn!.unregister((err: BusinessError) => {
              if (err) {
                hilog.error(DOMAIN, TAG, `${item.name} unregister failed: ${JSON.stringify(err)}`);
                reject(err);
              } else {
                hilog.info(DOMAIN, TAG, `${item.name} monitoring stopped`);
                resolve();
              }
            });
          });
        } catch (error) {
          hilog.error(DOMAIN, TAG, `Stop ${item.name} monitoring failed: ${JSON.stringify(error)}`);
        }
      }
    }

    this.wifiConnection = null;
    this.cellularConnection = null;
    this.defaultConnection = null;
  }

  async getCurrentNetworkStatus(): Promise<Map<string, boolean>> {
    const status = new Map<string, boolean>();

    try {
      const allNets = await connection.getAllNets();
      
      for (const netHandle of allNets) {
        const capabilities = await connection.getNetCapabilities(netHandle);
        
        for (const bearerType of capabilities.bearerTypes) {
          if (bearerType === 0) {
            status.set('Cellular', true);
          } else if (bearerType === 1) {
            status.set('WiFi', true);
          } else if (bearerType === 3) {
            status.set('Ethernet', true);
          }
        }
      }

      if (!status.has('Cellular')) {
        status.set('Cellular', false);
      }
      if (!status.has('WiFi')) {
        status.set('WiFi', false);
      }
      if (!status.has('Ethernet')) {
        status.set('Ethernet', false);
      }

      hilog.info(DOMAIN, TAG, `Current network status: ${JSON.stringify(Array.from(status.entries()))}`);

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Get network status failed: ${JSON.stringify(error)}`);
    }

    return status;
  }

  private async logNetworkDetails(netHandle: connection.NetHandle): Promise<void> {
    try {
      const capabilities = await connection.getNetCapabilities(netHandle);
      const properties = await connection.getConnectionProperties(netHandle);

      hilog.info(DOMAIN, TAG, `Network details for netId=${netHandle.netId}:`);
      hilog.info(DOMAIN, TAG, `  Capabilities: ${JSON.stringify(capabilities)}`);
      hilog.info(DOMAIN, TAG, `  Properties: ${JSON.stringify(properties)}`);

      this.parseNetworkInfo(capabilities, properties);

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Get network details failed: ${JSON.stringify(error)}`);
    }
  }

  private parseNetworkInfo(
    capabilities: connection.NetCapabilities,
    properties: connection.ConnectionProperties
  ): void {
    for (const bearerType of capabilities.bearerTypes) {
      const typeNames: Record<number, string> = {
        0: 'Cellular',
        1: 'WiFi',
        3: 'Ethernet'
      };
      hilog.info(DOMAIN, TAG, `  Type: ${typeNames[bearerType] || 'Unknown'}`);
    }

    for (const cap of capabilities.networkCap) {
      const capNames: Record<number, string> = {
        0: 'MMS',
        11: 'Not Metered',
        12: 'Internet',
        15: 'Not VPN',
        16: 'Validated'
      };
      hilog.info(DOMAIN, TAG, `  Capability: ${capNames[cap] || 'Unknown'}`);
    }

    if (properties.linkAddresses) {
      for (const addr of properties.linkAddresses) {
        hilog.info(DOMAIN, TAG, `  Link Address: ${addr.address}`);
      }
    }

    if (properties.dnsAddresses) {
      for (const dns of properties.dnsAddresses) {
        hilog.info(DOMAIN, TAG, `  DNS: ${dns.address}`);
      }
    }
  }
}

export async function main(): Promise<void> {
  const monitor = new NetworkMonitorExample();

  await monitor.startDefaultNetworkMonitoring();
  await monitor.startWifiMonitoring(10000);
  await monitor.startCellularMonitoring(5000);

  const status = await monitor.getCurrentNetworkStatus();
  hilog.info(DOMAIN, TAG, `Network status: Cellular=${status.get('Cellular')}, WiFi=${status.get('WiFi')}`);

  await new Promise(resolve => setTimeout(resolve, 60000));

  await monitor.stopAllMonitoring();
}