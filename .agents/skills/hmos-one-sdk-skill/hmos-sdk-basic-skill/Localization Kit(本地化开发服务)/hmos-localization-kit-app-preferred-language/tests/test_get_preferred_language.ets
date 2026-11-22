/**
 * 测试用例: 获取应用偏好语言
 * 测试场景: 正向测试 - 成功获取当前应用偏好语言
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('GetAppPreferredLanguage', () => {
  it('should_return_current_preferred_language', () => {
    try {
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证返回值类型
      expect(typeof appLanguage).toBe('string');
      
      // 验证返回值不为空
      expect(appLanguage.length > 0).toBe(true);
      
      // 验证返回值格式(可能为default或合法语言ID)
      const isValidFormat = appLanguage === 'default' || 
                           /^[a-z]{2,3}(-[A-Z]{2})?(-[A-Z]{4})?$/.test(appLanguage);
      expect(isValidFormat).toBe(true);
      
      console.info(`[Test] 获取应用偏好语言成功: ${appLanguage}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });

  it('should_handle_default_language', () => {
    try {
      // 先设置default
      i18n.System.setAppPreferredLanguage('default');
      
      // 获取语言
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证返回default
      expect(appLanguage).toBe('default');
      
      console.info('[Test] 处理default语言成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });
});