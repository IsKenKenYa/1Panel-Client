import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ResultHandling';

export interface LoadServiceResult {
  success: boolean;
  resultCode: number;
  message: string;
  formInfo?: {
    bundleName: string;
    name: string;
    abilityName: string;
    moduleName: string;
    defaultDimension: string;
  };
}

export class ResultHandler {
  public static handleReceiveData(data: productViewManager.ServiceViewReceiveData): LoadServiceResult {
    hilog.info(0x0001, TAG, `Processing receive data`);
    hilog.info(0x0001, TAG, `Result: ${data.result}, Message: ${data.msg}`);
    
    const result: LoadServiceResult = {
      success: false,
      resultCode: data.result,
      message: data.msg
    };
    
    switch (data.result) {
      case productViewManager.ReceiveDataResult.SUCCESS:
        result.success = true;
        hilog.info(0x0001, TAG, 'Load service succeeded');
        this.processFormInfo(data.formInfo, result);
        break;
        
      case productViewManager.ReceiveDataResult.FAILURE:
        result.success = false;
        hilog.warn(0x0001, TAG, 'Load service failed');
        this.processFailure(data.msg);
        break;
        
      case productViewManager.ReceiveDataResult.EXCEPTION:
        result.success = false;
        hilog.error(0x0001, TAG, 'Load service exception occurred');
        this.processException(data.msg);
        break;
        
      default:
        result.success = false;
        hilog.warn(0x0001, TAG, `Unknown result code: ${data.result}`);
        this.processUnknownResult(data.result, data.msg);
    }
    
    return result;
  }
  
  private static processFormInfo(formInfo: {[key: string]: Object}, result: LoadServiceResult): void {
    hilog.info(0x0001, TAG, 'Processing form info');
    
    if (!formInfo) {
      hilog.warn(0x0001, TAG, 'Form info is null or undefined');
      return;
    }
    
    try {
      result.formInfo = {
        bundleName: String(formInfo.bundleName || ''),
        name: String(formInfo.name || ''),
        abilityName: String(formInfo.abilityName || ''),
        moduleName: String(formInfo.moduleName || ''),
        defaultDimension: String(formInfo.defaultDimension || '')
      };
      
      hilog.info(0x0001, TAG, `Bundle name: ${result.formInfo.bundleName}`);
      hilog.info(0x0001, TAG, `Card name: ${result.formInfo.name}`);
      hilog.info(0x0001, TAG, `Ability name: ${result.formInfo.abilityName}`);
      hilog.info(0x0001, TAG, `Module name: ${result.formInfo.moduleName}`);
      hilog.info(0x0001, TAG, `Default dimension: ${result.formInfo.defaultDimension}`);
      
    } catch (err) {
      hilog.error(0x0001, TAG, 'Failed to parse form info');
    }
  }
  
  private static processFailure(message: string): void {
    hilog.warn(0x0001, TAG, `Failure reason: ${message}`);
    hilog.warn(0x0001, TAG, 'Suggested actions:');
    hilog.warn(0x0001, TAG, '- Check if the meta-service is valid');
    hilog.warn(0x0001, TAG, '- Verify user permissions');
    hilog.warn(0x0001, TAG, '- Ensure device compatibility');
  }
  
  private static processException(message: string): void {
    hilog.error(0x0001, TAG, `Exception details: ${message}`);
    hilog.error(0x0001, TAG, 'Suggested actions:');
    hilog.error(0x0001, TAG, '- Check system logs for more details');
    hilog.error(0x0001, TAG, '- Contact technical support');
    hilog.error(0x0001, TAG, '- Try restarting the application');
  }
  
  private static processUnknownResult(resultCode: number, message: string): void {
    hilog.warn(0x0001, TAG, `Unknown result: ${resultCode}`);
    hilog.warn(0x0001, TAG, `Message: ${message}`);
    hilog.warn(0x0001, TAG, 'Suggested actions:');
    hilog.warn(0x0001, TAG, '- Report this issue to developers');
    hilog.warn(0x0001, TAG, '- Check API documentation for updates');
  }
  
  public static getResultMessage(resultCode: number): string {
    switch (resultCode) {
      case productViewManager.ReceiveDataResult.SUCCESS:
        return '加桌成功';
      case productViewManager.ReceiveDataResult.FAILURE:
        return '加桌失败';
      case productViewManager.ReceiveDataResult.EXCEPTION:
        return '加桌异常';
      default:
        return '未知结果';
    }
  }
}