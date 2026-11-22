import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED = 1005300001,
}

@Entry
@Component
struct ErrorHandlingPage {
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.handleError(error);
          return;
        }
        if (response) {
          hilog.info(0x0000, 'ErrorHandling', 'Login succeeded.');
        }
      });

  handleError(error: BusinessError): void {
    hilog.error(0x0000, 'ErrorHandling', `Error: ${error.code}, ${error.message}`);
    
    switch (error.code) {
      case ErrorCode.ERROR_CODE_LOGIN_OUT:
        hilog.error(0x0000, 'ErrorHandling', 'Account not logged in.');
        break;
      case ErrorCode.ERROR_CODE_NETWORK_ERROR:
        hilog.error(0x0000, 'ErrorHandling', 'Network error.');
        break;
      case ErrorCode.ERROR_CODE_INTERNAL_ERROR:
        hilog.error(0x0000, 'ErrorHandling', 'Internal error.');
        break;
      case ErrorCode.ERROR_CODE_USER_CANCEL:
        hilog.info(0x0000, 'ErrorHandling', 'User cancelled.');
        break;
      case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
        hilog.error(0x0000, 'ErrorHandling', 'System service error.');
        break;
      case ErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED:
        hilog.info(0x0000, 'ErrorHandling', 'Agreement not accepted.');
        break;
      default:
        hilog.error(0x0000, 'ErrorHandling', 'Unknown error.');
    }
  }

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
  }
}
