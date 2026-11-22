import { Want, ShareExtensionAbility, UIExtensionContentSession } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

export default class ShareExtensionAbilityExample extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    console.info('[ShareExtAbility] onSessionCreate called');
    
    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        console.info('[ShareExtAbility] getSharedData success, records count:', data.getRecords().length);
        
        const records: systemShare.SharedRecord[] = data.getRecords();
        if (records.length === 0) {
          console.warn('[ShareExtAbility] No share data received');
          session.terminateSelf();
          return;
        }
        
        records.forEach((record: systemShare.SharedRecord, index: number) => {
          console.info(`[ShareExtAbility] Record ${index}: UTD=${record.utd}`);
          
          if (record.utd === utd.UniformDataType.PLAIN_TEXT || 
              record.utd === utd.UniformDataType.TEXT) {
            this.processTextShare(record);
          } else if (record.utd === utd.UniformDataType.IMAGE ||
                     record.utd === utd.UniformDataType.PNG ||
                     record.utd === utd.UniformDataType.JPEG) {
            this.processImageShare(record);
          } else if (record.utd === utd.UniformDataType.VIDEO) {
            this.processVideoShare(record);
          } else if (record.utd === utd.UniformDataType.FILE) {
            this.processFileShare(record);
          } else {
            console.warn(`[ShareExtAbility] Unsupported UTD type: ${record.utd}`);
          }
        });
        
        const storage: LocalStorage = new LocalStorage();
        storage.setOrCreate('shareData', data);
        storage.setOrCreate('session', session);
        
        session.loadContent('pages/ShareDetailPage', storage);
      })
      .catch((error: BusinessError) => {
        console.error(`[ShareExtAbility] getSharedData failed. Code: ${error.code}, message: ${error.message}`);
        session.terminateSelf();
      });
  }
  
  private processTextShare(record: systemShare.SharedRecord): void {
    const textContent: string = record.content || '';
    const title: string = record.title || 'Untitled';
    
    console.info(`[ShareExtAbility] Text share - Title: ${title}, Content: ${textContent}`);
    
    this.saveSharedContent({
      type: 'text',
      title: title,
      content: textContent,
      timestamp: Date.now()
    });
  }
  
  private processImageShare(record: systemShare.SharedRecord): void {
    const imageUri: string = record.uri || '';
    const title: string = record.title || 'Untitled Image';
    
    console.info(`[ShareExtAbility] Image share - Title: ${title}, URI: ${imageUri}`);
    
    this.saveSharedContent({
      type: 'image',
      title: title,
      uri: imageUri,
      timestamp: Date.now()
    });
  }
  
  private processVideoShare(record: systemShare.SharedRecord): void {
    const videoUri: string = record.uri || '';
    const title: string = record.title || 'Untitled Video';
    
    console.info(`[ShareExtAbility] Video share - Title: ${title}, URI: ${videoUri}`);
    
    this.saveSharedContent({
      type: 'video',
      title: title,
      uri: videoUri,
      timestamp: Date.now()
    });
  }
  
  private processFileShare(record: systemShare.SharedRecord): void {
    const fileUri: string = record.uri || '';
    const title: string = record.title || 'Untitled File';
    
    console.info(`[ShareExtAbility] File share - Title: ${title}, URI: ${fileUri}`);
    
    this.saveSharedContent({
      type: 'file',
      title: title,
      uri: fileUri,
      timestamp: Date.now()
    });
  }
  
  private saveSharedContent(contentData: Record<string, string | number>): void {
    console.info('[ShareExtAbility] Saving shared content:', JSON.stringify(contentData));
  }
  
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    console.info('[ShareExtAbility] onCreate called');
  }
  
  onForeground(): void {
    console.info('[ShareExtAbility] onForeground called');
  }
  
  onBackground(): void {
    console.info('[ShareExtAbility] onBackground called');
  }
  
  onDestroy(): void {
    console.info('[ShareExtAbility] onDestroy called');
  }
}