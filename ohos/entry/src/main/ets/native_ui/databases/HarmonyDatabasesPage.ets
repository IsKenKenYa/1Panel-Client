import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyDatabaseItem, harmonyDatabaseText } from './HarmonyDatabaseModels';
import { HarmonyDatabaseForm } from './HarmonyDatabaseForm';
import { HarmonyDatabaseDetail, HarmonyDatabaseSlowLog } from './HarmonyDatabaseDetail';
import { HarmonyDatabaseEditor } from './HarmonyDatabaseEditor';
import { HarmonyDatabaseUsers } from './HarmonyDatabaseUsers';
import { HarmonyDatabaseBackups } from './HarmonyDatabaseBackups';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyDatabasesPage {
  @Prop initialRoute: string = '/databases';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};
  @State private currentScope: string = 'mysql';
  /** 窗口宽度达到 600vp 时列表与详情同屏显示。 */
  @State private splitLayout: boolean = false;
  @State private targets: HarmonyDatabaseItem[] = [];
  @State private selectedTarget: number = -1;
  @State private entries: HarmonyDatabaseItem[] = [];
  @State private currentPage: number = 1;
  @State private totalPages: number = 0;
  @State private searchText: string = '';
  @State private sourceFilter: string = 'all';
  @State private isLoading: boolean = true;
  @State private errorMessage: string = '';
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly scopes: string[] = ['mysql', 'postgresql', 'mongodb', 'redis', 'remote'];
  private readonly paths: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    if (this.initialRoute === '/database-remote' || this.initialRoute === '/databases/remote-config') {
      this.currentScope = 'remote';
    } else if (this.initialRoute === '/databases/mongodb') {
      this.currentScope = 'mongodb';
    } else if (this.initialRoute === '/database-redis-config' || this.initialRoute === '/databases/redis/persistence') {
      this.currentScope = 'redis';
    } else if (this.initialRoute === '/databases/pg/privileges') {
      this.currentScope = 'postgresql';
    }
    const scope = this.routeArguments.get('scope') as string | null;
    if (scope !== null && scope !== undefined && this.scopes.includes(scope)) {
      this.currentScope = scope;
    }
    this.initialize();
  }

  private async initialize(): Promise<void> {
    await this.loadTargets();
    if (this.initialRoute === '/database-form') {
      this.open('form', new Map<string, Object | null>());
      return;
    }
    const itemData = this.routeArguments.get('item') as Map<string, Object | null> | undefined;
    if (itemData) {
      this.open(this.initialDestination(), itemData);
      return;
    }
    const databaseName = this.routeArguments.get('databaseName') as string | undefined;
    if (databaseName === undefined || databaseName.length === 0) return;
    if (this.initialRoute === '/databases/remote-config') {
      const database = new Map<string, Object | null>();
      database.set('name', databaseName);
      this.open('remote-form', database);
    } else if (this.initialRoute === '/databases/redis/persistence') {
      const item = this.entries.find((entry: HarmonyDatabaseItem): boolean => entry.lookupName === databaseName);
      if (item !== undefined) this.open('persistence', item.data);
    } else {
      const selected = this.targets.findIndex((target: HarmonyDatabaseItem): boolean => target.lookupName === databaseName);
      if (selected >= 0) {
        this.selectedTarget = selected;
        await this.loadPage();
        if (this.initialRoute !== '/databases/mongodb') this.open(this.initialDestination(), this.targets[selected].data);
      }
    }
  }

  private initialDestination(): string {
    if (this.initialRoute === '/database-users' || this.initialRoute === '/databases/pg/privileges') return 'users';
    if (this.initialRoute === '/database-backups') return 'backups';
    if (this.initialRoute === '/database-redis-config') return 'redis';
    if (this.initialRoute === '/databases/redis/persistence') return 'persistence';
    if (this.initialRoute === '/databases/mysql/variables') return 'variables';
    if (this.initialRoute === '/databases/slow-log') return 'slow-log';
    if (this.initialRoute === '/databases/remote-config') return 'remote-form';
    return 'detail';
  }

  private scopeOptions(): SelectOption[] {
    return this.scopes.map((scope: string): SelectOption => ({
      value: scope === 'remote' ? harmonyDatabaseText('databaseRemoteTab') : scope,
    }));
  }

  private targetOptions(): SelectOption[] {
    return this.visibleTargets().map((item: HarmonyDatabaseItem): SelectOption => ({ value: item.lookupName }));
  }

  private visibleTargets(): HarmonyDatabaseItem[] {
    return this.targets.filter((item: HarmonyDatabaseItem): boolean =>
      this.sourceFilter === 'all' || item.source === this.sourceFilter);
  }

  private async loadTargets(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.targets = [];
    this.selectedTarget = -1;
    this.currentPage = 1;
    try {
      if (this.currentScope !== 'remote' && this.currentScope !== 'redis') {
        const args = new Map<string, Object | null>();
        args.set('scope', this.currentScope);
        const records = await this.bridge.invoke<Array<Map<string, Object | null>>>('getHarmonyDatabaseTargets', args);
        this.targets = records.map((record: Map<string, Object | null>): HarmonyDatabaseItem => new HarmonyDatabaseItem(record));
        if (this.visibleTargets().length > 0) this.selectedTarget = 0;
      }
      await this.loadPage();
    } catch (error) {
      this.errorMessage = (error as Error).message;
      this.isLoading = false;
    }
  }

  private async loadPage(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('scope', this.currentScope);
      args.set('page', this.currentPage);
      args.set('pageSize', 20);
      args.set('query', this.searchText);
      const target = this.visibleTargets()[this.selectedTarget];
      if (target !== undefined) args.set('targetDatabase', target.lookupName);
      const result = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyDatabasePage', args);
      const records = result.get('items') as Array<Map<string, Object | null>>;
      this.entries = records.map((record: Map<string, Object | null>): HarmonyDatabaseItem => {
        if (target !== undefined) record.set('engine', target.engine);
        return new HarmonyDatabaseItem(record);
      });
      this.totalPages = result.get('totalPages') as number;
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private open(route: string, itemData: Map<string, Object | null>): void {
    const info: NavPathInfo = { name: route, param: itemData };
    this.paths.pushPath(info);
  }

  private finish(): void {
    this.paths.pop();
    this.loadPage();
  }

  private titleKey(name: string): string {
    if (name === 'form') return 'commonCreate';
    if (name === 'remote-form') return 'databaseRemoteTitle';
    if (name === 'users') return 'databaseUsersPageTitle';
    if (name === 'backups') return 'databaseBackupsPageTitle';
    if (name === 'config') return 'databaseConfigTitle';
    if (name === 'variables') return 'databaseMysqlVariablesTitle';
    if (name === 'slow-log') return 'databaseSlowLogTitle';
    if (name === 'redis') return 'databaseRedisConfigTitle';
    if (name === 'persistence') return 'databaseRedisPersistenceTitle';
    if (name === 'description') return 'commonDescription';
    if (name === 'access') return 'databaseRemoteAccessLabel';
    return 'databaseChangePasswordAction';
  }

  @Builder
  private rootTitle() {
    Row({ space: 8 }) {
      Button() { SymbolGlyph($r('sys.symbol.chevron_backward')).fontSize(24) }
        .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .accessibilityText(harmonyDatabaseText('commonBack'))
        .onClick((): void => { this.onBack(); })
      Text(harmonyDatabaseText('serverModuleDatabases')).fontSize(20).fontWeight(FontWeight.Medium).layoutWeight(1)
      Button() { SymbolGlyph($r('sys.symbol.plus')).fontSize(24) }
        .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .accessibilityText(harmonyDatabaseText('commonCreate'))
        .enabled(this.currentScope !== 'redis')
        .onClick((): void => { this.open('form', new Map<string, Object | null>()); })
    }
    .width('100%')
  }

  @Builder
  private listContent() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Select(this.scopeOptions()).selected(this.scopes.indexOf(this.currentScope))
          .value(this.currentScope === 'remote' ? harmonyDatabaseText('databaseRemoteTab') : this.currentScope)
          .height(48).layoutWeight(1)
          .accessibilityText(harmonyDatabaseText('databaseScopeLabel'))
          .onSelect((index: number): void => {
            this.currentScope = this.scopes[index];
            this.sourceFilter = 'all';
            this.loadTargets();
          })
        Button() { SymbolGlyph($r('sys.symbol.arrow_clockwise')).fontSize(24) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.isLoading)
          .accessibilityText(harmonyDatabaseText('commonRefresh'))
          .onClick((): void => { this.loadTargets(); })
      }
      .width('100%')
      if (this.currentScope !== 'remote' && this.currentScope !== 'redis') {
        Row({ space: 8 }) {
          Select([
            { value: harmonyDatabaseText('databaseSourceAll') },
            { value: harmonyDatabaseText('databaseSourceLocal') },
            { value: harmonyDatabaseText('databaseSourceRemote') },
          ]).height(48)
            .onSelect((index: number): void => {
              this.sourceFilter = ['all', 'local', 'remote'][index];
              this.selectedTarget = this.visibleTargets().length > 0 ? 0 : -1;
              this.currentPage = 1;
              this.loadPage();
            })
          Select(this.targetOptions()).selected(this.selectedTarget).height(48).layoutWeight(1)
            .accessibilityText(harmonyDatabaseText('databaseTargetInstance'))
            .onSelect((index: number): void => { this.selectedTarget = index; this.currentPage = 1; this.loadPage(); })
        }
        .width('100%')
      }
      if (this.currentScope !== 'redis') {
        Search({ value: this.searchText, placeholder: harmonyDatabaseText('commonSearch') })
          .height(48)
          .onChange((content: string): void => { this.searchText = content; })
          .onSubmit((content: string): void => { this.currentPage = 1; this.loadPage(); })
      }
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).width('100%').fontSize(14)
      }
      if (this.isLoading) {
        LoadingProgress().width(48).height(48)
      }
      List({ space: 12 }) {
        if (this.entries.length === 0 && !this.isLoading) {
          ListItem() { Text(harmonyDatabaseText('commonEmpty')).padding(24) }
        }
        ForEach(this.entries, (item: HarmonyDatabaseItem): void => {
          ListItem() {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text(item.name).fontSize(16).fontWeight(FontWeight.Medium).maxLines(2)
                Text(`${item.engine} · ${item.lookupName}`).fontSize(14).maxLines(1)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                if (item.text('description').length > 0) {
                  Text(item.text('description')).fontSize(14).maxLines(2)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                }
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Start)
              SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
                .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
            }
            .width('100%').constraintSize({ minHeight: 72 }).padding(16).borderRadius(16)
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .onClick((): void => { this.open('detail', item.data); })
            .accessibilityGroup(true).accessibilityText(`${item.name}, ${item.engine}`)
          }
        }, (item: HarmonyDatabaseItem): string => `${item.scope}:${item.databaseId}:${item.lookupName}:${item.name}`)
      }
      .width('100%').layoutWeight(1)
      if (this.totalPages > 1) {
        Row({ space: 16 }) {
          Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
            .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .enabled(this.currentPage > 1 && !this.isLoading)
            .accessibilityText(harmonyDatabaseText('commonPreviousPage'))
            .onClick((): void => { this.currentPage--; this.loadPage(); })
          Text(`${this.currentPage} / ${this.totalPages}`).layoutWeight(1).textAlign(TextAlign.Center)
          Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }
            .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .enabled(this.currentPage < this.totalPages && !this.isLoading)
            .accessibilityText(harmonyDatabaseText('commonNextPage'))
            .onClick((): void => { this.currentPage++; this.loadPage(); })
        }
        .width('100%')
      }
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 16 }).width('100%').height('100%')
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'detail') {
      NavDestination() {
        HarmonyDatabaseDetail({
          itemData: parameter as Map<string, Object | null>,
          onNavigate: (route: string): void => { this.open(route, parameter as Map<string, Object | null>); },
          onDeleted: (): void => { this.finish(); },
        })
      }
      .title((parameter as Map<string, Object | null>).get('name') as string,
        { barStyle: BarStyle.STANDARD })
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
    } else {
      NavDestination() {
        if (name === 'form' || name === 'remote-form') {
          HarmonyDatabaseForm({
            initialScope: this.currentScope,
            editing: parameter as Map<string, Object | null>,
            onSaved: (): void => { this.finish(); },
          })
        } else if (name === 'users') {
          HarmonyDatabaseUsers({ itemData: parameter as Map<string, Object | null> })
        } else if (name === 'backups') {
          HarmonyDatabaseBackups({ itemData: parameter as Map<string, Object | null> })
        } else if (name === 'slow-log') {
          HarmonyDatabaseSlowLog({ itemData: parameter as Map<string, Object | null> })
        } else {
          HarmonyDatabaseEditor({
            itemData: parameter as Map<string, Object | null>,
            editorMode: name,
            onSaved: (): void => { this.finish(); },
          })
        }
      }
      .title(harmonyDatabaseText(this.titleKey(name)), { barStyle: BarStyle.STANDARD })
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
    }
  }

  build() {
    Navigation(this.paths) { this.listContent() }
      .id('harmony.databases.page')
      .title(this.rootTitle, { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true)
      .navDestination(this.destination)
      .mode(this.splitLayout ? NavigationMode.Split : NavigationMode.Stack)
      .navBarWidth(240)
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .width('100%').height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
      .onAreaChange((_old: Area, current: Area): void => {
        const measured = current.width;
        if (typeof measured === 'number') {
          this.splitLayout = measured >= 600;
        }
      })
  }
}
