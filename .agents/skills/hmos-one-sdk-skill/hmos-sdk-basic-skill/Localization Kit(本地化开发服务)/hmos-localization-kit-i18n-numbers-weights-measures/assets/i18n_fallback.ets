/**
 * 数字与度量衡国际化 - 降级处理示例
 * 展示如何在API调用失败时进行友好的降级处理
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct FallbackExample {
  @State conversionResults: string[] = [];

  build() {
    Column() {
      Text('降级处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      ForEach(this.conversionResults, (result: string, index: number) => {
        Text(result)
          .fontSize(14)
          .margin({ top: 5 });
      });

      Button('执行降级测试')
        .fontSize(18)
        .margin({ top: 20 })
        .onClick(() => {
          this.testFallbackStrategies();
        });
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }

  /**
   * 测试各种降级策略
   */
  private testFallbackStrategies(): void {
    this.conversionResults = [];
    this.conversionResults.push('开始降级处理测试...\n');

    // 策略1: 区域ID降级
    this.localeFallbackStrategy();

    // 策略2: 格式化风格降级
    this.styleFallbackStrategy();

    // 策略3: 单位转换失败降级
    this.unitFallbackStrategy();

    // 策略4: 多级降级策略
    this.multiLevelFallbackStrategy();

    // 策略5: 最终降级方案
    this.finalFallbackStrategy();

    this.conversionResults.push('\n降级处理测试完成');
  }

  /**
   * 策略1: 区域ID降级
   * 当用户区域ID失败时,尝试使用默认区域ID
   */
  private localeFallbackStrategy(): void {
    this.conversionResults.push('\n[策略1] 区域ID降级:');
    
    const convertWithLocaleFallback = (
      fromUnit: i18n.UnitInfo,
      toUnit: i18n.UnitInfo,
      value: number,
      userLocale?: string
    ): string => {
      const defaultLocale = 'en-US';
      const fallbackLocale = 'zh-CN';
      const locale = userLocale || defaultLocale;

      try {
        // 尝试使用用户指定的区域ID
        let result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, 'short');
        this.conversionResults.push(`✓ 成功使用区域: ${locale}`);
        return result;
        
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        this.conversionResults.push(`区域 ${locale} 失败: ${err.message}`);

        // 降级到默认区域ID
        this.conversionResults.push(`降级尝试: ${defaultLocale}`);
        try {
          let result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, defaultLocale, 'short');
          this.conversionResults.push(`✓ 降级成功: ${result}`);
          return result;
        } catch (fallbackError) {
          // 再次降级到中文区域
          this.conversionResults.push(`再次降级: ${fallbackLocale}`);
          try {
            let result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, fallbackLocale, 'short');
            this.conversionResults.push(`✓ 最终降级成功: ${result}`);
            return result;
          } catch (finalError) {
            this.conversionResults.push('✗ 所有区域尝试失败');
            return value.toString();
          }
        }
      }
    };

    // 测试有效区域
    let validResult = convertWithLocaleFallback(
      { unit: 'cup', measureSystem: 'US' },
      { unit: 'liter', measureSystem: 'SI' },
      1000,
      'en-US'
    );
    this.conversionResults.push(`结果: ${validResult}`);

    // 测试可能失败的区域(某些特殊区域可能不支持)
    this.conversionResults.push('\n测试特殊区域:');
    let specialResult = convertWithLocaleFallback(
      { unit: 'cup', measureSystem: 'US' },
      { unit: 'liter', measureSystem: 'SI' },
      1000,
      'xx-YY'  // 无效区域测试
    );
    this.conversionResults.push(`结果(降级): ${specialResult}`);
  }

  /**
   * 策略2: 格式化风格降级
   * 当指定风格失败时,尝试使用默认风格
   */
  private styleFallbackStrategy(): void {
    this.conversionResults.push('\n[策略2] 格式化风格降级:');
    
    const convertWithStyleFallback = (
      fromUnit: i18n.UnitInfo,
      toUnit: i18n.UnitInfo,
      value: number,
      locale: string,
      preferredStyle?: string
    ): string => {
      const defaultStyle = 'short';
      const styles = preferredStyle ? [preferredStyle, defaultStyle] : [defaultStyle];

      for (let style of styles) {
        try {
          let result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, style);
          this.conversionResults.push(`✓ 使用风格: ${style} -> ${result}`);
          return result;
        } catch (error) {
          let err: BusinessError = error as BusinessError;
          this.conversionResults.push(`风格 ${style} 失败,尝试下一个`);
        }
      }

      // 所有风格都失败,返回原始值
      this.conversionResults.push('✗ 所有风格尝试失败');
      return value.toString();
    };

    // 测试不同风格
    let longResult = convertWithStyleFallback(
      { unit: 'cup', measureSystem: 'US' },
      { unit: 'liter', measureSystem: 'SI' },
      1000,
      'en-US',
      'long'
    );
  }

  /**
   * 策略3: 单位转换失败降级
   * 当单位转换失败时,提示用户并提供原始值
   */
  private unitFallbackStrategy(): void {
    this.conversionResults.push('\n[策略3] 单位转换失败降级:');
    
    const convertWithUnitFallback = (
      fromUnit: i18n.UnitInfo,
      toUnit: i18n.UnitInfo,
      value: number,
      locale: string
    ): { result: string; success: boolean; message: string } => {
      try {
        // 参数校验
        const validSystems = ['SI', 'US', 'UK'];
        if (!validSystems.includes(fromUnit.measureSystem)) {
          return {
            result: value.toString(),
            success: false,
            message: `不支持的度量体系: ${fromUnit.measureSystem}`
          };
        }

        if (!validSystems.includes(toUnit.measureSystem)) {
          return {
            result: value.toString(),
            success: false,
            message: `不支持的度量体系: ${toUnit.measureSystem}`
          };
        }

        // 执行转换
        let result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, 'short');
        return {
          result: result,
          success: true,
          message: '转换成功'
        };
        
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        
        if (err.code === 890001) {
          return {
            result: value.toString(),
            success: false,
            message: `单位转换失败: 单位名称或度量体系无效`
          };
        }
        
        return {
          result: value.toString(),
          success: false,
          message: `未知错误: ${err.message}`
        };
      }
    };

    // 测试有效单位
    let validConversion = convertWithUnitFallback(
      { unit: 'cup', measureSystem: 'US' },
      { unit: 'liter', measureSystem: 'SI' },
      1000,
      'en-US'
    );
    this.conversionResults.push(`有效单位: ${validConversion.message} - ${validConversion.result}`);

    // 测试无效单位(模拟)
    this.conversionResults.push('\n测试无效单位处理:');
    let invalidConversion = convertWithUnitFallback(
      { unit: 'invalid', measureSystem: 'US' },
      { unit: 'liter', measureSystem: 'SI' },
      1000,
      'en-US'
    );
    this.conversionResults.push(`无效单位: ${invalidConversion.message} - ${invalidConversion.result}`);
  }

  /**
   * 策略4: 多级降级策略
   * 按优先级依次尝试多种降级方案
   */
  private multiLevelFallbackStrategy(): void {
    this.conversionResults.push('\n[策略4] 多级降级策略:');
    
    enum FallbackLevel {
      PRIMARY = '用户首选配置',
      SECONDARY = '系统默认配置',
      TERTIARY = '通用降级配置',
      FINAL = '返回原始值'
    }

    const convertWithMultiLevelFallback = (
      fromUnit: i18n.UnitInfo,
      toUnit: i18n.UnitInfo,
      value: number,
      preferredLocale?: string,
      preferredStyle?: string
    ): string => {
      const configs = [
        { locale: preferredLocale || 'en-US', style: preferredStyle || 'long', level: FallbackLevel.PRIMARY },
        { locale: 'en-US', style: 'short', level: FallbackLevel.SECONDARY },
        { locale: 'zh-CN', style: 'short', level: FallbackLevel.TERTIARY }
      ];

      for (let config of configs) {
        try {
          this.conversionResults.push(`尝试: ${config.level} (${config.locale}, ${config.style})`);
          let result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, config.locale, config.style);
          this.conversionResults.push(`✓ ${config.level}成功: ${result}`);
          return result;
        } catch (error) {
          let err: BusinessError = error as BusinessError;
          this.conversionResults.push(`✗ ${config.level}失败: ${err.message}`);
        }
      }

      // 最终降级: 返回原始数值
      this.conversionResults.push(`最终降级: ${FallbackLevel.FINAL}`);
      return `${value} ${fromUnit.unit}`;
    };

    // 测试多级降级
    let result = convertWithMultiLevelFallback(
      { unit: 'cup', measureSystem: 'US' },
      { unit: 'liter', measureSystem: 'SI' },
      1000,
      'en-US',
      'long'
    );
    this.conversionResults.push(`\n最终结果: ${result}`);
  }

  /**
   * 策略5: 最终降级方案
   * 当所有API调用都失败时的兜底处理
   */
  private finalFallbackStrategy(): void {
    this.conversionResults.push('\n[策略5] 最终降级方案:');
    
    const safeConvert = (
      fromUnit: i18n.UnitInfo,
      toUnit: i18n.UnitInfo,
      value: number
    ): string => {
      try {
        // 尝试使用最安全的配置
        return i18n.I18NUtil.unitConvert(
          fromUnit,
          toUnit,
          value,
          'en-US',  // 最通用的区域
          'short'   // 最简单的风格
        );
      } catch (error) {
        // 所有尝试都失败,提供友好的降级显示
        this.conversionResults.push('API调用失败,使用友好降级');
        
        // 降级方案1: 显示原始单位和数值
        let fallback1 = `${value} ${fromUnit.unit}`;
        this.conversionResults.push(`降级方案1: ${fallback1}`);
        
        // 降级方案2: 提供提示信息
        let fallback2 = `${value} (单位转换不可用)`;
        this.conversionResults.push(`降级方案2: ${fallback2}`);
        
        // 降级方案3: 鼠标悬停提示(在UI中实现)
        this.conversionResults.push(`降级方案3: 提供悬停提示 "原始单位: ${fromUnit.unit}"`);
        
        return fallback1;
      }
    };

    // 测试安全转换
    let safeResult = safeConvert(
      { unit: 'cup', measureSystem: 'US' },
      { unit: 'liter', measureSystem: 'SI' },
      1000
    );
    this.conversionResults.push(`安全转换结果: ${safeResult}`);
  }
}