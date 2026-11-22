// entry/src/main/ets/jscardformability/JsCardFormAbility.ets
// FormExtensionAbility完整示例 - JS卡片生命周期管理

import { common, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';

const TAG: string = 'JsCardFormAbility';
const DATA_STORAGE_PATH: string = '/data/storage/el2/base/haps/form_store';
const DOMAIN_NUMBER: number = 0xFF00;

let fallbackStorage: Map<string, string> = new Map();

let storeFormInfo = async (formId: string, formName: string, tempFlag: boolean, context: common.FormExtensionContext): Promise<void> => {
  let formInfo: Record<string, string | boolean | number> = {
    'formName': formName,
    'tempFlag': tempFlag,
    'updateCount': 0
  };
  try {
    const storage: preferences.Preferences = await preferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.put(formId, JSON.stringify(formInfo));
    hilog.info(DOMAIN_NUMBER, TAG, `storeFormInfo success, formId: ${formId}`);
    await storage.flush();
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `storeFormInfo failed, using memory fallback, err: ${JSON.stringify(err as BusinessError)}`);
    fallbackStorage.set(formId, JSON.stringify(formInfo));
  }
}

let deleteFormInfo = async (formId: string, context: common.FormExtensionContext): Promise<void> => {
  try {
    const storage: preferences.Preferences = await preferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.delete(formId);
    hilog.info(DOMAIN_NUMBER, TAG, `deleteFormInfo success, formId: ${formId}`);
    await storage.flush();
    fallbackStorage.delete(formId);
  } catch (err) {
    hilog.error(DOMAIN_NUMBER, TAG, `deleteFormInfo failed, err: ${JSON.stringify(err as BusinessError)}`);
    fallbackStorage.delete(formId);
  }
};

let updateFormWithRetry = async (formId: string, formData: formBindingData.FormBindingData, maxRetries: number = 3): Promise<void> => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await formProvider.updateForm(formId, formData);
      hilog.info(DOMAIN_NUMBER, TAG, `updateForm success on attempt ${i + 1}`);
      return;
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed on attempt ${i + 1}, code: ${businessError.code}`);
      if (i === maxRetries - 1) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Max retries reached, update failed');
        throw businessError;
      }
    }
  }
}

export default class JsCardFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, '[JsCardFormAbility] onAddForm');
    
    if (want.parameters) {
      let formId = JSON.stringify(want.parameters['ohos.extra.param.key.form_identity']);
      let formName = JSON.stringify(want.parameters['ohos.extra.param.key.form_name']);
      let tempFlag = want.parameters['ohos.extra.param.key.form_temporary'] as boolean;
      
      storeFormInfo(formId, formName, tempFlag, this.context);
    }
    
    let obj: Record<string, string> = {
      'title': '卡片标题',
      'detail': '卡片详情',
      'temperature': '22°C',
      'time': new Date().toLocaleTimeString()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    return formData;
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[JsCardFormAbility] onRemoveForm, formId: ${formId}`);
    deleteFormInfo(formId, this.context);
  }

  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[JsCardFormAbility] onUpdateForm, formId: ${formId}`);
    
    let obj: Record<string, string> = {
      'title': '更新标题',
      'detail': '更新详情',
      'temperature': '25°C',
      'time': new Date().toLocaleTimeString()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    
    updateFormWithRetry(formId, formData).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Final update failed, code: ${error.code}, message: ${error.message}`);
    });
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[JsCardFormAbility] onCastToNormalForm, formId: ${formId}`);
    
    try {
      let formInfoStr = fallbackStorage.get(formId);
      if (formInfoStr) {
        let formInfo: Record<string, string | boolean | number> = JSON.parse(formInfoStr);
        formInfo.tempFlag = false;
        
        const storage: preferences.Preferences = await preferences.getPreferences(this.context, DATA_STORAGE_PATH);
        await storage.put(formId, JSON.stringify(formInfo));
        await storage.flush();
        fallbackStorage.delete(formId);
        
        hilog.info(DOMAIN_NUMBER, TAG, `Convert temporary form to normal form success, formId: ${formId}`);
      }
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, `onCastToNormalForm failed, err: ${JSON.stringify(err as BusinessError)}`);
    }
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[JsCardFormAbility] onFormEvent, formId: ${formId}, message: ${message}`);
    
    try {
      let msg: Record<string, string> = JSON.parse(message);
      
      if (msg.action === 'refresh') {
        this.onUpdateForm(formId);
      } else if (msg.action === 'detail') {
        hilog.info(DOMAIN_NUMBER, TAG, `Detail action triggered, detail: ${msg.detail}`);
      } else {
        hilog.warn(DOMAIN_NUMBER, TAG, `Unknown action: ${msg.action}`);
      }
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, `Parse message failed, err: ${JSON.stringify(err as BusinessError)}`);
    }
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[JsCardFormAbility] onChangeFormVisibility`);
    
    let keys: string[] = Object.keys(newStatus);
    for (let i = 0; i < keys.length; i++) {
      let formId = keys[i];
      let visibility = newStatus[formId];
      
      hilog.info(DOMAIN_NUMBER, TAG, `Form visibility changed, formId: ${formId}, visibility: ${visibility}`);
      
      let obj: Record<string, string> = {
        'visibility': visibility.toString()
      };
      let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
      
      formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, `Update form visibility failed, formId: ${formId}, code: ${error.code}`);
      });
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[JsCardFormAbility] onConfigurationUpdate, language: ${newConfig?.language}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    hilog.info(DOMAIN_NUMBER, TAG, `[JsCardFormAbility] onAcquireFormState`);
    return formInfo.FormState.READY;
  }
}