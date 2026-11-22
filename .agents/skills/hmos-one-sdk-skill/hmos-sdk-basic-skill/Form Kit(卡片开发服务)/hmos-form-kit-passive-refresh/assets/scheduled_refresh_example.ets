import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';

const TAG: string = 'ScheduledRefreshFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class ScheduledRefreshFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, 'onAddForm called');
    
    let formData: Record<string, string> = {
      'title': '定点刷新卡片',
      'content': '初始内容',
      'scheduledTime': want.parameters?.['ohos.extra.param.key.form_schedule_update_time'] || '未配置'
    };
    
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onUpdateForm: formId=${formId}, scheduledTime trigger`);
    
    try {
      let currentTime: string = new Date().toLocaleTimeString();
      let scheduledTime: string = this.getScheduledTime(formId);
      
      let formData: Record<string, string> = {
        'title': '定点刷新卡片',
        'content': `定点更新内容 (${scheduledTime})`,
        'lastUpdate': currentTime,
        'scheduledTime': scheduledTime
      };
      
      let bindingData = formBindingData.createFormBindingData(formData);
      
      formProvider.updateForm(formId, bindingData).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, `定点刷新成功 (预定时间: ${scheduledTime})`);
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `定点刷新失败: code=${error.code}, message=${error.message}`);
      });
      
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `定点刷新异常: ${(err as BusinessError).message}`);
    }
  }

  private getScheduledTime(formId: string): string {
    return '10:30';
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm: formId=${formId}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}