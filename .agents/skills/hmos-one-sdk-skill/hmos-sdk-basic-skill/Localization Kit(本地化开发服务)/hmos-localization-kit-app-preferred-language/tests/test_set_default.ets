/**
 * 测试用例: 设置应用偏好语言为default
 * 测试场景: 正向测试 - 成功清除应用偏好语言使其跟随系统
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageDefault', () => {
  it('should_set_default_successfully', () => {
    try {
      // 设置为default
      i18n.System.setAppPreferredLanguage('default');
      
      // 获取验证
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证设置成功
      expect(appLanguage).toBe('default');
      
      console.info('[Test] 设置default成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });

  it('should_clear_previous_setting', () => {
    try {
      // 先设置zh-Hans
      i18n.System.setAppPreferredLanguage('zh-Hans');
      const prevLanguage = i18n.System.getAppPreferredLanguage();
      expect(prevLanguage).toBe('zh-Hans');
      
      // 再设置default
      i18n.System.setAppPreferredLanguage('default');
      const currentLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证清除成功
      expect(currentLanguage).toBe('default');
      expect(currentLanguage).not.toBe(prevLanguage);
      
      console.info('[Test] 清除之前设置验证成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });
});