import { HarmonyNativeBridge, menuMaterial, sheetMaterial } from '../HarmonyNativeBridge';

class HarmonyWebsiteDomainRecord {
  readonly domainId: number;
  readonly domainName: string;
  readonly port: number;
  readonly ssl: boolean;

  constructor(data: Map<string, Object | null>) {
    this.domainId = data.get('id') as number;
    this.domainName = data.get('domain') as string;
    this.port = data.get('port') as number;
    this.ssl = data.get('ssl') as boolean;
  }
}

@Component
export struct HarmonyWebsiteDomains {
  @Require @Prop websiteId: number;
  @State private domains: HarmonyWebsiteDomainRecord[] = [];
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private pageError: string = '';
  @State private showForm: boolean = false;
  @State private batchMode: boolean = false;
  @State private domainText: string = '';
  @State private portText: string = '80';
  @State private ssl: boolean = false;
  @State private formError: string = '';
  private editingId: number | null = null;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.pageError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('id', this.websiteId);
      const result = await this.bridge.invoke<Array<Map<string, Object | null>>>('getWebsiteDomains', args);
      this.domains = result.map((data: Map<string, Object | null>): HarmonyWebsiteDomainRecord =>
        new HarmonyWebsiteDomainRecord(data));
    } catch (error) {
      this.pageError = `${error}`;
    } finally {
      this.loading = false;
    }
  }

  private openForm(domain: HarmonyWebsiteDomainRecord | null, batch: boolean = false): void {
    this.editingId = domain?.domainId ?? null;
    this.domainText = domain?.domainName ?? '';
    this.portText = domain === null ? '80' : `${domain.port}`;
    this.ssl = domain?.ssl ?? false;
    this.batchMode = batch;
    this.formError = '';
    this.showForm = true;
  }

  private async submit(): Promise<void> {
    const port = Number(this.portText);
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
      this.formError = this.text('websitesDomainValidationPort');
      return;
    }
    if (this.domainText.trim().length === 0) {
      this.formError = this.text('websitesDomainValidationRequired');
      return;
    }
    this.saving = true;
    this.formError = '';
    try {
      const args = new Map<string, Object | null>();
      if (this.editingId !== null) {
        args.set('id', this.editingId);
        args.set('domain', this.domainText.trim().toLowerCase());
        args.set('port', port);
        args.set('ssl', this.ssl);
        await this.bridge.invoke<Object | null>('updateNativeWebsiteDomain', args);
      } else {
        const lines = this.domainText.split('\n')
          .map((line: string): string => line.trim().toLowerCase())
          .filter((line: string): boolean => line.length > 0);
        const entries: Map<string, Object | null>[] = [];
        const sslEnabled: boolean = this.ssl;
        const portMessage: string = this.text('websitesDomainValidationPort');
        for (const line of lines) {
          const separator = line.lastIndexOf(':');
          const domain = separator > 0 ? line.substring(0, separator) : line;
          const entryPort = separator > 0 ? Number(line.substring(separator + 1)) : port;
          if (!Number.isInteger(entryPort) || entryPort < 1 || entryPort > 65535) {
            this.formError = portMessage;
            return;
          }
          const entry = new Map<string, Object | null>();
          entry.set('domain', domain);
          entry.set('port', entryPort);
          entry.set('ssl', sslEnabled);
          entries.push(entry);
        }
        args.set('websiteID', this.websiteId);
        args.set('domains', entries);
        const result = await this.bridge.invoke<Map<string, Object | null>>('addWebsiteDomains', args);
        if (result.get('success') !== true) throw new Error(result.get('error') as string);
      }
      this.showForm = false;
      await this.load();
    } catch (error) {
      this.formError = `${error}`;
    } finally {
      this.saving = false;
    }
  }

  private deleteDomain(domain: HarmonyWebsiteDomainRecord): void {
    this.getUIContext().showAlertDialog({
      title: this.text('commonDelete'),
      message: this.text('websitesDomainDeleteMessage').replace('{domain}', domain.domainName),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('commonDelete'),
        action: (): void => { this.performDelete(domain.domainId); },
      },
    });
  }

  private async performDelete(domainId: number): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('id', domainId);
      const result = await this.bridge.invoke<Map<string, Object | null>>('deleteWebsiteDomain', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private domainMenu(domain: HarmonyWebsiteDomainRecord): MenuElement[] {
    return [
      { value: this.text('commonEdit'), action: (): void => { this.openForm(domain); } },
      { value: this.text('commonDelete'), action: (): void => { this.deleteDomain(domain); } },
    ];
  }

  @Builder
  private form() {
    Column({ space: 16 }) {
      if (this.batchMode) {
        Text(this.text('websitesDomainBatchAddHint')).fontSize(14).width('100%')
        TextArea({ text: this.domainText, placeholder: this.text('websitesDomainBatchInputLabel') })
          .height(180)
          .onChange((content: string): void => { this.domainText = content; })
      } else {
        TextInput({ text: this.domainText, placeholder: this.text('websitesDomainLabel') })
          .height(48)
          .onChange((content: string): void => { this.domainText = content; })
      }
      TextInput({ text: this.portText, placeholder: this.text('websitesDomainPortLabel') })
        .height(48)
        .type(InputType.Number)
        .onChange((content: string): void => { this.portText = content; })
      Row() {
        Text(this.text('websitesDomainSslLabel')).layoutWeight(1).fontSize(16)
        Toggle({ type: ToggleType.Switch, isOn: this.ssl })
          .accessibilityText(this.text('websitesDomainSslLabel'))
          .onChange((selected: boolean): void => { this.ssl = selected; })
      }.width('100%').height(48)
      if (this.formError.length > 0) {
        Text(this.formError).fontSize(14).width('100%')
      }
      Button(this.text('commonSave')).width('100%').height(48).enabled(!this.saving)
        .onClick((): void => { this.submit(); })
    }
    .padding(16)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Button(this.text('commonAdd')).height(48)
          .onClick((): void => { this.openForm(null); })
        Button(this.text('websitesDomainBatchAddAction')).height(48).buttonStyle(ButtonStyleMode.NORMAL)
          .onClick((): void => { this.openForm(null, true); })
        Blank()
        Button(this.text('commonRefresh')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick((): void => { this.load(); })
      }.width('100%')
      if (this.pageError.length > 0) {
        Text(this.pageError).fontSize(14).width('100%')
      }
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else {
        List({ space: 12 }) {
          ForEach(this.domains, (domain: HarmonyWebsiteDomainRecord): void => {
            ListItem() {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.worldclock')).fontSize(24)
                  .fontColor([$r('sys.color.icon_primary')])
                Column({ space: 2 }) {
                  Text(domain.domainName).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(`${domain.port}`).fontSize(14).fontColor($r('sys.color.font_secondary'))
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                if (domain.ssl) {
                  Text('HTTPS').fontSize(14).fontColor($r('sys.color.font_secondary'))
                }
                Button() {
                  SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(22)
                }.width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .accessibilityText(this.text('commonMore'))
                  .bindMenu(this.domainMenu(domain), { systemMaterial: menuMaterial })
              }
              .padding(16)
              .width('100%')
              .constraintSize({ minHeight: 72 })
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius(16)
            }
          }, (domain: HarmonyWebsiteDomainRecord): string => `${domain.domainId}`)
          if (this.domains.length === 0) {
            ListItem() { Text(this.text('websitesDomainEmpty')).padding(24).fontSize(16) }
          }
        }.layoutWeight(1).width('100%')
      }
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .bindSheet($$this.showForm, this.form, { height: SheetSize.LARGE, showClose: true, dragBar: true, systemMaterial: sheetMaterial })
  }
}
