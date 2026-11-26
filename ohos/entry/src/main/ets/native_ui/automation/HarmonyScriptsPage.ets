import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { handleActivationKey } from '../HarmonyInteractionUtils';
import { HarmonyAutomationTitle, automationText, automationString, automationWrite, automationMoreSymbol, automationScriptSymbol } from './HarmonyAutomationUI';

@Component
export struct HarmonyScriptsPage {
  @Prop showBack: boolean = true;
  onBack: () => void = (): void => {};
  @State private scripts: Map<string, Object | null>[] = [];
  @State private groups: Map<string, Object | null>[] = [];
  @State private selectedScript: Map<string, Object | null> = new Map<string, Object | null>();
  @State private keyword: string = '';
  @State private groupId: number = 0;
  @State private currentPage: number = 1;
  @State private total: number = 0;
  @State private loading: boolean = false;
  @State private failure: string = '';
  @State private output: string = '';
  @State private running: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private paths: NavPathStack = new NavPathStack();
  private eventListener: (method: string, args: Object | null) => void =
    (method: string, args: Object | null): void => {
      if (method === 'nativeScriptOutput') {
        this.output += args as string;
      } else if (method === 'nativeScriptState') {
        this.running = args as boolean;
      }
    };

  aboutToAppear(): void {
    this.bridge.addMethodListener(this.eventListener);
    this.load();
  }

  aboutToDisappear(): void {
    this.bridge.removeMethodListener(this.eventListener);
    this.stop();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('page', this.currentPage); args.set('pageSize', 50); args.set('info', this.keyword);
      if (this.groupId > 0) args.set('groupID', this.groupId);
      const result = await this.bridge.invoke<Map<string, Object | null>>('searchNativeScripts', args);
      this.scripts = result.get('items') as Map<string, Object | null>[];
      this.total = result.get('total') as number;
      const groupArgs = new Map<string, Object | null>(); groupArgs.set('type', 'script');
      this.groups = await this.bridge.invoke<Map<string, Object | null>[]>('listNativeGroups', groupArgs);
    } catch (error) {
      this.failure = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private groupOptions(): SelectOption[] {
    const options: SelectOption[] = [{ value: automationText('scriptLibraryFilterAllGroups') }];
    this.groups.forEach((group: Map<string, Object | null>): void => {
      options.push({ value: automationString(group, 'name') });
    });
    return options;
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message.slice(0, 120) });
  }

  private confirmSync(): void {
    this.getUIContext().showAlertDialog({
      title: automationText('scriptLibrarySyncAction'), message: automationText('scriptLibrarySyncConfirm'),
      primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
      secondaryButton: { value: automationText('commonConfirm'), action: (): void => { this.sync(); } },
    });
  }

  private async sync(): Promise<void> {
    try {
      await automationWrite('syncNativeScripts');
      this.toast(automationText('commonOperationSuccess'));
      await this.load();
    } catch (error) { this.toast((error as Error).message); }
  }

  private detail(script: Map<string, Object | null>): void {
    this.selectedScript = script;
    const path: NavPathInfo = { name: 'script-detail' };
    this.paths.pushPath(path);
  }

  private async run(): Promise<void> {
    this.output = '';
    try {
      const args = new Map<string, Object | null>(); args.set('id', this.selectedScript.get('id') as number);
      await automationWrite('startNativeScript', args);
      this.running = true;
      const path: NavPathInfo = { name: 'script-run' }; this.paths.pushPath(path);
    } catch (error) { this.toast((error as Error).message); }
  }

  private async stop(): Promise<void> {
    try {
      await automationWrite('stopNativeScript');
      this.running = false;
    } catch (error) { this.toast((error as Error).message); }
  }

  private remove(script: Map<string, Object | null>): void {
    this.getUIContext().showAlertDialog({
      title: automationText('commonDelete'), message: automationString(script, 'name'),
      primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
      secondaryButton: { value: automationText('commonDelete'), action: (): void => { this.deleteScript(script); } },
    });
  }

  private async deleteScript(script: Map<string, Object | null>): Promise<void> {
    try {
      const args = new Map<string, Object | null>(); args.set('ids', [script.get('id') as number]);
      await automationWrite('deleteScripts', args); await this.load();
    } catch (error) { this.toast((error as Error).message); }
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: automationText('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); } },
      { value: automationText('scriptLibrarySyncAction'), action: (): void => { this.confirmSync(); } },
    ];
  }

  @Builder
  private scriptMenu(script: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: automationText('scriptLibraryViewCodeAction'), symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.doc_text')) })
        .onClick((): void => { this.detail(script); })
      MenuItem({ content: automationText('commonDelete'), symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash')) })
        .enabled(script.get('isSystem') !== true).onClick((): void => { this.remove(script); })
    }
  }

  @Builder
  private body() {
    Column({ space: 12 }) {
      Search({ value: this.keyword, placeholder: automationText('scriptLibrarySearchHint') })
        .onChange((content: string): void => { this.keyword = content; })
        .onSubmit((): void => { this.currentPage = 1; this.load(); })
      Select(this.groupOptions()).height(48).width('100%')
        .onSelect((index: number): void => {
          this.groupId = index === 0 ? 0 : this.groups[index - 1].get('id') as number;
          this.currentPage = 1; this.load();
        })
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else if (this.failure.length > 0) {
        Text(this.failure).fontSize(14)
        Button(automationText('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else {
        List({ space: 12 }) {
          if (this.scripts.length === 0) {
            ListItem() { Text(automationText('scriptLibraryEmptyTitle')).padding(24) }
          }
          ForEach(this.scripts, (script: Map<string, Object | null>): void => {
            ListItem() {
              Row({ space: 12 }) {
                SymbolGlyph(automationScriptSymbol).fontSize(24)
                Column({ space: 2 }) {
                  Text(automationString(script, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(automationString(script, 'description')).fontSize(14).maxLines(2)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Button() { SymbolGlyph(automationMoreSymbol).fontSize(24) }
                  .height(48).width(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .accessibilityText(automationText('commonMore'))
                  .bindMenu(this.scriptMenu(script), { systemMaterial: menuMaterial })
              }.padding({ left: 16, right: 8, top: 8, bottom: 8 })
              .constraintSize({ minHeight: 72 }).width('100%').borderRadius(16)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .onClick((): void => { this.detail(script); })
              .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
                event,
                (): void => { this.detail(script); },
              ))
              .focusable(true)
              .focusOnTouch(true)
              .focusBox({ margin: LengthMetrics.vp(2) })
              .hoverEffect(HoverEffect.Highlight)
            }
          }, (script: Map<string, Object | null>): string => `${script.get('id')}`)
        }.layoutWeight(1).width('100%')
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
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'script-detail') {
      NavDestination() {
        Scroll() {
          Column({ space: 16 }) {
            Text(automationString(this.selectedScript, 'description')).fontSize(14).width('100%')
            Text(automationString(this.selectedScript, 'script')).fontSize(14).fontFamily('monospace')
              .copyOption(CopyOptions.InApp).width('100%')
            Button(automationText('scriptLibraryRunAction')).height(48).width('100%').onClick((): void => { this.run(); })
          }.padding(16).width('100%')
        }
      }.title(automationString(this.selectedScript, 'name'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'script-run') {
      NavDestination() {
        Column({ space: 12 }) {
          Scroll() { Text(this.output.length > 0 ? this.output : automationText('scriptLibraryRunWaiting'))
            .fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp).width('100%') }
            .layoutWeight(1).width('100%')
          Button(automationText('commonStop')).height(48).width('100%').enabled(this.running)
            .onClick((): void => { this.stop(); })
        }.padding(16).width('100%').height('100%')
      }.title(automationText('scriptLibraryRunTitle'), { barStyle: BarStyle.STANDARD })
        .onWillDisappear((): void => { this.stop(); })
    }
  }

  @Builder
  private rootTitle() {
    HarmonyAutomationTitle({ label: automationText('operationsScriptsTitle'), showBack: this.showBack, onBack: this.onBack })
  }

  build() {
    Navigation(this.paths) { this.body() }
      .title(this.rootTitle, { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true).menus(this.menus())
      .navDestination(this.destination).mode(NavigationMode.Stack)
      .width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
  }
}
