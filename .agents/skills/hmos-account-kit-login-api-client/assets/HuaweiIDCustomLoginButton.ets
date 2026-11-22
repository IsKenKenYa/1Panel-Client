import { authentication } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { rcp } from '@kit.RemoteCommunicationKit';

const DOMAIN_ID: number = 0x0000;
const LOG_TAG: string = 'HuaweiIDCustomLogin';
const SERVICE_DOMAIN: string = 'http://localhost:8080';
const GET_ID_INFO_PATH: string = '/huawei/login';
const LOGIN_TEXT: string = '华为账号登录';
const HUAWEI_RED: string = '#CE0E2D';
const HUAWEI_GRAY: string = '#F2F2F2';
const ERROR_CODE_USER_CANCEL: number = 1001502012;
const ERROR_CODE_REQUEST_REFUSE: number = 1001500002;

export enum HuaweiIDButtonMode {
  ICON_ONLY,
  TEXT_ONLY,
  ICON_TEXT
}

export enum HuaweiIDButtonColorStyle {
  RED,
  WHITE,
  WHITE_BORDERED,
  GRAY,
  BLACK
}

interface ButtonPalette {
  backgroundColor: ResourceColor;
  contentColor: ResourceColor;
  logo?: Resource;
  borderColor: ResourceColor;
  borderWidth: number;
}

async function requestAuthorizationCode(context: common.Context | undefined): Promise<string> {
  const request = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
  request.forceLogin = true;
  request.state = util.generateRandomUUID();

  const controller = new authentication.AuthenticationController(context);
  const response = await controller.executeRequest(request) as authentication.LoginWithHuaweiIDResponse;
  if ((request.state || '') !== (response.state || '')) {
    throw new Error('The response state does not match the request state.');
  }

  const authorizationCode = response.data?.authorizationCode;
  if (!authorizationCode) {
    throw new Error('Authorization Code is empty.');
  }
  return authorizationCode;
}

function requestIDInfo(authorizationCode: string): void {
  const request = new rcp.Request(
    `${SERVICE_DOMAIN}${GET_ID_INFO_PATH}`,
    'POST',
    { 'accept': 'application/json' },
    { 'code': authorizationCode }
  );

  try {
    rcp.createSession().fetch(request)
      .then((response) => {
        if (!response.body) {
          return;
        }
        const result: Record<string, string> = JSON.parse(
          util.TextDecoder.create('utf-8').decodeToString(new Uint8Array(response.body))
        );
        const openId = result['openId'];
        const unionId = result['unionId'];
        if (openId && unionId) {
          // TODO: 在这里处理 Open ID 和 Union ID，例如保存登录信息或更新应用登录状态。
        }
      })
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN_ID, LOG_TAG,
          `Failed to get ID information. code: ${error.code}, message: ${error.message}`);
      });
  } catch (error) {
    const businessError = error as BusinessError;
    hilog.error(DOMAIN_ID, LOG_TAG,
      `Failed to request ID information. code: ${businessError.code}, message: ${businessError.message}`);
  }
}

@Component
export struct HuaweiIDCustomLoginButton {
  @State private isLoading: boolean = false;

  @Prop mode: HuaweiIDButtonMode = HuaweiIDButtonMode.TEXT_ONLY;
  @Prop colorStyle: HuaweiIDButtonColorStyle = HuaweiIDButtonColorStyle.RED;
  @Prop buttonWidth: Length = '100%';
  @Prop buttonHeight: number = 40;
  @Prop borderRadiusValue: number = 20;
  @Prop textFontSize: number = 16;
  @Prop textOnlyFontWeight: FontWeight = FontWeight.Medium;
  @Prop textOnlyFontFamily: string = 'sans-serif';
  @Prop textOnlyBackgroundColor: ResourceColor = HUAWEI_RED;
  @Prop textOnlyFontColor: ResourceColor = Color.White;
  @Prop iconTextSpace: number = 8;
  @Prop iconOnlyLogoScale: number = 0.5;
  private palette: ButtonPalette = {
    backgroundColor: HUAWEI_RED,
    contentColor: Color.White,
    logo: $r('app.media.huaweilogo_white'),
    borderColor: Color.Transparent,
    borderWidth: 0
  };

  aboutToAppear(): void {
    this.palette = this.createPalette();
  }

  private createPalette(): ButtonPalette {
    if (this.mode === HuaweiIDButtonMode.TEXT_ONLY) {
      return {
        backgroundColor: this.textOnlyBackgroundColor,
        contentColor: this.textOnlyFontColor,
        borderColor: Color.Transparent,
        borderWidth: 0
      };
    }
    if (this.colorStyle === HuaweiIDButtonColorStyle.WHITE ||
      this.colorStyle === HuaweiIDButtonColorStyle.WHITE_BORDERED) {
      return {
        backgroundColor: Color.White,
        contentColor: Color.Black,
        logo: $r('app.media.huaweilogo_red_black'),
        borderColor: HUAWEI_GRAY,
        borderWidth: this.colorStyle === HuaweiIDButtonColorStyle.WHITE_BORDERED ? 1 : 0
      };
    }
    if (this.colorStyle === HuaweiIDButtonColorStyle.GRAY) {
      return {
        backgroundColor: HUAWEI_GRAY,
        contentColor: Color.Black,
        logo: $r('app.media.huaweilogo_red_black'),
        borderColor: Color.Transparent,
        borderWidth: 0
      };
    }
    return {
      backgroundColor: this.colorStyle === HuaweiIDButtonColorStyle.BLACK ? Color.Black : HUAWEI_RED,
      contentColor: Color.White,
      logo: $r('app.media.huaweilogo_white'),
      borderColor: Color.Transparent,
      borderWidth: 0
    };
  }

  private getLogoSize(): number {
    if (this.mode === HuaweiIDButtonMode.ICON_ONLY) {
      return Math.max(16, Math.round(this.buttonHeight * this.iconOnlyLogoScale));
    }
    return Math.round(this.textFontSize * 1.5);
  }

  private async login(): Promise<void> {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    try {
      const authorizationCode = await requestAuthorizationCode(
        this.getUIContext().getHostContext()
      );
      this.getUIContext().getPromptAction().showToast({ message: '华为账号登录成功' });
      requestIDInfo(authorizationCode);
    } catch (error) {
      const businessError = error as BusinessError;
      if (businessError.code !== ERROR_CODE_USER_CANCEL &&
        businessError.code !== ERROR_CODE_REQUEST_REFUSE) {
        this.getUIContext().getPromptAction().showToast({ message: '华为账号登录失败，请重试' });
      }
    } finally {
      this.isLoading = false;
    }
  }

  @Builder
  textOnlyContent() {
    Text(LOGIN_TEXT)
      .fontSize(this.textFontSize)
      .fontWeight(this.textOnlyFontWeight)
      .fontFamily(this.textOnlyFontFamily)
      .fontColor(this.textOnlyFontColor)
      .maxLines(2)
      .textAlign(TextAlign.Center)
      .maxFontScale(3.2)
  }

  @Builder
  iconTextContent() {
    Row({ space: this.iconTextSpace }) {
      Image(this.palette.logo as Resource)
        .width(this.getLogoSize())
        .height(this.getLogoSize())
        .objectFit(ImageFit.Contain)

      Text(LOGIN_TEXT)
        .fontSize(this.textFontSize)
        .fontWeight(FontWeight.Medium)
        .fontFamily('sans-serif')
        .fontColor(this.palette.contentColor)
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .maxFontScale(3.2)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  iconOnlyContent() {
    Image(this.palette.logo as Resource)
      .width(this.getLogoSize())
      .height(this.getLogoSize())
      .objectFit(ImageFit.Contain)
  }

  build() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      if (this.isLoading) {
        LoadingProgress()
          .width(this.getLogoSize())
          .height(this.getLogoSize())
          .color(this.palette.contentColor)
      } else if (this.mode === HuaweiIDButtonMode.ICON_ONLY) {
        this.iconOnlyContent()
      } else if (this.mode === HuaweiIDButtonMode.ICON_TEXT) {
        this.iconTextContent()
      } else {
        this.textOnlyContent()
      }
    }
    .width(this.mode === HuaweiIDButtonMode.ICON_ONLY ? this.buttonHeight : this.buttonWidth)
    .height(this.buttonHeight)
    .constraintSize({
      minWidth: this.mode === HuaweiIDButtonMode.ICON_ONLY ? this.buttonHeight : 150
    })
    .padding({
      top: 0,
      right: this.mode === HuaweiIDButtonMode.ICON_ONLY ? 0 : 16,
      bottom: 0,
      left: this.mode === HuaweiIDButtonMode.ICON_ONLY ? 0 : 16
    })
    .border({
      width: this.palette.borderWidth,
      color: this.palette.borderColor,
      radius: this.borderRadiusValue
    })
    .backgroundColor(this.palette.backgroundColor)
    .enabled(!this.isLoading)
    .accessibilityText(LOGIN_TEXT)
    .onClick(() => {
      this.login();
    })
  }
}
