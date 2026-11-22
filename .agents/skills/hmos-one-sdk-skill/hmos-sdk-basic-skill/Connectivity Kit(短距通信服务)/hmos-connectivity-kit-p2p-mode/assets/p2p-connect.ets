import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'P2PConnect';
const DOMAIN = 0xFF00;

export async function discoverAndConnectDevices(): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      hilog.error(DOMAIN, TAG, 'Wi-Fi is not active, please enable Wi-Fi first');
      return;
    }
    
    let recvP2pConnectionChangeFunc = (result: wifiManager.WifiP2pLinkedInfo) => {
      hilog.info(DOMAIN, TAG, `P2P connection change receive event: ${JSON.stringify(result)}`);
      
      wifiManager.getP2pLinkedInfo((err, data) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `failed to get P2pLinkedInfo: ${JSON.stringify(err)}`);
          return;
        }
        hilog.info(DOMAIN, TAG, `get getP2pLinkedInfo: ${JSON.stringify(data)}`);
        
        if (data.connectState === wifiManager.P2pConnectState.P2P_CONNECTED) {
          hilog.info(DOMAIN, TAG, 'P2P connection established successfully');
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
            
            let config: wifiManager.WifiP2PConfig = {
              deviceAddress: data[i].deviceAddress,
              deviceAddressType: 1,
              netId: -2,
              passphrase: '',
              groupName: '',
              goBand: 0
            };
            
            wifiManager.p2pConnect(config);
            hilog.info(DOMAIN, TAG, 'P2P connect request sent');
          }
        }
      });
    };
    
    wifiManager.on('p2pPeerDeviceChange', recvP2pPeerDeviceChangeFunc);
    
    hilog.info(DOMAIN, TAG, 'Starting P2P device discovery');
    wifiManager.startDiscoverDevices();
    
    setTimeout(() => {
      wifiManager.off('p2pConnectionChange', recvP2pConnectionChangeFunc);
      hilog.info(DOMAIN, TAG, 'Unregistered p2pConnectionChange callback');
    }, 125 * 1000);
    
    setTimeout(() => {
      wifiManager.off('p2pPeerDeviceChange', recvP2pPeerDeviceChangeFunc);
      hilog.info(DOMAIN, TAG, 'Unregistered p2pPeerDeviceChange callback');
    }, 125 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Discover and connect failed: ${JSON.stringify(error)}`);
    
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied');
        break;
      case 401:
        hilog.error(DOMAIN, TAG, 'Invalid parameters');
        break;
      case 801:
        hilog.error(DOMAIN, TAG, 'Capability not supported');
        break;
      case 2801000:
        hilog.error(DOMAIN, TAG, 'P2P module exception');
        break;
      case 2801001:
        hilog.error(DOMAIN, TAG, 'Wi-Fi STA disabled');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
    }
  }
}

export async function cancelP2PConnect(): Promise<void> {
  try {
    wifiManager.p2pCancelConnect();
    hilog.info(DOMAIN, TAG, 'P2P connection cancelled successfully');
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Cancel P2P connect failed: ${JSON.stringify(error)}`);
  }
}