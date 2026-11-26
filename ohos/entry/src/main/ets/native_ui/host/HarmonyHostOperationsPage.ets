import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { HarmonyHostMonitoringHistory } from './HarmonyHostMonitoringHistory';
import { HarmonyHostTerminalPage } from './HarmonyHostTerminalPage';
import { HarmonyHostFailure, HarmonyHostLinkRow, HarmonyHostValueRow, hostString } from './HarmonyHostWidgets';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyHostOperationsPage {
  @Prop initialRoute: string = '/dashboard';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @State private dashboard: Map<string, Object | null> = new Map<string, Object | null>();
  @State private metrics: Map<string, Object | null> = new Map<string, Object | null>();
  @State private ssh: Map<string, Object | null> = new Map<string, Object | null>();
  @State private sshRawConfig: string = '';
  @State private sshPortDraft: string = '';
  @State private rules: Array<Map<string, Object | null>> = [];
  @State private hostRows: Array<Map<string, Object | null>> = [];
  @State private hostGroups: Array<Map<string, Object | null>> = [];
  @State private processRows: Array<Map<string, Object | null>> = [];
  @State private logs: string[] = [];
  @State private sshCerts: Array<Map<string, Object | null>> = [];
  @State private sshLogs: Array<Map<string, Object | null>> = [];
  @State private sshSessions: Array<Map<string, Object | null>> = [];
  @State private logFiles: string[] = [];
  @State private selectedLogFile: string = '';
  @State private useCoreLogs: boolean = false;
  @State private profileType: string = 'cpu';
  @State private profileDuration: number = 15;
  @State private capturingProfile: boolean = false;
  @State private searchText: string = '';
  @State private hostName: string = '';
  @State private hostDescription: string = '';
  @State private hostGroupIndex: number = -1;
  @State private hostAddress: string = '';
  @State private hostPort: string = '22';
  @State private hostUser: string = '';
  @State private hostAuthMode: string = 'password';
  @State private hostPassword: string = '';
  @State private hostPrivateKey: string = '';
  @State private hostPassPhrase: string = '';
  @State private rememberPassword: boolean = false;
  @State private hostConnectionVerified: boolean = false;
  @State private hostTesting: boolean = false;
  @State private certName: string = '';
  @State private certDescription: string = '';
  @State private certMode: string = 'generate';
  @State private certEncryptionMode: string = 'ed25519';
  @State private certPassPhrase: string = '';
  @State private certPublicKey: string = '';
  @State private certPrivateKey: string = '';
  @State private firewallAddress: string = '';
  @State private firewallPort: string = '';
  @State private firewallProtocol: string = 'tcp';
  @State private firewallStrategy: string = 'accept';
  @State private firewallDescription: string = '';
  @State private firewallState: string = '';
  @State private filterMode: string = 'port';
  @State private selectedProcess: Map<string, Object | null> = new Map<string, Object | null>();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly profileTypes: string[] = ['cpu', 'heap', 'goroutine', 'mutex', 'block', 'trace'];
  private readonly paths: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    if (this.initialRoute !== '/terminal') this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private routeTitle(): string {
    if (this.initialRoute === '/ssh/certs') return this.text('operationsSshCertsTitle');
    if (this.initialRoute === '/ssh/logs') return this.text('operationsSshLogsTitle');
    if (this.initialRoute === '/ssh/sessions') return this.text('operationsSshSessionsTitle');
    if (this.initialRoute.startsWith('/ssh')) return this.text('operationsSshTitle');
    if (this.initialRoute === '/processes/detail') return this.text('operationsProcessDetailTitle');
    if (this.initialRoute.startsWith('/process')) return this.text('operationsProcessesTitle');
    if (this.initialRoute.startsWith('/firewall')) return this.text('serverModuleFirewall');
    if (this.initialRoute.startsWith('/monitoring')) return this.text('serverModuleMonitoring');
    if (this.initialRoute === '/hosts/diagnostics') return this.text('hostDiagnosticsTitle');
    if (this.initialRoute === '/hosts-assets/form') return this.text('operationsHostAssetFormTitle');
    if (this.initialRoute === '/hosts-assets') return this.text('operationsHostAssetsTitle');
    if (this.initialRoute === '/logs/system') return this.text('operationsSystemLogViewerTitle');
    return this.text('serverModuleDashboard');
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      if (this.initialRoute === '/dashboard' || this.initialRoute === '/') {
        this.dashboard = await this.bridge.invoke<Map<string, Object | null>>('getDashboard');
      } else if (this.initialRoute.startsWith('/monitoring')) {
        this.metrics = await this.bridge.invoke<Map<string, Object | null>>('getMonitoring');
      } else if (this.initialRoute === '/ssh/certs') {
        const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeSshCerts');
        this.sshCerts = data.get('items') as Array<Map<string, Object | null>>;
      } else if (this.initialRoute === '/ssh/logs') {
        const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeSshLogs');
        this.sshLogs = data.get('items') as Array<Map<string, Object | null>>;
      } else if (this.initialRoute === '/ssh/sessions') {
        this.sshSessions = await this.bridge.invoke<Array<Map<string, Object | null>>>('getNativeSshSessions');
      } else if (this.initialRoute.startsWith('/ssh')) {
        const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeSshSettings');
        this.ssh = data;
        this.sshPortDraft = hostString(data, 'port');
        this.sshRawConfig = await this.bridge.invoke<string>('getNativeSshConfig');
      } else if (this.initialRoute.startsWith('/process')) {
        if (this.initialRoute === '/processes/detail') {
          const args = new Map<string, Object | null>();
          args.set('pid', this.routeArguments.get('pid') as number);
          this.selectedProcess = await this.bridge.invoke<Map<string, Object | null>>('getNativeProcessDetail', args);
        } else {
          await this.loadProcesses();
        }
      } else if (this.initialRoute.startsWith('/firewall')) {
        if (this.initialRoute === '/firewall-ips') this.filterMode = 'ip';
        const base = await this.bridge.invoke<Map<string, Object | null>>('getFirewallBaseInfo');
        this.firewallState = hostString(base, 'name') + ' · ' + hostString(base, 'version');
        this.rules = await this.bridge.invoke<Array<Map<string, Object | null>>>(
          this.filterMode === 'ip' ? 'getFirewallIpRules' : 'getFirewallRules');
      } else if (this.initialRoute.startsWith('/hosts-assets')) {
        if (this.initialRoute === '/hosts-assets/form') {
          await this.loadHostForm();
        } else {
          await this.loadHostAssets();
        }
      } else if (this.initialRoute === '/logs/system') {
        const names = await this.bridge.invoke<string[]>('getSystemLogFiles');
        this.logFiles = names;
        if (this.selectedLogFile.length === 0 && names.length > 0) this.selectedLogFile = names[0];
        await this.loadSelectedLog();
      } else if (this.initialRoute === '/hosts/diagnostics') {
        const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeHostDiagnostics');
        this.dashboard = data.get('summary') as Map<string, Object | null>;
        this.logs = [data.get('goroutines')?.toString() ?? ''];
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async loadProcesses(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('name', this.searchText);
    this.processRows = await this.bridge.invoke<Array<Map<string, Object | null>>>('getNativeProcesses', args);
  }

  private async stopProcess(): Promise<void> {
    const pid = this.selectedProcess.get('pid') as number;
    const message = this.text('processesStopConfirm').replace('{name}', hostString(this.selectedProcess, 'name'));
    if (!await this.confirmAction(this.text('commonStop'), message)) return;
    try {
      const args = new Map<string, Object | null>();
      args.set('pid', pid);
      await this.bridge.invoke<boolean>('stopNativeProcess', args);
      this.onBack();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    }
  }

  private async loadSelectedLog(): Promise<void> {
    if (this.selectedLogFile.length === 0) return;
    const args = new Map<string, Object | null>();
    args.set('fileName', this.selectedLogFile);
    args.set('useCoreLogs', this.useCoreLogs);
    const content = await this.bridge.invoke<Map<string, Object | null>>('getSystemLogContent', args);
    this.logs = content.get('lines') as string[];
  }

  private async captureProfile(): Promise<void> {
    this.capturingProfile = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('type', this.profileType);
      args.set('duration', this.profileDuration);
      await this.bridge.invoke<boolean>('captureNativeHostProfile', args);
      this.getUIContext().getPromptAction().showToast({ message: this.text('hostDiagnosticsCaptureDone') });
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    } finally {
      this.capturingProfile = false;
    }
  }

  private async loadHostForm(): Promise<void> {
    const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeHostGroups');
    this.hostGroups = data.get('items') as Array<Map<string, Object | null>>;
    const id = this.routeArguments.get('id') as number | null | undefined;
    if (id === undefined || id === null) {
      this.hostGroupIndex = this.hostGroups.findIndex((group: Map<string, Object | null>): boolean =>
        group.get('id') === data.get('defaultId'));
      this.hostUser = 'root';
      return;
    }
    const args = new Map<string, Object | null>();
    args.set('id', id);
    const item = await this.bridge.invoke<Map<string, Object | null>>('getNativeHostAsset', args);
    this.hostName = item.get('name') as string;
    this.hostAddress = item.get('addr') as string ?? '';
    this.hostPort = item.get('port')?.toString() ?? '';
    this.hostUser = item.get('user') as string ?? '';
    this.hostAuthMode = item.get('authMode') as string ?? '';
    this.hostPassword = item.get('password') as string ?? '';
    this.hostPrivateKey = item.get('privateKey') as string ?? '';
    this.hostPassPhrase = item.get('passPhrase') as string ?? '';
    this.rememberPassword = item.get('rememberPassword') === true;
    this.hostDescription = item.get('description') as string ?? '';
    this.hostGroupIndex = this.hostGroups.findIndex((group: Map<string, Object | null>): boolean =>
      group.get('id') === item.get('groupID'));
  }

  private async saveHostAsset(): Promise<void> {
    if (!this.hostConnectionVerified) {
      this.getUIContext().getPromptAction().showToast({
        message: this.text('hostAssetsConnectionNeedsTest'),
      });
      return;
    }
    const args = new Map<string, Object | null>();
    const id = this.routeArguments.get('id');
    if (id !== undefined && id !== null) args.set('id', id);
    args.set('name', this.hostName);
    args.set('description', this.hostDescription);
    if (this.hostGroupIndex >= 0) {
      const groupId = this.hostGroups[this.hostGroupIndex].get('id');
      if (groupId !== undefined && groupId !== null) args.set('groupID', groupId);
    }
    args.set('addr', this.hostAddress);
    args.set('port', Number(this.hostPort));
    args.set('user', this.hostUser);
    args.set('authMode', this.hostAuthMode);
    if (this.hostAuthMode === 'password') {
      args.set('password', this.hostPassword);
    } else {
      args.set('privateKey', this.hostPrivateKey);
      args.set('passPhrase', this.hostPassPhrase);
    }
    args.set('rememberPassword', this.rememberPassword);
    try {
      await this.bridge.invoke<boolean>('saveNativeHostAsset', args);
      this.onBack();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    }
  }

  private async testHostAsset(): Promise<void> {
    this.hostTesting = true;
    const args = new Map<string, Object | null>();
    args.set('addr', this.hostAddress);
    args.set('port', Number(this.hostPort));
    args.set('user', this.hostUser);
    args.set('authMode', this.hostAuthMode);
    if (this.hostAuthMode === 'password') args.set('password', this.hostPassword);
    else {
      args.set('privateKey', this.hostPrivateKey);
      args.set('passPhrase', this.hostPassPhrase);
    }
    try {
      this.hostConnectionVerified = await this.bridge.invoke<boolean>('testNativeHostAsset', args);
      this.getUIContext().getPromptAction().showToast({
        message: this.text(this.hostConnectionVerified ? 'hostAssetsConnectionVerified' : 'hostAssetsTestFailed'),
      });
    } catch (error) {
      this.hostConnectionVerified = false;
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    } finally {
      this.hostTesting = false;
    }
  }

  private async saveFirewallRule(): Promise<void> {
    const args = new Map<string, Object | null>();
    if (this.filterMode === 'ip') args.set('address', this.firewallAddress);
    else {
      args.set('address', this.firewallAddress);
      args.set('port', this.firewallPort);
      args.set('protocol', this.firewallProtocol);
    }
    args.set('strategy', this.firewallStrategy);
    args.set('description', this.firewallDescription);
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('addFirewallRule', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      if (this.initialRoute === '/firewall-rule-form') {
        this.onBack();
      } else {
        this.paths.pop();
        await this.load();
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    }
  }

  private async askAndRun(title: string, message: string, run: () => Promise<void>): Promise<void> {
    if (await this.confirmAction(title, message)) await run();
  }

  private async deleteFirewallRule(rule: Map<string, Object | null>): Promise<void> {
    const args = new Map<string, Object | null>();
    const inventoryId = rule.get('inventoryId');
    if (inventoryId !== undefined && inventoryId !== null) args.set('inventoryId', inventoryId);
    args.set('serverId', rule.get('serverId') ?? null);
    args.set('address', rule.get('address') ?? null);
    args.set('port', rule.get('port') ?? null);
    args.set('protocol', rule.get('protocol') ?? null);
    args.set('strategy', rule.get('strategy') ?? null);
    if (!await this.confirmAction(this.text('firewallOperationConfirmTitle'),
      this.text('firewallDeleteSelectedConfirm').replace('{count}', '1'))) return;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('deleteFirewallRule', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    }
  }

  private async confirmAction(title: string, message: string): Promise<boolean> {
    const result = await this.getUIContext().getPromptAction().showDialog({
      title: title,
      message: message,
      buttons: [
        { text: this.text('commonCancel'), color: $r('sys.color.font_secondary') },
        { text: this.text('commonConfirm'), color: $r('sys.color.font_primary') },
      ],
    });
    return result.index === 1;
  }

  private async changeSsh(key: string, current: string, next: string): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('key', key);
    args.set('oldValue', current);
    args.set('newValue', next);
    if (!await this.confirmAction(this.text('operationsSshTitle'),
      this.text('sshUpdateSettingConfirm').replace('{label}', key).replace('{value}', next))) return;
    await this.bridge.invoke<boolean>('updateNativeSshSetting', args);
    await this.load();
  }

  private async operateSsh(operation: string): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('operation', operation);
    if (!await this.confirmAction(this.text('operationsSshTitle'),
      this.text('sshOperateConfirm').replace('{operation}', operation))) return;
    await this.bridge.invoke<boolean>('operateNativeSsh', args);
    await this.load();
  }

  private async saveSshCert(): Promise<void> {
    const args = new Map<string, Object | null>();
    const id = this.routeArguments.get('id');
    if (id !== undefined && id !== null) args.set('id', id);
    args.set('name', this.certName);
    args.set('mode', this.certMode);
    args.set('encryptionMode', this.certEncryptionMode);
    args.set('passPhrase', this.certPassPhrase);
    args.set('publicKey', this.certPublicKey);
    args.set('privateKey', this.certPrivateKey);
    args.set('description', this.certDescription);
    await this.bridge.invoke<boolean>('saveNativeSshCert', args);
    this.paths.pop();
    await this.load();
  }

  @Builder
  private sshCertFormContent() {
    Scroll() {
      Column({ space: 12 }) {
        TextInput({ text: this.certName, placeholder: this.text('commonName') })
          .height(52).onChange((value: string): void => { this.certName = value; })
        Select([{ value: this.text('sshCertModeGenerate') },
          { value: this.text('sshCertModeInput') }, { value: this.text('sshCertModeImport') }])
          .selected(0).value(this.text('sshCertModeGenerate'))
          .onSelect((index: number): void => {
            this.certMode = ['generate', 'input', 'import'][index];
          })
        Select([{ value: 'ed25519' }, { value: 'rsa' }, { value: 'ecdsa' }, { value: 'dsa' }])
          .selected(0).value(this.certEncryptionMode)
          .onSelect((index: number): void => {
            this.certEncryptionMode = ['ed25519', 'rsa', 'ecdsa', 'dsa'][index];
          })
        TextInput({ text: this.certPassPhrase, placeholder: this.text('sshCertPassPhraseLabel') })
          .type(InputType.Password).height(52)
          .onChange((value: string): void => { this.certPassPhrase = value; })
        if (this.certMode !== 'generate') {
          TextArea({ text: this.certPublicKey, placeholder: this.text('sshCertPublicKeyLabel') })
            .height(120).onChange((value: string): void => { this.certPublicKey = value; })
          TextArea({ text: this.certPrivateKey, placeholder: this.text('sshCertPrivateKeyLabel') })
            .height(180).onChange((value: string): void => { this.certPrivateKey = value; })
        }
        if (this.certMode === 'import') {
          Button(this.text('sshCertPublicKeyLabel')).height(48).width('100%').onClick(async (): Promise<void> => {
            const key = await this.bridge.invoke<string | null>('pickNativeSshKey');
            if (key !== null) this.certPublicKey = key;
          })
          Button(this.text('sshCertPrivateKeyLabel')).height(48).width('100%').onClick(async (): Promise<void> => {
            const key = await this.bridge.invoke<string | null>('pickNativeSshKey');
            if (key !== null) this.certPrivateKey = key;
          })
        }
        TextInput({ text: this.certDescription, placeholder: this.text('commonDescription') })
          .height(48).onChange((value: string): void => { this.certDescription = value; })
        Button(this.text('commonSave')).height(48).width('100%')
          .enabled(this.certName.trim().length > 0 &&
            (this.certMode === 'generate' || (this.certPublicKey.trim().length > 0 && this.certPrivateKey.trim().length > 0)))
          .onClick(async (): Promise<void> => {
          await this.saveSshCert();
        })
      }.width('100%').padding(16)
    }.width('100%').height('100%')
  }

  private async deleteSshCert(item: Map<string, Object | null>): Promise<void> {
    const args = new Map<string, Object | null>();
    const id = item.get('id');
    if (id === undefined || id === null) return;
    args.set('ids', [id as number]);
    args.set('forceDelete', false);
    await this.askAndRun(this.text('operationsSshCertsTitle'),
      this.text('sshCertDeleteConfirm').replace('{name}', hostString(item, 'name')),
      async (): Promise<void> => {
        await this.bridge.invoke<boolean>('deleteNativeSshCerts', args);
        await this.load();
      });
  }

  private async operateFirewall(operation: string): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('operation', operation);
    const messageKey = operation === 'start' ? 'firewallStartConfirmMessage'
      : operation === 'stop' ? 'firewallStopConfirmMessage' : 'firewallRestartConfirmMessage';
    if (!await this.confirmAction(this.text('firewallOperationConfirmTitle'), this.text(messageKey))) return;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('operateFirewall', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    }
  }

  private rootMenus(): NavigationMenuItem[] {
    return [{
      value: this.text('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.load(); },
    }];
  }

  @Builder
  private linkRows() {
    Column({ space: 10 }) {
      HarmonyHostLinkRow({ label: this.text('serverModuleMonitoring'), symbol: $r('sys.symbol.clock'),
        onOpen: (): void => { this.bridge.openNativePage('/monitoring'); } })
      HarmonyHostLinkRow({ label: this.text('serverModuleFirewall'), symbol: $r('sys.symbol.checkmark_shield'),
        onOpen: (): void => { this.bridge.openNativePage('/firewall'); } })
      HarmonyHostLinkRow({ label: this.text('serverModuleTerminal'), symbol: $r('sys.symbol.doc_plaintext'),
        onOpen: (): void => { this.bridge.openNativePage('/terminal'); } })
      HarmonyHostLinkRow({ label: this.text('operationsSshTitle'), symbol: $r('sys.symbol.lock'),
        onOpen: (): void => { this.bridge.openNativePage('/ssh'); } })
      HarmonyHostLinkRow({ label: this.text('operationsProcessesTitle'), symbol: $r('sys.symbol.list_bullet'),
        onOpen: (): void => { this.bridge.openNativePage('/processes'); } })
      HarmonyHostLinkRow({ label: this.text('operationsHostAssetsTitle'), symbol: $r('sys.symbol.externaldrive'),
        onOpen: (): void => { this.bridge.openNativePage('/hosts-assets'); } })
      HarmonyHostLinkRow({ label: this.text('operationsToolboxTitle'), symbol: $r('sys.symbol.gearshape'),
        onOpen: (): void => { this.bridge.openNativePage('/toolbox'); } })
      HarmonyHostLinkRow({ label: this.text('logsSystemTabLabel'), symbol: $r('sys.symbol.doc_text'),
        onOpen: (): void => { this.bridge.openNativePage('/logs/system'); } })
    }
  }

  @Builder
  private dashboardContent() {
    List({ space: 12 }) {
      ListItemGroup() {
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardHostNameLabel'), content: hostString(this.dashboard, 'hostname') }) }
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardOsLabel'), content: hostString(this.dashboard, 'os') }) }
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardUptimeLabel'), content: hostString(this.dashboard, 'uptime') }) }
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      ListItemGroup({ header: (): void => { Text(this.text('dashboardResourceTitle')).fontSize(16).padding(8); } }) {
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardCpuUsage'), content: hostString(this.dashboard, 'cpu') + '%' }) }
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardMemoryUsage'), content: hostString(this.dashboard, 'memory') + '%' }) }
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardDiskUsage'), content: hostString(this.dashboard, 'disk') + '%' }) }
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      ListItem() { this.linkRows() }
    }
    .width('100%').padding(16)
  }

  @Builder
  private monitoringContent() {
    List({ space: 12 }) {
      ListItemGroup() {
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardCpuUsage'), content: hostString(this.metrics, 'cpu') + '%' }) }
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardMemoryUsage'), content: hostString(this.metrics, 'memory') + '%' }) }
        ListItem() { HarmonyHostValueRow({ label: this.text('dashboardDiskUsage'), content: hostString(this.metrics, 'disk') + '%' }) }
        ListItem() { HarmonyHostValueRow({ label: this.text('monitorLoadAverageTitle'),
          content: hostString(this.metrics, 'load1') + ' / ' + hostString(this.metrics, 'load5') + ' / ' + hostString(this.metrics, 'load15') }) }
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      ListItem() { HarmonyHostMonitoringHistory() }
      ListItem() {
        HarmonyHostLinkRow({ label: this.text('monitorSettingTitle'), symbol: $r('sys.symbol.gearshape'),
          onOpen: (): void => { this.bridge.openNativePage('/system-settings/monitor'); } })
      }
    }.width('100%').padding(16)
  }

  @Builder
  private sshContent() {
    List({ space: 12 }) {
      ListItemGroup() {
        ListItem() { HarmonyHostValueRow({ label: this.text('sshCurrentUserLabel'), content: hostString(this.ssh, 'currentUser') }) }
        ListItem() {
          Row({ space: 8 }) {
            Text(this.text('sshPortLabel')).layoutWeight(1)
            TextInput({ text: this.sshPortDraft }).type(InputType.Number)
              .width(100).height(48).accessibilityText(this.text('sshPortLabel')).onChange((value: string): void => { this.sshPortDraft = value; })
            Button(this.text('commonSave')).height(48).onClick((): void => {
              this.changeSsh('Port', hostString(this.ssh, 'port'), this.sshPortDraft);
            })
          }.width('100%').padding(12)
        }
        ListItem() { HarmonyHostValueRow({ label: this.text('sshListenAddressLabel'), content: hostString(this.ssh, 'listenAddress') }) }
        ListItem() {
          Row() {
            Text(this.text('sshPermitRootLoginLabel')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: hostString(this.ssh, 'permitRootLogin') === 'yes' })
              .onChange((enabled: boolean): void => { this.changeSsh('PermitRootLogin', hostString(this.ssh, 'permitRootLogin'), enabled ? 'yes' : 'no'); })
          }.width('100%').padding(12)
        }
        ListItem() {
          Row() {
            Text(this.text('sshPasswordAuthenticationLabel')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: hostString(this.ssh, 'passwordAuthentication') === 'yes' })
              .onChange((enabled: boolean): void => { this.changeSsh('PasswordAuthentication', hostString(this.ssh, 'passwordAuthentication'), enabled ? 'yes' : 'no'); })
          }.width('100%').padding(12)
        }
        ListItem() {
          Row() {
            Text(this.text('sshPubkeyAuthenticationLabel')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: hostString(this.ssh, 'pubkeyAuthentication') === 'yes' })
              .onChange((enabled: boolean): void => { this.changeSsh('PubkeyAuthentication', hostString(this.ssh, 'pubkeyAuthentication'), enabled ? 'yes' : 'no'); })
          }.width('100%').padding(12)
        }
        ListItem() {
          Row() {
            Text(this.text('sshUseDnsLabel')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: hostString(this.ssh, 'useDNS') === 'yes' })
              .onChange((enabled: boolean): void => { this.changeSsh('UseDNS', hostString(this.ssh, 'useDNS'), enabled ? 'yes' : 'no'); })
          }.width('100%').padding(12)
        }
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      ListItem() { this.sshLinks() }
      ListItem() {
        Row({ space: 8 }) {
          Button(this.text('commonStart')).height(48).onClick((): void => { this.operateSsh('start'); })
          Button(this.text('commonStop')).height(48).onClick((): void => { this.operateSsh('stop'); })
          Button(this.text('commonRestart')).height(48).onClick((): void => { this.operateSsh('restart'); })
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)
      }
      ListItem() {
        TextArea({ text: this.sshRawConfig })
          .width('100%').height(240).fontSize(14)
          .onChange((value: string): void => { this.sshRawConfig = value; })
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16).padding(12)
      ListItem() {
        Button(this.text('commonSave')).height(48).width('100%').onClick(async (): Promise<void> => {
          const args = new Map<string, Object | null>();
          args.set('value', this.sshRawConfig);
          await this.askAndRun(this.text('sshSettingsRawFileSectionTitle'), this.text('sshSaveRawFileConfirm'),
            async (): Promise<void> => {
              await this.bridge.invoke<boolean>('saveNativeSshConfig', args);
              await this.load();
            });
        })
      }
    }.width('100%').padding(16)
  }

  @Builder
  private processContent() {
    if (this.initialRoute === '/processes/detail') {
      List() {
        ForEach(Array.from(this.selectedProcess.keys()), (key: string): void => {
          ListItem() { HarmonyHostValueRow({ label: key, content: hostString(this.selectedProcess, key) }) }
        }, (key: string): string => key)
        ListItem() {
          Button(this.text('commonStop')).height(48).onClick((): void => { this.stopProcess(); })
        }
      }.width('100%').padding(16)
    } else {
      Column({ space: 8 }) {
        TextInput({ text: this.searchText, placeholder: this.text('processesSearchNameLabel') })
          .height(48).onChange((value: string): void => { this.searchText = value; })
          .onSubmit((): void => { this.load(); })
        List({ space: 8 }) {
          ForEach(this.processRows, (item: Map<string, Object | null>): void => {
            ListItem() {
              HarmonyHostLinkRow({
                label: hostString(item, 'name'),
                detail: 'PID ' + hostString(item, 'pid') + ' · ' + hostString(item, 'username'),
                symbol: $r('sys.symbol.gearshape'),
                onOpen: (): void => {
                  const args = new Map<string, Object | null>();
                  args.set('pid', item.get('pid') as number);
                  this.bridge.openNativePage('/processes/detail', args);
                },
              })
            }
          }, (item: Map<string, Object | null>): string => hostString(item, 'pid'))
        }.layoutWeight(1)
      }.width('100%').height('100%').padding(16)
    }
  }

  @Builder
  private firewallContent() {
    List({ space: 12 }) {
      ListItem() {
        Row({ space: 8 }) {
          Text(this.firewallState).layoutWeight(1)
          Button(this.text('commonStart')).height(48).onClick((): void => { this.operateFirewall('start'); })
          Button(this.text('commonStop')).height(48).onClick((): void => { this.operateFirewall('stop'); })
        }.width('100%')
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16).padding(12)
      ListItem() {
        Row({ space: 8 }) {
          Button(this.text('firewallTabPorts')).height(48).onClick((): void => { this.filterMode = 'port'; this.load(); })
          Button(this.text('firewallTabIps')).height(48).onClick((): void => { this.filterMode = 'ip'; this.load(); })
          Button(this.text('commonAdd')).height(48).onClick((): void => {
            this.paths.pushPath({ name: 'firewall-form' });
          })
        }.width('100%')
      }
      ListItem() {
        HarmonyHostLinkRow({ label: this.text('firewallV2Title'), symbol: $r('sys.symbol.checkmark_shield'),
          onOpen: (): void => { this.bridge.openNativePage('/firewall-v2'); } })
      }
      ForEach(this.rules, (rule: Map<string, Object | null>): void => {
        ListItem() {
          Column({ space: 4 }) {
            Text(hostString(rule, 'description')).fontSize(16).fontWeight(FontWeight.Medium)
            Text(hostString(rule, 'address') + ' · ' + hostString(rule, 'port') + ' · ' + hostString(rule, 'protocol'))
              .fontSize(14).fontColor($r('sys.color.font_secondary'))
            Row() {
              Text(hostString(rule, 'strategy')).fontSize(14).layoutWeight(1)
              if (rule.get('canDelete') === true) {
                Button(this.text('commonDelete')).height(48).onClick((): void => {
                  this.deleteFirewallRule(rule);
                })
              }
            }.width('100%')
          }.width('100%').padding(16)
        }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      }, (rule: Map<string, Object | null>): string => hostString(rule, 'id'))
    }.width('100%').padding(16)
  }

  @Builder
  private hostAssetsContent() {
    List({ space: 8 }) {
      ListItem() {
        Row({ space: 8 }) {
          TextInput({ text: this.searchText, placeholder: this.text('hostAssetsSearchHint') })
            .layoutWeight(1).height(48)
            .onChange((value: string): void => { this.searchText = value; })
            .onSubmit((): void => { this.load(); })
          Button(this.text('commonAdd')).height(48).onClick((): void => {
            this.bridge.openNativePage('/hosts-assets/form');
          })
        }.width('100%')
      }
      ForEach(this.hostRows, (item: Map<string, Object | null>): void => {
        ListItem() {
          HarmonyHostLinkRow({ label: hostString(item, 'name'),
            detail: hostString(item, 'user') + '@' + hostString(item, 'addr') + ':' + hostString(item, 'port'),
            symbol: $r('sys.symbol.externaldrive'),
            onOpen: (): void => {
              const id = item.get('id');
              if (id !== undefined && id !== null) {
                const args = new Map<string, Object | null>();
                args.set('id', id);
                this.bridge.openNativePage('/hosts-assets/form', args);
              }
            } })
        }
      }, (item: Map<string, Object | null>): string => hostString(item, 'id'))
    }.width('100%').padding(16)
  }

  private async loadHostAssets(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('info', this.searchText);
    const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeHostAssets', args);
    this.hostRows = data.get('items') as Array<Map<string, Object | null>>;
  }

  @Builder
  private hostFormContent() {
    Scroll() {
      Column({ space: 12 }) {
        TextInput({ text: this.hostName, placeholder: this.text('commonName') })
          .height(52).onChange((value: string): void => { this.hostName = value; })
        TextInput({ text: this.hostAddress, placeholder: this.text('hostAssetsAddressLabel') })
          .height(52).onChange((value: string): void => {
            this.hostAddress = value;
            this.hostConnectionVerified = false;
          })
        TextInput({ text: this.hostPort, placeholder: this.text('hostAssetsPortLabel') }).type(InputType.Number)
          .height(52).onChange((value: string): void => {
            this.hostPort = value;
            this.hostConnectionVerified = false;
          })
        TextInput({ text: this.hostUser, placeholder: this.text('hostAssetsUserLabel') })
          .height(52).onChange((value: string): void => {
            this.hostUser = value;
            this.hostConnectionVerified = false;
          })
        if (this.hostGroups.length > 0) {
          Select(this.hostGroups.map((group: Map<string, Object | null>): SelectOption => ({
            value: group.get('name') as string ?? this.text('operationsGroupDefaultLabel'),
          })))
            .selected(this.hostGroupIndex).height(48)
            .value(this.hostGroupIndex >= 0
              ? hostString(this.hostGroups[this.hostGroupIndex], 'name') : this.text('hostAssetsGroupLabel'))
            .onSelect((index: number): void => { this.hostGroupIndex = index; })
        }
        TextInput({ text: this.hostDescription, placeholder: this.text('commonDescription') })
          .height(52).onChange((value: string): void => { this.hostDescription = value; })
        Select([
          { value: this.text('hostAssetsPasswordMode') },
          { value: this.text('hostAssetsKeyMode') },
        ])
          .selected(this.hostAuthMode === 'password' ? 0 : 1)
          .value(this.hostAuthMode === 'password' ? this.text('hostAssetsPasswordMode') : this.text('hostAssetsKeyMode'))
          .onSelect((index: number): void => {
            this.hostAuthMode = index === 0 ? 'password' : 'key';
            this.hostConnectionVerified = false;
          })
        if (this.hostAuthMode === 'password') {
          TextInput({ text: this.hostPassword, placeholder: this.text('hostAssetsPasswordLabel') }).type(InputType.Password)
            .height(52).onChange((value: string): void => {
              this.hostPassword = value;
              this.hostConnectionVerified = false;
            })
        } else {
          TextArea({ text: this.hostPrivateKey, placeholder: this.text('hostAssetsPrivateKeyLabel') })
            .height(180).onChange((value: string): void => {
              this.hostPrivateKey = value;
              this.hostConnectionVerified = false;
            })
          TextInput({ text: this.hostPassPhrase, placeholder: this.text('hostAssetsPassPhraseLabel') }).type(InputType.Password)
            .height(52).onChange((value: string): void => {
              this.hostPassPhrase = value;
              this.hostConnectionVerified = false;
            })
        }
        Row() {
          Text(this.text('hostAssetsRememberPasswordLabel')).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.rememberPassword })
            .onChange((enabled: boolean): void => { this.rememberPassword = enabled; })
        }.width('100%').constraintSize({ minHeight: 48 })
        Button(this.text('hostAssetsTestAction')).height(48).width('100%')
          .enabled(!this.hostTesting && this.hostAddress.trim().length > 0 && this.hostUser.trim().length > 0 &&
            Number(this.hostPort) >= 1 && Number(this.hostPort) <= 65535)
          .onClick(async (): Promise<void> => {
          if (this.hostTesting) return;
          await this.testHostAsset();
        })
        Button(this.text('commonSave')).height(48).width('100%')
          .enabled(this.hostConnectionVerified && this.hostName.trim().length > 0 && this.hostGroupIndex >= 0)
          .onClick(async (): Promise<void> => {
          await this.saveHostAsset();
        })
      }.width('100%').padding(16)
    }.width('100%').height('100%')
  }

  @Builder
  private logsContent() {
    Column({ space: 8 }) {
      Select(this.logFiles.map((name: string): SelectOption => ({ value: name })))
        .value(this.selectedLogFile)
        .onSelect((index: number): void => {
          this.selectedLogFile = this.logFiles[index];
          this.loadSelectedLog();
        })
      Toggle({ type: ToggleType.Switch, isOn: this.useCoreLogs })
        .onChange((enabled: boolean): void => { this.useCoreLogs = enabled; this.loadSelectedLog(); })
      Scroll() {
        Text(this.logs.join('\n')).fontSize(12).fontFamily('monospace')
          .fontColor($r('sys.color.font_primary')).copyOption(CopyOptions.InApp)
          .width('100%').padding(12)
      }.layoutWeight(1).width('100%')
    }.width('100%').height('100%').padding(12)
  }

  @Builder
  private diagnosticsContent() {
    Scroll() {
      Column({ space: 12 }) {
        Text(this.text('hostDiagnosticsSummary')).fontSize(18).fontWeight(FontWeight.Medium)
        ForEach(Array.from(this.dashboard.keys()), (key: string): void => {
          HarmonyHostValueRow({ label: key, content: hostString(this.dashboard, key) })
        }, (key: string): string => key)
        Row({ space: 8 }) {
          Select(this.profileTypes.map((type: string): SelectOption => ({ value: type })))
            .value(this.profileType).height(48).enabled(!this.capturingProfile)
            .onSelect((index: number): void => { this.profileType = this.profileTypes[index]; })
          Button(this.text('hostDiagnosticsCapture')).height(48).enabled(!this.capturingProfile)
            .onClick((): void => { this.captureProfile(); })
        }.width('100%')
        Text(this.text('hostDiagnosticsDuration') + ' ' + this.profileDuration + ' s').fontSize(14)
        Slider({ value: this.profileDuration, min: 5, max: 60, step: 5 }).width('100%')
          .enabled(!this.capturingProfile).onChange((value: number): void => { this.profileDuration = value; })
        Text(this.text('hostDiagnosticsGoroutines')).fontSize(18).fontWeight(FontWeight.Medium)
        Text(this.logs.join('\n')).fontSize(12).fontFamily('monospace').copyOption(CopyOptions.InApp)
      }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private firewallFormContent() {
    Column({ space: 12 }) {
      if (this.filterMode === 'ip') {
        TextInput({ text: this.firewallAddress, placeholder: this.text('firewallAddressLabel') })
          .height(52).onChange((value: string): void => { this.firewallAddress = value; })
      } else {
        TextInput({ text: this.firewallAddress, placeholder: this.text('firewallAddressLabel') })
          .height(52).onChange((value: string): void => { this.firewallAddress = value; })
        TextInput({ text: this.firewallPort, placeholder: this.text('firewallPortLabel') })
          .height(52).onChange((value: string): void => { this.firewallPort = value; })
        Select([{ value: 'TCP' }, { value: 'UDP' }])
          .selected(this.firewallProtocol === 'tcp' ? 0 : 1)
          .value(this.firewallProtocol.toUpperCase())
          .onSelect((index: number): void => { this.firewallProtocol = index === 0 ? 'tcp' : 'udp'; })
      }
      Select([{ value: this.text('firewallStrategyAccept') }, { value: this.text('firewallStrategyDrop') }])
        .selected(this.firewallStrategy === 'accept' ? 0 : 1)
        .value(this.firewallStrategy === 'accept' ? this.text('firewallStrategyAccept') : this.text('firewallStrategyDrop'))
        .onSelect((index: number): void => { this.firewallStrategy = index === 0 ? 'accept' : 'drop'; })
      TextInput({ text: this.firewallDescription, placeholder: this.text('firewallDescriptionLabel') })
        .height(52).onChange((value: string): void => { this.firewallDescription = value; })
      Button(this.text('commonSave')).height(48).width('100%')
        .enabled(this.filterMode === 'ip' ? this.firewallAddress.trim().length > 0 : this.firewallPort.trim().length > 0)
        .onClick(async (): Promise<void> => {
        await this.saveFirewallRule();
      })
    }.width('100%').padding(16)
  }

  @Builder
  private sshLinks() {
    Column({ space: 8 }) {
      HarmonyHostLinkRow({ label: this.text('operationsSshCertsTitle'),
        onOpen: (): void => { this.bridge.openNativePage('/ssh/certs'); } })
      HarmonyHostLinkRow({ label: this.text('operationsSshLogsTitle'),
        onOpen: (): void => { this.bridge.openNativePage('/ssh/logs'); } })
      HarmonyHostLinkRow({ label: this.text('operationsSshSessionsTitle'),
        onOpen: (): void => { this.bridge.openNativePage('/ssh/sessions'); } })
    }
  }

  @Builder
  private sshSubpage() {
    if (this.initialRoute === '/ssh/certs') {
      List({ space: 8 }) {
        ListItem() {
          Row({ space: 8 }) {
            Button(this.text('commonRefresh')).height(48).onClick((): void => {
              this.askAndRun(this.text('operationsSshCertsTitle'), this.text('sshCertSyncConfirm'),
                async (): Promise<void> => {
                  await this.bridge.invoke<boolean>('syncNativeSshCerts');
                  await this.load();
                });
            })
            Button(this.text('commonAdd')).height(48).onClick((): void => {
              this.paths.pushPath({ name: 'ssh-cert-form' });
            })
          }
        }
        ForEach(this.sshCerts, (item: Map<string, Object | null>): void => {
          ListItem() {
            Column({ space: 4 }) {
              Text(hostString(item, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
              Text(hostString(item, 'encryptionMode') + ' · ' + hostString(item, 'createdAt'))
                .fontSize(14).fontColor($r('sys.color.font_secondary'))
              Text(hostString(item, 'publicKey')).fontSize(12).maxLines(3).copyOption(CopyOptions.InApp)
              Button(this.text('commonDelete')).height(48).onClick((): void => { this.deleteSshCert(item); })
            }.width('100%').padding(16)
          }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
        }, (item: Map<string, Object | null>): string => hostString(item, 'id'))
      }.width('100%').padding(16)
    } else if (this.initialRoute === '/ssh/logs') {
      List({ space: 8 }) {
        ForEach(this.sshLogs, (item: Map<string, Object | null>): void => {
          ListItem() {
            Column({ space: 4 }) {
              Text(hostString(item, 'user') + ' · ' + hostString(item, 'address')).fontSize(16)
              Text(hostString(item, 'date') + ' · ' + hostString(item, 'status') + ' · ' + hostString(item, 'message'))
                .fontSize(14).fontColor($r('sys.color.font_secondary')).maxLines(3)
            }.width('100%').padding(16)
          }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
        }, (item: Map<string, Object | null>): string => hostString(item, 'date') + hostString(item, 'address'))
      }.width('100%').padding(16)
    } else {
      List({ space: 8 }) {
        ForEach(this.sshSessions, (item: Map<string, Object | null>): void => {
          ListItem() {
            Column() {
              HarmonyHostLinkRow({
                label: hostString(item, 'username') + ' · ' + hostString(item, 'host'),
                detail: hostString(item, 'terminal') + ' · ' + hostString(item, 'loginTime'),
                symbol: $r('sys.symbol.person'),
              })
              Button(this.text('containerTerminalDisconnect')).height(48).onClick((): void => {
                const pid = item.get('pid');
                if (pid === undefined || pid === null) return;
                const args = new Map<string, Object | null>();
                args.set('pid', pid);
                this.askAndRun(this.text('operationsSshSessionsTitle'),
                  this.text('sshSessionDisconnectConfirm').replace('{username}', hostString(item, 'username')),
                  async (): Promise<void> => {
                    await this.bridge.invoke<boolean>('disconnectNativeSshSession', args);
                    await this.load();
                  });
              })
            }.width('100%')
          }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
        }, (item: Map<string, Object | null>): string => hostString(item, 'pid'))
      }.width('100%').padding(16)
    }
  }

  @Builder
  private pageContent() {
    if (this.initialRoute === '/hosts-assets/form') {
      this.hostFormContent()
    } else if (this.initialRoute === '/firewall-rule-form') {
      this.firewallFormContent()
    } else if (this.initialRoute === '/ssh/certs' ||
      this.initialRoute === '/ssh/logs' || this.initialRoute === '/ssh/sessions') {
      this.sshSubpage()
    } else if (this.initialRoute === '/monitoring') {
      this.monitoringContent()
    } else if (this.initialRoute.startsWith('/ssh')) {
      this.sshContent()
    } else if (this.initialRoute.startsWith('/process')) {
      this.processContent()
    } else if (this.initialRoute.startsWith('/firewall')) {
      this.firewallContent()
    } else if (this.initialRoute === '/logs/system') {
      this.logsContent()
    } else if (this.initialRoute === '/hosts/diagnostics') {
      this.diagnosticsContent()
    } else if (this.initialRoute === '/hosts-assets') {
      this.hostAssetsContent()
    } else {
      this.dashboardContent()
    }
  }

  @Builder
  private hostPage() {
    Navigation(this.paths) {
      if (this.loading) {
        Column() { LoadingProgress().width(48).height(48) }
          .layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (this.errorMessage.length > 0) {
        HarmonyHostFailure({ message: this.errorMessage, onRetry: (): void => { this.load(); } })
          .layoutWeight(1)
      } else {
        this.pageContent()
      }
    }
    .title(this.routeTitle(), moduleTitleOptions)
    .titleMode(NavigationTitleMode.Mini)
    .menus(this.rootMenus())
    .backgroundColor($r('sys.color.background_secondary'))
    .navDestination(this.destination)
    .mode(NavigationMode.Stack)
  }

  build() {
    if (this.initialRoute === '/terminal') {
      HarmonyHostTerminalPage()
    } else {
      this.hostPage()
    }
  }

  @Builder
  private destination(name: string, parameter: Object) {
    NavDestination() {
      if (name === 'firewall-form') {
        this.firewallFormContent()
      } else if (name === 'ssh-cert-form') {
        this.sshCertFormContent()
      }
    }
    .title(name === 'firewall-form' ? this.text('firewallCreateRuleAction') : this.text('sshCertCreateTitle'),
      { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
