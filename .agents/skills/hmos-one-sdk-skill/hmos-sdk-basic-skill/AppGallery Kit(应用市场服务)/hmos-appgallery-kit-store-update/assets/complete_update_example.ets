import { updateManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

enum UpdateState {
  IDLE = 'IDLE',
  CHECKING = 'CHECKING',
  UPDATE_AVAILABLE = 'UPDATE_AVAILABLE',
  UPDATING = 'UPDATING',
  NO_UPDATE = 'NO_UPDATE',
  ERROR = 'ERROR'
}

@Entry
@Component
struct CompleteUpdateExample {
  @State message: string = '应用更新检查';
  @State updateState: UpdateState = UpdateState.IDLE;
  @State versionName: string = '';
  @State versionCode: number = 0;

  build() {
    Column() {
      Text(this.message)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      if (this.updateState === UpdateState.UPDATE_AVAILABLE) {
        Text(`发现新版本: ${this.versionName} (${this.versionCode})`)
          .fontSize(24)
          .margin({ bottom: 20 })

        Button('立即更新')
          .width('60%')
          .height(50)
          .onClick(() => {
            this.showUpdateDialog();
          })
      }

      Button('检查更新')
        .width('60%')
        .height(50)
        .margin({ top: 20 })
        .enabled(this.updateState !== UpdateState.CHECKING)
        .onClick(() => {
          this.checkForUpdates();
        })

      if (this.updateState === UpdateState.CHECKING) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 })
      }

      if (this.updateState === UpdateState.ERROR) {
        Text(this.message)
          .fontSize(18)
          .fontColor(Color.Red)
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private async checkForUpdates(): Promise<void> {
    this.updateState = UpdateState.CHECKING;
    this.message = '正在检查更新...';

    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const checkResult: updateManager.CheckUpdateResult = await updateManager.checkAppUpdate(context);
      
      if (checkResult.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
        this.updateState = UpdateState.UPDATE_AVAILABLE;
        this.versionName = checkResult.versionName || '';
        this.versionCode = checkResult.versionCode || 0;
        this.message = '发现新版本';
        hilog.info(0, 'Update', `发现新版本: ${this.versionName} (${this.versionCode})`);
      } else {
        this.updateState = UpdateState.NO_UPDATE;
        this.message = '当前已是最新版本';
        hilog.info(0, 'Update', '当前已是最新版本');
      }
    } catch (error) {
      const err = error as BusinessError;
      this.updateState = UpdateState.ERROR;
      this.handleUpdateError(err);
    }
  }

  private async showUpdateDialog(): Promise<void> {
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const resultCode: updateManager.ShowUpdateResultCode = await updateManager.showUpdateDialog(context);
      
      if (resultCode === updateManager.ShowUpdateResultCode.SHOW_DIALOG_SUCCESS) {
        this.updateState = UpdateState.UPDATING;
        this.message = '请在应用市场完成更新';
        hilog.info(0, 'Update', '更新对话框显示成功');
      } else {
        this.updateState = UpdateState.ERROR;
        this.message = '更新对话框显示失败';
        hilog.error(0, 'Update', '更新对话框显示失败');
      }
    } catch (error) {
      const err = error as BusinessError;
      this.updateState = UpdateState.ERROR;
      this.handleUpdateError(err);
    }
  }

  private handleUpdateError(error: BusinessError): void {
    hilog.error(0, 'Update', `错误: ${error.code}, ${error.message}`);

    const errorMessages: Record<number, string> = {
      401: '参数错误，请检查调用参数',
      1009400001: '服务连接失败，请重试',
      1009400002: '服务请求失败，请稍后重试',
      1009400003: '网络错误，请检查网络连接',
      1009400004: '请在前台使用此功能',
      1009400005: '请先同意隐私协议',
      1009400006: '操作过于频繁，请稍后重试',
      1009400007: '发生未知错误'
    };

    this.message = errorMessages[error.code] || `错误: ${error.code}`;

    if (error.code === 1009400003) {
      this.showNetworkErrorFallback();
    } else if (error.code === 1009400004) {
      this.scheduleBackgroundCheck();
    }
  }

  private showNetworkErrorFallback(): void {
    hilog.warn(0, 'Update', '网络不可用，建议用户稍后手动检查更新');
    this.message = '网络不可用，请稍后手动检查更新';
  }

  private scheduleBackgroundCheck(): void {
    hilog.warn(0, 'Update', '应用不在前台，建议稍后检查');
    this.message = '请在前台使用更新功能';
  }
}