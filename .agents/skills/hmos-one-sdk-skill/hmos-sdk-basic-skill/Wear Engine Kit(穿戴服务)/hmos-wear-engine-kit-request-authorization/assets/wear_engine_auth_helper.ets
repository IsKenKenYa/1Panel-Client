import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class WearEngineAuthHelper {
  private authClient: wearEngine.AuthClient | null = null;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  private initAuthClient(): void {
    if (!this.authClient) {
      this.authClient = wearEngine.getAuthClient(this.context);
    }
  }

  async ensurePermissions(permissions: wearEngine.Permission[]): Promise<boolean> {
    this.initAuthClient();

    try {
      const authResult = await this.authClient!.getAuthorization();
      console.info(`Current authorized permissions: ${JSON.stringify(authResult.permissions)}`);

      const missingPermissions = permissions.filter(perm =>
        !authResult.permissions.includes(perm)
      );

      if (missingPermissions.length === 0) {
        console.info('All permissions are already authorized');
        return true;
      }

      console.info(`Requesting missing permissions: ${JSON.stringify(missingPermissions)}`);
      const requestResult = await this.authClient!.requestAuthorization({
        permissions: missingPermissions
      });

      const allGranted = permissions.every(perm =>
        requestResult.permissions.includes(perm)
      );

      if (allGranted) {
        console.info('All permissions granted');
        return true;
      } else {
        console.warn('Some permissions were not granted');
        return false;
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to ensure permissions. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }

  async getCurrentPermissions(): Promise<wearEngine.Permission[]> {
    this.initAuthClient();

    try {
      const result = await this.authClient!.getAuthorization();
      return result.permissions;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to get current permissions. Code: ${err.code}, Message: ${err.message}`);
      return [];
    }
  }

  async requestSinglePermission(permission: wearEngine.Permission): Promise<boolean> {
    this.initAuthClient();

    try {
      const result = await this.authClient!.requestAuthorization({
        permissions: [permission]
      });
      return result.permissions.includes(permission);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to request permission. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }

  async hasPermission(permission: wearEngine.Permission): Promise<boolean> {
    this.initAuthClient();

    try {
      const result = await this.authClient!.getAuthorization();
      return result.permissions.includes(permission);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to check permission. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }

  handleError(errorCode: number): string {
    switch (errorCode) {
      case 401:
        return '参数错误,请检查参数类型和必填项';
      case 801:
        return '当前设备不支持此能力';
      case 1008500001:
        return '网络错误,请检查网络连接';
      case 1008500004:
        return '应用未申请接入Wear Engine服务';
      case 1008500006:
        return '用户隐私未同意';
      case 1008500007:
        return '设备能力不支持';
      case 1008500008:
        return '用户未登录华为账号';
      case 1008500009:
        return '获取账号信息失败';
      case 1008509999:
        return '系统内部错误';
      default:
        return `未知错误: ${errorCode}`;
    }
  }
}