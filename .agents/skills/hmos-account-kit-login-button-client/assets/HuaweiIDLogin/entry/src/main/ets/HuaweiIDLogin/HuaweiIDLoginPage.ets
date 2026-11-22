/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { buffer, util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { rcp } from '@kit.RemoteCommunicationKit';

const DOMAIN_ID: number = 0x0000;
const LOG_TAG: string = 'HuaweiIDLoginPage';
const PRIVACY_URL_KEY: string = 'privacy_url';
const AGREEMENT_NOT_ACCEPTED: number = 1005300001;
const USER_NOT_LOGGED_IN: number = 1001502001;
const LOGIN_NOT_SUPPORTED: number = 1001500003;
const NETWORK_ERROR: number = 1001502005;
const USER_CANCELED: number = 1001502012;
const SERVICE_DOMAIN: string = 'http://localhost:8080';
const GET_ID_INFO_PATH: string = '/huawei/login';

interface IDInfoResponse {
  openId?: string;
  unionId?: string;
  sessionId?: string;
}

@Entry
@Component
struct HuaweiIDLoginPage {
  @State private isSelected: boolean = false;
  @State private isLoginEnabled: boolean = true;
  private readonly dataFile: string = 'data.json';
  private privacyText: loginComponentManager.PrivacyText[] = [
    {
      text: $r('app.string.agree'),
      type: loginComponentManager.TextType.PLAIN_TEXT
    },
    {
      text: $r('app.string.user_agreement'),
      type: loginComponentManager.TextType.RICH_TEXT,
      tag: ''
    },
    {
      text: $r('app.string.protocol_separator'),
      type: loginComponentManager.TextType.PLAIN_TEXT
    },
    {
      text: $r('app.string.and'),
      type: loginComponentManager.TextType.PLAIN_TEXT
    },
    {
      text: $r('app.string.privacy_policy'),
      type: loginComponentManager.TextType.RICH_TEXT,
      tag: ''
    },
    {
      text: $r('app.string.end'),
      type: loginComponentManager.TextType.PLAIN_TEXT
    }
  ];

  private loginController: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((
        error: BusinessError | undefined,
        credential: loginComponentManager.HuaweiIDCredential
      ) => {
        this.handleLoginResult(error, credential);
      })
      .onClickEvent(() => {
        this.setLoginEnabled(false);
      });

  private setAgreementAccepted(accepted: boolean): void {
    this.isSelected = accepted;
    this.loginController.setAgreementStatus(accepted
      ? loginComponentManager.AgreementStatus.ACCEPTED
      : loginComponentManager.AgreementStatus.NOT_ACCEPTED);
  }

  private setLoginEnabled(enabled: boolean): void {
    this.isLoginEnabled = enabled;
    this.loginController.setEnabled(enabled);
  }

  private handleLoginResult(
    error: BusinessError | undefined,
    credential: loginComponentManager.HuaweiIDCredential
  ): void {
    if (error) {
      this.handleLoginError(error);
      this.setLoginEnabled(true);
      return;
    }

    const authorizationCode = credential.authorizationCode;

    if (!authorizationCode) {
      hilog.error(DOMAIN_ID, LOG_TAG,
        'Failed to complete login: authorization code is empty.');
      this.showToast($r('app.string.service_error'));
      this.setLoginEnabled(true);
      return;
    }

    hilog.info(DOMAIN_ID, LOG_TAG, 'Huawei ID authorization succeeded.');
    this.getIDInfo(authorizationCode);
    this.showToast($r('app.string.login_success'));
    this.setLoginEnabled(true);
  }

  private getIDInfo(authCode: string): void {
    const headers: rcp.RequestHeaders = {
      'accept': 'application/json'
    };
    const postMessage: Record<string, string> = {
      'code': authCode
    };
    const securityConfig: rcp.SecurityConfiguration = {
      tlsOptions: {
        tlsVersion: 'TlsV1.3'
      }
    };
    const requestUrl = `${SERVICE_DOMAIN}${GET_ID_INFO_PATH}`;
    const request = new rcp.Request(requestUrl, 'POST', headers, postMessage);

    try {
      const session = rcp.createSession({
        requestConfiguration: {
          security: securityConfig
        }
      });
      session.fetch(request)
        .then((response) => {
          if (!response.body) {
            hilog.error(DOMAIN_ID, LOG_TAG,
              'Failed to get ID information: empty response body.');
            return;
          }

          const decoder = util.TextDecoder.create('utf-8');
          const result = JSON.parse(
            decoder.decodeToString(new Uint8Array(response.body))
          ) as IDInfoResponse;
          const openId = result.openId;
          const unionId = result.unionId;

          if (!openId || !unionId) {
            hilog.error(DOMAIN_ID, LOG_TAG,
              'Failed to get ID information: openId or unionId is missing.');
            return;
          }

          // Process Huawei ID openId and unionId according to the app's business requirements.
          hilog.info(DOMAIN_ID, LOG_TAG,
            'Succeeded in getting Open ID and Union ID from server.');
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN_ID, LOG_TAG,
            `Failed to get ID information. code: ${error.code}, message: ${error.message}`);
        });
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN_ID, LOG_TAG,
        `Failed to request ID information. code: ${businessError.code}, ` +
        `message: ${businessError.message}`);
    }
  }

  private handleLoginError(error: BusinessError): void {
    hilog.error(DOMAIN_ID, LOG_TAG,
      `Huawei ID login failed. code: ${error.code}, message: ${error.message}`);

    if (error.code === AGREEMENT_NOT_ACCEPTED) {
      this.showToast($r('app.string.agreement_not_accepted_toast'));
    } else if (error.code === NETWORK_ERROR) {
      this.showAlert($r('app.string.hwid_no_internet_connect'));
    } else if (error.code === USER_NOT_LOGGED_IN) {
      this.showToast($r('app.string.not_login_in'));
    } else if (error.code === LOGIN_NOT_SUPPORTED) {
      this.showToast($r('app.string.scope_not_supported'));
    } else if (error.code !== USER_CANCELED) {
      this.showToast($r('app.string.service_error'));
    }
  }

  private getProtocolUrl(): string {
    try {
      const content = this.getUIContext().getHostContext()?.resourceManager
        ?.getRawFileContentSync(this.dataFile);
      return JSON.parse(buffer.from(content?.buffer).toString())[PRIVACY_URL_KEY] as string;
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN_ID, LOG_TAG,
        `Failed to read protocol URL. code: ${businessError.code}, message: ${businessError.message}`);
      return '';
    }
  }

  private openProtocol(url: string): void {
    if (!url) {
      return;
    }
    const language = (this.getUIContext().getHostContext() as common.UIAbilityContext).config.language ?? '';
    this.getUIContext().getRouter().pushUrl({
      url: 'HuaweiIDLogin/ProtocolWebView',
      params: {
        'protocolUrl': url + language
      }
    });
  }

  private showAlert(message: Resource): void {
    this.getUIContext().showAlertDialog({
      message: message,
      textStyle: { wordBreak: WordBreak.BREAK_WORD },
      alignment: DialogAlignment.Center,
      autoCancel: false,
      confirm: {
        value: $r('app.string.hwid_text_button_known'),
        action: () => {}
      }
    });
  }

  private showToast(message: Resource): void {
    this.getUIContext().getPromptAction().showToast({
      message: message,
      duration: 2000
    });
  }

  @Builder
  private AgreementContent() {
    Flex({
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center
    }) {
      Checkbox({ name: 'privacyCheckbox', group: 'privacyCheckboxGroup' })
        .width(24)
        .height(24)
        .padding(2)
        .selectedColor($r('app.color.activity_color'))
        .select(this.isSelected)
        .enabled(this.isLoginEnabled)
        .onChange((value: boolean) => {
          this.setAgreementAccepted(value);
        })

      Text() {
        ForEach(this.privacyText, (item: loginComponentManager.PrivacyText) => {
          if (item.type === loginComponentManager.TextType.PLAIN_TEXT && item.text) {
            Span(item.text)
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
          } else if (item.type === loginComponentManager.TextType.RICH_TEXT && item.text) {
            Span(item.text)
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .fontColor(this.isLoginEnabled
                ? $r('sys.color.ohos_id_color_text_primary')
                : $r('sys.color.ohos_id_color_text_tertiary'))
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                if (this.isLoginEnabled) {
                  this.openProtocol(item.tag ?? '');
                }
              })
          }
        }, (item: loginComponentManager.PrivacyText, index: number) => `${item.text}_${index}`)
      }
      .layoutWeight(1)
      .padding({ left: 12 })
    }
    .width('100%')
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Image($r('app.media.appmarket'))
            .width(72)
            .height(72)
            .borderRadius(16)
            .draggable(false)
        }
        .width('100%')
        .height('44%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Column({ space: 16 }) {
            LoginWithHuaweiIDButton({
              params: {
                style: loginComponentManager.Style.BUTTON_CUSTOM,
                extraStyle: {
                  buttonStyle: new loginComponentManager.ButtonStyle()
                    .loadingStyle({ show: true })
                },
                loginType: loginComponentManager.LoginType.ID,
                supportDarkMode: true
              },
              controller: this.loginController
            })
              .width('100%')
              .height(40)
              .constraintSize({ maxWidth: 448 })

            Button($r('app.string.other_login_models'), {
              type: ButtonType.Capsule,
              stateEffect: true
            })
              .width('100%')
              .height(40)
              .constraintSize({ maxWidth: 448 })
              .fontColor($r('sys.color.ohos_id_color_focused_content_primary'))
              .fontSize($r('sys.float.ohos_id_text_size_button1'))
              .fontWeight(FontWeight.Medium)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .enabled(this.isLoginEnabled)
              .onClick(() => {})
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          this.AgreementContent()
        }
        .width('100%')
        .height('56%')
        .padding({ bottom: 16 })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
