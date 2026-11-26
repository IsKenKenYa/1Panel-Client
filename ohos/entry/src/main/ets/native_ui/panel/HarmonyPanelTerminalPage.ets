import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyPanelEntry, HarmonyPanelField } from './HarmonyPanelControls';

@Component
export struct HarmonyPanelTerminalPage {
  @Prop connectionOnly: boolean = false;
  @State private loading: boolean = true;
  @State private busy: boolean = false;
  @State private loadError: string = '';
  @State private terminal: Map<string, Object | null> = new Map<string, Object | null>();
  @State private connection: Map<string, Object | null> = new Map<string, Object | null>();
  @State private authMode: string = 'password';
  @State private testResult: string = '';
  @State private terminalValues: Map<string, string> = new Map<string, string>();
  @State private connectionValues: Map<string, string> = new Map<string, string>();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  aboutToAppear(): void { this.load(); }

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      if (!this.connectionOnly) {
        const terminal = await this.bridge.invoke<Map<string, Object | null> | null>('getHarmonyPanelTerminal');
        if (terminal === null) throw new Error(this.text('commonLoadFailedTitle'));
        this.terminal = terminal;
        this.terminalValues = this.stringValues(terminal);
      }
      if (this.connectionOnly) {
        const connection = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyPanelConnection');
        this.connection = connection;
        this.connectionValues = this.stringValues(connection);
        this.authMode = connection.get('authMode') === 'key' ? 'key' : 'password';
      }
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private stringValues(source: Map<string, Object | null>): Map<string, string> {
    const values = new Map<string, string>();
    source.forEach((value: Object | null, key: string): void => {
      if (value !== null && value !== undefined) values.set(key, value.toString());
    });
    return values;
  }

  private fieldValue(source: Map<string, Object | null>, key: string, fallback: string): string {
    const value = source.get(key);
    return value === undefined || value === null || value.toString().length === 0 ? fallback : value.toString();
  }

  private previewColor(key: string, fallback: Resource): ResourceColor {
    const color = this.terminalValues.get(key)?.trim();
    if (color && new RegExp('^#[0-9A-Fa-f]{6}$').test(color)) return color;
    return fallback;
  }

  private previewFontSize(): number {
    const size = Number(this.terminalValues.get('fontSize'));
    return Number.isFinite(size) && size >= 12 && size <= 24 ? size : 14;
  }

  private changed(values: Map<string, string>, key: string, value: string): void {
    values.set(key, value);
    if (values === this.connectionValues) this.connectionValues = values;
    else this.terminalValues = values;
  }

  private async saveTerminal(): Promise<void> {
    this.busy = true;
    try {
      const args = new Map<string, Object | null>();
      this.terminalValues.forEach((value: string, key: string): void => {
        if (value !== this.terminal.get(key)) args.set(key, value);
      });
      if (args.size === 0) return;
      await this.bridge.invoke<Object | null>('updateHarmonyPanelTerminal', args);
      await this.load();
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private connectionArgs(): Map<string, Object | null> {
    const address = this.connectionValues.get('addr')?.trim() ?? '';
    const user = this.connectionValues.get('user')?.trim() ?? '';
    const port = Number(this.connectionValues.get('port'));
    if (address.length === 0 || user.length === 0) {
      throw new Error(this.text('serverFormRequired'));
    }
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
      throw new Error(this.text('websitesDomainValidationPort'));
    }
    const args = new Map<string, Object | null>();
    args.set('addr', address);
    args.set('port', port);
    args.set('user', user);
    args.set('authMode', this.authMode);
    if (this.authMode === 'password') {
      args.set('password', this.connectionValues.get('password') ?? '');
    } else {
      const privateKey = this.connectionValues.get('privateKey')?.trim() ?? '';
      if (privateKey.length === 0) throw new Error(this.text('panelTlsValidationPrivateKeyRequired'));
      args.set('privateKey', privateKey);
      const passPhrase = this.connectionValues.get('passPhrase')?.trim();
      if (passPhrase) args.set('passPhrase', passPhrase);
    }
    return args;
  }

  private async testConnection(): Promise<void> {
    this.busy = true;
    this.testResult = '';
    try {
      const connected = await this.bridge.invoke<boolean>('testHarmonyPanelConnection', this.connectionArgs());
      this.testResult = this.text(connected ? 'commonSaveSuccess' : 'commonSaveFailed');
      this.getUIContext().getPromptAction().showToast({ message: this.testResult });
    } catch (error) {
      this.testResult = (error as Error).message;
      this.getUIContext().getPromptAction().showToast({ message: this.testResult.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private async saveConnection(): Promise<void> {
    this.busy = true;
    try {
      await this.bridge.invoke<Object | null>('saveHarmonyPanelConnection', this.connectionArgs());
      await this.load();
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private async setDefaultConnection(visible: boolean): Promise<void> {
    this.busy = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('visible', visible);
      await this.bridge.invoke<Object | null>('setHarmonyPanelDefaultConnection', args);
      await this.load();
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  @Builder
  private terminalSettings() {
    List({ space: 12 }) {
      ListItemGroup({ header: (): void => {
        Text(this.text('terminalSettingsPreview')).fontSize(14)
          .fontColor($r('sys.color.font_secondary')).padding({ left: 16, top: 8, bottom: 8 });
      } }) {
        ListItem() {
          Text('root@server:~# ls -la\ndrwxr-xr-x  2 root root 4096 .')
            .fontColor(this.previewColor('foregroundColor', $r('sys.color.font_primary')))
            .fontSize(this.previewFontSize()).fontFamily('monospace')
            .width('100%').padding(16)
            .backgroundColor(this.previewColor('backgroundColor', $r('sys.color.comp_background_primary')))
        }
      }.borderRadius(16).clip(true)
      ListItemGroup({ header: (): void => { Text(this.text('terminalSettingsDisplay')).fontSize(14).padding(16); } }) {
        ListItem() {
          Column({ space: 12 }) {
            HarmonyPanelField({ titleKey: 'terminalSettingsFontSize',
              fieldValue: this.terminalValues.get('fontSize') ?? this.fieldValue(this.terminal, 'fontSize', '14'),
              numeric: true, changed: (value: string): void => { this.changed(this.terminalValues, 'fontSize', value); } })
            HarmonyPanelField({ titleKey: 'terminalSettingsFontFamily',
              fieldValue: this.terminalValues.get('fontFamily') ?? this.fieldValue(this.terminal, 'fontFamily', ''),
              changed: (value: string): void => { this.changed(this.terminalValues, 'fontFamily', value); } })
            HarmonyPanelField({ titleKey: 'terminalSettingsBackgroundColor',
              fieldValue: this.terminalValues.get('backgroundColor') ?? this.fieldValue(this.terminal, 'backgroundColor', ''),
              changed: (value: string): void => { this.changed(this.terminalValues, 'backgroundColor', value); } })
            HarmonyPanelField({ titleKey: 'terminalSettingsForegroundColor',
              fieldValue: this.terminalValues.get('foregroundColor') ?? this.fieldValue(this.terminal, 'foregroundColor', ''),
              changed: (value: string): void => { this.changed(this.terminalValues, 'foregroundColor', value); } })
            Select([
              { value: this.text('terminalSettingsCursorBlock') },
              { value: this.text('terminalSettingsCursorUnderline') },
              { value: this.text('terminalSettingsCursorBar') },
            ]).selected(['block', 'underline', 'bar'].indexOf(this.terminalValues.get('cursorStyle') ?? this.fieldValue(this.terminal, 'cursorStyle', 'block')))
              .value(this.terminalValues.get('cursorStyle') ?? this.fieldValue(this.terminal, 'cursorStyle', 'block'))
              .height(48).onSelect((index: number): void => {
                const styles = ['block', 'underline', 'bar'];
                this.changed(this.terminalValues, 'cursorStyle', styles[index]);
              })
            Row({ space: 12 }) {
              Text(this.text('terminalSettingsCursorBlink')).fontSize(16).layoutWeight(1)
              Toggle({ type: ToggleType.Switch,
                isOn: (this.terminalValues.get('cursorBlink') ?? 'Enable').toLowerCase() === 'enable' })
                .accessibilityText(this.text('terminalSettingsCursorBlink'))
                .onChange((enabled: boolean): void => {
                  this.changed(this.terminalValues, 'cursorBlink', enabled ? 'Enable' : 'Disable');
                })
            }.width('100%')
            HarmonyPanelField({ titleKey: 'terminalSettingsScrollback',
              fieldValue: this.terminalValues.get('scrollback') ?? this.fieldValue(this.terminal, 'scrollback', '1000'), numeric: true,
              changed: (value: string): void => { this.changed(this.terminalValues, 'scrollback', value); } })
            HarmonyPanelField({ titleKey: 'terminalSettingsScrollSensitivity',
              fieldValue: this.terminalValues.get('scrollSensitivity') ?? this.fieldValue(this.terminal, 'scrollSensitivity', '6'), numeric: true,
              changed: (value: string): void => { this.changed(this.terminalValues, 'scrollSensitivity', value); } })
            HarmonyPanelField({ titleKey: 'terminalSettingsLineHeight',
              fieldValue: this.terminalValues.get('lineHeight') ?? this.fieldValue(this.terminal, 'lineHeight', '1.2'),
              changed: (value: string): void => { this.changed(this.terminalValues, 'lineHeight', value); } })
            HarmonyPanelField({ titleKey: 'terminalSettingsLetterSpacing',
              fieldValue: this.terminalValues.get('letterSpacing') ?? this.fieldValue(this.terminal, 'letterSpacing', '0'),
              changed: (value: string): void => { this.changed(this.terminalValues, 'letterSpacing', value); } })
            Button(this.text('commonSave')).height(48).width('100%').enabled(!this.busy)
              .onClick((): void => { this.saveTerminal(); })
          }.padding(16).width('100%')
        }.backgroundColor($r('sys.color.comp_background_primary'))
      }.borderRadius(16).clip(true)
      ListItem() {
        HarmonyPanelEntry({ titleKey: 'terminalSettingsDefaultLocalConnection', icon: $r('sys.symbol.link'),
          action: (): void => { this.bridge.openNativePage('/system-settings/connection'); } })
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
    }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
  }

  @Builder
  private connectionSettings() {
    List({ space: 12 }) {
      ListItemGroup() {
        ListItem() {
          Column({ space: 12 }) {
            HarmonyPanelField({ titleKey: 'sshSessionsHostLabel', fieldValue: this.connectionValues.get('addr') ?? '',
              changed: (value: string): void => { this.changed(this.connectionValues, 'addr', value); } })
            HarmonyPanelField({ titleKey: 'sshPortLabel', fieldValue: this.connectionValues.get('port') ?? '', numeric: true,
              changed: (value: string): void => { this.changed(this.connectionValues, 'port', value); } })
            HarmonyPanelField({ titleKey: 'sshSessionsLoginUserLabel', fieldValue: this.connectionValues.get('user') ?? '',
              changed: (value: string): void => { this.changed(this.connectionValues, 'user', value); } })
            Select([{ value: this.text('terminalSettingsConnectionPassword') }, { value: this.text('terminalSettingsConnectionPrivateKey') }])
              .selected(this.authMode === 'key' ? 1 : 0)
              .value(this.text(this.authMode === 'key' ? 'terminalSettingsConnectionPrivateKey' : 'terminalSettingsConnectionPassword'))
              .height(48).onSelect((index: number): void => { this.authMode = index === 1 ? 'key' : 'password'; })
            if (this.authMode === 'password') {
              HarmonyPanelField({ titleKey: 'terminalSettingsConnectionPassword', fieldValue: this.connectionValues.get('password') ?? '', secret: true,
                changed: (value: string): void => { this.changed(this.connectionValues, 'password', value); } })
            } else {
              HarmonyPanelField({ titleKey: 'terminalSettingsConnectionPrivateKey', fieldValue: this.connectionValues.get('privateKey') ?? '', multiline: true,
                changed: (value: string): void => { this.changed(this.connectionValues, 'privateKey', value); } })
              HarmonyPanelField({ titleKey: 'terminalSettingsConnectionPassPhrase', fieldValue: this.connectionValues.get('passPhrase') ?? '', secret: true,
                changed: (value: string): void => { this.changed(this.connectionValues, 'passPhrase', value); } })
            }
            if (this.testResult.length > 0) {
              Text(this.testResult).fontSize(14).fontColor($r('sys.color.font_secondary'))
                .width('100%').copyOption(CopyOptions.InApp)
            }
            Row({ space: 12 }) {
              Button(this.text('terminalSettingsTestConnection')).height(48).layoutWeight(1).enabled(!this.busy)
                .onClick((): void => { this.testConnection(); })
              Button(this.text('commonSave')).height(48).layoutWeight(1).enabled(!this.busy)
                .onClick((): void => { this.saveConnection(); })
            }.width('100%')
            Row({ space: 12 }) {
              Text(this.text('terminalSettingsShowLocalByDefault')).fontSize(16).layoutWeight(1)
              Toggle({ type: ToggleType.Switch,
                isOn: this.fieldValue(this.connection, 'localSSHConnShow', 'Disable').toLowerCase() === 'enable' })
                .accessibilityText(this.text('terminalSettingsShowLocalByDefault'))
                .onChange((enabled: boolean): void => { this.setDefaultConnection(enabled); })
            }.width('100%')
          }.padding(16).width('100%')
        }.backgroundColor($r('sys.color.comp_background_primary'))
      }.borderRadius(16).clip(true)
    }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
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
      } else if (this.connectionOnly) {
        this.connectionSettings()
      } else {
        this.terminalSettings()
      }
    }
    .title(this.text(this.connectionOnly ? 'terminalSettingsConnectionSetup' : 'terminalSettingsTitle'),
      { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .onShown((): void => { this.load(); })
  }
}
