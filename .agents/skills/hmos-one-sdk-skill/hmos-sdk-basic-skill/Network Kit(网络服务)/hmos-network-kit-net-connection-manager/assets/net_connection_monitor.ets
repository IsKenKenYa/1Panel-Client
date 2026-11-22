import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'NetConnectionMonitor';
const DOMAIN = 0x0000;

export class NetConnectionMonitor {
  private netConnection: connection.NetConnection | null = null;
  
  startMonitoring(specifier?: connection.NetSpecifier, timeout?: number): void {
    if (specifier && timeout) {
      this.netConnection = connection.createNetConnection(specifier, timeout);
    } else {
      this.netConnection = connection.createNetConnection();
    }
    
    this.setupEventListeners();
    this.register();
  }
  
  private setupEventListeners(): void {
    if (!this.netConnection) return;
    
    this.netConnection.on('netAvailable', (data: connection.NetHandle) => {
      hilog.info(DOMAIN, TAG, `Network available, NetId: ${data.netId}`);
      this.onNetworkAvailable(data);
    });
    
    this.netConnection.on('netUnavailable', (data: void) => {
      hilog.info(DOMAIN, TAG, 'Network unavailable');
      this.onNetworkUnavailable();
    });
    
    this.netConnection.on('netLost', (data: connection.NetHandle) => {
      hilog.info(DOMAIN, TAG, `Network lost, NetId: ${data.netId}`);
      this.onNetworkLost(data);
    });
    
    this.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
      hilog.info(DOMAIN, TAG, `Network capabilities changed: ${JSON.stringify(data)}`);
      this.onCapabilitiesChanged(data);
    });
    
    this.netConnection.on('netConnectionPropertiesChange', (data: connection.NetConnectionPropertyInfo) => {
      hilog.info(DOMAIN, TAG, `Network properties changed: ${JSON.stringify(data)}`);
      this.onPropertiesChanged(data);
    });
  }
  
  private register(): void {
    if (!this.netConnection) return;
    
    this.netConnection.register((err: BusinessError, data: void) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Register failed: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Register success');
    });
  }
  
  stopMonitoring(): void {
    if (!this.netConnection) return;
    
    this.netConnection.unregister((err: BusinessError, data: void) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Unregister failed: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Unregister success');
      this.netConnection = null;
    });
  }
  
  private onNetworkAvailable(netHandle: connection.NetHandle): void {
    console.log(`Network available: ${netHandle.netId}`);
  }
  
  private onNetworkUnavailable(): void {
    console.log('Network unavailable');
  }
  
  private onNetworkLost(netHandle: connection.NetHandle): void {
    console.log(`Network lost: ${netHandle.netId}`);
  }
  
  private onCapabilitiesChanged(capabilityInfo: connection.NetCapabilityInfo): void {
    console.log(`Capabilities changed: ${JSON.stringify(capabilityInfo)}`);
  }
  
  private onPropertiesChanged(propertyInfo: connection.NetConnectionPropertyInfo): void {
    console.log(`Properties changed: ${JSON.stringify(propertyInfo)}`);
  }
}

export function createWiFiNetworkSpecifier(): connection.NetSpecifier {
  return {
    netCapabilities: {
      bearerTypes: [connection.NetBearType.BEARER_WIFI],
      networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET],
    }
  };
}

export function createCellularNetworkSpecifier(): connection.NetSpecifier {
  return {
    netCapabilities: {
      bearerTypes: [connection.NetBearType.BEARER_CELLULAR],
      networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET],
    }
  };
}

export function monitorDefaultNetwork(): NetConnectionMonitor {
  const monitor = new NetConnectionMonitor();
  monitor.startMonitoring();
  return monitor;
}

export function monitorWiFiNetwork(timeout: number = 10000): NetConnectionMonitor {
  const monitor = new NetConnectionMonitor();
  const specifier = createWiFiNetworkSpecifier();
  monitor.startMonitoring(specifier, timeout);
  return monitor;
}