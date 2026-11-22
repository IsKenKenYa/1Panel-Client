import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class ContactShareAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('ContactShareAbility onCreate');
    
    systemShare.getContactInfo(want)
      .then(async (contact: systemShare.ContactInfo) => {
        console.info(`Contact info retrieved:`);
        console.info(`  Type: ${contact.contactType}`);
        console.info(`  ID: ${contact.contactId}`);
        
        const data = await systemShare.getSharedData(want);
        const records = data.getRecords();
        
        await this.shareToContact(contact, records);
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getContactInfo. Code: ${error.code}, message: ${error.message}`);
        console.warn('Contact info not available, processing share without contact');
        this.handleShareWithoutContact(want);
      });
  }
  
  private async shareToContact(
    contact: systemShare.ContactInfo, 
    records: systemShare.SharedRecord[]
  ): Promise<void> {
    console.info(`Sharing ${records.length} items to contact ${contact.contactId}`);
    
    for (const record of records) {
      console.info(`  Sharing record: ${record.utd} to contact type: ${contact.contactType}`);
      
      if (contact.contactType === 'Contact') {
        await this.shareToSingleContact(contact.contactId, record);
      } else if (contact.contactType === 'ChatGroup') {
        await this.shareToChatGroup(contact.contactId, record);
      }
    }
    
    console.info('Share to contact completed');
  }
  
  private async shareToSingleContact(contactId: string, record: systemShare.SharedRecord): Promise<void> {
    console.info(`Sharing to single contact: ${contactId}`);
    
    if (record.content) {
      console.info(`  Content: ${record.content}`);
    }
    
    if (record.uri) {
      console.info(`  URI: ${record.uri}`);
    }
  }
  
  private async shareToChatGroup(groupId: string, record: systemShare.SharedRecord): Promise<void> {
    console.info(`Sharing to chat group: ${groupId}`);
    
    if (record.content) {
      console.info(`  Content: ${record.content}`);
    }
    
    if (record.uri) {
      console.info(`  URI: ${record.uri}`);
    }
  }
  
  private async handleShareWithoutContact(want: Want): Promise<void> {
    try {
      const data = await systemShare.getSharedData(want);
      const records = data.getRecords();
      
      console.info(`Processing ${records.length} records without contact info`);
      
      for (const record of records) {
        await this.processShareRecord(record);
      }
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`Failed to handle share without contact. Code: ${businessError.code}`);
      this.context.terminateSelf();
    }
  }
  
  private async processShareRecord(record: systemShare.SharedRecord): Promise<void> {
    console.info(`Processing record: ${record.utd}`);
    return new Promise((resolve) => {
      setTimeout(() => {
        console.info(`  Record processed`);
        resolve();
      }, 100);
    });
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('ContactShareAbility onNewWant');
    this.onCreate(want, launchParam);
  }
  
  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('ContactShareAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        console.error(`Failed to load content. Code: ${error.code}`);
        return;
      }
      console.info('Succeeded in loading content');
    });
  }
  
  onForeground(): void {
    console.info('ContactShareAbility onForeground');
  }
  
  onBackground(): void {
    console.info('ContactShareAbility onBackground');
  }
  
  onDestroy(): void {
    console.info('ContactShareAbility onDestroy');
  }
}