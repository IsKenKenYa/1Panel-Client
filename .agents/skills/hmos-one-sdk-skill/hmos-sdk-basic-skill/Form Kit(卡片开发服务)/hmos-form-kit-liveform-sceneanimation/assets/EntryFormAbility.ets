import { FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'EntryFormAbility';
const DOMAIN_NUMBER = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  async onFormEvent(formId: string, message: string) {
    let shortMessage: string = JSON.parse(message)['message'];
    
    if (shortMessage === 'requestOverflow') {
      try {
        let formRect: formInfo.Rect = await formProvider.getFormRect(formId);
        this.requestOverflow(formId, formRect.width, formRect.height);
      } catch (error) {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `getFormRect failed, code: ${(error as BusinessError).code}`);
      }
      return;
    }
  }
  
  private requestOverflow(formId: string, formWidth: number, formHeight: number): void {
    if (formWidth <= 0 || formHeight <= 0) {
      hilog.info(DOMAIN_NUMBER, TAG, 'form size is not correct.');
      return;
    }
    
    let left: number = -0.1 * formWidth;
    let top: number = -0.15 * formHeight;
    let width: number = 1.2 * formWidth;
    let height: number = 1.3 * formHeight;
    let duration: number = 3500;
    
    try {
      formProvider.requestOverflow(formId, {
        area: {
          left: left,
          top: top,
          width: width,
          height: height
        },
        duration: duration,
        useDefaultAnimation: true,
      }).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, 'requestOverflow succeed');
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `requestOverflow failed, code: ${error.code}, message: ${error.message}`);
      });
    } catch (e) {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `requestOverflow failed, code: ${e.code}, message: ${e.message}`);
    }
  }
}