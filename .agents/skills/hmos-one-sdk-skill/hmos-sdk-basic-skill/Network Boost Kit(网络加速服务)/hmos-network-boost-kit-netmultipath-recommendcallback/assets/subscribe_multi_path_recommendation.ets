import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

class MultiPathRecommendationSubscriber {
  private isSubscribed: boolean = false;
  private recommendationCallback: (data: netHandover.MultiPathRecommendationInfo) => void;

  constructor() {
    this.recommendationCallback = this.handleRecommendation.bind(this);
  }

  subscribe(): void {
    if (this.isSubscribed) {
      console.info('Already subscribed to multiPathRecommendation');
      return;
    }

    try {
      netHandover.on('multiPathRecommendation', this.recommendationCallback);
      this.isSubscribed = true;
      console.info('Successfully subscribed to multiPathRecommendation');
    } catch (err) {
      const error = err as BusinessError;
      console.error('Failed to subscribe: errCode: ' + error.code + ', errMessage: ' + error.message);
      this.handleSubscriptionError(error);
    }
  }

  private handleRecommendation(data: netHandover.MultiPathRecommendationInfo): void {
    console.info('Received recommendation: ' + JSON.stringify(data));
    
    if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
      console.info('System recommends to request multi-path');
      this.onRecommendRequest();
    } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
      console.info('System recommends to release multi-path');
      this.onRecommendRelease();
    } else {
      console.warn('Unknown recommendation action: ' + data.action);
    }
  }

  private onRecommendRequest(): void {
    console.info('Business logic: decide whether to request multi-path based on current task importance');
  }

  private onRecommendRelease(): void {
    console.info('Business logic: decide whether to release multi-path based on current network quality');
  }

  private handleSubscriptionError(error: BusinessError): void {
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

  getSubscriptionStatus(): boolean {
    return this.isSubscribed;
  }
}

export { MultiPathRecommendationSubscriber };