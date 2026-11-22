import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'ErrorHandling';

export class ErrorHandler {
  public static handleError(error: BusinessError): string {
    hilog.error(0x0001, TAG, `Error code: ${error.code}, message: ${error.message}`);
    
    let errorMessage: string;
    
    switch (error.code) {
      case 401:
        errorMessage = '参数错误：请检查uri是否有效';
        hilog.error(0x0001, TAG, 'Parameter error occurred');
        this.logParameterError(error);
        break;
        
      case 1011:
        errorMessage = '拉起/切前台失败';
        hilog.error(0x0001, TAG, 'Failed to pull up or switch to foreground');
        this.logForegroundError(error);
        break;
        
      case 1012:
        errorMessage = '切后台失败';
        hilog.error(0x0001, TAG, 'Failed to switch to background');
        this.logBackgroundError(error);
        break;
        
      case 1013:
        errorMessage = '销毁失败';
        hilog.error(0x0001, TAG, 'Failed to destroy');
        this.logDestroyError(error);
        break;
        
      default:
        errorMessage = `未知错误: ${error.code} - ${error.message}`;
        hilog.error(0x0001, TAG, 'Unknown error occurred');
        this.logUnknownError(error);
    }
    
    return errorMessage;
  }
  
  private static logParameterError(error: BusinessError): void {
    hilog.error(0x0001, TAG, 'Possible causes:');
    hilog.error(0x0001, TAG, '- uri parameter is empty or invalid');
    hilog.error(0x0001, TAG, '- context type is incorrect');
    hilog.error(0x0001, TAG, '- Want object structure is malformed');
  }
  
  private static logForegroundError(error: BusinessError): void {
    hilog.error(0x0001, TAG, 'Possible causes:');
    hilog.error(0x0001, TAG, '- AppGallery service is unavailable');
    hilog.error(0x0001, TAG, '- Device does not support this feature');
    hilog.error(0x0001, TAG, '- System resources are insufficient');
  }
  
  private static logBackgroundError(error: BusinessError): void {
    hilog.error(0x0001, TAG, 'Possible causes:');
    hilog.error(0x0001, TAG, '- System internal error');
    hilog.error(0x0001, TAG, '- Application lifecycle issue');
  }
  
  private static logDestroyError(error: BusinessError): void {
    hilog.error(0x0001, TAG, 'Possible causes:');
    hilog.error(0x0001, TAG, '- System internal error');
    hilog.error(0x0001, TAG, '- Page lifecycle issue');
  }
  
  private static logUnknownError(error: BusinessError): void {
    hilog.error(0x0001, TAG, 'Error details:');
    hilog.error(0x0001, TAG, `Code: ${error.code}`);
    hilog.error(0x0001, TAG, `Message: ${error.message}`);
    hilog.error(0x0001, TAG, `Name: ${error.name}`);
  }
  
  public static getRetryRecommendation(errorCode: number): string {
    switch (errorCode) {
      case 401:
        return '请检查参数后重试';
      case 1011:
        return '请检查设备支持情况后重试';
      case 1012:
        return '建议稍后重试';
      case 1013:
        return '建议稍后重试';
      default:
        return '请联系技术支持';
    }
  }
}