import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { KeyCode } from '@kit.InputKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { moduleTitleOptions, MODULE_SPLIT_MIN_CONTENT_WIDTH, MODULE_SPLIT_NAV_BAR_RANGE, MODULE_SPLIT_NAV_BAR_WIDTH } from '../HarmonyModuleTitle';
import { HarmonySplitPlaceholderContent } from '../HarmonySplitPlaceholder';
import { HarmonyContainerFormPage } from './HarmonyContainerFormPage';
import { HarmonyContainerFilesPage } from './HarmonyContainerFilesPage';
import { HarmonyContainerAssetsPage } from './HarmonyContainerAssetsPage';
import { HarmonyContainerTerminalPage } from './HarmonyContainerTerminalPage';
import { HarmonyDockerConfigPage } from './HarmonyDockerConfigPage';

export class HarmonyContainerItem {
  id: string;
  name: string;
  image: string;
  status: string;
  state: string;
  constructor(data: Map<string, Object | null>) {
    this.id = data.get('id') as string;
    this.name = data.get('name') as string;
    this.image = data.get('image') as string;
    this.status = data.get('status') as string;
    this.state = data.get('state') as string;
  }
}

@Component
export struct HarmonyContainersPage {
  @Prop initialRoute: string = '/containers';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @State private containers: HarmonyContainerItem[] = [];
  /** 窗口宽度达到 600vp 时按官方分栏规范让列表与详情同屏显示。 */
  @State private splitLayout: boolean = false;
  @State private loading: boolean = false;
  @State private hasServer: boolean = false;
  @State private errorMessage: string = '';
  @State private searchText: string = '';
  @State private stateFilter: string = 'all';
  @State private selected: HarmonyContainerItem[] = [];
  @State private processing: boolean = false;
  @State private contentLoading: boolean = false;
  @State private contentText: string = '';
  @State private contentError: string = '';
  @State private logTail: string = '200';
  @State private followLogs: boolean = true;
  @State private logStatus: string = '';
  @State private statistics: Map<string, Object | null> = new Map<string, Object | null>();
  @State private renameText: string = '';
  @State private upgradeImage: string = '';
  @State private forcePull: boolean = true;
  @State private commitImage: string = '';
  @State private commitAuthor: string = '';
  @State private commitComment: string = '';
  @State private commitPause: boolean = true;
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private splitPlaceholder: HarmonySplitPlaceholderContent =
    new HarmonySplitPlaceholderContent($r('sys.symbol.square_stack_3d'));
  private initialOpened: boolean = false;
  private logVisible: boolean = false;
  private logRequestId: number = 0;
  private logListener: (method: string, args: Object | null) => void =
    (method: string, args: Object | null): void => {
      if (!this.logVisible || args === null || this.logRequestId === 0) return;
      if (method !== 'containerLogChunk' && method !== 'containerLogError' && method !== 'containerLogDone') return;
      const event = args as Map<string, Object | null>;
      if (event.get('requestID') !== this.logRequestId) return;
      this.contentLoading = false;
      if (method === 'containerLogChunk') {
        this.contentText += event.get('chunk') as string;
        this.logStatus = this.label('containerLogsFollowing');
      } else if (method === 'containerLogError') {
        this.contentError = event.get('error') as string;
        this.logRequestId = 0;
      } else {
        this.logStatus = this.label('containerLogsStreamEnded');
        this.logRequestId = 0;
      }
    };

  aboutToAppear(): void {
    this.bridge.addMethodListener(this.logListener);
    this.load();
  }
  aboutToDisappear(): void {
    this.logVisible = false;
    this.bridge.removeMethodListener(this.logListener);
    this.stopLogStream();
  }
  private label(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    this.errorMessage = '';
    try {
      this.hasServer = await this.bridge.invoke<Map<string, Object | null> | null>('getCurrentServer') !== null;
      if (!this.hasServer) { this.containers = []; return; }
      const records = await this.bridge.invoke<Array<Map<string, Object | null>>>('getContainers');
      this.containers = records.map((record: Map<string, Object | null>): HarmonyContainerItem =>
        new HarmonyContainerItem(record));
      this.openInitialRoute();
      this.autoSelectOnSplit();
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  /** 分栏时右侧详情区需要内容，默认打开首个容器的详情，避免右侧出现空白区域。 */
  private autoSelectOnSplit(): void {
    if (!this.splitLayout || this.selected.length > 0 || this.containers.length === 0) return;
    if (this.paths.size() > 0) return;
    const first = this.visibleContainers()[0];
    if (first === undefined) return;
    this.selected = [first];
    this.renameText = first.name;
    this.upgradeImage = first.image;
    this.push('detail');
  }

  private updateSplitLayout(mode: NavigationMode): void {
    const split = mode === NavigationMode.Split;
    if (split && !this.splitLayout) {
      this.splitLayout = split;
      this.autoSelectOnSplit();
      return;
    }
    this.splitLayout = split;
  }

  private openInitialRoute(): void {
    if (this.initialOpened || this.initialRoute === '/containers') return;
    this.initialOpened = true;
    if (this.initialRoute === '/containers/docker-config') { this.push('docker'); return; }
    if (this.initialRoute === '/containers/image-operations') { this.push('images'); return; }
    if (this.initialRoute === '/container-create') { this.push('create'); return; }
    const id = this.routeArguments.get('containerId') as string ?? this.routeArguments.get('id') as string;
    const name = this.routeArguments.get('containerName') as string ?? this.routeArguments.get('name') as string;
    const entry = this.containers.find((item: HarmonyContainerItem): boolean => item.id === id || item.name === name);
    if (entry === undefined) {
      this.errorMessage = this.label('commonEmpty');
      return;
    }
    this.selected = [entry];
    this.renameText = entry.name;
    this.upgradeImage = entry.image;
    if (this.initialRoute === '/containers/inspect') this.push('inspect');
    else if (this.initialRoute === '/containers/files') this.push('files');
    else if (this.initialRoute === '/containers/maintenance') this.push('commit');
    else this.push('detail');
  }

  private visibleContainers(): HarmonyContainerItem[] {
    const query = this.searchText.toLowerCase();
    return this.containers.filter((entry: HarmonyContainerItem): boolean =>
      (this.stateFilter === 'all' || entry.state === this.stateFilter) &&
      (entry.name.toLowerCase().includes(query) || entry.image.toLowerCase().includes(query)));
  }

  private push(name: string): void {
    const path: NavPathInfo = { name: name };
    this.paths.pushPath(path);
  }

  private select(entry: HarmonyContainerItem): void {
    this.selected = [entry];
    this.renameText = entry.name;
    this.upgradeImage = entry.image;
    this.push('detail');
  }

  private argumentsFor(entry: HarmonyContainerItem): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('id', entry.id);
    args.set('name', entry.name);
    return args;
  }

  private showError(error: Error): void {
    this.getUIContext().getPromptAction().showToast({ message: error.message.slice(0, 120) });
  }

  private async write(method: string, args: Map<string, Object | null>): Promise<void> {
    this.processing = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.getUIContext().getPromptAction().showToast({ message: this.label('containerOperateSuccess') });
      this.paths.popToIndex(0);
      await this.load();
    } catch (error) { this.showError(error as Error); }
    finally { this.processing = false; }
  }

  private confirm(entry: HarmonyContainerItem, method: string, key: string): void {
    this.getUIContext().showAlertDialog({
      title: this.label(key), message: entry.name,
      primaryButton: { value: this.label('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.label('commonConfirm'),
        action: (): void => { this.write(method, this.argumentsFor(entry)); } },
    });
  }

  private rootMenus(): NavigationMenuItem[] {
    return [
      { value: this.label('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); }, isEnabled: !this.loading },
      { value: this.label('containerCreate'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.push('create'); }, isEnabled: this.hasServer },
    ];
  }

  private detailMenus(entry: HarmonyContainerItem): NavigationMenuItem[] {
    const actions: NavigationMenuItem[] = [
      { value: this.label('containerActionRestart'), action: (): void => {
        this.confirm(entry, 'restartContainer', 'containerActionRestart'); } },
      { value: this.label('containerActionRename'), action: (): void => { this.push('rename'); } },
      { value: this.label('containerActionEdit'), action: (): void => { this.push('edit'); } },
      { value: this.label('containerActionUpgrade'), action: (): void => { this.push('upgrade'); } },
      { value: this.label('containerActionCommit'), action: (): void => { this.push('commit'); } },
      { value: this.label('containerActionForceStop'), action: (): void => {
        this.confirm(entry, 'killContainer', 'containerActionForceStop'); } },
      { value: this.label('containerActionCleanLog'), action: (): void => {
        this.confirm(entry, 'cleanContainerLog', 'containerActionCleanLog'); } },
      { value: this.label('commonDelete'), action: (): void => { this.confirm(entry, 'deleteContainer', 'commonDelete'); } },
    ];
    if (entry.state === 'running') {
      actions.unshift({ value: this.label('containerActionStop'), action: (): void => {
        this.confirm(entry, 'stopContainer', 'containerActionStop'); } });
      actions.push({ value: this.label('containerActionPause'), action: (): void => {
        this.confirm(entry, 'pauseContainer', 'containerActionPause'); } });
    } else if (entry.state === 'paused') {
      actions.unshift({ value: this.label('containerActionResume'), action: (): void => {
        this.confirm(entry, 'unpauseContainer', 'containerActionResume'); } });
    } else {
      actions.unshift({ value: this.label('containerActionStart'), action: (): void => {
        this.confirm(entry, 'startContainer', 'containerActionStart'); } });
    }
    return actions;
  }

  private async loadContent(kind: string): Promise<void> {
    if (this.selected.length === 0) return;
    this.contentLoading = true;
    this.contentError = '';
    try {
      const args = this.argumentsFor(this.selected[0]);
      if (kind === 'logs') {
        if (this.followLogs) { await this.startLogStream(); return; }
        args.set('tail', this.logTail);
        this.contentText = await this.bridge.invoke<string>('getContainerLogs', args);
      } else if (kind === 'inspect') {
        this.contentText = await this.bridge.invoke<string>('getContainerInspect', args);
      } else { this.statistics = await this.bridge.invoke<Map<string, Object | null>>('getContainerStats', args); }
    } catch (error) { this.contentError = (error as Error).message; }
    finally { this.contentLoading = false; }
  }

  private async startLogStream(): Promise<void> {
    await this.stopLogStream();
    if (!this.logVisible || this.selected.length === 0) return;
    const requestId = Date.now();
    this.logRequestId = requestId;
    this.contentText = '';
    this.logStatus = this.label('containerLogsConnecting');
    const args = new Map<string, Object | null>();
    args.set('container', this.selected[0].name);
    args.set('tail', this.logTail);
    args.set('follow', true);
    args.set('requestID', requestId);
    const result = await this.bridge.invoke<Map<string, Object | null>>('startContainerLogStream', args);
    if (requestId === this.logRequestId && result.get('success') !== true) {
      throw new Error(result.get('error') as string);
    }
  }

  private async stopLogStream(): Promise<void> {
    if (this.logRequestId === 0) return;
    const args = new Map<string, Object | null>();
    args.set('requestID', this.logRequestId);
    this.logRequestId = 0;
    await this.bridge.invoke<Map<string, Object | null>>('stopContainerLogStream', args);
  }

  private setLogFollow(enabled: boolean): void {
    this.followLogs = enabled;
    if (enabled) this.loadContent('logs');
    else {
      this.stopLogStream();
      this.logStatus = this.label('containerLogsFollowPaused');
    }
  }

  private async rename(entry: HarmonyContainerItem): Promise<void> {
    const args = this.argumentsFor(entry);
    args.set('newName', this.renameText);
    await this.write('renameContainer', args);
  }

  private async upgrade(entry: HarmonyContainerItem): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('names', [entry.name]);
    args.set('image', this.upgradeImage);
    args.set('forcePull', this.forcePull);
    await this.write('upgradeContainer', args);
  }

  private async commit(entry: HarmonyContainerItem): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('containerID', entry.id);
    args.set('containerName', entry.name);
    args.set('newImageName', this.commitImage);
    args.set('author', this.commitAuthor);
    args.set('comment', this.commitComment);
    args.set('pause', this.commitPause);
    await this.write('commitContainer', args);
  }

  @Builder
  private row(title: string, subtitle: string, action: () => void) {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(title).fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary')).maxLines(2)
        if (subtitle.length > 0) {
          Text(subtitle).fontSize(14).fontColor($r('sys.color.font_secondary')).maxLines(2)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.font_secondary')])
    }
    .width('100%').constraintSize({ minHeight: 64 }).padding(16)
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
    .accessibilityText(title).onClick(action)
    .focusable(true)
    .focusBox({ margin: LengthMetrics.vp(2) })
    .hoverEffect(HoverEffect.Highlight)
    .onKeyEvent((event?: KeyEvent): boolean => {
      if (event !== undefined && event.type === KeyType.Down &&
        (event.keyCode === KeyCode.KEYCODE_ENTER || event.keyCode === KeyCode.KEYCODE_SPACE)) {
        action();
        return true;
      }
      return false;
    })
  }

  @Builder
  private rootContent() {
    Refresh({ refreshing: this.loading }) {
      List({ space: 12 }) {
        ListItem() {
          Search({ value: this.searchText, placeholder: this.label('containerSearch') })
            .height(48).onChange((content: string): void => { this.searchText = content; })
        }
        ListItem() {
          Select([
            { value: this.label('transferFilterAll') }, { value: this.label('containerStatusRunning') },
            { value: this.label('containerStatusStopped') }, { value: this.label('containerStatusPaused') },
          ]).value(this.label('containerFilter')).height(48)
            .font({ size: 14 }).fontColor($r('sys.color.font_secondary'))
            .backgroundColor(Color.Transparent)
            .onSelect((index: number): void => { this.stateFilter = ['all', 'running', 'exited', 'paused'][index]; })
        }
        if (this.errorMessage.length > 0) {
          ListItem() { Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary')) }
        }
        ForEach(['images', 'networks', 'volumes', 'repositories'], (section: string): void => {
          ListItem() { this.row(this.sectionTitle(section), '', (): void => { this.push(section); }) }
        }, (section: string): string => section)
        ListItem() { this.row(this.label('containerTabOrchestration'), '', (): void => {
          this.bridge.openNativePage('/orchestration');
        }) }
        ListItem() { this.row(this.label('containerTabTemplates'), '', (): void => {
          this.bridge.openNativePage('/compose-templates');
        }) }
        ListItem() { this.row(this.label('dockerConfigTitle'), '', (): void => { this.push('docker'); }) }
        if (!this.hasServer && !this.loading) {
          ListItem() { Text(this.label('noServerSelectedDescription')).padding(16) }
        } else if (this.visibleContainers().length === 0 && !this.loading) {
          ListItem() { Text(this.label('containerEmptyTitle')).padding(16) }
        }
        ForEach(this.visibleContainers(), (entry: HarmonyContainerItem): void => {
          ListItem() { this.row(entry.name, `${entry.image}\n${entry.status}`, (): void => { this.select(entry); }) }
        }, (entry: HarmonyContainerItem): string => entry.id)
      }
      .width('100%').height('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    }.layoutWeight(1).width('100%').height('100%').onRefreshing((): void => { this.load(); })
  }

  private sectionTitle(section: string): string {
    if (section === 'images') return this.label('containerTabImages');
    if (section === 'networks') return this.label('containerTabNetworks');
    if (section === 'volumes') return this.label('containerTabVolumes');
    return this.label('containerTabRepositories');
  }

  @Builder
  private infoRow(key: string, content: string) {
    Column({ space: 4 }) {
      Text(this.label(key)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      Text(content).fontSize(16).fontColor($r('sys.color.font_primary')).copyOption(CopyOptions.LocalDevice)
    }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
  }

  @Builder
  private detailContent(entry: HarmonyContainerItem) {
    List({ space: 12 }) {
      ListItem() {
        Column() {
          this.infoRow('containerInfoImage', entry.image)
          Divider().color($r('sys.color.ohos_id_color_list_separator'))
          this.infoRow('containerInfoStatus', entry.status)
          Divider().color($r('sys.color.ohos_id_color_list_separator'))
          this.infoRow('containerInfoId', entry.id)
        }.backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
      }
      ListItem() { this.row(this.label('containerActionLogs'), '', (): void => { this.push('logs'); }) }
      ListItem() { this.row(this.label('containerActionStats'), '', (): void => { this.push('stats'); }) }
      ListItem() { this.row(this.label('containerActionInspect'), '', (): void => { this.push('inspect'); }) }
      ListItem() { this.row(this.label('containerTabFiles'), '', (): void => { this.push('files'); }) }
      ListItem() { this.row(this.label('containerActionTerminal'), '', (): void => { this.push('terminal'); }) }
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private textContent(kind: string) {
    Column({ space: 12 }) {
      if (kind === 'logs') {
        TextInput({ text: this.logTail, placeholder: this.label('containerActionLogs') })
          .height(48).type(InputType.Number).onChange((content: string): void => { this.logTail = content; })
        Row({ space: 12 }) {
          Text(this.label('containerLogsFollow')).fontSize(16).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.followLogs })
            .onChange((enabled: boolean): void => { this.setLogFollow(enabled); })
        }.constraintSize({ minHeight: 48 }).width('100%')
        Text(this.logStatus).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      }
      if (this.contentLoading) { LoadingProgress().width(48).height(48) }
      if (this.contentError.length > 0) { Text(this.contentError).fontColor($r('sys.color.font_primary')) }
      Scroll() {
        Text(this.contentText).fontFamily('monospace').fontSize(13)
          .fontColor($r('sys.color.font_primary')).copyOption(CopyOptions.LocalDevice).width('100%')
      }.layoutWeight(1).width('100%')
    }.padding(16).width('100%').height('100%')
  }

  private statsValue(key: string): string {
    const value = this.statistics.get(key);
    return value === null || value === undefined ? '—' : `${value}`;
  }

  @Builder
  private statsContent() {
    List() {
      if (this.contentLoading) { ListItem() { LoadingProgress().width(48).height(48) } }
      if (this.contentError.length > 0) { ListItem() { Text(this.contentError).padding(16) } }
      ListItem() { this.infoRow('containerStatsCpu', this.statsValue('cpuPercent')) }
      ListItem() { this.infoRow('containerStatsMemory', this.statsValue('memory')) }
      ListItem() { this.infoRow('containerStatsNetwork', `${this.statsValue('networkRX')} / ${this.statsValue('networkTX')}`) }
      ListItem() { this.infoRow('containerStatsBlock', `${this.statsValue('ioRead')} / ${this.statsValue('ioWrite')}`) }
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private maintenanceForm(kind: string, entry: HarmonyContainerItem) {
    Scroll() {
      Column({ space: 16 }) {
        if (kind === 'rename') {
          TextInput({ text: this.renameText, placeholder: this.label('containerInfoName') })
            .height(48).onChange((content: string): void => { this.renameText = content; })
          Button(this.label('commonSave')).height(48).width('100%').enabled(!this.processing)
            .onClick((): void => { this.rename(entry); })
        } else if (kind === 'upgrade') {
          TextInput({ text: this.upgradeImage, placeholder: this.label('containerInfoImage') })
            .height(48).onChange((content: string): void => { this.upgradeImage = content; })
          Row() {
            Text(this.label('containerUpgradeForcePull')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.forcePull })
              .onChange((enabled: boolean): void => { this.forcePull = enabled; })
          }.constraintSize({ minHeight: 48 })
          Button(this.label('containerActionUpgrade')).height(48).width('100%').enabled(!this.processing)
            .onClick((): void => { this.upgrade(entry); })
        } else {
          TextInput({ text: this.commitImage, placeholder: this.label('containerCommitImage') })
            .height(48).onChange((content: string): void => { this.commitImage = content; })
          TextInput({ text: this.commitAuthor, placeholder: this.label('containerCommitAuthor') })
            .height(48).onChange((content: string): void => { this.commitAuthor = content; })
          TextArea({ text: this.commitComment, placeholder: this.label('containerCommitComment') })
            .height(120).onChange((content: string): void => { this.commitComment = content; })
          Row() {
            Text(this.label('containerCommitPause')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.commitPause })
              .onChange((enabled: boolean): void => { this.commitPause = enabled; })
          }.constraintSize({ minHeight: 48 })
          Button(this.label('containerActionCommit')).height(48).width('100%').enabled(!this.processing)
            .onClick((): void => { this.commit(entry); })
        }
      }.padding(16).width('100%')
    }.width('100%').height('100%')
  }

  private contentMenus(kind: string): NavigationMenuItem[] {
    return [{ value: this.label('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.loadContent(kind); }, isEnabled: !this.contentLoading }];
  }

  private pageTitle(name: string): string {
    if (name === 'logs') return this.label('containerActionLogs');
    if (name === 'inspect') return this.label('containerInspectJson');
    if (name === 'rename') return this.label('containerActionRename');
    if (name === 'upgrade') return this.label('containerActionUpgrade');
    return this.label('containerActionCommit');
  }

  private assetsTitle(section: string): string {
    if (section === 'images') return this.label('containerTabImages');
    if (section === 'networks') return this.label('containerTabNetworks');
    if (section === 'volumes') return this.label('containerTabVolumes');
    return this.label('containerTabRepositories');
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'create') {
      NavDestination() { HarmonyContainerFormPage({ onSaved: (): void => { this.paths.pop(); this.load(); } }) }
        .title(this.label('containerCreate'), { barStyle: BarStyle.STANDARD })
        .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
    } else if (name === 'docker') {
      NavDestination() { HarmonyDockerConfigPage() }
        .title(this.label('dockerConfigTitle'), { barStyle: BarStyle.STANDARD })
        .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
    } else if (name === 'images' || name === 'networks' || name === 'volumes' || name === 'repositories') {
      NavDestination() { HarmonyContainerAssetsPage({ initialSection: name, embedded: true }) }
        .title(this.assetsTitle(name), { barStyle: BarStyle.STANDARD })
        .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
    } else {
      ForEach(this.selected, (entry: HarmonyContainerItem): void => {
        if (name === 'detail') {
          NavDestination() { this.detailContent(entry) }
            .title(entry.name, { barStyle: BarStyle.STANDARD })
            .menus(this.detailMenus(entry))
            .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
        } else if (name === 'edit') {
          NavDestination() {
            HarmonyContainerFormPage({ containerId: entry.id, containerName: entry.name, containerImage: entry.image,
              onSaved: (): void => { this.paths.pop(); this.load(); } })
          }.title(this.label('containerActionEdit'), { barStyle: BarStyle.STANDARD })
            .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
        } else if (name === 'files') {
          NavDestination() { HarmonyContainerFilesPage({ containerId: entry.id }) }
            .title(this.label('containerTabFiles'), { barStyle: BarStyle.STANDARD })
            .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
        } else if (name === 'terminal') {
          NavDestination() { HarmonyContainerTerminalPage({ containerName: entry.name }) }
            .title(this.label('containerActionTerminal'), { barStyle: BarStyle.STANDARD })
            .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
        } else if (name === 'logs' || name === 'inspect') {
          NavDestination() { this.textContent(name) }
            .title(this.pageTitle(name), { barStyle: BarStyle.STANDARD })
            .menus(this.contentMenus(name)).onShown((): void => {
              if (name === 'logs') this.logVisible = true;
              this.loadContent(name);
            }).onHidden((): void => {
              if (name === 'logs') { this.logVisible = false; this.stopLogStream(); }
            })
            .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
        } else if (name === 'stats') {
          NavDestination() { this.statsContent() }
            .title(this.label('containerActionStats'), { barStyle: BarStyle.STANDARD })
            .menus(this.contentMenus(name)).onShown((): void => { this.loadContent(name); })
            .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
        } else if (name === 'rename' || name === 'upgrade' || name === 'commit') {
          NavDestination() { this.maintenanceForm(name, entry) }
            .title(this.pageTitle(name), { barStyle: BarStyle.STANDARD })
            .systemTransition(this.splitLayout ? NavigationSystemTransitionType.CONTENT : NavigationSystemTransitionType.DEFAULT)
        }
      }, (entry: HarmonyContainerItem): string => entry.id)
    }
  }

  build() {
    Navigation(this.paths) { this.rootContent() }
      .id('harmony-containers-page')
      .title(this.label('containerTitle'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true).menus(this.rootMenus())
      .navDestination(this.destination)
      .mode(NavigationMode.Auto)
      .navBarWidth(MODULE_SPLIT_NAV_BAR_WIDTH)
      .navBarWidthRange(MODULE_SPLIT_NAV_BAR_RANGE)
      .minContentWidth(MODULE_SPLIT_MIN_CONTENT_WIDTH)
      .splitPlaceholder(this.splitPlaceholder.content(this.getUIContext()))
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary')).width('100%').height('100%')
      .onNavigationModeChange((mode: NavigationMode): void => {
        this.updateSplitLayout(mode);
      })
  }
}
