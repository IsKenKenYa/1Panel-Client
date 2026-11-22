import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';

const TAG = 'MinorsProtectionExample';
const DOMAIN = 0x0000;

let cachedMinorsModeState: boolean = false;
let cachedAgeGroup: minorsProtection.AgeGroup | undefined = undefined;

export class MinorsProtectionTurnOnExample {
  private context: Context;
  
  constructor(context: Context) {
    this.context = context;
  }
  
  async initialize(): void {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      hilog.info(DOMAIN, TAG, 'Device does not support minors protection capability');
      return;
    }
    
    await this.subscribeMinorsModeEvents();
    await this.checkAndGuideTurnOn();
  }
  
  async subscribeMinorsModeEvents(): void {
    try {
      commonEventManager.subscribeCommonEvent(
        'usual.event.MINORSMODE_ON',
        (err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Subscribe MINORSMODE_ON failed: ${err.message}`);
            return;
          }
          hilog.info(DOMAIN, TAG, 'Minors mode turned on');
          this.handleMinorsModeOn();
        }
      );
      
      commonEventManager.subscribeCommonEvent(
        'usual.event.MINORSMODE_OFF',
        (err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Subscribe MINORSMODE_OFF failed: ${err.message}`);
            return;
          }
          hilog.info(DOMAIN, TAG, 'Minors mode turned off');
          this.handleMinorsModeOff();
        }
      );
      
      hilog.info(DOMAIN, TAG, 'Subscribed minors mode events successfully');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Subscribe events failed: ${error.message}`);
    }
  }
  
  async checkAndGuideTurnOn(): void {
    try {
      if (!minorsProtection.supportMinorsMode()) {
        hilog.info(DOMAIN, TAG, 'Device environment does not support minors mode');
        this.showFallbackDialog();
        return;
      }
      
      const info = minorsProtection.getMinorsProtectionInfoSync();
      cachedMinorsModeState = info.minorsProtectionMode;
      cachedAgeGroup = info.ageGroup;
      
      hilog.info(DOMAIN, TAG, `Current minors mode state: ${cachedMinorsModeState}`);
      
      if (cachedMinorsModeState) {
        hilog.info(DOMAIN, TAG, 'Minors mode already on');
        if (cachedAgeGroup) {
          hilog.info(DOMAIN, TAG, 
            `Age group: [${cachedAgeGroup.lowerAge}, ${cachedAgeGroup.upperAge})`);
          this.updateContentByAgeGroup(cachedAgeGroup);
        }
      } else {
        hilog.info(DOMAIN, TAG, 'Minors mode not enabled, show guide entry');
        this.showTurnOnGuide();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Check minors mode failed: ${error.code}, ${error.message}`);
    }
  }
  
  async leadToTurnOnMinorsMode(): void {
    try {
      if (!minorsProtection.supportMinorsMode()) {
        this.showFallbackDialog();
        return;
      }
      
      const currentState = minorsProtection.getMinorsProtectionInfoSync().minorsProtectionMode;
      if (currentState) {
        hilog.info(DOMAIN, TAG, 'Minors mode already on');
        return;
      }
      
      minorsProtection.leadToTurnOnMinorsMode(this.context)
        .then(() => {
          hilog.info(DOMAIN, TAG, 'Turn on minors mode completed');
          this.showSuccessToast('未成年人模式设置流程已完成');
        })
        .catch((error: BusinessError<Object>) => {
          this.handleTurnOnError(error);
        });
    } catch (error) {
      hilog.error(DOMAIN, TAG, 
        `Lead to turn on failed: ${error.code}, ${error.message}`);
    }
  }
  
  handleMinorsModeOn(): void {
    cachedMinorsModeState = true;
    try {
      const info = minorsProtection.getMinorsProtectionInfoSync();
      cachedAgeGroup = info.ageGroup;
      if (cachedAgeGroup) {
        this.updateContentByAgeGroup(cachedAgeGroup);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Get age group failed after mode on');
    }
    this.showSuccessToast('未成年人模式已开启');
  }
  
  handleMinorsModeOff(): void {
    cachedMinorsModeState = false;
    cachedAgeGroup = undefined;
    this.restoreNormalContent();
    this.showInfoToast('未成年人模式已关闭');
  }
  
  handleTurnOnError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, 
      `Turn on failed: ${error.code}, ${error.message}`);
    
    switch (error.code) {
      case 1009900003:
        hilog.info(DOMAIN, TAG, 'User canceled operation');
        break;
        
      case 1009900005:
        hilog.info(DOMAIN, TAG, 'Minors mode already on');
        this.handleMinorsModeOn();
        break;
        
      case 1009900007:
        hilog.warn(DOMAIN, TAG, 'Unsupported account (overseas)');
        this.showLoginPrompt('请登录中国境内华为账号');
        break;
        
      case 1009900011:
        hilog.warn(DOMAIN, TAG, 'Service unavailable (privacy space)');
        this.showPrivacySpacePrompt();
        break;
        
      case 401:
        hilog.error(DOMAIN, TAG, 'Parameter error');
        break;
        
      case 1001502009:
        hilog.error(DOMAIN, TAG, 'Internal error');
        this.showRetryPrompt('系统错误，请重启设备后重试');
        break;
        
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}`);
        this.showUnknownErrorPrompt();
    }
  }
  
  updateContentByAgeGroup(ageGroup: minorsProtection.AgeGroup): void {
    const lowerAge = ageGroup.lowerAge;
    const upperAge = ageGroup.upperAge;
    
    hilog.info(DOMAIN, TAG, 
      `Updating content for age group [${lowerAge}, ${upperAge})`);
    
    if (lowerAge < 3) {
      this.showPreschoolContent();
    } else if (lowerAge < 8) {
      this.showEarlyChildhoodContent();
    } else if (lowerAge < 12) {
      this.showLateChildhoodContent();
    } else if (lowerAge < 16) {
      this.showEarlyTeensContent();
    } else if (lowerAge < 18) {
      this.showLateTeensContent();
    }
  }
  
  showPreschoolContent(): void {
    hilog.info(DOMAIN, TAG, 'Show preschool content (0-3 years)');
  }
  
  showEarlyChildhoodContent(): void {
    hilog.info(DOMAIN, TAG, 'Show early childhood content (3-8 years)');
  }
  
  showLateChildhoodContent(): void {
    hilog.info(DOMAIN, TAG, 'Show late childhood content (8-12 years)');
  }
  
  showEarlyTeensContent(): void {
    hilog.info(DOMAIN, TAG, 'Show early teens content (12-16 years)');
  }
  
  showLateTeensContent(): void {
    hilog.info(DOMAIN, TAG, 'Show late teens content (16-18 years)');
  }
  
  restoreNormalContent(): void {
    hilog.info(DOMAIN, TAG, 'Restore normal content (no minors mode)');
  }
  
  showTurnOnGuide(): void {
    hilog.info(DOMAIN, TAG, 'Show turn on minors mode guide');
  }
  
  showSuccessToast(message: string): void {
    hilog.info(DOMAIN, TAG, `Success: ${message}`);
  }
  
  showInfoToast(message: string): void {
    hilog.info(DOMAIN, TAG, `Info: ${message}`);
  }
  
  showLoginPrompt(message: string): void {
    hilog.info(DOMAIN, TAG, `Login prompt: ${message}`);
  }
  
  showPrivacySpacePrompt(): void {
    hilog.info(DOMAIN, TAG, 'Show privacy space exit prompt');
  }
  
  showRetryPrompt(message: string): void {
    hilog.info(DOMAIN, TAG, `Retry prompt: ${message}`);
  }
  
  showUnknownErrorPrompt(): void {
    hilog.info(DOMAIN, TAG, 'Show unknown error prompt');
  }
  
  showFallbackDialog(): void {
    hilog.info(DOMAIN, TAG, 'Show fallback dialog for app-level minors mode');
  }
}