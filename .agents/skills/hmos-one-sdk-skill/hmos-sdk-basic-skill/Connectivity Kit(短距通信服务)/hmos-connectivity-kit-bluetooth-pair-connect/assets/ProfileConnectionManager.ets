import { connection, a2dp, hfp, hid, baseProfile, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class ProfileConnectionManager {
  private a2dpProfile = a2dp.createA2dpSrcProfile();
  private hfpProfile = hfp.createHfpAgProfile();
  private hidProfile = hid.createHidHostProfile();
  private connectionStates: Map<string, Map<string, baseProfile.ProfileConnectionState>> = new Map();
  
  constructor() {
    this.subscribeAllProfileStates();
  }
  
  private subscribeAllProfileStates(): void {
    this.a2dpProfile.on('connectionStateChange', (data: baseProfile.StateChangeParam) => {
      this.updateConnectionState('A2DP', data);
      console.info(`A2DP connection state changed: device=${data.deviceId}, state=${data.state}`);
    });
    
    this.hfpProfile.on('connectionStateChange', (data: baseProfile.StateChangeParam) => {
      this.updateConnectionState('HFP', data);
      console.info(`HFP connection state changed: device=${data.deviceId}, state=${data.state}`);
    });
    
    this.hidProfile.on('connectionStateChange', (data: baseProfile.StateChangeParam) => {
      this.updateConnectionState('HID', data);
      console.info(`HID connection state changed: device=${data.deviceId}, state=${data.state}`);
    });
  }
  
  private updateConnectionState(profile: string, data: baseProfile.StateChangeParam): void {
    if (!this.connectionStates.has(data.deviceId)) {
      this.connectionStates.set(data.deviceId, new Map());
    }
    
    const deviceStates = this.connectionStates.get(data.deviceId)!;
    deviceStates.set(profile, data.state);
  }
  
  getConnectionState(deviceId: string, profile: string): baseProfile.ProfileConnectionState | undefined {
    const deviceStates = this.connectionStates.get(deviceId);
    if (!deviceStates) {
      return undefined;
    }
    
    return deviceStates.get(profile);
  }
  
  getAllConnectionStates(deviceId: string): Map<string, baseProfile.ProfileConnectionState> | undefined {
    return this.connectionStates.get(deviceId);
  }
  
  async checkDeviceProfileSupport(deviceId: string): Promise<{
    a2dp: boolean;
    hfp: boolean;
    hid: boolean;
  }> {
    try {
      const uuids = await connection.getRemoteProfileUuids(deviceId);
      
      const supportInfo = {
        a2dp: uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_A2DP_SINK.toLowerCase()),
        hfp: uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HFP_HF.toLowerCase()),
        hid: uuids.some(uuid => 
          uuid === constant.ProfileUuids.PROFILE_UUID_HID.toLowerCase() ||
          uuid === constant.ProfileUuids.PROFILE_UUID_HOGP.toLowerCase()
        )
      };
      
      console.info(`Device ${deviceId} profile support: ${JSON.stringify(supportInfo)}`);
      return supportInfo;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Check profile support failed: ${error.message}`);
      return { a2dp: false, hfp: false, hid: false };
    }
  }
  
  async connectProfiles(deviceId: string): Promise<void> {
    try {
      const supportInfo = await this.checkDeviceProfileSupport(deviceId);
      const supportedCount = (supportInfo.a2dp ? 1 : 0) + (supportInfo.hfp ? 1 : 0) + (supportInfo.hid ? 1 : 0);
      
      if (supportedCount === 0) {
        console.warn(`Device ${deviceId} does not support any profiles`);
        return;
      }
      
      await connection.connectAllowedProfiles(deviceId);
      console.info(`Initiated profile connection for device ${deviceId}`);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Connect profiles failed: ${error.message}`);
    }
  }
  
  isProfileConnected(deviceId: string, profile: string): boolean {
    const state = this.getConnectionState(deviceId, profile);
    return state === baseProfile.ProfileConnectionState.STATE_CONNECTED;
  }
  
  waitForProfileConnection(deviceId: string, profile: string, timeoutMs: number = 30000): Promise<boolean> {
    return new Promise((resolve) => {
      const startTime = Date.now();
      
      const checkInterval = setInterval(() => {
        if (this.isProfileConnected(deviceId, profile)) {
          clearInterval(checkInterval);
          resolve(true);
        }
        
        if (Date.now() - startTime > timeoutMs) {
          clearInterval(checkInterval);
          console.warn(`Profile ${profile} connection timeout for device ${deviceId}`);
          resolve(false);
        }
      }, 1000);
    });
  }
}