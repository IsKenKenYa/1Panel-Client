import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'OpenFormManagerDemo';

@Entry
@Component
struct Index {
  build() {
    Row() {
      Column() {
        Text('卡片管理演示')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        Button($r('app.string.open_form_manager_button'))
          .width('80%')
          .height(50)
          .onClick(() => {
            this.openFormManagerPage();
          })
          .margin({ top: 10, bottom: 10 })

        Text('点击按钮拉起卡片管理页面')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .padding(20)
    }
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private openFormManagerPage(): void {
    const want: Want = {
      bundleName: "com.samples.formmanagerdemo",
      abilityName: 'EntryFormAbility',
      parameters: {
        'ohos.extra.param.key.form_dimension': 2,
        'ohos.extra.param.key.form_name': 'widget',
        'ohos.extra.param.key.module_name': 'entry'
      },
    };

    try {
      formProvider.openFormManager(want);
      hilog.info(DOMAIN, TAG, 'openFormManager called successfully');
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'openFormManager failed, code: %{public}d, message: %{public}s',
        businessError.code, businessError.message);
      
      this.handleError(businessError);
    }
  }

  private handleError(error: BusinessError): void {
    let message: string = '';
    
    switch (error.code) {
      case 16500050:
        message = 'IPC连接失败,请稍后重试';
        break;
      case 16500100:
        message = '获取配置信息失败,请检查卡片配置';
        break;
      case 16501000:
        message = '内部功能错误,请重启应用后重试';
        break;
      default:
        message = '拉起卡片管理页面失败';
        break;
    }

    promptAction.openToast({ 
      message: message,
      duration: 2000
    });
  }
}