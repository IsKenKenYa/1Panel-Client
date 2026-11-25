import { LengthMetrics, SymbolGlyphModifier, uiMaterial } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
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
  @State private servers: HarmonyServerRecord[] = [];
  @State private listLoading: boolean = true;
  @State private listError: string = '';
  @State private processing: boolean = false;
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
  @State private detailName: string = '';
  @State private detailUrl: string = '';
  @State private dashboard: Map<string, Object | null> = new Map<string, Object | null>();
  @State private detailLoading: boolean = false;
  @State private detailError: string = '';

  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private paths: NavPathStack = new NavPathStack();
  private titleMaterial: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    interactive: true,
    lightEffect: {},
  });

  aboutToAppear(): void {
    this.loadServers();
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

  private async saveServer(): Promise<void> {
    const name = this.serverName.trim();
    const url = this.serverUrl.trim();
    const key = this.serverApiKey.trim();
    if (name.length === 0 || url.length === 0 ||
      ((this.editingId.length === 0 || url !== this.originalUrl) && key.length === 0)) {
      this.formError = this.bridge.text('serverFormRequired');
      return;
    }
    const minutes = Number(this.tokenMinutes);
    if (!Number.isInteger(minutes) || minutes < 0 || minutes > 9999) {
      this.formError = `${this.bridge.text('serverTokenValidity')}: 0–9999`;
      return;
    }
    this.processing = true;
    this.formError = '';
    try {
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
      await this.mutate(this.editingId.length > 0 ? 'updateServer' : 'addServer', args);
      this.serverApiKey = '';
      await this.loadServers();
      this.paths.pop();
      this.getUIContext().getPromptAction().showToast({ message: this.bridge.text('serverFormSaveSuccess') });
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
      await this.loadServers();
    } catch (error) {
      this.listError = (error as Error).message;
    } finally {
      this.processing = false;
    }
  }

  private async openDetails(server: HarmonyServerRecord): Promise<void> {
    this.processing = true;
    this.listError = '';
    try {
      await this.mutate('connectServer', this.serverArguments(server.serverId));
      this.detailName = server.name;
      this.detailUrl = server.url;
      this.dashboard = new Map<string, Object | null>();
      const path: NavPathInfo = { name: 'server-detail' };
      this.paths.pushPath(path);
      await this.loadServers();
    } catch (error) {
      this.listError = (error as Error).message;
    } finally {
      this.processing = false;
    }
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

  @Builder
  private serverCard(server: HarmonyServerRecord) {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(server.name)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
          Text(server.url)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        if (server.isCurrent) {
          Text(this.bridge.text('serverCurrent'))
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_emphasize'))
        }
      }
      Flex({
        wrap: FlexWrap.Wrap,
        space: { main: LengthMetrics.vp(16), cross: LengthMetrics.vp(8) },
      }) {
        Text(`${this.bridge.text('serverCpuLabel')} ${this.percent(server.cpu)}`)
        Text(`${this.bridge.text('serverMemoryLabel')} ${this.percent(server.memory)}`)
        Text(this.bridge.text(server.reachable ? 'serverOnline' : 'serverOffline'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .width('100%')
      Row({ space: 8 }) {
        Button(this.bridge.text('serverOpenDetail'))
          .id(`harmony-server-details-${server.serverId}`)
          .height(48)
          .layoutWeight(1)
          .enabled(!this.processing)
          .onClick((): void => { this.openDetails(server); })
        Button(this.bridge.text('commonEdit'), { buttonStyle: ButtonStyleMode.NORMAL })
          .height(48)
          .onClick((): void => { this.openForm(server); })
          .enabled(!this.processing)
        Button(this.bridge.text('commonDelete'), { buttonStyle: ButtonStyleMode.NORMAL })
          .height(48)
          .fontColor($r('sys.color.ohos_id_color_alert'))
          .onClick((): void => { this.confirmDelete(server); })
          .enabled(!this.processing)
      }
      if (!server.isCurrent) {
        Button(this.bridge.text('serverActionSwitch'), { buttonStyle: ButtonStyleMode.TEXTUAL })
          .id(`harmony-server-select-${server.serverId}`)
          .height(48)
          .width('100%')
          .enabled(!this.processing)
          .onClick((): void => { this.selectServer(server); })
      }
    }
    .id(`harmony-server-row-${server.serverId}`)
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .borderRadius(20)
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
          Text(this.bridge.text('serverListEmptyTitle')).fontSize(22)
          Text(this.bridge.text('serverListEmptyDesc'))
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
          ForEach(this.servers, (server: HarmonyServerRecord): void => {
            ListItem() { this.serverCard(server) }
          }, (server: HarmonyServerRecord): string => server.serverId)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
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
        Text(this.bridge.text('serverFormName')).width('100%')
        TextInput({ text: this.serverName, placeholder: this.bridge.text('serverFormNameHint') })
          .id('harmony-server-name')
          .height(48)
          .accessibilityText(this.bridge.text('serverFormName'))
          .onChange((content: string): void => { this.serverName = content; })
        Text(this.bridge.text('serverFormUrl')).width('100%')
        TextInput({ text: this.serverUrl, placeholder: this.bridge.text('serverFormUrlHint') })
          .id('harmony-server-url')
          .height(48)
          .type(InputType.URL)
          .accessibilityText(this.bridge.text('serverFormUrl'))
          .onChange((content: string): void => { this.serverUrl = content; })
        Text(this.bridge.text('serverFormApiKey')).width('100%')
        TextInput({ text: this.serverApiKey, placeholder: this.bridge.text('serverFormApiKeyHint') })
          .id('harmony-server-api-key')
          .height(48)
          .type(InputType.Password)
          .accessibilityText(this.bridge.text('serverFormApiKey'))
          .onChange((content: string): void => { this.serverApiKey = content; })
        if (this.editingId.length > 0) {
          Text(this.bridge.text('serverFormApiKeyKeepHint'))
            .width('100%')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        Text(this.bridge.text('serverTokenValidity')).width('100%')
        TextInput({ text: this.tokenMinutes })
          .id('harmony-server-token-minutes')
          .height(48)
          .type(InputType.Number)
          .accessibilityText(this.bridge.text('serverTokenValidity'))
          .onChange((content: string): void => { this.tokenMinutes = content; })
        Row({ space: 12 }) {
          Text(this.bridge.text('serverFormAllowInsecureTls')).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.insecureTls })
            .id('harmony-server-insecure-tls')
            .accessibilityText(this.bridge.text('serverFormAllowInsecureTls'))
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
            .fontColor($r('sys.color.ohos_id_color_alert'))
        }
        Button(this.bridge.text('commonSave'))
          .id('harmony-server-save')
          .height(48)
          .width('100%')
          .enabled(!this.processing)
          .onClick((): void => { this.saveServer(); })
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }

  @Builder
  private dashboardRow(label: string, content: string) {
    Row({ space: 16 }) {
      Text(label).fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(content).layoutWeight(1).textAlign(TextAlign.End)
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }

  @Builder
  private serverDetail() {
    List({ space: 12 }) {
      ListItem() {
        Column({ space: 8 }) {
          Text(this.detailName).fontSize(24).fontWeight(FontWeight.Medium)
          Text(this.detailUrl).fontColor($r('sys.color.ohos_id_color_text_secondary'))
          Button(this.bridge.text('commonRefresh'), { buttonStyle: ButtonStyleMode.NORMAL })
            .height(48)
            .enabled(!this.detailLoading)
            .onClick((): void => { this.loadDashboard(); })
        }
        .width('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
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
          .borderRadius(20)
        }
      }
      ListItem() {
        Button(this.bridge.text('serverModulesTitle'), { buttonStyle: ButtonStyleMode.NORMAL })
          .id('harmony-server-modules')
          .height(48)
          .width('100%')
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
          systemMaterial: this.titleMaterial,
        })
        .backgroundColor($r('sys.color.ohos_id_color_background'))
    } else if (name === 'server-detail') {
      NavDestination() { this.serverDetail() }
        .id('harmony-server-detail')
        .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
        .title(this.detailName, { barStyle: BarStyle.STANDARD, systemMaterial: this.titleMaterial })
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .onShown((): void => { this.loadDashboard(); })
    } else if (name === 'server-modules') {
      NavDestination() { HarmonyModulesPage() }
        .id('harmony-server-module-list')
        .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
        .title(this.bridge.text('serverModulesTitle'), {
          barStyle: BarStyle.STANDARD,
          systemMaterial: this.titleMaterial,
        })
        .backgroundColor($r('sys.color.ohos_id_color_background'))
    }
  }

  build() {
    Navigation(this.paths) { this.listBody() }
      .id('harmony-servers-page')
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .title(this.bridge.text('serverPageTitle'), { barStyle: BarStyle.STANDARD, systemMaterial: this.titleMaterial })
      .titleMode(NavigationTitleMode.Mini)
      .menus(this.navigationMenus())
      .navDestination(this.destination)
      .mode(NavigationMode.Stack)
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
