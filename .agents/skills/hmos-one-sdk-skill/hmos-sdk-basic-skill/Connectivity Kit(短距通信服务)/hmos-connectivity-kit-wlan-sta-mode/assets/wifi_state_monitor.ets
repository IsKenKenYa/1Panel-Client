import { wifiManager } from '@kit.ConnectivityKit';

/**
 * Wi-Fi状态监控示例
 * 功能：监听Wi-Fi开关状态变化，查询当前Wi-Fi是否已使能
 */
export class WifiStateMonitor {
  private recvPowerNotifyFunc: (result: number) => void;
  private isMonitoring: boolean = false;

  constructor() {
    this.recvPowerNotifyFunc = (result: number) => {
      let wifiState = "";
      switch (result) {
        case 0:
          wifiState = 'DISABLED';
          break;
        case 1:
          wifiState = 'ENABLED';
          break;
        case 2:
          wifiState = 'ENABLING';
          break;
        case 3:
          wifiState = 'DISABLING';
          break;
        default:
          wifiState = 'UNKNOWN STATUS';
          break;
      }
      console.info(`Wi-Fi state changed: ${wifiState}`);
    };
  }

  startMonitor(): void {
    try {
      if (this.isMonitoring) {
        console.warn("Wi-Fi monitor is already running");
        return;
      }

      wifiManager.on("wifiStateChange", this.recvPowerNotifyFunc);
      this.isMonitoring = true;

      let isWifiActive = wifiManager.isWifiActive();
      if (!isWifiActive) {
        console.info("Wi-Fi not enabled. Waiting for user to enable...");
      } else {
        console.info("Wi-Fi is enabled. Monitoring state changes...");
      }
    } catch (error) {
      console.error(`WiFi state monitor failed: ${error.message}`);
    }
  }

  stopMonitor(): void {
    try {
      if (!this.isMonitoring) {
        console.warn("Wi-Fi monitor is not running");
        return;
      }

      wifiManager.off("wifiStateChange", this.recvPowerNotifyFunc);
      this.isMonitoring = false;
      console.info("Wi-Fi monitor stopped");
    } catch (error) {
      console.error(`Failed to stop monitor: ${error.message}`);
    }
  }

  getWifiState(): boolean {
    try {
      return wifiManager.isWifiActive();
    } catch (error) {
      console.error(`Failed to get Wi-Fi state: ${error.message}`);
      return false;
    }
  }
}

async function wifiStateMonitorExample(): Promise<void> {
  const monitor = new WifiStateMonitor();

  monitor.startMonitor();

  await new Promise(resolve => setTimeout(resolve, 10000));

  console.info(`Current Wi-Fi state: ${monitor.getWifiState() ? 'ENABLED' : 'DISABLED'}`);

  monitor.stopMonitor();
}