import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HealthStoreInit';
const DOMAIN = 0x0000;

export class HealthStoreInitializer {
  private initializationPromise: Promise<void> | null = null;
  private isInitialized: boolean = false;

  async initialize(): Promise<boolean> {
    if (this.isInitialized) {
      hilog.info(DOMAIN, TAG, 'HealthStore already initialized');
      return true;
    }

    if (this.initializationPromise !== null) {
      hilog.info(DOMAIN, TAG, 'Waiting for existing initialization to complete');
      await this.initializationPromise;
      return this.isInitialized;
    }

    this.initializationPromise = this.performInitialization();
    
    try {
      await this.initializationPromise;
      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, 'HealthStore initialization completed successfully');
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `HealthStore initialization failed. Code: ${error.code}, message: ${error.message}`);
      this.initializationPromise = null;
      return false;
    }
  }

  private async performInitialization(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting HealthStore initialization...');
      await healthStore.init();
      hilog.info(DOMAIN, TAG, 'HealthStore.init() completed');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `HealthStore.init() failed: ${error.message}`);
      throw error;
    }
  }

  isReady(): boolean {
    return this.isInitialized;
  }

  async ensureInitialized(): Promise<void> {
    if (!this.isInitialized) {
      const success = await this.initialize();
      if (!success) {
        throw new Error('HealthStore initialization failed');
      }
    }
  }
}

export async function initWithRetry(maxRetries: number = 3): Promise<boolean> {
  const initializer = new HealthStoreInitializer();
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      const success = await initializer.initialize();
      if (success) {
        hilog.info(DOMAIN, TAG, 'Initialization successful on attempt ' + (i + 1));
        return true;
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, `Initialization attempt ${i + 1} failed: ${error.message}`);
      
      if (i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
  }
  
  hilog.error(DOMAIN, TAG, `Initialization failed after ${maxRetries} attempts`);
  return false;
}

export async function main(): Promise<void> {
  const success = await initWithRetry(3);
  
  if (success) {
    hilog.info(DOMAIN, TAG, 'HealthStore ready for use');
  } else {
    hilog.error(DOMAIN, TAG, 'Failed to initialize HealthStore. Cannot proceed with health data operations.');
  }
}