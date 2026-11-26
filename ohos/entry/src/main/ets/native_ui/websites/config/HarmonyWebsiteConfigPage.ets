import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';
import { HarmonyWebsiteOption } from '../HarmonyWebsiteModels';
import { HarmonyWebsiteRulesPage } from './HarmonyWebsiteRulesPage';
import { HarmonyWebsiteHttpsPage } from '../ssl/HarmonyWebsiteHttpsPage';

interface HarmonyWebsiteConfigSection {
  section: string;
  title: string;
}

@Component
export struct HarmonyWebsiteConfigPage {
  @Require @Prop websiteId: number;
  initialSection: string = 'config';
  /** 由外层 NavDestination 承载标题栏时，内层导航只负责内容与二级页，避免出现两层标题栏。 */
  @Prop embedded: boolean = false;
  @State private section: string = 'config';
  @State private loading: boolean = false;
  @State private saving: boolean = false;
  @State private pageError: string = '';
  @State private config: Map<string, Object | null> = new Map<string, Object | null>();
  @State private sourceText: string = '';
  @State private rewriteName: string = 'default';
  @State private logType: string = 'access.log';
  @State private logPage: number = 1;
  @State private runtimeIndex: number = -1;
  @State private runtimes: HarmonyWebsiteOption[] = [];
  @State private resources: Map<string, Object | null>[] = [];
  @State private databases: Map<string, Object | null>[] = [];
  @State private databaseIndex: number = -1;
  @State private scopeName: string = 'index';
  @State private scopeRows: Array<Map<string, Object | null>> = [];
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.section = this.initialSection;
    if (this.section !== 'config' && this.section !== 'routing' && this.section !== 'security' &&
      this.section !== 'https') this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private sections(): HarmonyWebsiteConfigSection[] {
    return [
      { section: 'basic', title: this.text('websitesBasicConfigTitle') },
      { section: 'nginx', title: this.text('websitesConfigEditorTitle') },
      { section: 'scope', title: this.text('websitesConfigScopeTitle') },
      { section: 'php', title: this.text('websitesPhpVersionTitle') },
      { section: 'https', title: 'HTTPS' },
      { section: 'proxy', title: this.text('websitesTabProxy') },
      { section: 'redirect', title: this.text('websiteRedirectTitle') },
      { section: 'auth', title: this.text('websiteAuthBasicTitle') },
      { section: 'pathauth', title: this.text('securitySettingsAccessControl') },
      { section: 'loadbalance', title: this.text('websitesLoadBalanceTitle') },
      { section: 'stream', title: this.text('websitesStreamTitle') },
      { section: 'cors', title: 'CORS' },
      { section: 'leech', title: this.text('websiteLeechTitle') },
      { section: 'rewrite', title: this.text('websitesTabRewrite') },
      { section: 'cache', title: this.text('websitesCacheTitle') },
      { section: 'realip', title: this.text('websitesRealIpTitle') },
      { section: 'logs', title: this.text('logsCenterTabWebsite') },
      { section: 'resource', title: this.text('websiteResourceTitle') },
    ];
  }

  private title(section: string): string {
    if (section === 'routing') return this.text('websitesTabProxy');
    if (section === 'security') return this.text('securitySettingsAccessControl');
    const item = this.sections().find((entry: HarmonyWebsiteConfigSection): boolean => entry.section === section);
    return item?.title ?? this.text('websitesConfigPageTitle');
  }

  private args(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('id', this.websiteId);
    args.set('websiteID', this.websiteId);
    args.set('websiteId', this.websiteId);
    return args;
  }

  private string(key: string): string {
    const content = this.config.get(key);
    if (content === null || content === undefined) return '';
    return `${content}`;
  }

  private bool(key: string): boolean {
    return this.config.get(key) === true;
  }

  private open(section: string): void {
    const location: NavPathInfo = { name: section };
    this.paths.pushPath(location);
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.pageError = '';
    try {
      const args = this.args();
      if (this.section === 'basic') {
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteDetail', args);
      } else if (this.section === 'nginx') {
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteNginx', args);
        this.sourceText = this.string('content');
      } else if (this.section === 'scope') {
        args.set('scope', this.scopeName);
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteScope', args);
        this.scopeRows = this.config.get('params') as Array<Map<string, Object | null>>;
      } else if (this.section === 'php') {
        const options = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteCreateOptions');
        this.runtimes = (options.get('runtimes') as Array<Map<string, Object | null>>)
          .map((item: Map<string, Object | null>): HarmonyWebsiteOption => new HarmonyWebsiteOption(item));
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteDetail', args);
        this.runtimeIndex = this.runtimes.findIndex((item: HarmonyWebsiteOption): boolean =>
          item.optionId === this.config.get('runtimeID'));
      } else if (this.section === 'cors') {
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteCors', args);
      } else if (this.section === 'leech') {
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteLeech', args);
        this.config.set('serverNamesText', (this.config.get('serverNames') as string[]).join('\n'));
      } else if (this.section === 'rewrite') {
        args.set('name', this.rewriteName);
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteRewrite', args);
        this.sourceText = this.string('content');
      } else if (this.section === 'cache') {
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteProxyCache', args);
      } else if (this.section === 'realip') {
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteRealIP', args);
      } else if (this.section === 'logs') {
        args.set('logType', this.logType);
        args.set('page', this.logPage);
        args.set('pageSize', 100);
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteLogs', args);
        this.sourceText = this.string('content');
      } else if (this.section === 'resource') {
        this.config = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteResource', args);
        this.resources = this.config.get('resources') as Map<string, Object | null>[];
        this.databases = this.config.get('databases') as Map<string, Object | null>[];
        this.databaseIndex = this.config.get('databaseId') === null || this.config.get('databaseId') === 0
          ? 0
          : this.databases.findIndex((database: Map<string, Object | null>): boolean =>
            database.get('id') === this.config.get('databaseId') && database.get('type') === this.config.get('databaseType'));
        if (this.config.get('databaseId') !== null && this.config.get('databaseId') !== 0 && this.databaseIndex >= 0) {
          this.databaseIndex++;
        }
      }
    } catch (error) {
      this.pageError = `${error}`;
    } finally {
      this.loading = false;
    }
  }

  private async save(): Promise<void> {
    this.saving = true;
    this.pageError = '';
    try {
      const args = this.args();
      let method = '';
      if (this.section === 'nginx') {
        args.set('content', this.sourceText);
        await this.bridge.invoke<Object | null>('saveNativeWebsiteNginx', args);
      } else if (this.section === 'scope') {
        args.set('scope', this.scopeName);
        args.set('params', this.scopeRows);
        await this.bridge.invoke<Object | null>('saveNativeWebsiteScope', args);
      } else if (this.section === 'php') {
        if (this.runtimeIndex < 0) return;
        args.set('runtimeId', this.runtimes[this.runtimeIndex].optionId);
        await this.bridge.invoke<Object | null>('setNativeWebsitePhp', args);
      } else if (this.section === 'resource') {
        if (this.databaseIndex < 0) return;
        if (this.databaseIndex === 0) {
          args.set('databaseId', 0);
        } else {
          const selectedDatabase = this.databases[this.databaseIndex - 1];
          args.set('databaseId', selectedDatabase.get('id') as number);
          args.set('databaseType', selectedDatabase.get('type') as string);
        }
        await this.bridge.invoke<Object | null>('setNativeWebsiteDatabase', args);
      } else {
        this.config.forEach((content: Object | null, key: string): void => { args.set(key, content); });
        if (this.section === 'cors') {
          method = 'updateWebsiteCors';
        } else if (this.section === 'leech') {
          method = 'updateWebsiteLeech';
          args.set('serverNames', this.string('serverNamesText').split('\n').filter((entry: string): boolean => entry.length > 0));
          args.set('return_', this.string('return'));
          args.set('cacheTime', Number(this.string('cacheTime')));
        } else if (this.section === 'rewrite') {
          method = 'updateWebsiteRewrite';
          args.set('name', this.rewriteName);
          args.set('content', this.sourceText);
        } else if (this.section === 'cache') {
          method = 'updateWebsiteProxyCache';
          args.set('cacheLimit', Number(this.string('cacheLimit')));
          args.set('shareCache', Number(this.string('shareCache')));
          args.set('cacheExpire', Number(this.string('cacheExpire')));
        } else if (this.section === 'realip') {
          method = 'updateWebsiteRealIP';
        }
        const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
        if (result.get('success') !== true) throw new Error(result.get('error') as string);
      }
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
      await this.load();
    } catch (error) {
      this.pageError = `${error}`;
    } finally {
      this.saving = false;
    }
  }

  private menus(): NavigationMenuItem[] {
    return [{ value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.load(); } }];
  }

  private runtimeOptions(): SelectOption[] {
    return this.runtimes.map((runtime: HarmonyWebsiteOption): SelectOption => ({ value: runtime.label }));
  }

  private updateScope(index: number, content: string): void {
    const rows = this.scopeRows.slice();
    const entry = new Map<string, Object | null>(rows[index]);
    entry.set('params', content.split(',').map((part: string): string => part.trim()));
    rows[index] = entry;
    this.scopeRows = rows;
  }

  private scopeText(entry: Map<string, Object | null>): string {
    return (entry.get('params') as string[]).join(', ');
  }

  @Builder
  private field(label: string, key: string, multiline: boolean = false) {
    Column({ space: 8 }) {
      Text(label).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      if (multiline) {
        TextArea({ text: this.string(key) }).height(120).fontSize(16)
          .onChange((content: string): void => { this.config.set(key, content); })
      } else {
        TextInput({ text: this.string(key) }).height(48).fontSize(16)
          .onChange((content: string): void => { this.config.set(key, content); })
      }
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private toggle(label: string, key: string) {
    Row({ space: 12 }) {
      Text(label).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.bool(key) })
        .accessibilityText(label)
        .onChange((selected: boolean): void => { this.config.set(key, selected); })
    }.width('100%').constraintSize({ minHeight: 48 })
  }

  @Builder
  private overview() {
    List() {
      ListItemGroup({ style: ListItemGroupStyle.CARD }) {
        ForEach(this.overviewSections(), (item: HarmonyWebsiteConfigSection): void => {
          ListItem() {
            Row({ space: 12 }) {
              Text(item.title).fontSize(16).layoutWeight(1)
              SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.icon_secondary')])
            }.padding({ left: 16, right: 16 }).width('100%').constraintSize({ minHeight: 56 })
              .onClick((): void => { this.open(item.section); })
          }
        }, (item: HarmonyWebsiteConfigSection): string => item.section)
      }
    }.padding(16).width('100%').height('100%')
  }

  private overviewSections(): HarmonyWebsiteConfigSection[] {
    const sections = this.sections();
    if (this.initialSection === 'routing') {
      return sections.filter((item: HarmonyWebsiteConfigSection): boolean =>
        ['proxy', 'redirect', 'rewrite', 'cache', 'loadbalance', 'stream'].includes(item.section));
    }
    if (this.initialSection === 'security') {
      return sections.filter((item: HarmonyWebsiteConfigSection): boolean =>
        ['https', 'auth', 'pathauth', 'cors', 'leech', 'realip'].includes(item.section));
    }
    return sections;
  }

  @Builder
  private sourceEditor(readOnly: boolean = false) {
    TextArea({ text: this.sourceText })
      .fontFamily('monospace')
      .fontSize(14)
      .height(420)
      .enabled(!readOnly)
      .onChange((content: string): void => { this.sourceText = content; })
  }

  @Builder
  private sectionForm() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) {
          LoadingProgress().width(48).height(48)
        } else {
          if (this.section === 'basic') {
            this.basicRows()
          } else if (this.section === 'nginx') {
            Text(this.string('path')).fontSize(14).width('100%').copyOption(CopyOptions.InApp)
            this.sourceEditor()
          } else if (this.section === 'scope') {
            Select([{ value: 'index' }, { value: 'limit-conn' }, { value: 'ssl' }, { value: 'cache' },
              { value: 'http-per' }, { value: 'proxy-cache' }])
              .value(this.scopeName).height(48).width('100%')
              .onSelect((index: number, label: string): void => { this.scopeName = label; this.load(); })
            ForEach(this.scopeRows, (entry: Map<string, Object | null>, index: number): void => {
              Column({ space: 8 }) {
                Text(entry.get('name') as string).fontSize(14).width('100%')
                TextInput({ text: this.scopeText(entry) }).height(48)
                  .onChange((content: string): void => { this.updateScope(index, content); })
              }.width('100%')
            }, (entry: Map<string, Object | null>): string => entry.get('name') as string)
          } else if (this.section === 'php') {
            Text(this.text('websitesRuntimeLabel')).fontSize(14).width('100%')
            Select(this.runtimeOptions()).selected(this.runtimeIndex).height(48).width('100%')
              .onSelect((index: number): void => { this.runtimeIndex = index; })
          } else if (this.section === 'cors') {
            this.toggle('CORS', 'cors')
            this.field('Access-Control-Allow-Origin', 'allowOrigins')
            this.field('Access-Control-Allow-Methods', 'allowMethods')
            this.field('Access-Control-Allow-Headers', 'allowHeaders')
            this.toggle('Access-Control-Allow-Credentials', 'allowCredentials')
            this.toggle('OPTIONS', 'preflight')
          } else if (this.section === 'leech') {
            this.toggle(this.text('websiteLeechProtection'), 'enable')
            this.field(this.text('filesTypeFile'), 'extends')
            this.field(this.text('websitesDomainBatchInputLabel'), 'serverNamesText', true)
            this.toggle('Referer: none', 'noneRef')
            this.toggle('Referer: blocked', 'blocked')
            this.field('HTTP status', 'return')
            this.toggle(this.text('websitesCacheEnableLabel'), 'cache')
            this.field(this.text('websitesCacheExpireLabel'), 'cacheTime')
            this.field(this.text('cronjobFormTimeoutUnitLabel'), 'cacheUint')
            this.toggle(this.text('logsCenterTabWebsite'), 'logEnable')
          } else if (this.section === 'rewrite') {
            TextInput({ text: this.rewriteName, placeholder: this.text('websitesRewriteNameLabel') })
              .height(48).onChange((content: string): void => { this.rewriteName = content; })
            Button(this.text('commonRefresh')).height(48).onClick((): void => { this.load(); })
            this.sourceEditor()
          } else if (this.section === 'cache') {
            this.toggle(this.text('websitesCacheEnableLabel'), 'open')
            this.field(this.text('websitesCacheLimitLabel'), 'cacheLimit')
            this.field(this.text('cronjobFormTimeoutUnitLabel'), 'cacheLimitUnit')
            this.field(this.text('websitesCacheShareLabel'), 'shareCache')
            this.field(this.text('cronjobFormTimeoutUnitLabel'), 'shareCacheUnit')
            this.field(this.text('websitesCacheExpireLabel'), 'cacheExpire')
            this.field(this.text('cronjobFormTimeoutUnitLabel'), 'cacheExpireUnit')
          } else if (this.section === 'realip') {
            this.toggle(this.text('websitesRealIpEnableLabel'), 'open')
            this.field(this.text('websitesRealIpFromLabel'), 'ipFrom', true)
            this.field(this.text('websitesRealIpHeaderLabel'), 'ipHeader')
            this.field(this.text('websitesRealIpOtherLabel'), 'ipOther')
          } else if (this.section === 'logs') {
            Select([{ value: 'access.log' }, { value: 'error.log' }]).value(this.logType).height(48)
              .onSelect((index: number, label: string): void => { this.logType = label; this.logPage = 1; this.load(); })
            Text(this.sourceText).fontSize(14).fontFamily('monospace').width('100%').copyOption(CopyOptions.InApp)
            Row({ space: 16 }) {
              Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
                .height(48).width(48).enabled(this.logPage > 1)
                .accessibilityText(this.text('commonPreviousPage'))
                .onClick((): void => { this.logPage--; this.load(); })
              Text(`${this.logPage}`).fontSize(16)
              Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }
                .height(48).width(48).enabled(!this.bool('end'))
                .accessibilityText(this.text('commonNextPage'))
                .onClick((): void => { this.logPage++; this.load(); })
            }
          } else if (this.section === 'resource') {
            this.resourceRows()
          }
          if (this.section !== 'resource' && this.section !== 'logs' && this.section !== 'basic') {
            Button(this.text('commonSave')).height(48).width('100%').enabled(!this.saving)
              .onClick((): void => { this.save(); })
          }
        }
        if (this.pageError.length > 0) {
          Text(this.pageError).fontSize(14).width('100%')
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }
      }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  private resourceType(type: string): string {
    if (type === 'app') return this.text('serverModuleApps');
    if (type === 'database') return this.text('serverModuleDatabases');
    if (type === 'runtime') return this.text('serverModuleRuntime');
    return type;
  }

  @Builder
  private basicRow(labelKey: string, content: string) {
    Row({ space: 12 }) {
      Text(this.text(labelKey)).fontSize(16).layoutWeight(1)
      Text(content.length > 0 ? content : '—').fontSize(14)
        .fontColor($r('sys.color.font_secondary')).copyOption(CopyOptions.InApp)
    }.width('100%').constraintSize({ minHeight: 56 }).padding({ left: 16, right: 16 })
  }

  @Builder
  private basicRows() {
    Column() {
      this.basicRow('websitesSitePathLabel', this.string('sitePath') || this.string('siteDir'))
      this.basicRow('websitesRuntimeLabel', this.string('runtimeName') || this.string('runtimeType'))
      this.basicRow('websitesBasicConfigDatabaseTitle', this.string('dbType'))
      this.basicRow('websitesHttpsConfigTitle', this.string('protocol'))
      this.basicRow('websitesRemarkLabel', this.string('remark'))
    }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16).width('100%')
  }

  private databaseOptions(): SelectOption[] {
    const options: SelectOption[] = [{ value: this.text('commonNone') }];
    for (const database of this.databases) {
      options.push({ value: `${database.get('name') as string} · ${database.get('databaseName') as string}` });
    }
    return options;
  }

  @Builder
  private resourceRows() {
    if (this.resources.length > 0) {
      Column() {
        ForEach(this.resources, (resource: Map<string, Object | null>) => {
          Row({ space: 12 }) {
            Text(this.resourceType(resource.get('type') as string)).fontSize(16).layoutWeight(1)
            Text(resource.get('name') as string).fontSize(14)
              .fontColor($r('sys.color.font_secondary')).copyOption(CopyOptions.InApp)
          }.width('100%').constraintSize({ minHeight: 56 }).padding({ left: 16, right: 16 })
        }, (resource: Map<string, Object | null>): string =>
          `${resource.get('type') as string}:${resource.get('resourceID') as number}`)
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16).width('100%')
    } else {
      Text(this.text('commonEmpty')).fontSize(16).width('100%').padding(16)
    }
    if (this.config.get('canChangeDatabase') === true) {
      Text(this.text('websitesBasicConfigDatabaseTitle')).fontSize(16).width('100%')
      Select(this.databaseOptions()).selected(this.databaseIndex).height(48).width('100%')
        .onSelect((index: number): void => { this.databaseIndex = index; })
      Button(this.text('commonSave')).height(48).width('100%')
        .enabled(!this.saving && this.databaseIndex >= 0)
        .onClick((): void => { this.save(); })
    }
  }

  @Builder
  private https() {
    HarmonyWebsiteHttpsPage({ websiteId: this.websiteId, onOpenCertificates: (): void => {
      this.bridge.openNativePage('/website-ssl-center').catch((error: Error): void => {
        this.getUIContext().getPromptAction().showToast({ message: error.message });
      });
    } })
  }

  @Builder
  private destination(name: string) {
    NavDestination() {
      if (name === 'proxy' || name === 'redirect' || name === 'auth' || name === 'pathauth' ||
        name === 'loadbalance' || name === 'stream') {
        HarmonyWebsiteRulesPage({ websiteId: this.websiteId, section: name })
      } else if (name === 'https') {
        this.https()
      } else {
        this.sectionForm()
      }
    }
      .title(this.title(name), { barStyle: BarStyle.STANDARD })
      .onShown((): void => {
        this.section = name;
        if (!['proxy', 'redirect', 'auth', 'pathauth', 'loadbalance', 'stream', 'https'].includes(name)) this.load();
      })
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
  }

  build() {
    Navigation(this.paths) {
      if (this.initialSection === 'config' || this.initialSection === 'routing' || this.initialSection === 'security') {
        this.overview()
      } else if (this.initialSection === 'https') {
        this.https()
      } else {
        if (this.initialSection === 'proxy' || this.initialSection === 'redirect' || this.initialSection === 'auth' ||
          this.initialSection === 'pathauth' || this.initialSection === 'loadbalance' || this.initialSection === 'stream') {
          HarmonyWebsiteRulesPage({ websiteId: this.websiteId, section: this.initialSection })
        } else {
          this.sectionForm()
        }
      }
    }
    .title(this.title(this.initialSection), { barStyle: BarStyle.STANDARD })
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(this.embedded)
    .menus(this.menus())
    .navDestination(this.destination)
    .mode(NavigationMode.Stack)
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
