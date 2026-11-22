import { updateManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct CheckUpdateExample {
  @State message: string = '检查应用更新';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.checkForUpdates();
          })
      }
      .width('100%')
    }
    .height('100%')
  }

  private async checkForUpdates(): Promise<void> {
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const checkResult: updateManager.CheckUpdateResult = await updateManager.checkAppUpdate(context);
      
      if (checkResult.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
        hilog.info(0, 'CheckUpdate', '发现新版本');
        
        if (checkResult.versionName) {
          hilog.info(0, 'CheckUpdate', `新版本名称: ${checkResult.versionName}`);
        }
        
        if (checkResult.versionCode) {
          hilog.info(0, 'CheckUpdate', `新版本号: ${checkResult.versionCode}`);
        }
        
        this.showUpdateDialog(context);
      } else {
        hilog.info(0, 'CheckUpdate', '当前已是最新版本');
        this.message = '当前已是最新版本';
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0, 'CheckUpdate', `检查更新失败: ${err.code}, ${err.message}`);
      this.handleUpdateError(err);
    }
  }

  private async showUpdateDialog(context: common.UIAbilityContext): Promise<void> {
    try {
      const resultCode: updateManager.ShowUpdateResultCode = await updateManager.showUpdateDialog(context);
      
      if (resultCode === updateManager.ShowUpdateResultCode.SHOW_DIALOG_SUCCESS) {
        hilog.info(0, 'CheckUpdate', '更新对话框显示成功');
        this.message = '请前往应用市场更新';
      } else {
        hilog.error(0, 'CheckUpdate', '更新对话框显示失败');
        this.message = '更新对话框显示失败';
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0, 'CheckUpdate', `显示更新对话框失败: ${err.code}, ${err.message}`);
      this.handleUpdateError(err);
    }
  }

  private handleUpdateError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        this.message = '参数错误';
        break;
      case 1009400001:
        this.message = '服务连接错误';
        break;
      case 1009400002:
        this.message = '服务请求错误';
        break;
      case 1009400003:
        this.message = '网络错误，请检查网络';
        break;
      case 1009400004:
        this.message = '请在前台使用';
        break;
      case 1009400005:
        this.message = '请先同意隐私协议';
        break;
      case 1009400006:
        this.message = '操作过于频繁，请稍后';
        break;
      case 1009400007:
        this.message = '未知错误';
        break;
      default:
        this.message = `错误: ${error.code}`;
    }
  }
}