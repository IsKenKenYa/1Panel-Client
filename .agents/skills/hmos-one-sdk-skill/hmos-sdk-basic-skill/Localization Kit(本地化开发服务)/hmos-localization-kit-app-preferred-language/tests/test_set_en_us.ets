/**
 * 测试用例: 设置应用偏好语言为英语
 * 测试场景: 正向测试 - 成功设置应用偏好语言为en-US
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageEnUS', () => {
  it('should_set_en_us_successfully', () => {
    try {
      // 设置为英语
      i18n.System.setAppPreferredLanguage('en-US');
      
      // 获取验证
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证设置成功
      expect(appLanguage).toBe('en-US');
      
      console.info('[Test] 设置en-US成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });

  it('should_switch_language_successfully', () => {
    try {
      // 先设置zh-Hans
      i18n.System.setAppPreferredLanguage('zh-Hans');
      expect(i18n.System.getAppPreferredLanguage()).toBe('zh-Hans');
      
      // 切换到en-US
      i18n.System.setAppPreferredLanguage('en-US');
      expect(i18n.System.getAppPreferredLanguage()).toBe('en-US');
      
      console.info('[Test] 语言切换验证成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });
});