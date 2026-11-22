import { authentication } from '@kit.AccountKit';
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.NetworkKit';

@Entry
@Component
struct QuickLoginRiskLevelDemo {
    @State quickLoginAnonymousPhone: string = '';
    @State authCode: string = '';
    @State isSelected: boolean = false;
    @State message: string = '';
    
    private logTag: string = 'QuickLoginRiskLevelDemo';
    private domainId: number = 0x0000;
    
    async aboutToAppear(): void {
        this.quickLoginAnonymousPhone = await this.getQuickLoginAnonymousPhone();
    }
    
    async getQuickLoginAnonymousPhone(): Promise<string> {
        const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
        authRequest.scopes = ['quickLoginAnonymousPhone'];
        authRequest.state = util.generateRandomUUID();
        authRequest.forceAuthorization = false;
        
        const controller = new authentication.AuthenticationController();
        let quickLoginAnonymousPhone: string = '';
        
        try {
            await controller.executeRequest(authRequest)
                .then((response: authentication.AuthorizationWithHuaweiIDResponse) => {
                    quickLoginAnonymousPhone = response.data?.extraInfo?.quickLoginAnonymousPhone as string;
                    if (quickLoginAnonymousPhone) {
                        hilog.info(this.domainId, this.logTag, 'Succeeded in getting anonymous phone.');
                    } else {
                        hilog.info(this.domainId, this.logTag, 'Anonymous phone is empty.');
                    }
                })
                .catch((error: BusinessError) => {
                    this.dealAllError(error);
                });
            return quickLoginAnonymousPhone;
        } catch (error) {
            const businessError = error as BusinessError;
            this.dealAllError(businessError);
            return quickLoginAnonymousPhone;
        }
    }
    
    privacyText: loginComponentManager.PrivacyText[] = [{
        text: '已阅读并同意',
        type: loginComponentManager.TextType.PLAIN_TEXT
    }, {
        text: '《用户服务协议》',
        tag: '用户服务协议',
        type: loginComponentManager.TextType.RICH_TEXT
    }, {
        text: '《隐私协议》',
        tag: '隐私协议',
        type: loginComponentManager.TextType.RICH_TEXT
    }, {
        text: '和',
        type: loginComponentManager.TextType.PLAIN_TEXT
    }, {
        text: '《华为账号用户认证协议》',
        tag: '华为账号用户认证协议',
        type: loginComponentManager.TextType.RICH_TEXT
    }];
    
    controller: loginComponentManager.LoginWithHuaweiIDButtonController =
        new loginComponentManager.LoginWithHuaweiIDButtonController()
            .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
            .onClickLoginWithHuaweiIDButton((error: BusinessError | undefined,
                response: loginComponentManager.HuaweiIDCredential) => {
                this.handleLoginResult(error, response);
            })
            .onClickEvent((error: BusinessError, clickEvent: loginComponentManager.ClickEvent) => {
                if (error) {
                    hilog.error(this.domainId, this.logTag,
                        `onClickEvent error: ${error.code}, message: ${error.message}`);
                    return;
                }
                hilog.info(this.domainId, this.logTag, `Button clicked.`);
                this.controller.setEnabled(false);
            });
    
    handleLoginResult(error: BusinessError | undefined, response: loginComponentManager.HuaweiIDCredential): void {
        if (error) {
            hilog.error(this.domainId, this.logTag,
                `Login failed: ${error.code}, message: ${error.message}`);
            this.message = `登录失败: ${error.message}`;
            this.controller.setEnabled(true);
            return;
        }
        
        if (response) {
            this.authCode = response.authorizationCode;
            hilog.info(this.domainId, this.logTag, `Got Authorization Code: ${this.authCode}`);
            this.message = `获取Authorization Code成功,请传递给服务端查询风险等级`;
            
            this.sendAuthCodeToServer(this.authCode);
        }
        
        this.controller.setEnabled(true);
    }
    
    async sendAuthCodeToServer(authCode: string): void {
        try {
            const checkNetConn = connection.hasDefaultNetSync();
            if (!checkNetConn) {
                this.message = '网络未连接,请检查网络设置';
                return;
            }
            
            const response = await fetch('https://your-server.com/api/getRiskLevel', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    authorizationCode: authCode
                })
            });
            
            const result = await response.json();
            if (result.riskLevel) {
                this.displayRiskLevel(result.riskLevel, result.riskTag);
            }
        } catch (error) {
            hilog.error(this.domainId, this.logTag, 'Failed to send auth code to server.');
            this.message = '服务端请求失败,请稍后重试';
        }
    }
    
    displayRiskLevel(riskLevel: number, riskTag: string[]): void {
        let riskLevelDesc: string = '';
        switch (riskLevel) {
            case 0:
                riskLevelDesc = '未发现显著风险';
                break;
            case 1:
                riskLevelDesc = '低风险';
                break;
            case 2:
                riskLevelDesc = '中风险';
                break;
            case 3:
                riskLevelDesc = '高风险';
                break;
            case 4:
                riskLevelDesc = '风险未知';
                break;
            default:
                riskLevelDesc = '未知风险等级';
                break;
        }
        
        this.message = `风险等级: ${riskLevel} (${riskLevelDesc})\n风险标签: ${riskTag.join(', ')}`;
        
        if (riskLevel >= 3) {
            this.message += '\n建议: 拦截本次操作或要求二次验证';
        } else if (riskLevel >= 2) {
            this.message += '\n建议: 降低奖励概率或要求二次验证';
        } else if (riskLevel >= 1) {
            this.message += '\n建议: 进行简单验证或人工审核';
        } else {
            this.message += '\n建议: 确认无风险后放通';
        }
    }
    
    dealAllError(error: BusinessError): void {
        hilog.error(this.domainId, this.logTag,
            `Error: ${error.code}, Message: ${error.message}`);
        
        if (error.code === 1001502001) {
            this.message = '用户未登录华为账号,请登录后重试';
        } else if (error.code === 1001502005) {
            this.message = '网络异常,请检查网络状态并重试';
        } else if (error.code === 1001502009) {
            this.message = '登录失败,请尝试使用其他方式登录';
        } else if (error.code === 1001502012) {
            this.message = '用户取消授权';
        } else if (error.code === 12300001) {
            this.message = '系统服务异常,请稍后重试';
        } else if (error.code === 1001502014) {
            this.message = '应用未申请riskLevel权限,请联系开发者';
        } else {
            this.message = `登录失败: ${error.message}`;
        }
    }
    
    build() {
        Scroll() {
            Column() {
                Column() {
                    Image($r('app.media.app_icon'))
                        .width(48)
                        .height(48)
                        .margin({ top: 100 })
                    
                    Text($r('app.string.app_name'))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .margin({ top: 12 })
                    
                    Text('应用描述')
                        .fontSize(14)
                        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                        .margin({ top: 8 })
                }
                .width('100%')
                
                Column() {
                    if (this.quickLoginAnonymousPhone) {
                        Text(this.quickLoginAnonymousPhone)
                            .fontSize(36)
                            .fontWeight(FontWeight.Bold)
                            .lineHeight(48)
                            .textAlign(TextAlign.Center)
                        
                        Text('华为账号绑定号码')
                            .fontSize(14)
                            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                            .margin({ top: 8 })
                    } else {
                        Text('未获取到匿名手机号')
                            .fontSize(16)
                            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                    }
                }
                .width('100%')
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
                            supportDarkMode: true,
                            verifyPhoneNumber: true,
                            riskLevel: true
                        },
                        controller: this.controller
                    })
                }
                .height(40)
                .width('100%')
                .margin({ top: 56 })
                
                if (this.message) {
                    Column() {
                        Text(this.message)
                            .fontSize(14)
                            .fontColor($r('sys.color.ohos_id_color_text_primary'))
                            .textAlign(TextAlign.Start)
                            .padding(16)
                    }
                    .width('100%')
                    .backgroundColor($r('sys.color.ohos_id_color_component_foreground'))
                    .borderRadius(8)
                    .margin({ top: 16, left: 16, right: 16 })
                }
                
                Row() {
                    Checkbox({ name: 'privacyCheckbox', group: 'privacyCheckboxGroup' })
                        .width(24)
                        .height(24)
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
                            if (item?.type === loginComponentManager.TextType.PLAIN_TEXT && item?.text) {
                                Span(item?.text)
                                    .fontSize(12)
                                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                            } else if (item?.type === loginComponentManager.TextType.RICH_TEXT && item?.text) {
                                Span(item?.text)
                                    .fontSize(12)
                                    .fontColor('#CE0E2D')
                                    .onClick(() => {
                                        hilog.info(this.domainId, this.logTag, `Click privacy text: ${item.tag}`);
                                    })
                            }
                        })
                    }
                    .margin({ left: 12 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .margin({ top: 16, bottom: 16, left: 16, right: 16 })
            }
            .width('100%')
            .constraintSize({ minHeight: '100%' })
        }
        .width('100%')
        .height('100%')
    }
}