import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class PermissionRequestHelper {
  private context: common.UIAbilityContext;
  
  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }
  
  async checkPermission(permission: Permissions): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    
    try {
      const grantStatus = await atManager.checkAccessToken(
        this.context.applicationInfo.accessTokenId,
        permission
      );
      
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Check permission failed: ${error.message}`);
      return false;
    }
  }
  
  async requestPermission(permission: Permissions): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    
    try {
      const alreadyGranted = await this.checkPermission(permission);
      if (alreadyGranted) {
        console.info(`Permission ${permission} already granted`);
        return true;
      }
      
      const result = await atManager.requestPermissionsFromUser(this.context, [permission]);
      
      if (result.authResults[0] === 0) {
        console.info(`Permission ${permission} granted by user`);
        return true;
      } else {
        console.error(`Permission ${permission} denied by user`);
        return false;
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Request permission failed: ${error.message}`);
      return false;
    }
  }
  
  async requestBluetoothPermission(): Promise<boolean> {
    const permission: Permissions = 'ohos.permission.ACCESS_BLUETOOTH';
    return await this.requestPermission(permission);
  }
  
  async verifyBluetoothPermission(): Promise<void> {
    const hasPermission = await this.requestBluetoothPermission();
    
    if (!hasPermission) {
      console.error('Bluetooth permission is required for this feature');
      console.info('Please grant permission in system settings or restart the app');
    }
  }
}