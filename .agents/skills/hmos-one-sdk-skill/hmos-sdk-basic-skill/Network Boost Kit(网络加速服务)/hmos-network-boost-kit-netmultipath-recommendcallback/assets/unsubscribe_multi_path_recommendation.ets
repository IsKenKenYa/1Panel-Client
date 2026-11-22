import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

class MultiPathRecommendationUnsubscriber {
  unsubscribeAll(): void {
    try {
      netHandover.off('multiPathRecommendation');
      console.info('Successfully unsubscribed all callbacks from multiPathRecommendation');
    } catch (err) {
      const error = err as BusinessError;
      console.error('Failed to unsubscribe: errCode: ' + error.code + ', errMessage: ' + error.message);
      this.handleUnsubscriptionError(error);
    }
  }

  unsubscribeSpecific(callback: (data: netHandover.MultiPathRecommendationInfo) => void): void {
    try {
      netHandover.off('multiPathRecommendation', callback);
      console.info('Successfully unsubscribed specific callback from multiPathRecommendation');
    } catch (err) {
      const error = err as BusinessError;
      console.error('Failed to unsubscribe specific callback: errCode: ' + error.code + ', errMessage: ' + error.message);
      this.handleUnsubscriptionError(error);
    }
  }

  private handleUnsubscriptionError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('Permission denied. Please apply for ohos.permission.LINKTURBO permission.');
        break;
      case 1013600001:
        console.error('Internal processing exception. Please check system state.');
        break;
      case 1013600002:
        console.error('System processing exception. Please check network management service.');
        break;
      case 801:
        console.error('API not supported on this device. Please upgrade system to API 6.0.0(20)+.');
        break;
      default:
        console.error('Unknown error: ' + error.message);
    }
  }
}

export { MultiPathRecommendationUnsubscriber };