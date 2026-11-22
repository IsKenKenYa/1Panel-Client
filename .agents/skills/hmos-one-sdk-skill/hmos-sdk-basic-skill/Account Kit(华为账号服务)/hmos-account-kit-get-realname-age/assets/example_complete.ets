import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002
}

@Entry
@Component
struct RealNameAgeRangePage {
  @State ageRange: string = '';
  @State isLoading: boolean = false;

  async getRealNameAgeRange(): Promise<void> {
    this.isLoading = true;
    
    try {
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      
      authRequest.scopes = ['realNameAgeRange'];
      authRequest.permissions = ['serviceauthcode'];
      authRequest.forceAuthorization = true;
      authRequest.state = util.generateRandomUUID();

      const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
      const data = await controller.executeRequest(authRequest);
      
      const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
      
      const state = authorizationWithHuaweiIDResponse.state;
      if (state && authRequest.state !== state) {
        hilog.error(0x0000, 'RealNameAgeRange', 'State mismatch');
        this.isLoading = false;
        return;
      }

      const authorizationCode = authorizationWithHuaweiIDResponse?.data?.authorizationCode;
      
      if (authorizationCode) {
        hilog.info(0x0000, 'RealNameAgeRange', 'Authorization succeeded');
        
        const ageRangeFromServer = await this.fetchAgeRangeFromServer(authorizationCode);
        this.ageRange = ageRangeFromServer;
      }
    } catch (error) {
      this.handleAuthError(error as BusinessError);
    }
    
    this.isLoading = false;
  }

  async fetchAgeRangeFromServer(authorizationCode: string): Promise<string> {
    hilog.info(0x0000, 'RealNameAgeRange', 'Fetching age range from server');
    
    return new Promise<string>((resolve) => {
      setTimeout(() => {
        resolve('18-25');
      }, 1000);
    });
  }

  handleAuthError(error: BusinessError): void {
    hilog.error(0x0000, 'RealNameAgeRange', `Error: ${error.code}, ${error.message}`);

    switch (error.code) {
      case ErrorCode.ERROR_CODE_LOGIN_OUT:
        AlertDialog.show({ message: 'Please login Huawei account' });
        break;
      case ErrorCode.ERROR_CODE_NETWORK_ERROR:
        AlertDialog.show({ message: 'Network error. Please check network' });
        break;
      case ErrorCode.ERROR_CODE_USER_CANCEL:
        AlertDialog.show({ message: 'User canceled authorization' });
        break;
      case ErrorCode.ERROR_CODE_SYSTEM_SERVICE:
        AlertDialog.show({ message: 'System error. Please retry later' });
        break;
      default:
        AlertDialog.show({ message: 'Unknown error' });
        break;
    }
  }

  build() {
    Column() {
      Text('Real Name Age Range')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50, bottom: 20 });

      if (this.isLoading) {
        LoadingProgress()
          .size(50)
          .margin({ top: 20 });
      } else {
        if (this.ageRange) {
          Text(`Age Range: ${this.ageRange}`)
            .fontSize(18)
            .margin({ top: 20 });
        }
      }

      Button('Get Age Range')
        .fontSize(16)
        .margin({ top: 30 })
        .onClick(() => {
          this.getRealNameAgeRange();
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}