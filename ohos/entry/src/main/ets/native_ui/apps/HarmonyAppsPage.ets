import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { HarmonySplitPlaceholderContent } from '../HarmonySplitPlaceholder';
import { HarmonyAppDestinationArgs, HarmonyAppIcon, HarmonyCatalogApp, HarmonyInstalledApp } from './HarmonyAppModels';
import { HarmonyAppInstallPage } from './HarmonyAppInstallPage';
import { HarmonyAppConfigPage } from './HarmonyAppConfigPage';
import { HarmonyInstalledAppPage } from './HarmonyInstalledAppPage';
import { HarmonyAppCatalogPage } from './HarmonyAppCatalogPage';
import { HarmonyIgnoredAppsPage } from './HarmonyIgnoredAppsPage';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyAppsPage {
  @Prop initialRoute: string = '/apps';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @State private installedApps: HarmonyInstalledApp[] = [];
  @State private catalogApps: HarmonyCatalogApp[] = [];
  @State private selectedTab: number = 0;
  @State private searchText: string = '';
  @State private loading: boolean = false;
  @State private operating: boolean = false;
  @State private errorMessage: string = '';
  @State private selectedTags: string[] = [];
  @State private hasMore: boolean = false;
  /** 窗口宽度达到 600vp 时让应用列表与详情同屏显示。 */
  @State private splitLayout: boolean = false;
  private page: number = 1;
  private initialOpened: boolean = false;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly paths: NavPathStack = new NavPathStack();
  private readonly splitPlaceholder: HarmonySplitPlaceholderContent =
    new HarmonySplitPlaceholderContent($r('sys.symbol.square_grid_2x2'));

  aboutToAppear(): void {
    this.selectedTab = this.initialRoute === '/app-store' || this.initialRoute === '/app-detail' ? 1 : 0;
    this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private async load(more: boolean = false): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    this.errorMessage = '';
    try {
      const nextPage = more ? this.page + 1 : 1;
      const args = new Map<string, Object | null>();
      args.set('page', nextPage);
      args.set('pageSize', 50);
      args.set('search', this.searchText);
      if (this.selectedTab === 0) {
        const data = await this.bridge.invoke<Array<Map<string, Object | null>>>('getApps', args);
        const apps = data.map((entry: Map<string, Object | null>): HarmonyInstalledApp =>
          new HarmonyInstalledApp(entry));
        this.installedApps = more ? this.installedApps.concat(apps) : apps;
        this.hasMore = data.length === 50;
      } else {
        args.set('tags', this.selectedTags);
        const data = await this.bridge.invoke<Array<Map<string, Object | null>>>('getAppStore', args);
        const apps = data.map((entry: Map<string, Object | null>): HarmonyCatalogApp =>
          new HarmonyCatalogApp(entry));
        this.catalogApps = more ? this.catalogApps.concat(apps) : apps;
        this.hasMore = data.length === 50;
      }
      this.page = nextPage;
      await this.openInitialDetail();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async openInitialDetail(): Promise<void> {
    if (this.initialOpened) return;
    if (this.initialRoute === '/installed-app-detail') {
      const id = this.routeArguments.get('installId') ?? this.routeArguments.get('appId');
      if (id !== undefined && id !== null) {
        this.openInstalled(Number(id));
      }
    } else if (this.initialRoute === '/app-detail') {
      const key = this.routeArguments.get('key') as string | undefined;
      const id = this.routeArguments.get('appId');
      let app = this.catalogApps.find((entry: HarmonyCatalogApp): boolean =>
        entry.appKey === key || `${entry.appId}` === `${id}`);
      if (app === undefined && key !== undefined) {
        const args = new Map<string, Object | null>();
        args.set('key', key);
        app = new HarmonyCatalogApp(await this.bridge.invoke<Map<string, Object | null>>('getAppDetailByKey', args));
      }
      if (app !== undefined) this.openCatalog(app);
    }
    this.initialOpened = true;
  }

  private async switchTab(index: number): Promise<void> {
    if (this.selectedTab === index) return;
    this.selectedTab = index;
    this.searchText = '';
    await this.load();
  }

  private openInstalled(installId: number): void {
    const args = new HarmonyAppDestinationArgs(installId);
    this.paths.pushPath({ name: 'installed', param: args });
  }

  private openCatalog(app: HarmonyCatalogApp): void {
    const args = new HarmonyAppDestinationArgs(undefined, app);
    this.paths.pushPath({ name: 'catalog', param: args });
  }

  private async synchronize(method: string): Promise<void> {
    this.operating = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>(method);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.getUIContext().getPromptAction().showToast({ message: this.text('appStoreSyncSuccess') });
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.operating = false;
    }
  }

  private menus(): NavigationMenuItem[] {
    return [
      {
        value: this.text('commonRefresh'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        isEnabled: !this.loading,
        action: (): void => { this.load(); },
      },
      {
        value: this.text('appStoreSync'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_down_circle')),
        isEnabled: !this.operating,
        action: (): void => { this.synchronize(this.selectedTab === 0 ? 'syncInstalledApps' : 'syncRemoteApps'); },
      },
    ];
  }

  /** 侧栏栏宽有限，低频动作通过列表侧「更多」菜单承载。 */
  private listActions(): MenuElement[] {
    return [
      {
        value: this.text('appStoreSyncLocal'),
        action: (): void => { this.synchronize('syncLocalApps'); },
      },
      {
        value: this.text('appIgnoredUpdatesTitle'),
        action: (): void => { this.paths.pushPath({ name: 'ignored' }); },
      },
    ];
  }

  private displayedInstalled(): HarmonyInstalledApp[] {
    const search = this.searchText.trim().toLowerCase();
    return this.installedApps.filter((app: HarmonyInstalledApp): boolean =>
      app.name.toLowerCase().includes(search));
  }

  private tagText(tag: string): string {
    if (tag === 'WebSite') return this.text('appStoreTagWebsite');
    if (tag === 'Database') return this.text('appStoreTagDatabase');
    if (tag === 'Runtime') return this.text('appStoreTagRuntime');
    if (tag === 'Tool') return this.text('appStoreTagTool');
    if (tag === 'Docker') return this.text('appStoreTagDocker');
    if (tag === 'CI/CD') return this.text('appStoreTagCICD');
    return this.text('appStoreTagMonitoring');
  }

  private changeTag(tag: string, selected: boolean): void {
    this.selectedTags = selected ? this.selectedTags.concat([tag])
      : this.selectedTags.filter((entry: string): boolean => entry !== tag);
    this.load();
  }

  @Builder
  private installedRow(app: HarmonyInstalledApp) {
    ListItem() {
      Row({ space: 12 }) {
        HarmonyAppIcon({ source: app.icon, appKey: app.appKey })
        Column({ space: 2 }) {
          Text(app.name).fontSize(16).fontWeight(FontWeight.Medium).maxLines(1)
          Text(`${app.version} · ${app.status}`)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(2)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }
      .width('100%')
      .constraintSize({ minHeight: 72 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(16)
      .id(`harmony.apps.installed.${app.installId}`)
      .accessibilityGroup(true)
      .accessibilityText(`${app.name}, ${app.version}, ${app.status}`)
      .onClick((): void => { this.openInstalled(app.installId); })
    }
  }

  @Builder
  private catalogRow(app: HarmonyCatalogApp) {
    ListItem() {
      Row({ space: 12 }) {
        HarmonyAppIcon({ source: app.icon, appKey: app.appKey })
        Column({ space: 2 }) {
          Text(app.name).fontSize(16).fontWeight(FontWeight.Medium).maxLines(1)
          Text(app.description)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(2)
          if (app.installed) {
            Text(this.text('appStoreInstalled')).fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_primary'))
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }
      .width('100%')
      .constraintSize({ minHeight: 72 })
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(16)
      .id(`harmony.apps.catalog.${app.appKey}`)
      .accessibilityGroup(true)
      .accessibilityText(`${app.name}, ${app.description}`)
      .onClick((): void => { this.openCatalog(app); })
    }
  }

  @Builder
  private bodyContent() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Button(this.text('appStoreInstalled'), { buttonStyle: ButtonStyleMode.NORMAL })
          .layoutWeight(1).height(48)
          .enabled(!this.loading)
          .fontColor(this.selectedTab === 0 ? $r('sys.color.ohos_id_color_primary') : $r('sys.color.ohos_id_color_text_secondary'))
          .onClick((): void => { this.switchTab(0); })
        Button(this.text('appStoreTitle'), { buttonStyle: ButtonStyleMode.NORMAL })
          .layoutWeight(1).height(48)
          .enabled(!this.loading)
          .fontColor(this.selectedTab === 1 ? $r('sys.color.ohos_id_color_primary') : $r('sys.color.ohos_id_color_text_secondary'))
          .onClick((): void => { this.switchTab(1); })
      }
      .width('100%')
      Row({ space: 8 }) {
        Search({ value: this.searchText, placeholder: this.text('appStoreSearchHint') })
          .layoutWeight(1)
          .height(48)
          .onChange((content: string): void => { this.searchText = content; })
          .onSubmit((): void => { this.load(); })
        if (this.splitLayout) {
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.TEXTUAL }) {
            SymbolGlyph($r('sys.symbol.more')).fontSize(22)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
          }
          .width(48).height(48)
          .accessibilityText(this.text('commonMore'))
          .bindMenu(this.listActions(), { systemMaterial: menuMaterial })
        }
      }
      .width('100%')
      if (this.selectedTab === 1) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(['WebSite', 'Database', 'Runtime', 'Tool', 'Docker', 'CI/CD', 'Monitoring'], (tag: string): void => {
              Toggle({ type: ToggleType.Button, isOn: this.selectedTags.includes(tag) }) {
                Text(this.tagText(tag)).fontSize(14)
              }
              .height(48).padding({ left: 12, right: 12 })
              .enabled(!this.loading)
              .onChange((selected: boolean): void => { this.changeTag(tag, selected); })
            }, (tag: string): string => tag)
          }
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      }
      if (this.loading) {
        LoadingProgress().width(40).height(40)
      }
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontSize(14)
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      }
      List({ space: 8 }) {
        if (this.selectedTab === 0) {
          if (this.displayedInstalled().length === 0 && !this.loading) {
            ListItem() {
              Text(this.text('appsInstalledEmptyDescription'))
                .fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary')).padding(24)
            }
          }
          ForEach(this.displayedInstalled(), (app: HarmonyInstalledApp): void => {
            this.installedRow(app)
          }, (app: HarmonyInstalledApp): string => `${app.installId}`)
        } else {
          if (this.catalogApps.length === 0 && !this.loading) {
            ListItem() { Text(this.text('appsListEmptyTitle')).padding(24) }
          }
          ForEach(this.catalogApps, (app: HarmonyCatalogApp): void => {
            this.catalogRow(app)
          }, (app: HarmonyCatalogApp): string => app.appKey)
        }
        if (this.hasMore && !this.loading) {
          ListItem() {
            Button(this.text('commonMore'), { buttonStyle: ButtonStyleMode.TEXTUAL })
              .height(48).width('100%').onClick((): void => { this.load(true); })
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .onReachEnd((): void => { if (this.hasMore && !this.loading) this.load(true); })
    }
    .padding({ left: 16, right: 16, top: 64, bottom: 16 })
    .width('100%')
    .height('100%')
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'installed') {
      HarmonyInstalledAppPage({ installId: (parameter as HarmonyAppDestinationArgs).installId as number })
    } else if (name === 'catalog') {
      HarmonyAppCatalogPage({ app: (parameter as HarmonyAppDestinationArgs).catalog as HarmonyCatalogApp })
    } else if (name === 'install') {
      HarmonyAppInstallPage({
        appId: ((parameter as HarmonyAppDestinationArgs).catalog as HarmonyCatalogApp).appId,
        appKey: ((parameter as HarmonyAppDestinationArgs).catalog as HarmonyCatalogApp).appKey,
        appName: ((parameter as HarmonyAppDestinationArgs).catalog as HarmonyCatalogApp).name,
        appType: ((parameter as HarmonyAppDestinationArgs).catalog as HarmonyCatalogApp).appType,
        versions: ((parameter as HarmonyAppDestinationArgs).catalog as HarmonyCatalogApp).versions,
      })
    } else if (name === 'config') {
      HarmonyAppConfigPage({ installId: (parameter as HarmonyAppDestinationArgs).installId as number })
    } else if (name === 'ignored') {
      HarmonyIgnoredAppsPage()
    }
  }

  private updateSplitLayout(mode: NavigationMode): void {
    this.splitLayout = mode === NavigationMode.Split;
  }

  build() {
    Navigation(this.paths) { this.bodyContent() }
      .id('harmony.apps.root')
      .title(this.text('appsPageTitle'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true)
      .menus(this.menus())
      .navDestination(this.destination)
      .mode(NavigationMode.Auto)
      .navBarWidth(240)
      .splitPlaceholder(this.splitPlaceholder.content(this.getUIContext()))
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
      .width('100%')
      .height('100%')
      .onNavigationModeChange((mode: NavigationMode): void => {
        this.updateSplitLayout(mode);
      })
  }
}
