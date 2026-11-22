import { attributionManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { SignUtil } from './sign_util';

const TAG: string = 'AttributionSource';
const DOMAIN: number = 0;

export class AttributionSourceExample {
  private adTechId: string = '20****e8';
  private privateKey: string = 'your_private_key_here';
  
  async registerImpressionSource(): Promise<void> {
    try {
      const osApiVersion: number = deviceInfo.sdkApiVersion;
      let campaignId: string = '';
      
      if (osApiVersion >= 22) {
        campaignId = '1*******9';
      } else {
        campaignId = '1****6';
      }
      
      const nonce: string = util.generateRandomUUID().replace(/-/g, '');
      const timestamp: number = Date.now();
      
      const adSourceInfo: attributionManager.AdSourceInfo = {
        adTechId: this.adTechId,
        campaignId: campaignId,
        destinationId: '691****4',
        sourceType: attributionManager.SourceType.IMPRESSION,
        mmpIds: ['2f****5'],
        serviceTag: 'testServiceTag',
        nonce: nonce,
        timestamp: timestamp,
        signature: await SignUtil.getSign(
          SignUtil.genSignContent(
            this.adTechId,
            campaignId,
            '691****4',
            ['2f****5'],
            'testServiceTag',
            nonce,
            timestamp
          ),
          this.privateKey
        )
      };
      
      await attributionManager.registerSource(adSourceInfo);
      hilog.info(DOMAIN, TAG, 'Succeeded in registering impression source.');
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to register impression source. Code: ${err.code}, Message: ${err.message}`);
      this.handleError(err);
    }
  }
  
  async registerClickSource(): Promise<void> {
    try {
      const osApiVersion: number = deviceInfo.sdkApiVersion;
      let campaignId: string = '';
      
      if (osApiVersion >= 22) {
        campaignId = '1*******9';
      } else {
        campaignId = '1****6';
      }
      
      const nonce: string = util.generateRandomUUID().replace(/-/g, '');
      const timestamp: number = Date.now();
      
      const adSourceInfo: attributionManager.AdSourceInfo = {
        adTechId: this.adTechId,
        campaignId: campaignId,
        destinationId: '691****4',
        sourceType: attributionManager.SourceType.CLICK,
        mmpIds: ['2f****5', '2f7***5'],
        serviceTag: 'clickServiceTag',
        nonce: nonce,
        timestamp: timestamp,
        signature: await SignUtil.getSign(
          SignUtil.genSignContent(
            this.adTechId,
            campaignId,
            '691****4',
            ['2f****5', '2f7***5'],
            'clickServiceTag',
            nonce,
            timestamp
          ),
          this.privateKey
        )
      };
      
      await attributionManager.registerSource(adSourceInfo);
      hilog.info(DOMAIN, TAG, 'Succeeded in registering click source.');
      
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to register click source. Code: ${err.code}, Message: ${err.message}`);
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
      case 1009300004:
        hilog.error(DOMAIN, TAG, 'Signature verification failed. Check signature generation and key pair.');
        break;
      case 1009300119:
        hilog.error(DOMAIN, TAG, 'Network error. Check network connection.');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error. Code: ${error.code}, Message: ${error.message}`);
    }
  }
}