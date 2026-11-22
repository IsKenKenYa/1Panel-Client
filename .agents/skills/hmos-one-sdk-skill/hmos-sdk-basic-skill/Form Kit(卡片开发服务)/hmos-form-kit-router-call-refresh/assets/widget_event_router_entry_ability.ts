import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WidgetEventRouterEntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class WidgetEventRouterEntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleFormRouterEvent(want, 'onCreate');
  }

  handleFormRouterEvent(want: Want, source: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `handleFormRouterEvent ${source}, Want: ${JSON.stringify(want)}`);
    
    if (want.parameters && want.parameters[formInfo.FormParam.IDENTITY_KEY] !== undefined) {
      let curFormId = want.parameters[formInfo.FormParam.IDENTITY_KEY].toString();
      let message: string = (JSON.parse(want.parameters?.params as string))?.routerDetail;
      
      hilog.info(DOMAIN_NUMBER, TAG, `UpdateForm formId: ${curFormId}, message: ${message}`);
      
      let formData: Record<string, string> = {
        'routerDetail': message + ' ' + source + ' UIAbility'
      };
      
      let formMsg = formBindingData.createFormBindingData(formData);
      
      formProvider.updateForm(curFormId, formMsg).then((data) => {
        hilog.info(DOMAIN_NUMBER, TAG, 'updateForm success.', JSON.stringify(data));
      }).catch((error: BusinessError) => {
        hilog.info(DOMAIN_NUMBER, TAG, 'updateForm failed.', JSON.stringify(error));
      });
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onNewWant Want:', JSON.stringify(want));
    this.handleFormRouterEvent(want, 'onNewWant');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN_NUMBER, TAG, '%{public}s', 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
  }
}