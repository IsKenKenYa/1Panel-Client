import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'P2PCreateGroup';
const DOMAIN = 0xFF00;

export async function createPermanentGroup(): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      hilog.error(DOMAIN, TAG, 'Wi-Fi is not active, please enable Wi-Fi first');
      return;
    }
    
    let recvP2pPersistentGroupChangeFunc = () => {
      hilog.info(DOMAIN, TAG, 'P2P persistent group change receive event');
    };
    
    wifiManager.on('p2pPersistentGroupChange', recvP2pPersistentGroupChangeFunc);
    
    let config: wifiManager.WifiP2PConfig = {
      deviceAddress: '00:11:22:33:44:55',
      deviceAddressType: 1,
      netId: -2,
      passphrase: '12345678',
      groupName: 'testGroup',
      goBand: 0
    };
    
    hilog.info(DOMAIN, TAG, `Creating P2P permanent group: ${config.groupName}`);
    wifiManager.createGroup(config);
    
    hilog.info(DOMAIN, TAG, 'P2P permanent group created successfully');
    hilog.info(DOMAIN, TAG, `Group name: ${config.groupName}, Passphrase: ${config.passphrase}`);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Create group failed: ${JSON.stringify(error)}`);
    
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied, please check GET_WIFI_INFO permission');
        break;
      case 401:
        hilog.error(DOMAIN, TAG, 'Invalid parameters, please check config format');
        break;
      case 801:
        hilog.error(DOMAIN, TAG, 'Capability not supported, this device does not support P2P');
        break;
      case 2801000:
        hilog.error(DOMAIN, TAG, 'P2P module exception, please try restart Wi-Fi');
        break;
      case 2801001:
        hilog.error(DOMAIN, TAG, 'Wi-Fi STA disabled, please enable Wi-Fi first');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.message}`);
    }
  }
}

export async function createTemporaryGroup(): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      hilog.error(DOMAIN, TAG, 'Wi-Fi is not active');
      return;
    }
    
    let config: wifiManager.WifiP2PConfig = {
      deviceAddress: '00:11:22:33:44:55',
      deviceAddressType: 1,
      netId: -1,
      passphrase: 'temp12345',
      groupName: 'tempGroup',
      goBand: wifiManager.GroupOwnerBand.GO_BAND_AUTO
    };
    
    hilog.info(DOMAIN, TAG, `Creating P2P temporary group: ${config.groupName}`);
    wifiManager.createGroup(config);
    
    hilog.info(DOMAIN, TAG, 'P2P temporary group created successfully');
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Create temporary group failed: ${JSON.stringify(error)}`);
  }
}

export async function removeGroup(): Promise<void> {
  try {
    wifiManager.removeGroup();
    hilog.info(DOMAIN, TAG, 'P2P group removed successfully');
  } catch (error) {
    hilog.error(DOMAIN, TAG, `Remove group failed: ${JSON.stringify(error)}`);
    
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied');
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