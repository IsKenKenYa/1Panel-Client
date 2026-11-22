// entry/src/main/ets/pages/index.ets
// 批量卡片刷新完整示例 - UIAbility中调用

import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'BatchRefreshPage';
const DOMAIN_NUMBER: number = 0xFF00;

@Entry
@Component
struct Index {
  @State reloadFormsResult: string = '';
  @State reloadAllFormsResult: string = '';
  @State isLoading: boolean = false;

  build() {
    Column({ space: 20 }) {
      Text('Form Batch Refresh Demo')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      // 批量刷新指定卡片按钮
      Button('Reload Specific Forms')
        .width('80%')
        .height(50)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.performReloadForms();
        })

      Text(this.reloadFormsResult)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 })

      // 批量刷新所有卡片按钮
      Button('Reload All Forms')
        .width('80%')
        .height(50)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.performReloadAllForms();
        })

      Text(this.reloadAllFormsResult)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 })

      // 查看已加桌卡片信息
      Button('Get Published Form Infos')
        .width('80%')
        .height(50)
        .onClick(() => {
          this.getPublishedFormInfos();
        })
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 执行批量刷新指定卡片
   */
  private async performReloadForms(): void {
    this.isLoading = true;
    this.reloadFormsResult = 'Loading...';

    try {
      // 获取UIAbilityContext
      let context: common.UIAbilityContext = 
        this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      // 指定卡片信息（根据实际配置修改）
      let moduleName: string = 'entry';
      let abilityName: string = 'EntryFormAbility';
      let formName: string = 'weatherCard'; // form_config.json中配置的卡片名称
      
      hilog.info(DOMAIN_NUMBER, TAG, 
        `ReloadForms params: module=${moduleName}, ability=${abilityName}, form=${formName}`);

      // 调用批量刷新接口
      formProvider.reloadForms(context, moduleName, abilityName, formName)
        .then((reloadNum: number) => {
          hilog.info(DOMAIN_NUMBER, TAG, `ReloadForms success, reload number: ${reloadNum}`);
          this.reloadFormsResult = `Success: Reloaded ${reloadNum} forms`;
          this.isLoading = false;
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN_NUMBER, TAG, 
            `ReloadForms failed, code: ${error.code}, message: ${error.message}`);
          this.reloadFormsResult = `Error: ${error.message}`;
          this.isLoading = false;
          
          // 错误处理
          this.handleReloadError(error);
        });
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Catch error: ${error}`);
      const businessError = error as BusinessError;
      this.reloadFormsResult = `Error: ${businessError.message}`;
      this.isLoading = false;
    }
  }

  /**
   * 执行批量刷新所有卡片
   */
  private async performReloadAllForms(): void {
    this.isLoading = true;
    this.reloadAllFormsResult = 'Loading...';

    try {
      // 获取UIAbilityContext
      let context: common.UIAbilityContext = 
        this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      hilog.info(DOMAIN_NUMBER, TAG, 'ReloadAllForms started');

      // 调用批量刷新所有卡片接口
      formProvider.reloadAllForms(context)
        .then((reloadNum: number) => {
          hilog.info(DOMAIN_NUMBER, TAG, `ReloadAllForms success, reload number: ${reloadNum}`);
          this.reloadAllFormsResult = `Success: Reloaded ${reloadNum} forms`;
          this.isLoading = false;
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN_NUMBER, TAG, 
            `ReloadAllForms failed, code: ${error.code}, message: ${error.message}`);
          this.reloadAllFormsResult = `Error: ${error.message}`;
          this.isLoading = false;
          
          // 错误处理
          this.handleReloadError(error);
        });
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Catch error: ${error}`);
      const businessError = error as BusinessError;
      this.reloadAllFormsResult = `Error: ${businessError.message}`;
      this.isLoading = false;
    }
  }

  /**
   * 获取已加桌卡片信息
   */
  private async getPublishedFormInfos(): void {
    try {
      // API version 20+使用getPublishedRunningFormInfos
      formProvider.getPublishedRunningFormInfos()
        .then((data: formInfo.RunningFormInfo[]) => {
          hilog.info(DOMAIN_NUMBER, TAG, 
            `Published form infos: ${JSON.stringify(data)}`);
          
          if (data.length === 0) {
            hilog.warn(DOMAIN_NUMBER, TAG, 'No forms published');
            return;
          }
          
          // 遍历显示卡片信息
          for (let form of data) {
            hilog.info(DOMAIN_NUMBER, TAG, 
              `Form: id=${form.formId}, name=${form.formName}, module=${form.moduleName}`);
          }
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN_NUMBER, TAG, 
            `GetPublishedFormInfos failed: ${error.message}`);
        });
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Error: ${error}`);
    }
  }

  /**
   * 处理批量刷新错误
   */
  private handleReloadError(error: BusinessError): void {
    switch (error.code) {
      case 16501000:
        hilog.error(DOMAIN_NUMBER, TAG, 'Internal functional error. Please retry.');
        // 可以提示用户稍后重试
        break;
      
      case 401:
        hilog.error(DOMAIN_NUMBER, TAG, 'Parameter error. Check moduleName, abilityName, formName.');
        // 检查参数配置是否正确
        break;
      
      default:
        hilog.error(DOMAIN_NUMBER, TAG, `Unknown error: ${error.code}`);
        // 其他错误处理
        break;
    }
  }
}

// form_config.json 配置示例
/*
{
  "forms": [
    {
      "name": "weatherCard",
      "displayName": "Weather Widget",
      "description": "Show weather information",
      "src": "./ets/weather/pages/WeatherCard.ets",
      "uiSyntax": "arkts",
      "window": {
        "designWidth": 720,
        "autoDesignWidth": true
      },
      "colorMode": "auto",
      "isDefault": true,
      "updateEnabled": true,
      "scheduledUpdateTime": "10:30",
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2", "2*4", "4*4"]
    }
  ]
}
*/