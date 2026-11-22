import { connection, a2dp, hfp, hid, baseProfile, constant, common } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common as abilityCommon, Permissions } from '@kit.AbilityKit';

export class BluetoothPairConnectDemo {
  private context: abilityCommon.UIAbilityContext;
  private a2dpSrcProfile = a2dp.createA2dpSrcProfile();
  private hfpAgProfile = hfp.createHfpAgProfile();
  private hidHostProfile = hid.createHidHostProfile();
  
  constructor(context: abilityCommon.UIAbilityContext) {
    this.context = context;
  }
  
  async requestBluetoothPermission(): Promise<boolean> {
    const permission: Permissions = 'ohos.permission.ACCESS_BLUETOOTH';
    const atManager = abilityAccessCtrl.createAtManager();
    
    try {
      const grantStatus = await atManager.checkAccessToken(
        this.context.applicationInfo.accessTokenId, 
        permission
      );
      
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.info('Bluetooth permission already granted');
        return true;
      }
      
      const result = await atManager.requestPermissionsFromUser(this.context, [permission]);
      if (result.authResults[0] === 0) {
        console.info('Bluetooth permission granted by user');
        return true;
      } else {
        console.error('Bluetooth permission denied by user');
        return false;
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Permission check failed: code=${error.code}, message=${error.message}`);
      return false;
    }
  }
  
  subscribeBondStateChange(): void {
    const onBondStateChange = (data: connection.BondStateParam) => {
      console.info(`Bond state: device=${data.deviceId}, state=${data.state}`);
      
      if (data.state === connection.BondState.BOND_STATE_BONDED) {
        console.info('Device bonded successfully, can now connect profiles');
        this.connectDeviceProfiles(data.deviceId);
      }
    };
    
    try {
      connection.on('bondStateChange', onBondStateChange);
      console.info('Bond state change event subscribed');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Subscribe bond state failed: code=${error.code}, message=${error.message}`);
    }
  }
  
  async pairDevice(deviceId: string): Promise<void> {
    try {
      await connection.pairDevice(deviceId);
      console.info(`Pairing initiated for device: ${deviceId}`);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Pair failed: code=${error.code}, message=${error.message}`);
      this.handlePairError(error);
    }
  }
  
  async pairDeviceWithAddressType(deviceId: string, addressType: common.BluetoothAddressType): Promise<void> {
    try {
      const btAddr: common.BluetoothAddress = {
        address: deviceId,
        addressType: addressType
      };
      
      await connection.pairDevice(btAddr);
      console.info(`Pairing initiated with address type: ${addressType}`);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Pair failed: code=${error.code}, message=${error.message}`);
      this.handlePairError(error);
    }
  }
  
  private handlePairError(error: BusinessError): void {
    switch (error.code) {
      case 2900003:
        console.error('Bluetooth is disabled');
        break;
      case 2900099:
        console.error('Operation failed, check device availability');
        break;
      default:
        console.error('Unknown pair error');
    }
  }
  
  subscribeProfileConnectionState(): void {
    try {
      this.a2dpSrcProfile.on('connectionStateChange', (data: baseProfile.StateChangeParam) => {
        console.info(`A2DP state: device=${data.deviceId}, state=${data.state}`);
      });
      
      this.hfpAgProfile.on('connectionStateChange', (data: baseProfile.StateChangeParam) => {
        console.info(`HFP state: device=${data.deviceId}, state=${data.state}`);
      });
      
      this.hidHostProfile.on('connectionStateChange', (data: baseProfile.StateChangeParam) => {
        console.info(`HID state: device=${data.deviceId}, state=${data.state}`);
      });
      
      console.info('Profile connection state events subscribed');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Subscribe profile state failed: code=${error.code}, message=${error.message}`);
    }
  }
  
  async queryDeviceProfiles(deviceId: string): Promise<Array<connection.ProfileUuids>> {
    try {
      const uuids = await connection.getRemoteProfileUuids(deviceId);
      console.info(`Device profiles: ${JSON.stringify(uuids)}`);
      return uuids;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Query profiles failed: code=${error.code}, message=${error.message}`);
      return [];
    }
  }
  
  async connectDeviceProfiles(deviceId: string): Promise<void> {
    try {
      const uuids = await this.queryDeviceProfiles(deviceId);
      let supportedProfiles = 0;
      
      if (uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_A2DP_SINK.toLowerCase())) {
        console.info('Supports A2DP Sink');
        supportedProfiles++;
      }
      
      if (uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HFP_HF.toLowerCase())) {
        console.info('Supports HFP HF');
        supportedProfiles++;
      }
      
      if (uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HID.toLowerCase()) ||
          uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HOGP.toLowerCase())) {
        console.info('Supports HID');
        supportedProfiles++;
      }
      
      if (supportedProfiles > 0) {
        await connection.connectAllowedProfiles(deviceId);
        console.info(`Connecting profiles for: ${deviceId}`);
      } else {
        console.warn('Device does not support A2DP/HFP/HID');
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Connect profiles failed: code=${error.code}, message=${error.message}`);
    }
  }
  
  async executeFullFlow(targetDevice: string): Promise<void> {
    console.info('Starting bluetooth pair and connect flow');
    
    const hasPermission = await this.requestBluetoothPermission();
    if (!hasPermission) {
      console.error('Permission request failed, cannot proceed');
      return;
    }
    
    this.subscribeBondStateChange();
    this.subscribeProfileConnectionState();
    
    await this.pairDevice(targetDevice);
  }
}