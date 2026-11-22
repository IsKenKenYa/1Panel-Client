import { connection, a2dp, hfp, hid, baseProfile, constant, common } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common as abilityCommon } from '@kit.AbilityKit';

export class PairDeviceManager {
  private device: string = '';
  private pairState: connection.BondState = connection.BondState.BOND_STATE_INVALID;
  private a2dpSrc = a2dp.createA2dpSrcProfile();
  private hfpAg = hfp.createHfpAgProfile();
  private hidHost = hid.createHidHostProfile();
  private pairRetryCount = 0;
  private maxRetryCount = 3;
  private context: abilityCommon.UIAbilityContext;

  constructor(context: abilityCommon.UIAbilityContext) {
    this.context = context;
  }

  async requestBluetoothPermission(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const grantResult = await atManager.requestPermissionsFromUser(
        this.context,
        ['ohos.permission.ACCESS_BLUETOOTH']
      );
      return grantResult.authResults[0] === 0;
    } catch (err) {
      console.error('Request permission failed: ' + JSON.stringify(err));
      return false;
    }
  }

  private onBondStateEvent = (data: connection.BondStateParam) => {
    console.info('Bond state changed: ' + JSON.stringify(data));
    if (data && data.deviceId === this.device) {
      this.pairState = data.state;
      if (data.state === connection.BondState.BOND_STATE_BONDED) {
        console.info('Device paired successfully');
        setTimeout(() => {
          this.connectProfiles(data.deviceId);
        }, 100);
      } else if (data.state === connection.BondState.BOND_STATE_INVALID) {
        console.error('Pairing failed or cancelled');
        this.handlePairingFailure();
      }
    }
  };

  private onA2dpConnectStateChange = (data: baseProfile.StateChangeParam) => {
    console.info('A2DP state: ' + JSON.stringify(data));
    if (data.state === constant.ProfileConnectionState.PROFILE_STATE_CONNECTED) {
      console.info('A2DP connected successfully');
    } else if (data.state === constant.ProfileConnectionState.PROFILE_STATE_DISCONNECTED) {
      console.warn('A2DP disconnected');
    }
  };

  private onHfpConnectStateChange = (data: baseProfile.StateChangeParam) => {
    console.info('HFP state: ' + JSON.stringify(data));
    if (data.state === constant.ProfileConnectionState.PROFILE_STATE_CONNECTED) {
      console.info('HFP connected successfully');
    } else if (data.state === constant.ProfileConnectionState.PROFILE_STATE_DISCONNECTED) {
      console.warn('HFP disconnected');
    }
  };

  private onHidConnectStateChange = (data: baseProfile.StateChangeParam) => {
    console.info('HID state: ' + JSON.stringify(data));
    if (data.state === constant.ProfileConnectionState.PROFILE_STATE_CONNECTED) {
      console.info('HID connected successfully');
    } else if (data.state === constant.ProfileConnectionState.PROFILE_STATE_DISCONNECTED) {
      console.warn('HID disconnected');
    }
  };

  async startPair(device: string): Promise<void> {
    const hasPermission = await this.requestBluetoothPermission();
    if (!hasPermission) {
      console.error('Bluetooth permission not granted');
      return;
    }

    this.device = device;
    this.pairRetryCount = 0;

    try {
      connection.on('bondStateChange', this.onBondStateEvent);
    } catch (err) {
      const error = err as BusinessError;
      console.error('Subscribe bondStateChange failed: code=' + error.code + ', message=' + error.message);
      return;
    }

    try {
      connection.pairDevice(device).then(() => {
        console.info('PairDevice request sent');
      }).catch((error: BusinessError) => {
        console.error('PairDevice failed: code=' + error.code + ', message=' + error.message);
        this.handlePairingError(error);
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error('PairDevice exception: code=' + error.code + ', message=' + error.message);
    }
  }

  async startPairWithAddressType(btAddr: common.BluetoothAddress): Promise<void> {
    const hasPermission = await this.requestBluetoothPermission();
    if (!hasPermission) {
      console.error('Bluetooth permission not granted');
      return;
    }

    this.device = btAddr.address;
    this.pairRetryCount = 0;

    try {
      connection.on('bondStateChange', this.onBondStateEvent);
    } catch (err) {
      const error = err as BusinessError;
      console.error('Subscribe bondStateChange failed: code=' + error.code + ', message=' + error.message);
      return;
    }

    try {
      connection.pairDevice(btAddr).then(() => {
        console.info('PairDevice request sent');
      }).catch((error: BusinessError) => {
        console.error('PairDevice failed: code=' + error.code + ', message=' + error.message);
        this.handlePairingError(error);
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error('PairDevice exception: code=' + error.code + ', message=' + error.message);
    }
  }

  private async connectProfiles(deviceId: string): Promise<void> {
    try {
      const uuids = await connection.getRemoteProfileUuids(deviceId);
      console.info('Supported profiles: ' + JSON.stringify(uuids));

      const hasA2dp = uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_A2DP_SINK.toLowerCase());
      const hasHfp = uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HFP_HF.toLowerCase());
      const hasHid = uuids.some(uuid =>
        uuid === constant.ProfileUuids.PROFILE_UUID_HID.toLowerCase() ||
        uuid === constant.ProfileUuids.PROFILE_UUID_HOGP.toLowerCase()
      );

      if (!hasA2dp && !hasHfp && !hasHid) {
        console.warn('Device does not support A2DP/HFP/HID');
        return;
      }

      if (hasA2dp) {
        this.a2dpSrc.on('connectionStateChange', this.onA2dpConnectStateChange);
      }
      if (hasHfp) {
        this.hfpAg.on('connectionStateChange', this.onHfpConnectStateChange);
      }
      if (hasHid) {
        this.hidHost.on('connectionStateChange', this.onHidConnectStateChange);
      }

      connection.connectAllowedProfiles(deviceId).then(() => {
        console.info('ConnectAllowedProfiles request sent');
      }).catch((error: BusinessError) => {
        console.error('ConnectAllowedProfiles failed: code=' + error.code + ', message=' + error.message);
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error('Connect profiles failed: code=' + error.code + ', message=' + error.message);
    }
  }

  private handlePairingError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('Permission denied');
        break;
      case 401:
        console.error('Invalid parameter');
        break;
      case 801:
        console.error('Capability not supported');
        break;
      case 2900001:
        console.error('Service stopped');
        break;
      case 2900003:
        console.error('Bluetooth disabled');
        break;
      case 2900099:
        console.error('Operation failed');
        break;
      default:
        console.error('Unknown error');
    }
  }

  private handlePairingFailure(): void {
    this.pairRetryCount++;
    if (this.pairRetryCount < this.maxRetryCount) {
      console.info('Retrying pairing... (' + this.pairRetryCount + '/' + this.maxRetryCount + ')');
      setTimeout(() => {
        this.startPair(this.device);
      }, 1000);
    } else {
      console.error('Max retry count reached. Please pair manually in Bluetooth settings');
    }
  }

  async disconnectProfiles(deviceId: string): Promise<void> {
    try {
      this.a2dpSrc.disconnect(deviceId);
      this.hfpAg.disconnect(deviceId);
      this.hidHost.disconnect(deviceId);
      console.info('Disconnected all profiles');
    } catch (err) {
      const error = err as BusinessError;
      console.error('Disconnect failed: code=' + error.code + ', message=' + error.message);
    }
  }

  async unpairDevice(deviceId: string): Promise<void> {
    try {
      await connection.removeBond(deviceId);
      console.info('Device unpaired successfully');
    } catch (err) {
      const error = err as BusinessError;
      console.error('Unpair failed: code=' + error.code + ', message=' + error.message);
    }
  }
}

let pairDeviceManager: PairDeviceManager | null = null;

export function initPairDeviceManager(context: abilityCommon.UIAbilityContext): PairDeviceManager {
  pairDeviceManager = new PairDeviceManager(context);
  return pairDeviceManager;
}

export function getPairDeviceManager(): PairDeviceManager | null {
  return pairDeviceManager;
}