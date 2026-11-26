import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';
import { HarmonyPanelEntry, HarmonyPanelField } from './HarmonyPanelControls';

@Component
export struct HarmonyPanelConfigurationPage {
  @Prop section: string = 'basic';
  @State private loading: boolean = true;
  @State private busy: boolean = false;
  @State private loadError: string = '';
  @State private value: string = '';
  @State private draft: string = '';
  @State private entries: string[] = [];
  @State private addedValue: string = '';
  @State private editingMenuIndex: number = -1;
  @State private editingMenuValue: string = '';
  @State private menuSheet: boolean = false;
  @State private security: Map<string, Object | null> = new Map<string, Object | null>();
  @State private securityDraft: string = '';
  @State private securityEditKey: string = '';
  @State private securityEditTitle: string = '';
  @State private securitySheet: boolean = false;
  @State private storeUrl: string = '';
  @State private proxyUrl: string = '';
  @State private proxyPort: string = '';
  @State private proxyType: string = '';
  @State private proxyUser: string = '';
  @State private proxyPasswd: string = '';
  @State private proxyPasswdKeep: boolean = false;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.load(); }

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      if (this.section === 'menu') {
        this.entries = await this.bridge.invoke<string[]>('getHarmonyPanelMenus');
      } else if (this.section === 'memo') {
        const current = await this.bridge.invoke<string | null>('getHarmonyPanelMemo');
        this.value = current ?? '';
        this.draft = this.value;
      } else if (this.section === 'store') {
        const config = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyPanelAppStore');
        this.storeUrl = this.extractStoreUrl(config);
        this.draft = this.storeUrl;
      } else if (this.section === 'proxy') {
        const settings = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyPanelProxy');
        this.proxyType = (settings.get('proxyType') as string | null) ?? '';
        this.proxyUrl = (settings.get('proxyUrl') as string | null) ?? '';
        const prefix = `${this.proxyType}://`;
        if (this.proxyUrl.startsWith(prefix)) {
          this.proxyUrl = this.proxyUrl.substring(prefix.length);
        }
        this.proxyPort = (settings.get('proxyPort') as string | null) ?? '';
        this.proxyUser = (settings.get('proxyUser') as string | null) ?? '';
        this.proxyPasswd = (settings.get('proxyPasswd') as string | null) ?? '';
        this.proxyPasswdKeep = settings.get('proxyPasswdKeep') === 'Enable';
      } else if (this.section === 'interfaces') {
        this.entries = await this.bridge.invoke<string[]>('getHarmonyPanelInterfaces');
      } else if (this.section === 'security' || this.section === 'basic') {
        const settings = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyPanelSettings');
        this.security = settings;
        this.entries = this.section === 'basic' ? [
          `${this.text('panelSettingsPanelName')}: ${this.displayValue(settings.get('panelName'))}`,
          `${this.text('panelSettingsVersion')}: ${this.displayValue(settings.get('systemVersion'))}`,
          `${this.text('panelSettingsPort')}: ${this.displayValue(settings.get('serverPort'))}`,
          `${this.text('panelSettingsBindAddress')}: ${this.displayValue(settings.get('bindAddress'))}`,
          `${this.text('panelSettingsDeveloperMode')}: ${this.status(settings.get('developerMode'))}`,
          `${this.text('panelSettingsIpv6')}: ${this.status(settings.get('ipv6'))}`,
          `${this.text('panelSettingsSessionTimeout')}: ${this.displayValue(settings.get('sessionTimeout'))}`,
        ] : [];
      } else {
        throw new Error(`Unsupported panel settings section: ${this.section}`);
      }
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private displayValue(value: Object | null | undefined): string {
    return value === undefined || value === null || value.toString().length === 0 ? '—' : value.toString();
  }

  private status(value: Object | null | undefined): string {
    const text = this.displayValue(value).toLowerCase();
    return text === 'enable' || text === 'true' ? this.text('systemSettingsEnabled') : this.text('systemSettingsDisabled');
  }

  private extractStoreUrl(config: Map<string, Object | null>): string {
    const value = config.get('storeUrl') ?? config.get('url') ?? config.get('storeURL');
    return value === null || value === undefined ? '' : value.toString();
  }

  private proxyOptions(): SelectOption[] {
    return [{ value: this.text('systemSettingsDisabled') }, { value: 'HTTP' },
      { value: 'HTTPS' }, { value: 'SOCKS5' }];
  }

  private proxyConfigured(): boolean {
    return this.proxyType.length > 0 && this.proxyType !== 'close';
  }

  private async save(): Promise<void> {
    this.busy = true;
    try {
      if (this.section === 'memo') {
        const args = new Map<string, Object | null>();
        args.set('content', this.draft);
        await this.bridge.invoke<Object | null>('updateHarmonyPanelMemo', args);
      } else if (this.section === 'store') {
        const args = new Map<string, Object | null>();
        args.set('storeUrl', this.draft);
        await this.bridge.invoke<Object | null>('updateHarmonyPanelAppStore', args);
      } else if (this.section === 'proxy') {
        const args = new Map<string, Object | null>();
        if (this.proxyConfigured()) {
          const port = Number(this.proxyPort.trim());
          if (this.proxyUrl.trim().length === 0) throw new Error(this.text('serverFormRequired'));
          if (!Number.isInteger(port) || port < 1 || port > 65535) {
            throw new Error(this.text('websitesDomainValidationPort'));
          }
          args.set('proxyType', this.proxyType);
          args.set('proxyUrl', this.proxyUrl.trim());
          args.set('proxyPort', port);
          args.set('proxyUser', this.proxyUser.trim());
          args.set('proxyPasswd', this.proxyPasswd);
          args.set('proxyPasswdKeep', this.proxyPasswdKeep ? 'Enable' : 'Disable');
        } else {
          args.set('proxyType', '');
          args.set('proxyUrl', '');
          args.set('proxyUser', '');
          args.set('proxyPasswd', '');
          args.set('proxyPasswdKeep', '');
        }
        await this.bridge.invoke<Object | null>('updateHarmonyPanelProxy', args);
      }
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private addMenu(): void {
    const menu = this.addedValue.trim();
    if (menu.length === 0 || this.entries.includes(menu)) return;
    this.entries = this.entries.concat([menu]);
    this.addedValue = '';
  }

  private moveMenu(index: number, target: number): void {
    const items = this.entries.slice();
    const moved = items.splice(index, 1)[0];
    items.splice(target, 0, moved);
    this.entries = items;
  }

  private applyMenuEdit(): void {
    const value = this.editingMenuValue.trim();
    if (value.length === 0) return;
    const entries = this.entries.slice();
    entries[this.editingMenuIndex] = value;
    this.entries = entries;
    this.menuSheet = false;
  }

  private editSecurity(responseKey: string, settingKey: string, titleKey: string): void {
    this.securityDraft = (this.security.get(responseKey) as string | null) ?? '';
    this.securityEditKey = settingKey;
    this.securityEditTitle = titleKey;
    this.securitySheet = true;
  }

  private async saveMenus(): Promise<void> {
    this.busy = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('menus', this.entries);
      await this.bridge.invoke<Object | null>('updateHarmonyPanelMenus', args);
      this.getUIContext().getPromptAction().showToast({ message: this.text('menuSettingsSaveSuccess') });
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private async changeSetting(key: string, value: string): Promise<void> {
    this.busy = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('key', key);
      args.set('value', value);
      await this.bridge.invoke<Object | null>('updateHarmonyPanelSetting', args);
      this.securitySheet = false;
      await this.load();
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  @Builder
  private editMenuSheet() {
    Column({ space: 16 }) {
      HarmonyPanelField({ titleKey: 'menuSettingsAddLabel', fieldValue: this.editingMenuValue,
        changed: (value: string): void => { this.editingMenuValue = value; } })
      Button(this.text('commonSave')).height(48).width('100%').enabled(this.editingMenuValue.trim().length > 0)
        .onClick((): void => { this.applyMenuEdit(); })
    }.width('100%').padding(24)
  }

  @Builder
  private editSecuritySheet() {
    Column({ space: 16 }) {
      HarmonyPanelField({ titleKey: this.securityEditTitle, fieldValue: this.securityDraft,
        numeric: this.securityEditKey === 'ExpirationDays',
        changed: (value: string): void => { this.securityDraft = value; } })
      Button(this.text('commonSave')).height(48).width('100%').enabled(!this.busy)
        .onClick((): void => { this.changeSetting(this.securityEditKey, this.securityDraft.trim()); })
    }.width('100%').padding(24)
  }

  @Builder
  private securityRow(responseKey: string, settingKey: string, titleKey: string) {
    ListItem() {
      Row({ space: 12 }) {
        Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
        Text(responseKey === 'securityEntrance' ?
          this.text(this.security.get(responseKey) ? 'systemSettingsEnabled' : 'systemSettingsDisabled') :
          this.displayValue(this.security.get(responseKey)))
          .fontSize(14).fontColor($r('sys.color.font_secondary')).constraintSize({ maxWidth: '45%' })
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
      }.width('100%').padding(16).constraintSize({ minHeight: 56 })
    }.backgroundColor($r('sys.color.comp_background_primary'))
      .onClick((): void => { this.editSecurity(responseKey, settingKey, titleKey); })
  }

  build() {
    NavDestination() {
      if (this.loading) {
        Column() { LoadingProgress().width(48).height(48) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.section === 'security') {
        List({ space: 12 }) {
          ListItemGroup() {
            ListItem() {
              HarmonyPanelEntry({ titleKey: 'settingsPanelAccountSecurity',
                icon: $r('sys.symbol.person'),
                action: (): void => { this.bridge.openNativePage('/security-verification'); } })
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
          ListItemGroup() {
            this.securityRow('securityEntrance', 'SecurityEntrance', 'securitySettingsSecurityEntrance')
            this.securityRow('bindDomain', 'BindDomain', 'securitySettingsBindDomain')
            this.securityRow('allowIPs', 'AllowIPs', 'securitySettingsAllowIPs')
          }.borderRadius(16).clip(true)
          ListItemGroup() {
            ListItem() {
              Row({ space: 12 }) {
                Text(this.text('securitySettingsComplexityVerification')).fontSize(16).layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.security.get('complexityVerification') === 'Enable' })
                  .enabled(!this.busy)
                  .accessibilityText(this.text('securitySettingsComplexityVerification'))
                  .onChange((enabled: boolean): void => {
                    this.changeSetting('ComplexityVerification', enabled ? 'Enable' : 'Disable');
                  })
              }.width('100%').padding(16).constraintSize({ minHeight: 56 })
            }.backgroundColor($r('sys.color.comp_background_primary'))
            this.securityRow('expirationDays', 'ExpirationDays', 'securitySettingsExpirationDays')
          }.borderRadius(16).clip(true)
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
      } else if (this.section === 'menu' || this.section === 'interfaces' || this.section === 'basic') {
        List({ space: 12 }) {
          if (this.section === 'menu') {
            ListItemGroup() {
              ListItem() {
                Column({ space: 12 }) {
                  Text(this.text('menuSettingsDescription')).fontSize(14).fontColor($r('sys.color.font_secondary'))
                  HarmonyPanelField({ titleKey: 'menuSettingsAddLabel', fieldValue: this.addedValue,
                    changed: (value: string): void => { this.addedValue = value; } })
                  Button(this.text('commonCreate')).height(48).width('100%').onClick((): void => { this.addMenu(); })
                }.width('100%').padding(16)
              }.backgroundColor($r('sys.color.comp_background_primary'))
            }.borderRadius(16).clip(true)
          }
          ListItemGroup() {
            ForEach(this.entries, (entry: string, index: number): void => {
              ListItem() {
                Row({ space: 12 }) {
                  Text(entry).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
                  if (this.section === 'menu') {
                    Button() { SymbolGlyph($r('sys.symbol.arrow_up')).fontSize(18) }
                      .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                      .accessibilityText(this.text('menuSettingsMoveUp')).enabled(index > 0)
                      .onClick((): void => { this.moveMenu(index, index - 1); })
                    Button() { SymbolGlyph($r('sys.symbol.arrow_down')).fontSize(18) }
                      .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                      .accessibilityText(this.text('menuSettingsMoveDown')).enabled(index < this.entries.length - 1)
                      .onClick((): void => { this.moveMenu(index, index + 1); })
                    Button(this.text('commonEdit')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                      .onClick((): void => {
                        this.editingMenuIndex = index;
                        this.editingMenuValue = entry;
                        this.menuSheet = true;
                      })
                    Button(this.text('commonDelete')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                      .onClick((): void => { this.entries.splice(index, 1); this.entries = this.entries.slice(); })
                  }
                }.width('100%').padding(16).constraintSize({ minHeight: 56 })
              }.backgroundColor($r('sys.color.comp_background_primary'))
            }, (entry: string, index: number): string => `${index}:${entry}`)
          }.borderRadius(16).clip(true)
          if (this.section === 'menu') {
            ListItem() {
              Button(this.text('commonSave')).height(52).width('100%').enabled(!this.busy)
                .onClick((): void => { this.saveMenus(); })
            }
          }
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            if (this.section === 'proxy') {
              Text(this.text('proxySettingsType')).fontSize(14)
                .fontColor($r('sys.color.font_secondary')).width('100%')
              Select(this.proxyOptions()).height(48)
                .selected(this.proxyConfigured() ? ['http', 'https', 'socks5'].indexOf(this.proxyType) + 1 : 0)
                .value(this.proxyConfigured() ? this.proxyType.toUpperCase() : this.text('systemSettingsDisabled'))
                .onSelect((index: number): void => {
                  this.proxyType = ['', 'http', 'https', 'socks5'][index];
                })
              if (this.proxyConfigured()) {
                HarmonyPanelField({ titleKey: 'proxySettingsHost', fieldValue: this.proxyUrl,
                  changed: (value: string): void => { this.proxyUrl = value; } })
                HarmonyPanelField({ titleKey: 'proxySettingsPort', fieldValue: this.proxyPort, numeric: true,
                  changed: (value: string): void => { this.proxyPort = value; } })
                HarmonyPanelField({ titleKey: 'proxySettingsUser', fieldValue: this.proxyUser,
                  changed: (value: string): void => { this.proxyUser = value; } })
                HarmonyPanelField({ titleKey: 'proxySettingsPassword', fieldValue: this.proxyPasswd, secret: true,
                  changed: (value: string): void => { this.proxyPasswd = value; } })
                Row({ space: 12 }) {
                  Text(this.text('hostAssetsRememberPasswordLabel')).fontSize(16).layoutWeight(1)
                  Toggle({ type: ToggleType.Switch, isOn: this.proxyPasswdKeep })
                    .accessibilityText(this.text('hostAssetsRememberPasswordLabel'))
                    .onChange((enabled: boolean): void => { this.proxyPasswdKeep = enabled; })
                }.width('100%').constraintSize({ minHeight: 56 })
              }
            } else {
              HarmonyPanelField({
                titleKey: this.section === 'memo' ? 'systemSettingsDashboardMemoHint' : 'appStoreTitle',
                fieldValue: this.draft,
                multiline: this.section === 'memo',
                changed: (value: string): void => { this.draft = value; },
              })
            }
            Button(this.text('commonSave')).height(52).width('100%').enabled(!this.busy)
              .onClick((): void => { this.save(); })
          }.width('100%').padding(20).alignItems(HorizontalAlign.Start)
        }.width('100%').height('100%')
      }
    }
    .title(this.text(this.section === 'basic' ? 'panelSettingsTitle' :
      this.section === 'store' ? 'appStoreTitle' :
        this.section === 'menu' ? 'menuSettingsTitle' :
          this.section === 'memo' ? 'systemSettingsDashboardMemo' :
            this.section === 'proxy' ? 'proxySettingsTitle' :
              this.section === 'interfaces' ? 'panelSettingsInterface' : 'securitySettingsTitle'),
      { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .bindSheet($$this.menuSheet, this.editMenuSheet, {
      height: SheetSize.MEDIUM, showClose: true, title: { title: this.text('menuSettingsEditTitle') },
      systemMaterial: sheetMaterial,
    })
    .bindSheet($$this.securitySheet, this.editSecuritySheet, {
      height: SheetSize.MEDIUM, showClose: true, title: { title: this.text(this.securityEditTitle) },
      systemMaterial: sheetMaterial,
    })
    .onShown((): void => { this.load(); })
  }
}
