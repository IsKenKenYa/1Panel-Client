import { formInfo, LiveFormInfo, LiveFormExtensionAbility } from '@kit.FormKit';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'MyLiveFormExtensionAbility';

export default class MyLiveFormExtensionAbility extends LiveFormExtensionAbility {
  onLiveFormCreate(liveFormInfo: LiveFormInfo, session: UIExtensionContentSession) {
    hilog.info(DOMAIN, TAG, `onLiveFormCreate, formId: ${liveFormInfo.formId}`);
    
    let storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('context', this.context);
    storage.setOrCreate('session', session);
    storage.setOrCreate('formId', liveFormInfo.formId);
    storage.setOrCreate('borderRadius', liveFormInfo.borderRadius);
    storage.setOrCreate('formRect', liveFormInfo.rect);
    
    hilog.info(DOMAIN, TAG, `borderRadius: ${liveFormInfo.borderRadius}, formRect: ${JSON.stringify(liveFormInfo.rect)}`);
    
    session.loadContent('myliveformextensionability/pages/MyLiveFormPage', storage);
  }
  
  onLiveFormDestroy(liveFormInfo: LiveFormInfo) {
    hilog.info(DOMAIN, TAG, `onLiveFormDestroy, formId: ${liveFormInfo.formId}`);
  }
}