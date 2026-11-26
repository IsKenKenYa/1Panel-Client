import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { HarmonyWebsiteForm } from './HarmonyWebsiteForm';
import { HarmonyWebsiteDomains } from './HarmonyWebsiteDomains';
import { HarmonyWebsiteConfigPage } from './config/HarmonyWebsiteConfigPage';
import { HarmonyWebsiteTemplatesPage } from './templates/HarmonyWebsiteTemplatesPage';
import { HarmonyOpenRestyPage } from './security/HarmonyOpenRestyPage';
import { HarmonySecurityGatewayPage } from './security/HarmonySecurityGatewayPage';
import { HarmonyWebsiteLocation, HarmonyWebsiteOption, HarmonyWebsiteRecord } from './HarmonyWebsiteModels';

interface HarmonyWebsiteSection {
  section: string;
  titleKey: string;
}

@Component
export struct HarmonyWebsitesPage {
  initialRoute: string = '/websites';
  routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};
  @State private websites: HarmonyWebsiteRecord[] = [];
  /** 窗口宽度达到 600vp 时列表与详情同屏显示。 */
  @State private splitLayout: boolean = false;
  @State private groups: HarmonyWebsiteOption[] = [];
  @State private loading: boolean = true;
  @State private pageError: string = '';
  @State private query: string = '';
  @State private selectedType: number = 0;
  @State private selectedGroup: number = 0;
  @State private selectedIds: number[] = [];
  @State private selecting: boolean = false;
  @State private pageNumber: number = 1;
  @State private total: number = 0;
  @State private detail: Map<string, Object | null> = new Map<string, Object | null>();
  @State private detailLoading: boolean = false;
  @State private detailError: string = '';
  private started: boolean = false;
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private types: string[] = ['', 'runtime', 'proxy', 'subsite', 'static'];
  private sections: HarmonyWebsiteSection[] = [
    { section: 'edit', titleKey: 'websitesLifecycleEditTitle' },
    { section: 'domains', titleKey: 'websitesDomainsPageTitle' },
    { section: 'config', titleKey: 'websitesConfigPageTitle' },
    { section: 'routing', titleKey: 'websitesTabProxy' },
    { section: 'security', titleKey: 'securitySettingsAccessControl' },
    { section: 'ssl', titleKey: 'websitesSslPageTitle' },
  ];

  aboutToAppear(): void {
    this.loadGroups();
    this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private async loadGroups(): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      const result = await this.bridge.invoke<Array<Map<string, Object | null>>>('getNativeWebsiteGroups', args);
      this.groups = result.map((item: Map<string, Object | null>): HarmonyWebsiteOption => new HarmonyWebsiteOption(item));
    } catch (error) {
      this.pageError = `${error}`;
    }
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.pageError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('page', this.pageNumber);
      args.set('pageSize', 100);
      if (this.query.trim().length > 0) args.set('name', this.query.trim());
      if (this.selectedType > 0) args.set('type', this.types[this.selectedType]);
      if (this.selectedGroup > 0) args.set('groupId', this.groups[this.selectedGroup - 1].optionId);
      const result = await this.bridge.invoke<Map<string, Object | null>>('searchNativeWebsites', args);
      this.websites = (result.get('items') as Array<Map<string, Object | null>>)
        .map((item: Map<string, Object | null>): HarmonyWebsiteRecord => new HarmonyWebsiteRecord(item));
      this.total = result.get('total') as number;
      this.selectedIds = [];
    } catch (error) {
      this.pageError = `${error}`;
    } finally {
      this.loading = false;
    }
  }

  private begin(): void {
    if (this.started) return;
    this.started = true;
    if (this.initialRoute === '/openresty' || this.initialRoute === '/openresty-source-editor') {
      this.push('openresty');
      return;
    }
    if (this.initialRoute === '/security-gateway') { this.push('gateway'); return; }
    if (this.initialRoute.startsWith('/website-template')) { this.push('templates'); return; }
    if (this.initialRoute === '/website-create') {
      this.push('create');
      return;
    }
    const websiteId = this.routeArguments.get('websiteId') as number | undefined;
    if (websiteId === undefined) return;
    let section = 'detail';
    if (this.initialRoute === '/website-edit') section = 'edit';
    if (this.initialRoute === '/website-domains') section = 'domains';
    if (this.initialRoute === '/website-config-center') section = 'config';
    if (this.initialRoute === '/website-routing-rules') section = 'routing';
    if (this.initialRoute === '/website-security-access') section = 'security';
    if (this.initialRoute === '/website-site-ssl') section = 'ssl';
    if (this.initialRoute === '/website/https') section = 'https';
    if (this.initialRoute === '/website/redirect') section = 'redirect';
    if (this.initialRoute === '/website/cors') section = 'cors';
    if (this.initialRoute === '/website/leech') section = 'leech';
    if (this.initialRoute === '/website/log') section = 'logs';
    if (this.initialRoute === '/website/auth-basic') section = 'auth';
    if (this.initialRoute === '/website/resource') section = 'resource';
    if (this.initialRoute === '/website/load-balancer') section = 'loadbalance';
    this.push(section, websiteId);
  }

  private push(section: string, websiteId?: number): void {
    if (section === 'ssl') {
      this.openNative('/website-site-ssl', websiteId ?? null);
      return;
    }
    if (websiteId === undefined) {
      const route: NavPathInfo = { name: section };
      this.paths.pushPath(route);
    } else {
      const location: HarmonyWebsiteLocation = { websiteId: websiteId, section: section };
      const route: NavPathInfo = { name: section, param: location };
      this.paths.pushPath(route);
    }
  }

  private async loadDetail(websiteId: number): Promise<void> {
    this.detailLoading = true;
    this.detailError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('id', websiteId);
      this.detail = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteDetail', args);
    } catch (error) {
      this.detailError = `${error}`;
    } finally {
      this.detailLoading = false;
    }
  }

  private value(key: string): string {
    const content = this.detail.get(key);
    return content === null || content === undefined ? '—' : `${content}`;
  }

  private toggleSelection(websiteId: number): void {
    this.selectedIds = this.selectedIds.includes(websiteId)
      ? this.selectedIds.filter((id: number): boolean => id !== websiteId)
      : this.selectedIds.concat([websiteId]);
  }

  private async operate(ids: number[], operation: string): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('ids', ids);
      args.set('operation', operation);
      await this.bridge.invoke<Object | null>('operateNativeWebsites', args);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private confirmOperation(ids: number[], operation: string, title: string): void {
    this.getUIContext().showAlertDialog({
      title: title,
      message: operation === 'delete' ? this.text('websitesBatchDeleteMessage').replace('{count}', `${ids.length}`) : title,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.operate(ids, operation); } },
    });
  }

  private async setDefault(websiteId: number): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('id', websiteId);
      await this.bridge.invoke<Object | null>('setNativeDefaultWebsite', args);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private groupMenu(): MenuElement[] {
    return this.groups.map((group: HarmonyWebsiteOption): MenuElement => ({
      value: group.label,
      action: (): void => { this.assignGroup(group.optionId); },
    }));
  }

  private async assignGroup(groupId: number): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('ids', this.selectedIds);
      args.set('groupId', groupId);
      await this.bridge.invoke<Object | null>('setNativeWebsiteGroup', args);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private openNative(route: string, websiteId: number | null = null): void {
    const args = new Map<string, Object | null>();
    if (websiteId !== null) args.set('websiteId', websiteId);
    this.bridge.openNativePage(route, args).catch((error: Error): void => {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    });
  }

  private rowMenu(website: HarmonyWebsiteRecord): MenuElement[] {
    return [
      { value: this.text('commonEdit'), action: (): void => { this.push('edit', website.websiteId); } },
      { value: this.text('websitesActionStart'), action: (): void => { this.operate([website.websiteId], 'start'); } },
      { value: this.text('websitesActionStop'), action: (): void => {
        this.confirmOperation([website.websiteId], 'stop', this.text('websitesActionStop')); } },
      { value: this.text('websitesActionRestart'), action: (): void => {
        this.confirmOperation([website.websiteId], 'restart', this.text('websitesActionRestart')); } },
      { value: this.text('websitesSetDefaultAction'), action: (): void => { this.setDefault(website.websiteId); } },
      { value: this.text('commonDelete'), action: (): void => {
        this.confirmOperation([website.websiteId], 'delete', this.text('websitesDeleteTitle')); } },
    ];
  }

  private navigationMenus(): NavigationMenuItem[] {
    return [
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); } },
      { value: this.text('websitesLifecycleCreateTitle'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.push('create'); } },
      { value: this.text('websitesTemplateTitle'), action: (): void => { this.push('templates'); } },
      { value: this.text('websitesSslPageTitle'), action: (): void => { this.openNative('/website-ssl-center'); } },
      { value: this.text('operationsRuntimesTitle'), action: (): void => { this.openNative('/runtimes'); } },
      { value: this.text('openrestyPageTitle'), action: (): void => { this.push('openresty'); } },
      { value: this.text('securityGatewayPageTitle'), action: (): void => { this.push('gateway'); } },
    ];
  }

  private typeOptions(): SelectOption[] {
    return [
      { value: this.text('websitesFilterAllTypes') },
      { value: this.text('websitesLifecycleTypeRuntime') },
      { value: this.text('websitesLifecycleTypeProxy') },
      { value: this.text('websitesLifecycleTypeSubsite') },
      { value: this.text('websitesLifecycleTypeStatic') },
    ];
  }

  private groupOptions(): SelectOption[] {
    const options: SelectOption[] = [{ value: this.text('websitesFilterAllGroups') }];
    this.groups.forEach((group: HarmonyWebsiteOption): void => { options.push({ value: group.label }); });
    return options;
  }

  private websiteStatus(status: string): string {
    if (status.toLowerCase() === 'running') return this.text('websitesStatusRunning');
    if (status.toLowerCase() === 'stopped') return this.text('websitesStatusStopped');
    return status;
  }

  private websiteType(type: string): string {
    if (type === 'runtime') return this.text('websitesLifecycleTypeRuntime');
    if (type === 'proxy') return this.text('websitesLifecycleTypeProxy');
    if (type === 'static') return this.text('websitesLifecycleTypeStatic');
    if (type === 'subsite') return this.text('websitesLifecycleTypeSubsite');
    return type;
  }

  @Builder
  private websiteRow(website: HarmonyWebsiteRecord) {
    Row({ space: 12 }) {
      if (this.selecting) {
        Checkbox().select(this.selectedIds.includes(website.websiteId))
          .onChange((): void => { this.toggleSelection(website.websiteId); })
      } else {
        SymbolGlyph($r('sys.symbol.worldclock')).fontSize(24).fontColor([$r('sys.color.icon_primary')])
      }
      Column({ space: 2 }) {
        Text(website.domain).fontSize(16).fontWeight(FontWeight.Medium).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${this.websiteStatus(website.status)} · ${this.websiteType(website.websiteType)}`)
          .fontSize(14).fontColor($r('sys.color.font_secondary')).maxLines(1)
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(22) }
        .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .accessibilityText(this.text('commonMore'))
        .bindMenu(this.rowMenu(website), { systemMaterial: menuMaterial })
    }
    .padding({ left: 16, right: 8 })
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .onClick((): void => {
      if (this.selecting) this.toggleSelection(website.websiteId);
      else this.push('detail', website.websiteId);
    })
  }

  @Builder
  private listBody() {
    Column({ space: 12 }) {
      Search({ value: this.query, placeholder: this.text('commonSearch') })
        .height(48)
        .onChange((content: string): void => { this.query = content; })
        .onSubmit((): void => { this.pageNumber = 1; this.load(); })
      Row({ space: 8 }) {
        Select(this.typeOptions()).selected(this.selectedType).layoutWeight(1).height(48)
          .onSelect((index: number): void => { this.selectedType = index; this.pageNumber = 1; this.load(); })
        Select(this.groupOptions()).selected(this.selectedGroup).layoutWeight(1).height(48)
          .onSelect((index: number): void => { this.selectedGroup = index; this.pageNumber = 1; this.load(); })
        Button(this.text(this.selecting ? 'commonCancel' : 'websitesSelectionEnable'))
          .height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick((): void => { this.selecting = !this.selecting; this.selectedIds = []; })
      }.width('100%')
      if (this.selectedIds.length > 0) {
        Row({ space: 8 }) {
          Text(`${this.selectedIds.length}`).fontSize(16)
          Button(this.text('websitesActionStart')).height(48).buttonStyle(ButtonStyleMode.NORMAL)
            .onClick((): void => { this.operate(this.selectedIds, 'start'); })
          Button(this.text('websitesActionStop')).height(48).buttonStyle(ButtonStyleMode.NORMAL)
            .onClick((): void => { this.confirmOperation(this.selectedIds, 'stop', this.text('websitesActionStop')); })
          Button(this.text('websitesSetGroupAction')).height(48).buttonStyle(ButtonStyleMode.NORMAL)
            .bindMenu(this.groupMenu(), { systemMaterial: menuMaterial })
          Button(this.text('commonDelete')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.confirmOperation(this.selectedIds, 'delete', this.text('commonDelete')); })
        }.width('100%')
      }
      if (this.pageError.length > 0) {
        Text(this.pageError).fontSize(14).width('100%')
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      }
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else {
        List({ space: 12 }) {
          if (this.websites.length > 0) {
            ListItemGroup({ style: ListItemGroupStyle.CARD }) {
              ForEach(this.websites, (website: HarmonyWebsiteRecord): void => {
                ListItem() { this.websiteRow(website) }
              }, (website: HarmonyWebsiteRecord): string => `${website.websiteId}`)
            }
          }
          if (this.websites.length === 0 && this.pageError.length === 0) {
            ListItem() { Text(this.text('websitesEmptyTitle')).fontSize(16).padding(24) }
          }
          if (this.pageNumber > 1 || this.pageNumber * 100 < this.total) {
            ListItem() {
              Row({ space: 16 }) {
                Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
                  .height(48).width(48).enabled(this.pageNumber > 1)
                  .accessibilityText(this.text('commonPreviousPage'))
                  .onClick((): void => { this.pageNumber--; this.load(); })
                Text(`${this.pageNumber}`).fontSize(16)
                Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }
                  .height(48).width(48).enabled(this.pageNumber * 100 < this.total)
                  .accessibilityText(this.text('commonNextPage'))
                  .onClick((): void => { this.pageNumber++; this.load(); })
              }.width('100%').justifyContent(FlexAlign.Center)
            }
          }
        }.layoutWeight(1).width('100%').scrollBar(BarState.Auto)
      }
    }
    .padding(16)
    .width('100%')
    .height('100%')
  }

  @Builder
  private infoRow(labelKey: string, content: string) {
    Row({ space: 12 }) {
      Text(this.text(labelKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      Text(content).fontSize(16).layoutWeight(1).textAlign(TextAlign.End).copyOption(CopyOptions.InApp)
    }.width('100%').constraintSize({ minHeight: 48 })
  }

  @Builder
  private detailBody(websiteId: number) {
    List({ space: 16 }) {
      if (this.detailLoading) {
        ListItem() { LoadingProgress().width(48).height(48) }
      }
      if (this.detailError.length > 0) {
        ListItem() { Text(this.detailError).fontSize(14) }
      }
      ListItem() {
        Column() {
          this.infoRow('websitesPrimaryDomainLabel', this.value('primaryDomain'))
          this.infoRow('websitesAliasLabel', this.value('alias'))
          this.infoRow('websitesStatusLabel', this.websiteStatus(this.value('status')))
          this.infoRow('websitesTypeLabel', this.websiteType(this.value('type')))
          this.infoRow('websitesSiteDirLabel', this.value('siteDir'))
          this.infoRow('websitesRemarkLabel', this.value('remark'))
        }.padding(16).width('100%').backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      }
      ForEach(this.sections, (section: HarmonyWebsiteSection): void => {
        ListItem() {
          Row({ space: 12 }) {
            Text(this.text(section.titleKey)).fontSize(16).layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.icon_secondary')])
          }.width('100%').constraintSize({ minHeight: 56 }).padding(16)
            .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
            .onClick((): void => { this.push(section.section, websiteId); })
        }
      }, (section: HarmonyWebsiteSection): string => section.section)
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private rootTitleBar() {
    Row({ space: 8 }) {
      Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(22) }
        .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .accessibilityText(this.text('commonBack')).onClick(this.onBack)
      Text(this.text('websitesPageTitle')).fontSize(20).fontWeight(FontWeight.Medium)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
    }.width('100%')
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'create') {
      NavDestination() {
        HarmonyWebsiteForm({ onSaved: (): void => { this.paths.pop(); this.load(); } })
      }.title(this.text('websitesLifecycleCreateTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'edit') {
      NavDestination() {
        HarmonyWebsiteForm({ websiteId: (parameter as HarmonyWebsiteLocation).websiteId,
          onSaved: (): void => { this.paths.pop(); this.load(); } })
      }.title(this.text('websitesLifecycleEditTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'detail') {
      NavDestination() { this.detailBody((parameter as HarmonyWebsiteLocation).websiteId) }
        .title(this.text('websitesDetailTitle'), { barStyle: BarStyle.STANDARD })
        .onShown((): void => { this.loadDetail((parameter as HarmonyWebsiteLocation).websiteId); })
    } else if (name === 'domains') {
      NavDestination() { HarmonyWebsiteDomains({ websiteId: (parameter as HarmonyWebsiteLocation).websiteId }) }
        .title(this.text('websitesDomainsPageTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'config' || name === 'routing' || name === 'security' || name === 'https' || name === 'redirect' ||
      name === 'cors' || name === 'leech' || name === 'logs' || name === 'auth' || name === 'resource' || name === 'loadbalance') {
      NavDestination() {
        HarmonyWebsiteConfigPage({
          websiteId: (parameter as HarmonyWebsiteLocation).websiteId, initialSection: name, embedded: true,
        })
      }.title(this.text('websitesConfigPageTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'templates') {
      NavDestination() {
        HarmonyWebsiteTemplatesPage({ initialRoute: this.initialRoute, routeArguments: this.routeArguments, embedded: true })
      }.title(this.text('websitesTemplateTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'openresty') {
      NavDestination() {
        HarmonyOpenRestyPage({
          showSourceEditor: this.initialRoute === '/openresty-source-editor',
          initialSource: this.routeArguments.get('initialContent') as string | null ?? null,
          onOpenApps: (): void => { this.openNative('/apps'); },
          embedded: true,
        })
      }.title(this.text('openrestyPageTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'gateway') {
      NavDestination() {
        HarmonySecurityGatewayPage({
          onOpenPanelTls: (): void => { this.openNative('/panel-ssl'); },
          onOpenCertificates: (): void => { this.openNative('/website-ssl-center'); },
          onOpenWebsiteStrategy: (websiteId: number): void => { this.openNative('/website-site-ssl', websiteId); },
          onOpenOpenResty: (): void => { this.push('openresty'); },
          embedded: true,
        })
      }.title(this.text('securityGatewayPageTitle'), { barStyle: BarStyle.STANDARD })
    }
  }

  private updateSplitLayout(mode: NavigationMode): void {
    this.splitLayout = mode === NavigationMode.Split;
  }

  build() {
    Navigation(this.paths) { this.listBody() }
      .title(this.rootTitleBar, { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true)
      .menus(this.navigationMenus())
      .navDestination(this.destination)
      .mode(NavigationMode.Auto)
      .navBarWidth(240)
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
      .width('100%')
      .height('100%')
      .onAppear((): void => { this.begin(); })
      .onNavigationModeChange((mode: NavigationMode): void => {
        this.updateSplitLayout(mode);
      })
  }
}
