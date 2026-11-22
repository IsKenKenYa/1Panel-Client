// entry/src/main/ets/entryability/EntryAbility.ets
// UIAbility接收router事件示例

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const TAG: string = 'EntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryAbility] onCreate');
    
    if (want?.parameters?.params) {
      let params: Record<string, Object> = JSON.parse(JSON.stringify(want.parameters.params));
      
      if (params.message === 'router message from widget') {
        hilog.info(DOMAIN_NUMBER, TAG, `Received router message: ${params.message}`);
      }
      
      if (params.target === 'detail_page') {
        hilog.info(DOMAIN_NUMBER, TAG, `Target page: ${params.target}`);
      }
      
      if (params.info) {
        hilog.info(DOMAIN_NUMBER, TAG, `Router info: ${params.info}`);
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryAbility] onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryAbility] onWindowStageCreate');
    
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_NUMBER, TAG, `Failed to load content. Cause: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryAbility] onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryAbility] onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN_NUMBER, TAG, '[EntryAbility] onBackground');
  }
}