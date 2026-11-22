import { appInfoManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class DynamicIconManager {
  private readonly TAG: string = 'DynamicIconManager';

  async queryDynamicIcons(): Promise<appInfoManager.DynamicIconInfo[]> {
    try {
      const iconInfos: appInfoManager.DynamicIconInfo[] = 
        await appInfoManager.queryDynamicIcons();
      
      hilog.info(0, this.TAG, `Query succeeded, icon count: ${iconInfos.length}`);
      
      iconInfos.forEach((icon, index) => {
        hilog.info(0, this.TAG, 
          `Icon ${index}: id=${icon.iconId}, enabled=${icon.enabled}, url=${icon.iconUrl}`);
      });
      
      return iconInfos;
    } catch (error) {
      const err = error as BusinessError;
      this.handleError(err, 'queryDynamicIcons');
      throw error;
    }
  }

  async switchDynamicIcon(iconId: string): Promise<void> {
    if (!iconId || iconId.trim() === '') {
      hilog.error(0, this.TAG, 'Invalid iconId: empty or null');
      throw new Error('Invalid iconId parameter');
    }

    try {
      await appInfoManager.selectDynamicIcon(iconId);
      hilog.info(0, this.TAG, `Switch succeeded, new iconId: ${iconId}`);
    } catch (error) {
      const err = error as BusinessError;
      this.handleError(err, 'switchDynamicIcon');
      throw error;
    }
  }

  async restoreDefaultIcon(): Promise<void> {
    try {
      await appInfoManager.disableDynamicIcon();
      hilog.info(0, this.TAG, 'Restore default icon succeeded');
    } catch (error) {
      const err = error as BusinessError;
      this.handleError(err, 'restoreDefaultIcon');
      throw error;
    }
  }

  async queryWithRetry(maxRetries: number = 3): Promise<appInfoManager.DynamicIconInfo[]> {
    let lastError: BusinessError | null = null;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await this.queryDynamicIcons();
      } catch (error) {
        lastError = error as BusinessError;
        hilog.warn(0, this.TAG, `Attempt ${i + 1} failed, retrying...`);
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
    
    hilog.error(0, this.TAG, 'All retries failed');
    throw lastError;
  }

  async querySafely(): Promise<appInfoManager.DynamicIconInfo[]> {
    try {
      const icons = await this.queryDynamicIcons();
      return icons;
    } catch (error) {
      const err = error as BusinessError;
      if (err.code === 1006800010) {
        hilog.warn(0, this.TAG, 'No dynamic icon configured, returning empty array');
        return [];
      }
      throw error;
    }
  }

  private handleError(error: BusinessError, operation: string): void {
    const errorMsg = `${operation} failed, code: ${error.code}, message: ${error.message}`;
    
    switch (error.code) {
      case 1006800001:
        hilog.error(0, this.TAG, 
          `${errorMsg}. Suggestion: Install AppGallery client`);
        break;
      case 1006800009:
        hilog.error(0, this.TAG, 
          `${errorMsg}. Suggestion: Retry or contact support`);
        break;
      case 1006800010:
        hilog.error(0, this.TAG, 
          `${errorMsg}. Suggestion: Upload dynamic icons in AGC`);
        break;
      case 1006800011:
        hilog.error(0, this.TAG, 
          `${errorMsg}. Suggestion: Contact support`);
        break;
      case 1006800012:
        hilog.warn(0, this.TAG, 
          `${errorMsg}. Already using default icon`);
        break;
      case 1006800013:
        hilog.error(0, this.TAG, 
          `${errorMsg}. Suggestion: Switch to official theme first`);
        break;
      case 401:
        hilog.error(0, this.TAG, 
          `${errorMsg}. Suggestion: Check iconId parameter`);
        break;
      default:
        hilog.error(0, this.TAG, `Unknown error: ${errorMsg}`);
    }
  }
}