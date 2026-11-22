import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = '[ShareUIAbility]';
const DOMAIN: number = 0x0000;

export default class ShareUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate called');
    
    try {
      if (launchParam?.launchReasonMessage === 'ReasonMessage_SystemShare') {
        hilog.info(DOMAIN, TAG, '应用被系统分享拉起');
        this.handleSystemShareLaunch(want);
      } else {
        hilog.info(DOMAIN, TAG, 
          `应用启动原因：${launchParam?.launchReasonMessage || launchParam?.launchReason || '未知'}`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Error in onCreate: ${JSON.stringify(error)}`);
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant called');
    
    try {
      if (launchParam?.launchReasonMessage === 'ReasonMessage_SystemShare') {
        hilog.info(DOMAIN, TAG, '应用被系统分享拉起（热启动）');
        this.handleSystemShareLaunch(want);
      } else {
        hilog.info(DOMAIN, TAG, 
          `应用启动原因：${launchParam?.launchReasonMessage || launchParam?.launchReason || '未知'}`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Error in onNewWant: ${JSON.stringify(error)}`);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate called');
    
    windowStage.loadContent('pages/ShareUIPage', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `Failed to load content. Code: ${err.code}, Message: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, `Succeeded in loading content. Data: ${JSON.stringify(data)}`);
    });
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground called');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground called');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy called');
  }

  private handleSystemShareLaunch(want: Want): void {
    hilog.info(DOMAIN, TAG, `开始处理分享内容`);
    hilog.info(DOMAIN, TAG, `Want data: ${JSON.stringify(want)}`);
    
    if (want.parameters) {
      const shareText = want.parameters['shareText'];
      const shareUri = want.parameters['shareUri'];
      
      if (shareText) {
        hilog.info(DOMAIN, TAG, `分享文本: ${shareText}`);
      }
      
      if (shareUri) {
        hilog.info(DOMAIN, TAG, `分享URI: ${shareUri}`);
      }
    }
  }
}