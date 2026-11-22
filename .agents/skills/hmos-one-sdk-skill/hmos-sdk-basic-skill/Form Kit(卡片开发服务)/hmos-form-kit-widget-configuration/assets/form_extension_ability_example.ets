import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class MyFormExtensionAbility extends FormExtensionAbility {
  // 卡片创建时回调
  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info(`FormExtensionAbility onAddForm, want: ${want.abilityName}`);
    
    // 获取卡片信息
    let formId = want.parameters?.['ohos.extra.param.key.form_id'] as string;
    let formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;
    let formDimension = want.parameters?.['ohos.extra.param.key.form_dimension'] as number;
    
    console.info(`FormExtensionAbility onAddForm, formId: ${formId}, formName: ${formName}, formDimension: ${formDimension}`);
    
    // 准备卡片数据
    let dataObj: Record<string, string | number> = {
      'title': '天气卡片',
      'temperature': '25°C',
      'weather': '晴',
      'updateTime': new Date().toLocaleTimeString()
    };
    
    // 创建并返回卡片数据
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(dataObj);
    
    // 持久化卡片信息（重要：用于后续更新和删除）
    this.storeFormInfo(formId, formName, formDimension);
    
    return formData;
  }
  
  // 卡片更新时回调
  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    console.info(`FormExtensionAbility onUpdateForm, formId: ${formId}`);
    
    // 获取最新数据
    let latestData: Record<string, string | number> = {
      'title': '天气卡片',
      'temperature': '26°C',
      'weather': '多云',
      'updateTime': new Date().toLocaleTimeString()
    };
    
    // 创建新的卡片数据
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(latestData);
    
    // 更新卡片
    formProvider.updateForm(formId, formData).then(() => {
      console.info(`FormExtensionAbility updateForm success`);
    }).catch((error: BusinessError) => {
      console.error(`FormExtensionAbility updateForm failed, code: ${error.code}, message: ${error.message}`);
    });
  }
  
  // 卡片删除时回调
  onRemoveForm(formId: string): void {
    console.info(`FormExtensionAbility onRemoveForm, formId: ${formId}`);
    
    // 删除持久化的卡片信息
    this.deleteFormInfo(formId);
  }
  
  // 卡片事件处理
  onFormEvent(formId: string, message: string): void {
    console.info(`FormExtensionAbility onFormEvent, formId: ${formId}, message: ${message}`);
    
    // 处理卡片事件（如点击事件）
    if (message === 'refresh') {
      // 手动刷新卡片
      this.onUpdateForm(formId);
    }
  }
  
  // 配置更新时回调
  onConfigurationUpdate(newConfig: Configuration): void {
    console.info(`FormExtensionAbility onConfigurationUpdate, config: ${JSON.stringify(newConfig)}`);
    
    // 处理配置变更（如语言、颜色模式变化）
    // 注意：FormExtensionAbility创建后10秒内无操作将会被清理
  }
  
  // 卡片状态查询（可选）
  onAcquireFormState(want: Want): formInfo.FormState {
    console.info(`FormExtensionAbility onAcquireFormState, want: ${want}`);
    
    // 返回卡片状态（默认返回UNKNOWN）
    return formInfo.FormState.READY;
  }
  
  // 卡片进程退出时回调（API version 12+）
  onStop(): void {
    console.info(`FormExtensionAbility onStop`);
    
    // 清理资源
  }
  
  // 卡片位置变化时回调（API version 20+）
  onFormLocationChanged(formId: string, newFormLocation: formInfo.FormLocation): void {
    console.info(`FormExtensionAbility onFormLocationChanged, formId: ${formId}, location: ${newFormLocation}`);
    
    // 处理卡片位置变化（如从桌面移动到锁屏）
  }
  
  // 卡片大小变化时回调（API version 20+）
  onSizeChanged(formId: string, newDimension: formInfo.FormDimension, newRect: formInfo.Rect): void {
    console.info(`FormExtensionAbility onSizeChanged, formId: ${formId}, dimension: ${newDimension}`);
    
    // 处理卡片尺寸变化（需要根据新尺寸调整UI布局）
  }
  
  // 持久化卡片信息（示例实现）
  private storeFormInfo(formId: string, formName: string, dimension: number): void {
    // 实际开发中应使用Preferences或其他持久化方式
    console.info(`Store form info: formId=${formId}, formName=${formName}, dimension=${dimension}`);
  }
  
  // 删除卡片信息（示例实现）
  private deleteFormInfo(formId: string): void {
    // 实际开发中应使用Preferences或其他持久化方式
    console.info(`Delete form info: formId=${formId}`);
  }
}