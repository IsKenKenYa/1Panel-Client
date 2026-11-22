import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = '[RobustShareUIAbility]';
const DOMAIN: number = 0x0000;

export default class RobustShareUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate called');
    
    if (!this.validateLaunchParam(launchParam)) {
      hilog.error(DOMAIN, TAG, 'launchParam validation failed');
      return;
    }
    
    try {
      const launchReason = this.determineLaunchReason(launchParam);
      
      if (launchReason.isSystemShare) {
        hilog.info(DOMAIN, TAG, '确认应用被系统分享拉起');
        this.handleSystemShareLaunch(want, launchParam);
      } else {
        hilog.info(DOMAIN, TAG, `应用启动原因: ${launchReason.description}`);
        this.handleNormalLaunch(want, launchParam);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Error processing launch: ${JSON.stringify(error)}`);
      this.handleFallbackLaunch(want, launchParam);
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant called');
    
    if (!this.validateLaunchParam(launchParam)) {
      hilog.error(DOMAIN, TAG, 'launchParam validation failed');
      return;
    }
    
    try {
      const launchReason = this.determineLaunchReason(launchParam);
      
      if (launchReason.isSystemShare) {
        hilog.info(DOMAIN, TAG, '确认应用被系统分享拉起（热启动）');
        this.handleSystemShareLaunch(want, launchParam);
      } else {
        hilog.info(DOMAIN, TAG, `应用启动原因: ${launchReason.description}`);
        this.handleNormalLaunch(want, launchParam);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Error processing launch: ${JSON.stringify(error)}`);
      this.handleFallbackLaunch(want, launchParam);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate called');
    
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 
          `Failed to load content. Code: ${err.code}, Message: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, `Succeeded in loading content`);
    });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy called');
  }

  private validateLaunchParam(launchParam: AbilityConstant.LaunchParam): boolean {
    if (!launchParam) {
      hilog.error(DOMAIN, TAG, 'launchParam is null or undefined');
      return false;
    }
    
    if (typeof launchParam.launchReason === 'undefined') {
      hilog.warn(DOMAIN, TAG, 'launchReason field is undefined');
    }
    
    return true;
  }

  private determineLaunchReason(launchParam: AbilityConstant.LaunchParam): 
    { isSystemShare: boolean; description: string; method: string } {
    
    if (launchParam.launchReasonMessage) {
      if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
        return {
          isSystemShare: true,
          description: '系统分享启动',
          method: 'launchReasonMessage'
        };
      } else {
        return {
          isSystemShare: false,
          description: launchParam.launchReasonMessage,
          method: 'launchReasonMessage'
        };
      }
    } else {
      hilog.warn(DOMAIN, TAG, 
        'launchReasonMessage not supported, using fallback method');
      
      if (launchParam.launchReason === AbilityConstant.LaunchReason.SHARE) {
        return {
          isSystemShare: true,
          description: '分享启动（LaunchReason.SHARE）',
          method: 'launchReason'
        };
      } else {
        const reasonMap: Record<number, string> = {
          0: '未知原因',
          1: 'startAbility启动',
          2: 'Call调用启动',
          3: '跨端迁移启动',
          4: '故障恢复启动',
          5: '分享启动',
          8: '开机自启动',
          9: '洞察意图启动',
          10: '跨端迁移提前启动',
          11: '预加载启动'
        };
        
        const description = reasonMap[launchParam.launchReason] || `未知(${launchParam.launchReason})`;
        return {
          isSystemShare: launchParam.launchReason === AbilityConstant.LaunchReason.SHARE,
          description,
          method: 'launchReason'
        };
      }
    }
  }

  private handleSystemShareLaunch(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '处理系统分享启动');
    hilog.info(DOMAIN, TAG, `Want: ${JSON.stringify(want)}`);
    
    if (want.parameters) {
      Object.keys(want.parameters).forEach(key => {
        hilog.info(DOMAIN, TAG, `Parameter[${key}]: ${want.parameters[key]}`);
      });
    }
  }

  private handleNormalLaunch(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '处理普通启动');
  }

  private handleFallbackLaunch(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.warn(DOMAIN, TAG, '使用降级方案处理启动');
    
    if (launchParam?.launchReason === AbilityConstant.LaunchReason.SHARE) {
      hilog.info(DOMAIN, TAG, '降级判断：可能是分享启动');
      this.handleSystemShareLaunch(want, launchParam);
    } else {
      this.handleNormalLaunch(want, launchParam);
    }
  }
}