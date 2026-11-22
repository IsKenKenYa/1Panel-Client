/**
 * 获取语言名称在指定语言环境下的翻译
 * 
 * 功能说明：
 * - 调用i18n.System.getDisplayLanguage获取语言名称的本地化翻译
 * - 支持全球200+种语言
 * - 可控制首字母大小写格式
 * 
 * 使用场景：
 * - 应用国际化语言选择界面
 * - 语言设置页面显示
 * - 多语言环境下的语言名称展示
 * 
 * @since API version 9
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 获取语言名称在指定语言环境下的翻译
 * 
 * @param language 语言ID，如'zh'、'en'、'de'、'fr'
 * @param locale 区域ID，如'en-GB'、'zh-Hans-CN'、'ja-JP'
 * @param sentenceCase 是否首字母大写，默认true
 * @returns 语言名称的翻译
 * @throws {BusinessError} 参数错误(401)或参数无效(890001)
 * 
 * @example
 * // 获取德语在简体中文环境下的名称
 * const germanName = getLanguageDisplayName('de', 'zh-Hans-CN');
 * console.log(germanName); // 输出: 德文
 * 
 * // 获取中文在英文环境下的名称
 * const chineseName = getLanguageDisplayName('zh', 'en-GB');
 * console.log(chineseName); // 输出: Chinese
 */
function getLanguageDisplayName(
  language: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    // 参数校验
    if (!language || !locale) {
      throw new Error('参数错误：语言ID和区域ID不能为空');
    }
    
    // 调用系统API获取语言名称翻译
    const displayLanguage: string = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
    console.log(`语言 ${language} 在 ${locale} 环境下显示为: ${displayLanguage}`);
    return displayLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`获取语言名称失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    throw error;
  }
}

/**
 * 批量获取多个语言在同一区域环境下的翻译
 * 
 * @param languages 语言ID数组
 * @param locale 目标区域ID
 * @param sentenceCase 是否首字母大写，默认true
 * @returns 语言名称翻译的Map对象
 * 
 * @example
 * const languages = ['zh', 'en', 'de', 'fr', 'ja'];
 * const names = getMultipleLanguageDisplayNames(languages, 'zh-Hans-CN');
 * names.forEach((name, lang) => {
 *   console.log(`${lang}: ${name}`);
 * });
 */
function getMultipleLanguageDisplayNames(
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
      resultMap.set(language, language); // 失败时使用原始语言ID
    }
  }
  
  return resultMap;
}

/**
 * 安全获取语言名称翻译（带降级处理）
 * 
 * @param language 语言ID
 * @param locale 区域ID
 * @param sentenceCase 是否首字母大写
 * @returns 语言名称翻译，失败时返回原始语言ID
 */
function safeGetLanguageDisplayName(
  language: string,
  locale: string,
  sentenceCase: boolean = true
): string {
  try {
    const displayName = i18n.System.getDisplayLanguage(language, locale, sentenceCase);
    return displayName;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    // 降级方案1：尝试使用默认区域ID
    if (locale !== 'en-US') {
      try {
        console.warn(`使用区域ID ${locale} 失败，尝试使用 en-US 作为默认值`);
        const fallbackName = i18n.System.getDisplayLanguage(language, 'en-US', sentenceCase);
        return fallbackName;
      } catch (fallbackError) {
        console.warn('降级方案1失败');
      }
    }
    
    // 降级方案2：返回原始语言ID
    console.warn(`无法获取语言 ${language} 的翻译，返回原始语言ID`);
    return language.toUpperCase();
  }
}

// 示例用法
function main(): void {
  console.log('=== 获取语言名称翻译示例 ===\n');
  
  // 示例1：获取单个语言的翻译
  console.log('示例1：获取单个语言的翻译');
  try {
    const germanInChinese = getLanguageDisplayName('de', 'zh-Hans-CN');
    console.log(`德语在中文环境下显示为: ${germanInChinese}`);
    
    const chineseInEnglish = getLanguageDisplayName('zh', 'en-GB');
    console.log(`中文在英文环境下显示为: ${chineseInEnglish}`);
  } catch (error) {
    console.error('示例1执行失败');
  }
  
  // 示例2：批量获取多个语言的翻译
  console.log('\n示例2：批量获取多个语言的翻译');
  const languages = ['zh', 'en', 'de', 'fr', 'ja', 'ko', 'es', 'ru'];
  const languageNames = getMultipleLanguageDisplayNames(languages, 'zh-Hans-CN');
  
  console.log('在简体中文环境下各语言的名称：');
  languageNames.forEach((name, lang) => {
    console.log(`  ${lang}: ${name}`);
  });
  
  // 示例3：安全获取（带降级处理）
  console.log('\n示例3：安全获取语言名称（带降级处理）');
  const safeName = safeGetLanguageDisplayName('invalid-code', 'zh-Hans-CN');
  console.log(`安全获取结果: ${safeName}`);
  
  // 示例4：不同大小写格式
  console.log('\n示例4：不同大小写格式');
  const nameWithCap = getLanguageDisplayName('de', 'en-GB', true);
  const nameWithoutCap = getLanguageDisplayName('de', 'en-GB', false);
  console.log(`首字母大写: ${nameWithCap}`);
  console.log(`默认格式: ${nameWithoutCap}`);
}

// 执行示例
main();