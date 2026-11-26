import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { handleActivationKey } from '../HarmonyInteractionUtils';
import { HarmonyComputeField, HarmonyComputeInfo, HarmonyComputeToggle, computeArguments, computeWrite } from './HarmonyComputeControls';

@Component
export struct HarmonyAIPage {
  @Prop initialRoute: string = '/ai';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @Prop showBack: boolean = true;
  onBack: () => void = (): void => {};
  @State private selectedTab: number = 0;
  /** 窗口宽度达到 600vp 时列表与详情同屏显示。 */
  @State private splitLayout: boolean = false;
  @State private ollama: Map<string, Object | null>[] = [];
  @State private gpus: Map<string, Object | null>[] = [];
  @State private featured: Map<string, Object | null>[] = [];
  @State private market: Map<string, Object | null>[] = [];
  @State private downloadTasks: Map<string, Object | null>[] = [];
  @State private localModels: Map<string, Object | null>[] = [];
  @State private accounts: Map<string, Object | null>[] = [];
  @State private providers: Map<string, Object | null>[] = [];
  @State private agents: Map<string, Object | null>[] = [];
  @State private servers: Map<string, Object | null>[] = [];
  @State private binding: Map<string, Object | null> = new Map<string, Object | null>();
  @State private selected: Map<string, Object | null> = new Map<string, Object | null>();
  @State private selectedAgent: Map<string, Object | null> = new Map<string, Object | null>();
  @State private agentDetails: Map<string, Object | null>[] = [];
  @State private foundExtensions: Map<string, Object | null>[] = [];
  @State private extensionQuery: string = '';
  @State private skillSourceIndex: number = 0;
  @State private detail: Map<string, Object | null> = new Map<string, Object | null>();
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private searchText: string = '';
  @State private source: string = 'hf';
  @State private modelSort: number = 0;
  @State private modelRepo: string = '';
  @State private modelSource: string = 'hf';
  @State private modelRevision: string = '';
  @State private modelDownloadType: string = 'all';
  @State private modelInfo: Map<string, Object | null> = new Map<string, Object | null>();
  @State private modelDir: string = '';
  @State private hfEndpoint: string = '';
  @State private hfToken: string = '';
  @State private modelScopeEndpoint: string = '';
  @State private modelScopeToken: string = '';
  @State private modelAutoSync: boolean = true;
  @State private modelRemoveFiles: boolean = false;
  @State private agentSection: number = 0;
  @State private formKind: string = '';
  @State private nameText: string = '';
  @State private typeText: string = 'stdio';
  @State private commandText: string = '';
  @State private urlText: string = '';
  @State private containerText: string = '';
  @State private portText: string = '8080';
  @State private outputTransportText: string = 'streamable-http';
  @State private ssePathText: string = '';
  @State private httpPathText: string = '';
  @State private repoText: string = '';
  @State private agentTypeText: string = 'openclaw';
  @State private agentAccountIndex: number = -1;
  @State private agentModelIndex: number = -1;
  @State private agentToken: string = '';
  @State private versionText: string = '';
  @State private webPortText: string = '';
  @State private appInstallIdText: string = '';
  @State private providerText: string = '';
  @State private apiKeyText: string = '';
  @State private baseURLText: string = '';
  @State private apiTypeText: string = '';
  @State private remarkText: string = '';
  @State private domainText: string = '';
  @State private allowedIpsText: string = '';
  @State private sslIdText: string = '';
  @State private websiteIdText: string = '';
  @State private logText: string = '';
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private tabs: string[] = ['aiTabModels', 'aiTabGpu', 'aiTabModelDownloader', 'aiTabDomain', 'aiTabAgents', 'aiTabMcp'];
  private agentTypes: string[] = ['openclaw', 'copaw', 'hermes-agent', 'deepseek-harness', 'octop'];

  aboutToAppear(): void {
    const requested = this.tabs.indexOf(this.routeArguments.get('tab') as string ?? '');
    if (requested >= 0) this.selectedTab = requested;
    if (this.initialRoute === '/ai/accounts') {
      this.selectedTab = 4;
      this.agentSection = 1;
    } else if (this.initialRoute === '/ai/agents/plugins') {
      this.selectedTab = 4;
      const id = Number(this.routeArguments.get('agentId'));
      if (Number.isInteger(id) && id > 0) {
        this.selectedAgent = computeArguments('id', id);
        this.openExtensions(true);
        return;
      }
      this.errorMessage = this.text('commonErrorBadRequest');
      return;
    } else if (this.initialRoute === '/ai/agents') {
      this.selectedTab = 4;
    } else if (this.initialRoute === '/ai/gpu-history') {
      this.selectedTab = 1;
      this.search();
    } else if (this.initialRoute === '/ai/mcp/detail') {
      this.selectedTab = 5;
      const args = new Map<string, Object | null>();
      args.set('id', this.routeArguments.get('serverId') as number);
      this.loadServerDetail(args);
    }
    this.load();
  }

  private text(key: string): string { return this.bridge.text(key); }
  private str(record: Map<string, Object | null>, key: string): string {
    const value = record.get(key);
    return value === undefined || value === null ? '' : `${value}`;
  }
  private args(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('page', 1); args.set('pageSize', 100);
    if (this.searchText.length > 0) args.set('name', this.searchText);
    return args;
  }
  private async load(): Promise<void> {
    this.loading = true; this.errorMessage = '';
    try {
      if (this.selectedTab === 0) {
        const args = new Map<string, Object | null>();
        args.set('info', this.searchText);
        this.ollama = await this.bridge.invoke<Map<string, Object | null>[]>('harmonyCompute/searchNativeOllamaModels', args);
      } else if (this.selectedTab === 1) {
        this.gpus = await this.bridge.invoke<Map<string, Object | null>[]>('getGpuLoad');
      } else if (this.selectedTab === 2) {
        const results = await Promise.all([
          this.bridge.invoke<Map<string, Object | null>>('getModelDownloaderFeatured', this.args()),
          this.bridge.invoke<Map<string, Object | null>>('getModelDownloaderTasks'),
          this.bridge.invoke<Map<string, Object | null>>('getModelDownloaderLocal'),
        ]);
        this.featured = this.items(results[0]);
        this.downloadTasks = this.items(results[1]);
        this.localModels = this.items(results[2]);
      } else if (this.selectedTab === 3) {
        const context = await this.bridge.invoke<Map<string, Object | null>>('getOllamaContext');
        if (context.get('found') === true && this.appInstallIdText.length === 0) {
          this.appInstallIdText = this.str(context, 'appInstallId');
        }
        if (this.appInstallIdText.length > 0) await this.loadDomain();
      } else if (this.selectedTab === 4 && this.agentSection === 0) {
        this.agents = this.items(await this.bridge.invoke<Map<string, Object | null>>('pageAgentsNative', this.args()));
      } else if (this.selectedTab === 4) {
        this.accounts = this.items(await this.bridge.invoke<Map<string, Object | null>>('getAgentAccounts', this.args()));
        this.providers = await this.bridge.invoke<Map<string, Object | null>[]>('getAgentProviders');
      } else {
        this.servers = this.items(await this.bridge.invoke<Map<string, Object | null>>('getMcpServers', this.args()));
      }
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private items(result: Map<string, Object | null>): Map<string, Object | null>[] {
    return (result.get('items') as Map<string, Object | null>[] | undefined) ?? [];
  }

  private async search(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      if (this.selectedTab === 0) {
        await this.load();
      } else if (this.selectedTab === 1) {
        const args = new Map<string, Object | null>(); args.set('startTime', new Date(Date.now() - 86400000).toISOString()); args.set('endTime', new Date().toISOString());
        this.detail = await this.bridge.invoke<Map<string, Object | null>>('searchGpuHistory', args);
        this.push('gpu-history');
      } else if (this.selectedTab === 2) {
        const args = new Map<string, Object | null>(); args.set('source', this.source); args.set('query', this.searchText); args.set('page', 1); args.set('pageSize', 50);
        args.set('sort', ['trending', 'downloads', 'likes', 'updated'][this.modelSort]);
        this.market = this.items(await this.bridge.invoke<Map<string, Object | null>>('getModelDownloaderSearch', args));
      } else if (this.selectedTab === 3) {
        this.bindDomain();
      } else if (this.selectedTab === 4) {
        const args = new Map<string, Object | null>(); args.set('page', 1); args.set('pageSize', 50); args.set('name', this.searchText);
        const result = this.agentSection === 0 ? await this.bridge.invoke<Map<string, Object | null>>('pageAgentsNative', args) : await this.bridge.invoke<Map<string, Object | null>>('getAgentAccounts', args);
        if (this.agentSection === 0) this.agents = result.get('items') as Map<string, Object | null>[];
        else this.accounts = result.get('items') as Map<string, Object | null>[];
      } else {
        const args = new Map<string, Object | null>(); args.set('page', 1); args.set('pageSize', 50); args.set('name', this.searchText);
        this.servers = (await this.bridge.invoke<Map<string, Object | null>>('getMcpServers', args)).get('items') as Map<string, Object | null>[];
      }
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private push(name: string): void { const path: NavPathInfo = { name: name }; this.paths.pushPath(path); }

  private async mutate(method: string, args: Map<string, Object | null>, refresh: boolean = true, successKey: string = 'commonOperationSuccess'): Promise<void> {
    this.loading = true; this.errorMessage = '';
    try {
      await computeWrite(method, args);
      if (successKey.length > 0) this.getUIContext().getPromptAction().showToast({ message: this.text(successKey) });
      if (refresh) await this.load();
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  @Builder
  private actionMenu(record: Map<string, Object | null>, actions: string[]) {
    Menu() {
      ForEach(actions, (action: string): void => {
        MenuItem({ content: this.text(action) }).onClick((): void => { this.openAction(record, action); });
      }, (action: string): string => action)
    }
  }

  private openAction(record: Map<string, Object | null>, action: string): void {
    this.selected = record;
    if (action === 'commonLoad' || action === 'commonClose') {
      const args = new Map<string, Object | null>(); args.set('name', this.str(record, 'name'));
      this.mutate(action === 'commonLoad' ? 'loadOllamaModelNative' : 'closeOllamaModelNative', args);
    } else if (action === 'aiModelRecreate') {
      this.confirm(action, this.str(record, 'name'));
    } else if (action === 'commonDelete') {
      this.confirm(action, this.str(record, 'name'));
    } else if (action === 'aiTabAgents') {
      this.selectAgent(record);
    } else if (action === 'aiMcpConfigPreviewTitle') {
      const args = new Map<string, Object | null>(); args.set('id', record.get('id') as number);
      this.loadServerDetail(args);
    } else if (action === 'commonEdit' && this.selectedTab === 4) {
      this.openAccountForm(record);
    } else if (action === 'commonEdit') {
      const args = new Map<string, Object | null>(); args.set('id', record.get('id') as number);
      this.loadServerDetail(args, true);
    } else if (['commonStart', 'commonStop', 'commonRestart'].includes(action)) {
      const args = new Map<string, Object | null>(); args.set('id', record.get('id') as number);
      args.set('operate', action === 'commonStart' ? 'start' : action === 'commonStop' ? 'stop' : 'restart');
      this.mutate('operateMcpServerNative', args);
    } else if (action === 'backupFormTestConnectionAction') {
      const args = new Map<string, Object | null>(); args.set('id', record.get('id') as number);
      this.mutate('testMcpConnection', args, false);
    } else if (action === 'aiAgentPluginsTitle') {
      this.selectedAgent = record; this.openExtensions(true);
    } else if (action === 'aiAgentsSubTabModel') {
      this.openAccountForm(record);
    } else if (action === 'modelDownloaderModelInfoTitle') {
      this.openModelInfo(record);
    } else if (action === 'modelDownloaderTaskCancelAction') {
      this.confirm(action, this.text('modelDownloaderTaskCancelConfirm').replace('{name}', this.str(record, 'repoID')));
    } else if (action === 'modelDownloaderTaskRetryAction') {
      this.confirm(action, this.text('modelDownloaderTaskRetryConfirm').replace('{name}', this.str(record, 'repoID')));
    } else if (action === 'modelDownloaderTaskRemoveAction' || action === 'modelDownloaderLocalDeleteAction') {
      this.modelRemoveFiles = action === 'modelDownloaderLocalDeleteAction';
      this.errorMessage = '';
      this.push(action);
    }
  }

  private confirm(action: string, label: string): void {
    this.getUIContext().showAlertDialog({ title: this.text(action), message: label,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.applyAction(action); } },
    });
  }

  private async applyAction(action: string): Promise<void> {
    const args = new Map<string, Object | null>();
    if (action === 'aiModelRecreate') { args.set('name', this.str(this.selected, 'name')); await this.mutate('recreateAIModel', args); }
    else if (this.selectedTab === 0) { args.set('id', this.selected.get('id') as number); await this.mutate('deleteAIModel', args); }
    else if (action === 'modelDownloaderTaskCancelAction' || action === 'modelDownloaderTaskRetryAction') {
      args.set('id', this.selected.get('id') as number);
      await this.mutate(action === 'modelDownloaderTaskCancelAction' ? 'cancelModelTask' : 'retryModelTask', args);
    }
    else if (this.selectedTab === 4 && this.agentSection === 0) { args.set('id', this.selected.get('id') as number); args.set('forceDelete', false); await this.mutate('deleteAgentNative', args); }
    else if (this.selectedTab === 4) { args.set('id', this.selected.get('id') as number); await this.mutate('deleteAgentAccountNative', args); }
    else { args.set('id', this.selected.get('id') as number); await this.mutate('deleteMcpServerNative', args); }
  }

  private async loadServerDetail(args: Map<string, Object | null>, editing: boolean = false): Promise<void> {
    try {
      this.detail = await this.bridge.invoke<Map<string, Object | null>>('getMcpServerDetail', args);
      if (editing) this.openMcpForm(this.detail);
      else this.push('mcp-detail');
    }
    catch (error) { this.errorMessage = (error as Error).message; }
  }

  private openMcpForm(record?: Map<string, Object | null>): void {
    this.formKind = record === undefined ? 'mcp' : 'mcp-edit';
    this.selected = record ?? new Map<string, Object | null>();
    this.nameText = record === undefined ? '' : this.str(record, 'name');
    this.typeText = record === undefined ? 'stdio' : this.str(record, 'type');
    this.commandText = record === undefined ? '' : this.str(record, 'command');
    this.urlText = record === undefined ? '' : this.str(record, 'baseUrl');
    this.containerText = record === undefined ? '' : this.str(record, 'containerName');
    this.portText = record === undefined ? '8080' : this.str(record, 'port');
    this.outputTransportText = record === undefined ? 'streamable-http' : this.str(record, 'outputTransport');
    this.ssePathText = record === undefined ? '' : this.str(record, 'ssePath');
    this.httpPathText = record === undefined ? '' : this.str(record, 'streamableHttpPath');
    this.push('ai-form');
  }

  private openAccountForm(record?: Map<string, Object | null>): void {
    this.formKind = record === undefined ? 'account' : 'account-edit';
    this.selected = record ?? new Map<string, Object | null>();
    this.nameText = record === undefined ? '' : this.str(record, 'name');
    this.providerText = record === undefined ? '' : this.str(record, 'provider');
    this.baseURLText = record === undefined ? '' : this.str(record, 'baseUrl');
    this.apiTypeText = record === undefined ? '' : this.str(record, 'apiType');
    this.remarkText = record === undefined ? '' : this.str(record, 'remark');
    this.apiKeyText = '';
    this.push('ai-form');
  }

  private async openAgentForm(): Promise<void> {
    this.errorMessage = '';
    try {
      this.accounts = this.items(await this.bridge.invoke<Map<string, Object | null>>('getAgentAccounts',
        new Map<string, Object | null>([['page', 1], ['pageSize', 100]])));
      this.formKind = 'agent';
      this.nameText = 'OpenClaw';
      this.versionText = 'latest';
      this.agentToken = '';
      this.selectAgentType(0);
      this.push('ai-form');
    } catch (error) { this.errorMessage = (error as Error).message; }
  }

  private selectAgentType(index: number): void {
    this.agentTypeText = this.agentTypes[index];
    this.webPortText = ['18789', '8088', '9119', '10443', '8088'][index];
    this.agentAccountIndex = -1;
    this.agentModelIndex = -1;
  }

  private usesAgentModel(): boolean {
    return this.agentTypeText === 'openclaw' || this.agentTypeText === 'hermes-agent';
  }

  private accountModels(): Map<string, Object | null>[] {
    if (this.agentAccountIndex < 0) return [];
    return this.accounts[this.agentAccountIndex].get('models') as Map<string, Object | null>[];
  }

  private agentFormError(): string {
    if (this.nameText.trim().length === 0) return this.text('aiAgentsNameRequired');
    if (this.versionText.trim().length === 0) return this.text('aiAgentsVersionRequired');
    const port = Number(this.webPortText);
    if (!Number.isInteger(port) || port < 1 || port > 65535) return this.text('aiAgentsPortRequired');
    if (this.usesAgentModel() && this.agentAccountIndex < 0) return this.text('aiAgentsAccountRequired');
    if (this.usesAgentModel() && this.agentModelIndex < 0) return this.text('aiAgentsModelRequired');
    return '';
  }

  private async saveForm(): Promise<void> {
    const args = new Map<string, Object | null>();
    if (this.formKind === 'mcp' || this.formKind === 'mcp-edit') {
      args.set('name', this.nameText); args.set('type', this.typeText); args.set('command', this.commandText);
      if (this.formKind === 'mcp-edit') args.set('id', this.selected.get('id') as number);
      args.set('baseUrl', this.urlText); args.set('containerName', this.containerText); args.set('port', Number(this.portText));
      args.set('outputTransport', this.outputTransportText); args.set('ssePath', this.ssePathText); args.set('streamableHttpPath', this.httpPathText);
      await this.mutate(this.formKind === 'mcp' ? 'createNativeMcpServer' : 'updateNativeMcpServer', args, false);
    } else if (this.formKind === 'account' || this.formKind === 'account-edit') {
      args.set('provider', this.providerText); args.set('name', this.nameText); args.set('apiKey', this.apiKeyText);
      args.set('baseURL', this.baseURLText); args.set('apiType', this.apiTypeText); args.set('remark', this.remarkText);
      if (this.formKind === 'account-edit') args.set('id', this.selected.get('id') as number);
      await this.mutate(this.formKind === 'account' ? 'createAgentAccountNative' : 'updateAgentAccountNative', args);
    } else if (this.formKind === 'agent') {
      this.errorMessage = this.agentFormError();
      if (this.errorMessage.length > 0) return;
      args.set('agentType', this.agentTypeText);
      args.set('name', this.nameText.trim());
      args.set('appVersion', this.versionText.trim());
      args.set('webUIPort', Number(this.webPortText));
      if (this.usesAgentModel()) {
        args.set('accountId', this.accounts[this.agentAccountIndex].get('id') as number);
        args.set('model', this.str(this.accountModels()[this.agentModelIndex], 'id'));
      }
      if (this.agentTypeText === 'openclaw' && this.agentToken.trim().length > 0) args.set('token', this.agentToken.trim());
      await this.mutate('createAgentNative', args, false);
    } else if (this.formKind === 'domain') {
      args.set('appInstallID', Number(this.appInstallIdText));
      args.set('domain', this.domainText);
      if (this.allowedIpsText.trim().length > 0) args.set('ipList', this.allowedIpsText.trim());
      if (this.sslIdText.trim().length > 0) args.set('sslID', Number(this.sslIdText));
      if (this.websiteIdText.trim().length > 0) args.set('websiteID', Number(this.websiteIdText));
      await this.mutate('harmonyCompute/saveNativeOllamaBinding', args, false);
    } else if (this.formKind === 'ollama') {
      await this.mutate('createAIModel', this.nameArguments(), false);
    }
    await this.closeSavedForm();
  }

  private async closeSavedForm(): Promise<void> {
    if (this.errorMessage.length > 0) return;
    this.paths.pop();
    await this.load();
  }

  private bindDomain(): void {
    this.domainText = this.str(this.binding, 'domain');
    this.allowedIpsText = ((this.binding.get('allowIPs') as string[] | undefined) ?? []).join('\n');
    this.sslIdText = this.str(this.binding, 'sslID');
    this.websiteIdText = this.str(this.binding, 'websiteID');
    this.formKind = 'domain'; this.push('ai-form');
  }

  private async loadDomain(): Promise<void> {
    const args = computeArguments('appInstallID', Number(this.appInstallIdText));
    this.binding = await this.bridge.invoke<Map<string, Object | null>>('harmonyCompute/getNativeOllamaBinding', args);
  }

  private async refreshDomainForm(): Promise<void> {
    this.errorMessage = '';
    try {
      await this.loadDomain();
      this.domainText = this.str(this.binding, 'domain');
      this.allowedIpsText = ((this.binding.get('allowIPs') as string[] | undefined) ?? []).join('\n');
      this.sslIdText = this.str(this.binding, 'sslID');
      this.websiteIdText = this.str(this.binding, 'websiteID');
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private rootMenus(): NavigationMenuItem[] {
    const actions: NavigationMenuItem[] = [
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')), action: (): void => { this.load(); } },
    ];
    if (this.selectedTab === 0) {
      actions.push({ value: this.text('aiModelCreate'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')), action: (): void => { this.formKind = 'ollama'; this.nameText = ''; this.push('ai-form'); } });
    } else if (this.selectedTab === 2) {
      actions.push({ value: this.text('modelDownloaderSettingsAction'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.gearshape')), action: (): void => { this.openModelSettings(); } });
    }
    return actions;
  }

  /** 侧栏栏宽有限，标题栏只放图标动作，同级文字动作经列表侧「更多」进入。 */
  private secondaryActions(): MenuElement[] {
    const actions: MenuElement[] = [];
    if (this.selectedTab === 0) {
      actions.push({ value: this.text('aiModelSync'), action: (): void => { this.mutate('syncOllamaModelsNative', new Map<string, Object | null>()); } });
    } else if (this.selectedTab === 2) {
      actions.push({ value: this.text('modelDownloaderFeaturedSyncAction'), action: (): void => { this.mutate('syncModelDownloaderFeatured', new Map<string, Object | null>()); } });
    } else if (this.selectedTab === 3) {
      actions.push({ value: this.text('aiMcpBindDomain'), action: (): void => { this.bindDomain(); } });
    } else if (this.selectedTab === 4) {
      actions.push({ value: this.text(this.agentSection === 0 ? 'aiAgentsCreate' : 'commonAdd'), action: (): void => { if (this.agentSection === 0) this.openAgentForm(); else this.openAccountForm(); } });
    } else if (this.selectedTab === 5) {
      actions.push({ value: this.text('aiMcpCreate'), action: (): void => { this.openMcpForm(); } });
    }
    return actions;
  }

  private activateRow(record: Map<string, Object | null>): void {
    this.selected = record;
    if (this.selectedTab === 4 && this.agentSection === 0) this.selectAgent(record);
    else if (this.selectedTab === 5) this.openAction(record, 'aiMcpConfigPreviewTitle');
  }

  @Builder
  private row(title: string, subtitle: string, actions: string[], record: Map<string, Object | null>) {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
        if (subtitle.length > 0) Text(subtitle).fontSize(14).fontColor($r('sys.color.font_secondary')).maxLines(3)
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      if (actions.length > 0) Button() { SymbolGlyph($r('sys.symbol.more')).fontSize(22) }
        .height(48).width(48).buttonStyle(ButtonStyleMode.TEXTUAL).accessibilityText(this.text('commonMore'))
        .bindMenu(this.actionMenu(record, actions), { systemMaterial: menuMaterial })
    }.padding({ left: 16, right: 8, top: 8, bottom: 8 }).constraintSize({ minHeight: 68 }).width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
      .onClick((): void => { this.activateRow(record); })
      .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
        event,
        (): void => { this.activateRow(record); },
      ))
      .focusable(true)
      .focusOnTouch(true)
      .focusBox({ margin: LengthMetrics.vp(2) })
      .hoverEffect(HoverEffect.Highlight)
  }

  @Builder
  private body() {
    Column({ space: 12 }) {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.tabs, (tab: string, index: number): void => {
            Button(this.text(tab), { buttonStyle: this.selectedTab === index ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL })
              .height(48).onClick((): void => { this.selectedTab = index; this.searchText = ''; this.load(); })
          }, (tab: string): string => tab)
        }
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      if (this.selectedTab !== 1 && this.selectedTab !== 3) {
        Row({ space: 8 }) {
          TextInput({ text: this.searchText, placeholder: this.text('commonSearch') })
            .layoutWeight(1).height(48).onChange((content: string): void => { this.searchText = content; })
          Button() { SymbolGlyph($r('sys.symbol.magnifyingglass')).fontSize(20) }.width(48).height(48)
            .accessibilityText(this.text('commonSearch')).onClick((): void => { this.search(); })
          if (this.splitLayout && this.secondaryActions().length > 0) {
            Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.TEXTUAL }) {
              SymbolGlyph($r('sys.symbol.more')).fontSize(22)
                .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            }
            .width(48).height(48)
            .accessibilityText(this.text('commonMore'))
            .bindMenu(this.secondaryActions(), { systemMaterial: menuMaterial })
          }
        }
      }
      if (this.selectedTab === 2) {
        Row({ space: 8 }) {
          Select([{ value: 'Hugging Face' }, { value: 'ModelScope' }]).selected(this.source === 'hf' ? 0 : 1)
            .height(48).layoutWeight(1).enabled(!this.loading)
            .accessibilityText(this.text('modelDownloaderSearchSourceLabel'))
            .onSelect((index: number): void => { this.source = index === 0 ? 'hf' : 'modelScope'; this.search(); })
          Select([{ value: this.text('modelDownloaderSortTrending') }, { value: this.text('modelDownloaderSortDownloads') },
            { value: this.text('modelDownloaderSortLikes') }, { value: this.text('modelDownloaderSortUpdated') }])
            .selected(this.modelSort).height(48).layoutWeight(1).enabled(!this.loading)
            .accessibilityText(this.text('modelDownloaderSearchSortLabel'))
            .onSelect((index: number): void => { this.modelSort = index; this.search(); })
        }.width('100%')
      }
      if (this.selectedTab === 4) {
        Row({ space: 8 }) {
          Button(this.text('aiAgentsSubTabAgent'), { buttonStyle: this.agentSection === 0 ? ButtonStyleMode.EMPHASIZED : ButtonStyleMode.TEXTUAL })
            .height(48).layoutWeight(1).onClick((): void => { this.agentSection = 0; this.load(); })
          Button(this.text('aiAgentsSubTabModel'), { buttonStyle: this.agentSection === 1 ? ButtonStyleMode.EMPHASIZED : ButtonStyleMode.TEXTUAL })
            .height(48).layoutWeight(1).onClick((): void => { this.agentSection = 1; this.load(); })
        }
      }
      if (this.loading) LoadingProgress().width(40).height(40)
      if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary'))
      if (this.selectedTab === 3) {
        Column({ space: 8 }) {
          Text(this.text('aiMcpBindingTitle')).fontSize(18).fontWeight(FontWeight.Medium)
          Text(this.str(this.binding, 'domain')).fontSize(16)
          Text(this.str(this.binding, 'connUrl')).fontSize(14).fontColor($r('sys.color.font_secondary')).copyOption(CopyOptions.InApp)
          Button(this.text('aiMcpBindDomain')).height(48).onClick((): void => { this.bindDomain(); })
        }.width('100%').alignItems(HorizontalAlign.Start)
      } else {
        List({ space: 10 }) {
          if (this.selectedTab === 0) ForEach(this.ollama, (item: Map<string, Object | null>): void => {
            ListItem() { this.row(this.str(item, 'name'), `${this.str(item, 'size')} · ${this.str(item, 'modified')}`, ['commonLoad', 'commonClose', 'aiModelRecreate', 'commonDelete'], item) }
          }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
          else if (this.selectedTab === 1) ForEach(this.gpus, (item: Map<string, Object | null>): void => {
            ListItem() { this.row(this.str(item, 'productName'), `${this.str(item, 'name')} · ${this.str(item, 'deviceID')}`, [], item) }
          }, (item: Map<string, Object | null>): string => this.str(item, 'deviceID'))
          else if (this.selectedTab === 2) {
            ListItem() { this.sectionTitle('modelDownloaderFeaturedSectionTitle') }
            ForEach(this.featured, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.str(item, 'repoID'), `${this.str(item, 'family')} · ${this.str(item, 'weightGB')} GB`, ['modelDownloaderModelInfoTitle'], item) }
            }, (item: Map<string, Object | null>): string => this.str(item, 'key'))
            ListItem() { this.sectionTitle('modelDownloaderSearchSectionTitle') }
            ForEach(this.market, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.str(item, 'repoID'), this.str(item, 'sizeFormatted'), ['modelDownloaderModelInfoTitle'], item) }
            }, (item: Map<string, Object | null>): string => this.str(item, 'repoID'))
            ListItem() { this.sectionTitle('modelDownloaderTasksSectionTitle') }
            ForEach(this.downloadTasks, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.str(item, 'repoID'), this.modelTaskSubtitle(item), this.downloadTaskActions(item), item) }
            }, (item: Map<string, Object | null>): string => this.str(item, 'id'))
            ListItem() { this.sectionTitle('modelDownloaderLocalSectionTitle') }
            ForEach(this.localModels, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.str(item, 'repoID'), `${this.str(item, 'source')} · ${this.str(item, 'sizeFormatted')}`, ['modelDownloaderLocalDeleteAction'], item) }
            }, (item: Map<string, Object | null>): string => `${this.str(item, 'path')}:${this.str(item, 'downloadType')}`)
          } else if (this.selectedTab === 4 && this.agentSection === 0) ForEach(this.agents, (item: Map<string, Object | null>): void => {
            ListItem() { this.row(this.str(item, 'name'), `${this.str(item, 'agentType')} · ${this.str(item, 'status')}`,
              item.get('agentType') === 'openclaw' ? ['aiTabAgents', 'aiAgentPluginsTitle', 'commonDelete'] : ['aiTabAgents', 'commonDelete'], item) }
          }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
          else if (this.selectedTab === 4) ForEach(this.accounts, (item: Map<string, Object | null>): void => {
            ListItem() { this.row(this.str(item, 'name'), `${this.str(item, 'providerName')} · ${this.str(item, 'apiType')} · ${this.str(item, 'verified')}`, ['commonEdit', 'commonDelete'], item) }
          }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
          else if (this.selectedTab === 5) ForEach(this.servers, (item: Map<string, Object | null>): void => {
            ListItem() { this.row(this.str(item, 'name'), `${this.str(item, 'status')} · ${this.str(item, 'port')} · ${this.str(item, 'outputTransport')}`, ['aiMcpConfigPreviewTitle', 'commonEdit', 'commonStart', 'commonStop', 'commonRestart', 'backupFormTestConnectionAction', 'commonDelete'], item) }
          }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
        }.layoutWeight(1).width('100%')
      }
    }.padding(16).width('100%').height('100%')
  }

  private async selectAgent(agent: Map<string, Object | null>): Promise<void> {
    this.selectedAgent = agent;
    const args = new Map<string, Object | null>(); args.set('agentId', agent.get('id') as number);
    try { this.detail = await this.bridge.invoke<Map<string, Object | null>>('getAgentOverviewNative', args); this.push('agent-detail'); }
    catch (error) { this.errorMessage = (error as Error).message; }
  }

  private async openAgentSettings(): Promise<void> {
    const args = new Map<string, Object | null>(); args.set('agentId', this.selectedAgent.get('id') as number);
    try {
      this.detail = await this.bridge.invoke<Map<string, Object | null>>('getNativeAgentSettings', args);
      const security = this.detail.get('security') as Map<string, Object | null>;
      const config = this.detail.get('configFile') as Map<string, Object | null>;
      this.logText = ((security.get('allowedOrigins') as string[] | undefined) ?? []).join('\n');
      this.repoText = this.str(config, 'content');
      this.push('agent-settings');
    }
    catch (error) { this.errorMessage = (error as Error).message; }
  }

  private async saveAgentSetting(section: string, content: string): Promise<void> {
    const args = new Map<string, Object | null>(); args.set('agentId', this.selectedAgent.get('id') as number);
    if (section === 'security') { args.set('allowedOrigins', content.split('\n').map((value: string): string => value.trim()).filter((value: string): boolean => value.length > 0)); await this.mutate('saveNativeAgentSecurity', args, false); }
    else if (section === 'configFile') { args.set('content', content); await this.mutate('saveNativeAgentConfigFile', args, false); }
  }

  private openExtensions(plugins: boolean): void {
    this.agentDetails = [];
    this.foundExtensions = [];
    this.extensionQuery = '';
    this.skillSourceIndex = 0;
    this.push(plugins ? 'agent-plugins' : 'agent-skills');
  }

  private skillSources(): string[] {
    return this.selectedAgent.get('agentType') === 'hermes-agent'
      ? ['official', 'skills-sh', 'local-hub'] : ['clawhub-global', 'clawhub-cn', 'skillhub', 'local-hub'];
  }

  private async loadExtensions(plugins: boolean, search: boolean = false): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    const args = new Map<string, Object | null>([['agentId', this.selectedAgent.get('id') as number]]);
    try {
      if (search) {
        args.set('keyword', this.extensionQuery.trim());
        if (plugins) args.set('limit', 20);
        else args.set('source', this.skillSources()[this.skillSourceIndex]);
        this.foundExtensions = await this.bridge.invoke<Map<string, Object | null>[]>(
          plugins ? 'searchNativeAgentPlugins' : 'searchNativeAgentSkills', args);
      } else {
        this.agentDetails = await this.bridge.invoke<Map<string, Object | null>[]>(
          plugins ? 'getNativeAgentPlugins' : 'getNativeAgentSkills', args);
      }
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private async changeExtension(plugins: boolean, item: Map<string, Object | null>, action: string): Promise<void> {
    const args = new Map<string, Object | null>([['agentId', this.selectedAgent.get('id') as number]]);
    const taskId = util.generateRandomUUID();
    let method: string;
    if (action === 'install') {
      args.set('taskID', taskId);
      if (plugins) {
        method = 'installNativeAgentPlugin';
        args.set('package', this.str(item, 'package'));
        args.set('version', this.str(item, 'version'));
      } else {
        method = 'installNativeAgentSkill';
        args.set('source', this.str(item, 'source'));
        args.set('slug', this.str(item, 'slug'));
      }
    } else if (plugins) {
      method = 'operateNativeAgentPlugin';
      args.set('taskID', taskId);
      args.set('pluginId', this.str(item, 'id'));
      args.set('operate', action);
    } else {
      method = 'toggleNativeAgentSkill';
      args.set('name', this.str(item, 'name'));
      args.set('enabled', action === 'enable');
    }
    await this.mutate(method, args, false, args.has('taskID') ? '' : 'commonOperationSuccess');
    if (this.errorMessage.length > 0) return;
    if (args.has('taskID')) {
      try {
        await this.bridge.openNativePage('/logs/task/detail', new Map<string, Object | null>([['taskId', taskId]]));
      } catch (error) { this.errorMessage = (error as Error).message; }
    } else {
      await this.loadExtensions(plugins);
    }
  }

  private confirmExtension(plugins: boolean, item: Map<string, Object | null>, action: string, label: string): void {
    this.getUIContext().showAlertDialog({ title: this.text(label), message: this.str(item, 'name'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.changeExtension(plugins, item, action); } },
    });
  }

  @Builder
  private extensionMenu(plugins: boolean, item: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: this.text(plugins ? item.get('enabled') === true ? 'cronjobsDisableAction' : 'commonEnable'
        : item.get('disabled') === true ? 'commonEnable' : 'cronjobsDisableAction') })
        .onClick((): void => {
          const isEnabled = plugins ? item.get('enabled') === true : item.get('disabled') !== true;
          this.confirmExtension(plugins, item, isEnabled ? 'disable' : 'enable', isEnabled ? 'cronjobsDisableAction' : 'commonEnable');
        })
      if (plugins && item.get('origin') !== 'bundled') {
        MenuItem({ content: this.text('aiAgentPluginUpgrade') })
          .onClick((): void => { this.confirmExtension(true, item, 'update', 'aiAgentPluginUpgrade'); })
        MenuItem({ content: this.text('aiAgentPluginUninstall') })
          .onClick((): void => { this.confirmExtension(true, item, 'uninstall', 'aiAgentPluginUninstall'); })
      }
    }
  }

  @Builder
  private extensionRow(plugins: boolean, item: Map<string, Object | null>, market: boolean) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(this.str(item, 'name')).fontSize(16).width('100%')
        Text(plugins && !market ? `${this.str(item, 'version')} · ${this.str(item, 'origin')}` : this.str(item, 'description'))
          .fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      }.layoutWeight(1)
      if (market) {
        Button(this.text('aiAgentsInstall'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).enabled(!this.loading)
          .onClick((): void => { this.confirmExtension(plugins, item, 'install', 'aiAgentsInstall'); })
      } else {
        Button() { SymbolGlyph($r('sys.symbol.more')).fontSize(22) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.loading)
          .accessibilityText(this.text('commonMore'))
          .bindMenu(this.extensionMenu(plugins, item), { systemMaterial: menuMaterial })
      }
    }.padding({ left: 16, right: 8, top: 8, bottom: 8 }).width('100%').constraintSize({ minHeight: 60 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
  }

  @Builder
  private sectionTitle(label: string) {
    Text(this.text(label)).fontSize(16).fontWeight(FontWeight.Medium).width('100%').padding({ top: 8, left: 4 })
  }

  private async openModelSettings(): Promise<void> {
    this.errorMessage = '';
    try {
      const settings = await this.bridge.invoke<Map<string, Object | null>>('getModelDownloaderSettings');
      this.modelDir = this.str(settings, 'modelDir');
      this.hfEndpoint = this.str(settings, 'hfEndpoint');
      this.hfToken = this.str(settings, 'hfToken');
      this.modelScopeEndpoint = this.str(settings, 'modelScopeEndpoint');
      this.modelScopeToken = this.str(settings, 'modelScopeToken');
      this.modelAutoSync = settings.get('featuredModelsSync') !== 'Disable';
      this.push('model-settings');
    } catch (error) { this.errorMessage = (error as Error).message; }
  }

  private async saveModelSettings(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('modelDir', this.modelDir.trim());
    args.set('hfEndpoint', this.hfEndpoint.trim());
    args.set('hfToken', this.hfToken.trim());
    args.set('modelScopeEndpoint', this.modelScopeEndpoint.trim());
    args.set('modelScopeToken', this.modelScopeToken.trim());
    args.set('featuredSync', this.modelAutoSync);
    await this.mutate('updateModelDownloaderSettings', args, false, 'modelDownloaderSettingsSaveSuccess');
    await this.closeSavedForm();
  }

  private openModelInfo(item: Map<string, Object | null>): void {
    this.modelSource = item.has('preferredSource') ? this.str(item, 'preferredSource') : this.source;
    this.modelRepo = item.has('preferredRepoID') ? this.str(item, 'preferredRepoID') : this.str(item, 'repoID');
    this.modelInfo = new Map<string, Object | null>();
    this.modelRevision = '';
    this.modelDownloadType = 'all';
    this.push('model-info');
    this.loadModelInfo();
  }

  private modelArguments(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('source', this.modelSource.toLowerCase() === 'hf' ? 'hf' : 'modelScope');
    args.set('repoID', this.modelRepo);
    if (this.modelRevision.trim().length > 0) args.set('revision', this.modelRevision.trim());
    return args;
  }

  private async loadModelInfo(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      this.modelInfo = await this.bridge.invoke<Map<string, Object | null>>('harmonyCompute/getNativeModelDownloadInfo', this.modelArguments());
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private async download(): Promise<void> {
    const args = this.modelArguments();
    args.set('downloadType', this.modelDownloadType);
    await this.mutate('downloadModel', args, false, 'modelDownloaderDownloadStarted');
    await this.closeSavedForm();
  }

  private modelTaskSubtitle(item: Map<string, Object | null>): string {
    const progress = Math.round((item.get('progressRatio') as number) * 100);
    const error = this.str(item, 'errorMessage');
    const status = this.str(item, 'status');
    const state = status.length === 0 ? '' : `modelDownloaderTaskStatus${status[0].toUpperCase()}${status.substring(1)}`;
    const label = this.text(state);
    return `${label === state ? status : label} · ${progress}%${error.length > 0 ? ` · ${error}` : ''}`;
  }

  private downloadTaskActions(item: Map<string, Object | null>): string[] {
    const actions: string[] = [];
    if (item.get('canCancel') === true) actions.push('modelDownloaderTaskCancelAction');
    if (item.get('canRetry') === true) actions.push('modelDownloaderTaskRetryAction');
    if (item.get('canRemoveRecord') === true) actions.push('modelDownloaderTaskRemoveAction');
    return actions;
  }

  private async removeModel(local: boolean): Promise<void> {
    const args = new Map<string, Object | null>([['withFile', this.modelRemoveFiles]]);
    if (local) {
      const name = this.str(this.selected, 'name');
      args.set('name', name.length > 0 ? name : this.str(this.selected, 'repoID'));
      args.set('downloadType', this.str(this.selected, 'downloadType'));
    } else {
      args.set('id', this.selected.get('id') as number);
    }
    await this.mutate(local ? 'deleteLocalModel' : 'removeModelTask', args, false);
    await this.closeSavedForm();
  }

  private async serverAction(item: Map<string, Object | null>, action: string): Promise<void> {
    const args = new Map<string, Object | null>(); args.set('id', item.get('id') as number);
    if (action === 'commonStart' || action === 'commonStop' || action === 'commonRestart') {
      args.set('operate', action === 'commonStart' ? 'start' : action === 'commonStop' ? 'stop' : 'restart');
      await this.mutate('operateMcpServerNative', args);
    } else if (action === 'aiMcpTestConnection') await this.mutate('testMcpConnection', args, false);
    else if (action === 'commonDelete') await this.mutate('deleteMcpServerNative', args);
    else await this.loadServerDetail(args);
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'ai-form') {
      NavDestination() {
        Scroll() {
          Column({ space: 14 }) {
            if (this.formKind === 'ollama') {
              HarmonyComputeField({ labelKey: 'commonName', fieldText: this.nameText })
            } else if (this.formKind === 'mcp' || this.formKind === 'mcp-edit') {
              HarmonyComputeField({ labelKey: 'commonName', fieldText: this.nameText })
              Select([{ value: 'stdio' }, { value: 'http' }, { value: 'sse' }]).value(this.typeText).height(48)
                .onSelect((index: number): void => { this.typeText = ['stdio', 'http', 'sse'][index]; })
              HarmonyComputeField({ labelKey: 'aiMcpCommandLabel', fieldText: this.commandText })
              HarmonyComputeField({ labelKey: 'aiMcpBaseUrlLabel', fieldText: this.urlText })
              HarmonyComputeField({ labelKey: 'aiMcpContainerLabel', fieldText: this.containerText })
              HarmonyComputeField({ labelKey: 'aiMcpPortLabel', fieldText: this.portText, inputType: InputType.Number })
              HarmonyComputeField({ labelKey: 'aiMcpTransportLabel', fieldText: this.outputTransportText })
              HarmonyComputeField({ labelKey: 'aiMcpSsePathLabel', fieldText: this.ssePathText })
              HarmonyComputeField({ labelKey: 'aiMcpStreamablePathLabel', fieldText: this.httpPathText })
            } else if (this.formKind === 'account' || this.formKind === 'account-edit') {
              if (this.formKind === 'account') {
                Select(this.providers.map((item: Map<string, Object | null>): SelectOption => ({ value: this.str(item, 'displayName') })) )
                  .value(this.providerText).height(48).onSelect((index: number): void => {
                    const item = this.providers[index]; this.providerText = this.str(item, 'provider'); this.baseURLText = this.str(item, 'baseUrl');
                    this.apiTypeText = this.str(item, 'defaultApiType');
                  })
              }
              HarmonyComputeField({ labelKey: 'commonName', fieldText: this.nameText })
              HarmonyComputeField({ labelKey: 'aiAgentsBaseUrl', fieldText: this.baseURLText })
              HarmonyComputeField({ labelKey: 'aiAgentsApiType', fieldText: this.apiTypeText })
              HarmonyComputeField({ labelKey: 'aiAgentsApiKey', fieldText: this.apiKeyText, inputType: InputType.Password })
              HarmonyComputeField({ labelKey: 'commonDescription', fieldText: this.remarkText })
              if (this.formKind === 'account') Button(this.text('modelDownloaderSearchAction')).height(48).onClick((): void => { this.discoverModels(); })
            } else if (this.formKind === 'agent') {
              Select([{ value: 'OpenClaw' }, { value: 'CoPaw' }, { value: 'Hermes Agent' }, { value: 'DeepSeek Harness' }, { value: 'Octop' }])
                .selected(this.agentTypes.indexOf(this.agentTypeText)).height(48).width('100%')
                .accessibilityText(this.text('aiAgentsAgentType')).onSelect((index: number): void => { this.selectAgentType(index); })
              HarmonyComputeField({ labelKey: 'commonName', fieldText: this.nameText })
              HarmonyComputeField({ labelKey: 'aiAgentsAppVersion', fieldText: this.versionText })
              HarmonyComputeField({ labelKey: 'aiAgentsWebUiPort', fieldText: this.webPortText, inputType: InputType.Number })
              if (this.usesAgentModel()) {
                Text(this.text('aiAgentsAccount')).fontSize(14).fontColor($r('sys.color.font_secondary'))
                if (this.accounts.length > 0) {
                  Select(this.accounts.map((item: Map<string, Object | null>): SelectOption => ({ value: this.str(item, 'name') })))
                    .selected(this.agentAccountIndex).height(48).width('100%')
                    .accessibilityText(this.text('aiAgentsAccount')).onSelect((index: number): void => {
                      this.agentAccountIndex = index;
                      this.agentModelIndex = this.accountModels().length > 0 ? 0 : -1;
                    })
                } else {
                  Text(this.text('commonEmpty')).fontSize(14)
                }
                if (this.agentAccountIndex >= 0) {
                  Text(this.text('aiAgentsModel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
                  if (this.accountModels().length > 0) {
                    Select(this.accountModels().map((item: Map<string, Object | null>): SelectOption => ({ value: this.str(item, 'name') })))
                      .selected(this.agentModelIndex).height(48).width('100%')
                      .accessibilityText(this.text('aiAgentsModel')).onSelect((index: number): void => { this.agentModelIndex = index; })
                  } else {
                    Text(this.text('commonEmpty')).fontSize(14)
                  }
                }
              }
              if (this.agentTypeText === 'openclaw') {
                HarmonyComputeField({ labelKey: 'aiAgentsTokenOptional', fieldText: this.agentToken, inputType: InputType.Password })
              }
            } else {
              HarmonyComputeField({ labelKey: 'aiAppInstallIdLabel', fieldText: this.appInstallIdText, inputType: InputType.Number })
              HarmonyComputeField({ labelKey: 'websitesDomainLabel', fieldText: this.domainText })
              TextArea({ text: this.allowedIpsText, placeholder: this.text('aiIpAllowListLabel') }).height(96)
                .onChange((content: string): void => { this.allowedIpsText = content; })
              HarmonyComputeField({ labelKey: 'aiSslIdOptionalLabel', fieldText: this.sslIdText, inputType: InputType.Number })
              HarmonyComputeField({ labelKey: 'aiWebsiteIdOptionalLabel', fieldText: this.websiteIdText, inputType: InputType.Number })
              Button(this.text('commonLoad'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48)
                .enabled(this.appInstallIdText.length > 0).onClick((): void => { this.refreshDomainForm(); })
            }
            if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
            Button(this.text('commonSave')).width('100%').height(48).enabled(!this.loading)
              .onClick((): void => { this.saveForm(); })
          }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
        }.width('100%').height('100%')
      }.title(this.text(this.formKind === 'ollama' ? 'aiModelCreate' : this.formKind === 'domain' ? 'aiMcpBindDomain' : this.formKind.startsWith('mcp') ? 'aiMcpDialogCreateTitle' : this.formKind === 'agent' ? 'aiAgentsCreate' : 'aiAgentsSubTabModel'))
    } else if (name === 'modelDownloaderTaskRemoveAction' || name === 'modelDownloaderLocalDeleteAction') {
      NavDestination() {
        Column({ space: 12 }) {
          Text(this.str(this.selected, 'repoID')).fontSize(16).width('100%')
          HarmonyComputeToggle({
            labelKey: name === 'modelDownloaderLocalDeleteAction' ? 'modelDownloaderLocalDeleteFileLabel' : 'modelDownloaderTaskRemoveWithFileLabel',
            selected: this.modelRemoveFiles,
          })
          if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
          Button(this.text(name)).height(48).width('100%').enabled(!this.loading)
            .onClick((): void => { this.removeModel(name === 'modelDownloaderLocalDeleteAction'); })
        }.padding(16).width('100%')
      }.title(this.text(name))
    } else if (name === 'model-settings') {
      NavDestination() {
        Scroll() {
          Column({ space: 14 }) {
            HarmonyComputeField({ labelKey: 'modelDownloaderSettingsModelDirLabel', fieldText: this.modelDir })
            HarmonyComputeField({ labelKey: 'modelDownloaderSettingsHfEndpointLabel', fieldText: this.hfEndpoint })
            HarmonyComputeField({ labelKey: 'modelDownloaderSettingsHfTokenLabel', fieldText: this.hfToken, inputType: InputType.Password })
            HarmonyComputeField({ labelKey: 'modelDownloaderSettingsModelScopeEndpointLabel', fieldText: this.modelScopeEndpoint })
            HarmonyComputeField({ labelKey: 'modelDownloaderSettingsModelScopeTokenLabel', fieldText: this.modelScopeToken, inputType: InputType.Password })
            HarmonyComputeToggle({ labelKey: 'modelDownloaderSettingsFeaturedSyncLabel', selected: this.modelAutoSync })
            if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
            Button(this.text('commonSave')).height(48).width('100%').enabled(!this.loading && this.modelDir.trim().length > 0)
              .onClick((): void => { this.saveModelSettings(); })
          }.padding(16).width('100%')
        }.width('100%').height('100%')
      }.title(this.text('modelDownloaderSettingsTitle'))
    } else if (name === 'model-info') {
      NavDestination() {
        Scroll() {
          Column({ space: 12 }) {
            HarmonyComputeInfo({ labelKey: 'commonName', content: this.modelRepo })
            HarmonyComputeInfo({ labelKey: 'modelDownloaderSearchSourceLabel', content: this.modelSource.toLowerCase() === 'hf' ? 'Hugging Face' : 'ModelScope' })
            HarmonyComputeField({ labelKey: 'modelDownloaderRevisionLabel', fieldText: this.modelRevision })
            Button(this.text('commonRefresh'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).enabled(!this.loading)
              .onClick((): void => { this.loadModelInfo(); })
            if (this.loading) LoadingProgress().width(40).height(40)
            if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
            if (this.modelInfo.has('repoID')) {
              HarmonyComputeInfo({ labelKey: 'modelDownloaderLocalSizeLabel', content: this.str(this.modelInfo, 'sizeFormatted') })
              HarmonyComputeInfo({ labelKey: 'modelDownloaderDownloadCountLabel', content: this.str(this.modelInfo, 'downloads') })
              HarmonyComputeInfo({ labelKey: 'modelDownloaderLikeCountLabel', content: this.str(this.modelInfo, 'likes') })
              if (this.str(this.modelInfo, 'modelCard').length > 0) {
                this.sectionTitle('modelDownloaderModelCardLabel')
                Text(this.str(this.modelInfo, 'modelCard')).fontSize(14).copyOption(CopyOptions.InApp).width('100%')
              }
              this.sectionTitle('modelDownloaderModelFilesLabel')
              ForEach(this.modelInfo.get('files') as Map<string, Object | null>[], (item: Map<string, Object | null>): void => {
                Row({ space: 12 }) {
                  Text(this.str(item, 'name')).fontSize(14).layoutWeight(1)
                  Text(this.str(item, 'sizeFormatted')).fontSize(14)
                }.constraintSize({ minHeight: 48 }).width('100%')
              }, (item: Map<string, Object | null>): string => this.str(item, 'name'))
            }
            Text(this.text('modelDownloaderDownloadTypeLabel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
            Select([{ value: this.text('modelDownloaderDownloadTypeAll') }, { value: this.text('modelDownloaderDownloadTypeTokenizer') }])
              .selected(this.modelDownloadType === 'all' ? 0 : 1).height(48).width('100%')
              .onSelect((index: number): void => { this.modelDownloadType = index === 0 ? 'all' : 'tokenizer'; })
            Button(this.text('modelDownloaderDownloadAction')).height(48).width('100%').enabled(!this.loading)
              .onClick((): void => { this.download(); })
          }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
        }.width('100%').height('100%')
      }.title(this.text('modelDownloaderModelInfoTitle'))
    } else if (name === 'agent-detail') {
      NavDestination() {
        Column({ space: 12 }) {
          HarmonyComputeInfo({ labelKey: 'commonName', content: this.str(this.selectedAgent, 'name') })
          HarmonyComputeInfo({ labelKey: 'aiAgentsAgentType', content: this.str(this.selectedAgent, 'agentType') })
          HarmonyComputeInfo({ labelKey: 'commonStatus', content: this.str(this.selectedAgent, 'status') })
          HarmonyComputeInfo({ labelKey: 'aiAgentsModel', content: this.str(this.selectedAgent, 'model') })
          Button(this.text('aiAgentsSettings')).width('100%').height(48).onClick((): void => { this.openAgentSettings(); })
          if (this.selectedAgent.get('agentType') === 'openclaw' || this.selectedAgent.get('agentType') === 'hermes-agent') {
            Button(this.text('aiAgentsSkills')).width('100%').height(48).onClick((): void => { this.openExtensions(false); })
          }
          if (this.selectedAgent.get('agentType') === 'openclaw') {
            Button(this.text('aiAgentPluginsTitle')).width('100%').height(48).onClick((): void => { this.openExtensions(true); })
          }
          Button(this.text('commonRefresh')).width('100%').height(48).onClick((): void => { this.loadAgentOverview(); })
        }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
      }.title(this.str(this.selectedAgent, 'name'))
    } else if (name === 'agent-settings') {
      NavDestination() {
        Scroll() {
          Column({ space: 12 }) {
            TextArea({ text: this.logText, placeholder: this.text('aiAgentsAllowedOrigins') })
              .height(120).onChange((content: string): void => { this.logText = content; })
            Button(this.text('commonSave')).height(48).onClick((): void => { this.saveAgentSetting('security', this.logText); })
            TextArea({ text: this.repoText, placeholder: this.text('aiAgentsConfigFile') })
              .height(240).onChange((content: string): void => { this.repoText = content; })
            Button(this.text('aiAgentsSaveConfig')).height(48).onClick((): void => { this.saveAgentSetting('configFile', this.repoText); })
          }.padding(16).width('100%')
        }.width('100%').height('100%')
      }.title(this.text('aiAgentsSettings'))
    } else if (name === 'agent-skills' || name === 'agent-plugins') {
      NavDestination() {
        List({ space: 10 }) {
          ListItem() {
            Column({ space: 8 }) {
              if (name === 'agent-plugins') this.sectionTitle('aiAgentPluginMarket')
              Row({ space: 8 }) {
                TextInput({ text: this.extensionQuery, placeholder: this.text(name === 'agent-plugins' ? 'aiAgentPluginSearchHint' : 'aiAgentsSkillSearchHint') })
                  .height(48).layoutWeight(1).onChange((content: string): void => { this.extensionQuery = content; })
                Button() { SymbolGlyph($r('sys.symbol.magnifyingglass')).fontSize(20) }
                  .width(48).height(48).enabled(!this.loading && this.extensionQuery.trim().length > 0)
                  .accessibilityText(this.text('commonSearch')).onClick((): void => { this.loadExtensions(name === 'agent-plugins', true); })
              }
              if (name === 'agent-skills') {
                Select(this.skillSources().map((source: string): SelectOption => ({ value: source })))
                  .selected(this.skillSourceIndex).height(48).width('100%')
                  .onSelect((index: number): void => { this.skillSourceIndex = index; this.foundExtensions = []; })
              }
              if (this.loading) LoadingProgress().width(40).height(40)
              if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
            }.width('100%')
          }
          ForEach(this.foundExtensions, (item: Map<string, Object | null>): void => {
            ListItem() { this.extensionRow(name === 'agent-plugins', item, true) }
          }, (item: Map<string, Object | null>): string => this.str(item, name === 'agent-plugins' ? 'package' : 'slug'))
          ListItem() {
            Row({ space: 8 }) {
              Text(this.text(name === 'agent-plugins' ? 'aiAgentInstalledPlugins' : 'aiAgentsSkills')).fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1)
              Button() { SymbolGlyph($r('sys.symbol.arrow_clockwise')).fontSize(20) }
                .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.loading)
                .accessibilityText(this.text('commonRefresh')).onClick((): void => { this.loadExtensions(name === 'agent-plugins'); })
            }.width('100%')
          }
          if (!this.loading && this.agentDetails.length === 0) ListItem() { Text(this.text('commonEmpty')).fontSize(14) }
          ForEach(this.agentDetails, (item: Map<string, Object | null>): void => {
            ListItem() { this.extensionRow(name === 'agent-plugins', item, false) }
          }, (item: Map<string, Object | null>): string => this.str(item, name === 'agent-plugins' ? 'id' : 'name'))
        }.padding(16).width('100%').height('100%')
      }.title(this.text(name === 'agent-skills' ? 'aiAgentsSkills' : 'aiAgentPluginsTitle'))
        .onShown((): void => { this.loadExtensions(name === 'agent-plugins'); })
    } else if (name === 'mcp-detail') {
      NavDestination() {
        Scroll() {
          Column({ space: 10 }) {
            Text(JSON.stringify(this.detail)).fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp)
            Button(this.text('commonEdit')).height(48).onClick((): void => { this.openMcpForm(this.detail); })
          }.padding(16).alignItems(HorizontalAlign.Start)
        }.width('100%').height('100%')
      }.title(this.str(this.detail, 'name'))
    } else if (name === 'gpu-history') {
      NavDestination() {
        Scroll() { Text(JSON.stringify(this.detail)).fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp).padding(16) }
      }.title(this.text('aiGpuHistoryTitle'))
    }
  }

  private nameArguments(): Map<string, Object | null> { const args = new Map<string, Object | null>(); args.set('name', this.nameText); return args; }
  private async discoverModels(): Promise<void> {
    const args = new Map<string, Object | null>(); args.set('provider', this.providerText); args.set('baseURL', this.baseURLText); args.set('apiKey', this.apiKeyText); args.set('apiType', this.apiTypeText);
    await this.mutate('discoverAgentModels', args, false);
  }
  private async loadAgentOverview(): Promise<void> {
    const args = new Map<string, Object | null>(); args.set('agentId', this.selectedAgent.get('id') as number);
    try { this.detail = await this.bridge.invoke<Map<string, Object | null>>('getAgentOverviewNative', args); }
    catch (error) { this.errorMessage = (error as Error).message; }
  }

  private updateSplitLayout(mode: NavigationMode): void {
    this.splitLayout = mode === NavigationMode.Split;
  }

  build() {
    Navigation(this.paths) { this.body() }
      .title(this.text('serverModuleAi'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true)
      .menus(this.rootMenus()).navDestination(this.destination)
      .mode(NavigationMode.Auto)
      .navBarWidth(240)
      .width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
      .onNavigationModeChange((mode: NavigationMode): void => {
        this.updateSplitLayout(mode);
      })
  }
}
