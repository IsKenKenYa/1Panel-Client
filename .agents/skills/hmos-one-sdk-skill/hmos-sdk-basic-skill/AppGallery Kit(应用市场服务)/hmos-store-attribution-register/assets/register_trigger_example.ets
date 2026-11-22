import { attributionManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';

const TAG: string = 'AttributionTrigger';
const DOMAIN: number = 0;

export class AttributionTriggerExample {
  async registerStandardTrigger(): Promise<void> {
    try {
      const adTriggerInfo: attributionManager.AdTriggerInfo = {
        businessScene: 5,
        triggerData: 100
      };
      
      const osApiVersion: number = deviceInfo.sdkApiVersion;
      if (osApiVersion >= 22) {
        adTriggerInfo.timestamp = Date.now();
        adTriggerInfo.serviceTag = 'standardTriggerServiceTag';
      }
      
      await attributionManager.registerTrigger(adTriggerInfo);
      hilog.info(DOMAIN, TAG, 'Succeeded in registering standard trigger.');
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to register standard trigger. Code: ${err.code}, Message: ${err.message}`);
      this.handleError(err);
    }
  }
  
  async registerCustomTrigger(): Promise<void> {
    try {
      const adTriggerInfo: attributionManager.AdTriggerInfo = {
        businessScene: 10,
        triggerData: 505
      };
      
      const osApiVersion: number = deviceInfo.sdkApiVersion;
      if (osApiVersion >= 22) {
        adTriggerInfo.timestamp = Date.now();
        adTriggerInfo.serviceTag = 'customTriggerServiceTag';
      }
      
      await attributionManager.registerTrigger(adTriggerInfo);
      hilog.info(DOMAIN, TAG, 'Succeeded in registering custom trigger.');
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to register custom trigger. Code: ${err.code}, Message: ${err.message}`);
      this.handleError(err);
    }
  }
  
  async registerTriggerWithScene(scene: number, triggerData: number): Promise<void> {
    try {
      if (scene < 0 || scene > 99) {
        hilog.error(DOMAIN, TAG, `Invalid businessScene value: ${scene}. Range: [0, 99]`);
        return;
      }
      
      const isStandardTrigger = triggerData >= 1 && triggerData <= 200;
      const isCustomTrigger = triggerData >= 501 && triggerData <= 600;
      
      if (!isStandardTrigger && !isCustomTrigger) {
        hilog.error(DOMAIN, TAG, `Invalid triggerData value: ${triggerData}. Standard: [1, 200], Custom: [501, 600]`);
        return;
      }
      
      const adTriggerInfo: attributionManager.AdTriggerInfo = {
        businessScene: scene,
        triggerData: triggerData
      };
      
      const osApiVersion: number = deviceInfo.sdkApiVersion;
      if (osApiVersion >= 22) {
        adTriggerInfo.timestamp = Date.now();
        adTriggerInfo.serviceTag = `scene_${scene}_trigger_${triggerData}`;
      }
      
      await attributionManager.registerTrigger(adTriggerInfo);
      hilog.info(DOMAIN, TAG, `Succeeded in registering trigger. Scene: ${scene}, TriggerData: ${triggerData}`);
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to register trigger. Code: ${err.code}, Message: ${err.message}`);
      this.handleError(err);
    }
  }
  
  private handleError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error. Check parameter format and value range.');
        break;
      case 1009300001:
        hilog.error(DOMAIN, TAG, 'Service extension connection failed. Install AppGallery client.');
        break;
      case 1009300003:
        hilog.error(DOMAIN, TAG, 'Identity check error. Check app publication and partner registration.');
        break;
      case 1009300109:
        hilog.error(DOMAIN, TAG, 'Missing triggerData parameter.');
        break;
      case 1009300119:
        hilog.error(DOMAIN, TAG, 'Network error. Check network connection.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error. Code: ${error.code}, Message: ${error.message}`);
    }
  }
}