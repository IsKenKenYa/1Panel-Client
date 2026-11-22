import { AbilityConstant, ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = '[ShareExtAbility]';
const DOMAIN: number = 0x0000;

export default class ShareExtAbility extends ShareExtensionAbility {
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate called');
    
    try {
      if (launchParam?.launchReasonMessage === 'ReasonMessage_SystemShare') {
        hilog.info(DOMAIN, TAG, 'Extension被系统分享拉起');
        hilog.info(DOMAIN, TAG, `启动参数: ${JSON.stringify(launchParam)}`);
      } else {
        hilog.info(DOMAIN, TAG, 
          `Extension启动原因：${launchParam?.launchReasonMessage || launchParam?.launchReason || '未知'}`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Error in onCreate: ${JSON.stringify(error)}`);
    }
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    hilog.info(DOMAIN, TAG, 'onSessionCreate called');
    hilog.info(DOMAIN, TAG, `Want data: ${JSON.stringify(want)}`);
    
    try {
      session.loadContent('pages/ShareExtDialog', (err, data) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 
            `Failed to load content. Code: ${err.code}, Message: ${err.message}`);
          return;
        }
        hilog.info(DOMAIN, TAG, `Succeeded in loading content. Data: ${JSON.stringify(data)}`);
      });
      
      this.processShareContent(want, session);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Error in onSessionCreate: ${JSON.stringify(error)}`);
    }
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    hilog.info(DOMAIN, TAG, 'onSessionDestroy called');
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

  private processShareContent(want: Want, session: UIExtensionContentSession): void {
    hilog.info(DOMAIN, TAG, '开始处理分享内容');
    
    if (want.parameters) {
      const shareText = want.parameters['shareText'];
      const shareUri = want.parameters['shareUri'];
      const shareMimeType = want.parameters['shareMimeType'];
      
      if (shareText) {
        hilog.info(DOMAIN, TAG, `分享文本内容: ${shareText}`);
      }
      
      if (shareUri) {
        hilog.info(DOMAIN, TAG, `分享资源URI: ${shareUri}`);
      }
      
      if (shareMimeType) {
        hilog.info(DOMAIN, TAG, `分享内容类型: ${shareMimeType}`);
      }
    }
  }
}