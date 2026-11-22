/**
 * 测试用例: 边界测试 - 获取未设置的语言
 * 测试场景: 测试获取未设置偏好语言时的返回值
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('GetAppPreferredLanguageUnset', () => {
  it('should_return_default_when_unset', () => {
    try {
      // 先清除偏好语言
      i18n.System.setAppPreferredLanguage('default');
      
      // 获取语言
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证返回default
      expect(appLanguage).toBe('default');
      
      console.info('[Test] 未设置时返回default验证成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });

  it('should_return_valid_string', () => {
    try {
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证返回值始终是字符串
      expect(typeof appLanguage).toBe('string');
      expect(appLanguage.length > 0).toBe(true);
      
      console.info('[Test] 返回值类型验证成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });
});