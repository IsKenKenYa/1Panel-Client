import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyAutomationTitle, automationText, automationString, automationWrite, automationMoreSymbol, automationEditSymbol } from './HarmonyAutomationUI';

@Component
export struct HarmonyGroupsPage {
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @Prop showBack: boolean = true;
  onBack: () => void = (): void => {};
  @State private groupType: string = 'command';
  @State private scope: string = 'core';
  @State private groups: Map<string, Object | null>[] = [];
  @State private loading: boolean = false;
  @State private failure: string = '';
  @State private editingId: number = -1;
  @State private groupName: string = '';
  @State private defaultGroup: boolean = false;
  private paths: NavPathStack = new NavPathStack();
  private types: string[] = ['command', 'cronjob', 'script', 'website', 'database', 'host'];

  aboutToAppear(): void {
    this.groupType = this.routeArguments.get('type') as string ?? 'command';
    this.scope = this.routeArguments.get('scope') as string ?? 'core';
    this.load();
  }

  private arguments(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('type', this.groupType);
    args.set('scope', this.scope);
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      this.groups = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>[]>('listNativeGroups', this.arguments());
    } catch (error) {
      this.failure = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private edit(group?: Map<string, Object | null>): void {
    this.editingId = group === undefined ? -1 : group.get('id') as number;
    this.groupName = group === undefined ? '' : automationString(group, 'name');
    this.defaultGroup = group?.get('isDefault') === true;
    const path: NavPathInfo = { name: 'group-edit' };
    this.paths.pushPath(path);
  }

  private async save(): Promise<void> {
    try {
      const args = this.arguments();
      if (this.editingId >= 0) args.set('id', this.editingId);
      args.set('name', this.groupName);
      args.set('isDefault', this.defaultGroup);
      await automationWrite('saveNativeGroup', args);
      this.paths.pop();
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private remove(group: Map<string, Object | null>): void {
    this.getUIContext().showAlertDialog({
      title: automationText('operationsGroupDeleteConfirmTitle'),
      message: automationString(group, 'name'),
      primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
      secondaryButton: { value: automationText('commonDelete'), action: (): void => { this.deleteGroup(group); } },
    });
  }

  private async deleteGroup(group: Map<string, Object | null>): Promise<void> {
    try {
      const args = this.arguments();
      args.set('id', group.get('id') as number);
      await automationWrite('deleteNativeGroup', args);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private typeOptions(): SelectOption[] {
    const keys: string[] = ['operationsCommandsTitle', 'operationsCronjobsTitle', 'operationsScriptsTitle',
      'websitesPageTitle', 'serverModuleDatabases', 'operationsHostAssetsTitle'];
    return keys.map((key: string): SelectOption => ({ value: automationText(key) }));
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: automationText('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); } },
      { value: automationText('commonAdd'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.edit(); } },
    ];
  }

  @Builder
  private groupMenu(group: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: automationText('commonEdit'), symbolStartIcon: new SymbolGlyphModifier(automationEditSymbol) })
        .onClick((): void => { this.edit(group); })
      MenuItem({ content: automationText('commonDelete'), symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash')) })
        .onClick((): void => { this.remove(group); })
    }
  }

  @Builder
  private body() {
    Column({ space: 16 }) {
      Select(this.typeOptions()).selected(this.types.indexOf(this.groupType)).height(48).width('100%')
        .onSelect((index: number): void => { this.groupType = this.types[index]; this.load(); })
      Select([{ value: automationText('operationsGroupScopeCore') }, { value: automationText('operationsGroupScopeAgent') }])
        .selected(this.scope === 'core' ? 0 : 1).height(48).width('100%')
        .onSelect((index: number): void => { this.scope = index === 0 ? 'core' : 'agent'; this.load(); })
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else if (this.failure.length > 0) {
        Text(this.failure).fontSize(14)
        Button(automationText('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else {
        List({ space: 12 }) {
          if (this.groups.length === 0) {
            ListItem() { Text(automationText('groupEmptyTitle')).padding(24) }
          }
          ForEach(this.groups, (group: Map<string, Object | null>): void => {
            ListItem() {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.folder')).fontSize(24)
                Column({ space: 2 }) {
                  Text(automationString(group, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
                  if (group.get('isDefault') === true) {
                    Text(automationText('operationsGroupDefaultLabel')).fontSize(14)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  }
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Button() { SymbolGlyph(automationMoreSymbol).fontSize(24) }
                  .height(48).width(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .accessibilityText(automationText('commonMore')).bindMenu(this.groupMenu(group))
              }
              .padding({ left: 16, right: 8, top: 8, bottom: 8 }).constraintSize({ minHeight: 64 })
              .width('100%').borderRadius(16).backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .onClick((): void => { this.edit(group); })
            }
          }, (group: Map<string, Object | null>): string => `${group.get('id')}`)
        }.layoutWeight(1).width('100%')
      }
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'group-edit') {
      NavDestination() {
        Column({ space: 16 }) {
          TextInput({ text: this.groupName, placeholder: automationText('operationsGroupNameHint') })
            .height(48).onChange((content: string): void => { this.groupName = content; })
          Row({ space: 12 }) {
            Text(automationText('operationsGroupDefaultLabel')).fontSize(16).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.defaultGroup })
              .onChange((selected: boolean): void => { this.defaultGroup = selected; })
          }.constraintSize({ minHeight: 48 })
          Button(automationText('commonSave')).width('100%').height(48)
            .onClick((): void => { this.save(); })
        }.padding(16).width('100%')
      }
      .title(automationText(this.editingId < 0 ? 'operationsGroupCreateTitle' : 'operationsGroupRenameTitle'),
        { barStyle: BarStyle.STANDARD })
    }
  }

  @Builder
  private rootTitle() {
    HarmonyAutomationTitle({ label: automationText('operationsGroupCenterTitle'), showBack: this.showBack, onBack: this.onBack })
  }

  build() {
    Navigation(this.paths) { this.body() }
      .title(this.rootTitle, { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true).menus(this.menus())
      .navDestination(this.destination).mode(NavigationMode.Stack)
      .width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
  }
}
