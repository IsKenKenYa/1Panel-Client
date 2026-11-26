import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { HarmonyHostFailure, HarmonyHostLinkRow, HarmonyHostValueRow, hostString, hostText } from './HarmonyHostWidgets';

interface OperationLink {
  title: string;
  route: string;
  icon: Resource;
}

@Component
export struct HarmonyHostActivityPage {
  @Prop initialRoute: string = '/operations';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @State private loading: boolean = false;
  @State private error: string = '';
  @State private logType: number = 0;
  @State private rows: Array<Map<string, Object | null>> = [];
  @State private lines: string[] = [];
  @State private hasMore: boolean = false;
  @State private detail: Map<string, Object | null> = new Map<string, Object | null>();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly paths: NavPathStack = new NavPathStack();
  private page: number = 1;
  private readonly typeKeys: string[] = ['logsCenterTabOperation', 'logsCenterTabLogin', 'logsCenterTabTask'];
  private readonly methods: string[] = ['getOperationLogs', 'getLoginLogs', 'getTaskLogs'];
  private readonly automation: OperationLink[] = [
    { title: 'operationsCronjobsTitle', route: '/cronjobs', icon: $r('sys.symbol.clock') },
    { title: 'operationsScriptsTitle', route: '/scripts', icon: $r('sys.symbol.doc_plaintext') },
    { title: 'operationsCommandsTitle', route: '/commands', icon: $r('sys.symbol.doc_plaintext') },
    { title: 'operationsBackupsTitle', route: '/backups', icon: $r('sys.symbol.cloud') },
  ];
  private readonly runtime: OperationLink[] = [
    { title: 'operationsRuntimesTitle', route: '/runtimes', icon: $r('sys.symbol.puzzle') },
  ];
  private readonly system: OperationLink[] = [
    { title: 'operationsGroupCenterTitle', route: '/operations/groups', icon: $r('sys.symbol.folder') },
    { title: 'operationsHostAssetsTitle', route: '/hosts-assets', icon: $r('sys.symbol.externaldrive') },
    { title: 'operationsSshTitle', route: '/ssh', icon: $r('sys.symbol.lock') },
    { title: 'operationsProcessesTitle', route: '/processes', icon: $r('sys.symbol.list_bullet') },
    { title: 'operationsLogsTitle', route: '/logs', icon: $r('sys.symbol.doc_text') },
    { title: 'alertPageTitle', route: '/alert', icon: $r('sys.symbol.bell_fill') },
    { title: 'operationsToolboxTitle', route: '/toolbox', icon: $r('sys.symbol.gearshape') },
  ];

  aboutToAppear(): void {
    if (this.initialRoute !== '/operations') this.load();
  }

  private title(): string {
    if (this.initialRoute === '/operations') return hostText('operationsCenterPageTitle');
    if (this.initialRoute === '/logs/task/detail') return hostText('operationsTaskLogDetailTitle');
    return hostText('operationsLogsTitle');
  }

  private async load(more: boolean = false): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    this.error = '';
    const page = more ? this.page + 1 : 1;
    try {
      const args = new Map<string, Object | null>();
      args.set('page', page);
      if (this.initialRoute === '/logs/task/detail') {
        const taskId = this.routeArguments.get('taskId') as string | undefined;
        if (taskId === undefined || taskId.length === 0) throw new Error(hostText('logsTaskMissingTaskId'));
        args.set('taskId', taskId);
        args.set('pageSize', 200);
        const result = await this.bridge.invoke<Map<string, Object | null>>('getTaskLogContent', args);
        const lines = result.get('lines') as string[];
        this.lines = more ? this.lines.concat(lines) : lines;
        this.hasMore = result.get('end') !== true && lines.length === 200;
      } else {
        args.set('pageSize', 50);
        const rows = await this.bridge.invoke<Array<Map<string, Object | null>>>(this.methods[this.logType], args);
        this.rows = more ? this.rows.concat(rows) : rows;
        this.hasMore = rows.length === 50;
      }
      this.page = page;
    } catch (error) {
      this.error = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private openLog(item: Map<string, Object | null>): void {
    if (this.logType === 2) {
      const args = new Map<string, Object | null>();
      args.set('taskId', item.get('id') as string);
      this.bridge.openNativePage('/logs/task/detail', args);
    } else {
      this.detail = item;
      this.paths.pushPath({ name: 'detail' });
    }
  }

  private logTitle(item: Map<string, Object | null>): string {
    if (this.logType === 0) return hostString(item, 'method') + ' ' + hostString(item, 'path');
    if (this.logType === 1) return hostString(item, 'ip');
    return hostString(item, 'name');
  }

  private refreshMenu(): NavigationMenuItem[] {
    return [{
      value: hostText('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.load(); },
    }];
  }

  private rootMenus(): NavigationMenuItem[] {
    return this.initialRoute === '/operations' ? [] : this.refreshMenu();
  }

  @Builder
  private group(entries: OperationLink[], title: string) {
    ListItemGroup({ header: (): void => {
      Text(hostText(title)).fontSize(14).fontColor($r('sys.color.font_secondary')).padding(12);
    } }) {
      ForEach(entries, (entry: OperationLink): void => {
        ListItem() {
          HarmonyHostLinkRow({
            label: hostText(entry.title), symbol: entry.icon,
            onOpen: (): void => { this.bridge.openNativePage(entry.route); },
          })
        }
      }, (entry: OperationLink): string => entry.route)
    }.borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private operations() {
    List({ space: 12 }) {
      this.group(this.automation, 'operationsCenterAutomationSectionTitle')
      this.group(this.runtime, 'operationsCenterRuntimeSectionTitle')
      this.group(this.system, 'operationsCenterSystemSectionTitle')
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private body() {
    Column({ space: 8 }) {
      if (this.initialRoute === '/logs') {
        Row({ space: 8 }) {
          Select(this.typeKeys.map((key: string): SelectOption => ({ value: hostText(key) })))
            .value(hostText(this.typeKeys[this.logType])).selected(this.logType).height(48)
            .layoutWeight(1).enabled(!this.loading)
            .onSelect((index: number): void => {
              this.logType = index;
              this.rows = [];
              this.load();
            })
          Button(hostText('logsCenterTabSystem')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.bridge.openNativePage('/logs/system'); })
        }.width('100%')
      }
      if (this.loading && this.rows.length === 0 && this.lines.length === 0) {
        LoadingProgress().width(48).height(48)
      } else if (this.error.length > 0) {
        HarmonyHostFailure({ message: this.error, onRetry: (): void => { this.load(); } })
      } else if (this.initialRoute === '/logs/task/detail') {
        Scroll() {
          Text(this.lines.join('\n')).fontFamily('monospace').fontSize(14)
            .copyOption(CopyOptions.InApp).width('100%')
        }.layoutWeight(1).width('100%').onScrollEdge((edge: Edge): void => {
          if (edge === Edge.Bottom && this.hasMore) this.load(true);
        })
      } else {
        List({ space: 8 }) {
          if (this.rows.length === 0) {
            ListItem() {
              Text(hostText(['logsOperationEmptyTitle', 'logsLoginEmptyTitle', 'logsTaskEmptyTitle'][this.logType]))
                .fontSize(16).padding(16)
            }
          }
          ForEach(this.rows, (item: Map<string, Object | null>): void => {
            ListItem() {
              HarmonyHostLinkRow({
                label: this.logTitle(item), detail: hostString(item, 'status'),
                symbol: $r('sys.symbol.doc_plaintext'), onOpen: (): void => { this.openLog(item); },
              })
            }
          }, (item: Map<string, Object | null>, index: number): string => hostString(item, 'id') + ':' + index)
        }.layoutWeight(1).width('100%').onReachEnd((): void => {
          if (this.hasMore) this.load(true);
        })
      }
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private destination(name: string, parameter: Object) {
    NavDestination() {
      List() {
        ForEach(Array.from(this.detail.keys()), (key: string): void => {
          ListItem() { HarmonyHostValueRow({ label: key, content: hostString(this.detail, key) }) }
        }, (key: string): string => key)
      }.width('100%').height('100%').padding(16)
    }
    .title(hostText(this.logType === 0 ? 'logsOperationDetailTitle' : 'logsLoginDetailTitle'),
      { barStyle: BarStyle.STANDARD })
  }

  build() {
    Navigation(this.paths) {
      if (this.initialRoute === '/operations') this.operations()
      else this.body()
    }
    .title(this.title(), moduleTitleOptions)
    .titleMode(NavigationTitleMode.Mini)
    .menus(this.rootMenus())
    .navDestination(this.destination)
    .mode(NavigationMode.Stack)
    .width('100%').height('100%')
  }
}
