import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

class FallbackRecommendationHandler {
  private checkInterval: number = 5000;
  private intervalId: number | null = null;
  private isFallbackActive: boolean = false;

  useFallbackStrategy(error: BusinessError): void {
    console.warn('Using fallback strategy for multi-path recommendation due to error: ' + error.code);
    this.isFallbackActive = true;
    
    if (error.code === 201) {
      this.showPermissionGuidance();
    } else if (error.code === 801) {
      this.showVersionGuidance();
    } else {
      this.startPeriodicNetworkCheck();
    }
  }

  private showPermissionGuidance(): void {
    console.warn('Permission ohos.permission.LINKTURBO is required');
    console.warn('Please guide user to grant permission in settings');
  }

  private showVersionGuidance(): void {
    console.warn('System version is too low');
    console.warn('Please upgrade to HarmonyOS API 6.0.0(20) or higher');
  }

  private startPeriodicNetworkCheck(): void {
    console.info('Starting periodic network quality check as fallback');
    
    this.intervalId = setInterval(() => {
      this.checkNetworkQuality();
    }, this.checkInterval);
  }

  private checkNetworkQuality(): void {
    const quality = this.getNetworkQuality();
    
    if (quality.isPoor) {
      console.info('Fallback: Network quality is poor, consider requesting multi-path');
      this.onPoorNetworkDetected();
    } else {
      console.info('Fallback: Network quality is good');
    }
  }

  private getNetworkQuality(): { isPoor: boolean } {
    return { isPoor: false };
  }

  private onPoorNetworkDetected(): void {
    console.info('Fallback: Providing manual multi-path request option');
    this.showManualOption();
  }

  private showManualOption(): void {
    console.info('Fallback: Display manual multi-path request button in UI');
  }

  stopFallback(): void {
    if (this.intervalId !== null) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.isFallbackActive = false;
    console.info('Fallback strategy stopped');
  }

  isActive(): boolean {
    return this.isFallbackActive;
  }
}

export { FallbackRecommendationHandler };

async function main(): Promise<void> {
  const fallbackHandler = new FallbackRecommendationHandler();
  
  try {
    netHandover.on('multiPathRecommendation', (data) => {
      console.info('Received recommendation: ' + JSON.stringify(data));
    });
  } catch (err) {
    const error = err as BusinessError;
    fallbackHandler.useFallbackStrategy(error);
  }
  
  await new Promise<void>(resolve => setTimeout(resolve, 30000));
  
  fallbackHandler.stopFallback();
}

main();