// entry/src/main/ets/entryformability/EntryFormAbility.ets
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Configuration, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onAddForm');
    
    // 从want参数中获取卡片信息
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string;
    const dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number;
    
    hilog.info(DOMAIN_NUMBER, TAG, `FormId: ${formId}, Name: ${formName}, Dimension: ${dimension}`);
    
    // 创建卡片初始数据
    let obj: Record<string, string> = {
      'title': 'titleOnAddForm',
      'detail': 'detailOnAddForm',
      'temperature': '22°',
      'time': new Date().toLocaleTimeString()
    };
    
    // 创建FormBindingData对象并返回
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    return formData;
  }
  
  onCastToNormalForm(formId: string): void {
    // 当前卡片使用方不会涉及该场景，无需实现该回调函数
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onCastToNormalForm, formId: ${formId}`);
  }
  
  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onUpdateForm, formId: ${formId}`);
    
    // 获取最新数据（实际应用中应从数据库或网络获取）
    let obj: Record<string, string> = {
      'title': 'titleOnUpdateForm',
      'detail': 'detailOnUpdateForm',
      'temperature': '25°',
      'time': new Date().toLocaleTimeString()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    
    // 使用formProvider.updateForm刷新卡片数据
    formProvider.updateForm(formId, formData).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'updateForm success');
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `updateForm failed, code: ${error.code}, message: ${error.message}`);
    });
  }
  
  onChangeFormVisibility(newStatus: Record<string, number>): void {
    // 卡片使用方发起可见或者不可见通知触发，提供方需要做相应的处理，仅系统应用生效
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onChangeFormVisibility, newStatus: ${JSON.stringify(newStatus)}`);
    
    // 处理可见性变化（仅系统应用生效）
    // 示例：当卡片变为可见时，更新数据
    let keys = Object.keys(newStatus);
    for (let key of keys) {
      if (newStatus[key] === formInfo.VisibilityType.FORM_VISIBLE) {
        hilog.info(DOMAIN_NUMBER, TAG, `Form ${key} is visible, updating data...`);
        // 可以在此处调用更新逻辑
      }
    }
  }
  
  onFormEvent(formId: string, message: string): void {
    // 若卡片支持触发事件，则需要重写该方法并实现对事件的触发
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onFormEvent, formId: ${formId}, message: ${message}`);
    
    // 处理卡片事件（根据message内容执行相应操作）
    try {
      const eventObj = JSON.parse(message);
      hilog.info(DOMAIN_NUMBER, TAG, `Event action: ${eventObj.action}`);
      
      // 根据事件类型处理
      if (eventObj.action === 'refresh') {
        // 刷新卡片数据
        this.onUpdateForm(formId);
      } else if (eventObj.action === 'openApp') {
        // 拉起主应用
        this.launchMainApp(formId, eventObj);
      }
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Parse event message failed: ${error}`);
    }
  }
  
  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onRemoveForm, formId: ${formId}`);
    
    // 删除之前持久化的卡片实例数据
    // 此接口请根据实际情况实现，具体请参考：FormExtAbility Stage模型卡片实例
    try {
      // 示例：删除本地存储的卡片数据
      // PreferencesUtil.deleteFormData(formId);
      hilog.info(DOMAIN_NUMBER, TAG, `Form data removed for formId: ${formId}`);
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Remove form data failed: ${error}`);
    }
  }
  
  onConfigurationUpdate(config: Configuration): void {
    // 当前formExtensionAbility存活时更新系统配置信息时触发的回调
    // 需注意：formExtensionAbility创建后10秒内无操作将会被清理
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onConfigurationUpdate: ${JSON.stringify(config)}`);
    
    // 处理配置变化（如语言、颜色模式等）
    if (config.language) {
      hilog.info(DOMAIN_NUMBER, TAG, `Language changed to: ${config.language}`);
      // 可以根据语言变化更新卡片显示内容
    }
  }
  
  onAcquireFormState(want: Want): formInfo.FormState {
    // 卡片提供方接收查询卡片状态通知接口，默认返回卡片初始状态
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onAcquireFormState, want: ${JSON.stringify(want)}`);
    
    // 返回卡片状态
    return formInfo.FormState.READY;
  }
  
  // 辅助方法：拉起主应用处理长时间任务
  private launchMainApp(formId: string, eventObj: any): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] launchMainApp, formId: ${formId}`);
    
    // 对于可能需要10秒以上才能完成的业务逻辑，建议拉起主应用进行处理
    // 处理完成后使用updateForm通知卡片进行刷新
    try {
      let want: Want = {
        bundleName: 'com.example.myapplication', // 替换为实际的bundleName
        abilityName: 'EntryAbility', // 替换为实际的abilityName
        moduleName: 'entry',
        parameters: {
          'formId': formId,
          'action': eventObj.action,
          'data': eventObj.data
        }
      };
      
      this.context.startAbility(want).then(() => {
        hilog.info(DOMAIN_NUMBER, TAG, 'startAbility success');
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN_NUMBER, TAG, `startAbility failed, code: ${error.code}, message: ${error.message}`);
      });
    } catch (error) {
      let businessError = error as BusinessError;
      hilog.error(DOMAIN_NUMBER, TAG, `launchMainApp failed, code: ${businessError.code}, message: ${businessError.message}`);
    }
  }
}