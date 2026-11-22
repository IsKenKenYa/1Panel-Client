import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class BasicShareAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('BasicShareAbility onCreate');
    
    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        const records = data.getRecords();
        console.info(`Received ${records.length} share records`);
        
        records.forEach((record: systemShare.SharedRecord) => {
          this.processShareRecord(record);
        });
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getSharedData. Code: ${error.code}, message: ${error.message}`);
        this.context.terminateSelf();
      });
  }
  
  private processShareRecord(record: systemShare.SharedRecord): void {
    console.info(`Processing record:`);
    console.info(`  UTD: ${record.utd}`);
    console.info(`  Title: ${record.title}`);
    console.info(`  Label: ${record.label}`);
    console.info(`  Description: ${record.description}`);
    
    if (record.content) {
      console.info(`  Content: ${record.content}`);
    }
    
    if (record.uri) {
      console.info(`  URI: ${record.uri}`);
    }
    
    if (record.thumbnail) {
      console.info(`  Thumbnail size: ${record.thumbnail.length} bytes`);
    }
    
    if (record.thumbnailUri) {
      console.info(`  Thumbnail URI: ${record.thumbnailUri}`);
    }
    
    if (record.extraData) {
      console.info(`  ExtraData: ${JSON.stringify(record.extraData)}`);
    }
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('BasicShareAbility onNewWant');
    this.onCreate(want, launchParam);
  }
  
  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('BasicShareAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        console.error(`Failed to load content. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      console.info('Succeeded in loading content');
    });
  }
  
  onForeground(): void {
    console.info('BasicShareAbility onForeground');
  }
  
  onBackground(): void {
    console.info('BasicShareAbility onBackground');
  }
  
  onDestroy(): void {
    console.info('BasicShareAbility onDestroy');
  }
}