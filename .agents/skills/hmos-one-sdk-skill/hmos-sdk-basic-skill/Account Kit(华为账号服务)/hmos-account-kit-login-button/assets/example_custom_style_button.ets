import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct CustomStyleButtonPage {
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          hilog.error(0x0000, 'CustomButton', `Failed: ${error.code}`);
          return;
        }
        if (response) {
          hilog.info(0x0000, 'CustomButton', 'Login succeeded.');
        }
      });

  build() {
    Column() {
      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_CUSTOM,
          borderRadius: 12,
          loginType: loginComponentManager.LoginType.ID,
          supportDarkMode: true,
          extraStyle: {
            buttonStyle: new loginComponentManager.ButtonStyle()
              .backgroundColor('#CE0E2D')
              .fontColor(Color.White)
              .loadingStyle({ show: true })
          }
        },
        controller: this.controller
      })
    }
    .height(48)
    .width('80%')
    .margin({ left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
  }
}
