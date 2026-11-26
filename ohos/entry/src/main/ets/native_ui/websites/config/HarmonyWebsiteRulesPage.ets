import { HarmonyNativeBridge, sheetMaterial } from '../../HarmonyNativeBridge';

@Component
export struct HarmonyWebsiteRulesPage {
  @Require @Prop websiteId: number;
  section: string = 'proxy';
  @State private items: Array<Map<string, Object | null>> = [];
  @State private servers: Array<Map<string, Object | null>> = [];
  @State private formValues: Map<string, Object | null> = new Map<string, Object | null>();
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private loadError: string = '';
  @State private formError: string = '';
  @State private showForm: boolean = false;
  @State private editingSource: boolean = false;
  @State private sourceContent: string = '';
  @State private editing: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private args(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('id', this.websiteId);
    args.set('websiteID', this.websiteId);
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      const args = this.args();
      let method = 'getWebsiteProxies';
      if (this.section === 'redirect') method = 'getWebsiteRedirects';
      if (this.section === 'pathauth') method = 'getWebsitePathAuths';
      if (this.section === 'loadbalance') method = 'getWebsiteLoadBalancers';
      if (this.section === 'auth') {
        const result = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteAuths', args);
        this.items = result.get('items') as Array<Map<string, Object | null>>;
      } else if (this.section === 'stream') {
        const result = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteStream', args);
        this.items = [result];
      } else {
        this.items = await this.bridge.invoke<Array<Map<string, Object | null>>>(method, args);
      }
    } catch (error) {
      this.loadError = `${error}`;
    } finally {
      this.loading = false;
    }
  }

  private itemName(item: Map<string, Object | null>): string {
    if (this.section === 'auth') return item.get('username') as string;
    if (this.section === 'pathauth') return item.get('path') as string;
    return item.get('name') as string;
  }

  private itemDescription(item: Map<string, Object | null>): string {
    if (this.section === 'proxy') return item.get('proxyPass') as string;
    if (this.section === 'redirect') return item.get('target') as string;
    if (this.section === 'auth' || this.section === 'pathauth') return item.get('remark') as string ?? '';
    if (this.section === 'stream') return item.get('streamPorts') as string;
    return item.get('algorithm') as string;
  }

  private formString(key: string): string {
    const content = this.formValues.get(key);
    return content === null || content === undefined ? '' : `${content}`;
  }

  private formBool(key: string): boolean {
    return this.formValues.get(key) === true;
  }

  private openForm(item: Map<string, Object | null> | null): void {
    this.editingSource = false;
    this.editing = item !== null;
    this.formError = '';
    this.formValues = item === null ? new Map<string, Object | null>() : new Map<string, Object | null>(item);
    this.servers = item?.get('servers') as Array<Map<string, Object | null>> ?? [];
    if (item === null) {
      this.formValues.set('enable', true);
      this.formValues.set('proxyProtocol', 'http://');
      this.formValues.set('match', '/');
      this.formValues.set('proxyHost', '$host');
      this.formValues.set('type', 'domain');
      this.formValues.set('redirect', '301');
      this.formValues.set('algorithm', 'default');
    } else if (this.section === 'proxy') {
      const destination = this.formString('proxyPass');
      const protocolEnd = destination.indexOf('://');
      if (protocolEnd >= 0) {
        this.formValues.set('proxyProtocol', destination.substring(0, protocolEnd + 3));
        this.formValues.set('proxyAddress', destination.substring(protocolEnd + 3));
      } else {
        this.formValues.set('proxyProtocol', '');
        this.formValues.set('proxyAddress', destination);
      }
    }
    const domains = this.formValues.get('domains') as string[] | null;
    if (domains) this.formValues.set('domainText', domains.join('\n'));
    this.showForm = true;
  }

  private openSource(item: Map<string, Object | null>): void {
    this.formValues = item;
    this.sourceContent = item.get('content') as string | null ?? '';
    this.editingSource = true;
    this.formError = '';
    this.showForm = true;
  }

  private async saveSource(): Promise<void> {
    this.saving = true;
    this.formError = '';
    try {
      const args = this.args();
      args.set('websiteId', this.websiteId);
      args.set('name', this.formString('name'));
      args.set('ruleType', this.section);
      args.set('content', this.sourceContent);
      await this.bridge.invoke<Object | null>('saveNativeWebsiteRuleSource', args);
      this.showForm = false;
      await this.load();
    } catch (error) {
      this.formError = (error as Error).message;
    } finally {
      this.saving = false;
    }
  }

  private async submit(): Promise<void> {
    this.saving = true;
    this.formError = '';
    try {
      const args = this.args();
      this.formValues.forEach((content: Object | null, key: string): void => { args.set(key, content); });
      args.set('websiteID', this.websiteId);
      args.set('id', this.websiteId);
      args.set('operate', this.editing ? 'edit' : 'create');
      let method = 'updateWebsiteProxy';
      if (this.section === 'proxy') {
        if (this.formString('serverCacheTime').length > 0) {
          args.set('serverCacheTime', Number(this.formString('serverCacheTime')));
        }
        if (this.formString('cacheTime').length > 0) args.set('cacheTime', Number(this.formString('cacheTime')));
      } else if (this.section === 'redirect') {
        method = 'updateWebsiteRedirect';
        args.set('domains', this.formString('domainText').split('\n').filter((line: string): boolean => line.length > 0));
      } else if (this.section === 'auth') {
        method = 'updateWebsiteAuth';
        args.set('scope', 'root');
      } else if (this.section === 'pathauth') {
        method = 'updateWebsitePathAuth';
      } else if (this.section === 'loadbalance') {
        method = this.editing ? 'updateWebsiteLoadBalancer' : 'createWebsiteLoadBalancer';
        args.set('servers', this.servers);
      } else if (this.section === 'stream') {
        method = 'updateWebsiteStream';
        args.set('servers', this.servers);
      }
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.showForm = false;
      await this.load();
    } catch (error) {
      this.formError = `${error}`;
    } finally {
      this.saving = false;
    }
  }

  private async perform(item: Map<string, Object | null>, operation: string): Promise<void> {
    try {
      const args = this.args();
      item.forEach((content: Object | null, key: string): void => { args.set(key, content); });
      args.set('id', this.websiteId);
      args.set('websiteID', this.websiteId);
      args.set('operate', operation);
      let method = '';
      if (this.section === 'proxy') {
        method = operation === 'delete' ? 'deleteWebsiteProxy' : 'updateWebsiteProxyStatus';
        args.set('status', operation);
      } else if (this.section === 'redirect') {
        method = 'updateWebsiteRedirect';
      } else if (this.section === 'auth') {
        method = 'updateWebsiteAuth';
        args.set('scope', 'root');
      } else if (this.section === 'pathauth') {
        method = 'updateWebsitePathAuth';
      } else if (this.section === 'loadbalance') {
        method = 'deleteWebsiteLoadBalancer';
      }
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private confirmDelete(item: Map<string, Object | null>): void {
    this.getUIContext().showAlertDialog({
      title: this.text('commonDelete'), message: this.itemName(item),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonDelete'), action: (): void => { this.perform(item, 'delete'); } },
    });
  }

  private menu(item: Map<string, Object | null>): MenuElement[] {
    const menu: MenuElement[] = [{ value: this.text('commonEdit'), action: (): void => { this.openForm(item); } }];
    if (['proxy', 'redirect', 'loadbalance'].includes(this.section) &&
      (item.get('content') as string | null ?? '').length > 0) {
      menu.push({ value: this.text('websitesConfigEditorTitle'), action: (): void => { this.openSource(item); } });
    }
    if (this.section === 'proxy' || this.section === 'redirect' || this.section === 'auth') {
      menu.push({ value: this.text('websitesActionStart'), action: (): void => { this.perform(item, 'enable'); } });
      menu.push({ value: this.text('websitesActionStop'), action: (): void => { this.perform(item, 'disable'); } });
    }
    if (this.section !== 'stream') {
      menu.push({ value: this.text('commonDelete'), action: (): void => { this.confirmDelete(item); } });
    }
    return menu;
  }

  private addServer(): void {
    const server = new Map<string, Object | null>();
    server.set('server', '');
    server.set('weight', 1);
    server.set('maxFails', 0);
    server.set('maxConns', 0);
    server.set('failTimeout', 0);
    server.set('failTimeoutUnit', 's');
    server.set('flag', '');
    this.servers = this.servers.concat([server]);
  }

  private serverString(server: Map<string, Object | null>, key: string): string {
    const content = server.get(key);
    return content === null || content === undefined ? '' : `${content}`;
  }

  private setServer(index: number, key: string, content: string, numeric: boolean): void {
    const entries = this.servers.slice();
    const server = new Map<string, Object | null>(entries[index]);
    server.set(key, numeric ? Number(content) : content);
    entries[index] = server;
    this.servers = entries;
  }

  @Builder
  private field(label: string, key: string, multiline: boolean = false, secret: boolean = false) {
    Column({ space: 8 }) {
      Text(label).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      if (multiline) {
        TextArea({ text: this.formString(key) }).height(100)
          .onChange((content: string): void => { this.formValues.set(key, content); })
      } else {
        TextInput({ text: this.formString(key) }).height(48)
          .type(secret ? InputType.Password : InputType.Normal)
          .onChange((content: string): void => { this.formValues.set(key, content); })
      }
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private toggle(label: string, key: string) {
    Row({ space: 12 }) {
      Text(label).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.formBool(key) })
        .accessibilityText(label).onChange((selected: boolean): void => { this.formValues.set(key, selected); })
    }.width('100%').constraintSize({ minHeight: 48 })
  }

  @Builder
  private serverField(server: Map<string, Object | null>, index: number, label: string, key: string, numeric: boolean = false) {
    Column({ space: 4 }) {
      Text(label).fontSize(14).width('100%')
      TextInput({ text: this.serverString(server, key) }).height(48)
        .onChange((content: string): void => { this.setServer(index, key, content, numeric); })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private serverFields() {
    ForEach(this.servers, (server: Map<string, Object | null>, index: number): void => {
      Column({ space: 12 }) {
        this.serverField(server, index, this.text('websitesLoadBalanceServerLabel'), 'server')
        this.serverField(server, index, this.text('websitesLoadBalanceWeightLabel'), 'weight', true)
        this.serverField(server, index, this.text('websitesLoadBalanceMaxFailsLabel'), 'maxFails', true)
        this.serverField(server, index, this.text('websitesLoadBalanceMaxConnsLabel'), 'maxConns', true)
        this.serverField(server, index, this.text('websitesLoadBalanceFailTimeoutLabel'), 'failTimeout', true)
        this.serverField(server, index, this.text('cronjobFormTimeoutUnitLabel'), 'failTimeoutUnit')
        this.serverField(server, index, this.text('websitesLoadBalanceFlagLabel'), 'flag')
        Button(this.text('websitesLoadBalanceRemoveServer')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick((): void => { this.servers = this.servers.filter((entry: Map<string, Object | null>, itemIndex: number): boolean => itemIndex !== index); })
      }.padding(16).width('100%').backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
    }, (server: Map<string, Object | null>, index: number): string => `${index}`)
    Button(this.text('websitesLoadBalanceAddServer')).height(48).width('100%').buttonStyle(ButtonStyleMode.NORMAL)
      .onClick((): void => { this.addServer(); })
  }

  @Builder
  private form() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.editingSource) {
          Text(this.formString('name')).fontSize(20).fontWeight(FontWeight.Medium).width('100%')
          TextArea({ text: this.sourceContent }).fontFamily('monospace').fontSize(14).height(320)
            .width('100%').onChange((content: string): void => { this.sourceContent = content; })
            .accessibilityText(this.text('websitesConfigEditorTitle'))
        } else if (this.section === 'auth' || this.section === 'pathauth') {
          this.field(this.text('commonUsername'), 'username')
          this.field(this.text('commonPassword'), 'password', false, true)
          this.field(this.text('websitesRemarkLabel'), 'remark')
          if (this.section === 'pathauth') {
            this.field(this.text('websitesProxyMatchLabel'), 'path')
            this.field(this.text('commonName'), 'name')
          }
        } else {
          this.field(this.text('commonName'), 'name')
          if (this.section === 'proxy') {
            this.toggle(this.text('websitesActionStart'), 'enable')
            this.field(this.text('websitesProxyMatchLabel'), 'match')
            this.field(this.text('websitesProtocolLabel'), 'proxyProtocol')
            this.field(this.text('websitesProxyAddressLabel'), 'proxyAddress')
            this.field('Host', 'proxyHost')
            this.toggle('SNI', 'sni')
            this.field('SNI', 'proxySSLName')
            this.toggle('TLS', 'sslVerify')
            this.toggle(this.text('websitesCacheEnableLabel'), 'cache')
            this.field(this.text('websitesCacheExpireLabel'), 'serverCacheTime')
            this.field(this.text('cronjobFormTimeoutUnitLabel'), 'serverCacheUnit')
            this.field('Cache-Control', 'browserCache')
            this.field(this.text('websitesCacheExpireLabel'), 'cacheTime')
            this.field(this.text('cronjobFormTimeoutUnitLabel'), 'cacheUnit')
            this.toggle('CORS', 'cors')
            this.field('Access-Control-Allow-Origin', 'allowOrigins')
            this.field('Access-Control-Allow-Methods', 'allowMethods')
            this.field('Access-Control-Allow-Headers', 'allowHeaders')
            this.toggle('Access-Control-Allow-Credentials', 'allowCredentials')
            this.toggle('OPTIONS', 'preflight')
          } else if (this.section === 'redirect') {
            this.toggle(this.text('websitesActionStart'), 'enable')
            this.field(this.text('websitesTypeLabel'), 'type')
            this.field('301 / 302', 'redirect')
            this.field(this.text('websitesProxyMatchLabel'), 'path')
            this.field(this.text('websitesDomainBatchInputLabel'), 'domainText', true)
            this.field('URL', 'target')
            this.toggle(this.text('filesPathLabel'), 'keepPath')
            this.toggle(this.text('filesPathLabel'), 'redirectRoot')
          } else {
            this.field(this.text('websitesLoadBalanceAlgorithmLabel'), 'algorithm')
            if (this.section === 'stream') {
              this.field(this.text('websitesStreamPortsLabel'), 'streamPorts')
              this.toggle('UDP', 'udp')
            }
            this.serverFields()
          }
        }
        if (this.formError.length > 0) {
          Text(this.formError).fontSize(14).width('100%')
        }
        Button(this.text('commonSave')).height(48).width('100%')
          .enabled(!this.saving && (!this.editingSource || this.sourceContent.trim().length > 0))
          .onClick((): void => { if (this.editingSource) this.saveSource(); else this.submit(); })
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        if (this.section !== 'stream') {
          Button(this.text('commonAdd')).height(48).onClick((): void => { this.openForm(null); })
        }
        Blank()
        Button(this.text('commonRefresh')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick((): void => { this.load(); })
      }.width('100%')
      if (this.loadError.length > 0) {
        Text(this.loadError).fontSize(14).width('100%')
      }
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else {
        List({ space: 12 }) {
          ForEach(this.items, (item: Map<string, Object | null>): void => {
            ListItem() {
              Row({ space: 12 }) {
                Column({ space: 2 }) {
                  Text(this.itemName(item)).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(this.itemDescription(item)).fontSize(14).fontColor($r('sys.color.font_secondary')).maxLines(2)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(22) }
                  .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .accessibilityText(this.text('commonMore')).bindMenu(this.menu(item))
              }.padding(16).width('100%').constraintSize({ minHeight: 72 })
                .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
                .onClick((): void => { this.openForm(item); })
            }
          }, (item: Map<string, Object | null>): string => this.itemName(item))
          if (this.items.length === 0 && this.loadError.length === 0) {
            ListItem() { Text(this.text('commonEmpty')).fontSize(16).padding(24) }
          }
        }.layoutWeight(1).width('100%').scrollBar(BarState.Auto)
      }
    }
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .bindSheet($$this.showForm, this.form, { height: SheetSize.LARGE, showClose: true, dragBar: true, systemMaterial: sheetMaterial })
  }
}
