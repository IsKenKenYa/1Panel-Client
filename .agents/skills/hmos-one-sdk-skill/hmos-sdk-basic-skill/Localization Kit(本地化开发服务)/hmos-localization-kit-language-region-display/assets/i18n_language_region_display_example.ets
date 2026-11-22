/**
 * 本地化语言与地区名称完整示例
 * 
 * 功能说明：
 * - 演示如何使用i18n模块获取语言名称和国家/地区名称的本地化翻译
 * - 展示多种使用场景和最佳实践
 * - 包含错误处理和降级方案
 * 
 * 使用场景：
 * - 应用国际化语言选择界面
 * - 应用国际化国家/地区选择界面
 * - 多语言环境下的名称展示
 * - 语言和地区设置页面
 * 
 * @since API version 9
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 语言名称管理类
 * 用于管理语言名称的本地化翻译
 */
class LanguageNameManager {
  /**
   * 获取单个语言的本地化名称
   */
  static getLanguageName(
    language: string,
    locale: string,
    sentenceCase: boolean = true
  ): string {
    try {
      if (!language || !locale) {
        throw new Error('参数错误：语言ID和区域ID不能为空');
      }
      
      const displayName = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
      console.log(`语言 ${language} 在 ${locale} 环境下显示为: ${displayName}`);
      return displayName;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleError(err, '获取语言名称');
      throw error;
    }
  }
  
  /**
   * 批量获取语言名称
   */
  static getLanguageNames(
    languages: string[],
    locale: string,
    sentenceCase: boolean = true
  ): Map<string, string> {
    const resultMap = new Map<string, string>();
    
    for (const language of languages) {
      try {
        const displayName = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
        resultMap.set(language, displayName);
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        console.error(`获取语言 ${language} 的名称失败: ${err.message}`);
        resultMap.set(language, language);
      }
    }
    
    return resultMap;
  }
  
  /**
   * 错误处理
   */
  private static handleError(error: BusinessError, operation: string): void {
    switch (error.code) {
      case 401:
        console.error(`${operation}失败：参数错误`);
        console.error('可能原因：1.必填参数未指定；2.参数类型错误');
        break;
      case 890001:
        console.error(`${operation}失败：参数无效`);
        console.error('可能原因：语言ID或区域ID格式不正确');
        break;
      default:
        console.error(`${operation}失败：未知错误 ${error.code}, ${error.message}`);
    }
  }
}

/**
 * 国家/地区名称管理类
 * 用于管理国家/地区名称的本地化翻译
 */
class CountryNameManager {
  /**
   * 获取单个国家/地区的本地化名称
   */
  static getCountryName(
    country: string,
    locale: string,
    sentenceCase: boolean = true
  ): string {
    try {
      if (!country || !locale) {
        throw new Error('参数错误：国家地区码和区域ID不能为空');
      }
      
      const displayName = i18n.System.getDisplayCountry(country, locale, sentenceCase);
      console.log(`国家/地区 ${country} 在 ${locale} 环境下显示为: ${displayName}`);
      return displayName;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.handleError(err, '获取国家/地区名称');
      throw error;
    }
  }
  
  /**
   * 批量获取国家/地区名称
   */
  static getCountryNames(
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
        resultMap.set(country, country);
      }
    }
    
    return resultMap;
  }
  
  /**
   * 错误处理
   */
  private static handleError(error: BusinessError, operation: string): void {
    switch (error.code) {
      case 401:
        console.error(`${operation}失败：参数错误`);
        console.error('可能原因：1.必填参数未指定；2.参数类型错误');
        break;
      case 890001:
        console.error(`${operation}失败：参数无效`);
        console.error('可能原因：国家地区码或区域ID格式不正确');
        break;
      default:
        console.error(`${operation}失败：未知错误 ${error.code}, ${error.message}`);
    }
  }
}

/**
 * 国际化名称显示组件
 * 用于在UI界面中展示语言和国家/地区名称
 */
class I18nDisplayNameComponent {
  /**
   * 渲染语言选择列表
   */
  static renderLanguageList(languages: string[], currentLocale: string): void {
    console.log('\n=== 语言选择列表 ===');
    
    const languageNames = LanguageNameManager.getLanguageNames(languages, currentLocale);
    
    languageNames.forEach((name, code) => {
      console.log(`  ${code} - ${name}`);
    });
  }
  
  /**
   * 渲染国家/地区选择列表
   */
  static renderCountryList(countries: string[], currentLocale: string): void {
    console.log('\n=== 国家/地区选择列表 ===');
    
    const countryNames = CountryNameManager.getCountryNames(countries, currentLocale);
    
    countryNames.forEach((name, code) => {
      console.log(`  ${code} - ${name}`);
    });
  }
  
  /**
   * 渲染多语言对照表
   */
  static renderLanguageComparison(language: string, locales: string[]): void {
    console.log(`\n=== 语言 "${language}" 在不同环境下的显示 ===`);
    
    for (const locale of locales) {
      try {
        const name = i18n.System.getDisplayLanguage(language, locale, true);
        console.log(`  ${locale}: ${name}`);
      } catch (error) {
        console.error(`  ${locale}: [获取失败]`);
      }
    }
  }
  
  /**
   * 渲染国家/地区多语言对照表
   */
  static renderCountryComparison(country: string, locales: string[]): void {
    console.log(`\n=== 国家/地区 "${country}" 在不同环境下的显示 ===`);
    
    for (const locale of locales) {
      try {
        const name = i18n.System.getDisplayCountry(country, locale, true);
        console.log(`  ${locale}: ${name}`);
      } catch (error) {
        console.error(`  ${locale}: [获取失败]`);
      }
    }
  }
}

/**
 * 场景1：应用语言设置页面
 */
function scenario1_LanguageSettings(): void {
  console.log('\n========================================');
  console.log('场景1：应用语言设置页面');
  console.log('========================================');
  
  const supportedLanguages = ['zh', 'en', 'de', 'fr', 'ja', 'ko', 'es', 'ru', 'pt', 'it'];
  const currentLocale = 'zh-Hans-CN';
  
  I18nDisplayNameComponent.renderLanguageList(supportedLanguages, currentLocale);
}

/**
 * 场景2：应用国家/地区设置页面
 */
function scenario2_CountrySettings(): void {
  console.log('\n========================================');
  console.log('场景2：应用国家/地区设置页面');
  console.log('========================================');
  
  const supportedCountries = ['CN', 'US', 'DE', 'FR', 'JP', 'KR', 'GB', 'SA', 'AU', 'CA'];
  const currentLocale = 'en-US';
  
  I18nDisplayNameComponent.renderCountryList(supportedCountries, currentLocale);
}

/**
 * 场景3：多语言名称对照展示
 */
function scenario3_MultiLanguageComparison(): void {
  console.log('\n========================================');
  console.log('场景3：多语言名称对照展示');
  console.log('========================================');
  
  const locales = ['zh-Hans-CN', 'en-US', 'ja-JP', 'de-DE', 'fr-FR', 'es-ES', 'ru-RU'];
  
  // 展示中文在不同语言环境下的显示
  I18nDisplayNameComponent.renderLanguageComparison('zh', locales);
  
  // 展示美国在不同语言环境下的显示
  I18nDisplayNameComponent.renderCountryComparison('US', locales);
}

/**
 * 场景4：错误处理和降级方案
 */
function scenario4_ErrorHandling(): void {
  console.log('\n========================================');
  console.log('场景4：错误处理和降级方案');
  console.log('========================================');
  
  // 测试非法参数
  console.log('\n测试非法参数处理：');
  
  try {
    // 非法语言ID
    const invalidLangName = i18n.System.getDisplayLanguage('invalid-lang', 'zh-Hans-CN');
    console.log(`结果: ${invalidLangName}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`捕获错误: 错误码 ${err.code}, 消息: ${err.message}`);
  }
  
  try {
    // 非法国家地区码
    const invalidCountryName = i18n.System.getDisplayCountry('invalid-country', 'zh-Hans-CN');
    console.log(`结果: ${invalidCountryName}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`捕获错误: 错误码 ${err.code}, 消息: ${err.message}`);
  }
  
  try {
    // 空参数
    const emptyParam = i18n.System.getDisplayLanguage('', 'zh-Hans-CN');
    console.log(`结果: ${emptyParam}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`捕获错误: 错误码 ${err.code}, 消息: ${err.message}`);
  }
}

/**
 * 场景5：sentenceCase参数效果对比
 */
function scenario5_SentenceCaseComparison(): void {
  console.log('\n========================================');
  console.log('场景5：sentenceCase参数效果对比');
  console.log('========================================');
  
  const languages = ['de', 'fr', 'es', 'pt'];
  const locale = 'en-US';
  
  console.log(`\n在 ${locale} 环境下，不同语言的显示对比：\n`);
  console.log('语言代码 | 首字母大写=true | 首字母大写=false');
  console.log('---------|-----------------|------------------');
  
  for (const lang of languages) {
    try {
      const nameWithCap = i18n.System.getDisplayLanguage(lang, locale, true);
      const nameWithoutCap = i18n.System.getDisplayLanguage(lang, locale, false);
      console.log(`${lang.padEnd(9)}| ${nameWithCap.padEnd(16)}| ${nameWithoutCap}`);
    } catch (error) {
      console.error(`获取语言 ${lang} 的名称失败`);
    }
  }
}

/**
 * 主函数
 */
function main(): void {
  console.log('╔════════════════════════════════════════════╗');
  console.log('║   本地化语言与地区名称功能完整示例        ║');
  console.log('╚════════════════════════════════════════════╝');
  
  // 执行各种场景示例
  scenario1_LanguageSettings();
  scenario2_CountrySettings();
  scenario3_MultiLanguageComparison();
  scenario4_ErrorHandling();
  scenario5_SentenceCaseComparison();
  
  console.log('\n╔════════════════════════════════════════════╗');
  console.log('║   所有场景演示完成                        ║');
  console.log('╚════════════════════════════════════════════╝\n');
}

// 执行示例
main();