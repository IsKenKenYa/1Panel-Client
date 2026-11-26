import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';
import { moduleTitleOptions } from '../../HarmonyModuleTitle';
import { HarmonyWebsiteCertificateForm } from './HarmonyWebsiteCertificateForm';
import { HarmonyWebsiteHttpsPage } from './HarmonyWebsiteHttpsPage';
import { HarmonyWebsiteSslAccountsPage } from './HarmonyWebsiteSslAccountsPage';

interface HarmonySslMetricOptions {
  label: string;
  content: string;
}

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyWebsiteSslCenterPage {
  @Prop initialWebsiteId: number | null = null;
  @Prop initialRoute: string = '/website-ssl-center';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};
  @State private paths: NavPathStack = new NavPathStack();
  @State private groups: Map<string, Object | null>[] = [];
  @State private providerOptions: string[] = [];
  @State private providerFilter: string = '__all__';
  @State private expiryFilter: string = 'all';
  @State private searchQuery: string = '';
  @State private certificate: Map<string, Object | null> = new Map<string, Object | null>();
  @State private loading: boolean = true;
  @State private operating: boolean = false;
  @State private errorMessage: string = '';
  @State private activeWebsiteId: number | null = null;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.activeWebsiteId = this.initialWebsiteId ?? this.routeArguments.get('websiteId') as number | null ?? null;
    if (this.initialRoute === '/website-certificate-detail') {
      this.loadCertificate(this.routeArguments.get('certificateId') as number, false);
    } else if (!this.opensWebsiteHttps()) {
      this.load(false);
    }
  }

  aboutToDisappear(): void {
    this.bridge.invoke<Object | null>('releaseNativeWebsiteSsl');
  }

  private text(key: string): string { return this.bridge.text(key); }
  private certText(key: string): string { return this.certificate.get(key) as string | null ?? '—'; }
  private certId(): number | null { return this.certificate.get('id') as number | null ?? null; }

  private opensWebsiteHttps(): boolean {
    return this.initialRoute === '/website-site-ssl' || this.initialRoute === '/website/https';
  }

  private rootTitle(): string {
    if (this.opensWebsiteHttps()) return this.text('websiteSiteSslPageTitle');
    if (this.initialRoute === '/website-certificate-detail') return this.text('websitesSslInfoTitle');
    return this.text('websitesSslPageTitle');
  }

  private syncCenter(reply: Map<string, Object | null>): void {
    this.groups = reply.get('groups') as Map<string, Object | null>[];
    this.providerOptions = reply.get('providerOptions') as string[];
    this.providerFilter = reply.get('provider') as string;
    this.expiryFilter = reply.get('expiry') as string;
    this.errorMessage = reply.get('error') as string | null ?? '';
  }

  private async load(refresh: boolean): Promise<void> {
    this.loading = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('refresh', refresh);
      args.set('search', this.searchQuery);
      args.set('provider', this.providerFilter);
      args.set('expiry', this.expiryFilter);
      this.syncCenter(await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteSslCenter', args));
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async loadCertificate(id: number, navigate: boolean): Promise<void> {
    this.loading = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('id', id);
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteCertificate', args);
      this.errorMessage = reply.get('error') as string | null ?? '';
      const cert = reply.get('certificate') as Map<string, Object | null> | null;
      if (cert !== null && this.errorMessage.length === 0) {
        this.certificate = cert;
        if (navigate) this.paths.pushPath({ name: 'detail' });
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private openForm(operation: string, useCurrentCertificate: boolean = false): void {
    if (!useCurrentCertificate) this.certificate = new Map<string, Object | null>();
    this.paths.pushPath({ name: operation });
  }

  private openCenter(): void {
    this.paths.pushPath({ name: 'center' });
    this.load(false);
  }

  private async certificateAction(action: string): Promise<void> {
    this.operating = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('action', action);
      args.set('id', this.certId());
      if (action === 'download') args.set('fileName', `${this.certText('primaryDomain')}.zip`);
      const reply = await this.bridge.invoke<Map<string, Object | null>>('performNativeWebsiteSslAction', args);
      this.syncCenter(reply);
      if (this.errorMessage.length > 0) throw new Error(this.errorMessage);
      const download = reply.get('download') as Map<string, Object | null> | null;
      if (download?.get('cancelled') === true) return;
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonOperationSuccess') });
      if (action === 'delete') this.paths.pop();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    } finally {
      this.operating = false;
    }
  }

  private confirmDelete(): void {
    this.getUIContext().showAlertDialog({
      title: this.text('websitesSslDeleteTitle'),
      message: this.text('websitesSslDeleteMessage').replace('{domain}', this.certText('primaryDomain')),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonDelete'), action: (): void => { this.certificateAction('delete'); } },
    });
  }

  private menuItem(key: string, action: () => void): NavigationMenuItem {
    return { value: this.text(key), action: action, isEnabled: !this.operating };
  }

  private centerMenus(): NavigationMenuItem[] {
    return [
      this.menuItem('websitesSslCreateAction', (): void => { this.openForm('create'); }),
      this.menuItem('websitesSslUploadAction', (): void => { this.openForm('upload'); }),
      this.menuItem('sslSettingsTitle', (): void => { this.paths.pushPath({ name: 'accounts' }); }),
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(true); }, isEnabled: !this.loading },
    ];
  }

  private certificateMenus(): NavigationMenuItem[] {
    if (this.certId() === null) return [];
    const provider = this.certText('provider');
    const status = this.certText('status');
    const items: NavigationMenuItem[] = [];
    if (provider === 'manual') {
      items.push(this.menuItem('websitesSslUpdateAction', (): void => { this.openForm('upload', true); }));
    } else if (provider !== 'fromMaster') {
      items.push(this.menuItem('websitesSslUpdateAction', (): void => { this.openForm('update', true); }));
      if (status !== 'applying') {
        items.push(this.menuItem('websitesSslApplyAction', (): void => { this.openForm('apply', true); }));
        if (provider === 'dnsManual') {
          items.push(this.menuItem('websitesSslResolveAction', (): void => { this.openForm('resolve', true); }));
        }
      }
    }
    if (status === 'ready' || provider === 'manual' || provider === 'fromMaster') {
      items.push(this.menuItem('websitesSslDownload', (): void => { this.certificateAction('download'); }));
    }
    items.push(this.menuItem('commonDelete', (): void => { this.confirmDelete(); }));
    return items;
  }

  private expiryOptions(): SelectOption[] {
    return [
      { value: this.text('websitesSslGroupAll') }, { value: this.text('websitesSslGroupExpired') },
      { value: this.text('websitesSslGroupWithin7Days') }, { value: this.text('websitesSslGroupWithin30Days') },
    ];
  }

  private providerSelectOptions(): SelectOption[] {
    return this.providerOptions.map((provider: string): SelectOption => ({
      value: provider === '__all__' ? this.text('websitesSslProviderFilterAll') : provider,
    }));
  }

  private groupLabel(name: string): string {
    if (name === 'Expired') return this.text('websitesSslGroupExpired');
    if (name === 'Within 7 days') return this.text('websitesSslGroupWithin7Days');
    if (name === 'Within 30 days') return this.text('websitesSslGroupWithin30Days');
    if (name === 'Healthy') return this.text('websitesSslGroupHealthy');
    return this.text('websitesSslGroupAll');
  }

  @Builder
  private metric($$: HarmonySslMetricOptions) {
    Column({ space: 6 }) {
      Text($$.label).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary')).width('100%')
      Text($$.content).fontSize(16).width('100%').copyOption(CopyOptions.LocalDevice)
    }.width('100%').padding({ top: 10, bottom: 10 })
  }

  @Builder
  private centerContent() {
    Column({ space: 12 }) {
      Search({ value: this.searchQuery, placeholder: this.text('commonSearch') })
        .height(48).onChange((query: string): void => { this.searchQuery = query; })
        .onSubmit((): void => { this.load(false); })
      Row({ space: 12 }) {
        Select(this.providerSelectOptions())
          .value(this.providerFilter === '__all__' ? this.text('websitesSslProviderFilterAll') : this.providerFilter)
          .height(48).layoutWeight(1)
          .onSelect((index: number): void => { this.providerFilter = this.providerOptions[index]; this.load(false); })
        Select(this.expiryOptions()).value(this.text('websitesSslExpirationViewTitle')).height(48)
          .onSelect((index: number): void => {
            this.expiryFilter = ['all', 'expired', 'within7Days', 'within30Days'][index]; this.load(false);
          })
      }
      if (this.loading) {
        LoadingProgress().width(40).height(40)
      }
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontSize(14).fontColor('#D94838').width('100%')
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(true); })
      }
      if (!this.loading && this.groups.length === 0 && this.errorMessage.length === 0) {
        Text(this.text('websitesSslListEmpty')).fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_secondary')).padding({ top: 48 })
        Button(this.text('websitesSslCreateAction')).height(48).onClick((): void => { this.openForm('create'); })
      }
      List({ space: 16 }) {
        ForEach(this.groups, (group: Map<string, Object | null>) => {
          ListItemGroup({ header: this.groupHeader(group.get('name') as string) }) {
            ForEach(group.get('certificates') as Map<string, Object | null>[], (cert: Map<string, Object | null>) => {
              ListItem() {
                Row({ space: 12 }) {
                  Column({ space: 6 }) {
                    Text(cert.get('primaryDomain') as string | null ?? '—').fontSize(16).fontWeight(FontWeight.Medium)
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                    Text(`${cert.get('provider') as string | null ?? '—'} · ${cert.get('expireDate') as string | null ?? '—'}`)
                      .fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary')).width('100%')
                  }.layoutWeight(1)
                  SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
                    .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
                }.padding(16).constraintSize({ minHeight: 80 }).width('100%')
                .onClick((): void => { this.loadCertificate(cert.get('id') as number, true); })
                .accessibilityText(cert.get('primaryDomain') as string | null ?? this.text('websitesSslInfoTitle'))
              }
            }, (cert: Map<string, Object | null>): string => String(cert.get('id')))
          }.backgroundColor($r('sys.color.ohos_id_color_foreground_contrary')).borderRadius(16)
        }, (group: Map<string, Object | null>): string => group.get('name') as string)
      }.layoutWeight(1).width('100%')
    }.padding({ left: 16, right: 16, top: 12, bottom: 12 }).width('100%').height('100%')
  }

  @Builder
  private groupHeader(name: string) {
    Text(this.groupLabel(name)).fontSize(14).fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  @Builder
  private detailContent() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) { LoadingProgress().width(40).height(40) }
        if (this.errorMessage.length > 0) { Text(this.errorMessage).fontColor('#D94838').fontSize(14) }
        Column() {
          Text(this.certText('primaryDomain')).fontSize(24).fontWeight(FontWeight.Medium).width('100%').padding({ bottom: 12 })
          this.metric({ label: this.text('websitesSslOtherDomainsLabel'), content: (this.certificate.get('domains') as string[] | null ?? []).join(', ') })
          this.metric({ label: this.text('websitesSslProviderLabel'), content: this.certText('provider') })
          this.metric({ label: this.text('websitesSslStatus'), content: this.certText('status') })
          this.metric({ label: this.text('websitesSslExpireDate'), content: this.certText('expireDate') })
          this.metric({ label: this.text('websitesSslAccountsOrganizationLabel'), content: this.certText('organization') })
          this.metric({ label: this.text('websitesSslDescriptionLabel'), content: this.certText('description') })
          this.metric({ label: this.text('websitesSslAutoRenew'), content: this.text(this.certificate.get('autoRenew') === true ? 'systemSettingsEnabled' : 'systemSettingsDisabled') })
        }.padding(16).backgroundColor($r('sys.color.ohos_id_color_foreground_contrary')).borderRadius(16)
        Button(this.text('websitesSslCertificateLabel')).height(48).width('100%')
          .buttonStyle(ButtonStyleMode.NORMAL).onClick((): void => { this.paths.pushPath({ name: 'pem' }); })
        Button(this.text('websitesSslPrivateKeyLabel')).height(48).width('100%')
          .buttonStyle(ButtonStyleMode.NORMAL).onClick((): void => { this.paths.pushPath({ name: 'privateKey' }); })
        ForEach(this.certificate.get('websites') as Map<string, Object | null>[] | null ?? [],
          (website: Map<string, Object | null>) => {
            Button({ type: ButtonType.Normal }) {
              Row({ space: 12 }) {
                Text(website.get('primaryDomain') as string | null ?? '—').fontSize(16).layoutWeight(1)
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
              }.padding(16).width('100%')
            }.height(56).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.activeWebsiteId = website.get('id') as number; this.paths.pushPath({ name: 'https' }); })
          }, (website: Map<string, Object | null>): string => String(website.get('id')))
      }.padding(16).width('100%')
    }.height('100%').width('100%').align(Alignment.TopStart)
  }

  @Builder
  private destination(name: string) {
    NavDestination() {
      if (name === 'detail') {
        this.detailContent()
      } else if (name === 'accounts') {
        HarmonyWebsiteSslAccountsPage()
      } else if (name === 'https') {
        HarmonyWebsiteHttpsPage({ websiteId: this.activeWebsiteId as number,
          onOpenCertificates: (): void => { this.openCenter(); } })
      } else if (name === 'center') {
        this.centerContent()
      } else if (name === 'pem' || name === 'privateKey') {
        Scroll() {
          Text(this.certText(name)).fontFamily('monospace').fontSize(14).copyOption(CopyOptions.LocalDevice)
            .padding(16).width('100%')
        }.height('100%').width('100%').align(Alignment.TopStart)
      } else {
        HarmonyWebsiteCertificateForm({ operation: name, certificate: this.certificate,
          onSaved: (): void => {
            this.paths.pop();
            const id = this.certId();
            if (id !== null) this.loadCertificate(id, false);
            this.load(true);
          } })
      }
    }
    .title(this.destinationTitle(name), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .menus(name === 'detail' ? this.certificateMenus() : name === 'center' ? this.centerMenus() : [])
  }

  private destinationTitle(name: string): string {
    if (name === 'detail') return this.text('websitesSslInfoTitle');
    if (name === 'accounts') return this.text('sslSettingsTitle');
    if (name === 'https') return this.text('websiteSiteSslPageTitle');
    if (name === 'center') return this.text('websitesSslPageTitle');
    if (name === 'pem') return this.text('websitesSslCertificateLabel');
    if (name === 'privateKey') return this.text('websitesSslPrivateKeyLabel');
    if (name === 'upload') return this.text('websitesSslUploadAction');
    if (name === 'update') return this.text('websitesSslUpdateAction');
    if (name === 'apply') return this.text('websitesSslApplyAction');
    if (name === 'resolve') return this.text('websitesSslResolveAction');
    return this.text('websitesSslCreateAction');
  }

  private rootMenus(): NavigationMenuItem[] {
    return this.initialRoute === '/website-certificate-detail' ? this.certificateMenus() :
      this.opensWebsiteHttps() ? [] : this.centerMenus();
  }

  build() {
    Navigation(this.paths) {
      if (this.opensWebsiteHttps() && this.activeWebsiteId !== null) {
        HarmonyWebsiteHttpsPage({ websiteId: this.activeWebsiteId,
          displayName: this.routeArguments.get('displayName') as string | null ?? '',
          onOpenCertificates: (): void => { this.openCenter(); } })
      } else if (this.initialRoute === '/website-certificate-detail') {
        this.detailContent()
      } else {
        this.centerContent()
      }
    }
    .title(this.rootTitle(), moduleTitleOptions)
    .titleMode(NavigationTitleMode.Mini)
    .menus(this.rootMenus())
    .navDestination(this.destination).mode(NavigationMode.Stack)
    .width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
  }
}
