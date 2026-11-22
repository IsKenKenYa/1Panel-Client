import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';

const TAG: string = 'TimedRefreshFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class TimedRefreshFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, 'onAddForm called');
    
    let formData: Record<string, string> = {
      'title': '定时刷新卡片',
      'content': '初始内容',
      'lastUpdate': '首次创建'
    };
    
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onUpdateForm: formId=${formId}`);
    
    try {
      let currentTime: string = new Date().toLocaleTimeString();
      
      let formData: Record<string, string> = {
        'title': '定时刷新卡片',
        'content': `定时更新内容 - ${currentTime}`,
        'lastUpdate': currentTime
      };
      
      let bindingData = formBindingData.createFormBindingData(formData);
      
      formProvider.updateForm(formId, bindingData).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, '定时刷新成功');
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `定时刷新失败: code=${error.code}, message=${error.message}`);
      });
      
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `定时刷新异常: ${(err as BusinessError).message}`);
    }
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm: formId=${formId}`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onConfigurationUpdate: ${JSON.stringify(newConfig)}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}