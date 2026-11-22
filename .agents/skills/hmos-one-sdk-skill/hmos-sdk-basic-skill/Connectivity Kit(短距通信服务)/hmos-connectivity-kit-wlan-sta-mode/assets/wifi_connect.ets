import { wifiManager } from '@kit.ConnectivityKit';

export class WifiConnector {
  private recvWifiConnectionChangeFunc: (result: number) => void;
  private isMonitoring: boolean = false;
  private isConnectedFlag: boolean = false;

  constructor() {
    this.recvWifiConnectionChangeFunc = (result: number) => {
      console.info(`Wi-Fi connection state changed: ${result}`);
      this.isConnectedFlag = result === 1;
    };
  }

  async connectToWifi(ssid: string, password: string, securityType?: wifiManager.WifiSecurityType): Promise<number> {
    try {
      if (!wifiManager.isWifiActive()) {
        console.error("Wi-Fi is not enabled");
        throw new Error("Wi-Fi not enabled");
      }

      const secType = securityType || wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK;

      let config: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        preSharedKey: password,
        securityType: secType
      };

      wifiManager.on("wifiConnectionChange", this.recvWifiConnectionChangeFunc);
      this.isMonitoring = true;

      let networkId = await wifiManager.addCandidateConfig(config);
      console.info(`Candidate config added, networkId: ${networkId}`);

      wifiManager.connectToCandidateConfig(networkId);

      await new Promise(resolve => setTimeout(resolve, 5000));

      if (wifiManager.isConnected()) {
        console.info("Wi-Fi connected successfully");
        let linkedInfo = await wifiManager.getLinkedInfo();
        console.info(`Connected to: ${linkedInfo.ssid}`);
        console.info(`Signal level: ${wifiManager.getSignalLevel(linkedInfo.rssi, linkedInfo.band)}`);
      } else {
        console.warn("Wi-Fi connection timeout or failed");
      }

      return networkId;
    } catch (error) {
      console.error(`WiFi connection failed: ${error.message}`);
      throw error;
    }
  }

  async disconnectWifi(networkId: number): Promise<void> {
    try {
      await wifiManager.removeCandidateConfig(networkId);
      console.info(`Candidate config ${networkId} removed`);
    } catch (error) {
      console.error(`Failed to disconnect: ${error.message}`);
      throw error;
    }
  }

  getConnectionInfo(): Promise<wifiManager.WifiLinkedInfo> {
    return wifiManager.getLinkedInfo();
  }

  stopMonitoring(): void {
    if (this.isMonitoring) {
      wifiManager.off("wifiConnectionChange", this.recvWifiConnectionChangeFunc);
      this.isMonitoring = false;
      console.info("Connection monitoring stopped");
    }
  }
}

async function wifiConnectExample(): Promise<void> {
  const connector = new WifiConnector();

  try {
    const ssid = "YourWiFiSSID";
    const password = "YourWiFiPassword";

    const networkId = await connector.connectToWifi(ssid, password);

    await new Promise(resolve => setTimeout(resolve, 3000));

    const linkedInfo = await connector.getConnectionInfo();
    console.info(`Connection info: ${JSON.stringify(linkedInfo)}`);

    await new Promise(resolve => setTimeout(resolve, 5000));

    await connector.disconnectWifi(networkId);
  } catch (error) {
    console.error(`Example failed: ${error.message}`);
  } finally {
    connector.stopMonitoring();
  }
}