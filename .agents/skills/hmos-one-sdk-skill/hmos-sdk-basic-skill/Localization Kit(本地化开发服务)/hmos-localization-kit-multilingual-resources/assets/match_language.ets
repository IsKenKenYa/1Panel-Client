import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function matchLanguageBySimplified(): string {
  try {
    const systemLanguage = i18n.System.getSimplifiedLanguage();
    console.info(`Simplified system language: ${systemLanguage}`);
    
    const languagesList = ['zh-Hans', 'zh-Hant-HK', 'zh-Hant-TW', 'en', 'ja', 'ko'];
    const matchedLanguage = i18n.I18NUtil.getBestMatchLocale(systemLanguage, languagesList);
    
    console.info(`Matched language: ${matchedLanguage}`);
    return matchedLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to match language, error code: ${err.code}, message: ${err.message}`);
    return 'default';
  }
}

function matchLanguageWithCustomList(customLanguages: string[]): string {
  try {
    const systemLanguage = i18n.System.getSimplifiedLanguage();
    const matchedLanguage = i18n.I18NUtil.getBestMatchLocale(systemLanguage, customLanguages);
    
    console.info(`Matched language from custom list: ${matchedLanguage}`);
    return matchedLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to match language with custom list, error code: ${err.code}, message: ${err.message}`);
    return 'default';
  }
}

function getLanguageInfo(): void {
  try {
    const simplifiedLanguage = i18n.System.getSimplifiedLanguage('zh-Hans-CN');
    console.info(`Simplified language for zh-Hans-CN: ${simplifiedLanguage}`);
    
    const simplifiedLanguageDefault = i18n.System.getSimplifiedLanguage();
    console.info(`Simplified system language: ${simplifiedLanguageDefault}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get language info, error code: ${err.code}, message: ${err.message}`);
  }
}

export { matchLanguageBySimplified, matchLanguageWithCustomList, getLanguageInfo };