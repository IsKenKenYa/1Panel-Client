// 锁屏卡片FormExtensionAbility完整实现
// 文件路径: entry/src/main/ets/formability/LockScreenFormAbility.ets

import { formBindingData, FormExtensionAbility, formProvider, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class LockScreenFormAbility extends FormExtensionAbility {
  // 卡片创建回调
  onAddForm(want: Want) {
    console.info('LockScreenFormAbility onAddForm, want:', want.abilityName);
    
    // 获取卡片参数
    let formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    let formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;
    let formDimension = want.parameters?.['ohos.extra.param.key.form_dimension'] as number;
    
    console.info('formId:', formId, 'formName:', formName, 'formDimension:', formDimension);
    
    // 准备卡片数据
    let formData: Record<string, string> = {
      'temperature': '20c',
      'time': '12:00',
      'weatherIcon': '☀️'
    };
    
    // 创建卡片绑定数据
    let bindingData = formBindingData.createFormBindingData(formData);
    return bindingData;
  }
  
  // 卡片更新回调
  onUpdateForm(formId: string, wantParams?: Record<string, Object>) {
    console.info('LockScreenFormAbility onUpdateForm, formId:', formId);
    
    // 获取最新数据(这里可以调用网络接口或其他数据源)
    let latestTemperature = this.fetchLatestTemperature();
    let latestTime = this.getCurrentTime();
    
    // 准备更新数据
    let formData: Record<string, string> = {
      'temperature': latestTemperature,
      'time': latestTime,
      'weatherIcon': '☀️'
    };
    
    let bindingData = formBindingData.createFormBindingData(formData);
    
    // 更新卡片
    formProvider.updateForm(formId, bindingData).then(() => {
      console.info('锁屏卡片更新成功');
    }).catch((error: BusinessError) => {
      console.error('锁屏卡片更新失败, code:', error.code, 'message:', error.message);
      
      // 错误处理
      this.handleUpdateError(error);
    });
  }
  
  // 卡片销毁回调
  onRemoveForm(formId: string) {
    console.info('LockScreenFormAbility onRemoveForm, formId:', formId);
    
    // 清理卡片相关数据
    this.cleanWidgetData(formId);
  }
  
  // 卡片事件回调
  onFormEvent(formId: string, message: string) {
    console.info('LockScreenFormAbility onFormEvent, formId:', formId, 'message:', message);
    
    // 处理卡片事件(如点击事件)
    if (message === 'refresh') {
      // 刷新卡片数据
      this.onUpdateForm(formId);
    }
  }
  
  // 卡片可见性变化回调(仅系统应用)
  onChangeFormVisibility(newStatus: Record<string, number>) {
    console.info('LockScreenFormAbility onChangeFormVisibility');
    
    // 处理卡片可见性变化
    let keys = Object.keys(newStatus);
    for (let i = 0; i < keys.length; i++) {
      let formId = keys[i];
      let visibility = newStatus[formId];
      console.info('formId:', formId, 'visibility:', visibility);
      
      // 根据可见性更新卡片
      if (visibility === 1) {
        // 卡片可见,更新数据
        this.onUpdateForm(formId);
      }
    }
  }
  
  // 配置更新回调
  onConfigurationUpdate(newConfig: Configuration) {
    console.info('LockScreenFormAbility onConfigurationUpdate, config:', newConfig?.language);
    
    // 处理系统配置变化(如语言变化)
    // 可以根据新配置更新卡片内容
  }
  
  // 卡片状态查询回调
  onAcquireFormState(want: Want): formInfo.FormState {
    console.info('LockScreenFormAbility onAcquireFormState, want:', want);
    
    // 返回卡片状态
    return formInfo.FormState.READY;
  }
  
  // 卡片位置变化回调(API version 20+)
  onFormLocationChanged(formId: string, newFormLocation: formInfo.FormLocation) {
    console.info('LockScreenFormAbility onFormLocationChanged, location:', newFormLocation);
    
    // 处理卡片位置变化(如从桌面移动到锁屏)
  }
  
  // 辅助方法:获取最新温度
  private fetchLatestTemperature(): string {
    // 这里可以调用天气API获取实时温度
    // 示例返回固定值
    return '25c';
  }
  
  // 辅助方法:获取当前时间
  private getCurrentTime(): string {
    let now = new Date();
    let hours = now.getHours().toString().padStart(2, '0');
    let minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
  
  // 辅助方法:清理卡片数据
  private cleanWidgetData(formId: string) {
    // 清理卡片持久化数据
    console.info('清理卡片数据, formId:', formId);
  }
  
  // 辅助方法:处理更新错误
  private handleUpdateError(error: BusinessError) {
    switch (error.code) {
      case 1:
        console.error('卡片不存在');
        break;
      case 2:
        console.error('卡片ID无效');
        break;
      case 3:
        console.error('卡片数据格式错误');
        break;
      default:
        console.error('未知错误:', error.message);
    }
  }
}