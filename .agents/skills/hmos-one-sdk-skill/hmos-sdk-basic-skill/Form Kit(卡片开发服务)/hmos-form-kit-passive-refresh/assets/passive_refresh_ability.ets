import { formBindingData, FormExtensionAbility, formProvider, formInfo } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want, Configuration } from '@kit.AbilityKit';

const TAG: string = 'PassiveRefreshFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;
const FIVE_MINUTE: number = 5;
const MAX_RETRY: number = 3;

export default class PassiveRefreshFormAbility extends FormExtensionAbility {
  private refreshCount: Map<string, number> = new Map();

  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, 'onAddForm called');
    
    let formId: string = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    this.refreshCount.set(formId, 0);
    
    let formData: Record<string, string> = {
      'title': '被动刷新卡片',
      'content': '初始内容',
      'refreshCount': '0',
      'lastUpdate': new Date().toLocaleTimeString()
    };
    
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onUpdateForm: formId=${formId}, wantParams=${JSON.stringify(wantParams)}`);
    
    let currentCount: number = this.refreshCount.get(formId) || 0;
    currentCount++;
    this.refreshCount.set(formId, currentCount);
    
    this.updateCardWithRetry(formId, currentCount, MAX_RETRY);
  }

  private updateCardWithRetry(formId: string, refreshCount: number, maxRetries: number): void {
    let retryCount: number = 0;
    
    const attemptUpdate = () => {
      try {
        let currentTime: string = new Date().toLocaleTimeString();
        
        let formData: Record<string, string> = {
          'title': '被动刷新卡片',
          'content': `第${refreshCount}次刷新`,
          'refreshCount': refreshCount.toString(),
          'lastUpdate': currentTime,
          'retryCount': retryCount.toString()
        };
        
        let bindingData = formBindingData.createFormBindingData(formData);
        
        formProvider.updateForm(formId, bindingData).then(() => {
          hilog.info(DOMAIN_NUMBER, TAG, 
            `卡片更新成功 (第${refreshCount}次刷新, 尝试次数${retryCount})`);
        }).catch((error: BusinessError) => {
          retryCount++;
          
          if (retryCount < maxRetries) {
            hilog.warn(DOMAIN_NUMBER, TAG, 
              `更新失败,重试中... (尝试${retryCount}/${maxRetries})`);
            setTimeout(attemptUpdate, 1000);
          } else {
            hilog.error(DOMAIN_NUMBER, TAG, 
              `更新失败,已达最大重试次数${maxRetries}`);
            this.handleUpdateError(error, formId, refreshCount);
          }
        });
        
      } catch (err) {
        retryCount++;
        if (retryCount < maxRetries) {
          setTimeout(attemptUpdate, 1000);
        } else {
          this.handleUpdateError(err as BusinessError, formId, refreshCount);
        }
      }
    };
    
    attemptUpdate();
  }

  private handleUpdateError(error: BusinessError, formId: string, refreshCount: number): void {
    hilog.error(DOMAIN_NUMBER, TAG, 
      `卡片更新错误: formId=${formId}, refreshCount=${refreshCount}, code=${error.code}`);
    
    switch (error.code) {
      case 401:
        hilog.error(DOMAIN_NUMBER, TAG, '参数错误');
        break;
        
      case 16500050:
        hilog.error(DOMAIN_NUMBER, TAG, 'IPC连接错误');
        this.useFallbackData(formId, refreshCount);
        break;
        
      case 16500060:
        hilog.error(DOMAIN_NUMBER, TAG, '服务连接错误');
        this.useFallbackData(formId, refreshCount);
        break;
        
      case 16500100:
        hilog.error(DOMAIN_NUMBER, TAG, '无法获取配置信息');
        break;
        
      case 16501000:
        hilog.error(DOMAIN_NUMBER, TAG, '内部功能错误');
        break;
        
      case 16501001:
        hilog.error(DOMAIN_NUMBER, TAG, '卡片ID不存在');
        this.refreshCount.delete(formId);
        break;
        
      case 16501002:
        hilog.error(DOMAIN_NUMBER, TAG, '卡片数量超过上限');
        break;
        
      case 16501003:
        hilog.error(DOMAIN_NUMBER, TAG, '当前应用无法操作此卡片');
        break;
        
      default:
        hilog.error(DOMAIN_NUMBER, TAG, `未知错误: ${error.message}`);
        this.useFallbackData(formId, refreshCount);
        break;
    }
  }

  private useFallbackData(formId: string, refreshCount: number): void {
    hilog.warn(DOMAIN_NUMBER, TAG, `使用降级数据: formId=${formId}`);
    
    try {
      let fallbackData: Record<string, string> = {
        'title': '被动刷新卡片',
        'content': '数据暂时不可用',
        'refreshCount': refreshCount.toString(),
        'lastUpdate': new Date().toLocaleTimeString(),
        'error': 'true'
      };
      
      let bindingData = formBindingData.createFormBindingData(fallbackData);
      formProvider.updateForm(formId, bindingData);
      
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `降级数据更新也失败: ${(err as BusinessError).message}`);
    }
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onFormEvent: formId=${formId}, message=${message}`);
    
    try {
      formProvider.setFormNextRefreshTime(formId, FIVE_MINUTE, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN_NUMBER, TAG, 
            `setFormNextRefreshTime失败: code=${err.code}, message=${err.message}`);
          return;
        }
        hilog.info(DOMAIN_NUMBER, TAG, 
          `setFormNextRefreshTime成功: ${FIVE_MINUTE}分钟后刷新`);
      });
      
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `setFormNextRefreshTime异常: ${(err as BusinessError).message}`);
    }
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm: formId=${formId}`);
    this.refreshCount.delete(formId);
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onCastToNormalForm: formId=${formId}`);
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onChangeFormVisibility: ${JSON.stringify(newStatus)}`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onConfigurationUpdate: ${JSON.stringify(newConfig)}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}