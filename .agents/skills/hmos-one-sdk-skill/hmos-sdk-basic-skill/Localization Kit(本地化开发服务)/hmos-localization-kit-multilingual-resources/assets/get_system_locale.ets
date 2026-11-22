import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function getSystemLocaleInfo(): Promise<void> {
  try {
    const locale = i18n.System.getSystemLocaleInstance();
    const localeId = locale.toString();
    console.info(`System locale: ${localeId}`);
    
    const language = i18n.System.getSystemLanguage();
    console.info(`System language: ${language}`);
    
    const region = i18n.System.getSystemRegion();
    console.info(`System region: ${region}`);
    
    const isRTL = i18n.isRTL(localeId);
    console.info(`Is RTL language: ${isRTL}`);
    
    const is24HourClock = i18n.System.is24HourClock();
    console.info(`Is 24 hour clock: ${is24HourClock}`);
    
    const preferredLanguageList = i18n.System.getPreferredLanguageList();
    console.info(`Preferred language list: ${preferredLanguageList.join(', ')}`);
    
    const firstPreferredLanguage = i18n.System.getFirstPreferredLanguage();
    console.info(`First preferred language: ${firstPreferredLanguage}`);
    
    const usingLocalDigit = i18n.System.getUsingLocalDigit();
    console.info(`Using local digit: ${usingLocalDigit}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get system locale info, error code: ${err.code}, message: ${err.message}`);
  }
}

async function getDisplayNames(): Promise<void> {
  try {
    const displayCountry = i18n.System.getDisplayCountry('CN', 'en-GB');
    console.info(`Display country (CN in en-GB): ${displayCountry}`);
    
    const displayLanguage = i18n.System.getDisplayLanguage('zh', 'en-GB');
    console.info(`Display language (zh in en-GB): ${displayLanguage}`);
    
    const systemLanguages = i18n.System.getSystemLanguages();
    console.info(`System languages: ${systemLanguages.join(', ')}`);
    
    const systemCountries = i18n.System.getSystemCountries('zh');
    console.info(`System countries for zh: ${systemCountries.join(', ')}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get display names, error code: ${err.code}, message: ${err.message}`);
  }
}

async function checkSuggestedLanguage(): Promise<void> {
  try {
    const isSuggested = i18n.System.isSuggested('zh', 'CN');
    console.info(`Is zh suggested for CN: ${isSuggested}`);
    
    const isSuggestedDefault = i18n.System.isSuggested('en');
    console.info(`Is en suggested: ${isSuggestedDefault}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to check suggested language, error code: ${err.code}, message: ${err.message}`);
  }
}

export { getSystemLocaleInfo, getDisplayNames, checkSuggestedLanguage };