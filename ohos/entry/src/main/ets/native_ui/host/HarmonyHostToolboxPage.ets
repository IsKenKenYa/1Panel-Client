import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyHostFailure, HarmonyHostLinkRow, HarmonyHostValueRow, hostString, hostText } from './HarmonyHostWidgets';

interface ToolboxEntry {
  route: string;
  label: string;
  method: string;
  symbol: Resource;
}

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyHostToolboxPage {
  @Prop initialRoute: string = '/toolbox';
  onBack: () => void = (): void => {};
  @State private data: Map<string, Object | null> = new Map<string, Object | null>();
  @State private rows: Array<Map<string, Object | null>> = [];
  @State private updating: boolean = false;
  @State private loading: boolean = false;
  @State private error: string = '';
  @State private hostname: string = '';
  @State private dns: string = '';
  @State private ntp: string = '';
  @State private swap: string = '';
  @State private config: string = '';
  @State private ftpUser: string = '';
  @State private ftpPassword: string = '';
  @State private ftpPath: string = '';
  @State private ftpBaseDir: string = '';
  @State private ftpId: number | null = null;
  @State private banTime: string = '';
  @State private findTime: string = '';
  @State private maxRetry: string = '';
  @State private banPort: string = '';
  @State private banEnabled: boolean = false;
  @State private diskDevice: string = '';
  @State private diskFilesystem: string = 'ext4';
  @State private diskMountPoint: string = '';
  @State private diskLabel: string = '';
  @State private diskAutoMount: boolean = true;
  @State private diskNoFail: boolean = true;
  @State private diskPartitioning: boolean = false;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly paths: NavPathStack = new NavPathStack();
  private entries: ToolboxEntry[] = [
    { route: '/toolbox/device', label: 'toolboxDeviceTitle', method: 'getNativeDevice', symbol: $r('sys.symbol.externaldrive') },
    { route: '/toolbox/disk', label: 'toolboxDiskTitle', method: 'getNativeDisks', symbol: $r('sys.symbol.externaldrive') },
    { route: '/toolbox/ftp', label: 'toolboxFtpTitle', method: 'getNativeFtp', symbol: $r('sys.symbol.folder') },
    { route: '/toolbox/fail2ban', label: 'toolboxFail2banTitle', method: 'getNativeFail2ban', symbol: $r('sys.symbol.checkmark_shield') },
    { route: '/toolbox/clam', label: 'toolboxClamTitle', method: 'getNativeClam', symbol: $r('sys.symbol.checkmark_shield') },
    { route: '/toolbox/host-tool', label: 'toolboxHostToolTitle', method: 'getNativeSupervisor', symbol: $r('sys.symbol.gearshape') },
  ];

  aboutToAppear(): void { this.load(); }

  private route(): string {
    return this.initialRoute === '/toolbox/supervisor' ? '/toolbox/host-tool' : this.initialRoute;
  }

  private async load(): Promise<void> {
    const entry = this.entries.find((item: ToolboxEntry): boolean => item.route === this.route());
    if (entry === undefined || this.loading) return;
    this.loading = true;
    this.error = '';
    try {
      this.data = await this.bridge.invoke<Map<string, Object | null>>(entry.method);
      if (entry.route === '/toolbox/device') {
        const base = this.data.get('base') as Map<string, Object | null>;
        const conf = this.data.get('conf') as Map<string, Object | null>;
        this.hostname = conf.get('hostname') as string ?? base.get('hostname') as string ?? '';
        this.dns = conf.get('dns')?.toString() ?? base.get('dns')?.toString() ?? '';
        this.ntp = conf.get('ntp') as string ?? base.get('ntp') as string ?? '';
        this.swap = conf.get('swap')?.toString() ?? '';
      } else if (entry.route === '/toolbox/disk') {
        this.rows = this.data.get('disks') as Array<Map<string, Object | null>>;
      } else if (entry.route === '/toolbox/ftp') {
        const base = this.data.get('base') as Map<string, Object | null>;
        this.ftpBaseDir = base.get('baseDir') as string ?? '';
        this.rows = this.data.get('users') as Array<Map<string, Object | null>>;
      } else if (entry.route === '/toolbox/fail2ban') {
        const base = this.data.get('base') as Map<string, Object | null>;
        this.banTime = base.get('bantime') as string ?? '';
        this.findTime = base.get('findtime') as string ?? '';
        this.maxRetry = base.get('maxretry') as string ?? '';
        this.banPort = base.get('port') as string ?? '';
        this.banEnabled = base.get('isEnable') === true;
        this.rows = this.data.get('records') as Array<Map<string, Object | null>>;
      } else if (entry.route === '/toolbox/clam') {
        this.rows = this.data.get('tasks') as Array<Map<string, Object | null>>;
      } else {
        this.config = this.data.get('config') as string;
        this.rows = this.data.get('processes') as Array<Map<string, Object | null>>;
      }
    } catch (error) {
      this.error = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private title(): string {
    const entry = this.entries.find((item: ToolboxEntry): boolean => item.route === this.route());
    return hostText(entry?.label ?? 'operationsToolboxTitle');
  }

  private async write(method: string, args?: Map<string, Object | null>): Promise<boolean> {
    if (this.updating) return false;
    this.updating = true;
    try {
      await this.bridge.invoke<boolean>(method, args);
      this.getUIContext().getPromptAction().showToast({ message: hostText('commonSaveSuccess') });
      await this.load();
      return true;
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
      return false;
    } finally {
      this.updating = false;
    }
  }

  private async confirm(method: string, args: Map<string, Object | null>, title: string, message: string): Promise<boolean> {
    const response = await this.getUIContext().getPromptAction().showDialog({
      title: title,
      message: message,
      buttons: [
        { text: hostText('commonCancel'), color: $r('sys.color.font_secondary') },
        { text: hostText('commonConfirm'), color: $r('sys.color.font_primary') },
      ],
    });
    return response.index === 1 && await this.write(method, args);
  }

  private openDisk(item: Map<string, Object | null>, partitioning: boolean): void {
    this.diskDevice = item.get('device') as string;
    const filesystem = item.get('filesystem') as string;
    this.diskFilesystem = filesystem.length > 0 ? filesystem : 'ext4';
    this.diskMountPoint = item.get('mountPoint') as string;
    this.diskLabel = '';
    this.diskAutoMount = true;
    this.diskNoFail = true;
    this.diskPartitioning = partitioning;
    this.paths.pushPath({ name: 'disk' });
  }

  private async saveDisk(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('device', this.diskDevice);
    args.set('filesystem', this.diskFilesystem.trim());
    args.set('mountPoint', this.diskMountPoint.trim());
    args.set('autoMount', this.diskAutoMount);
    if (this.diskPartitioning) {
      args.set('label', this.diskLabel.trim());
      const saved = await this.confirm('partitionNativeDisk', args,
        hostText('toolboxDiskPartitionAction'), this.diskDevice);
      if (saved) this.paths.pop();
    } else {
      args.set('noFail', this.diskNoFail);
      if (await this.write('mountNativeDisk', args)) this.paths.pop();
    }
  }

  private operateService(method: string, operation: string, label: string, key: string = 'operation'): void {
    const args = new Map<string, Object | null>();
    args.set(key, operation);
    this.confirm(method, args, hostText(label), this.title());
  }

  @Builder
  private serviceActions(method: string, key: string = 'operation') {
    Row({ space: 8 }) {
      Button(hostText('commonStart')).height(48)
        .onClick((): void => { this.operateService(method, 'start', 'commonStart', key); })
      Button(hostText('commonStop')).height(48)
        .onClick((): void => { this.operateService(method, 'stop', 'commonStop', key); })
      Button(hostText('commonRestart')).height(48)
        .onClick((): void => { this.operateService(method, 'restart', 'commonRestart', key); })
    }.width('100%')
  }

  @Builder
  private titleBar() {
    Row({ space: 8 }) {
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20)
      }
      .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
      .accessibilityText(hostText('commonBack')).onClick(this.onBack)
      Text(this.title()).fontSize(20).fontWeight(FontWeight.Medium).layoutWeight(1)
    }.width('100%')
  }

  private refreshMenu(): NavigationMenuItem[] {
    return [{
      value: hostText('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.load(); },
    }];
  }

  @Builder
  private home() {
    List() {
      ListItemGroup() {
        ForEach(this.entries, (entry: ToolboxEntry): void => {
          ListItem() {
            HarmonyHostLinkRow({ label: hostText(entry.label), symbol: entry.symbol,
              onOpen: (): void => { this.bridge.openNativePage(entry.route); } })
          }
        }, (entry: ToolboxEntry): string => entry.route)
      }
        .borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private field(label: string, value: string, change: (value: string) => void, secret: boolean = false) {
    Column({ space: 4 }) {
      Text(label).fontSize(14).fontColor($r('sys.color.font_secondary'))
      TextInput({ text: value }).type(secret ? InputType.Password : InputType.Normal)
        .height(48).width('100%').accessibilityText(label).onChange(change)
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private device() {
    this.field(hostText('toolboxDeviceHostname'), this.hostname, (value: string): void => { this.hostname = value; })
    this.field(hostText('toolboxDeviceDns'), this.dns, (value: string): void => { this.dns = value; })
    this.field(hostText('toolboxDeviceNtp'), this.ntp, (value: string): void => { this.ntp = value; })
    this.field(hostText('toolboxDeviceSwap'), this.swap, (value: string): void => { this.swap = value; })
    Row({ space: 8 }) {
      Button(hostText('toolboxDeviceCheckDns')).height(48).onClick((): void => {
        const args = new Map<string, Object | null>();
        args.set('key', 'form');
        args.set('value', this.dns);
        this.write('verifyNativeDeviceDns', args);
      })
      Button(hostText('commonSave')).height(48).onClick((): void => {
        const args = new Map<string, Object | null>();
        args.set('dns', this.dns);
        args.set('hostname', this.hostname);
        args.set('ntp', this.ntp);
        args.set('swap', this.swap);
        this.write('saveNativeDevice', args);
      })
    }.width('100%')
    HarmonyHostValueRow({ label: hostText('toolboxDeviceTimeLabel'),
      content: hostString(this.data.get('base') as Map<string, Object | null>, 'localTime') })
    HarmonyHostValueRow({ label: hostText('toolboxDeviceUsersTitle'),
      content: (this.data.get('users') as string[]).join(', ') })
  }

  @Builder
  private diskEntry(item: Map<string, Object | null>) {
    Column({ space: 8 }) {
      HarmonyHostValueRow({ label: hostString(item, 'device'), content: hostString(item, 'size') })
      HarmonyHostValueRow({ label: hostText('toolboxDiskMountPointLabel'), content: hostString(item, 'mountPoint') })
      if (item.get('isMounted') === true && item.get('isSystem') !== true) {
        Button(hostText('toolboxDiskUnmountAction')).height(48).onClick((): void => {
          const args = new Map<string, Object | null>();
          args.set('mountPoint', item.get('mountPoint') as string);
          this.confirm('unmountNativeDisk', args,
            hostText('toolboxDiskUnmountAction'), hostString(item, 'mountPoint'));
        })
      } else if (item.get('isSystem') !== true && hostString(item, 'filesystem').length > 0) {
        Button(hostText('toolboxDiskMountAction')).height(48)
          .onClick((): void => { this.openDisk(item, false); })
      }
    }.width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private disks() {
    ForEach(this.rows, (item: Map<string, Object | null>): void => {
      this.diskEntry(item)
      ForEach(item.get('partitions') as Array<Map<string, Object | null>>,
        (partition: Map<string, Object | null>): void => { this.diskEntry(partition); },
        (partition: Map<string, Object | null>): string => hostString(partition, 'device'))
    }, (item: Map<string, Object | null>): string => hostString(item, 'device'))
    ForEach(this.data.get('unpartitioned') as Array<Map<string, Object | null>>,
      (item: Map<string, Object | null>): void => {
        Column() {
          HarmonyHostValueRow({ label: hostString(item, 'device'), content: hostString(item, 'size') })
          Button(hostText('toolboxDiskPartitionAction')).height(48)
            .onClick((): void => { this.openDisk(item, true); })
        }.width('100%').backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      }, (item: Map<string, Object | null>): string => hostString(item, 'device'))
  }

  @Builder
  private ftp() {
    this.serviceActions('operateNativeFtp')
    this.field(hostText('commonUsername'), this.ftpUser, (value: string): void => { this.ftpUser = value; })
    this.field(hostText('commonPassword'), this.ftpPassword, (value: string): void => { this.ftpPassword = value; }, true)
    this.field(hostText('toolboxFtpBaseDir'), this.ftpBaseDir, (value: string): void => { this.ftpBaseDir = value; })
    this.field(hostText('commonPath'), this.ftpPath, (value: string): void => { this.ftpPath = value; })
    Row({ space: 8 }) {
      Button(hostText(this.ftpId === null ? 'commonAdd' : 'commonSave')).height(48)
        .enabled(this.ftpUser.length > 0 && (this.ftpId !== null || this.ftpPassword.length > 0))
        .onClick(async (): Promise<void> => {
          const args = new Map<string, Object | null>();
          if (this.ftpId !== null) args.set('id', this.ftpId);
          args.set('user', this.ftpUser);
          if (this.ftpPassword.length > 0) args.set('password', this.ftpPassword);
          args.set('baseDir', this.ftpBaseDir);
          args.set('path', this.ftpPath);
          if (await this.write('saveNativeFtpUser', args)) {
            this.ftpId = null;
            this.ftpUser = '';
            this.ftpPassword = '';
            this.ftpPath = '';
          }
        })
      Button(hostText('toolboxFtpSyncAction')).height(48).onClick((): void => { this.write('syncNativeFtpUsers'); })
    }.width('100%')
    ForEach(this.rows, (item: Map<string, Object | null>): void => {
      Row() {
        HarmonyHostValueRow({ label: hostString(item, 'user'), content: hostString(item, 'path') }).layoutWeight(1)
        Button(hostText('commonEdit')).height(48).onClick((): void => {
          this.ftpId = item.get('id') as number;
          this.ftpUser = item.get('user') as string;
          this.ftpBaseDir = item.get('baseDir') as string;
          this.ftpPath = item.get('path') as string;
          this.ftpPassword = '';
        })
        Button(hostText('commonDelete')).height(48).onClick((): void => {
          const args = new Map<string, Object | null>();
          args.set('ids', [item.get('id') as number]);
          this.confirm('deleteNativeFtpUsers', args, hostText('commonDelete'), hostString(item, 'user'));
        })
      }.width('100%')
    }, (item: Map<string, Object | null>): string => hostString(item, 'id'))
  }

  @Builder
  private fail2ban() {
    this.serviceActions('operateNativeFail2ban')
    this.field(hostText('toolboxFail2banBantime'), this.banTime, (value: string): void => { this.banTime = value; })
    this.field(hostText('toolboxFail2banFindtime'), this.findTime, (value: string): void => { this.findTime = value; })
    this.field(hostText('toolboxFail2banMaxretry'), this.maxRetry, (value: string): void => { this.maxRetry = value; })
    this.field(hostText('toolboxFail2banPort'), this.banPort, (value: string): void => { this.banPort = value; })
    Row() {
      Text(hostText('toolboxStatusEnabled')).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.banEnabled })
        .onChange((value: boolean): void => { this.banEnabled = value; })
    }.width('100%').constraintSize({ minHeight: 48 })
    Button(hostText('commonSave')).height(48).onClick((): void => {
      const args = new Map<string, Object | null>();
      args.set('bantime', this.banTime);
      args.set('findtime', this.findTime);
      args.set('maxretry', this.maxRetry);
      args.set('port', this.banPort);
      args.set('isEnable', this.banEnabled);
      this.write('saveNativeFail2ban', args);
    })
    ForEach(this.rows, (item: Map<string, Object | null>): void => {
      HarmonyHostValueRow({ label: hostString(item, 'ip'), content: hostString(item, 'status') })
    }, (item: Map<string, Object | null>): string => hostString(item, 'ip'))
  }

  @Builder
  private clam() {
    this.serviceActions('operateNativeClam')
    ForEach(this.rows, (item: Map<string, Object | null>): void => {
      Column() {
        HarmonyHostValueRow({ label: hostString(item, 'name'), content: hostString(item, 'status') })
        HarmonyHostValueRow({ label: hostText('toolboxClamCronExpression'), content: hostString(item, 'spec') })
        Button(hostText('commonStart')).height(48).onClick((): void => {
          const args = new Map<string, Object | null>();
          args.set('id', item.get('id') as number);
          this.write('runNativeClamTask', args);
        })
      }.width('100%').backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
    }, (item: Map<string, Object | null>): string => hostString(item, 'id'))
  }

  @Builder
  private supervisor() {
    this.serviceActions('operateNativeSupervisor', 'operate')
    HarmonyHostValueRow({ label: hostText('toolboxHostToolStatusLabel'),
      content: hostString(this.data.get('service') as Map<string, Object | null>, 'status') })
    TextArea({ text: this.config }).width('100%').height(220)
      .accessibilityText(hostText('toolboxHostToolConfigSectionTitle'))
      .onChange((value: string): void => { this.config = value; })
    Button(hostText('commonSave')).height(48).onClick((): void => {
      const args = new Map<string, Object | null>();
      args.set('content', this.config);
      this.confirm('saveNativeSupervisorConfig', args, hostText('commonSave'), hostText('toolboxHostToolConfigSectionTitle'));
    })
    ForEach(this.rows, (item: Map<string, Object | null>): void => {
      HarmonyHostValueRow({ label: hostString(item, 'name'), content: hostString(item, 'status') })
    }, (item: Map<string, Object | null>): string => hostString(item, 'name'))
  }

  @Builder
  private destination(name: string, parameter: Object) {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Text(this.diskDevice).fontSize(16)
          this.field(hostText('toolboxDiskFilesystemLabel'), this.diskFilesystem,
            (value: string): void => { this.diskFilesystem = value; })
          this.field(hostText('toolboxDiskMountPointLabel'), this.diskMountPoint,
            (value: string): void => { this.diskMountPoint = value; })
          if (this.diskPartitioning) {
            this.field(hostText('toolboxDiskLabelLabel'), this.diskLabel,
              (value: string): void => { this.diskLabel = value; })
          } else {
            Row() {
              Text(hostText('toolboxDiskNoFailLabel')).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.diskNoFail })
                .onChange((value: boolean): void => { this.diskNoFail = value; })
            }.width('100%').constraintSize({ minHeight: 48 })
          }
          Row() {
            Text(hostText('toolboxDiskAutoMountLabel')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.diskAutoMount })
              .onChange((value: boolean): void => { this.diskAutoMount = value; })
          }.width('100%').constraintSize({ minHeight: 48 })
          Button(hostText('commonSave')).height(48)
            .enabled(this.diskFilesystem.trim().length > 0 && this.diskMountPoint.trim().length > 0)
            .onClick((): void => { this.saveDisk(); })
        }.width('100%').padding(16)
      }.width('100%').height('100%')
    }
    .title(hostText(this.diskPartitioning ? 'toolboxDiskPartitionAction' : 'toolboxDiskMountAction'),
      { barStyle: BarStyle.STANDARD })
  }

  build() {
    Navigation(this.paths) {
      if (this.initialRoute === '/toolbox') {
        this.home()
      } else if (this.loading) {
        Column() { LoadingProgress().width(48).height(48) }.width('100%').padding(32)
      } else if (this.error.length > 0) {
        HarmonyHostFailure({ message: this.error, onRetry: (): void => { this.load(); } })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.route() === '/toolbox/device') this.device()
            else if (this.route() === '/toolbox/disk') this.disks()
            else if (this.route() === '/toolbox/ftp') this.ftp()
            else if (this.route() === '/toolbox/fail2ban') this.fail2ban()
            else if (this.route() === '/toolbox/clam') this.clam()
            else if (this.route() === '/toolbox/host-tool') this.supervisor()
          }.width('100%').padding(16)
        }.width('100%').height('100%')
      }
    }
    .title(this.titleBar, { barStyle: BarStyle.STANDARD })
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .menus(this.initialRoute === '/toolbox' ? [] : this.refreshMenu())
    .navDestination(this.destination)
    .mode(NavigationMode.Stack)
    .width('100%').height('100%')
  }
}
