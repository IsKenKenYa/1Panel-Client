import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

class MultiPathRecommendationManager {
  private isSubscribed: boolean = false;
  private recommendationCallback: (data: netHandover.MultiPathRecommendationInfo) => void;
  private hasImportantTask: boolean = false;
  private isNetworkQualityGood: boolean = false;

  constructor() {
    this.recommendationCallback = (data: netHandover.MultiPathRecommendationInfo) => {
      this.handleRecommendation(data);
    };
  }

  startBusinessProcess(): void {
    console.info('Starting business process, subscribing to multi-path recommendation');
    this.subscribeRecommendation();
  }

  endBusinessProcess(): void {
    console.info('Ending business process, unsubscribing from multi-path recommendation');
    this.unsubscribeRecommendation();
  }

  setTaskImportance(isImportant: boolean): void {
    this.hasImportantTask = isImportant;
    console.info('Task importance set to: ' + isImportant);
  }

  updateNetworkQuality(isGood: boolean): void {
    this.isNetworkQualityGood = isGood;
    console.info('Network quality updated to: ' + isGood);
  }

  private subscribeRecommendation(): void {
    if (this.isSubscribed) {
      console.info('Already subscribed');
      return;
    }

    try {
      netHandover.on('multiPathRecommendation', this.recommendationCallback);
      this.isSubscribed = true;
      console.info('Successfully subscribed to multiPathRecommendation');
    } catch (err) {
      const error = err as BusinessError;
      console.error('Subscription failed: ' + error.code + ', ' + error.message);
      this.handleSubscriptionError(error);
    }
  }

  private unsubscribeRecommendation(): void {
    if (!this.isSubscribed) {
      console.info('Not subscribed');
      return;
    }

    try {
      netHandover.off('multiPathRecommendation', this.recommendationCallback);
      this.isSubscribed = false;
      console.info('Successfully unsubscribed from multiPathRecommendation');
    } catch (err) {
      const error = err as BusinessError;
      console.error('Unsubscription failed: ' + error.code + ', ' + error.message);
      this.handleUnsubscriptionError(error);
    }
  }

  private handleRecommendation(data: netHandover.MultiPathRecommendationInfo): void {
    console.info('Received recommendation: action=' + data.action);
    
    if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
      this.decideToRequest();
    } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
      this.decideToRelease();
    }
  }

  private decideToRequest(): void {
    if (this.hasImportantTask) {
      console.info('Decided to request multi-path for important task');
      this.requestMultiPath();
    } else {
      console.info('Skipped multi-path request due to no important task');
    }
  }

  private decideToRelease(): void {
    if (this.isNetworkQualityGood) {
      console.info('Decided to release multi-path due to good network quality');
      this.releaseMultiPath();
    } else {
      console.info('Kept multi-path due to still poor network quality');
    }
  }

  private requestMultiPath(): void {
    console.info('Calling requestMultiPath API');
  }

  private releaseMultiPath(): void {
    console.info('Calling releaseMultiPath API');
  }

  private handleSubscriptionError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('Permission denied');
        break;
      case 801:
        console.error('API not supported');
        break;
      case 1013600001:
        console.error('Internal exception');
        break;
      case 1013600002:
        console.error('System exception');
        break;
      default:
        console.error('Unknown error');
    }
  }

  private handleUnsubscriptionError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('Permission denied');
        break;
      case 801:
        console.error('API not supported');
        break;
      case 1013600001:
        console.error('Internal exception');
        break;
      case 1013600002:
        console.error('System exception');
        break;
      default:
        console.error('Unknown error');
    }
  }

  getSubscriptionStatus(): boolean {
    return this.isSubscribed;
  }
}

export { MultiPathRecommendationManager };

async function main(): Promise<void> {
  const manager = new MultiPathRecommendationManager();
  
  manager.setTaskImportance(true);
  manager.updateNetworkQuality(false);
  
  manager.startBusinessProcess();
  
  await new Promise<void>(resolve => setTimeout(resolve, 10000));
  
  manager.endBusinessProcess();
}

main();