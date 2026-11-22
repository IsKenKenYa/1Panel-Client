import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class PermissionManager {
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
      console.error(`检查权限失败: ${error.message}`);
      return false;
    }
  }

  async requestPermission(permission: Permissions): Promise<boolean> {
    const hasPermission = await this.checkPermission(permission);
    
    if (hasPermission) {
      console.info(`权限 ${permission} 已授予`);
      return true;
    }

    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const result = await atManager.requestPermissionsFromUser(
        this.context,
        [permission]
      );

      if (result.authResults[0] === 0) {
        console.info(`权限 ${permission} 申请成功`);
        return true;
      } else {
        console.warn(`权限 ${permission} 申请失败，用户拒绝授权`);
        return false;
      }
    } catch (err) {
      const error = err as BusinessError;
      console.error(`申请权限失败: ${error.message}`);
      return false;
    }
  }

  async requestMultiplePermissions(permissions: Permissions[]): Promise<boolean[]> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const result = await atManager.requestPermissionsFromUser(
        this.context,
        permissions
      );

      const grantedList: boolean[] = result.authResults.map((authResult) => {
        return authResult === 0;
      });

      console.info(`权限申请结果: ${JSON.stringify(grantedList)}`);
      return grantedList;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`批量申请权限失败: ${error.message}`);
      return permissions.map(() => false);
    }
  }
}

import { motion } from '@kit.MultimodalAwarenessKit';

@Entry
@Component
struct PermissionRequestPage {
  @State permissionStatus: string = '未申请';
  private permissionManager: PermissionManager | null = null;

  aboutToAppear() {
    this.permissionManager = new PermissionManager(getContext(this) as common.UIAbilityContext);
  }

  async requestMotionPermission() {
    const granted = await this.permissionManager!.requestPermission(
      'ohos.permission.ACTIVITY_MOTION'
    );
    
    if (granted) {
      this.permissionStatus = 'ACTIVITY_MOTION权限已授予';
      console.info('可以订阅操作手状态了');
    } else {
      this.permissionStatus = 'ACTIVITY_MOTION权限被拒绝';
    }
  }

  async requestGesturePermission() {
    const granted = await this.permissionManager!.requestPermission(
      'ohos.permission.DETECT_GESTURE'
    );
    
    if (granted) {
      this.permissionStatus = 'DETECT_GESTURE权限已授予';
      console.info('可以订阅握持手状态了');
    } else {
      this.permissionStatus = 'DETECT_GESTURE权限被拒绝';
    }
  }

  async requestAllPermissions() {
    const grantedList = await this.permissionManager!.requestMultiplePermissions([
      'ohos.permission.ACTIVITY_MOTION',
      'ohos.permission.DETECT_GESTURE'
    ]);

    let statusText: string = '';
    if (grantedList[0]) {
      statusText += 'ACTIVITY_MOTION: 已授予\n';
    } else {
      statusText += 'ACTIVITY_MOTION: 被拒绝\n';
    }

    if (grantedList[1]) {
      statusText += 'DETECT_GESTURE: 已授予';
    } else {
      statusText += 'DETECT_GESTURE: 被拒绝';
    }

    this.permissionStatus = statusText;
  }

  async checkPermissions() {
    const hasMotion = await this.permissionManager!.checkPermission(
      'ohos.permission.ACTIVITY_MOTION'
    );
    const hasGesture = await this.permissionManager!.checkPermission(
      'ohos.permission.DETECT_GESTURE'
    );

    this.permissionStatus = `ACTIVITY_MOTION: ${hasMotion ? '已授予' : '未授予'}\nDETECT_GESTURE: ${hasGesture ? '已授予' : '未授予'}`;
  }

  build() {
    Column() {
      Text('权限申请示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(this.permissionStatus)
        .fontSize(16)
        .margin({ bottom: 20 });

      Button('申请ACTIVITY_MOTION权限')
        .width('80%')
        .onClick(() => {
          this.requestMotionPermission();
        })
        .margin({ bottom: 10 });

      Button('申请DETECT_GESTURE权限')
        .width('80%')
        .onClick(() => {
          this.requestGesturePermission();
        })
        .margin({ bottom: 10 });

      Button('申请所有权限')
        .width('80%')
        .onClick(() => {
          this.requestAllPermissions();
        })
        .margin({ bottom: 10 });

      Button('检查权限状态')
        .width('80%')
        .onClick(() => {
          this.checkPermissions();
        })
        .margin({ bottom: 10 });

      Text('说明:')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text('ACTIVITY_MOTION: 用于操作手识别')
        .fontSize(14)
        .margin({ top: 5 });

      Text('DETECT_GESTURE: 用于握持手识别')
        .fontSize(14)
        .margin({ top: 5 });

      Text('这两个权限都是user_grant权限，需要用户手动授权')
        .fontSize(14)
        .margin({ top: 5 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}