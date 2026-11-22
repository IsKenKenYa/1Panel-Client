import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';

const TAG = 'P2PCompleteExample';
const DOMAIN = 0xFF00;

export class P2PManager {
  private isSwitchOn: boolean = false;
  private netId: number = -2;
  private passphrase: string = '12345678';
  private groupName: string = 'testGroup';
  private goBand: number = 0;

  aboutToAppear(): void {
    if (!wifiManager.isWifiActive()) {
      promptAction.showToast({
        message: 'Please active Wi-Fi first',
        duration: 2000
      });
      return;
    }
    
    this.isSwitchOn = true;
    this.startP2PDiscovery();
    this.addListener();
  }

  aboutToDisappear(): void {
    wifiManager.off('p2pPeerDeviceChange');
    wifiManager.off('p2pConnectionChange');
    wifiManager.off('p2pPersistentGroupChange');
  }

  async createGroup(): Promise<void> {
    try {
      let deviceInfo = await wifiManager.getP2pLocalDevice();
      let config: wifiManager.WifiP2PConfig = {
        deviceAddress: deviceInfo.deviceAddress,
        deviceAddressType: 1,
        netId: this.netId,
        passphrase: this.passphrase,
        groupName: this.groupName,
        goBand: this.goBand
      };
      
      hilog.info(DOMAIN, TAG, `deviceAddress: ${config.deviceAddress}, netId: ${config.netId}`);
      hilog.info(DOMAIN, TAG, `passphrase: ${config.passphrase}, groupName: ${config.groupName}`);
      
      await wifiManager.createGroup(config);
      
      promptAction.showToast({
        message: 'Create group success',
        duration: 2000
      });
      
      hilog.info(DOMAIN, TAG, 'P2P group created successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Create group error: ${JSON.stringify(error)}`);
      
      promptAction.showToast({
        message: `Create group failed: ${error.message}`,
        duration: 2000
      });
    }
  }

  async removeGroup(): Promise<void> {
    try {
      wifiManager.removeGroup();
      
      promptAction.showToast({
        message: 'Remove group success',
        duration: 2000
      });
      
      hilog.info(DOMAIN, TAG, 'P2P group removed successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Remove group error: ${JSON.stringify(error)}`);
    }
  }

  connectP2p(p2pScanInfo: wifiManager.WifiP2pDevice): void {
    promptAction.showToast({
      message: 'Connect to device',
      duration: 2000
    });
    
    hilog.info(DOMAIN, TAG, `connect deviceAddress=${p2pScanInfo.deviceAddress}`);
    hilog.info(DOMAIN, TAG, `p2pScanInfo: ${JSON.stringify(p2pScanInfo)}`);
    
    let config: wifiManager.WifiP2PConfig = {
      deviceAddress: p2pScanInfo.deviceAddress,
      deviceAddressType: 1,
      netId: -2,
      passphrase: '',
      groupName: '',
      goBand: 0
    };
    
    wifiManager.p2pConnect(config);
  }

  startP2PDiscovery(): void {
    try {
      wifiManager.startDiscoverDevices();
      hilog.info(DOMAIN, TAG, 'P2P device discovery started');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Start discovery error: ${JSON.stringify(error)}`);
    }
  }

  stopP2PDiscovery(): void {
    try {
      wifiManager.stopDiscoverDevices();
      hilog.info(DOMAIN, TAG, 'P2P device discovery stopped');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Stop discovery error: ${JSON.stringify(error)}`);
    }
  }

  addListener(): void {
    let recvP2pConnectionChangeFunc = (result: wifiManager.WifiP2pLinkedInfo) => {
      hilog.info(DOMAIN, TAG, `p2p connection change receive event: ${JSON.stringify(result)}`);
      
      wifiManager.getP2pLinkedInfo((err, data) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `failed to get P2pLinkedInfo: ${JSON.stringify(err)}`);
          return;
        }
        hilog.info(DOMAIN, TAG, `get getP2pLinkedInfo: ${JSON.stringify(data)}`);
        
        if (data.connectState === wifiManager.P2pConnectState.P2P_CONNECTED) {
          this.getGroupInfo();
        }
      });
    };
    
    wifiManager.on('p2pConnectionChange', recvP2pConnectionChangeFunc);
    
    let recvP2pPeerDeviceChangeFunc = (result: wifiManager.WifiP2pDevice[]) => {
      hilog.info(DOMAIN, TAG, `p2p peer device change receive event: ${JSON.stringify(result)}`);
      
      wifiManager.getP2pPeerDevices((err, data) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `failed to get peer devices: ${JSON.stringify(err)}`);
          return;
        }
        hilog.info(DOMAIN, TAG, `get peer devices: ${JSON.stringify(data)}`);
        
        let len = data.length;
        for (let i = 0; i < len; ++i) {
          if (data[i].deviceName === 'my_test_device') {
            hilog.info(DOMAIN, TAG, `p2p connect to test device: ${data[i].deviceAddress}`);
            this.connectP2p(data[i]);
          }
        }
      });
    };
    
    wifiManager.on('p2pPeerDeviceChange', recvP2pPeerDeviceChangeFunc);
    
    let recvP2pPersistentGroupChangeFunc = () => {
      hilog.info(DOMAIN, TAG, 'p2p persistent group change receive event');
    };
    
    wifiManager.on('p2pPersistentGroupChange', recvP2pPersistentGroupChangeFunc);
  }

  async getGroupInfo(): Promise<void> {
    try {
      let groupInfo = await wifiManager.getCurrentGroup();
      hilog.info(DOMAIN, TAG, `Current group info: ${JSON.stringify(groupInfo)}`);
      hilog.info(DOMAIN, TAG, `Group owner IP: ${groupInfo.goIpAddress}`);
      
      promptAction.showToast({
        message: `Connected! Group IP: ${groupInfo.goIpAddress}`,
        duration: 3000
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Get group info error: ${JSON.stringify(error)}`);
    }
  }

  async getConnectionInfo(): Promise<void> {
    try {
      let linkedInfo = await wifiManager.getP2pLinkedInfo();
      hilog.info(DOMAIN, TAG, `P2P linked info: ${JSON.stringify(linkedInfo)}`);
      
      if (linkedInfo.connectState === wifiManager.P2pConnectState.P2P_CONNECTED) {
        hilog.info(DOMAIN, TAG, 'P2P connected');
        this.getGroupInfo();
      } else {
        hilog.info(DOMAIN, TAG, 'P2P not connected');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Get connection info error: ${JSON.stringify(error)}`);
    }
  }
}