import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';
import { moduleTitleOptions } from '../../HarmonyModuleTitle';
import { HarmonyRuntimeDetail } from './HarmonyRuntimeDetail';
import { HarmonyRuntimeForm } from './HarmonyRuntimeForm';
import { HarmonyRuntimePackages } from './HarmonyRuntimePackages';
import { HarmonyPhpRuntimeConfig } from './HarmonyPhpRuntimeConfig';
import { HarmonyPhpSupervisor } from './HarmonyPhpSupervisor';

interface HarmonyRuntimeDestination {
  runtimeId?: number;
  runtimeType: string;
}

@Component
export struct HarmonyRuntimesPage {
  initialRoute: string = '/runtimes';
  routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};

  @State private items: Array<Map<string, Object | null>> = [];
  @State private languageIndex: number = 0;
  @State private statusIndex: number = 0;
  @State private searchTerm: string = '';
  @State private loading: boolean = true;
  @State private loadError: boolean = false;
  @State private currentPage: number = 1;
  @State private hasNextPage: boolean = false;
  @State private detailRefresh: number = 0;
  private requestNumber: number = 0;
  private started: boolean = false;
  private syncing: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private paths: NavPathStack = new NavPathStack();
  private runtimeTypes: string[] = ['php', 'node', 'java', 'go', 'python', 'dotnet'];
  private typeLabels: string[] = ['runtimeTypePhp', 'runtimeTypeNode', 'runtimeTypeJava', 'runtimeTypeGo',
    'runtimeTypePython', 'runtimeTypeDotnet'];
  private statusFilters: string[] = ['', 'Running', 'Stopped', 'Error'];

  aboutToAppear(): void {
    this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private statusLabel(status: string): string {
    switch (status) {
      case '': return this.text('runtimeStatusAll');
      case 'Running': return this.text('runtimeStatusRunning');
      case 'Stopped': return this.text('runtimeStatusStopped');
      case 'Error': return this.text('runtimeStatusError');
      case 'Starting': return this.text('runtimeStatusStarting');
      case 'Building': return this.text('runtimeStatusBuilding');
      case 'Recreating': return this.text('runtimeStatusRecreating');
      case 'SystemRestart': return this.text('runtimeStatusSystemRestart');
      default: return status;
    }
  }

  private async load(): Promise<void> {
    const requestNumber = ++this.requestNumber;
    this.loading = true;
    this.loadError = false;
    const args = new Map<string, Object | null>();
    args.set('type', this.runtimeTypes[this.languageIndex]);
    args.set('status', this.statusFilters[this.statusIndex]);
    args.set('name', this.searchTerm);
    args.set('page', this.currentPage);
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('searchNativeRuntimes', args);
      if (requestNumber !== this.requestNumber) return;
      this.items = result.get('items') as Array<Map<string, Object | null>>;
      this.hasNextPage = result.get('hasNextPage') === true;
      if (this.currentPage > 1 && this.items.length === 0) {
        this.currentPage--;
        await this.load();
      }
    } catch (error) {
      if (requestNumber === this.requestNumber) this.loadError = true;
    } finally {
      if (requestNumber === this.requestNumber) this.loading = false;
    }
  }

  private search(): void {
    this.currentPage = 1;
    this.load();
  }

  private async sync(): Promise<void> {
    if (this.syncing) return;
    this.syncing = true;
    try {
      await this.bridge.invoke<Object | null>('syncNativeRuntimes', new Map<string, Object | null>());
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: this.text('runtimeSyncFailed') });
    } finally {
      this.syncing = false;
    }
  }

  private begin(): void {
    if (this.started) return;
    this.started = true;
    if (this.initialRoute === '/runtimes') return;
    const runtimeId = (this.routeArguments.get('runtimeId') ?? this.routeArguments.get('id')) as number | undefined;
    const initialType = this.routeArguments.get('initialType') as string | undefined;
    if (this.initialRoute === '/runtimes/form') {
      this.open('form', runtimeId, initialType);
    } else {
      this.open(this.initialRoute.substring('/runtimes/'.length), runtimeId, initialType);
    }
  }

  private open(section: string, runtimeId?: number, runtimeType?: string): void {
    const info: HarmonyRuntimeDestination = { runtimeId: runtimeId, runtimeType: runtimeType ?? 'node' };
    this.paths.pushPath({ name: section, param: info });
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: this.text('runtimeActionSync'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.sync(); } },
      { value: this.text('runtimeFormCreateTitle'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.open('form', undefined, this.runtimeTypes[this.languageIndex]); } },
    ];
  }

  private rowSummary(item: Map<string, Object | null>): string {
    const status = item.get('status')?.toString() ?? '';
    const version = item.get('version')?.toString() ?? '';
    return [version, status.length > 0 ? this.statusLabel(status) : '']
      .filter((part: string): boolean => part.length > 0).join(' · ');
  }

  private managementTitle(section: string): string {
    switch (section) {
      case 'node/modules': return this.text('operationsNodeModulesTitle');
      case 'node/scripts': return this.text('operationsNodeScriptsTitle');
      default: return this.text('operationsPhpExtensionsTitle');
    }
  }

  @Builder
  private runtimeRow(item: Map<string, Object | null>) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(item.get('name')?.toString() ?? '').fontSize(16).fontColor($r('sys.color.font_primary'))
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.rowSummary(item).length > 0) {
            Text(this.rowSummary(item)).fontSize(14).fontColor($r('sys.color.font_secondary'))
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.icon_tertiary')])
      }.width('100%').padding(16)
    }.width('100%').constraintSize({ minHeight: 56 }).buttonStyle(ButtonStyleMode.TEXTUAL)
      .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(0)
      .enabled(typeof item.get('id') === 'number')
      .onClick((): void => { this.open('detail', item.get('id') as number); })
  }

  @Builder
  private runtimeList() {
    Column({ space: 12 }) {
      Search({ value: this.searchTerm, placeholder: this.text('runtimeSearchHint') })
        .height(48).width('100%')
        .onChange((term: string): void => { this.searchTerm = term; if (term.length === 0) this.search(); })
        .onSubmit((term: string): void => { this.searchTerm = term; this.search(); })
      Row({ space: 8 }) {
        Select(this.typeLabels.map((key: string): SelectOption => ({ value: this.text(key) })))
          .height(48).selected(this.languageIndex).value(this.text(this.typeLabels[this.languageIndex]))
          .accessibilityText(this.text('runtimeFieldType'))
          .onSelect((index: number): void => { this.languageIndex = index; this.search(); })
        Select(this.statusFilters.map((status: string): SelectOption => ({ value: this.statusLabel(status) })))
          .height(48).selected(this.statusIndex).value(this.statusLabel(this.statusFilters[this.statusIndex]))
          .accessibilityText(this.text('runtimeFieldStatus'))
          .onSelect((index: number): void => { this.statusIndex = index; this.search(); })
      }.width('100%')
      if (this.loading) {
        LoadingProgress().width(40).height(40).accessibilityText(this.text('commonLoading'))
      } else if (this.loadError) {
        Text(this.text('runtimeListLoadFailed')).fontColor($r('sys.color.font_secondary'))
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else if (this.items.length === 0) {
        Text(this.text('runtimeEmptyTitle')).fontColor($r('sys.color.font_secondary')).padding(16)
      } else {
        List() {
          ForEach(this.items, (item: Map<string, Object | null>): void => {
            ListItem() { this.runtimeRow(item) }
          }, (item: Map<string, Object | null>): string => item.get('id')?.toString() ?? item.get('name')?.toString() ?? '')
        }.width('100%').layoutWeight(1).scrollBar(BarState.Auto).borderRadius(16)
          .divider({ strokeWidth: 1, color: $r('sys.color.comp_divider'), startMargin: 16, endMargin: 16 })
        if (this.currentPage > 1 || this.hasNextPage) {
          Row({ space: 12 }) {
            Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(18) }
              .width(48).height(48).enabled(this.currentPage > 1).accessibilityText(this.text('commonPreviousPage'))
              .onClick((): void => { this.currentPage--; this.load(); })
            Text(`${this.currentPage}`).fontSize(16)
            Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(18) }
              .width(48).height(48).enabled(this.hasNextPage).accessibilityText(this.text('commonNextPage'))
              .onClick((): void => { this.currentPage++; this.load(); })
          }.width('100%').justifyContent(FlexAlign.Center)
        }
      }
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private destination(section: string, parameter: Object) {
    if (section === 'form') {
      NavDestination() {
        HarmonyRuntimeForm({
          runtimeId: (parameter as HarmonyRuntimeDestination).runtimeId,
          initialType: (parameter as HarmonyRuntimeDestination).runtimeType,
          onSaved: (): void => { this.paths.pop(); this.detailRefresh++; this.load(); },
        })
      }.title(this.text((parameter as HarmonyRuntimeDestination).runtimeId === undefined ?
        'runtimeFormCreateTitle' : 'runtimeFormEditTitle'), { barStyle: BarStyle.STANDARD })
    } else if (section === 'detail') {
      NavDestination() {
        HarmonyRuntimeDetail({
          runtimeId: (parameter as HarmonyRuntimeDestination).runtimeId,
          refreshVersion: this.detailRefresh,
          onEdit: (id: number): void => { this.open('form', id); },
          onChanged: (): void => { this.load(); },
          onDeleted: (): void => { this.paths.pop(); this.load(); },
          onAdvanced: (advancedSection: string, id: number): void => { this.open(advancedSection, id); },
        })
      }.title(this.text('operationsRuntimeDetailTitle'), { barStyle: BarStyle.STANDARD })
    } else if (section === 'node/modules' || section === 'node/scripts' || section === 'php/extensions') {
      NavDestination() {
        HarmonyRuntimePackages({ runtimeId: (parameter as HarmonyRuntimeDestination).runtimeId, section: section })
      }.title(this.managementTitle(section), { barStyle: BarStyle.STANDARD })
    } else if (section === 'php/config') {
      NavDestination() {
        HarmonyPhpRuntimeConfig({ runtimeId: (parameter as HarmonyRuntimeDestination).runtimeId })
      }.title(this.text('operationsPhpConfigTitle'), { barStyle: BarStyle.STANDARD })
    } else if (section === 'php/supervisor') {
      NavDestination() {
        HarmonyPhpSupervisor({ runtimeId: (parameter as HarmonyRuntimeDestination).runtimeId })
      }.title(this.text('operationsSupervisorTitle'), { barStyle: BarStyle.STANDARD })
    }
  }

  build() {
    Navigation(this.paths) { this.runtimeList() }
      .title(this.text('operationsRuntimesTitle'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini)
      .menus(this.menus())
      .navDestination(this.destination)
      .mode(NavigationMode.Stack)
      .backgroundColor($r('sys.color.background_secondary'))
      .width('100%')
      .height('100%')
      .onAppear((): void => { this.begin(); })
  }
}
