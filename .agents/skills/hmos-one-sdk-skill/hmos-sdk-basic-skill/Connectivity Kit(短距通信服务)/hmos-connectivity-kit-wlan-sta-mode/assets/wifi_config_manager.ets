import { wifiManager } from '@kit.ConnectivityKit';

export class WifiConfigManager {
  addCandidateConfig(ssid: string, password: string, securityType?: wifiManager.WifiSecurityType): Promise<number> {
    try {
      const secType = securityType || wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK;

      let config: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        preSharedKey: password,
        securityType: secType
      };

      return wifiManager.addCandidateConfig(config);
    } catch (error) {
      console.error(`Failed to add config: ${error.message}`);
      throw error;
    }
  }

  removeCandidateConfig(networkId: number): Promise<void> {
    try {
      return wifiManager.removeCandidateConfig(networkId);
    } catch (error) {
      console.error(`Failed to remove config: ${error.message}`);
      throw error;
    }
  }

  getCandidateConfigs(): wifiManager.WifiDeviceConfig[] {
    try {
      return wifiManager.getCandidateConfigs();
    } catch (error) {
      console.error(`Failed to get configs: ${error.message}`);
      throw error;
    }
  }

  listCandidateConfigs(): void {
    try {
      const configs = this.getCandidateConfigs();
      console.info(`Total candidate configs: ${configs.length}`);

      for (let i = 0; i < configs.length; i++) {
        console.info(`Config ${i}:`);
        console.info(`  SSID: ${configs[i].ssid}`);
        console.info(`  BSSID: ${configs[i].bssid || 'N/A'}`);
        console.info(`  Security Type: ${configs[i].securityType}`);
        console.info(`  Network ID: ${configs[i].netId || 'N/A'}`);
      }
    } catch (error) {
      console.error(`Failed to list configs: ${error.message}`);
    }
  }

  async clearAllCandidateConfigs(): Promise<void> {
    try {
      const configs = this.getCandidateConfigs();
      console.info(`Clearing ${configs.length} candidate configs...`);

      for (const config of configs) {
        if (config.netId !== undefined) {
          await this.removeCandidateConfig(config.netId);
          console.info(`Removed config: ${config.ssid} (ID: ${config.netId})`);
        }
      }

      console.info("All candidate configs cleared");
    } catch (error) {
      console.error(`Failed to clear configs: ${error.message}`);
      throw error;
    }
  }

  async updateCandidateConfig(oldNetworkId: number, newSsid: string, newPassword: string): Promise<number> {
    try {
      await this.removeCandidateConfig(oldNetworkId);
      console.info(`Removed old config (ID: ${oldNetworkId})`);

      const newNetworkId = await this.addCandidateConfig(newSsid, newPassword);
      console.info(`Added new config (ID: ${newNetworkId})`);

      return newNetworkId;
    } catch (error) {
      console.error(`Failed to update config: ${error.message}`);
      throw error;
    }
  }
}

async function wifiConfigManagerExample(): Promise<void> {
  const manager = new WifiConfigManager();

  try {
    manager.listCandidateConfigs();

    const networkId1 = await manager.addCandidateConfig("Network1", "Password1");
    console.info(`Added Network1, ID: ${networkId1}`);

    const networkId2 = await manager.addCandidateConfig("Network2", "Password2");
    console.info(`Added Network2, ID: ${networkId2}`);

    manager.listCandidateConfigs();

    await manager.removeCandidateConfig(networkId1);
    console.info(`Removed Network1`);

    manager.listCandidateConfigs();

    const updatedId = await manager.updateCandidateConfig(networkId2, "Network2Updated", "NewPassword");
    console.info(`Updated Network2, new ID: ${updatedId}`);

    manager.listCandidateConfigs();

    await new Promise(resolve => setTimeout(resolve, 3000));

    await manager.clearAllCandidateConfigs();
    console.info("Cleared all configs");
  } catch (error) {
    console.error(`Example failed: ${error.message}`);
  }
}