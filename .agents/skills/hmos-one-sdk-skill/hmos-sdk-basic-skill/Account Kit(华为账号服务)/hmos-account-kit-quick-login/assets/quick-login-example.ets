import { authentication } from '@kit.AccountKit';
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.NetworkKit';

export enum ErrorCode {
    ERROR_CODE_LOGIN_OUT = 1001502001,
    ERROR_CODE_NOT_SUPPORTED = 1001500003,
    ERROR_CODE_NETWORK_ERROR = 1001502005,
    ERROR_CODE_INTERNAL_ERROR = 1001502009,
    ERROR_CODE_USER_CANCEL = 1001502012,
    ERROR_CODE_SYSTEM_SERVICE = 12300001,
    ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED = 1005300001,
    ERROR_CODE_PARAMETER_ERROR = 401,
    ERROR_CODE_REQUEST_REFUSE = 1001500002
}

@Entry
@Component
struct QuickLoginPage {
    logTag: string = 'QuickLoginPage';
    domainId: number = 0x0000;
    @State quickLoginAnonymousPhone: string = '';
    @State isSelected: boolean = false;

    async aboutToAppear() {
        this.quickLoginAnonymousPhone = await this.getQuickLoginAnonymousPhone();
    }

    async getQuickLoginAnonymousPhone(): Promise<string> {
        const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
        authRequest.scopes = ['quickLoginAnonymousPhone'];
        authRequest.state = util.generateRandomUUID();
        authRequest.forceAuthorization = false;

        const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
        let quickLoginAnonymousPhone: string = '';

        try {
            const response = await controller.executeRequest(authRequest) as authentication.AuthorizationWithHuaweiIDResponse;
            quickLoginAnonymousPhone = response.data?.extraInfo?.quickLoginAnonymousPhone as string;

            if (quickLoginAnonymousPhone) {
                hilog.info(this.domainId, this.logTag, 'Succeeded in getting anonymous phone.');
                return quickLoginAnonymousPhone;
            }

            hilog.info(this.domainId, this.logTag, 'AnonymousPhone is empty.');
            return quickLoginAnonymousPhone;
        } catch (error) {
            const err = error as BusinessError;
            hilog.error(this.domainId, this.logTag,
                `Failed to get quickLoginAnonymousPhone, errorCode is ${err.code}, errorMessage is ${err.message}`);
            this.dealAllError(err);
            return quickLoginAnonymousPhone;
        }
    }

    privacyText: loginComponentManager.PrivacyText[] = [
        { text: '已阅读并同意', type: loginComponentManager.TextType.PLAIN_TEXT },
        { text: '《用户服务协议》', tag: '用户服务协议', type: loginComponentManager.TextType.RICH_TEXT },
        { text: '《隐私协议》', tag: '隐私协议', type: loginComponentManager.TextType.RICH_TEXT },
        { text: '和', type: loginComponentManager.TextType.PLAIN_TEXT },
        { text: '《华为账号用户认证协议》', tag: '华为账号用户认证协议', type: loginComponentManager.TextType.RICH_TEXT },
        { text: '。', type: loginComponentManager.TextType.PLAIN_TEXT }
    ];

    controller: loginComponentManager.LoginWithHuaweiIDButtonController =
        new loginComponentManager.LoginWithHuaweiIDButtonController()
            .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
            .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
                this.handleLoginWithHuaweiIDButton(error, response);
            })
            .onClickEvent((error: BusinessError, clickEvent: loginComponentManager.ClickEvent) => {
                if (error) {
                    hilog.error(this.domainId, this.logTag,
                        `onClickEvent error. errCode is ${error.code}, errMessage is ${error.message}`);
                    return;
                }
                hilog.info(this.domainId, this.logTag, `onClickEvent clickEvent: ${clickEvent}`);
                this.controller.setEnabled(false);
            });

    agreementDialog: CustomDialogController = new CustomDialogController({
        builder: AgreementDialog({
            privacyText: this.privacyText,
            cancel: () => {
                this.agreementDialog.close();
                this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED);
            },
            confirm: () => {
                this.agreementDialog.close();
                this.isSelected = true;
                this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.ACCEPTED);
                this.controller.continueLogin((error: BusinessError) => {
                    if (error) {
                        hilog.error(this.domainId, this.logTag,
                            `Failed to login with agreementDialog. errCode is ${error.code}`);
                    } else {
                        hilog.info(this.domainId, this.logTag,
                            'Succeeded in clicking agreementDialog continueLogin.');
                    }
                });
            },
            clickHyperlinkText: () => {
                this.agreementDialog.close();
                this.jumpToPrivacyWebView();
            }
        }),
        autoCancel: false,
        alignment: DialogAlignment.Center
    });

    handleLoginWithHuaweiIDButton(error: BusinessError, response: loginComponentManager.HuaweiIDCredential) {
        if (error) {
            hilog.error(this.domainId, this.logTag,
                `Failed to login. errCode is ${error.code}, errMessage is ${error.message}`);

            if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
                this.showToast('网络未连接，请检查网络设置');
            } else if (error.code === ErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED) {
                this.agreementDialog.open();
            } else if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
                this.showToast('华为账号未登录，请重试');
            } else if (error.code === ErrorCode.ERROR_CODE_NOT_SUPPORTED) {
                this.showToast('该scopes或permissions不支持');
            } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
                hilog.info(this.domainId, this.logTag, 'User canceled.');
            } else {
                this.showToast('服务或网络异常，请稍后重试');
            }

            this.controller.setEnabled(true);
            return;
        }

        try {
            if (this.isSelected && response) {
                hilog.info(this.domainId, this.logTag, 'Succeeded in clicking LoginWithHuaweiIDButton.');
                const authCode = response.authorizationCode;
                const unionID = response.unionID;
                const openID = response.openID;

                hilog.info(this.domainId, this.logTag,
                    `Authorization Code: ${authCode}, UnionID: ${unionID}, OpenID: ${openID}`);

                this.sendAuthorizationCodeToServer(authCode);
            } else {
                this.agreementDialog.open();
            }
        } catch (err) {
            const errMsg = err as BusinessError;
            hilog.error(this.domainId, this.logTag,
                `Failed to login, errCode: ${errMsg.code}, errMessage: ${errMsg.message}`);
            this.showToast('服务或网络异常，请稍后重试');
        } finally {
            this.controller.setEnabled(true);
        }
    }

    showToast(message: string) {
        try {
            this.getUIContext().getPromptAction().showToast({
                message: message,
                duration: 2000
            });
        } catch (error) {
            hilog.error(this.domainId, this.logTag, `Failed to show toast.`);
        }
    }

    jumpToPrivacyWebView() {
        try {
            const checkNetConn = connection.hasDefaultNetSync();
            if (!checkNetConn) {
                this.showToast('服务或网络异常，请稍后重试');
                return;
            }
        } catch (error) {
            hilog.error(this.domainId, this.logTag, `Failed to check network.`);
        }

        this.getUIContext().getRouter().pushUrl({
            url: 'pages/WebPage',
            params: {
                isFromDialog: true,
                url: 'https://privacy.consumer.huawei.com/legal/id/authentication-terms.htm?code=CN&language=zh-CN'
            }
        }, (err) => {
            if (err) {
                hilog.error(this.domainId, this.logTag,
                    `Failed to jumpToPrivacyWebView, errCode: ${err.code}`);
            }
        });
    }

    async sendAuthorizationCodeToServer(authCode: string) {
        hilog.info(this.domainId, this.logTag, `Sending Authorization Code to server: ${authCode}`);
    }

    dealAllError(error: BusinessError): void {
        hilog.error(this.domainId, this.logTag,
            `Error occurred, errorCode is ${error.code}, errorMessage is ${error.message}`);

        if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
            this.showToast('华为账号未登录，请使用其他方式登录');
        } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
            this.showToast('网络异常，请检查当前网络状态并重试');
        } else if (error.code === ErrorCode.ERROR_CODE_INTERNAL_ERROR) {
            this.showToast('登录失败，请使用其他方式登录');
        } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
            this.showToast('系统服务异常，请稍后重试');
        } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
            hilog.info(this.domainId, this.logTag, 'Duplicate request, no need to handle.');
        } else {
            this.showToast('应用登录失败，请使用其他方式登录');
        }
    }

    build() {
        Scroll() {
            Column() {
                if (this.quickLoginAnonymousPhone) {
                    Column() {
                        Image($r('app.media.app_icon'))
                            .width(48)
                            .height(48)
                            .draggable(false)
                            .copyOption(CopyOptions.None)

                        Text($r('app.string.app_name'))
                            .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
                            .fontWeight(FontWeight.Bold)
                            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                            .fontColor($r('sys.color.ohos_id_color_text_primary'))
                            .maxLines(1)
                            .margin({ top: 12 })

                        Text('应用描述')
                            .fontSize($r('sys.float.ohos_id_text_size_body2'))
                            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                            .margin({ top: 8 })
                    }
                    .margin({ top: 100 })

                    Column() {
                        Text(this.quickLoginAnonymousPhone)
                            .fontSize(36)
                            .fontColor($r('sys.color.ohos_id_color_text_primary'))
                            .fontWeight(FontWeight.Bold)
                            .lineHeight(48)
                            .textAlign(TextAlign.Center)
                            .maxLines(1)

                        Text('华为账号绑定号码')
                            .fontSize($r('sys.float.ohos_id_text_size_body2'))
                            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                            .margin({ top: 8 })
                    }
                    .margin({ top: 64 })

                    Column() {
                        LoginWithHuaweiIDButton({
                            params: {
                                style: loginComponentManager.Style.BUTTON_RED,
                                extraStyle: {
                                    buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                                        show: true
                                    })
                                },
                                borderRadius: 24,
                                loginType: loginComponentManager.LoginType.QUICK_LOGIN,
                                supportDarkMode: true
                            },
                            controller: this.controller
                        })
                    }
                    .height(40)
                    .margin({ top: 56 })

                    Column() {
                        Button({
                            type: ButtonType.Capsule,
                            stateEffect: true
                        }) {
                            Text('其他方式登录')
                                .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                        }
                        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                        .constraintSize({ minHeight: 40 })
                        .width('100%')
                        .onClick(() => {
                            hilog.info(this.domainId, this.logTag, 'click optionalLoginButton.');
                        })
                    }
                    .margin({ top: 16 })

                    Row() {
                        Checkbox({ name: 'privacyCheckbox', group: 'privacyCheckboxGroup' })
                            .width(24)
                            .height(24)
                            .select(this.isSelected)
                            .onChange((value: boolean) => {
                                if (value) {
                                    this.isSelected = true;
                                    this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.ACCEPTED);
                                } else {
                                    this.isSelected = false;
                                    this.controller.setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED);
                                }
                                hilog.info(this.domainId, this.logTag, `agreementChecked: ${value}`);
                            })

                        Text() {
                            ForEach(this.privacyText, (item: loginComponentManager.PrivacyText) => {
                                if (item?.type === loginComponentManager.TextType.PLAIN_TEXT && item?.text) {
                                    Span(item?.text)
                                        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                                        .fontSize($r('sys.float.ohos_id_text_size_body3'))
                                } else if (item?.type === loginComponentManager.TextType.RICH_TEXT && item?.text) {
                                    Span(item?.text)
                                        .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                                        .fontSize($r('sys.float.ohos_id_text_size_body3'))
                                        .onClick(() => {
                                            hilog.info(this.domainId, this.logTag, `click privacy text tag: ${item.tag}`);
                                            if (item.tag === '华为账号用户认证协议') {
                                                this.jumpToPrivacyWebView();
                                            }
                                        })
                                }
                            }, (item: loginComponentManager.PrivacyText) => item.text.toString())
                        }
                        .width('100%')
                        .margin({ left: 12 })
                    }
                    .alignItems(VerticalAlign.Top)
                    .margin({ top: 16, bottom: 16 })
                } else {
                    Column() {
                        Text('请使用其他方式登录')
                            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                            .fontColor($r('sys.color.ohos_id_color_text_primary'))
                            .margin({ top: 200 })
                    }
                }
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .constraintSize({ minHeight: '100%' })
            .margin({ left: 16, right: 16 })
        }
        .width('100%')
        .height('100%')
    }
}

@CustomDialog
export struct AgreementDialog {
    logTag: string = 'AgreementDialog';
    domainId: number = 0x0000;
    dialogController?: CustomDialogController;
    cancel: () => void = () => {};
    confirm: () => void = () => {};
    clickHyperlinkText: () => void = () => {};
    privacyText: loginComponentManager.PrivacyText[] = [];

    build() {
        Column() {
            Row() {
                Text('用户协议与隐私条款')
                    .fontSize($r('sys.float.ohos_id_text_size_headline8'))
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .fontWeight(FontWeight.Bold)
                    .textAlign(TextAlign.Center)
                    .maxLines(2)
            }
            .alignItems(VerticalAlign.Center)
            .constraintSize({ minHeight: 56, maxWidth: 400 })
            .margin({ left: $r('sys.float.ohos_id_max_padding_start'), right: $r('sys.float.ohos_id_max_padding_start') })

            Row() {
                Text() {
                    ForEach(this.privacyText, (item: loginComponentManager.PrivacyText) => {
                        if (item?.type === loginComponentManager.TextType.PLAIN_TEXT && item?.text) {
                            Span(item?.text)
                                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                        } else if (item?.type === loginComponentManager.TextType.RICH_TEXT && item?.text) {
                            Span(item?.text)
                                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                                .fontColor('#CE0E2D')
                                .onClick(() => {
                                    hilog.info(this.domainId, this.logTag, `click privacy text tag: ${item.tag}`);
                                    if (item.tag === '华为账号用户认证协议') {
                                        this.clickHyperlinkText();
                                    }
                                })
                        }
                    }, (item: loginComponentManager.PrivacyText) => item.text.toString())
                }
                .width('100%')
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .maxLines(10)
                .textAlign(TextAlign.Start)
                .padding({ left: 24, right: 24 })
            }
            .width('100%')

            Flex({ direction: FlexDirection.Row }) {
                Button('取消', { type: ButtonType.Capsule, stateEffect: true })
                    .fontColor($r('sys.color.ohos_id_color_text_primary'))
                    .fontSize($r('sys.float.ohos_id_text_size_button1'))
                    .backgroundColor(Color.Transparent)
                    .constraintSize({ minHeight: 40, maxWidth: 400 })
                    .width('50%')
                    .onClick(() => {
                        hilog.info(this.domainId, this.logTag, 'AgreementDialog cancel.');
                        this.cancel();
                    })

                Button('同意并登录', { type: ButtonType.Capsule, stateEffect: true })
                    .fontColor(Color.White)
                    .backgroundColor('#CE0E2D')
                    .fontSize($r('sys.float.ohos_id_text_size_button1'))
                    .constraintSize({ minHeight: 40, maxWidth: 400 })
                    .width('50%')
                    .onClick(() => {
                        hilog.info(this.domainId, this.logTag, 'AgreementDialog confirm.');
                        this.confirm();
                    })
            }
            .margin({ top: 8, left: $r('sys.float.ohos_id_elements_margin_horizontal_l'), 
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_l'), bottom: 16 })
        }
        .backgroundColor($r('sys.color.ohos_id_color_dialog_default_bg'))
        .padding({ left: 16, right: 16 })
    }
}