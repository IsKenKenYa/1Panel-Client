import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct BasicLoginButtonPage {
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          hilog.error(0x0000, 'LoginButton', `Failed: ${error.code}, ${error.message}`);
          return;
        }
        if (response) {
          const authorizationCode = response.authorizationCode;
          const openID = response.openID;
          hilog.info(0x0000, 'LoginButton', 'Succeeded in getting response.');
          // 将authorizationCode传给服务端处理
        }
      });

  build() {
    Column() {
      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.ID,
          supportDarkMode: true
        },
        controller: this.controller
      })
    }
    .height(40)
    .width('100%')
    .margin({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
  }
}
