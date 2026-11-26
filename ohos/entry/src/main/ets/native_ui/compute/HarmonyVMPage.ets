import { SymbolGlyphModifier } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyComputeInfo, computeText, computeWrite } from './HarmonyComputeControls';
import { HarmonyVMFormPage } from './HarmonyVMFormPage';
import { HarmonyAutomationTitle } from '../automation/HarmonyAutomationUI';

@Component
export struct HarmonyVMPage {
  onBack: () => void = (): void => {};
  @Prop initialRoute: string = '/vm';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @Prop showBack: boolean = true;
  @State private selectedTab: number = 0;
  @State private environment: Map<string, Object | null> = new Map<string, Object | null>();
  @State private vms: Map<string, Object | null>[] = [];
  @State private networks: Map<string, Object | null>[] = [];
  @State private storages: Map<string, Object | null>[] = [];
  @State private isos: Map<string, Object | null>[] = [];
  @State private templates: Map<string, Object | null>[] = [];
  @State private selectedVm: Map<string, Object | null> = new Map<string, Object | null>();
  @State private snapshots: Map<string, Object | null>[] = [];
  @State private healthItems: Map<string, Object | null>[] = [];
  @State private stats: Map<string, Object | null>[] = [];
  @State private monitorMessage: string = '';
  @State private chartWidth: number = 0;
  @State private orphanItems: Map<string, Object | null>[] = [];
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private searchText: string = '';
  @State private snapshotName: string = '';
  @State private snapshotDescription: string = '';
  @State private creatingSnapshot: boolean = false;
  @State private actionName: string = '';
  @State private actionRecord: Map<string, Object | null> = new Map<string, Object | null>();
  @State private actionText: string = '';
  @State private actionPath: string = '';
  @State private forceDelete: boolean = false;
  @State private selectedOrphans: Map<string, Object | null>[] = [];
  @State private resultText: string = '';
  private paths: NavPathStack = new NavPathStack();
  private monitorTimer: number = -1;
  private monitorVisible: boolean = false;
  private monitorLoading: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private tabNames: string[] = ['vmTabOverview', 'vmTabInstances', 'vmTabNetworks', 'vmTabStorages', 'vmTabIso', 'vmTabTemplates'];

  aboutToAppear(): void {
    this.loadAll();
    if (this.initialRoute === '/vm/form') {
      this.actionName = 'instance';
      this.actionRecord = new Map<string, Object | null>();
      this.push('vm-form');
    } else if (this.initialRoute === '/vm/detail') {
      this.openDetail(this.routeArguments.get('name') as string);
    }
  }

  aboutToDisappear(): void {
    this.stopMonitor();
  }

  private text(key: string): string { return this.bridge.text(key); }

  private push(name: string): void {
    const path: NavPathInfo = { name: name };
    this.paths.pushPath(path);
  }

  private vmArgs(name: string): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('name', name);
    return args;
  }

  private async loadAll(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      this.environment = await this.bridge.invoke<Map<string, Object | null>>('getVmEnvironment');
      if (this.environment.get('ready') !== true) return;
      const values = await Promise.all([
        this.bridge.invoke<Map<string, Object | null>>('getVms', this.searchArguments()),
        this.bridge.invoke<Map<string, Object | null>[]>('getVmNetworks'),
        this.bridge.invoke<Map<string, Object | null>[]>('getVmStorages'),
        this.bridge.invoke<Map<string, Object | null>[]>('getVmIsos'),
        this.bridge.invoke<Map<string, Object | null>[]>('getVmTemplates'),
      ]);
      this.vms = (values[0] as Map<string, Object | null>).get('items') as Map<string, Object | null>[];
      this.networks = values[1] as Map<string, Object | null>[];
      this.storages = values[2] as Map<string, Object | null>[];
      this.isos = values[3] as Map<string, Object | null>[];
      this.templates = values[4] as Map<string, Object | null>[];
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private searchArguments(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('info', this.searchText);
    return args;
  }

  private async search(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getVms', this.searchArguments());
      this.vms = result.get('items') as Map<string, Object | null>[];
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async openDetail(name: string): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      this.selectedVm = await this.bridge.invoke<Map<string, Object | null>>('getVmInfo', this.vmArgs(name));
      this.push('vm-detail');
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async runVmOperation(operation: string): Promise<void> {
    const args = this.vmArgs(this.value(this.selectedVm, 'name'));
    args.set('operate', operation);
    await this.mutate('operateVm', args, true);
  }

  private async mutate(method: string, args: Map<string, Object | null>, refresh: boolean): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      await computeWrite(method, args);
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonOperationSuccess') });
      if (refresh) await this.loadAll();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private confirmVmOperation(operation: string): void {
    this.getUIContext().showAlertDialog({
      title: this.operationLabel(operation),
      message: this.value(this.selectedVm, 'name'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.operationLabel(operation), action: (): void => { this.runVmOperation(operation); } },
    });
  }

  private operationLabel(operation: string): string {
    if (operation === 'start') return this.text('vmInstanceActionStart');
    if (operation === 'shutdown') return this.text('vmInstanceActionShutdown');
    if (operation === 'reboot') return this.text('vmInstanceActionReboot');
    if (operation === 'suspend') return this.text('vmInstanceActionSuspend');
    if (operation === 'resume') return this.text('vmInstanceActionResume');
    if (operation === 'destroy') return this.text('vmInstanceActionDestroy');
    return operation;
  }

  private value(record: Map<string, Object | null>, key: string): string {
    const value = record.get(key);
    return value === null || value === undefined ? '' : `${value}`;
  }

  private openForm(kind: string, record: Map<string, Object | null> = new Map<string, Object | null>()): void {
    this.actionName = kind;
    this.actionRecord = record;
    this.push('vm-form');
  }

  private async openSnapshots(open: boolean = true): Promise<void> {
    this.loading = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getVmSnapshots', this.vmArgs(this.value(this.selectedVm, 'name')));
      this.snapshots = result.get('items') as Map<string, Object | null>[];
      if (open) this.push('vm-snapshots');
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private async createSnapshot(): Promise<void> {
    this.creatingSnapshot = true;
    const args = this.vmArgs(this.value(this.selectedVm, 'name'));
    args.set('snapshotName', this.snapshotName);
    args.set('description', this.snapshotDescription);
    await this.mutate('createVmSnapshot', args, false);
    this.creatingSnapshot = false;
    if (this.errorMessage.length === 0) {
      this.snapshotName = '';
      this.snapshotDescription = '';
      await this.openSnapshots(false);
    }
  }

  private snapshotAction(method: string, name: string): void {
    this.getUIContext().showAlertDialog({
      title: this.text(method === 'recoverVmSnapshot' ? 'vmInstanceSnapshotRecoverAction' : 'vmInstanceSnapshotDeleteAction'),
      message: name,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.applySnapshotAction(method, name); } },
    });
  }

  private async applySnapshotAction(method: string, name: string): Promise<void> {
    const args = this.vmArgs(this.value(this.selectedVm, 'name'));
    args.set('snapshotName', name);
    await this.mutate(method, args, false);
    if (this.errorMessage.length === 0) await this.openSnapshots(false);
  }

  private async inspect(kind: string): Promise<void> {
    if (kind === 'stats') {
      this.stats = [];
      this.monitorMessage = '';
      this.push('vm-stats');
      return;
    }
    this.resultText = '';
    this.healthItems = [];
    try {
      const method = kind === 'health' ? 'getVmHealth' : 'getNativeVmConsole';
      const result = await this.bridge.invoke<Object | null>(method, this.vmArgs(this.value(this.selectedVm, 'name')));
      if (kind === 'health') {
        const health = result as Map<string, Object | null>;
        this.healthItems = health.get('items') as Map<string, Object | null>[];
        this.resultText = this.text((health.get('warn') === 0 && health.get('fail') === 0)
          ? 'vmHealthCheckAllPassed' : 'vmHealthCheckNeedAttention');
      } else {
        this.resultText = result as string;
      }
      this.actionName = kind;
      this.push(`vm-${kind}`);
    } catch (error) { this.errorMessage = (error as Error).message; }
  }

  private startMonitor(): void {
    this.stopMonitor();
    this.monitorVisible = true;
    this.sampleStats();
    this.monitorTimer = setInterval((): void => { this.sampleStats(); }, 5000);
  }

  private stopMonitor(): void {
    this.monitorVisible = false;
    if (this.monitorTimer !== -1) {
      clearInterval(this.monitorTimer);
      this.monitorTimer = -1;
    }
  }

  private async sampleStats(): Promise<void> {
    if (!this.monitorVisible || this.monitorLoading) return;
    this.monitorLoading = true;
    try {
      const sample = await this.bridge.invoke<Map<string, Object | null>>('getVmStats',
        this.vmArgs(this.value(this.selectedVm, 'name')));
      if (!this.monitorVisible) return;
      if (sample.get('isRunning') !== true) {
        this.monitorMessage = this.text('vmMonitorStopped');
        this.stopMonitor();
        return;
      }
      this.stats = [...this.stats.slice(-49), sample];
    } catch (error) {
      if (this.monitorVisible) {
        this.monitorMessage = (error as Error).message;
        this.stopMonitor();
      }
    } finally {
      this.monitorLoading = false;
    }
  }

  private monitorPoints(key: string, max: number): Array<[number, number]> {
    const values = this.stats.map((item: Map<string, Object | null>): number => item.get(key) as number);
    const ceiling = values.reduce((largest: number, sample: number): number => Math.max(largest, sample), max);
    return values.map((sample: number, index: number): [number, number] =>
      [index * Math.max(this.chartWidth - 4, 0) / (values.length - 1) + 2, 50 - (sample / ceiling) * 46]);
  }

  private currentSample(key: string, unit: string): string {
    const sample = this.stats[this.stats.length - 1].get(key) as number;
    return `${sample.toFixed(1)}${unit}`;
  }

  private async openConsole(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: this.resultText,
        entities: ['entity.system.browsable'] });
    } catch (_) {
      await this.copyConsole();
    }
  }

  private async copyConsole(): Promise<void> {
    try {
      await pasteboard.getSystemPasteboard().setData(
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.resultText),
      );
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonCopied') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    }
  }

  private async loadOrphans(open: boolean = true): Promise<void> {
    this.loading = true;
    try {
      this.orphanItems = await this.bridge.invoke<Map<string, Object | null>[]>('getNativeVmOrphans');
      this.selectedOrphans = [];
      if (open) this.push('vm-orphans');
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private async cleanOrphans(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('items', this.selectedOrphans);
    await this.mutate('cleanNativeVmOrphans', args, false);
    if (this.errorMessage.length === 0) await this.loadOrphans(false);
  }

  private rootMenus(): NavigationMenuItem[] {
    return [
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.loadAll(); } },
      { value: this.text('vmInstanceSyncAction'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_2_circlepath')),
        isEnabled: this.environment.get('ready') === true,
        action: (): void => { this.mutate('syncVms', new Map<string, Object | null>(), true); } },
      { value: this.text('commonCreate'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        isEnabled: this.environment.get('ready') === true && this.selectedTab < 5,
        action: (): void => { this.openForm(this.selectedTab < 2 ? 'instance' : ['network', 'storage', 'iso'][this.selectedTab - 2]); } },
      { value: this.text('vmOrphanDialogTitle'), isEnabled: this.environment.get('ready') === true,
        action: (): void => { this.loadOrphans(); } },
    ];
  }

  private vmMenus(): NavigationMenuItem[] {
    const menus: NavigationMenuItem[] = [];
    if (this.vmCan('canHealthCheck')) menus.push({ value: this.text('vmInstanceActionHealthCheck'), action: (): void => { this.inspect('health'); } });
    if (this.vmCan('canMonitor')) menus.push({ value: this.text('vmInstanceActionMonitor'), action: (): void => { this.inspect('stats'); } });
    if (this.vmCan('canOpenConsole')) menus.push({ value: this.text('vmInstanceActionConsole'), action: (): void => { this.inspect('console'); } });
    if (this.vmCan('canCreateSnapshot')) menus.push({ value: this.text('vmInstanceSnapshotTitle'), action: (): void => { this.openSnapshots(); } });
    const operations: string[] = ['start', 'shutdown', 'reboot', 'suspend', 'resume', 'destroy'];
    operations.forEach((operation: string): void => {
      if (this.vmCan(`can${operation.charAt(0).toUpperCase()}${operation.slice(1)}`)) {
        menus.push({ value: this.operationLabel(operation), action: (): void => { this.confirmVmOperation(operation); } });
      }
    });
    if (this.value(this.selectedVm, 'statusKey') === 'shut off') {
      menus.push({ value: this.text('vmInstanceActionEdit'), action: (): void => { this.openForm('instance', this.selectedVm); } });
      menus.push({ value: this.text('vmInstanceActionTemplate'), action: (): void => { this.openInstanceAction('template'); } });
    }
    if (this.vmCan('canResizeDisk')) menus.push({ value: this.text('vmInstanceActionDisk'), action: (): void => { this.openInstanceAction('resize'); } });
    menus.push({ value: this.text('vmInstanceActionRename'), action: (): void => { this.openInstanceAction('rename'); } });
    menus.push({ value: this.text('vmInstanceActionDelete'), action: (): void => { this.openInstanceAction('delete'); } });
    return menus;
  }

  private vmCan(key: string): boolean {
    const capabilities = this.selectedVm.get('capabilities') as Map<string, Object | null> | undefined;
    return capabilities?.get(key) === true;
  }

  private openInstanceAction(kind: string): void {
    this.actionName = kind;
    this.actionText = '';
    this.actionPath = '';
    this.forceDelete = false;
    this.errorMessage = '';
    this.push('vm-action');
  }

  private async applyInstanceAction(): Promise<void> {
    const args = this.vmArgs(this.value(this.selectedVm, 'name'));
    let method = 'renameNativeVm';
    if (this.actionName === 'delete') {
      method = 'deleteNativeVm';
      args.set('id', this.selectedVm.get('id') as number);
      args.set('force', this.forceDelete);
    } else if (this.actionName === 'resize') {
      method = 'resizeNativeVmDisk';
      args.set('target', this.actionPath);
      args.set('sizeGiB', Number(this.actionText));
    } else if (this.actionName === 'template') {
      method = 'createNativeVmTemplate';
      args.set('templateName', this.actionText);
      if (this.actionPath.length > 0) args.set('storagePool', this.actionPath);
    } else {
      args.set('newName', this.actionText);
    }
    await this.mutate(method, args, false);
    if (this.errorMessage.length === 0) {
      this.paths.pop();
      if (this.actionName === 'delete' || this.actionName === 'rename') this.paths.pop();
      await this.loadAll();
    }
  }

  private resizeTargets(): Map<string, Object | null>[] {
    return (this.selectedVm.get('disks') as Map<string, Object | null>[]).filter(
      (disk: Map<string, Object | null>): boolean => this.value(disk, 'device') === 'disk' &&
        this.value(disk, 'resizeBlocked').length === 0,
    );
  }

  @Builder
  private row(title: string, subtitle: string, action: () => void) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
        if (subtitle.length > 0) Text(subtitle).fontSize(14).fontColor($r('sys.color.font_secondary'))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.font_secondary')])
    }.padding(16).constraintSize({ minHeight: 64 }).width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16).onClick(action)
  }

  @Builder
  private listContent() {
    Column({ space: 12 }) {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.tabNames, (key: string, index: number): void => {
            Button(this.text(key), { buttonStyle: this.selectedTab === index ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL })
              .height(48).onClick((): void => { this.selectedTab = index; })
          }, (key: string): string => key)
        }
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      if (this.selectedTab === 1) {
        Row({ space: 8 }) {
          TextInput({ text: this.searchText, placeholder: this.text('vmInstanceSearchHint') })
            .layoutWeight(1).height(48).onChange((content: string): void => { this.searchText = content; })
          Button(this.text('commonSearch')).height(48).onClick((): void => { this.search(); })
        }
      }
      if (this.loading) LoadingProgress().width(40).height(40)
      if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary'))
      if (this.selectedTab === 0) {
        Column({ space: 12 }) {
          this.row(this.text('vmEnvironmentSectionTitle'), `${this.value(this.environment, 'arch')} · ${this.environment.get('ready') === true ? this.text('vmEnvironmentReady') : this.text('vmEnvironmentNotReady')}`, (): void => { this.push('vm-environment'); })
          this.row(this.text('vmTabInstances'), `${this.vms.length}`, (): void => { this.selectedTab = 1; })
          this.row(this.text('vmTabNetworks'), `${this.networks.length}`, (): void => { this.selectedTab = 2; })
          this.row(this.text('vmTabStorages'), `${this.storages.length}`, (): void => { this.selectedTab = 3; })
          this.row(this.text('vmTabIso'), `${this.isos.length}`, (): void => { this.selectedTab = 4; })
          this.row(this.text('vmTabTemplates'), `${this.templates.length}`, (): void => { this.selectedTab = 5; })
          if (this.environment.get('ready') !== true) Button(this.text('vmEnvironmentEnableAction')).height(48)
            .enabled(!this.loading && this.environment.get('archSupported') === true)
            .onClick((): void => { this.confirmEnableEnvironment(); })
        }.width('100%')
      } else {
        List({ space: 10 }) {
          if (this.selectedTab === 1) {
            ForEach(this.vms, (vm: Map<string, Object | null>): void => {
              ListItem() { this.row(this.value(vm, 'name'), `${this.value(vm, 'status')} · ${this.text('vmInstanceCpuLabel')} ${this.value(vm, 'cpu')} · ${this.value(vm, 'memoryMiB')} MiB`, (): void => { this.openDetail(this.value(vm, 'name')); }) }
            }, (vm: Map<string, Object | null>): string => `${vm.get('id')}`)
          } else if (this.selectedTab === 2) {
            ForEach(this.networks, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.value(item, 'name'), `${this.value(item, 'type')} · ${this.value(item, 'status')} · ${this.text('vmNetworkVmCountLabel')} ${this.value(item, 'vmCount')}`, (): void => { this.openForm('network', item); }) }
            }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
          } else if (this.selectedTab === 3) {
            ForEach(this.storages, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.value(item, 'name'), `${this.value(item, 'path')} · ${this.value(item, 'usedPercent')}%`, (): void => { this.openForm('storage', item); }) }
            }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
          } else if (this.selectedTab === 4) {
            ForEach(this.isos, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.value(item, 'name'), `${this.value(item, 'path')} · ${this.value(item, 'status')}`, (): void => { this.openForm('iso', item); }) }
            }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
          } else {
            ForEach(this.templates, (item: Map<string, Object | null>): void => {
              ListItem() { this.row(this.value(item, 'name'), `${this.value(item, 'sourceVM')} · ${this.value(item, 'cpu')} CPU · ${this.value(item, 'memoryMiB')} MiB`, (): void => { this.showTemplate(item); }) }
            }, (item: Map<string, Object | null>): string => `${item.get('id')}`)
          }
        }.layoutWeight(1).width('100%')
      }
    }.padding(16).width('100%').height('100%')
  }

  private async showTemplate(item: Map<string, Object | null>): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('id', item.get('id') as number);
    args.set('deleteDisk', false);
    this.getUIContext().showAlertDialog({ title: this.value(item, 'name'),
      message: `${this.text('vmInstanceCpuLabel')} ${this.value(item, 'cpu')} · ${this.value(item, 'memoryMiB')} MiB · ${this.value(item, 'storagePool')}`,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonDelete'), action: (): void => { this.mutate('deleteNativeVmTemplate', args, true); } },
    });
  }

  @Builder
  private detailContent() {
    Scroll() {
      Column({ space: 8 }) {
        HarmonyComputeInfo({ labelKey: 'vmInstanceNameLabel', content: this.value(this.selectedVm, 'name') })
        HarmonyComputeInfo({ labelKey: 'vmInstanceUuidLabel', content: this.value(this.selectedVm, 'uuid') })
        HarmonyComputeInfo({ labelKey: 'commonStatus', content: this.value(this.selectedVm, 'status') })
        HarmonyComputeInfo({ labelKey: 'vmInstanceCpuLabel', content: this.value(this.selectedVm, 'cpu') })
        HarmonyComputeInfo({ labelKey: 'vmInstanceMemoryLabel', content: `${this.value(this.selectedVm, 'memoryMiB')} MiB` })
        HarmonyComputeInfo({ labelKey: 'vmInstanceDiskBusLabel', content: this.value(this.selectedVm, 'diskBus') })
        HarmonyComputeInfo({ labelKey: 'vmInstanceNetworkLabel', content: this.value(this.selectedVm, 'network') })
        HarmonyComputeInfo({ labelKey: 'vmInstanceBootOrderLabel', content: this.value(this.selectedVm, 'bootOrder') })
        HarmonyComputeInfo({ labelKey: 'vmInstanceStoragePoolLabel', content: this.value(this.selectedVm, 'storagePool') })
        ForEach(this.selectedVm.get('disks') as Map<string, Object | null>[], (disk: Map<string, Object | null>): void => {
          HarmonyComputeInfo({ labelKey: 'vmInstanceDiskTargetColumn', content: `${this.value(disk, 'target')} · ${this.value(disk, 'source')} · ${this.value(disk, 'capacity')}` })
        }, (disk: Map<string, Object | null>): string => `${disk.get('target')}`)
        ForEach(this.selectedVm.get('interfaces') as Map<string, Object | null>[], (item: Map<string, Object | null>): void => {
          HarmonyComputeInfo({ labelKey: 'vmInstanceInterfacesSectionTitle', content: `${this.value(item, 'type')} · ${this.value(item, 'source')} · ${this.value(item, 'ip')}` })
        }, (item: Map<string, Object | null>): string => `${item.get('mac')}`)
        Text(this.value(this.selectedVm, 'description')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private instanceActionForm() {
    Column({ space: 16 }) {
      if (this.actionName === 'delete') {
        Text(this.value(this.selectedVm, 'name')).fontSize(16).width('100%')
        TextInput({ text: this.actionText, placeholder: this.text('vmInstanceNameLabel') }).height(48)
          .onChange((content: string): void => { this.actionText = content; })
        Row({ space: 8 }) {
          Text(this.text('vmInstanceDeleteForceLabel')).fontSize(16).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.forceDelete })
            .accessibilityText(this.text('vmInstanceDeleteForceLabel'))
            .onChange((checked: boolean): void => { this.forceDelete = checked; })
        }.width('100%').constraintSize({ minHeight: 48 })
      } else if (this.actionName === 'resize') {
        Select(this.resizeTargets().map((disk: Map<string, Object | null>): SelectOption => ({ value: this.value(disk, 'target') })))
          .value(this.actionPath).height(48).width('100%')
          .onSelect((index: number): void => { this.actionPath = this.value(this.resizeTargets()[index], 'target'); })
        TextInput({ text: this.actionText, placeholder: this.text('vmInstanceDiskNewCapacityLabel') })
          .type(InputType.Number).height(48).onChange((content: string): void => { this.actionText = content; })
      } else {
        TextInput({ text: this.actionText, placeholder: this.text(this.actionName === 'rename'
          ? 'vmInstanceRenameNewNameLabel' : 'vmInstanceTemplateNameLabel') }).height(48)
          .onChange((content: string): void => { this.actionText = content; })
        if (this.actionName === 'template' && this.storages.length > 0) {
          Select(this.storages.map((item: Map<string, Object | null>): SelectOption => ({ value: this.value(item, 'name') })))
            .value(this.actionPath.length > 0 ? this.actionPath : this.text('vmInstanceStoragePoolLabel')).height(48).width('100%')
            .onSelect((index: number): void => { this.actionPath = this.value(this.storages[index], 'name'); })
        }
      }
      if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
      Button(this.text(this.actionName === 'delete' ? 'commonDelete' : 'commonConfirm')).height(48).width('100%')
        .enabled(!this.loading && this.actionText.trim().length > 0 &&
          (this.actionName !== 'delete' || this.actionText.trim() === this.value(this.selectedVm, 'name')) &&
          (this.actionName !== 'resize' || this.actionPath.length > 0))
        .onClick((): void => { this.applyInstanceAction(); })
    }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private snapshotContent() {
    Column({ space: 12 }) {
      TextInput({ text: this.snapshotName, placeholder: this.text('vmInstanceSnapshotNameLabel') }).height(48)
        .onChange((content: string): void => { this.snapshotName = content; })
      TextInput({ text: this.snapshotDescription, placeholder: this.text('commonDescription') }).height(48)
        .onChange((content: string): void => { this.snapshotDescription = content; })
      Button(this.text('vmInstanceSnapshotCreateAction')).width('100%').height(48)
        .enabled(this.snapshotName.trim().length > 0 && !this.creatingSnapshot)
        .onClick((): void => { this.createSnapshot(); })
      if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
      List({ space: 10 }) {
        ForEach(this.snapshots, (item: Map<string, Object | null>): void => {
          ListItem() {
            Row({ space: 8 }) {
              Column({ space: 4 }) {
                Text(this.value(item, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
                Text(`${this.value(item, 'createdAt')} · ${this.value(item, 'state')} · ${this.value(item, 'size')}`)
                  .fontSize(14).fontColor($r('sys.color.font_secondary'))
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              if (item.get('canRecover') === true) Button(this.text('vmInstanceSnapshotRecoverAction')).height(48)
                .onClick((): void => { this.snapshotAction('recoverVmSnapshot', this.value(item, 'name')); })
              Button() { SymbolGlyph($r('sys.symbol.trash')).fontSize(20) }.width(48).height(48)
                .accessibilityText(this.text('vmInstanceSnapshotDeleteAction'))
                .onClick((): void => { this.snapshotAction('deleteVmSnapshot', this.value(item, 'name')); })
            }.padding(12).width('100%').backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }
        }, (item: Map<string, Object | null>): string => this.value(item, 'name'))
      }.layoutWeight(1).width('100%')
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private resultContent() {
    Scroll() {
      Column({ space: 12 }) {
        Text(this.resultText).fontSize(16).copyOption(CopyOptions.InApp).width('100%')
        if (this.actionName === 'health') {
          ForEach(this.healthItems, (item: Map<string, Object | null>): void => {
            Column({ space: 6 }) {
              Text(`${this.value(item, 'level')} · ${this.value(item, 'check')}`).fontSize(16).fontWeight(FontWeight.Medium)
              Text(this.value(item, 'reason')).fontSize(14)
              Text(this.value(item, 'detail')).fontSize(14).fontColor($r('sys.color.font_secondary'))
              Text(this.value(item, 'fixCommand')).fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp)
            }.padding(14).width('100%').alignItems(HorizontalAlign.Start)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }, (item: Map<string, Object | null>): string => this.value(item, 'check'))
        } else if (this.actionName === 'console') {
          Button(this.text('vmInstanceConsoleOpenAction')).height(48).width('100%')
            .onClick((): void => { this.openConsole(); })
          Button(this.text('commonCopy')).height(48).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.copyConsole(); })
        }
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private monitorChart(label: string, key: string, unit: string, max: number) {
    Column({ space: 6 }) {
      HarmonyComputeInfo({ labelKey: label, content: this.currentSample(key, unit) })
      if (this.stats.length > 1) {
        Polyline().points(this.monitorPoints(key, max)).fill(Color.Transparent)
          .stroke($r('sys.color.ohos_id_color_emphasize')).strokeWidth(2).width('100%').height(54)
      }
    }.width('100%')
  }

  @Builder
  private monitorContent() {
    Scroll() {
      Column({ space: 12 }) {
        if (this.monitorMessage.length > 0) {
          Text(this.monitorMessage).fontColor($r('sys.color.font_secondary'))
        } else if (this.stats.length === 0) {
          Text(this.text('vmMonitorWaitingSamples')).fontColor($r('sys.color.font_secondary'))
        }
        if (this.stats.length > 0) {
          this.monitorChart('vmMonitorCpuChart', 'cpuPercent', '%', 100)
          this.monitorChart('vmMonitorMemoryChart', 'memoryPercent', '%', 100)
          this.monitorChart('vmMonitorDiskChart', 'diskBytesPerSecond', ' B/s', 1)
          this.monitorChart('vmMonitorNetworkChart', 'networkBytesPerSecond', ' B/s', 1)
        }
      }.width('100%').alignItems(HorizontalAlign.Start)
        .onAreaChange((previous: Area, current: Area): void => { this.chartWidth = Number(current.width); })
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private orphanContent() {
    Column({ space: 12 }) {
      if (this.errorMessage.length > 0) Text(this.errorMessage)
      List({ space: 10 }) {
        ForEach(this.orphanItems, (item: Map<string, Object | null>): void => {
          ListItem() {
            Row({ space: 8 }) {
              Checkbox({ name: this.value(item, 'path'), group: 'orphans' })
                .select(this.selectedOrphans.some((selected: Map<string, Object | null>): boolean => selected.get('path') === item.get('path')))
                .onChange((selected: boolean): void => { this.toggleOrphan(item, selected); })
              Column({ space: 4 }) {
                Text(this.value(item, 'path')).fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp)
                Text(`${this.value(item, 'type')} · ${this.value(item, 'size')}`).fontSize(14).fontColor($r('sys.color.font_secondary'))
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            }.padding(12).backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }
        }, (item: Map<string, Object | null>): string => this.value(item, 'path'))
      }.layoutWeight(1).width('100%')
      Button(this.text('vmOrphanCleanAction')).width('100%').height(48).enabled(this.selectedOrphans.length > 0)
        .onClick((): void => { this.confirmCleanOrphans(); })
    }.padding(16).width('100%').height('100%')
  }

  private toggleOrphan(item: Map<string, Object | null>, selected: boolean): void {
    if (selected) this.selectedOrphans = [...this.selectedOrphans, item];
    else this.selectedOrphans = this.selectedOrphans.filter((value: Map<string, Object | null>): boolean => value.get('path') !== item.get('path'));
  }

  private confirmCleanOrphans(): void {
    this.getUIContext().showAlertDialog({ title: this.text('vmOrphanCleanAction'),
      message: `${this.selectedOrphans.length}`,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.cleanOrphans(); } },
    });
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'vm-form') {
      HarmonyVMFormPage({ formKind: this.actionName, record: this.actionRecord, networks: this.networks,
        storages: this.storages, isos: this.isos, onSaved: (): void => { this.loadAll(); } })
    } else if (name === 'vm-detail') {
      NavDestination() { this.detailContent() }
        .title(this.value(this.selectedVm, 'name'), { barStyle: BarStyle.STANDARD })
        .menus(this.vmMenus())
    } else if (name === 'vm-action') {
      NavDestination() { this.instanceActionForm() }
        .title(this.text(this.actionName === 'delete' ? 'vmInstanceDeleteTitle' : this.actionName === 'resize'
          ? 'vmInstanceDiskResizeTitle' : this.actionName === 'template' ? 'vmInstanceTemplateDialogTitle' : 'vmInstanceRenameTitle'),
          { barStyle: BarStyle.STANDARD })
    } else if (name === 'vm-snapshots') {
      NavDestination() { this.snapshotContent() }.title(this.text('vmInstanceSnapshotTitle'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'vm-stats') {
      NavDestination() { this.monitorContent() }
        .title(this.text('vmMonitorTitle'), { barStyle: BarStyle.STANDARD })
        .onShown((): void => { this.startMonitor(); }).onHidden((): void => { this.stopMonitor(); })
    } else if (name === 'vm-health' || name === 'vm-console') {
      NavDestination() { this.resultContent() }.title(this.text(name === 'vm-health' ? 'vmInstanceActionHealthCheck' : 'vmInstanceActionConsole'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'vm-orphans') {
      NavDestination() { this.orphanContent() }.title(this.text('vmOrphanDialogTitle'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'vm-environment') {
      NavDestination() {
        Scroll() {
          Column() {
            HarmonyComputeInfo({ labelKey: 'vmEnvironmentArchLabel', content: this.value(this.environment, 'arch') })
            HarmonyComputeInfo({ labelKey: 'vmEnvironmentHelperLabel', content: this.value(this.environment, 'helperMessage') })
            HarmonyComputeInfo({ labelKey: 'vmEnvironmentKvmLabel', content: this.value(this.environment, 'kvmMessage') })
            HarmonyComputeInfo({ labelKey: 'vmEnvironmentLibvirtLabel', content: this.value(this.environment, 'libvirtMessage') })
            HarmonyComputeInfo({ labelKey: 'vmEnvironmentStorageLabel', content: this.value(this.environment, 'storageMessage') })
          }.padding(16).width('100%')
        }.width('100%').height('100%')
      }.title(this.text('vmEnvironmentSectionTitle'), { barStyle: BarStyle.STANDARD })
    }
  }

  private confirmEnableEnvironment(): void {
    this.getUIContext().showAlertDialog({
      title: this.text('vmEnvironmentEnableAction'), message: this.text('vmEnvironmentEnableConfirm'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => {
        this.mutate('enableVmEnvironment', new Map<string, Object | null>(), true);
      } },
    });
  }

  @Builder
  private rootTitle() {
    HarmonyAutomationTitle({ label: this.text('vmPageTitle'), showBack: this.showBack, onBack: this.onBack })
  }

  build() {
    Navigation(this.paths) { this.listContent() }
      .title(this.rootTitle, { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true)
      .menus(this.rootMenus())
      .navDestination(this.destination)
      .mode(NavigationMode.Stack)
      .width('100%').height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
  }
}
