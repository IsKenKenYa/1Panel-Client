// entry/src/main/ets/entryformability/EntryFormAbility.ts
// FormExtensionAbility完整示例：接收message事件并刷新卡片

import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Configuration, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  // 卡片创建时回调
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onAddForm, want: ${want.abilityName}`);
    
    let dataObj: Record<string, string> = {
      'title': '初始标题',
      'detail': '初始描述内容',
      'updateTime': '未更新'
    };
    
    let obj: formBindingData.FormBindingData = formBindingData.createFormBindingData(dataObj);
    return obj;
  }

  // message事件回调处理
  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${message}`);
    
    try {
      // 解析消息参数（message为JSON字符串）
      let messageObj = JSON.parse(message);
      hilog.info(DOMAIN_NUMBER, TAG, `Parsed message: ${JSON.stringify(messageObj)}`);
      
      // 定义更新数据类，字段需与卡片页面LocalStorageProp对应
      class FormDataClass {
        title: string = '标题已更新';
        detail: string = '描述内容更新成功';
        updateTime: string = new Date().toLocaleTimeString();
      }
      
      // 创建更新数据
      let formData = new FormDataClass();
      let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
      
      // 调用updateForm刷新卡片
      formProvider.updateForm(formId, formInfo).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
      }).catch((error: BusinessError) => {
        this.handleUpdateError(error);
      });
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Failed to process message: ${error}`);
    }
  }

  // 卡片更新回调（定时刷新等）
  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onUpdateForm, formId: ${formId}`);
    
    let param: Record<string, string> = {
      'title': '定时更新标题',
      'detail': '定时更新描述',
      'updateTime': new Date().toLocaleTimeString()
    };
    
    let obj: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
    formProvider.updateForm(formId, obj).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility onUpdateForm success');
    }).catch((error: BusinessError) => {
      this.handleUpdateError(error);
    });
  }

  // 卡片销毁回调
  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `FormAbility onRemoveForm, formId: ${formId}`);
    // 清理该卡片相关的持久化数据
  }

  // 配置更新回调
  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onConfigurationUpdate, config: ${newConfig?.language}`);
  }

  // 错误处理函数
  private handleUpdateError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(DOMAIN_NUMBER, TAG, 'Parameter error: mandatory parameters missing or incorrect types');
        break;
      case 16500050:
        hilog.error(DOMAIN_NUMBER, TAG, 'IPC connection error');
        break;
      case 16500060:
        hilog.error(DOMAIN_NUMBER, TAG, 'Service connection error');
        break;
      case 16500100:
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to obtain configuration information');
        break;
      case 16501000:
        hilog.error(DOMAIN_NUMBER, TAG, 'Internal functional error occurred');
        break;
      case 16501001:
        hilog.error(DOMAIN_NUMBER, TAG, 'The ID of the form to be operated does not exist');
        break;
      case 16501003:
        hilog.error(DOMAIN_NUMBER, TAG, 'The form cannot be operated by the current application');
        break;
      default:
        hilog.error(DOMAIN_NUMBER, TAG, `Unknown error: code ${error.code}, message ${error.message}`);
    }
  }
}