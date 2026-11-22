import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 度量衡转换完整示例
 * 展示不同格式化风格和错误处理
 */

// 示例1：基本度量衡转换
function basicConversion(): void {
  console.log('=== 基本度量衡转换示例 ===');
  
  // 设置要转换的单位和目标单位
  const fromUnit: i18n.UnitInfo = { unit: 'cup', measureSystem: 'US' };
  const toUnit: i18n.UnitInfo = { unit: 'liter', measureSystem: 'SI' };
  
  // 简短格式转换（默认）
  const shortResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US');
  console.log('简短格式:', shortResult);  // 输出: "236.588 L"
  
  // 完整格式转换
  const longResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US', 'long');
  console.log('完整格式:', longResult);  // 输出: "236.588 liters"
  
  // 紧凑格式转换
  const narrowResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US', 'narrow');
  console.log('紧凑格式:', narrowResult);  // 输出: "236.588L"
}

// 示例2：不同度量体系的转换
function differentMeasureSystems(): void {
  console.log('=== 不同度量体系转换示例 ===');
  
  // 美制转公制：inch -> meter
  const inchToMeter = i18n.I18NUtil.unitConvert(
    { unit: 'inch', measureSystem: 'US' },
    { unit: 'meter', measureSystem: 'SI' },
    100,
    'zh-CN',
    'short'
  );
  console.log('100英寸转米:', inchToMeter);
  
  // 英制转公制：foot -> meter
  const footToMeter = i18n.I18NUtil.unitConvert(
    { unit: 'foot', measureSystem: 'UK' },
    { unit: 'meter', measureSystem: 'SI' },
    10,
    'en-GB',
    'long'
  );
  console.log('10英尺转米:', footToMeter);
  
  // 美制转公制：mile -> kilometer
  const mileToKm = i18n.I18NUtil.unitConvert(
    { unit: 'mile', measureSystem: 'US' },
    { unit: 'kilometer', measureSystem: 'SI' },
    5,
    'en-US',
    'short'
  );
  console.log('5英里转公里:', mileToKm);
}

// 示例3：不同区域ID的格式化效果
function differentLocales(): void {
  console.log('=== 不同区域ID格式化示例 ===');
  
  const fromUnit: i18n.UnitInfo = { unit: 'cup', measureSystem: 'US' };
  const toUnit: i18n.UnitInfo = { unit: 'liter', measureSystem: 'SI' };
  
  // 美式英语
  const usResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US', 'long');
  console.log('美式英语:', usResult);
  
  // 简体中文
  const cnResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'zh-CN', 'long');
  console.log('简体中文:', cnResult);
  
  // 德语
  const deResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'de-DE', 'long');
  console.log('德语:', deResult);
  
  // 日语
  const jpResult = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'ja-JP', 'long');
  console.log('日语:', jpResult);
}

// 示例4：带错误处理的转换
function conversionWithErrorHandling(): void {
  console.log('=== 错误处理示例 ===');
  
  try {
    const fromUnit: i18n.UnitInfo = { unit: 'cup', measureSystem: 'US' };
    const toUnit: i18n.UnitInfo = { unit: 'liter', measureSystem: 'SI' };
    
    const result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, 1000, 'en-US', 'short');
    console.log('转换成功:', result);
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('参数错误:', err.message);
        break;
      case 890001:
        console.error('无效参数:', err.message);
        break;
      default:
        console.error('未知错误:', err.code, err.message);
    }
  }
}

// 示例5：完整的转换函数（包含参数校验和降级处理）
async function safeConvertUnit(
  fromUnit: i18n.UnitInfo,
  toUnit: i18n.UnitInfo,
  value: number,
  locale: string,
  style: string = 'short'
): Promise<string> {
  console.log('=== 安全转换示例 ===');
  
  try {
    // 参数校验
    if (!fromUnit.unit || !fromUnit.measureSystem) {
      throw new Error('源单位信息不完整');
    }
    if (!toUnit.unit || !toUnit.measureSystem) {
      throw new Error('目标单位信息不完整');
    }
    if (typeof value !== 'number') {
      throw new Error('数值类型错误');
    }
    
    // 度量体系校验
    const validSystems = ['SI', 'US', 'UK'];
    if (!validSystems.includes(fromUnit.measureSystem)) {
      throw new Error(`不支持的度量体系: ${fromUnit.measureSystem}`);
    }
    if (!validSystems.includes(toUnit.measureSystem)) {
      throw new Error(`不支持的度量体系: ${toUnit.measureSystem}`);
    }
    
    // 格式化风格校验
    const validStyles = ['long', 'short', 'narrow'];
    if (!validStyles.includes(style)) {
      console.warn(`不支持的格式化风格: ${style}, 使用默认值'short'`);
      style = 'short';
    }
    
    // 调用API
    const result = i18n.I18NUtil.unitConvert(fromUnit, toUnit, value, locale, style);
    console.log(`转换成功: ${value} ${fromUnit.unit} -> ${result}`);
    return result;
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error('转换失败:', err.code, err.message);
    
    // 降级处理：返回原始值
    return `${value} ${fromUnit.unit}`;
  }
}

// 示例6：批量转换
function batchConversion(): void {
  console.log('=== 批量转换示例 ===');
  
  const conversions = [
    { from: { unit: 'cup', measureSystem: 'US' }, to: { unit: 'liter', measureSystem: 'SI' }, value: 100 },
    { from: { unit: 'inch', measureSystem: 'US' }, to: { unit: 'meter', measureSystem: 'SI' }, value: 50 },
    { from: { unit: 'mile', measureSystem: 'US' }, to: { unit: 'kilometer', measureSystem: 'SI' }, value: 10 },
    { from: { unit: 'pound', measureSystem: 'US' }, to: { unit: 'kilogram', measureSystem: 'SI' }, value: 25 },
  ];
  
  conversions.forEach((item, index) => {
    const result = i18n.I18NUtil.unitConvert(item.from, item.to, item.value, 'en-US', 'short');
    console.log(`转换${index + 1}: ${item.value} ${item.from.unit} = ${result}`);
  });
}

// 主函数 - 运行所有示例
export function runAllExamples(): void {
  console.log('\n===== 度量衡转换完整示例 =====\n');
  
  basicConversion();
  console.log('');
  
  differentMeasureSystems();
  console.log('');
  
  differentLocales();
  console.log('');
  
  conversionWithErrorHandling();
  console.log('');
  
  batchConversion();
  console.log('');
  
  // 异步示例
  safeConvertUnit(
    { unit: 'cup', measureSystem: 'US' },
    { unit: 'liter', measureSystem: 'SI' },
    500,
    'zh-CN',
    'long'
  ).then(result => {
    console.log('异步转换结果:', result);
  });
}

// 导出函数供其他模块使用
export {
  basicConversion,
  differentMeasureSystems,
  differentLocales,
  conversionWithErrorHandling,
  safeConvertUnit,
  batchConversion
};