/**
 * 本地化语言与地区名称完整示例
 * 功能：演示如何使用i18n.System API获取语言和国家地区名称的本地化翻译
 * API: getDisplayLanguage, getDisplayCountry
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 获取语言名称的本地化翻译
 * @param language 语言代码，如'zh', 'en', 'de'
 * @param locale 区域ID，如'zh-Hans-CN', 'en-GB'
 * @param sentenceCase 首字母是否大写，默认true
 * @returns 翻译后的语言名称
 */
function getLocalizedLanguageName(
  language: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 参数校验
    if (!language || language.trim().length === 0) {
      console.error('语言代码不能为空');
      return '';
    }
    
    if (!locale || locale.trim().length === 0) {
      console.error('区域ID不能为空');
      return '';
    }
    
    // 调用API获取翻译
    const displayLanguage = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
    
    console.info(`语言 ${language} 在 ${locale} 下显示为: ${displayLanguage}`);
    return displayLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`调用getDisplayLanguage失败，错误码: ${err.code}, 消息: ${err.message}`);
    
    // 降级处理：返回原始语言代码
    return language;
  }
}

/**
 * 获取国家地区名称的本地化翻译
 * @param country 国家地区代码，如'CN', 'DE', 'SA'
 * @param locale 区域ID，如'zh-Hans-CN', 'en-GB'
 * @param sentenceCase 首字母是否大写，默认true
 * @returns 翻译后的国家地区名称
 */
function getLocalizedCountryName(
  country: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 参数校验
    if (!country || country.trim().length === 0) {
      console.error('国家地区代码不能为空');
      return '';
    }
    
    if (!locale || locale.trim().length === 0) {
      console.error('区域ID不能为空');
      return '';
    }
    
    // 调用API获取翻译
    const displayCountry = i18n.System.getDisplayCountry(country, locale, sentenceCase);
    
    console.info(`国家地区 ${country} 在 ${locale} 下显示为: ${displayCountry}`);
    return displayCountry;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`调用getDisplayCountry失败，错误码: ${err.code}, 消息: ${err.message}`);
    
    // 降级处理：返回原始国家地区代码
    return country;
  }
}

/**
 * 批量获取语言列表的本地化名称
 * @param languages 语言代码列表
 * @param locale 目标区域ID
 * @returns 翻译后的语言名称映射表
 */
function getLocalizedLanguageList(
  languages: Array<string>,
  locale: string
): Map<string, string> {
  const resultMap = new Map<string, string>();
  
  for (const language of languages) {
    const displayName = getLocalizedLanguageName(language, locale);
    resultMap.set(language, displayName);
  }
  
  return resultMap;
}

/**
 * 批量获取国家地区列表的本地化名称
 * @param countries 国家地区代码列表
 * @param locale 目标区域ID
 * @returns 翻译后的国家地区名称映射表
 */
function getLocalizedCountryList(
  countries: Array<string>,
  locale: string
): Map<string, string> {
  const resultMap = new Map<string, string>();
  
  for (const country of countries) {
    const displayName = getLocalizedCountryName(country, locale);
    resultMap.set(country, displayName);
  }
  
  return resultMap;
}

/**
 * 创建语言选择器数据
 * @param locale 目标区域ID
 * @returns 语言选择器数据列表
 */
function createLanguagePickerData(locale: string): Array<{code: string, name: string}> {
  // 获取系统支持的语言列表
  const systemLanguages = i18n.System.getSystemLanguages();
  
  const pickerData: Array<{code: string, name: string}> = [];
  
  for (const language of systemLanguages) {
    const displayName = getLocalizedLanguageName(language, locale);
    pickerData.push({
      code: language,
      name: displayName
    });
  }
  
  return pickerData;
}

/**
 * 创建地区选择器数据
 * @param language 目标语言代码
 * @param locale 目标区域ID
 * @returns 地区选择器数据列表
 */
function createCountryPickerData(
  language: string,
  locale: string
): Array<{code: string, name: string}> {
  // 获取指定语言下系统支持的国家地区列表
  const systemCountries = i18n.System.getSystemCountries(language);
  
  const pickerData: Array<{code: string, name: string}> = [];
  
  for (const country of systemCountries) {
    const displayName = getLocalizedCountryName(country, locale);
    pickerData.push({
      code: country,
      name: displayName
    });
  }
  
  return pickerData;
}

/**
 * 主函数：演示完整的使用场景
 */
function main(): void {
  console.info('=== 本地化语言与地区名称示例 ===');
  
  // 示例1: 获取语言名称翻译
  console.info('\n示例1: 获取语言名称翻译');
  const languageZh = getLocalizedLanguageName('de', 'zh-Hans-CN'); // 德文
  const languageEn = getLocalizedLanguageName('zh', 'en-GB');      // Chinese
  const languageFr = getLocalizedLanguageName('fr', 'zh-Hans-CN'); // 法文
  
  console.info(`德语在中文下显示: ${languageZh}`);
  console.info(`中文在英文下显示: ${languageEn}`);
  console.info(`法语在中文下显示: ${languageFr}`);
  
  // 示例2: 获取国家地区名称翻译
  console.info('\n示例2: 获取国家地区名称翻译');
  const countryZh = getLocalizedCountryName('SA', 'zh-Hans-CN'); // 沙特阿拉伯
  const countryEn = getLocalizedCountryName('CN', 'en-GB');      // China
  const countryDe = getLocalizedCountryName('DE', 'zh-Hans-CN'); // 德国
  
  console.info(`沙特阿拉伯在中文下显示: ${countryZh}`);
  console.info(`中国在英文下显示: ${countryEn}`);
  console.info(`德国在中文下显示: ${countryDe}`);
  
  // 示例3: 测试首字母大小写
  console.info('\n示例3: 测试首字母大小写');
  const languageUpper = getLocalizedLanguageName('de', 'en-GB', true);  // German
  const languageLower = getLocalizedLanguageName('de', 'en-GB', false); // german
  
  console.info(`首字母大写: ${languageUpper}`);
  console.info(`原始大小写: ${languageLower}`);
  
  // 示例4: 批量获取语言列表
  console.info('\n示例4: 批量获取语言列表');
  const languages = ['zh', 'en', 'de', 'fr', 'ja'];
  const languageMap = getLocalizedLanguageList(languages, 'zh-Hans-CN');
  
  for (const [code, name] of languageMap) {
    console.info(`${code} -> ${name}`);
  }
  
  // 示例5: 批量获取国家地区列表
  console.info('\n示例5: 批量获取国家地区列表');
  const countries = ['CN', 'US', 'DE', 'JP', 'SA'];
  const countryMap = getLocalizedCountryList(countries, 'zh-Hans-CN');
  
  for (const [code, name] of countryMap) {
    console.info(`${code} -> ${name}`);
  }
  
  // 示例6: 创建语言选择器
  console.info('\n示例6: 创建语言选择器');
  const languagePickerData = createLanguagePickerData('zh-Hans-CN');
  console.info(`语言选择器数据项数: ${languagePickerData.length}`);
  
  // 示例7: 创建地区选择器
  console.info('\n示例7: 创建地区选择器');
  const countryPickerData = createCountryPickerData('zh', 'zh-Hans-CN');
  console.info(`地区选择器数据项数: ${countryPickerData.length}`);
  
  console.info('\n=== 示例执行完成 ===');
}

// 执行主函数
main();