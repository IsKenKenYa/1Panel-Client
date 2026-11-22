/**
 * 数字与度量衡国际化完整示例
 * 展示unitConvert API的基本使用方法
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct UnitConvertExample {
  @State conversionResults: string[] = [];

  build() {
    Column() {
      Text('度量衡单位转换示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      // 展示转换结果
      ForEach(this.conversionResults, (result: string, index: number) => {
        Text(result)
          .fontSize(16)
          .margin({ top: 10 });
      });

      Button('执行单位转换')
        .fontSize(18)
        .margin({ top: 20 })
        .onClick(() => {
          this.performUnitConversions();
        });
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }

  /**
   * 执行多种单位转换示例
   */
  private performUnitConversions(): void {
    this.conversionResults = [];

    try {
      // 示例1: 美制cup转公制liter - 不同格式化风格
      this.convertWithDifferentStyles();

      // 示例2: 不同度量体系的单位转换
      this.convertDifferentSystems();

      // 示例3: 不同区域ID的格式化效果
      this.convertWithDifferentLocales();

      // 示例4: 常见单位转换场景
      this.commonConversionExamples();

    } catch (error) {
      let err: BusinessError = error as BusinessError;
      this.conversionResults.push(`错误: ${err.message}`);
    }
  }

  /**
   * 示例1: 不同格式化风格的对比
   */
  private convertWithDifferentStyles(): void {
    const fromUnit: i18n.UnitInfo = { unit: 'cup', measureSystem: 'US' };
    const toUnit: i18n.UnitInfo = { unit: 'liter', measureSystem: 'SI' };
    const value = 1000;
    const locale = 'en-US';

    // long风格: 显示完整单位名称
    let longResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, 'long');
    this.conversionResults.push(`[Long风格] 1000 cup = ${longResult}`);

    // short风格: 显示单位缩写(默认)
    let shortResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, 'short');
    this.conversionResults.push(`[Short风格] 1000 cup = ${shortResult}`);

    // narrow风格: 显示紧凑格式
    let narrowResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, 'narrow');
    this.conversionResults.push(`[Narrow风格] 1000 cup = ${narrowResult}`);
  }

  /**
   * 示例2: 不同度量体系的转换
   */
  private convertDifferentSystems(): void {
    // US美制 -> SI公制
    let usToSi = i18n.I18NUtil.unitConvert(
      { unit: 'inch', measureSystem: 'US' },
      { unit: 'meter', measureSystem: 'SI' },
      10,
      'en-US',
      'long'
    );
    this.conversionResults.push(`[US->SI] 10 inch = ${usToSi}`);

    // UK英制 -> SI公制
    let ukToSi = i18n.I18NUtil.unitConvert(
      { unit: 'pint', measureSystem: 'UK' },
      { unit: 'liter', measureSystem: 'SI' },
      5,
      'en-GB',
      'short'
    );
    this.conversionResults.push(`[UK->SI] 5 pint = ${ukToSi}`);
  }

  /**
   * 示例3: 不同区域ID的格式化效果
   */
  private convertWithDifferentLocales(): void {
    const fromUnit: i18n.UnitInfo = { unit: 'meter', measureSystem: 'SI' };
    const toUnit: i18n.UnitInfo = { unit: 'foot', measureSystem: 'US' };
    const value = 100;

    // 英语-美国区域
    let enUsResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, 'en-US', 'short');
    this.conversionResults.push(`[en-US] 100 meter = ${enUsResult}`);

    // 中文-中国区域
    let zhCnResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, 'zh-CN', 'short');
    this.conversionResults.push(`[zh-CN] 100 meter = ${zhCnResult}`);

    // 德语-德国区域
    let deDeResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, 'de-DE', 'short');
    this.conversionResults.push(`[de-DE] 100 meter = ${deDeResult}`);
  }

  /**
   * 示例4: 常见单位转换场景
   */
  private commonConversionExamples(): void {
    // 长度单位转换
    let lengthResult = i18n.I18NUtil.unitConvert(
      { unit: 'kilometer', measureSystem: 'SI' },
      { unit: 'mile', measureSystem: 'US' },
      5,
      'zh-CN',
      'long'
    );
    this.conversionResults.push(`[长度] 5 km = ${lengthResult}`);

    // 重量单位转换
    let weightResult = i18n.I18NUtil.unitConvert(
      { unit: 'pound', measureSystem: 'US' },
      { unit: 'kilogram', measureSystem: 'SI' },
      10,
      'zh-CN',
      'short'
    );
    this.conversionResults.push(`[重量] 10 pound = ${weightResult}`);

    // 温度单位转换(注意:温度转换可能需要特殊处理)
    // 本示例仅展示单位格式化,实际温度转换可能需要额外计算
    this.conversionResults.push(`[提示] 温度转换请参考i18n.TemperatureType`);
  }
}