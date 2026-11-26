import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge, menuMaterial, titleBarMaterial } from '../HarmonyNativeBridge';
import { HarmonyModulesPage } from '../modules/HarmonyModulesPage';

class HarmonyServerRecord {
  readonly serverId: string;
  readonly revision: string;
  readonly name: string;
  readonly url: string;
  readonly panelType: string;
  readonly isCurrent: boolean;
  readonly tokenValidity: number;
  readonly allowInsecureTls: boolean;
  readonly cpu: number | null;
  readonly memory: number | null;
  readonly reachable: boolean;

  constructor(record: Map<string, Object | null>) {
    this.serverId = record.get('id') as string;
    this.revision = record.get('revision') as string;
    this.name = record.get('name') as string;
    this.url = record.get('url') as string;
    this.panelType = record.get('panelType') as string;
    this.isCurrent = record.get('isCurrent') as boolean;
    this.tokenValidity = record.get('tokenValidity') as number;
    this.allowInsecureTls = record.get('allowInsecureTls') as boolean;
    this.cpu = record.get('cpu') as number | null;
    this.memory = record.get('memory') as number | null;
    this.reachable = record.get('reachable') as boolean;
  }
}

@Component
export struct HarmonyServersPage {
  @Prop initialRoute: string = '/server';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack?: () => void;
  /** 窗口宽度达到 600vp 时按官方分栏规范让列表与详情同屏显示。 */
  @State private splitLayout: boolean = false;
  @State private servers: HarmonyServerRecord[] = [];
  @State private searchQuery: string = '';
  @State private listLoading: boolean = true;
  @State private listError: string = '';
  @State private processing: boolean = false;
  @State private testing: boolean = false;
  @State private editingId: string = '';
  @State private editingRevision: string = '';
  @State private editingPanelType: string = '1panel';
  @State private originalUrl: string = '';
  @State private serverName: string = '';
  @State private serverUrl: string = '';
  @State private serverApiKey: string = '';
  @State private tokenMinutes: string = '0';
  @State private insecureTls: boolean = false;
  @State private formError: string = '';
  @State private detailId: string = '';
  @State private detailName: string = '';
  @State private detailUrl: string = '';
  @State private dashboard: Map<string, Object | null> = new Map<string, Object | null>();
  @State private detailLoading: boolean = false;
  @State private detailError: string = '';

  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private paths: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.loadInitialRoute();
  }

  private async loadInitialRoute(): Promise<void> {
    await this.loadServers();
    const serverId = this.routeArguments.get('serverId') as string | null | undefined;
    if (this.initialRoute === '/server-config' && (serverId === undefined || serverId === null)) {
      this.openForm();
      return;
    }
    if (this.initialRoute !== '/server-config' && this.initialRoute !== '/server-detail') {
      this.autoOpenOnSplit();
      return;
    }
    const server = this.servers.find((record: HarmonyServerRecord): boolean => record.serverId === serverId);
    if (server === undefined) {
      if (this.listError.length === 0) {
        this.listError = this.bridge.text('noServerSelectedDescription');
      }
    } else if (this.initialRoute === '/server-config') {
      this.openForm(server);
    } else {
      await this.openDetails(server);
    }
  }

  /** 分栏时右侧详情区需要内容，默认打开首个服务器详情，避免右侧出现空白区域。 */
  private autoOpenOnSplit(): void {
    if (!this.splitLayout || this.servers.length === 0 || this.paths.size() > 0) return;
    const first = this.visibleServers()[0];
    if (first === undefined) return;
    this.openDetails(first);
  }

  private updateSplitLayout(mode: NavigationMode): void {
    const split = mode === NavigationMode.Split;
    if (split && !this.splitLayout) {
      this.splitLayout = split;
      this.autoOpenOnSplit();
      return;
    }
    this.splitLayout = split;
  }

  private async loadServers(): Promise<void> {
    this.listLoading = true;
    this.listError = '';
    try {
      const records = await this.bridge.invoke<Array<Map<string, Object | null>>>('getServers');
      this.servers = records.map((record: Map<string, Object | null>): HarmonyServerRecord =>
        new HarmonyServerRecord(record));
    } catch (error) {
      this.listError = (error as Error).message;
    } finally {
      this.listLoading = false;
    }
  }

  private async mutate(method: string, args: Map<string, Object | null>): Promise<Map<string, Object | null>> {
    const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
    if (result.get('success') !== true) {
      throw new Error(result.get('error') as string);
    }
    return result;
  }

  private serverArguments(serverId: string): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('id', serverId);
    return args;
  }

  private percent(amount: number | null): string {
    return amount === null ? '—' : `${amount.toFixed(1)}%`;
  }

  private openForm(server?: HarmonyServerRecord): void {
    this.editingId = server?.serverId ?? '';
    this.editingRevision = server?.revision ?? '';
    this.editingPanelType = server?.panelType ?? '1panel';
    this.originalUrl = server?.url ?? '';
    this.serverName = server?.name ?? '';
    this.serverUrl = server?.url ?? '';
    this.serverApiKey = '';
    this.tokenMinutes = server === undefined ? '0' : server.tokenValidity.toString();
    this.insecureTls = server?.allowInsecureTls ?? false;
    this.formError = '';
    const path: NavPathInfo = { name: 'server-form' };
    this.paths.pushPath(path);
  }

  private readFormArguments(): Map<string, Object | null> | null {
    const name = this.serverName.trim();
    const url = this.serverUrl.trim();
    const key = this.serverApiKey.trim();
    if (name.length === 0 || url.length === 0 ||
      ((this.editingId.length === 0 || url !== this.originalUrl) && key.length === 0)) {
      this.formError = this.bridge.text('serverFormRequired');
      return null;
    }
    const minutes = Number(this.tokenMinutes);
    if (!Number.isInteger(minutes) || minutes < 0 || minutes > 9999) {
      this.formError = `${this.bridge.text('serverTokenValidity')}: 0–9999`;
      return null;
    }
    const args = new Map<string, Object | null>();
    args.set('name', name);
    args.set('url', url);
    args.set('panelType', this.editingPanelType);
    args.set('apiKey', key);
    args.set('tokenValidity', minutes);
    args.set('allowInsecureTls', this.insecureTls);
    if (this.editingId.length > 0) {
      args.set('id', this.editingId);
      args.set('revision', this.editingRevision);
    }
    this.formError = '';
    return args;
  }

  private activeForm(): boolean {
    return this.paths.getAllPathName()[this.paths.size() - 1] === 'server-form';
  }

  private async testConnection(): Promise<void> {
    if (this.testing || this.processing) return;
    const args = this.readFormArguments();
    if (args === null) return;
    this.testing = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('testHarmonyServerConnection', args);
      if (!this.activeForm()) return;
      if (result.get('success') !== true) {
        const error = result.get('error') as string | null;
        this.formError = error ? `${this.bridge.text('serverTestFailed')}: ${error}` : this.bridge.text('serverTestFailed');
        return;
      }
      const parts = [this.bridge.text('serverTestSuccess')];
      const operatingSystem = result.get('operatingSystem') as string | null;
      const responseTime = result.get('responseTimeMs') as number | null;
      if (operatingSystem) parts.push(operatingSystem);
      if (responseTime !== null) parts.push(`${responseTime} ms`);
      this.getUIContext().getPromptAction().showToast({ message: parts.join(' · ') });
    } catch (error) {
      if (this.activeForm()) this.formError = this.bridge.text('serverTestFailed');
    } finally {
      this.testing = false;
    }
  }

  private async saveServer(): Promise<void> {
    if (this.testing || this.processing) return;
    const args = this.readFormArguments();
    if (args === null) return;
    this.processing = true;
    try {
      await this.mutate(this.editingId.length > 0 ? 'updateServer' : 'addServer', args);
      this.serverApiKey = '';
      await this.loadServers();
      if (this.editingId === this.detailId) {
        const updated = this.servers.find((server: HarmonyServerRecord): boolean => server.serverId === this.detailId);
        if (updated !== undefined) {
          this.detailName = updated.name;
          this.detailUrl = updated.url;
        }
      }
      this.getUIContext().getPromptAction().showToast({ message: this.bridge.text('serverFormSaveSuccess') });
      if (this.activeForm() && !this.closeInitialDestination('server-form')) this.paths.pop();
    } catch (error) {
      this.formError = (error as Error).message;
    } finally {
      this.processing = false;
    }
  }

  private async selectServer(server: HarmonyServerRecord): Promise<void> {
    this.processing = true;
    this.listError = '';
    try {
      await this.mutate('connectServer', this.serverArguments(server.serverId));
      if (this.initialRoute === '/server-selection') {
        const onBack = this.onBack;
        if (onBack !== undefined) {
          onBack();
          return;
        }
      }
      await this.loadServers();
    } catch (error) {
      this.listError = (error as Error).message;
    } finally {
      this.processing = false;
    }
  }

  private closeInitialDestination(name: string): boolean {
    const onBack = this.onBack;
    const form = name === 'server-form' && this.initialRoute === '/server-config';
    const detail = name === 'server-detail' && this.initialRoute === '/server-detail';
    if (onBack === undefined || this.paths.size() !== 1 || (!form && !detail)) return false;
    onBack();
    return true;
  }

  private visibleServers(): HarmonyServerRecord[] {
    const query = this.searchQuery.trim().toLowerCase();
    if (query.length === 0) return this.servers;
    return this.servers.filter((server: HarmonyServerRecord): boolean =>
      server.name.toLowerCase().includes(query) || server.url.toLowerCase().includes(query));
  }

  private async openDetails(server: HarmonyServerRecord, replace: boolean = false): Promise<void> {
    this.processing = true;
    this.listError = '';
    try {
      if (!server.isCurrent) await this.mutate('connectServer', this.serverArguments(server.serverId));
      this.detailId = server.serverId;
      this.detailName = server.name;
      this.detailUrl = server.url;
      this.dashboard = new Map<string, Object | null>();
      if (replace) {
        await this.loadDashboard();
      } else {
        const path: NavPathInfo = { name: 'server-detail' };
        this.paths.pushPath(path);
      }
      await this.loadServers();
    } catch (error) {
      if (replace) {
        this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
      } else {
        this.listError = (error as Error).message;
      }
    } finally {
      this.processing = false;
    }
  }

  private chooseDetailServer(): void {
    const choices = this.servers.filter((server: HarmonyServerRecord): boolean => server.serverId !== this.detailId);
    this.getUIContext().showActionSheet({
      title: this.bridge.text('serverActionSwitch'),
      message: '',
      sheets: choices.map((server: HarmonyServerRecord): SheetInfo => ({
        title: server.name,
        action: (): void => { this.openDetails(server, true); },
      })),
    });
  }

  private async loadDashboard(): Promise<void> {
    this.detailLoading = true;
    this.detailError = '';
    try {
      this.dashboard = await this.bridge.invoke<Map<string, Object | null>>('getDashboard');
      if (this.dashboard.size === 0) {
        this.detailError = this.bridge.text('dashboardLoadFailedTitle');
      }
    } catch (error) {
      this.detailError = (error as Error).message;
    } finally {
      this.detailLoading = false;
    }
  }

  private openModules(): void {
    const path: NavPathInfo = { name: 'server-modules' };
    this.paths.pushPath(path);
  }

  private confirmDelete(server: HarmonyServerRecord): void {
    this.getUIContext().showAlertDialog({
      title: this.bridge.text('serverDeleteConfirmTitle'),
      message: this.bridge.text('serverDeleteConfirmMessage').replace('{name}', server.name),
      primaryButton: { value: this.bridge.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.bridge.text('commonDelete'),
        fontColor: $r('sys.color.ohos_id_color_alert'),
        action: (): void => { this.deleteServer(server); },
      },
    });
  }

  private async deleteServer(server: HarmonyServerRecord): Promise<void> {
    this.processing = true;
    this.listError = '';
    try {
      await this.mutate('deleteServer', this.serverArguments(server.serverId));
      await this.loadServers();
      if (this.detailId === server.serverId &&
        this.paths.getAllPathName()[this.paths.size() - 1] === 'server-detail' &&
        !this.closeInitialDestination('server-detail')) {
        this.paths.pop();
      }
    } catch (error) {
      this.listError = (error as Error).message;
    } finally {
      this.processing = false;
    }
  }

  private navigationMenus(): NavigationMenuItem[] {
    return [
      {
        value: this.bridge.text('commonRefresh'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.loadServers(); },
        isEnabled: !this.listLoading && !this.processing,
      },
      {
        value: this.bridge.text('serverAdd'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.openForm(); },
        isEnabled: !this.processing,
      },
    ];
  }

  private detailMenus(): NavigationMenuItem[] {
    const server = this.servers.find((record: HarmonyServerRecord): boolean => record.serverId === this.detailId);
    const menus: NavigationMenuItem[] = [{
      value: this.bridge.text('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !this.detailLoading,
      action: (): void => { this.loadDashboard(); },
    }];
    if (this.servers.length > 1) {
      menus.push({
        value: this.bridge.text('serverActionSwitch'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.externaldrive')),
        isEnabled: !this.processing,
        action: (): void => { this.chooseDetailServer(); },
      });
    }
    if (server !== undefined) {
      menus.push({
        value: this.bridge.text('commonEdit'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.square_and_pencil')),
        isEnabled: !this.processing,
        action: (): void => { this.openForm(server); },
      }, {
        value: this.bridge.text('commonDelete'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.trash')),
        isEnabled: !this.processing,
        action: (): void => { this.confirmDelete(server); },
      });
    }
    return menus;
  }

  @Builder
  private serverActions(server: HarmonyServerRecord) {
    Menu() {
      if (!server.isCurrent) {
        MenuItem({
          content: this.bridge.text('serverActionSwitch'),
          symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.checkmark_circle')),
        })
          .id(`harmony-server-select-${server.serverId}`)
          .enabled(!this.processing)
          .onClick((): void => { this.selectServer(server); })
      }
      MenuItem({
        content: this.bridge.text('commonEdit'),
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.square_and_pencil')),
      })
        .id(`harmony-server-edit-${server.serverId}`)
        .enabled(!this.processing)
        .onClick((): void => { this.openForm(server); })
      MenuItem({
        content: this.bridge.text('commonDelete'),
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash')),
      })
        .id(`harmony-server-delete-${server.serverId}`)
        .contentFontColor($r('sys.color.ohos_id_color_alert'))
        .enabled(!this.processing)
        .onClick((): void => { this.confirmDelete(server); })
    }
  }

  @Builder
  private serverCard(server: HarmonyServerRecord) {
    Row({ space: 4 }) {
      Button({ type: ButtonType.Normal }) {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.externaldrive'))
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_primary')])
              .width(32)
            Column({ space: 2 }) {
              Text(server.name)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(server.url)
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            if (server.isCurrent) {
              SymbolGlyph($r('sys.symbol.checkmark_circle'))
                .fontSize(20)
                .fontColor([$r('sys.color.ohos_id_color_emphasize')])
                .accessibilityText(this.bridge.text('serverCurrent'))
            }
          }
          .width('100%')
          Flex({
            wrap: FlexWrap.Wrap,
            space: { main: LengthMetrics.vp(12), cross: LengthMetrics.vp(4) },
          }) {
            Text(`${this.bridge.text('serverCpuLabel')} ${this.percent(server.cpu)}`)
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            Text(`${this.bridge.text('serverMemoryLabel')} ${this.percent(server.memory)}`)
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            Text(this.bridge.text(server.reachable ? 'serverOnline' : 'serverOffline'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
      .id(`harmony-server-details-${server.serverId}`)
      .layoutWeight(1)
      .constraintSize({ minHeight: 96 })
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .backgroundColor(Color.Transparent)
      .borderRadius(16)
      .accessibilityText(`${server.name}, ${this.bridge.text(
        this.initialRoute === '/server-selection' ? 'serverActionSwitch' : 'serverOpenDetail')}`)
      .enabled(!this.processing)
      .onClick((): void => {
        if (this.initialRoute === '/server-selection') {
          this.selectServer(server);
        } else {
          this.openDetails(server);
        }
      })
      .bindContextMenu((): void => { this.serverActions(server); }, ResponseType.LongPress,
        { systemMaterial: menuMaterial })
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.more'))
          .fontSize(24)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }
      .id(`harmony-server-menu-${server.serverId}`)
      .width(48)
      .height(48)
      .margin({ right: 8 })
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .accessibilityText(this.bridge.text('commonMore'))
      .enabled(!this.processing)
      .bindMenu((): void => { this.serverActions(server); }, { systemMaterial: menuMaterial })
    }
    .id(`harmony-server-row-${server.serverId}`)
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .borderRadius(16)
    .hoverEffect(HoverEffect.Highlight)
  }

  @Builder
  private listBody() {
    Column({ space: 12 }) {
      if (this.listError.length > 0) {
        Text(this.listError)
          .fontColor($r('sys.color.ohos_id_color_alert'))
          .padding(16)
      }
      if (this.listLoading && this.servers.length === 0) {
        LoadingProgress().width(48).height(48)
      } else if (this.servers.length === 0) {
        Column({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.externaldrive'))
            .fontSize(48)
            .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
          Text(this.bridge.text('serverListEmptyTitle')).fontSize(20).fontWeight(FontWeight.Medium)
          Text(this.bridge.text('serverListEmptyDesc'))
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          Button(this.bridge.text('serverFormTitle'))
            .id('harmony-server-add')
            .height(48)
            .onClick((): void => { this.openForm(); })
        }
        .padding(24)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ListItem() {
            Search({ placeholder: this.bridge.text('serverSearchHint') })
              .height(48)
              .accessibilityText(this.bridge.text('serverSearchHint'))
              .onChange((query: string): void => { this.searchQuery = query; })
          }
          if (this.visibleServers().length === 0) {
            ListItem() {
              Text(this.bridge.text('commonEmpty'))
                .width('100%').textAlign(TextAlign.Center)
                .fontColor($r('sys.color.ohos_id_color_text_secondary')).padding(24)
            }
          }
          ForEach(this.visibleServers(), (server: HarmonyServerRecord): void => {
            ListItem() { this.serverCard(server) }
          }, (server: HarmonyServerRecord): string => server.serverId)
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .contentStartOffset(76)
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private serverForm() {
    Scroll() {
      Column({ space: 12 }) {
        Text(this.bridge.text('serverFormName'))
          .width('100%')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        TextInput({ text: this.serverName, placeholder: this.bridge.text('serverFormNameHint') })
          .id('harmony-server-name')
          .height(48)
          .fontSize(16)
          .accessibilityText(this.bridge.text('serverFormName'))
          .enabled(!this.processing && !this.testing)
          .onChange((content: string): void => { this.serverName = content; })
        Text(this.bridge.text('serverFormUrl'))
          .width('100%')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .margin({ top: 4 })
        TextInput({ text: this.serverUrl, placeholder: this.bridge.text('serverFormUrlHint') })
          .id('harmony-server-url')
          .height(48)
          .fontSize(16)
          .type(InputType.URL)
          .accessibilityText(this.bridge.text('serverFormUrl'))
          .enabled(!this.processing && !this.testing)
          .onChange((content: string): void => { this.serverUrl = content; })
        Text(this.bridge.text('serverFormApiKey'))
          .width('100%')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .margin({ top: 4 })
        TextInput({ text: this.serverApiKey, placeholder: this.bridge.text('serverFormApiKeyHint') })
          .id('harmony-server-api-key')
          .height(48)
          .fontSize(16)
          .type(InputType.Password)
          .accessibilityText(this.bridge.text('serverFormApiKey'))
          .enabled(!this.processing && !this.testing)
          .onChange((content: string): void => { this.serverApiKey = content; })
        if (this.editingId.length > 0) {
          Text(this.bridge.text('serverFormApiKeyKeepHint'))
            .width('100%')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        Text(this.bridge.text('serverTokenValidity'))
          .width('100%')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .margin({ top: 4 })
        TextInput({ text: this.tokenMinutes })
          .id('harmony-server-token-minutes')
          .height(48)
          .fontSize(16)
          .type(InputType.Number)
          .accessibilityText(this.bridge.text('serverTokenValidity'))
          .enabled(!this.processing && !this.testing)
          .onChange((content: string): void => { this.tokenMinutes = content; })
        Row({ space: 12 }) {
          Text(this.bridge.text('serverFormAllowInsecureTls'))
            .layoutWeight(1)
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
          Toggle({ type: ToggleType.Switch, isOn: this.insecureTls })
            .id('harmony-server-insecure-tls')
            .accessibilityText(this.bridge.text('serverFormAllowInsecureTls'))
            .enabled(!this.processing && !this.testing)
            .onChange((selected: boolean): void => { this.insecureTls = selected; })
        }
        .constraintSize({ minHeight: 48 })
        Text(this.bridge.text('serverFormAllowInsecureTlsHint'))
          .width('100%')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        if (this.formError.length > 0) {
          Text(this.formError)
            .width('100%')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_alert'))
        }
        Button(this.bridge.text(this.testing ? 'serverTestTesting' : 'serverFormTest'))
          .id('harmony-server-test-connection')
          .height(48)
          .width('100%')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.processing && !this.testing)
          .onClick((): void => { this.testConnection(); })
        Button(this.bridge.text('commonSave'))
          .id('harmony-server-save')
          .height(48)
          .width('100%')
          .margin({ top: 4 })
          .enabled(!this.processing && !this.testing)
          .onClick((): void => { this.saveServer(); })
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }

  @Builder
  private dashboardRow(label: string, content: string) {
    Row({ space: 16 }) {
      Text(label)
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(content)
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }

  @Builder
  private serverDetail() {
    List({ space: 12 }) {
      ListItem() {
        Row({ space: 12 }) {
          SymbolGlyph($r('sys.symbol.externaldrive'))
            .fontSize(24)
            .fontColor([$r('sys.color.ohos_id_color_primary')])
          Text(this.detailUrl)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .layoutWeight(1)
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
        .borderRadius(16)
      }
      if (this.detailLoading) {
        ListItem() { LoadingProgress().width(48).height(48) }
      }
      if (this.detailError.length > 0) {
        ListItem() {
          Text(this.detailError)
            .fontColor($r('sys.color.ohos_id_color_alert'))
            .padding(16)
        }
      }
      if (this.dashboard.size > 0) {
        ListItem() {
          Column() {
            this.dashboardRow(this.bridge.text('dashboardCpuUsage'),
              this.percent(this.dashboard.get('cpu') as number))
            this.dashboardRow(this.bridge.text('dashboardMemoryUsage'),
              this.percent(this.dashboard.get('memory') as number))
            this.dashboardRow(this.bridge.text('dashboardDiskUsage'),
              this.percent(this.dashboard.get('disk') as number))
            this.dashboardRow(this.bridge.text('dashboardHostNameLabel'),
              this.dashboard.get('hostname') as string)
            this.dashboardRow(this.bridge.text('dashboardOsLabel'), this.dashboard.get('os') as string)
            this.dashboardRow(this.bridge.text('dashboardPanelVersionLabel'),
              this.dashboard.get('panelVersion') as string)
          }
          .padding(16)
          .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
          .borderRadius(16)
        }
      }
      ListItem() {
        Button({ type: ButtonType.Normal }) {
          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.square_grid_2x2'))
              .fontSize(24)
              .fontColor([$r('sys.color.ohos_id_color_primary')])
            Text(this.bridge.text('serverModulesTitle'))
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(16)
              .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
          }
          .width('100%')
          .padding(16)
        }
          .id('harmony-server-modules')
          .constraintSize({ minHeight: 64 })
          .width('100%')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
          .borderRadius(16)
          .onClick((): void => { this.openModules(); })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 24 })
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'server-form') {
      NavDestination() { this.serverForm() }
        .id('harmony-server-form')
        .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
        .title(this.bridge.text(this.editingId.length > 0 ? 'serverFormEditTitle' : 'serverFormTitle'), {
          barStyle: BarStyle.STANDARD,
        })
        .onBackPressed((): boolean => this.closeInitialDestination('server-form'))
        .backgroundColor($r('sys.color.background_secondary'))
        .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
    } else if (name === 'server-detail') {
      NavDestination() { this.serverDetail() }
        .id('harmony-server-detail')
        .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
        .title(this.detailName, { barStyle: BarStyle.STANDARD })
        .menus(this.detailMenus())
        .backgroundColor($r('sys.color.background_secondary'))
        .onBackPressed((): boolean => this.closeInitialDestination('server-detail'))
        .onShown((): void => { this.loadDashboard(); })
        .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
    } else if (name === 'server-modules') {
      NavDestination() { HarmonyModulesPage() }
        .id('harmony-server-module-list')
        .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
        .title(this.bridge.text('serverModulesTitle'), {
          barStyle: BarStyle.STANDARD,
        })
        .backgroundColor($r('sys.color.background_secondary'))
    }
  }

  build() {
    Navigation(this.paths) { this.listBody() }
      .id('harmony-servers-page')
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .title(this.bridge.text('serverPageTitle'), {
        barStyle: BarStyle.STACK,
        systemMaterial: titleBarMaterial,
        scrollEffectOptions: { scrollEffectType: ScrollEffectType.COMMON_BLUR },
      })
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true)
      .menus(this.navigationMenus())
      .navDestination(this.destination)
      .mode(NavigationMode.Auto)
      .navBarWidth(240)
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
      .onNavigationModeChange((mode: NavigationMode): void => {
        this.updateSplitLayout(mode);
      })
  }
}
