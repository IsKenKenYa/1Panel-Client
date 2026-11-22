import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import hilog from '@ohos.hilog';
import fs from '@ohos.file.fs';

const TAG = 'ShareKitReceiver';
const DOMAIN = 0xFF00;

export default class EntryAbility extends UIAbility {
  async onCreate(want: common.Want, launchParam: common.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'EntryAbility onCreate');
    
    if (want.parameters) {
      await this.handleShareData(want);
    }
  }

  async handleShareData(want: common.Want): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Handling share data');
      
      if (!want.parameters) {
        hilog.error(DOMAIN, TAG, 'Want parameters is empty');
        return;
      }
      
      const streamKey = 'ohos.extra.param.key.stream';
      const files = want.parameters[streamKey] as Array<string>;
      
      if (!files || files.length === 0) {
        hilog.error(DOMAIN, TAG, 'No files received');
        return;
      }
      
      if (files.length > 1) {
        hilog.error(DOMAIN, TAG, 'Multiple files not supported, count: %{public}d', files.length);
        return;
      }
      
      const filePath = files[0];
      hilog.info(DOMAIN, TAG, 'Received file: %{public}s', filePath);
      
      if (!filePath) {
        hilog.error(DOMAIN, TAG, 'File path is empty');
        return;
      }
      
      const fileInfo: fs.Stat = await fs.stat(filePath);
      hilog.info(DOMAIN, TAG, 'File size: %{public}d bytes', fileInfo.size);
      
      const fileName = filePath.split('/').pop() || 'unknown';
      hilog.info(DOMAIN, TAG, 'File name: %{public}s', fileName);
      
      const fileExtension = fileName.split('.').pop() || '';
      hilog.info(DOMAIN, TAG, 'File extension: %{public}s', fileExtension);
      
      const context = getContext(this) as common.UIAbilityContext;
      const cacheDir = context.cacheDir;
      const destPath = `${cacheDir}/${fileName}`;
      
      await fs.copyFile(filePath, destPath);
      hilog.info(DOMAIN, TAG, 'File copied to: %{public}s', destPath);
      
      this.showSuccessToast(`接收文件成功: ${fileName}`);
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Handle share data failed: %{public}s', error.message);
      this.showErrorToast('接收文件失败');
    }
  }

  showSuccessToast(message: string): void {
    hilog.info(DOMAIN, TAG, 'Success: %{public}s', message);
  }

  showErrorToast(message: string): void {
    hilog.error(DOMAIN, TAG, 'Error: %{public}s', message);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageCreate');
    
    const mainWindow = await windowStage.getMainWindow();
    const windowClass = await mainWindow;
    
    await windowClass.setWindowLayoutFullScreen(true);
    
    const displayInfo = await windowClass.getLastWindow(getContext(this));
    const properties = await displayInfo.getProperties();
    const screenHeight = properties.windowRect.height;
    const avoidArea = await windowClass.getAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    
    hilog.info(DOMAIN, TAG, 'Screen height: %{public}d', screenHeight);
    
    try {
      await windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', err.message);
          return;
        }
        hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Load content failed: %{public}s', error.message);
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'EntryAbility onBackground');
  }
}