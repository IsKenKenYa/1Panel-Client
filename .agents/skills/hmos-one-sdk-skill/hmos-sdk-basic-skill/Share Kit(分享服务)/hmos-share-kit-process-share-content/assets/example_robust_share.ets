import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class RobustShareAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('RobustShareAbility onCreate');
    this.handleShareWithFallback(want);
  }
  
  private async handleShareWithFallback(want: Want): Promise<void> {
    try {
      console.info('Attempting to parse share data');
      
      const data = await systemShare.getSharedData(want);
      const records = data.getRecords();
      
      console.info(`Data parsed successfully. Record count: ${records.length}`);
      
      if (records.length === 0) {
        console.warn('No share records found');
        this.showToast('未收到分享内容');
        this.context.terminateSelf();
        return;
      }
      
      if (records.length > 100) {
        console.warn(`Too many records: ${records.length}. Processing first 100 only`);
        this.showToast(`收到${records.length}条分享，仅处理前100条`);
        await this.processFirstNRecords(records, 100);
      } else {
        console.info(`Processing all ${records.length} records`);
        await this.processAllRecords(records);
      }
      
      console.info('Share processing completed successfully');
      
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`Share processing error. Code: ${businessError.code}, Message: ${businessError.message}`);
      this.handleShareError(businessError);
    }
  }
  
  private handleShareError(error: BusinessError): void {
    let errorMessage: string;
    
    switch (error.code) {
      case 401:
        console.error('Parameter error: Invalid Want format');
        errorMessage = '分享数据格式错误';
        break;
        
      case 1003703001:
        console.error('Parse data failed: Cannot extract share data from Want');
        errorMessage = '无法解析分享数据';
        break;
        
      case 1003700001:
        console.error('Record count exceeds maximum limit');
        errorMessage = '分享内容过多，请减少分享数量';
        break;
        
      case 1003702002:
        console.error('IPC data size exceeds limit');
        errorMessage = '分享数据过大，请压缩后重新分享';
        break;
        
      default:
        console.error(`Unknown error code: ${error.code}`);
        errorMessage = `处理分享失败: ${error.message}`;
    }
    
    this.showToast(errorMessage);
    
    setTimeout(() => {
      this.context.terminateSelf();
    }, 2000);
  }
  
  private showToast(message: string): void {
    console.info(`[Toast Message]: ${message}`);
  }
  
  private async processFirstNRecords(
    records: systemShare.SharedRecord[], 
    max: number
  ): Promise<void> {
    const subset = records.slice(0, max);
    console.info(`Processing first ${subset.length} records`);
    
    await this.processAllRecords(subset);
  }
  
  private async processAllRecords(records: systemShare.SharedRecord[]): Promise<void> {
    let successCount = 0;
    let failureCount = 0;
    
    for (const record of records) {
      try {
        await this.processShareRecordAsync(record);
        successCount++;
        console.info(`Record ${successCount} processed successfully: ${record.utd}`);
      } catch (error) {
        failureCount++;
        console.warn(`Record ${failureCount} failed: ${record.utd}. Error: ${(error as Error).message}`);
      }
    }
    
    console.info(`Processing summary: Success=${successCount}, Failure=${failureCount}`);
    
    if (failureCount > 0) {
      this.showToast(`处理完成: ${successCount}成功, ${failureCount}失败`);
    } else {
      this.showToast(`处理完成: ${successCount}条记录`);
    }
  }
  
  private async processShareRecordAsync(record: systemShare.SharedRecord): Promise<void> {
    return new Promise((resolve, reject) => {
      console.info(`Processing record details:`);
      console.info(`  UTD: ${record.utd}`);
      console.info(`  Title: ${record.title || 'N/A'}`);
      
      if (!record.utd) {
        reject(new Error('Missing UTD type'));
        return;
      }
      
      if (record.content) {
        console.info(`  Content length: ${record.content.length}`);
      }
      
      if (record.uri) {
        console.info(`  URI: ${record.uri}`);
      }
      
      setTimeout(() => {
        if (record.content && record.content.length > 10000) {
          reject(new Error('Content too large'));
        } else {
          resolve();
        }
      }, 50);
    });
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('RobustShareAbility onNewWant');
    this.handleShareWithFallback(want);
  }
  
  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('RobustShareAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        console.error(`Failed to load content. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      console.info('Succeeded in loading content');
    });
  }
  
  onForeground(): void {
    console.info('RobustShareAbility onForeground');
  }
  
  onBackground(): void {
    console.info('RobustShareAbility onBackground');
  }
  
  onDestroy(): void {
    console.info('RobustShareAbility onDestroy');
  }
}