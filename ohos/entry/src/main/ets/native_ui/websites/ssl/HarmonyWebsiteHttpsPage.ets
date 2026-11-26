import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';
import { HarmonySslSelectField, HarmonySslTextField, HarmonySslToggleField } from './HarmonyWebsiteSslFields';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyWebsiteHttpsPage {
  @Prop websiteId: number;
  @Prop displayName: string = '';
  onOpenCertificates: () => void = (): void => {};
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private errorMessage: string = '';
  @State private strategy: Map<string, Object | null> = new Map<string, Object | null>();
  @State private boundCertificate: Map<string, Object | null> = new Map<string, Object | null>();
  @State private certificates: Map<string, Object | null>[] = [];
  @State private differences: Map<string, Object | null>[] = [];
  @State private risks: Map<string, Object | null>[] = [];
  @State private hasChanges: boolean = false;
  @State private canRestore: boolean = false;
  @State private advanced: boolean = false;
  @State private httpsPorts: string = '';
  @State private protocols: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private modes: string[] = ['HTTPAlso', 'HTTPToHTTPS', 'HTTPSOnly'];
  private types: string[] = ['existed', 'manual'];

  aboutToAppear(): void { this.load(); }
  private text(key: string): string { return this.bridge.text(key); }
  private content(key: string): string { return this.strategy.get(key) as string | null ?? ''; }
  private checked(key: string): boolean { return this.strategy.get(key) === true; }

  private sync(reply: Map<string, Object | null>): void {
    this.errorMessage = reply.get('error') as string | null ?? '';
    this.strategy = reply.get('strategy') as Map<string, Object | null>;
    this.boundCertificate = reply.get('boundCertificate') as Map<string, Object | null> | null ?? new Map<string, Object | null>();
    this.certificates = reply.get('certificates') as Map<string, Object | null>[];
    this.differences = reply.get('diffs') as Map<string, Object | null>[] | null ?? [];
    this.risks = reply.get('risks') as Map<string, Object | null>[];
    this.hasChanges = reply.get('hasChanges') as boolean;
    this.canRestore = reply.get('canRestore') as boolean;
    const https = reply.get('https') as Map<string, Object | null> | null;
    this.httpsPorts = https?.get('httpsPort') as string | null ?? '';
    this.protocols = (this.strategy.get('SSLProtocol') as string[] | null ?? []).join(', ');
  }

  private requestArgs(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('websiteId', this.websiteId);
    args.set('displayName', this.displayName);
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    try {
      this.sync(await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteHttps', this.requestArgs()));
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async perform(action: string): Promise<void> {
    this.saving = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>(this.strategy);
      args.set('websiteId', this.websiteId);
      args.set('displayName', this.displayName);
      args.set('action', action);
      args.set('certificateId', this.strategy.get('websiteSSLId') ?? null);
      if (action === 'saveAdvanced') {
        args.set('SSLProtocol', this.protocols.split(/[\n,]+/).map((entry: string): string => entry.trim())
          .filter((entry: string): boolean => entry.length > 0));
      }
      this.sync(await this.bridge.invoke<Map<string, Object | null>>('performNativeWebsiteHttpsAction', args));
      if (this.errorMessage.length === 0 && action !== 'stage' && action !== 'discard') {
        this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.saving = false;
    }
  }

  private confirmAction(action: string): void {
    this.getUIContext().showAlertDialog({
      title: this.text(action === 'restore' ? 'websiteSiteSslRollbackAction' : 'hostHttpsSaveConfirmTitle'),
      message: this.displayName.length > 0 ? this.displayName : this.websiteId.toString(),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.perform(action); } },
    });
  }

  private certificateChoices(): SelectOption[] {
    const options: SelectOption[] = [{ value: this.text('websiteSiteSslNoCertificate') }];
    for (const cert of this.certificates) options.push({ value: cert.get('primaryDomain') as string | null ?? '—' });
    return options;
  }

  private selectedCertificate(): string {
    const selected = this.certificates.find((cert: Map<string, Object | null>): boolean =>
      cert.get('id') === this.strategy.get('websiteSSLId'));
    return selected?.get('primaryDomain') as string | null ?? this.text('websiteSiteSslNoCertificate');
  }

  private modeChoices(): SelectOption[] {
    return [
      { value: this.text('websitesHttpsHTTPConfigAlso') },
      { value: this.text('websitesHttpsHTTPConfigToHttps') },
      { value: this.text('websitesHttpsHTTPConfigOnly') },
    ];
  }

  private modeLabel(): string {
    return this.modeChoices()[this.modes.indexOf(this.content('httpConfig'))]?.value as string | null ?? this.content('httpConfig');
  }

  private riskText(title: string): string {
    if (title === 'HTTPS enabled without certificate') return this.text('websiteSiteSslRiskNoCertMessage');
    if (title === 'Domain mismatch') return this.text('websiteSiteSslRiskDomainMismatchMessage');
    if (title === 'Expired certificate') return this.text('websiteSiteSslRiskExpiredCertMessage');
    return this.text('websiteSiteSslRiskExpiringSoonMessage');
  }

  private diffLabel(field: string): string {
    if (field === 'enable') return this.text('websiteSiteSslDiffLabelHttps');
    if (field === 'httpConfig') return this.text('websiteSiteSslDiffLabelHttpMode');
    if (field === 'certificate') return this.text('websiteSiteSslDiffLabelCertificate');
    if (field === 'expireDate') return this.text('websiteSiteSslDiffLabelExpiration');
    return this.text('websiteSiteSslDiffLabelProvider');
  }

  @Builder
  private basicFields() {
    Column({ space: 16 }) {
      Text(this.text('websiteSiteSslStrategySection')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
      HarmonySslToggleField({ label: this.text('websiteSiteSslEnableHttpsLabel'), checked: this.checked('enable'),
        onCheckedChanged: (checked: boolean): void => { this.strategy.set('enable', checked); } })
      HarmonySslSelectField({ label: this.text('websiteSiteSslHttpModeRow'), choices: this.modeChoices(), selectedText: this.modeLabel(),
        onSelected: (index: number): void => { this.strategy.set('httpConfig', this.modes[index]); } })
      HarmonySslSelectField({ label: this.text('websiteSiteSslSelectedCertRow'), choices: this.certificateChoices(),
        selectedText: this.selectedCertificate(), onSelected: (index: number): void => {
          this.strategy.set('websiteSSLId', index === 0 ? null : this.certificates[index - 1].get('id') as number);
        } })
      Button(this.text('websiteSiteSslOpenCertCenterAction')).height(48).width('100%')
        .buttonStyle(ButtonStyleMode.TEXTUAL).onClick(this.onOpenCertificates)
      if (!this.advanced) {
        Button(this.text('websiteSiteSslPreviewAction')).height(48).width('100%').enabled(!this.saving)
          .onClick((): void => { this.perform('stage'); })
      }
    }.padding(16).backgroundColor($r('sys.color.ohos_id_color_foreground_contrary')).borderRadius(16)
  }

  @Builder
  private advancedFields() {
    Column({ space: 16 }) {
      HarmonySslSelectField({ label: this.text('websitesHttpsTypeLabel'),
        choices: this.types.map((entry: string): SelectOption => ({ value: entry })), selectedText: this.content('type'),
        onSelected: (index: number): void => { this.strategy.set('type', this.types[index]); } })
      if (this.content('type') === 'manual') {
        HarmonySslTextField({ label: this.text('websitesSslCertificateLabel'), currentText: this.content('certificate'), multiline: true,
          onTextChanged: (content: string): void => { this.strategy.set('certificate', content); } })
        HarmonySslTextField({ label: this.text('websitesSslPrivateKeyLabel'), currentText: this.content('privateKey'), multiline: true,
          onTextChanged: (content: string): void => { this.strategy.set('privateKey', content); } })
      }
      if (this.httpsPorts.length > 0) {
        Row({ space: 12 }) {
          Text(this.text('hostHttpsPortLabel')).fontSize(16).layoutWeight(1)
          Text(this.httpsPorts).fontSize(16).fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }.width('100%').constraintSize({ minHeight: 48 })
      }
      HarmonySslTextField({ label: this.text('hostHttpsProtocolLabel'), currentText: this.protocols,
        onTextChanged: (content: string): void => { this.protocols = content; } })
      HarmonySslTextField({ label: this.text('hostHttpsAlgorithmLabel'), currentText: this.content('algorithm'),
        onTextChanged: (content: string): void => { this.strategy.set('algorithm', content); } })
      HarmonySslToggleField({ label: this.text('websiteHttpsHsts'), checked: this.checked('hsts'),
        onCheckedChanged: (checked: boolean): void => { this.strategy.set('hsts', checked); } })
      HarmonySslToggleField({ label: this.text('hostHttpsHstsSubDomainsLabel'), checked: this.checked('hstsIncludeSubDomains'),
        onCheckedChanged: (checked: boolean): void => { this.strategy.set('hstsIncludeSubDomains', checked); } })
      HarmonySslToggleField({ label: this.text('hostHttpsHttp3Label'), checked: this.checked('http3'),
        onCheckedChanged: (checked: boolean): void => { this.strategy.set('http3', checked); } })
      Button(this.text('commonSave')).height(48).width('100%').enabled(!this.saving)
        .onClick((): void => { this.confirmAction('saveAdvanced'); })
    }.padding(16).backgroundColor($r('sys.color.ohos_id_color_foreground_contrary')).borderRadius(16)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) { LoadingProgress().width(40).height(40) }
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontSize(14).fontColor('#D94838').width('100%')
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }
        if (!this.loading) {
          Column({ space: 8 }) {
            Text(this.text('websiteSiteSslCurrentCertSection')).fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary')).width('100%')
            Text(this.boundCertificate.get('primaryDomain') as string | null ?? this.text('websiteSiteSslNoCertificateBound'))
              .fontSize(20).fontWeight(FontWeight.Medium).width('100%')
            Text(this.boundCertificate.get('expireDate') as string | null ?? '—').fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary')).width('100%')
          }.width('100%').padding(16).backgroundColor($r('sys.color.ohos_id_color_foreground_contrary')).borderRadius(16)
          this.basicFields()
          ForEach(this.risks, (risk: Map<string, Object | null>) => {
            Text(this.riskText(risk.get('title') as string)).fontSize(14).width('100%')
              .fontColor($r('sys.color.ohos_id_color_text_secondary')).padding({ left: 4, right: 4 })
          }, (risk: Map<string, Object | null>): string => risk.get('title') as string)
          if (this.hasChanges) {
            Column({ space: 12 }) {
              Text(this.text('websiteSiteSslStrategyDiffTitle')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
              ForEach(this.differences, (diff: Map<string, Object | null>) => {
                Column({ space: 4 }) {
                  Text(this.diffLabel(diff.get('field') as string)).fontSize(14).width('100%')
                  Text(`${String(diff.get('currentValue'))} → ${String(diff.get('nextValue'))}`).fontSize(16).width('100%')
                }.padding({ top: 4, bottom: 4 })
              }, (diff: Map<string, Object | null>): string => diff.get('field') as string)
              Button(this.text('commonSave')).height(48).width('100%').enabled(!this.saving)
                .onClick((): void => { this.confirmAction('apply'); })
              Button(this.text('commonCancel')).height(48).width('100%').enabled(!this.saving)
                .buttonStyle(ButtonStyleMode.TEXTUAL).onClick((): void => { this.perform('discard'); })
            }.padding(16).backgroundColor($r('sys.color.ohos_id_color_foreground_contrary')).borderRadius(16)
          }
          Button(this.text('websitesHttpsAdvancedTitle')).height(48).width('100%')
            .buttonStyle(ButtonStyleMode.TEXTUAL).onClick((): void => { this.advanced = !this.advanced; })
          if (this.advanced) { this.advancedFields() }
          if (this.canRestore) {
            Button(this.text('websiteSiteSslRollbackAction')).height(48).width('100%').enabled(!this.saving)
              .buttonStyle(ButtonStyleMode.TEXTUAL).onClick((): void => { this.confirmAction('restore'); })
          }
        }
      }.padding(16).width('100%')
    }.width('100%').height('100%').align(Alignment.TopStart)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
