import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'UpdateByStatusFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class UpdateByStatusFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    let formId: string = '';
    if (want.parameters) {
      formId = want.parameters[formInfo.FormParam.IDENTITY_KEY].toString();
      let promise: Promise<preferences.Preferences> = preferences.getPreferences(this.context, 'myStore');
      promise.then(async (storeDB: preferences.Preferences) => {
        hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences.');
        await storeDB.put('A' + formId, 'false');
        await storeDB.put('B' + formId, 'false');
        await storeDB.flush();
      }).catch((err: BusinessError) => {
        hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
      });
    }
    let formData: Record<string, Object | string> = {};
    return formBindingData.createFormBindingData(formData);
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onRemoveForm, formId:' + formId);
    let promise = preferences.getPreferences(this.context, 'myStore');
    promise.then(async (storeDB) => {
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences.');
      await storeDB.delete('A' + formId);
      await storeDB.delete('B' + formId);
    }).catch((err: BusinessError) => {
      hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
    });
  }

  onCastToNormalForm(formId: string): void {
  }

  onUpdateForm(formId: string): void {
    let promise: Promise<preferences.Preferences> = preferences.getPreferences(this.context, 'myStore');
    promise.then(async (storeDB: preferences.Preferences) => {
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences from onUpdateForm.');
      let stateA = await storeDB.get('A' + formId, 'false');
      let stateB = await storeDB.get('B' + formId, 'false');
      
      if (stateA === 'true') {
        let param: Record<string, string> = {
          'textA': 'AAA'
        };
        let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
        await formProvider.updateForm(formId, formInfo);
      }
      
      if (stateB === 'true') {
        let param: Record<string, string> = {
          'textB': 'BBB'
        };
        let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
        await formProvider.updateForm(formId, formInfo);
      }
      
      hilog.info(DOMAIN_NUMBER, TAG, `Update form success stateA:${stateA} stateB:${stateB}.`);
    }).catch((err: BusinessError) => {
      hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
    });
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onFormEvent formId:' + formId + 'msg:' + message);
    let promise: Promise<preferences.Preferences> = preferences.getPreferences(this.context, 'myStore');
    promise.then(async (storeDB: preferences.Preferences) => {
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded to get preferences.');
      let msg: Record<string, string> = JSON.parse(message);
      if (msg.selectA !== undefined) {
        hilog.info(DOMAIN_NUMBER, TAG, 'onFormEvent selectA info:' + msg.selectA);
        await storeDB.put('A' + formId, msg.selectA);
      }
      if (msg.selectB !== undefined) {
        hilog.info(DOMAIN_NUMBER, TAG, 'onFormEvent selectB info:' + msg.selectB);
        await storeDB.put('B' + formId, msg.selectB);
      }
      await storeDB.flush();
    }).catch((err: BusinessError) => {
      hilog.info(DOMAIN_NUMBER, TAG, `Failed to get preferences. ${JSON.stringify(err)}`);
    });
  }
}