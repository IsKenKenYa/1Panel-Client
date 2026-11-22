import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct WearEngineAuthExample {
  private authClient: wearEngine.AuthClient | null = null;
  @State message: string = '点击按钮申请权限';
  @State authorizedPermissions: string = '';

  aboutToAppear() {
    this.authClient = wearEngine.getAuthClient(this.getUIContext().getHostContext());
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text(this.authorizedPermissions)
        .fontSize(16)
        .margin({ bottom: 20 })

      Button('申请用户状态权限')
        .width('80%')
        .height(50)
        .margin({ bottom: 10 })
        .onClick(() => {
          this.requestUserStatusPermission();
        })

      Button('申请健康传感器权限')
        .width('80%')
        .height(50)
        .margin({ bottom: 10 })
        .onClick(() => {
          this.requestHealthSensorPermission();
        })

      Button('申请多个权限')
        .width('80%')
        .height(50)
        .margin({ bottom: 10 })
        .onClick(() => {
          this.requestMultiplePermissions();
        })

      Button('查询已授权权限')
        .width('80%')
        .height(50)
        .margin({ bottom: 10 })
        .onClick(() => {
          this.queryAuthorizedPermissions();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  async requestUserStatusPermission() {
    try {
      let request: wearEngine.AuthorizationRequest = {
        permissions: [wearEngine.Permission.USER_STATUS]
      };

      const result = await this.authClient!.requestAuthorization(request);
      this.message = '申请权限成功';
      this.authorizedPermissions = `已授权: ${this.permissionToString(result.permissions)}`;
    } catch (error) {
      const err = error as BusinessError;
      this.message = `申请失败: ${err.message}`;
      this.authorizedPermissions = `错误码: ${err.code}`;
    }
  }

  async requestHealthSensorPermission() {
    try {
      let request: wearEngine.AuthorizationRequest = {
        permissions: [wearEngine.Permission.HEALTH_SENSOR]
      };

      const result = await this.authClient!.requestAuthorization(request);
      this.message = '申请健康传感器权限成功';
      this.authorizedPermissions = `已授权: ${this.permissionToString(result.permissions)}`;
    } catch (error) {
      const err = error as BusinessError;
      this.message = `申请失败: ${err.message}`;
      this.authorizedPermissions = `错误码: ${err.code}`;
    }
  }

  async requestMultiplePermissions() {
    try {
      let request: wearEngine.AuthorizationRequest = {
        permissions: [
          wearEngine.Permission.USER_STATUS,
          wearEngine.Permission.MOTION_SENSOR,
          wearEngine.Permission.HEALTH_SENSOR
        ]
      };

      const result = await this.authClient!.requestAuthorization(request);
      this.message = '申请多个权限成功';
      this.authorizedPermissions = `已授权: ${this.permissionToString(result.permissions)}`;
      
      if (result.permissions.length < request.permissions.length) {
        this.message = '部分权限已授权';
      }
    } catch (error) {
      const err = error as BusinessError;
      this.message = `申请失败: ${err.message}`;
      this.authorizedPermissions = `错误码: ${err.code}`;
    }
  }

  async queryAuthorizedPermissions() {
    try {
      const result = await this.authClient!.getAuthorization();
      this.message = '查询授权权限成功';
      this.authorizedPermissions = `当前已授权: ${this.permissionToString(result.permissions)}`;
    } catch (error) {
      const err = error as BusinessError;
      this.message = `查询失败: ${err.message}`;
      this.authorizedPermissions = `错误码: ${err.code}`;
    }
  }

  permissionToString(permissions: wearEngine.Permission[]): string {
    return permissions.map(perm => {
      switch (perm) {
        case wearEngine.Permission.USER_STATUS:
          return 'USER_STATUS';
        case wearEngine.Permission.MOTION_SENSOR:
          return 'MOTION_SENSOR';
        case wearEngine.Permission.HEALTH_SENSOR:
          return 'HEALTH_SENSOR';
        case wearEngine.Permission.DEVICE_IDENTIFIER:
          return 'DEVICE_IDENTIFIER';
        default:
          return 'UNKNOWN';
      }
    }).join(', ');
  }
}