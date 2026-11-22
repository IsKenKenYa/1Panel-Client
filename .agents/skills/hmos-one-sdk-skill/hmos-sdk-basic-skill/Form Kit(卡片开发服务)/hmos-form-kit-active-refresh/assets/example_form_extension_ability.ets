// entry/src/main/ets/entryformability/EntryFormAbility.ets
// 单个卡片主动刷新完整示例 - FormExtensionAbility实现

import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Configuration, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryFormAbility extends FormExtensionAbility {
  /**
   * 卡片添加时触发
   * 返回卡片初始数据
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onAddForm');
    hilog.info(DOMAIN_NUMBER, TAG, `Form name: ${want.parameters?.[formInfo.FormParam.NAME_KEY] as string}`);
    
    // 卡片使用方创建卡片时触发，卡片提供方需要返回卡片数据绑定类
    let obj: Record<string, string> = {
      'title': 'Weather Card',
      'detail': ' Sunny day',
      'temperature': '22c',
      'updateTime': this.getCurrentTime()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    return formData;
  }

  /**
   * 卡片更新时触发
   * 定时更新、定点更新、卡片使用方主动请求更新
   */
  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryFormAbility] onUpdateForm');
    
    // 获取最新数据（实际应用中应从网络或本地数据库获取）
    let obj: Record<string, string> = {
      'title': 'Weather Updated',
      'detail': 'Partly cloudy',
      'temperature': this.getWeatherTemperature(),
      'updateTime': this.getCurrentTime()
    };
    
    let formData: formBindingData.FormBindingData = formBindingData.createFormBindingData(obj);
    
    formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `[EntryFormAbility] updateForm failed, code: ${error.code}, message: ${error.message}`);
    });
  }

  /**
   * 卡片事件触发时调用
   * 通过postCardAction的message事件触发
   */
  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, 
      `FormAbility onFormEvent, formId = ${formId}, message: ${message}`);
    
    try {
      // 解析消息参数
      const messageObj = JSON.parse(message);
      hilog.info(DOMAIN_NUMBER, TAG, `Message params: ${JSON.stringify(messageObj)}`);
      
      // 根据事件类型处理不同刷新逻辑
      if (messageObj.actionType === 'refresh') {
        this.performManualRefresh(formId);
      } else if (messageObj.actionType === 'update_temperature') {
        this.updateTemperature(formId);
      }
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Failed to parse message: ${error}`);
      // 使用默认刷新逻辑
      this.performManualRefresh(formId);
    }
  }

  /**
   * 执行手动刷新
   */
  private performManualRefresh(formId: string): void {
    class FormDataClass {
      title: string = 'Weather Updated';
      detail: string = 'Description update success.';
      temperature: string = this.getTemperature();
      updateTime: string = this.getTime();
      
      private getTemperature(): string {
        // 模拟获取温度数据（实际应用应从API获取）
        const temp = Math.floor(Math.random() * 10 + 20); // 20-30度
        return `${temp}c`;
      }
      
      private getTime(): string {
        const now = new Date();
        return `${now.getHours()}:${now.getMinutes()}`;
      }
    }
    
    let formData = new FormDataClass();
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    
    formProvider.updateForm(formId, formInfo).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, 'FormAbility updateForm success.');
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, 
        `Operation updateForm failed. code: ${error.code}, message: ${error.message}`);
      
      // 降级处理：使用缓存数据
      this.useCachedData(formId);
    });
  }

  /**
   * 更新温度信息
   */
  private updateTemperature(formId: string): void {
    const temp = this.getWeatherTemperature();
    const obj: Record<string, string> = {
      'temperature': temp,
      'updateTime': this.getCurrentTime()
    };
    
    let formData = formBindingData.createFormBindingData(obj);
    formProvider.updateForm(formId, formData).catch((error: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `Update temperature failed: ${error.message}`);
    });
  }

  /**
   * 使用缓存数据降级处理
   */
  private useCachedData(formId: string): void {
    try {
      // 从本地缓存获取上次成功的数据（实际应用需要实现缓存机制）
      const cachedData: Record<string, string> = {
        'title': 'Cached Weather',
        'detail': 'Using cached data',
        'temperature': '20c',
        'updateTime': 'Cached'
      };
      
      let formData = formBindingData.createFormBindingData(cachedData);
      formProvider.updateForm(formId, formData);
      hilog.warn(DOMAIN_NUMBER, TAG, 'Used cached data for refresh');
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Cache fallback failed: ${error}`);
    }
  }

  /**
   * 卡片销毁时触发
   */
  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onRemoveForm, formId: ${formId}`);
    // 清理该卡片相关的持久化数据
  }

  /**
   * 临时卡片转常态卡片
   */
  onCastToNormalForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onCastToNormalForm, formId: ${formId}`);
  }

  /**
   * 卡片可见性变更
   */
  onChangeFormVisibility(newStatus: Record<string, number>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onChangeFormVisibility`);
  }

  /**
   * 配置更新
   */
  onConfigurationUpdate(config: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, 
      `[EntryFormAbility] onConfigurationUpdate: ${JSON.stringify(config)}`);
  }

  /**
   * 查询卡片状态
   */
  onAcquireFormState(want: Want): formInfo.FormState {
    hilog.info(DOMAIN_NUMBER, TAG, `[EntryFormAbility] onAcquireFormState`);
    return formInfo.FormState.READY;
  }

  /**
   * 获取当前时间
   */
  private getCurrentTime(): string {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 获取天气温度（模拟数据）
   */
  private getWeatherTemperature(): string {
    const temp = Math.floor(Math.random() * 10 + 20);
    return `${temp}c`;
  }
}