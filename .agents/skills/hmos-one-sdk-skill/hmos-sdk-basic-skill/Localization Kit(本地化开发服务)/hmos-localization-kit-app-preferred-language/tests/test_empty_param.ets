/**
 * 测试用例: 异常测试 - 空参数
 * 测试场景: 测试设置空语言参数的错误处理
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageEmptyParam', () => {
  it('should_throw_error_on_empty_string', () => {
    try {
      // 尝试设置空字符串
      i18n.System.setAppPreferredLanguage('');
      
      // 不应该到达这里
      console.error('[Test] 设置空字符串应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码为401(参数错误)
      expect(err.code).toBe(401);
      
      // 验证错误信息包含参数错误提示
      expect(err.message.includes('Parameter error')).toBe(true);
      
      console.info(`[Test] 空参数错误处理成功: 错误码${err.code}`);
    }
  });

  it('should_throw_error_on_whitespace_only', () => {
    try {
      // 尝试设置空白字符串
      i18n.System.setAppPreferredLanguage('   ');
      
      // 不应该到达这里
      console.error('[Test] 设置空白字符串应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码
      expect(err.code === 401 || err.code === 890001).toBe(true);
      
      console.info(`[Test] 空白参数错误处理成功: 错误码${err.code}`);
    }
  });
});