import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { handleActivationKey } from '../HarmonyInteractionUtils';
import { automationText, automationString, automationWrite, automationMoreSymbol, automationEditSymbol, automationCopySymbol } from './HarmonyAutomationUI';

@Component
export struct HarmonyCommandsPage {
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @Prop showBack: boolean = true;
  onBack: () => void = (): void => {};
  @State private commands: Map<string, Object | null>[] = [];
  @State private groups: Map<string, Object | null>[] = [];
  @State private selectedIds: number[] = [];
  @State private keyword: string = '';
  @State private selectedGroup: number = 0;
  @State private currentPage: number = 1;
  @State private total: number = 0;
  @State private loading: boolean = true;
  @State private failure: string = '';
  @State private editingId: number = -1;
  @State private commandName: string = '';
  @State private commandContent: string = '';
  @State private commandGroup: number = 0;
  @State private saving: boolean = false;
  @State private importItems: Map<string, Object | null>[] = [];
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const groupArgs = new Map<string, Object | null>();
      groupArgs.set('type', 'command');
      this.groups = await this.bridge.invoke<Map<string, Object | null>[]>('listNativeGroups', groupArgs);
      const args = new Map<string, Object | null>();
      args.set('page', this.currentPage);
      args.set('pageSize', 50);
      args.set('info', this.keyword);
      if (this.selectedGroup > 0) args.set('groupID', this.selectedGroup);
      const result = await this.bridge.invoke<Map<string, Object | null>>('searchNativeCommands', args);
      this.commands = result.get('items') as Map<string, Object | null>[];
      this.total = result.get('total') as number;
      this.selectedIds = [];
    } catch (error) {
      this.failure = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private groupOptions(): SelectOption[] {
    const result: SelectOption[] = [{ value: automationText('commandsFilterAllGroups') }];
    this.groups.forEach((group: Map<string, Object | null>): void => {
      result.push({ value: automationString(group, 'name') });
    });
    return result;
  }

  private groupIndex(id: number): number {
    return this.groups.findIndex((group: Map<string, Object | null>): boolean => group.get('id') === id) + 1;
  }

  private groupId(index: number): number {
    return index === 0 ? 0 : this.groups[index - 1].get('id') as number;
  }

  private edit(record?: Map<string, Object | null>): void {
    this.editingId = record === undefined ? -1 : record.get('id') as number;
    this.commandName = record === undefined ? '' : automationString(record, 'name');
    this.commandContent = record === undefined ? '' : automationString(record, 'command');
    this.commandGroup = record === undefined ? 0 : record.get('groupID') as number;
    const path: NavPathInfo = { name: 'command-form' };
    this.paths.pushPath(path);
  }

  private async save(): Promise<void> {
    this.saving = true;
    try {
      const args = new Map<string, Object | null>();
      if (this.editingId >= 0) args.set('id', this.editingId);
      args.set('name', this.commandName);
      args.set('command', this.commandContent);
      args.set('type', 'command');
      if (this.commandGroup > 0) args.set('groupID', this.commandGroup);
      await automationWrite('saveNativeCommand', args);
      this.paths.pop();
      await this.load();
    } catch (error) {
      this.toast((error as Error).message);
    } finally {
      this.saving = false;
    }
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message.slice(0, 120) });
  }

  private async copy(record: Map<string, Object | null>): Promise<void> {
    await pasteboard.getSystemPasteboard().setData(
      pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, automationString(record, 'command')),
    );
    this.toast(automationText('commonCopied'));
  }

  private select(id: number, selected: boolean): void {
    if (selected) {
      this.selectedIds = this.selectedIds.concat([id]);
    } else {
      this.selectedIds = this.selectedIds.filter((entry: number): boolean => entry !== id);
    }
  }

  private confirmDelete(ids: number[]): void {
    this.getUIContext().showAlertDialog({
      title: automationText('commonDelete'),
      message: automationText('commandsDeleteSelectedConfirm'),
      primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: automationText('commonDelete'),
        action: (): void => { this.remove(ids); },
      },
    });
  }

  private async remove(ids: number[]): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('ids', ids);
      await automationWrite('deleteNativeCommands', args);
      await this.load();
    } catch (error) {
      this.toast((error as Error).message);
    }
  }

  private async previewImport(): Promise<void> {
    try {
      const items = await this.bridge.invoke<Map<string, Object | null>[] | null>('previewNativeCommandsImport');
      if (items === null) return;
      this.importItems = items;
      const path: NavPathInfo = { name: 'command-import' };
      this.paths.pushPath(path);
    } catch (error) {
      this.toast((error as Error).message);
    }
  }

  private async importCommands(): Promise<void> {
    this.saving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('items', this.importItems);
      await automationWrite('importNativeCommands', args);
      this.paths.pop();
      await this.load();
    } catch (error) {
      this.toast((error as Error).message);
    } finally {
      this.saving = false;
    }
  }

  private async exportCommands(): Promise<void> {
    try {
      await automationWrite('exportNativeCommands');
    } catch (error) {
      this.toast((error as Error).message);
    }
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: automationText('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); } },
      { value: automationText('commonAdd'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.edit(); } },
      { value: automationText('commonImport'), action: (): void => { this.previewImport(); } },
      { value: automationText('commonExport'), action: (): void => { this.exportCommands(); } },
    ];
  }

  @Builder
  private commandMenu(record: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: automationText('commonCopy'), symbolStartIcon: new SymbolGlyphModifier(automationCopySymbol) })
        .onClick((): void => { this.copy(record); })
      MenuItem({ content: automationText('commonEdit'), symbolStartIcon: new SymbolGlyphModifier(automationEditSymbol) })
        .onClick((): void => { this.edit(record); })
      MenuItem({ content: automationText('commonDelete'), symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash')) })
        .onClick((): void => { this.confirmDelete([record.get('id') as number]); })
    }
  }

  @Builder
  private commandRow(record: Map<string, Object | null>) {
    Row({ space: 12 }) {
      Checkbox()
        .select(this.selectedIds.includes(record.get('id') as number))
        .width(24).height(24)
        .padding(12)
        .accessibilityText(automationString(record, 'name'))
        .onChange((selected: boolean): void => { this.select(record.get('id') as number, selected); })
      Column({ space: 2 }) {
        Text(automationString(record, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
        Text(automationString(record, 'command')).fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        if (automationString(record, 'groupBelong').length > 0) {
          Text(automationString(record, 'groupBelong')).fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)
      .onClick((): void => { this.edit(record); })
      Button() { SymbolGlyph(automationMoreSymbol).fontSize(24) }
        .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .accessibilityText(automationText('commonMore'))
        .bindMenu(this.commandMenu(record), { systemMaterial: menuMaterial })
    }
    .constraintSize({ minHeight: 72 }).padding({ top: 8, bottom: 8, right: 8 })
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .borderRadius(16)
    .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
      event,
      (): void => { this.edit(record); },
    ))
    .focusable(true)
    .focusOnTouch(true)
    .focusBox({ margin: LengthMetrics.vp(2) })
    .hoverEffect(HoverEffect.Highlight)
  }

  @Builder
  private listBody() {
    Column({ space: 12 }) {
      Search({ value: this.keyword, placeholder: automationText('commandsSearchHint') })
        .onChange((content: string): void => { this.keyword = content; })
        .onSubmit((): void => { this.currentPage = 1; this.load(); })
      Select(this.groupOptions()).selected(this.groupIndex(this.selectedGroup))
        .width('100%').height(48)
        .onSelect((index: number): void => {
          this.selectedGroup = this.groupId(index); this.currentPage = 1; this.load();
        })
      if (this.selectedIds.length > 0) {
        Row({ space: 12 }) {
          Button(automationText('commandsSelectAll')).height(48)
            .onClick((): void => { this.selectedIds = this.commands.map((entry: Map<string, Object | null>): number => entry.get('id') as number); })
          Button(automationText('commonDelete'), { role: ButtonRole.ERROR }).height(48)
            .onClick((): void => { this.confirmDelete(this.selectedIds); })
        }
      }
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else if (this.failure.length > 0) {
        Text(this.failure).fontSize(14)
        Button(automationText('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else {
        List({ space: 12 }) {
          if (this.commands.length === 0) {
            ListItem() { Text(automationText('commandsEmptyTitle')).padding(24) }
          }
          ForEach(this.commands, (record: Map<string, Object | null>): void => {
            ListItem() { this.commandRow(record) }
          }, (record: Map<string, Object | null>): string => `${record.get('id')}`)
        }
        .layoutWeight(1).width('100%')
        Row({ space: 16 }) {
          Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
            .width(48).height(48).enabled(this.currentPage > 1)
            .accessibilityText(automationText('commonPreviousPage'))
            .onClick((): void => { this.currentPage--; this.load(); })
          Text(`${this.currentPage}`).fontSize(14)
          Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }
            .width(48).height(48).enabled(this.currentPage * 50 < this.total)
            .accessibilityText(automationText('commonNextPage'))
            .onClick((): void => { this.currentPage++; this.load(); })
        }
      }
    }
    .padding(16).width('100%').height('100%')
  }

  @Builder
  private destinations(name: string, parameter: Object) {
    if (name === 'command-form') {
      NavDestination() {
        Scroll() {
          Column({ space: 16 }) {
            TextInput({ text: this.commandName, placeholder: automationText('commonName') })
              .height(48).onChange((content: string): void => { this.commandName = content; })
            Select(this.groupOptions()).selected(this.groupIndex(this.commandGroup)).height(48).width('100%')
              .onSelect((index: number): void => { this.commandGroup = this.groupId(index); })
            Text(automationText('commandsCommandFieldLabel')).width('100%').fontSize(16)
            TextArea({ text: this.commandContent }).height(240).fontFamily('monospace')
              .onChange((content: string): void => { this.commandContent = content; })
            Button(automationText('commonSave')).height(48).width('100%').enabled(!this.saving)
              .onClick((): void => { this.save(); })
          }
          .padding(16).width('100%')
        }
      }
      .title(automationText(this.editingId < 0 ? 'commandsCreateTitle' : 'commandsEditTitle'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'command-import') {
      NavDestination() {
        Column({ space: 16 }) {
          List({ space: 12 }) {
            ForEach(this.importItems, (record: Map<string, Object | null>): void => {
              ListItem() {
                Column({ space: 2 }) {
                  Text(automationString(record, 'name')).fontSize(16)
                  Text(automationString(record, 'command')).fontSize(14).fontFamily('monospace')
                }.alignItems(HorizontalAlign.Start).padding(16)
              }
            }, (record: Map<string, Object | null>): string => `${record.get('name')}:${record.get('command')}`)
          }.layoutWeight(1)
          Button(automationText('commonImport')).height(48).width('100%')
            .enabled(this.importItems.length > 0 && !this.saving)
            .onClick((): void => { this.importCommands(); })
        }.padding(16).height('100%')
      }.title(automationText('commandsPreviewLabel'))
    }
  }

  build() {
    Navigation(this.paths) { this.listBody() }
      .title(automationText('operationsCommandsTitle'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true)
      .menus(this.menus()).navDestination(this.destinations).mode(NavigationMode.Stack)
      .width('100%').height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
  }
}
