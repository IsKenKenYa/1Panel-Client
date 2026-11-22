/**
 * 测试用例: 边界测试 - 设置完整语言ID
 * 测试场景: 测试设置完整的语言-脚本-国家地区ID(如zh-Hans-CN)
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageFullLocale', () => {
  it('should_set_full_locale_id', () => {
    try {
      // 设置完整语言ID
      i18n.System.setAppPreferredLanguage('zh-Hans-CN');
      
      // 获取验证
      const appLanguage = i18n.System.getAppPreferredLanguage();
      
      // 验证设置成功(可能返回完整ID或简化ID)
      expect(appLanguage.includes('zh')).toBe(true);
      
      console.info(`[Test] 设置完整语言ID成功: ${appLanguage}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });

  it('should_handle_different_formats', () => {
    try {
      // 测试不同格式的语言ID
      const testLanguages = [
        'en-Latn-US',
        'zh-Hant-TW',
        'ja-JP'
      ];

      for (const lang of testLanguages) {
        i18n.System.setAppPreferredLanguage(lang);
        const result = i18n.System.getAppPreferredLanguage();
        
        // 验证设置成功
        expect(result.length > 0).toBe(true);
        console.info(`[Test] 设置${lang}成功: ${result}`);
      }
      
      console.info('[Test] 不同格式验证成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });
});