import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonySecurityGatewayPage {
  @Prop websiteId: number | null = null;
  @Prop initialSection: string = 'panelTls';
  onOpenPanelTls: () => void = (): void => {};
  onOpenCertificates: () => void = (): void => {};
  onOpenWebsiteStrategy: (websiteId: number) => void = (websiteId: number): void => {};
  onOpenOpenResty: () => void = (): void => {};
  /** 由外层 NavDestination 承载标题栏时，内层导航只负责内容与二级页，避免出现两层标题栏。 */
  @Prop embedded: boolean = false;
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @State private panelTlsEnabled: boolean = false;
  @State private panelDomain: string = '';
  @State private panelExpiration: string = '';
  @State private certificateCount: number = 0;
  @State private expiringCount: number = 0;
  @State private openRestyRunning: boolean = false;
  @State private openRestyHttps: boolean = false;
  @State private risks: Map<string, Object | null>[] = [];
  @State private recentChanges: Map<string, Object | null>[] = [];
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.load(false);
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private countLabel(key: string, count: number): string {
    return this.text(key).replace('{count}', count.toString());
  }

  private panelState(): string {
    return this.text(this.panelTlsEnabled ? 'securityGatewayAvailable' : 'securityGatewayUnavailable');
  }

  private gatewayState(): string {
    return this.text(this.openRestyRunning ? 'securityGatewayRunning' : 'securityGatewayInactive');
  }

  private httpsState(): string {
    return this.text(this.openRestyHttps ? 'securityGatewayEnabled' : 'securityGatewayDisabled');
  }

  private entryFocus(): string {
    if (this.initialSection === 'websiteCertificates') return this.text('securityGatewayEntryWebsiteCerts');
    if (this.initialSection === 'openresty') return this.text('securityGatewayEntryOpenResty');
    return this.text('securityGatewayEntryPanelTls');
  }

  private changeTitle(scope: string): string {
    if (scope === 'openresty_https') return this.text('openrestyTabHttps');
    if (scope === 'openresty_modules') return this.text('openrestyTabModules');
    if (scope === 'openresty_config') return this.text('openrestyTabConfig');
    if (scope.startsWith('website_https:')) return this.text('websiteSiteSslPageTitle');
    return this.text('securityGatewayPanelTlsSection');
  }

  private recentSummary(prefix: string): string {
    for (const change of this.recentChanges) {
      const scope = change.get('scope') as string;
      if (scope.startsWith(prefix)) return `${this.changeTitle(scope)} · ${change.get('createdAt') as string}`;
    }
    return this.text('securityGatewayNoRecentSnapshot');
  }

  private riskTitle(title: string): string {
    if (title === 'Panel TLS expired') return this.text('securityGatewayRiskPanelTlsExpiredTitle');
    if (title === 'Website certificates expiring') return this.text('securityGatewayRiskWebsiteCertsExpiringTitle');
    return this.text('securityGatewayRiskOpenRestyUnavailableTitle');
  }

  private riskMessage(title: string): string {
    if (title === 'Panel TLS expired') return this.text('securityGatewayRiskPanelTlsExpiredMessage');
    if (title === 'Website certificates expiring') {
      return this.countLabel('securityGatewayRiskWebsiteCertsExpiringMessage', this.expiringCount);
    }
    return this.text('securityGatewayRiskOpenRestyUnavailableMessage');
  }

  private async load(restore: boolean): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      if (this.websiteId !== null) args.set('websiteId', this.websiteId);
      const reply = await this.bridge.invoke<Map<string, Object | null>>(
        restore ? 'rollbackNativeSecurityGateway' : 'getNativeSecurityGatewayState', args);
      this.errorMessage = reply.get('error') as string | null ?? '';
      this.panelTlsEnabled = reply.get('panelTlsEnabled') as boolean;
      const panel = reply.get('panelSslInfo') as Map<string, Object | null>;
      this.panelDomain = panel.get('domain') as string | null ?? '—';
      this.panelExpiration = panel.get('timeout') as string | null ?? '—';
      this.certificateCount = (reply.get('certificates') as Map<string, Object | null>[]).length;
      this.expiringCount = reply.get('expiringCertificateCount') as number;
      this.openRestyRunning = reply.get('openRestyRunning') as boolean;
      this.openRestyHttps = (reply.get('openRestyHttps') as Map<string, Object | null>).get('https') === true;
      this.risks = reply.get('risks') as Map<string, Object | null>[];
      this.recentChanges = reply.get('recentSnapshots') as Map<string, Object | null>[];
      if (restore && this.errorMessage.length === 0) {
        this.getUIContext().getPromptAction().showToast({
          message: this.text(reply.get('applied') === true ?
            'securityGatewayRollbackSuccess' : 'securityGatewayRollbackEmpty'),
        });
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private confirmRestore(): void {
    this.getUIContext().showAlertDialog({
      title: this.text('securityGatewayRollbackLatestAction'),
      message: this.recentSummary(''),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('commonConfirm'),
        action: (): void => { this.load(true); },
      },
    });
  }

  private menus(): NavigationMenuItem[] {
    return [{
      value: this.text('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.load(false); },
      isEnabled: !this.loading,
    }];
  }

  @Builder
  private metric(label: string, content: string) {
    Row({ space: 12 }) {
      Text(label).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(content).fontSize(16).textAlign(TextAlign.End).layoutWeight(1)
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }

  @Builder
  private sectionTitle(key: string) {
    Text(this.text(key)).fontSize(16).fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  private openRow(key: string, action: () => void) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Text(this.text(key)).fontSize(16).layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }.width('100%').padding({ left: 16, right: 16 })
    }
    .buttonStyle(ButtonStyleMode.TEXTUAL)
    .constraintSize({ minHeight: 56 })
    .width('100%')
    .accessibilityText(this.text(key))
    .onClick(action)
  }

  @Builder
  private content() {
    List({ space: 16 }) {
      if (this.loading) {
        ListItem() { LoadingProgress().width(48).height(48).margin(16) }
      }
      if (this.errorMessage.length > 0) {
        ListItem() {
          Column({ space: 12 }) {
            Text(this.errorMessage).fontSize(14).copyOption(CopyOptions.InApp)
            Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(false); })
          }.width('100%').padding(16)
        }
      }
      if (!this.loading) {
        if (this.risks.length > 0) {
          ListItem() {
            Column({ space: 12 }) {
              ForEach(this.risks, (risk: Map<string, Object | null>): void => {
                Column({ space: 4 }) {
                  Text(this.riskTitle(risk.get('title') as string)).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(this.riskMessage(risk.get('title') as string)).fontSize(14)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                }.width('100%').alignItems(HorizontalAlign.Start)
              }, (risk: Map<string, Object | null>): string => risk.get('title') as string)
            }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }
        }
        ListItem() {
          Column() {
            this.sectionTitle('securityGatewaySummarySection')
            Column() {
              this.metric(this.text('securityGatewayEntryFocusLabel'), this.entryFocus())
              this.metric(this.text('securityGatewayPanelTlsSection'), this.panelState())
              this.metric(this.text('securityGatewayWebsiteExpiringLabel'),
                this.countLabel('securityGatewayExpiringSoonCount', this.expiringCount))
              this.metric(this.text('securityGatewayOpenRestyLabel'), this.gatewayState())
              this.metric(this.text('securityGatewayLatestApplyLabel'), this.recentSummary(''))
            }.width('100%').padding({ left: 16, right: 16 })
          }.width('100%').backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
        }
        ListItem() {
          Column() {
            this.sectionTitle('securityGatewayPanelTlsSection')
            Column() {
              this.metric(this.text('sslSettingsDomain'), this.panelDomain)
              this.metric(this.text('websiteSiteSslExpirationRow'), this.panelExpiration)
              this.metric(this.text('securityGatewayRecentLabel'), this.recentSummary('panel'))
            }.width('100%').padding({ left: 16, right: 16 })
            this.openRow('securityGatewayOpenPanelTlsAction', this.onOpenPanelTls)
          }.width('100%').backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
        }
        ListItem() {
          Column() {
            this.sectionTitle('securityGatewayWebsiteCertsSection')
            Column() {
              this.metric(this.text('securityGatewaySummaryLabel'),
                this.countLabel('securityGatewayCertsLoadedCount', this.certificateCount))
              this.metric(this.text('securityGatewayRiskLabel'),
                this.countLabel('securityGatewayExpiringSoonCount', this.expiringCount))
              this.metric(this.text('securityGatewayRecentLabel'), this.recentSummary('website_https'))
            }.width('100%').padding({ left: 16, right: 16 })
            this.openRow('securityGatewayOpenCertCenterAction', this.onOpenCertificates)
            if (this.websiteId !== null) {
              this.openRow('securityGatewayOpenWebsiteStrategyAction', (): void => {
                if (this.websiteId !== null) this.onOpenWebsiteStrategy(this.websiteId);
              })
            }
          }.width('100%').backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
        }
        ListItem() {
          Column() {
            this.sectionTitle('securityGatewayOpenRestyGatewaySection')
            Column() {
              this.metric(this.text('securityGatewayStatusLabel'), this.gatewayState())
              this.metric(this.text('openrestyTabHttps'), this.httpsState())
              this.metric(this.text('securityGatewayRecentLabel'), this.recentSummary('openresty_'))
            }.width('100%').padding({ left: 16, right: 16 })
            this.openRow('securityGatewayOpenOpenRestyAction', this.onOpenOpenResty)
          }.width('100%').backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
        }
        ListItem() {
          Button(this.text('securityGatewayRollbackLatestAction')).height(48).width('100%')
            .enabled(this.recentChanges.length > 0)
            .onClick((): void => { this.confirmRestore(); })
        }
      }
    }.width('100%').height('100%').padding(16)
  }

  build() {
    Navigation() {
      this.content()
    }
    .title(this.text('securityGatewayPageTitle'), { barStyle: BarStyle.STANDARD })
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(this.embedded)
    .menus(this.menus())
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
  }
}
