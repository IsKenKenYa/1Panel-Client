/**
 * 获取国家/地区名称在指定语言环境下的翻译
 * 
 * 功能说明：
 * - 调用i18n.System.getDisplayCountry获取国家/地区名称的本地化翻译
 * - 支持全球200+个国家和地区的翻译
 * - 可控制首字母大小写格式
 * 
 * 使用场景：
 * - 应用国际化国家选择界面
 * - 地区设置页面显示
 * - 多语言环境下的国家/地区名称展示
 * 
 * @since API version 9
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 获取国家/地区名称在指定语言环境下的翻译
 * 
 * @param country 国家地区码，如'CN'、'US'、'DE'、'SA'
 * @param locale 区域ID，如'en-GB'、'zh-Hans-CN'、'ja-JP'
 * @param sentenceCase 是否首字母大写，默认true
 * @returns 国家/地区名称的翻译
 * @throws {BusinessError} 参数错误(401)或参数无效(890001)
 * 
 * @example
 * // 获取沙特阿拉伯在英文环境下的名称
 * const saName = getCountryDisplayName('SA', 'en-GB');
 * console.log(saName); // 输出: Saudi Arabia
 * 
 * // 获取中国在中文环境下的名称
 * const cnName = getCountryDisplayName('CN', 'zh-Hans-CN');
 * console.log(cnName); // 输出: 中国
 */
function getCountryDisplayName(
  country: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 参数校验
    if (!country || !locale) {
      throw new Error('参数错误：国家地区码和区域ID不能为空');
    }
    
    // 调用系统API获取国家/地区名称翻译
    const displayCountry: string = i18n.System.getDisplayCountry(country, locale, sentenceCase);
    console.log(`国家/地区 ${country} 在 ${locale} 环境下显示为: ${displayCountry}`);
    return displayCountry;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`获取国家/地区名称失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    throw error;
  }
}

/**
 * 批量获取多个国家/地区在同一区域环境下的翻译
 * 
 * @param countries 国家地区码数组
 * @param locale 目标区域ID
 * @param sentenceCase 是否首字母大写，默认true
 * @returns 国家/地区名称翻译的Map对象
 * 
 * @example
 * const countries = ['CN', 'US', 'DE', 'FR', 'JP'];
 * const names = getMultipleCountryDisplayNames(countries, 'zh-Hans-CN');
 * names.forEach((name, country) => {
 *   console.log(`${country}: ${name}`);
 * });
 */
function getMultipleCountryDisplayNames(
  countries: string[],
  locale: string,
  sentenceCase: boolean = true
): Map<string, string> {
  const resultMap = new Map<string, string>();
  
  for (const country of countries) {
    try {
      const displayName = i18n.System.getDisplayCountry(country, locale, sentenceCase);
      resultMap.set(country, displayName);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取国家/地区 ${country} 的名称失败: ${err.message}`);
      resultMap.set(country, country); // 失败时使用原始国家地区码
    }
  }
  
  return resultMap;
}

/**
 * 安全获取国家/地区名称翻译（带降级处理）
 * 
 * @param country 国家地区码
 * @param locale 区域ID
 * @param sentenceCase 是否首字母大写
 * @returns 国家/地区名称翻译，失败时返回原始国家地区码
 */
function safeGetCountryDisplayName(
  country: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    const displayName = i18n.System.getDisplayCountry(country, locale, sentenceCase);
    return displayName;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    // 降级方案1：尝试使用默认区域ID
    if (locale !== 'en-US') {
      try {
        console.warn(`使用区域ID ${locale} 失败，尝试使用 en-US 作为默认值`);
        const fallbackName = i18n.System.getDisplayCountry(country, 'en-US', sentenceCase);
        return fallbackName;
      } catch (fallbackError) {
        console.warn('降级方案1失败');
      }
    }
    
    // 降级方案2：返回原始国家地区码
    console.warn(`无法获取国家/地区 ${country} 的翻译，返回原始国家地区码`);
    return country.toUpperCase();
  }
}

/**
 * 获取国家名称在不同语言环境下的翻译对比
 * 
 * @param country 国家地区码
 * @param locales 区域ID数组
 * @returns 不同语言环境下的国家名称Map
 */
function getCountryNameInDifferentLocales(
  country: string,
  locales: string[]
): Map<string, string> {
  const resultMap = new Map<string, string>();
  
  for (const locale of locales) {
    try {
      const displayName = i18n.System.getDisplayCountry(country, locale, true);
      resultMap.set(locale, displayName);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`获取国家 ${country} 在 ${locale} 环境下的名称失败: ${err.message}`);
      resultMap.set(locale, country);
    }
  }
  
  return resultMap;
}

// 示例用法
function main(): void {
  console.log('=== 获取国家/地区名称翻译示例 ===\n');
  
  // 示例1：获取单个国家/地区的翻译
  console.log('示例1：获取单个国家/地区的翻译');
  try {
    const saInEnglish = getCountryDisplayName('SA', 'en-GB');
    console.log(`沙特阿拉伯在英文环境下显示为: ${saInEnglish}`);
    
    const cnInChinese = getCountryDisplayName('CN', 'zh-Hans-CN');
    console.log(`中国在中文环境下显示为: ${cnInChinese}`);
    
    const jpInJapanese = getCountryDisplayName('JP', 'ja-JP');
    console.log(`日本在日文环境下显示为: ${jpInJapanese}`);
  } catch (error) {
    console.error('示例1执行失败');
  }
  
  // 示例2：批量获取多个国家/地区的翻译
  console.log('\n示例2：批量获取多个国家/地区的翻译');
  const countries = ['CN', 'US', 'DE', 'FR', 'JP', 'KR', 'GB', 'SA'];
  const countryNames = getMultipleCountryDisplayNames(countries, 'zh-Hans-CN');
  
  console.log('在简体中文环境下各国家/地区的名称：');
  countryNames.forEach((name, country) => {
    console.log(`  ${country}: ${name}`);
  });
  
  // 示例3：安全获取（带降级处理）
  console.log('\n示例3：安全获取国家/地区名称（带降级处理）');
  const safeName = safeGetCountryDisplayName('invalid-code', 'zh-Hans-CN');
  console.log(`安全获取结果: ${safeName}`);
  
  // 示例4：同一国家在不同语言环境下的名称对比
  console.log('\n示例4：同一国家在不同语言环境下的名称对比');
  const locales = ['zh-Hans-CN', 'en-US', 'ja-JP', 'de-DE', 'fr-FR'];
  const chinaNames = getCountryNameInDifferentLocales('CN', locales);
  
  console.log('中国在不同语言环境下的名称：');
  chinaNames.forEach((name, locale) => {
    console.log(`  ${locale}: ${name}`);
  });
  
  // 示例5：不同大小写格式
  console.log('\n示例5：不同大小写格式');
  const nameWithCap = getCountryDisplayName('SA', 'en-GB', true);
  const nameWithoutCap = getCountryDisplayName('SA', 'en-GB', false);
  console.log(`首字母大写: ${nameWithCap}`);
  console.log(`默认格式: ${nameWithoutCap}`);
}

// 执行示例
main();