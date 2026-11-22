/**
 * 应用内开启未成年人模式 - 完整示例代码
 * 
 * 本示例展示如何在应用内引导用户开启系统未成年人模式，
 * 并与系统未成年人模式状态联动。
 */

import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const TAG = 'MinorsProtectionExample';
const DOMAIN = 0x0000;

/**
 * 未成年人模式状态缓存
 */
let cachedMinorsModeStatus: boolean = false;
let cachedAgeGroup: minorsProtection.AgeGroup | null = null;

/**
 * 未成年人模式完整实现示例
 */
export class MinorsProtectionManager {
  private context: common.Context;
  private minorsModeOnSubscriber: any = null;
  private minorsModeOffSubscriber: any = null;
  
  constructor(context: common.Context) {
    this.context = context;
  }
  
  /**
   * 初始化未成年人模式管理
   * 检查设备支持、订阅事件、获取当前状态
   */
  async initialize(): Promise<void> {
    hilog.info(DOMAIN, TAG, '初始化未成年人模式管理');
    
    // 1. 检查系统能力是否支持
    if (!this.checkSystemCapability()) {
      hilog.warn(DOMAIN, TAG, '当前设备不支持未成年人模式系统能力');
      this.provideFallbackSolution();
      return;
    }
    
    // 2. 检查设备环境是否支持
    if (!this.checkDeviceSupport()) {
      hilog.warn(DOMAIN, TAG, '当前设备环境不支持未成年人模式');
      this.provideFallbackSolution();
      return;
    }
    
    // 3. 订阅未成年人模式事件
    this.subscribeMinorsModeEvents();
    
    // 4. 获取当前未成年人模式状态
    await this.refreshMinorsModeStatus();
  }
  
  /**
   * 检查系统能力是否支持
   */
  private checkSystemCapability(): boolean {
    try {
      const isSupported = canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection');
      hilog.info(DOMAIN, TAG, `系统能力检查结果: ${isSupported}`);
      return isSupported;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `系统能力检查异常: ${error}`);
      return false;
    }
  }
  
  /**
   * 检查设备环境是否支持未成年人模式
   */
  private checkDeviceSupport(): boolean {
    try {
      const isSupported = minorsProtection.supportMinorsMode();
      hilog.info(DOMAIN, TAG, `设备环境支持检查结果: ${isSupported}`);
      return isSupported;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `设备支持检查异常: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 获取未成年人模式当前状态
   */
  private async refreshMinorsModeStatus(): Promise<void> {
    try {
      // 使用同步接口获取状态
      const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
      
      // 获取未成年人模式开启状态
      const isMinorsModeOn = minorsProtectionInfo.minorsProtectionMode;
      
      // 缓存状态
      cachedMinorsModeStatus = isMinorsModeOn;
      hilog.info(DOMAIN, TAG, `未成年人模式状态: ${isMinorsModeOn ? '已开启' : '未开启'}`);
      
      // 如果未成年人模式已开启，获取年龄段信息
      if (isMinorsModeOn) {
        const ageGroup = minorsProtectionInfo.ageGroup;
        if (ageGroup) {
          cachedAgeGroup = ageGroup;
          hilog.info(DOMAIN, TAG, 
            `年龄段信息: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
          
          // 根据年龄段调整内容展示
          this.adjustContentByAgeGroup(ageGroup);
        }
        
        // 更新应用状态：开启应用内未成年人模式
        this.updateAppMinorsModeStatus(true);
      } else {
        // 未成年人模式未开启
        cachedAgeGroup = null;
        
        // 更新应用状态：关闭应用内未成年人模式
        this.updateAppMinorsModeStatus(false);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `获取未成年人模式状态失败: ${JSON.stringify(error)}`);
      this.handleInternalError(error as BusinessError<Object>);
    }
  }
  
  /**
   * 引导用户开启未成年人模式
   */
  async guideUserToTurnOnMinorsMode(): Promise<void> {
    hilog.info(DOMAIN, TAG, '引导用户开启未成年人模式');
    
    // 先检查当前状态
    if (cachedMinorsModeStatus) {
      hilog.info(DOMAIN, TAG, '未成年人模式已开启，无需重复开启');
      this.showToast('未成年人模式已开启');
      return;
    }
    
    try {
      // 引导用户开启未成年人模式
      await minorsProtection.leadToTurnOnMinorsMode(this.context);
      
      hilog.info(DOMAIN, TAG, '引导开启未成年人模式流程已完成');
      
      // 必须在 then 方法中弹出提示
      this.showToast('未成年人模式已开启');
      
      // 等待订阅的事件回调来更新状态
      // 注意：不要在这里直接更新状态，应该等待事件回调
      
    } catch (error) {
      const businessError = error as BusinessError<Object>;
      this.handleTurnOnError(businessError);
    }
  }
  
  /**
   * 处理引导开启未成年人模式的错误
   */
  private handleTurnOnError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, 
      `引导开启未成年人模式失败。错误码: ${error.code}, 错误信息: ${error.message}`);
    
    switch (error.code) {
      case 401:
        hilog.error(DOMAIN, TAG, '参数错误：Context 无效或类型不正确');
        this.showToast('参数错误，无法开启未成年人模式');
        break;
        
      case 1001502009:
        hilog.error(DOMAIN, TAG, '内部错误');
        this.handleInternalError(error);
        break;
        
      case 1009900003:
        hilog.info(DOMAIN, TAG, '用户取消了开启未成年人模式操作');
        // 应用无需特殊处理
        break;
        
      case 1009900005:
        hilog.info(DOMAIN, TAG, '未成年人模式已经开启');
        this.showToast('未成年人模式已经开启');
        // 更新状态
        cachedMinorsModeStatus = true;
        this.updateAppMinorsModeStatus(true);
        break;
        
      case 1009900007:
        hilog.error(DOMAIN, TAG, '当前账号不支持未成年人模式（海外账号）');
        this.provideFallbackForUnsupportedAccount();
        break;
        
      case 1009900011:
        hilog.error(DOMAIN, TAG, '服务不可用（隐私空间）');
        this.provideFallbackForPrivacySpace();
        break;
        
      default:
        hilog.error(DOMAIN, TAG, `未知错误: ${error.code}`);
        this.showToast(`开启失败，错误码: ${error.code}`);
        break;
    }
  }
  
  /**
   * 订阅未成年人模式开启/关闭事件
   */
  private subscribeMinorsModeEvents(): void {
    hilog.info(DOMAIN, TAG, '订阅未成年人模式事件');
    
    // 订阅未成年人模式开启事件
    this.minorsModeOnSubscriber = commonEventManager.createSubscriber({
      events: ['usual.event.MINORSMODE_ON']
    });
    
    commonEventManager.subscribe(this.minorsModeOnSubscriber, (err, data) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `订阅未成年人模式开启事件失败: ${err.code}`);
        return;
      }
      
      hilog.info(DOMAIN, TAG, '收到未成年人模式开启事件');
      
      // 更新应用状态：开启应用内未成年人模式
      this.updateAppMinorsModeStatus(true);
      
      // 刷新年龄段信息
      this.refreshAgeGroupInfo();
    });
    
    // 订阅未成年人模式关闭事件
    this.minorsModeOffSubscriber = commonEventManager.createSubscriber({
      events: ['usual.event.MINORSMODE_OFF']
    });
    
    commonEventManager.subscribe(this.minorsModeOffSubscriber, (err, data) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `订阅未成年人模式关闭事件失败: ${err.code}`);
        return;
      }
      
      hilog.info(DOMAIN, TAG, '收到未成年人模式关闭事件');
      
      // 更新应用状态：关闭应用内未成年人模式
      this.updateAppMinorsModeStatus(false);
      
      // 清除年龄段信息缓存
      this.clearAgeGroupCache();
    });
  }
  
  /**
   * 刷新年龄段信息
   */
  private async refreshAgeGroupInfo(): Promise<void> {
    try {
      const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
      
      if (minorsProtectionInfo.minorsProtectionMode && minorsProtectionInfo.ageGroup) {
        cachedAgeGroup = minorsProtectionInfo.ageGroup;
        hilog.info(DOMAIN, TAG, 
          `年龄段信息已更新: [${cachedAgeGroup.lowerAge}, ${cachedAgeGroup.upperAge})`);
        
        // 根据年龄段调整内容展示
        this.adjustContentByAgeGroup(cachedAgeGroup);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `刷新年龄段信息失败: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 根据年龄段调整内容展示
   */
  private adjustContentByAgeGroup(ageGroup: minorsProtection.AgeGroup): void {
    hilog.info(DOMAIN, TAG, `根据年龄段 [${ageGroup.lowerAge}, ${ageGroup.upperAge}) 调整内容`);
    
    // 根据年龄段实现内容分级逻辑
    if (ageGroup.lowerAge >= 0 && ageGroup.upperAge <= 3) {
      // 0-3岁：展示最基础的内容
      this.setContentLevel('level_0_3');
    } else if (ageGroup.lowerAge >= 3 && ageGroup.upperAge <= 8) {
      // 3-8岁：展示儿童友好内容
      this.setContentLevel('level_3_8');
    } else if (ageGroup.lowerAge >= 8 && ageGroup.upperAge <= 12) {
      // 8-12岁：展示少年内容
      this.setContentLevel('level_8_12');
    } else if (ageGroup.lowerAge >= 12 && ageGroup.upperAge <= 16) {
      // 12-16岁：展示青少年内容
      this.setContentLevel('level_12_16');
    } else if (ageGroup.lowerAge >= 16 && ageGroup.upperAge <= 18) {
      // 16-18岁：展示接近成人内容
      this.setContentLevel('level_16_18');
    }
  }
  
  /**
   * 设置内容等级（应用自定义实现）
   */
  private setContentLevel(level: string): void {
    hilog.info(DOMAIN, TAG, `设置内容等级: ${level}`);
    // 应用根据自身业务逻辑实现内容分级
    // 例如：限制某些功能、过滤内容等
  }
  
  /**
   * 更新应用未成年人模式状态（应用自定义实现）
   */
  private updateAppMinorsModeStatus(isOn: boolean): void {
    hilog.info(DOMAIN, TAG, `更新应用未成年人模式状态: ${isOn ? '开启' : '关闭'}`);
    cachedMinorsModeStatus = isOn;
    
    // 应用根据自身业务逻辑实现状态更新
    // 例如：更新UI、切换功能模块等
  }
  
  /**
   * 清除年龄段信息缓存
   */
  private clearAgeGroupCache(): void {
    cachedAgeGroup = null;
    hilog.info(DOMAIN, TAG, '年龄段信息缓存已清除');
  }
  
  /**
   * 处理内部错误
   */
  private handleInternalError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, `内部错误: ${error.code}`);
    
    // 建议：重启设备后重试，或提交问题给华为支持
    this.showDialog(
      '发生内部错误',
      '建议重启设备后重试，或联系华为技术支持'
    );
  }
  
  /**
   * 设备不支持时的降级方案
   */
  private provideFallbackSolution(): void {
    hilog.info(DOMAIN, TAG, '提供降级方案：构建应用自己的未成年人模式');
    
    this.showDialog(
      '设备不支持系统未成年人模式',
      '当前设备不支持系统未成年人模式，应用将使用自己的未成年人保护机制'
    );
    
    // 构建应用自己的未成年人模式
    this.buildAppOwnMinorsMode();
  }
  
  /**
   * 海外账号不支持时的降级方案
   */
  private provideFallbackForUnsupportedAccount(): void {
    hilog.info(DOMAIN, TAG, '提供降级方案：海外账号不支持');
    
    this.showDialogWithOptions(
      '海外账号不支持系统未成年人模式',
      [
        { text: '登录中国境内账号', action: () => this.guideToLoginChineseAccount() },
        { text: '使用应用未成年人模式', action: () => this.buildAppOwnMinorsMode() }
      ]
    );
  }
  
  /**
   * 隐私空间环境时的降级方案
   */
  private provideFallbackForPrivacySpace(): void {
    hilog.info(DOMAIN, TAG, '提供降级方案：隐私空间不支持');
    
    this.showDialogWithOptions(
      '隐私空间不支持系统未成年人模式',
      [
        { text: '退出隐私空间', action: () => this.guideToExitPrivacySpace() },
        { text: '使用应用未成年人模式', action: () => this.buildAppOwnMinorsMode() }
      ]
    );
  }
  
  /**
   * 构建应用自己的未成年人模式（应用自定义实现）
   */
  private buildAppOwnMinorsMode(): void {
    hilog.info(DOMAIN, TAG, '构建应用自己的未成年人模式');
    // 应用根据自身业务逻辑实现自己的未成年人保护机制
  }
  
  /**
   * 引导登录中国境内账号（应用自定义实现）
   */
  private guideToLoginChineseAccount(): void {
    hilog.info(DOMAIN, TAG, '引导用户登录中国境内账号');
    // 引导用户到系统设置登录中国境内账号
  }
  
  /**
   * 引导退出隐私空间（应用自定义实现）
   */
  private guideToExitPrivacySpace(): void {
    hilog.info(DOMAIN, TAG, '引导用户退出隐私空间');
    // 提示用户到设置退出隐私空间
  }
  
  /**
   * 显示 Toast（应用自定义实现）
   */
  private showToast(message: string): void {
    hilog.info(DOMAIN, TAG, `Toast: ${message}`);
    // 应用使用自己的 Toast 实现显示提示
  }
  
  /**
   * 显示对话框（应用自定义实现）
   */
  private showDialog(title: string, message: string): void {
    hilog.info(DOMAIN, TAG, `Dialog: ${title} - ${message}`);
    // 应用使用自己的 Dialog 实现显示对话框
  }
  
  /**
   * 显示选项对话框（应用自定义实现）
   */
  private showDialogWithOptions(
    title: string, 
    options: Array<{ text: string; action: () => void }>
  ): void {
    hilog.info(DOMAIN, TAG, `Options Dialog: ${title}`);
    // 应用使用自己的 Dialog 实现显示选项对话框
  }
  
  /**
   * 获取当前未成年人模式状态
   */
  getCurrentStatus(): boolean {
    return cachedMinorsModeStatus;
  }
  
  /**
   * 获取当前年龄段信息
   */
  getCurrentAgeGroup(): minorsProtection.AgeGroup | null {
    return cachedAgeGroup;
  }
  
  /**
   * 清理资源
   */
  cleanup(): void {
    hilog.info(DOMAIN, TAG, '清理未成年人模式管理资源');
    
    // 取消订阅事件
    if (this.minorsModeOnSubscriber) {
      commonEventManager.unsubscribe(this.minorsModeOnSubscriber, (err) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `取消订阅开启事件失败: ${err.code}`);
        }
      });
    }
    
    if (this.minorsModeOffSubscriber) {
      commonEventManager.unsubscribe(this.minorsModeOffSubscriber, (err) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `取消订阅关闭事件失败: ${err.code}`);
        }
      });
    }
    
    // 清除缓存
    this.clearAgeGroupCache();
    cachedMinorsModeStatus = false;
  }
}

/**
 * 使用示例
 */
export function exampleUsage() {
  // 在自定义组件或页面中使用
  // const manager = new MinorsProtectionManager(this.getUIContext().getHostContext());
  
  // 初始化
  // await manager.initialize();
  
  // 引导开启未成年人模式
  // await manager.guideUserToTurnOnMinorsMode();
  
  // 获取当前状态
  // const isOn = manager.getCurrentStatus();
  // const ageGroup = manager.getCurrentAgeGroup();
  
  // 清理资源
  // manager.cleanup();
}