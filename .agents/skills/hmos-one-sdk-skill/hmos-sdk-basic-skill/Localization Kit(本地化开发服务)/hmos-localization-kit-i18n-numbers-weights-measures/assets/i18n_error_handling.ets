/**
 * 数字与度量衡国际化 - 错误处理示例
 * 展示如何正确处理API调用中的各种错误情况
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct ErrorHandlingExample {
  @State errorLogs: string[] = [];

  build() {
    Column() {
      Text('错误处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      ForEach(this.errorLogs, (log: string, index: number) => {
        Text(log)
          .fontSize(14)
          .margin({ top: 5 })
          .fontColor(index % 2 === 0 ? '#000000' : '#FF0000');
      });

      Button('执行错误测试')
        .fontSize(18)
        .margin({ top: 20 })
        .onClick(() => {
          this.testErrorHandling();
        });
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }

  /**
   * 执行各种错误场景测试
   */
  private testErrorHandling(): void {
    this.errorLogs = [];
    this.errorLogs.push('开始错误处理测试...\n');

    // 测试1: 无效单位名称
    this.testInvalidUnitName();

    // 测试2: 无效度量体系
    this.testInvalidMeasureSystem();

    // 测试3: 无效区域ID
    this.testInvalidLocale();

    // 测试4: 缺失参数
    this.testMissingParameters();

    // 测试5: 参数类型错误
    this.testInvalidParameterTypes();

    this.errorLogs.push('\n错误处理测试完成');
  }

  /**
   * 测试无效单位名称 - 错误码890001
   */
  private testInvalidUnitName(): void {
    this.errorLogs.push('\n[测试1] 无效单位名称:');
    this.errorLogs.push('尝试转换: invalid_unit -> liter');

    try {
      let result = i18n.I18NUtil.unitConvert(
        { unit: 'invalid_unit', measureSystem: 'US' },
        { unit: 'liter', measureSystem: 'SI' },
        100,
        'en-US'
      );
      this.errorLogs.push(`成功(意外): ${result}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.errorLogs.push(`✓ 捕获错误: ${err.code} - ${err.message}`);
      
      if (err.code === 890001) {
        this.errorLogs.push('✓ 错误码验证成功: Invalid parameter');
      }
    }
  }

  /**
   * 测试无效度量体系 - 错误码890001
   */
  private testInvalidMeasureSystem(): void {
    this.errorLogs.push('\n[测试2] 无效度量体系:');
    this.errorLogs.push('尝试使用: INVALID_SYSTEM');

    try {
      let result = i18n.I18NUtil.unitConvert(
        { unit: 'cup', measureSystem: 'INVALID_SYSTEM' },
        { unit: 'liter', measureSystem: 'SI' },
        100,
        'en-US'
      );
      this.errorLogs.push(`成功(意外): ${result}`);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.errorLogs.push(`✓ 捕获错误: ${err.code} - ${err.message}`);
      
      if (err.code === 890001) {
        this.errorLogs.push('✓ 错误码验证成功: Invalid measure system');
      }
    }
  }

  /**
   * 测试无效区域ID - 可能降级处理
   */
  private testInvalidLocale(): void {
    this.errorLogs.push('\n[测试3] 无效区域ID:');
    this.errorLogs.push('尝试使用: INVALID_LOCALE');

    try {
      let result = i18n.I18NUtil.unitConvert(
        { unit: 'cup', measureSystem: 'US' },
        { unit: 'liter', measureSystem: 'SI' },
        100,
        'INVALID_LOCALE'
      );
      this.errorLogs.push(`结果: ${result}`);
      this.errorLogs.push('提示: 某些无效locale可能被降级处理');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.errorLogs.push(`✓ 捕获错误: ${err.code} - ${err.message}`);
    }
  }

  /**
   * 测试缺失参数 - 错误码401
   */
  private testMissingParameters(): void {
    this.errorLogs.push('\n[测试4] 缺失参数:');
    this.errorLogs.push('尝试缺少style参数(可选参数)');

    try {
      // style参数是可选的,应该可以正常工作
      let result = i18n.I18NUtil.unitConvert(
        { unit: 'cup', measureSystem: 'US' },
        { unit: 'liter', measureSystem: 'SI' },
        100,
        'en-US'
        // 不传style参数
      );
      this.errorLogs.push(`✓ 成功(可选参数): ${result}`);
      this.errorLogs.push('提示: style是可选参数,默认值为short');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.errorLogs.push(`捕获错误: ${err.code} - ${err.message}`);
    }

    // 测试缺少必填参数(需要在调用前校验)
    this.errorLogs.push('\n尝试缺少必填参数locale:');
    
    // 无法直接测试缺少必填参数,TypeScript会编译报错
    // 需要在代码层面进行参数校验
    this.errorLogs.push('提示: TypeScript会在编译时检查必填参数');
    this.errorLogs.push('建议: 在调用前手动校验参数完整性');
  }

  /**
   * 测试参数类型错误 - 错误码401
   */
  private testInvalidParameterTypes(): void {
    this.errorLogs.push('\n[测试5] 参数类型错误:');
    this.errorLogs.push('尝试传入错误类型的value');

    try {
      // TypeScript会在编译时检查类型
      // 以下代码在实际编译时会报错
      // let result = i18n.I18NUtil.unitConvert(
      //   { unit: 'cup', measureSystem: 'US' },
      //   { unit: 'liter', measureSystem: 'SI' },
      //   'invalid_type',  // 应为number
      //   'en-US'
      // );
      
      this.errorLogs.push('提示: TypeScript会在编译时阻止类型错误');
      this.errorLogs.push('建议: 使用明确的类型定义');
      
      // 模拟运行时类型错误
      let invalidValue: any = 'not_a_number';
      if (typeof invalidValue !== 'number') {
        this.errorLogs.push('✓ 参数校验成功: 检测到value不是number类型');
      }
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.errorLogs.push(`捕获错误: ${err.code} - ${err.message}`);
    }
  }

  /**
   * 完整的错误处理函数模板
   */
  private convertUnitWithErrorHandling(
    fromUnit: i18n.UnitInfo,
    toUnit: i18n.UnitInfo,
    value: number,
    locale: string,
    style?: string
  ): string {
    try {
      // 参数校验
      if (typeof value !== 'number' || isNaN(value)) {
        throw new Error('Invalid value: must be a valid number');
      }
      
      if (!fromUnit.unit || !fromUnit.measureSystem) {
        throw new Error('Invalid fromUnit: unit and measureSystem are required');
      }
      
      if (!toUnit.unit || !toUnit.measureSystem) {
        throw new Error('Invalid toUnit: unit and measureSystem are required');
      }
      
      if (!locale) {
        throw new Error('Invalid locale: locale is required');
      }
      
      // 度量体系校验
      const validSystems = ['SI', 'US', 'UK'];
      if (!validSystems.includes(fromUnit.measureSystem) || 
          !validSystems.includes(toUnit.measureSystem)) {
        throw new Error('Invalid measureSystem: must be SI, US, or UK');
      }
      
      // 执行转换
      return i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, style);
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      
      if (err.code === 401) {
        this.errorLogs.push('错误401: 参数缺失或类型错误');
        throw new Error('Invalid parameters provided');
      }
      
      if (err.code === 890001) {
        this.errorLogs.push('错误890001: 参数验证失败');
        throw new Error('Parameter validation failed');
      }
      
      this.errorLogs.push(`未知错误: ${err.message}`);
      throw error;
    }
  }
}