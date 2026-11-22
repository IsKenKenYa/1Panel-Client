import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';

const TAG: string = 'NetworkRefreshFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class NetworkRefreshFormAbility extends FormExtensionAbility {
  private networkStatus: boolean = false;

  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, 'onAddForm called');
    
    this.networkStatus = this.checkNetworkStatus();
    
    let formData: Record<string, string> = {
      'title': '网络条件刷新卡片',
      'content': '初始内容',
      'networkStatus': this.networkStatus ? '已连接' : '未连接',
      'triggerType': '初始创建'
    };
    
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onUpdateForm: formId=${formId}`);
    
    let triggerReason: string = '网络状态变化';
    
    if (wantParams && wantParams['conditionUpdate']) {
      triggerReason = `条件刷新: ${wantParams['conditionUpdate']}`;
    }
    
    try {
      let currentTime: string = new Date().toLocaleTimeString();
      this.networkStatus = this.checkNetworkStatus();
      
      let formData: Record<string, string> = {
        'title': '网络条件刷新卡片',
        'content': `网络恢复后更新 - ${currentTime}`,
        'networkStatus': this.networkStatus ? '已连接' : '未连接',
        'lastUpdate': currentTime,
        'triggerType': triggerReason
      };
      
      let bindingData = formBindingData.createFormBindingData(formData);
      
      formProvider.updateForm(formId, bindingData).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, `网络条件刷新成功: ${triggerReason}`);
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, 
          `网络条件刷新失败: code=${error.code}, message=${error.message}`);
      });
      
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `网络条件刷新异常: ${(err as BusinessError).message}`);
    }
  }

  private checkNetworkStatus(): boolean {
    return true;
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm: formId=${formId}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}