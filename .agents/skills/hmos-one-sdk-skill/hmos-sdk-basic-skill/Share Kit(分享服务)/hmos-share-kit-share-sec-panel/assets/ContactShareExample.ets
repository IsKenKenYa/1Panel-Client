import { Want, ShareExtensionAbility, UIExtensionContentSession } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

export default class ContactShareExample extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    console.info('[ContactShare] onSessionCreate called');
    
    systemShare.getContactInfo(want)
      .then(async (contact: systemShare.ContactInfo) => {
        console.info('[ContactShare] getContactInfo success');
        console.info(`[ContactShare] Contact type: ${contact.contactType}, ID: ${contact.contactId}`);
        
        const data: systemShare.SharedData = await systemShare.getSharedData(want);
        console.info('[ContactShare] getSharedData success, records count:', data.getRecords().length);
        
        const records: systemShare.SharedRecord[] = data.getRecords();
        
        const contactInfo = {
          type: contact.contactType,
          id: contact.contactId,
          isGroup: contact.contactType === 'ChatGroup'
        };
        
        records.forEach((record: systemShare.SharedRecord) => {
          this.shareToContact(record, contactInfo);
        });
        
        const storage: LocalStorage = new LocalStorage();
        storage.setOrCreate('contactInfo', contactInfo);
        storage.setOrCreate('shareData', data);
        storage.setOrCreate('session', session);
        
        session.loadContent('pages/ContactSharePage', storage);
      })
      .catch((error: BusinessError) => {
        console.error(`[ContactShare] getContactInfo failed. Code: ${error.code}, message: ${error.message}`);
        
        systemShare.getSharedData(want)
          .then((data: systemShare.SharedData) => {
            console.info('[ContactShare] Fallback: getSharedData success');
            
            const storage: LocalStorage = new LocalStorage();
            storage.setOrCreate('shareData', data);
            storage.setOrCreate('session', session);
            
            session.loadContent('pages/ShareDetailPage', storage);
          })
          .catch((fallbackError: BusinessError) => {
            console.error(`[ContactShare] Fallback failed. Code: ${fallbackError.code}`);
            session.terminateSelf();
          });
      });
  }
  
  private shareToContact(record: systemShare.SharedRecord, contactInfo: Record<string, string | boolean>): void {
    const contactId = contactInfo.id as string;
    const contactType = contactInfo.type as string;
    const isGroup = contactInfo.isGroup as boolean;
    
    console.info(`[ContactShare] Sharing to ${isGroup ? 'group' : 'contact'}: ${contactId}`);
    console.info(`[ContactShare] Record UTD: ${record.utd}`);
    
    if (record.utd === utd.UniformDataType.PLAIN_TEXT || 
        record.utd === utd.UniformDataType.TEXT) {
      this.sendTextToContact(contactId, contactType, record.content || '');
    } else if (record.utd === utd.UniformDataType.IMAGE ||
               record.utd === utd.UniformDataType.PNG ||
               record.utd === utd.UniformDataType.JPEG) {
      this.sendImageToContact(contactId, contactType, record.uri || '');
    } else if (record.utd === utd.UniformDataType.VIDEO) {
      this.sendVideoToContact(contactId, contactType, record.uri || '');
    }
  }
  
  private sendTextToContact(contactId: string, contactType: string, content: string): void {
    console.info(`[ContactShare] Sending text to ${contactType} ${contactId}: ${content}`);
  }
  
  private sendImageToContact(contactId: string, contactType: string, uri: string): void {
    console.info(`[ContactShare] Sending image to ${contactType} ${contactId}: ${uri}`);
  }
  
  private sendVideoToContact(contactId: string, contactType: string, uri: string): void {
    console.info(`[ContactShare] Sending video to ${contactType} ${contactId}: ${uri}`);
  }
  
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    console.info('[ContactShare] onCreate called');
  }
  
  onForeground(): void {
    console.info('[ContactShare] onForeground called');
  }
  
  onBackground(): void {
    console.info('[ContactShare] onBackground called');
  }
  
  onDestroy(): void {
    console.info('[ContactShare] onDestroy called');
  }
}