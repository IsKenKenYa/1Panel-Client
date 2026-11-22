/**
 * 测试用例: 设置应用偏好语言为简体中文
 * 测试场景: 正向测试 - 成功设置应用偏好语言为zh-Hans
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageZhHans', () => {
  it('should_set_zh_hans_successfully', () => {
    try {
      // 设置为简体中文
      i18n.System.setAppPreferredLanguage('zh-Hans');
      
      // 获取验证
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证设置成功
      expect(appLanguage).toBe('zh-Hans');
      
      console.info('[Test] 设置zh-Hans成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });

  it('should_persist_language_setting', () => {
    try {
      // 设置zh-Hans
      i18n.System.setAppPreferredLanguage('zh-Hans');
      
      // 多次获取验证设置持久性
      const language1 = i18n.System.getAppPreferredLanguage();
      const language2 = i18n.System.getAppPreferredLanguage();
      
      expect(language1).toBe('zh-Hans');
      expect(language2).toBe('zh-Hans');
      expect(language1).toBe(language2);
      
      console.info('[Test] 语言设置持久化验证成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });
});