import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function setAppPreferredLanguage(language: string): Promise<void> {
  try {
    i18n.System.setAppPreferredLanguage(language);
    console.info(`App preferred language set to: ${language}`);
    
    const appLanguage = i18n.System.getAppPreferredLanguage();
    console.info(`Current app preferred language: ${appLanguage}`);
    
    console.info(`Note: The app needs to be restarted for the language change to take effect`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to set app language, error code: ${err.code}, message: ${err.message}`);
  }
}

async function resetAppPreferredLanguage(): Promise<void> {
  try {
    i18n.System.setAppPreferredLanguage('default');
    console.info(`App preferred language reset to default (follow system)`);
    
    const appLanguage = i18n.System.getAppPreferredLanguage();
    console.info(`Current app preferred language: ${appLanguage}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to reset app language, error code: ${err.code}, message: ${err.message}`);
  }
}

async function getAppPreferredLanguageInfo(): Promise<string> {
  try {
    const appLanguage = i18n.System.getAppPreferredLanguage();
    console.info(`Current app preferred language: ${appLanguage}`);
    
    const preferredLanguageList = i18n.System.getPreferredLanguageList();
    console.info(`System preferred language list: ${preferredLanguageList.join(', ')}`);
    
    const firstPreferredLanguage = i18n.System.getFirstPreferredLanguage();
    console.info(`First preferred language: ${firstPreferredLanguage}`);
    
    return appLanguage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get app language info, error code: ${err.code}, message: ${err.message}`);
    return 'unknown';
  }
}

async function demonstrateLanguagePreference(): Promise<void> {
  console.info(`=== App Preferred Language Demo ===`);
  
  const currentLanguage = await getAppPreferredLanguageInfo();
  console.info(`Current language: ${currentLanguage}`);
  
  await setAppPreferredLanguage('zh-Hans');
  
  await setAppPreferredLanguage('en');
  
  await resetAppPreferredLanguage();
  
  console.info(`=== Demo Complete ===`);
}

export { setAppPreferredLanguage, resetAppPreferredLanguage, getAppPreferredLanguageInfo, demonstrateLanguagePreference };