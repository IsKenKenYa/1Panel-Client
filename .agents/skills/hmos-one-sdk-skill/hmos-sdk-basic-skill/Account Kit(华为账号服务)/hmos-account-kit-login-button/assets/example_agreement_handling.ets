import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct AgreementHandlingPage {
  @State isSelected: boolean = false;
  
  privacyText: loginComponentManager.PrivacyText[] = [
    { text: '已阅读并同意', type: loginComponentManager.TextType.PLAIN_TEXT },
    { text: '《用户服务协议》', tag: '用户服务协议', type: loginComponentManager.TextType.RICH_TEXT },
    { text: '和', type: loginComponentManager.TextType.PLAIN_TEXT },
    { text: '《华为账号用户认证协议》', tag: '华为账号用户认证协议', type: loginComponentManager.TextType.RICH_TEXT }
  ];

  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          if (error.code === 1005300001) {
            hilog.info(0x0000, 'Agreement', 'User did not accept agreement.');
          }
          return;
        }
        if (response) {
          hilog.info(0x0000, 'Agreement', 'Login succeeded.');
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
      
      Row() {
        Checkbox({ name: 'privacyCheckbox', group: 'privacyCheckboxGroup' })
          .select(this.isSelected)
          .onChange((value: boolean) => {
            this.isSelected = value;
            if (value) {
              this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.ACCEPTED);
            } else {
              this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED);
            }
          })
        
        Text() {
          ForEach(this.privacyText, (item: loginComponentManager.PrivacyText) => {
            if (item.type === loginComponentManager.TextType.PLAIN_TEXT) {
              Span(item.text)
            } else {
              Span(item.text)
                .onClick(() => {
                  hilog.info(0x0000, 'Agreement', `Clicked: ${item.tag}`);
                })
            }
          })
        }
      }
      .margin({ top: 16 })
    }
    .height(40)
    .width('100%')
    .margin({ left: 16, right: 16 })
  }
}
