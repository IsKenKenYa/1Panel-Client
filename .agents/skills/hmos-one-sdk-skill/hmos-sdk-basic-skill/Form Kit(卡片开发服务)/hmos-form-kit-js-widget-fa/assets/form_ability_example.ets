import type featureAbility from '@ohos.ability.featureAbility';
import type Want from '@ohos.app.ability.Want';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import formProvider from '@ohos.app.form.formProvider';
import dataPreferences from '@ohos.data.preferences';
import hilog from '@ohos.hilog';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = '[FormAbilityExample]';
const domain: number = 0xFF00;
const DATA_STORAGE_PATH: string = 'form_store';

class LifeCycle {
  onCreate: (want: Want) => formBindingData.FormBindingData = (want) => ({ data: '' });
  onCastToNormal: (formId: string) => void = (formId) => {};
  onUpdate: (formId: string) => void = (formId) => {};
  onVisibilityChange: (newStatus: Record<string, number>) => void = (newStatus) => {};
  onEvent: (formId: string, message: string) => void = (formId, message) => {};
  onDestroy: (formId: string) => void = (formId) => {};
  onAcquireFormState?: (want: Want) => formInfo.FormState = (want) => (0);
  onShareForm?: (formId: string) => Record<string, Object> = (formId) => {
    let obj: Record<string, number> = {
      'test': 1
    };
    return obj;
  };
}

async function storeFormInfo(formId: string, formName: string, tempFlag: boolean, context: featureAbility.Context): Promise<void> {
  let formInfo: Record<string, string | number | boolean> = {
    'formName': formName,
    'tempFlag': tempFlag,
    'updateCount': 0,
    'createTime': Date.now()
  };
  
  try {
    const storage = await dataPreferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.put(formId, JSON.stringify(formInfo));
    hilog.info(domain, TAG, `storeFormInfo success, formId: ${formId}, formName: ${formName}`);
    await storage.flush();
  } catch (err) {
    hilog.error(domain, TAG, `storeFormInfo failed, err: ${JSON.stringify(err as Error)}`);
  }
}

async function deleteFormInfo(formId: string, context: featureAbility.Context): Promise<void> {
  try {
    const storage = await dataPreferences.getPreferences(context, DATA_STORAGE_PATH);
    await storage.delete(formId);
    hilog.info(domain, TAG, `deleteFormInfo success, formId: ${formId}`);
    await storage.flush();
  } catch (err) {
    hilog.error(domain, TAG, `deleteFormInfo failed, err: ${JSON.stringify(err)}`);
  }
}

async function updateFormCount(formId: string, context: featureAbility.Context): Promise<void> {
  try {
    const storage = await dataPreferences.getPreferences(context, DATA_STORAGE_PATH);
    let formInfoStr = await storage.get(formId, '') as string;
    if (formInfoStr) {
      let formInfo = JSON.parse(formInfoStr);
      formInfo.updateCount = (formInfo.updateCount || 0) + 1;
      await storage.put(formId, JSON.stringify(formInfo));
      await storage.flush();
      hilog.info(domain, TAG, `updateFormCount success, formId: ${formId}, count: ${formInfo.updateCount}`);
    }
  } catch (err) {
    hilog.error(domain, TAG, `updateFormCount failed, err: ${JSON.stringify(err)}`);
  }
}

let formAbilityObj: LifeCycle = {
  onCreate(want: Want) {
    hilog.info(domain, TAG, 'FormAbility onCreate');
    
    if (want.parameters) {
      let formId = String(want.parameters['ohos.extra.param.key.form_identity']);
      let formName = String(want.parameters['ohos.extra.param.key.form_name']);
      let tempFlag = Boolean(want.parameters['ohos.extra.param.key.form_temporary']);
      
      hilog.info(domain, TAG, `formId: ${formId}, formName: ${formName}, tempFlag: ${tempFlag}`);
      
      storeFormInfo(formId, formName, tempFlag, this.context);
    }
    
    let data: Record<string, string> = {
      'title': '天气预报',
      'detail': '温度: 26°C',
      'updateTime': new Date().toLocaleTimeString()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(data);
    hilog.info(domain, TAG, 'FormAbility onCreate completed');
    
    return formData;
  },
  
  onCastToNormal(formId: string) {
    hilog.info(domain, TAG, `FormAbility onCastToNormal, formId: ${formId}`);
  },
  
  onUpdate(formId: string) {
    hilog.info(domain, TAG, `FormAbility onUpdate, formId: ${formId}`);
    
    updateFormCount(formId, this.context);
    
    let data: Record<string, string> = {
      'title': '天气预报(更新)',
      'detail': '温度: 28°C',
      'updateTime': new Date().toLocaleTimeString()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(data);
    
    formProvider.updateForm(formId, formData).then(() => {
      hilog.info(domain, TAG, `updateForm success, formId: ${formId}`);
    }).catch((error: BusinessError) => {
      hilog.error(domain, TAG, `updateForm failed, code: ${error.code}, message: ${error.message}`);
      
      switch (error.code) {
        case 16501000:
          hilog.error(domain, TAG, 'Internal functional error');
          break;
        case 16501001:
          hilog.error(domain, TAG, 'Form ID does not exist');
          break;
        case 16501003:
          hilog.error(domain, TAG, 'Cannot operate this form');
          break;
        default:
          hilog.error(domain, TAG, 'Unknown error');
      }
    });
  },
  
  onVisibilityChange(newStatus: Record<string, number>) {
    hilog.info(domain, TAG, `FormAbility onVisibilityChange, newStatus: ${JSON.stringify(newStatus)}`);
  },
  
  onEvent(formId: string, message: string) {
    hilog.info(domain, TAG, `FormAbility onEvent, formId: ${formId}, message: ${message}`);
    
    let messageObj = JSON.parse(message);
    hilog.info(domain, TAG, `Event message: ${JSON.stringify(messageObj)}`);
    
    let data: Record<string, string> = {
      'title': '事件触发',
      'detail': `消息: ${messageObj.message || '无'}`,
      'updateTime': new Date().toLocaleTimeString()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(data);
    
    formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
      hilog.error(domain, TAG, `updateForm failed in onEvent, code: ${error.code}, message: ${error.message}`);
    });
  },
  
  onDestroy(formId: string) {
    hilog.info(domain, TAG, `FormAbility onDestroy, formId: ${formId}`);
    deleteFormInfo(formId, this.context);
  },
  
  onAcquireFormState(want: Want) {
    hilog.info(domain, TAG, 'FormAbility onAcquireFormState');
    return formInfo.FormState.READY;
  }
};

export default formAbilityObj;