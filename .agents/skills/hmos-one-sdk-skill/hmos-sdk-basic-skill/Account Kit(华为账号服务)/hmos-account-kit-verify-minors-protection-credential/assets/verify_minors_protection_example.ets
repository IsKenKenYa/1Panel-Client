/**
 * 未成年人模式密码验证完整示例
 * 
 * 功能说明：
 * 本示例展示如何在应用内验证未成年人模式密码以调整应用设置。
 * 当用户需要调整内容偏好、使用时长等设置时，通过验证家长身份来确认权限。
 * 
 * 使用场景：
 * - 应用内调整未成年人模式设置
 * - 验证家长身份
 * - 修改内容偏好和使用时长配置
 * 
 * 注意事项：
 * - 必须在页面或自定义组件生命周期内调用
 * - 未成年人模式必须已开启（否则返回错误码1009900002）
 * - 仅支持中国境内（香港特别行政区、澳门特别行政区、中国台湾除外）账号
 */

import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const LOG_TAG = 'MinorsProtectionVerify';
const LOG_DOMAIN = 0x0000;

/**
 * 未成年人模式密码验证组件
 */
@Entry
@Component
struct MinorsProtectionVerifyPage {
  @State minorsModeEnabled: boolean = false;
  @State verifyResult: boolean = false;
  @State ageGroupText: string = '';
  @State errorMessage: string = '';
  
  /**
   * 页面加载时查询未成年人模式状态
   */
  async aboutToAppear() {
    await this.queryMinorsProtectionStatus();
  }
  
  /**
   * 查询未成年人模式状态
   */
  async queryMinorsProtectionStatus(): Promise<void> {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'Current device does not support minors protection');
      this.errorMessage = '当前设备不支持未成年人模式功能';
      return;
    }
    
    try {
      // 检查设备是否支持未成年人模式
      if (minorsProtection.supportMinorsMode()) {
        // 使用同步接口查询状态
        const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
        this.minorsModeEnabled = minorsProtectionInfo.minorsProtectionMode;
        
        hilog.info(LOG_DOMAIN, LOG_TAG, 
          `Minors protection mode: ${this.minorsModeEnabled}`);
        
        if (this.minorsModeEnabled) {
          // 获取年龄段信息
          const ageGroup = minorsProtectionInfo.ageGroup;
          if (ageGroup) {
            this.ageGroupText = `[${ageGroup.lowerAge}, ${ageGroup.upperAge})岁`;
            hilog.info(LOG_DOMAIN, LOG_TAG, 
              `Age group: ${this.ageGroupText}`);
          }
        } else {
          this.errorMessage = '未成年人模式未开启';
        }
      } else {
        hilog.warn(LOG_DOMAIN, LOG_TAG, 'Device does not support minors mode');
        this.errorMessage = '当前设备环境不支持未成年人模式';
      }
    } catch (error) {
      const err = error as BusinessError<Object>;
      hilog.error(LOG_DOMAIN, LOG_TAG, 
        `Failed to query status. Code: ${err.code}, Message: ${err.message}`);
      this.errorMessage = `查询失败: ${err.message}`;
    }
  }
  
  /**
   * 验证未成年人模式密码
   * 
   * @returns Promise<boolean> 验证结果
   */
  async verifyMinorsProtectionPassword(): Promise<boolean> {
    // 前置校验
    if (!this.minorsModeEnabled) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'Minors mode is not enabled');
      this.errorMessage = '未成年人模式未开启，无法验证密码';
      return false;
    }
    
    try {
      // 获取Context上下文（必须在自定义组件实例中）
      const context = this.getUIContext().getHostContext() as common.Context;
      
      // 调用验证接口
      const result = await minorsProtection.verifyMinorsProtectionCredential(context);
      
      this.verifyResult = result;
      hilog.info(LOG_DOMAIN, LOG_TAG, `Verification result: ${result}`);
      
      if (result) {
        // 验证成功，可以调整设置
        this.showAdjustSettingsDialog();
      } else {
        this.errorMessage = '密码验证未通过';
      }
      
      return result;
    } catch (error) {
      const err = error as BusinessError<Object>;
      this.handleVerifyError(err);
      return false;
    }
  }
  
  /**
   * 处理验证错误
   */
  handleVerifyError(error: BusinessError<Object>): void {
    hilog.error(LOG_DOMAIN, LOG_TAG, 
      `Verification failed. Code: ${error.code}, Message: ${error.message}`);
    
    switch (error.code) {
      case 401:
        this.errorMessage = '参数错误，请检查Context参数';
        break;
      case 1001502009:
        this.errorMessage = '内部错误，请重启设备后重试';
        break;
      case 1009900002:
        this.errorMessage = '未成年人模式未开启';
        this.minorsModeEnabled = false;
        break;
      case 1009900003:
        this.errorMessage = '用户取消验证';
        break;
      case 1009900011:
        this.errorMessage = '服务不可用，请退出隐私空间';
        break;
      default:
        this.errorMessage = `验证失败: ${error.message}`;
    }
  }
  
  /**
   * 显示调整设置对话框
   */
  showAdjustSettingsDialog(): void {
    AlertDialog.show({
      title: '验证成功',
      message: '家长身份验证通过，现在可以调整未成年人模式设置',
      confirm: {
        value: '确定',
        action: () => {
          // 执行调整设置的逻辑
          this.adjustMinorsModeSettings();
        }
      }
    });
  }
  
  /**
   * 调整未成年人模式设置
   * 
   * 注意：此方法应在验证成功后调用
   */
  adjustMinorsModeSettings(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Adjusting minors mode settings...');
    
    // 示例：调整内容偏好
    this.adjustContentPreference();
    
    // 示例：调整使用时长
    this.adjustUsageTimeLimit();
  }
  
  /**
   * 调整内容偏好
   */
  adjustContentPreference(): void {
    // 根据年龄段设置内容过滤级别
    const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
    const ageGroup = minorsProtectionInfo.ageGroup;
    
    if (ageGroup) {
      hilog.info(LOG_DOMAIN, LOG_TAG, 
        `Setting content filter for age group: [${ageGroup.lowerAge}, ${ageGroup.upperAge})`);
      
      // 实际应用中，这里会设置内容过滤、推荐算法等
      // 示例：根据年龄段调整推荐内容
      if (ageGroup.lowerAge < 8) {
        // 低龄段：严格过滤
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting strict content filter');
      } else if (ageGroup.lowerAge < 12) {
        // 中龄段：适度过滤
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting moderate content filter');
      } else {
        // 高龄段：轻度过滤
        hilog.info(LOG_DOMAIN, LOG_TAG, 'Setting light content filter');
      }
    }
  }
  
  /**
   * 调整使用时长限制
   */
  adjustUsageTimeLimit(): void {
    // 示例：设置每日使用时长限制
    hilog.info(LOG_DOMAIN, LOG_TAG, 'Adjusting usage time limit');
    
    // 实际应用中，这里会设置时间限制、提醒规则等
    // 注意：具体的时间限制功能需要应用自己实现
  }
  
  build() {
    Column() {
      // 标题
      Text('未成年人模式设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      // 状态显示
      if (this.errorMessage !== '') {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
          .margin({ bottom: 20 });
      }
      
      // 未成年人模式状态
      Text(`未成年人模式状态: ${this.minorsModeEnabled ? '已开启' : '未开启'}`)
        .fontSize(18)
        .margin({ bottom: 10 });
      
      // 年龄段信息
      if (this.minorsModeEnabled && this.ageGroupText !== '') {
        Text(`年龄段: ${this.ageGroupText}`)
          .fontSize(18)
          .margin({ bottom: 20 });
      }
      
      // 验证结果
      if (this.verifyResult) {
        Text('验证成功')
          .fontSize(16)
          .fontColor(Color.Green)
          .margin({ bottom: 20 });
      }
      
      // 验证按钮
      Button('验证家长身份')
        .width('80%')
        .height(50)
        .fontSize(18)
        .enabled(this.minorsModeEnabled)
        .onClick(() => {
          this.verifyMinorsProtectionPassword();
        })
        .margin({ bottom: 20 });
      
      // 刷新状态按钮
      Button('刷新状态')
        .width('80%')
        .height(50)
        .fontSize(18)
        .onClick(() => {
          this.queryMinorsProtectionStatus();
        })
        .margin({ bottom: 20 });
      
      // 说明文字
      Text('提示：验证家长身份后可调整应用内的未成年人模式设置')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 20 });
    }
    .width('100%')
    .padding(20);
  }
}