/**
 * 测试用例: 异常测试 - 非法语言ID
 * 测试场景: 测试设置非法语言ID的错误处理
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageInvalidLanguage', () => {
  it('should_throw_error_on_invalid_format', () => {
    try {
      // 尝试设置非法格式
      i18n.System.setAppPreferredLanguage('invalid-language-123');
      
      // 不应该到达这里
      console.error('[Test] 设置非法格式应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码为890001(参数无效)
      expect(err.code).toBe(890001);
      
      // 验证错误信息包含参数无效提示
      expect(err.message.includes('Invalid parameter')).toBe(true);
      
      console.info(`[Test] 非法格式错误处理成功: 错误码${err.code}`);
    }
  });

  it('should_throw_error_on_numeric_id', () => {
    try {
      // 尝试设置数字ID
      i18n.System.setAppPreferredLanguage('12345');
      
      // 不应该到达这里
      console.error('[Test] 设置数字ID应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码
      expect(err.code === 401 || err.code === 890001).toBe(true);
      
      console.info(`[Test] 数字ID错误处理成功: 错误码${err.code}`);
    }
  });

  it('should_throw_error_on_special_chars', () => {
    try {
      // 尝试设置特殊字符
      i18n.System.setAppPreferredLanguage('@#$%');
      
      // 不应该到达这里
      console.error('[Test] 设置特殊字符应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码
      expect(err.code === 401 || err.code === 890001).toBe(true);
      
      console.info(`[Test] 特殊字符错误处理成功: 错误码${err.code}`);
    }
  });
});