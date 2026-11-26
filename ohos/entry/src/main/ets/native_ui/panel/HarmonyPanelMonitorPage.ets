import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';
import { HarmonyPanelField } from './HarmonyPanelControls';

@Component
export struct HarmonyPanelMonitorPage {
  @State private loading: boolean = true;
  @State private busy: boolean = false;
  @State private loadError: string = '';
  @State private settings: Map<string, Object | null> = new Map<string, Object | null>();
  @State private ioOptions: string[] = [];
  @State private networkOptions: string[] = [];
  @State private editKey: string = '';
  @State private editValue: string = '';
  @State private editSheet: boolean = false;
  @State private serverName: string = '';
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyPanelMonitor');
      this.settings = result;
      this.serverName = result.get('serverName') as string;
      this.ioOptions = result.get('ioOptions') as string[];
      this.networkOptions = result.get('networkOptions') as string[];
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private value(key: string): string {
    const result = this.settings.get(key);
    return result === undefined || result === null ? '—' : result.toString();
  }

  private update(values: Map<string, Object | null>): void {
    this.busy = true;
    this.updateSettings(values);
  }

  private async updateSettings(values: Map<string, Object | null>): Promise<void> {
    try {
      await this.bridge.invoke<Object | null>('updateHarmonyPanelMonitor', values);
      await this.load();
      this.getUIContext().getPromptAction().showToast({ message: this.text('monitorSettingsSaved') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private edit(key: string, value: string): void {
    this.editKey = key;
    this.editValue = value === '—' ? '' : value;
    this.editSheet = true;
  }

  private saveEditedValue(): void {
    const parsed = Number(this.editValue.trim());
    if (!Number.isInteger(parsed) || parsed <= 0 ||
      (this.editKey === 'interval' && (parsed < 10 || parsed > 43200))) {
      const validationKey = this.editKey === 'interval' ? 'monitorIntervalValidation' : 'monitorRetentionValidation';
      this.getUIContext().getPromptAction().showToast({ message: this.text(validationKey) });
      return;
    }
    const values = new Map<string, Object | null>();
    values.set(this.editKey, parsed);
    this.editSheet = false;
    this.update(values);
  }

  private selectDevice(key: string, options: string[]): void {
    if (options.length > 0) this.edit(key, this.value(key));
  }

  private async clearData(): Promise<void> {
    this.busy = true;
    try {
      await this.bridge.invoke<Object | null>('cleanHarmonyPanelMonitor');
      await this.load();
      this.getUIContext().getPromptAction().showToast({ message: this.text('monitorCleanSuccess') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  @Builder
  private numericRow(key: string, titleKey: string, unitKey: string) {
    ListItem() {
      Row({ space: 12 }) {
        Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
        Text(this.value(key) === '—' ? '—' : `${this.value(key)} ${this.text(unitKey)}`)
          .fontSize(14).fontColor($r('sys.color.font_secondary'))
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
      }.width('100%').padding(16).constraintSize({ minHeight: 56 })
    }.backgroundColor($r('sys.color.comp_background_primary'))
      .enabled(!this.busy).onClick((): void => { this.edit(key, this.value(key)); })
  }

  @Builder
  private deviceRow(key: string, titleKey: string) {
    ListItem() {
      Row({ space: 12 }) {
        Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
        Text(this.value(key) === 'all' ? this.text('monitorAll') : this.value(key))
          .fontSize(14).fontColor($r('sys.color.font_secondary'))
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
      }.width('100%').padding(16).constraintSize({ minHeight: 56 })
    }.backgroundColor($r('sys.color.comp_background_primary'))
      .enabled(!this.busy && (key === 'defaultIO' ? this.ioOptions.length > 0 : this.networkOptions.length > 0))
      .onClick((): void => { this.selectDevice(key, key === 'defaultIO' ? this.ioOptions : this.networkOptions); })
  }

  @Builder
  private editSheetContent() {
    Column({ space: 16 }) {
      if (this.editKey === 'defaultIO' || this.editKey === 'defaultNetwork') {
        List() {
          ForEach(this.editKey === 'defaultIO' ? this.ioOptions : this.networkOptions, (option: string): void => {
            ListItem() {
              Button(option === 'all' ? this.text('monitorAll') : option)
                .height(48).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick((): void => {
                    this.editSheet = false;
                    if (this.editValue === option) return;
                  const values = new Map<string, Object | null>();
                  values.set(this.editKey, option);
                  this.update(values);
                })
            }
          }, (option: string): string => option)
        }.width('100%').layoutWeight(1)
      } else {
        HarmonyPanelField({ titleKey: this.editKey === 'interval' ? 'monitorSettingsInterval' : 'monitorSettingsStoreDays',
          fieldValue: this.editValue, numeric: true,
          changed: (value: string): void => { this.editValue = value; } })
        Button(this.text('commonSave')).height(48).width('100%').enabled(!this.busy)
          .onClick((): void => { this.saveEditedValue(); })
      }
    }.width('100%').height('100%').padding(24)
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
      } else {
        List({ space: 12 }) {
          ListItemGroup() {
            ListItem() {
              Row({ space: 16 }) {
                Text(this.text('monitorSettingsEnable')).fontSize(16)
                  .fontColor($r('sys.color.font_primary')).layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.value('enabled') === 'true' })
                  .enabled(!this.busy)
                  .onChange((enabled: boolean): void => {
                    const values = new Map<string, Object | null>();
                    values.set('enabled', enabled);
                    this.update(values);
                  })
              }.width('100%').padding(16).constraintSize({ minHeight: 64 })
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
          ListItemGroup() {
            this.numericRow('interval', 'monitorSettingsInterval', 'monitorIntervalUnit')
            this.numericRow('retention', 'monitorSettingsStoreDays', 'monitorRetentionUnit')
            this.deviceRow('defaultIO', 'monitorIoDeviceLabel')
            this.deviceRow('defaultNetwork', 'monitorNetworkInterfaceLabel')
          }.borderRadius(16).clip(true)
          ListItemGroup() {
            ListItem() {
              Button(this.text('monitorCleanData')).height(56).width('100%')
                .buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.busy)
                .onClick((): void => {
                  this.getUIContext().showAlertDialog({
                    title: this.text('monitorCleanData'),
                    message: `${this.serverName}\n${this.text('monitorCleanConfirm')}`,
                    primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
                    secondaryButton: { value: this.text('commonClear'), action: (): void => { this.clearData(); } },
                  });
                })
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
      }
    }
    .title(this.text('monitorSettingsTitle'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .bindSheet($$this.editSheet, this.editSheetContent, {
      height: SheetSize.MEDIUM, showClose: true,
      title: { title: this.text(this.editKey === 'interval' ? 'monitorSettingsInterval' :
        this.editKey === 'retention' ? 'monitorSettingsStoreDays' :
          this.editKey === 'defaultIO' ? 'monitorIoDeviceLabel' : 'monitorNetworkInterfaceLabel') },
      systemMaterial: sheetMaterial,
    })
    .onShown((): void => { this.load(); })
  }
}
