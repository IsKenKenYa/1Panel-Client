/**
 * 测试用例: 异常测试 - 类型错误
 * 测试场景: 测试参数类型错误的处理
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

describe('SetAppPreferredLanguageWrongType', () => {
  it('should_throw_error_on_number_param', () => {
    try {
      // 尝试设置数字类型参数(需要类型转换)
      // TypeScript会阻止这种错误,这里模拟运行时错误
      const wrongParam: any = 123;
      i18n.System.setAppPreferredLanguage(wrongParam);
      
      // 不应该到达这里
      console.error('[Test] 设置数字类型应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码为401(参数错误)
      expect(err.code).toBe(401);
      
      console.info(`[Test] 数字类型错误处理成功: 错误码${err.code}`);
    }
  });

  it('should_throw_error_on_null_param', () => {
    try {
      // 尝试设置null参数
      const nullParam: any = null;
      i18n.System.setAppPreferredLanguage(nullParam);
      
      // 不应该到达这里
      console.error('[Test] 设置null应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码为401(参数错误)
      expect(err.code).toBe(401);
      
      console.info(`[Test] null参数错误处理成功: 错误码${err.code}`);
    }
  });

  it('should_throw_error_on_undefined_param', () => {
    try {
      // 尝试设置undefined参数
      const undefinedParam: any = undefined;
      i18n.System.setAppPreferredLanguage(undefinedParam);
      
      // 不应该到达这里
      console.error('[Test] 设置undefined应该抛出错误');
      throw new Error('Expected error not thrown');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      // 验证错误码为401(参数错误)
      expect(err.code).toBe(401);
      
      console.info(`[Test] undefined参数错误处理成功: 错误码${err.code}`);
    }
  });
});