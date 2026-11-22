// 华为账号一键登录客户端完整示例代码
// 实现从获取匿名手机号到发送Authorization Code到服务端的完整流程

import { authentication } from '@kit.AccountKit';
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.NetworkKit';

@Entry
@Component
struct QuickLoginPage {
  @State quickLoginAnonymousPhone: string = '';
  @State isLoading: boolean = false;
  
  async aboutToAppear() {
    // 步骤1：获取匿名手机号
    this.quickLoginAnonymousPhone = await this.getQuickLoginAnonymousPhone();
  }
  
  // 获取匿名手机号
  async getQuickLoginAnonymousPhone(): Promise<string> {
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['quickLoginAnonymousPhone'];
    authRequest.state = util.generateRandomUUID();
    authRequest.forceAuthorization = false;
    
    const controller = new authentication.AuthenticationController();
    
    try {
      const response = await controller.executeRequest(authRequest) as authentication.AuthorizationWithHuaweiIDResponse;
      const anonymousPhone = response.data?.extraInfo?.quickLoginAnonymousPhone as string;
      
      if (anonymousPhone) {
        hilog.info(0x0000, 'QuickLogin', `获取匿名手机号成功: ${anonymousPhone}`);
        return anonymousPhone;
      } else {
        hilog.error(0x0000, 'QuickLogin', '匿名手机号为空，展示其他登录方式');
        return '';
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0000, 'QuickLogin', `获取匿名手机号失败: ${err.code} - ${err.message}`);
      return '';
    }
  }
  
  build() {
    if (this.quickLoginAnonymousPhone) {
      QuickLoginButtonComponent({
        quickLoginAnonymousPhone: this.quickLoginAnonymousPhone,
        onLoginSuccess: (authCode: string) => {
          // 步骤3：发送Authorization Code到服务端
          this.sendAuthCodeToServer(authCode);
        }
      });
    } else {
      // 展示其他登录方式
      Column() {
        Text('请使用其他方式登录')
          .fontSize(16)
          .margin({ top: 100 })
      }
    }
  }
  
  // 发送Authorization Code到服务端
  async sendAuthCodeToServer(authCode: string) {
    this.isLoading = true;
    
    const headers: rcp.RequestHeaders = {
      'accept': 'application/json',
      'Content-Type': 'application/json'
    };
    
    const postMessage = { 'authorizationCode': authCode };
    const baseUrl = 'http://localhost:8080/login';
    const req = new rcp.Request(baseUrl, 'POST', headers, postMessage);
    
    try {
      const session = rcp.createSession();
      const response = await session.fetch(req);
      
      if (response.body) {
        const decoder = util.TextDecoder.create('utf-8');
        const result = JSON.parse(decoder.decodeToString(new Uint8Array(response.body)));
        
        hilog.info(0x0000, 'QuickLogin', `登录成功: ${JSON.stringify(result)}`);
        this.isLoading = false;
        
        // 保存用户信息，跳转到主页
        // ...
      }
    } catch (error) {
      hilog.error(0x0000, 'QuickLogin', `发送失败: ${(error as BusinessError).message}`);
      this.isLoading = false;
    }
  }
}

@Component
struct QuickLoginButtonComponent {
  @State quickLoginAnonymousPhone: string = '';
  @State isSelected: boolean = false;
  onLoginSuccess?: (authCode: string) => void;
  
  privacyText: loginComponentManager.PrivacyText[] = [
    { text: '已阅读并同意', type: loginComponentManager.TextType.PLAIN_TEXT },
    { text: '《华为账号用户认证协议》', tag: '华为账号用户认证协议', type: loginComponentManager.TextType.RICH_TEXT }
  ];
  
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError | undefined, 
        response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          hilog.error(0x0000, 'QuickLogin', `登录失败: ${error.code}`);
          this.controller.setEnabled(true);
          return;
        }
        
        if (response && this.onLoginSuccess) {
          const authCode = response.authorizationCode;
          hilog.info(0x0000, 'QuickLogin', `获取Authorization Code成功`);
          this.onLoginSuccess(authCode);
        }
      });
  
  build() {
    Column() {
      // 展示匿名手机号
      Text(this.quickLoginAnonymousPhone)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })
      
      Text('华为账号绑定号码')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
      
      // 一键登录按钮
      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.QUICK_LOGIN,
          supportDarkMode: true
        },
        controller: this.controller
      })
      .margin({ top: 56 })
      
      // 协议勾选框
      Row() {
        Checkbox()
          .select(this.isSelected)
          .onChange((value: boolean) => {
            this.isSelected = value;
            this.controller.setAgreementStatus(
              value ? loginComponentManager.AgreementStatus.ACCEPTED : 
                     loginComponentManager.AgreementStatus.NOT_ACCEPTED
            );
          })
        
        Text() {
          ForEach(this.privacyText, (item) => {
            if (item.type === loginComponentManager.TextType.PLAIN_TEXT) {
              Span(item.text)
            } else {
              Span(item.text)
                .fontColor('#0000FF')
                .onClick(() => {
                  // 跳转协议页面
                })
            }
          })
        }
      }
      .margin({ top: 16 })
    }
  }
}