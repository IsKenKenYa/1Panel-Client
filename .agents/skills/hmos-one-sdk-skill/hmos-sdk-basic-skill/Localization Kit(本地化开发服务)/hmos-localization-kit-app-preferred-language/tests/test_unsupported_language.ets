/**
 * 测试用例: 异常测试 - 不支持的语言
 * 测试场景: 测试设置系统不支持语言的错误处理
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageUnsupportedLanguage', () => {
  it('should_throw_error_on_unsupported_language', () => {
    try {
      // 尝试设置不支持的语言
      i18n.System.setAppPreferredLanguage('xx-YY');
      
      // 不应该到达这里
      console.error('[Test] 设置不支持语言应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码为890001(参数无效)
      expect(err.code).toBe(890001);
      
      console.info(`[Test] 不支持语言错误处理成功: 错误码${err.code}`);
    }
  });

  it('should_handle_fallback_gracefully', () => {
    try {
      // 获取当前语言作为备份
      const currentLanguage = i18n.System.getAppPreferredLanguage();
      
      // 尝试设置不支持的语言
      try {
        i18n.System.setAppPreferredLanguage('unsupported-lang');
      } catch (setError) {
        const setErr: BusinessError = setError as BusinessError;
        console.info(`[Test] 设置失败: ${setErr.message}`);
      }
      
      // 验证语言未改变
      const languageAfter = i18n.System.getAppPreferredLanguage();
      expect(languageAfter).toBe(currentLanguage);
      
      console.info('[Test] 降级处理验证成功');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[Test] 测试失败: ${err.message}`);
      throw error;
    }
  });
});