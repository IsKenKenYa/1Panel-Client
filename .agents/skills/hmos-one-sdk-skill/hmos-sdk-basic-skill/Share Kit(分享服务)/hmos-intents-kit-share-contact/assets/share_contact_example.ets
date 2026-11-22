import BuildProfile from 'BuildProfile';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { insightIntent } from '@kit.IntentsKit';
import common from '@kit.AbilityKit';
import preferences from '@ohos.data.preferences';

export class ContactShareManager {
  private context: common.BaseContext;
  private preferencesInstance: preferences.Preferences | null = null;
  
  constructor(context: common.BaseContext) {
    this.context = context;
    this.initPreferences();
  }
  
  private async initPreferences(): Promise<void> {
    try {
      this.preferencesInstance = await preferences.getPreferences(this.context, 'intent_cache');
      console.info('Preferences initialized successfully');
    } catch (error) {
      console.error('Failed to initialize preferences:', error);
    }
  }
  
  public async shareContactToRecommendArea(
    contactId: string,
    contactName: string,
    contactIcon: string,
    phoneNumbers: string[]
  ): Promise<void> {
    try {
      const intent = this.buildContactIntent(contactId, contactName, contactIcon, phoneNumbers);
      await this.executeShareIntent(intent);
      console.info('Contact shared successfully to recommend area');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to share contact. Code: ${err.code}, Message: ${err.message}`);
      await this.handleShareError(err, intent);
    }
  }
  
  private buildContactIntent(
    contactId: string,
    contactName: string,
    contactIcon: string,
    phoneNumbers: string[]
  ): insightIntent.InsightIntent {
    const intent: insightIntent.InsightIntent = {
      intentName: 'SendMessage',
      intentVersion: '1.0',
      identifier: util.generateRandomUUID(),
      
      intentActionInfo: {
        actionMode: 'EXECUTED',
        executedTimeSlots: {
          executedStartTime: new Date().getTime(),
          executedEndTime: new Date().getTime(),
        }
      },
      
      intentEntityInfo: {
        entityId: contactId,
        entityName: 'Contact',
        name: contactName,
        icon: contactIcon,
        phoneNumbers: phoneNumbers,
        
        extras: {
          shareParams: {
            bundleName: BuildProfile.BUNDLE_NAME,
            moduleName: 'entry',
            abilityName: 'SampleContactAbility',
            action: 'ohos.want.action.sendData',
          }
        }
      }
    };
    
    return intent;
  }
  
  private async executeShareIntent(intent: insightIntent.InsightIntent): Promise<void> {
    try {
      await insightIntent.shareIntent(this.context, [intent]);
      console.info('shareIntent API call succeeded');
    } catch (error) {
      throw error;
    }
  }
  
  private async handleShareError(error: BusinessError, intent: insightIntent.InsightIntent): Promise<void> {
    switch (error.code) {
      case 401:
        console.error('Parameter validation failed. Please check intent data structure.');
        throw new Error('Invalid intent parameters');
        
      case 1000101101:
        console.error('Application not registered with InsightIntent. Please apply for whitelist.');
        throw new Error('Whitelist required. See: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/intents-access-flow');
        
      case 1000101104:
        console.error('Share count exceeded limit (20 times per day per app).');
        await this.cacheIntentForRetry(intent);
        throw new Error('Share limit exceeded. Intent cached for retry tomorrow.');
        
      case 1000101105:
        console.error('Single share data size exceeded 50KB limit.');
        throw new Error('Data size too large. Please compress or reduce data.');
        
      case 1000101106:
        console.error('Total share count exceeded limit (3000 times per day for all apps).');
        await this.delayedRetry(intent, 3600000);
        throw new Error('System busy. Will retry in 1 hour.');
        
      case 1000101201:
        console.error('Service abnormal. Please retry later.');
        await this.delayedRetry(intent, 60000);
        throw new Error('Service error. Will retry in 1 minute.');
        
      default:
        console.error(`Unknown error: ${error.message}`);
        throw new Error(`Share failed: ${error.message}`);
    }
  }
  
  private async cacheIntentForRetry(intent: insightIntent.InsightIntent): Promise<void> {
    if (!this.preferencesInstance) {
      console.warn('Preferences not initialized. Cannot cache intent.');
      return;
    }
    
    try {
      const cacheKey = `intent_${intent.identifier}_${Date.now()}`;
      await this.preferencesInstance.put(cacheKey, JSON.stringify(intent));
      await this.preferencesInstance.flush();
      console.info(`Intent cached successfully with key: ${cacheKey}`);
    } catch (error) {
      console.error('Failed to cache intent:', error);
    }
  }
  
  private async delayedRetry(intent: insightIntent.InsightIntent, delayMs: number): Promise<void> {
    setTimeout(async () => {
      try {
        await this.executeShareIntent(intent);
        console.info('Delayed retry succeeded');
      } catch (error) {
        console.error('Delayed retry failed:', error);
      }
    }, delayMs);
    console.info(`Scheduled retry after ${delayMs}ms`);
  }
  
  public async retryCachedIntents(): Promise<void> {
    if (!this.preferencesInstance) {
      console.warn('Preferences not initialized. Cannot retry cached intents.');
      return;
    }
    
    try {
      const allData = await this.preferencesInstance.getAll();
      const cachedIntents: insightIntent.InsightIntent[] = [];
      
      for (const key in allData) {
        if (key.startsWith('intent_')) {
          const intentJson = allData[key] as string;
          const intent = JSON.parse(intentJson) as insightIntent.InsightIntent;
          cachedIntents.push(intent);
          await this.preferencesInstance.delete(key);
        }
      }
      
      if (cachedIntents.length === 0) {
        console.info('No cached intents to retry');
        return;
      }
      
      console.info(`Retrying ${cachedIntents.length} cached intents`);
      
      for (const intent of cachedIntents) {
        try {
          await this.executeShareIntent(intent);
          console.info(`Cached intent ${intent.identifier} retried successfully`);
        } catch (error) {
          console.error(`Failed to retry cached intent ${intent.identifier}:`, error);
        }
      }
      
      await this.preferencesInstance.flush();
      console.info('All cached intents processed');
    } catch (error) {
      console.error('Failed to retry cached intents:', error);
    }
  }
  
  public getShareLimitInfo(): string {
    return `Share limits:
- Per app: 20 times/day
- Per request: 50KB max
- Total apps: 3000 times/day
Recommendation: Batch share to reduce frequency`;
  }
}

export function createContactShareManager(context: common.BaseContext): ContactShareManager {
  return new ContactShareManager(context);
}

export async function shareSingleContact(
  context: common.BaseContext,
  contactId: string,
  contactName: string,
  contactIcon: string,
  phoneNumbers: string[]
): Promise<void> {
  const manager = new ContactShareManager(context);
  await manager.shareContactToRecommendArea(contactId, contactName, contactIcon, phoneNumbers);
}

export async function shareMultipleContacts(
  context: common.BaseContext,
  contacts: Array<{
    id: string;
    name: string;
    icon: string;
    phoneNumbers: string[];
  }>
): Promise<void> {
  const manager = new ContactShareManager(context);
  
  for (const contact of contacts) {
    try {
      await manager.shareContactToRecommendArea(
        contact.id,
        contact.name,
        contact.icon,
        contact.phoneNumbers
      );
    } catch (error) {
      console.error(`Failed to share contact ${contact.id}:`, error);
    }
  }
}