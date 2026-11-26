import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';

@Component
export struct HarmonyStoragePage {
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private loadError: string = '';
  @State private cacheStrategy: string = 'hybrid';
  @State private maxSizeMB: number = 100;
  @State private currentSizeMB: string = '';
  @State private itemCount: number = 0;
  @State private expirationMinutes: number = 0;
  @State private usePicker: boolean = true;
  @State private folder: string = '';
  @State private folderDraft: string = '';
  @State private folderSheet: boolean = false;
  @State private sizeOptions: number[] = [50, 100, 200, 500];
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly strategies: string[] = ['hybrid', 'memoryOnly', 'diskOnly'];
  private readonly strategyKeys: string[] = [
    'settingsCacheStrategyHybrid', 'settingsCacheStrategyMemoryOnly', 'settingsCacheStrategyDiskOnly',
  ];

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyStorage');
      this.cacheStrategy = result.get('strategy') as string;
      this.maxSizeMB = result.get('maxSizeMB') as number;
      this.usePicker = result.get('usePicker') as boolean;
      this.folder = result.get('folder') as string;
      const stats = result.get('stats') as Map<string, Object | null>;
      this.currentSizeMB = `${stats.get('currentSizeMB')}`;
      this.itemCount = stats.get('itemCount') as number;
      this.expirationMinutes = stats.get('expirationMinutes') as number;
      const options: number[] = [50, 100, 200, 500];
      if (!options.includes(this.maxSizeMB)) options.push(this.maxSizeMB);
      this.sizeOptions = options.sort((first: number, second: number): number => first - second);
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async save(key: string, settingValue: string | number | boolean): Promise<boolean> {
    this.isSaving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('key', key);
      args.set('value', settingValue);
      args.set('failureMessage', this.text('settingsInvalidFolderName'));
      await this.bridge.invoke<Object | null>('updateHarmonyStorage', args);
      await this.load();
      if (key === 'clear') {
        this.getUIContext().getPromptAction().showToast({ message: this.text('settingsCacheCleared') });
      }
      return true;
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
      return false;
    } finally {
      this.isSaving = false;
    }
  }

  private clearCache(): void {
    this.getUIContext().showAlertDialog({
      title: this.text('settingsCacheClearConfirm'),
      message: this.text('settingsCacheClearConfirmMessage'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('settingsCacheClear'),
        action: (): void => { this.save('clear', true); },
      },
    });
  }

  private async saveFolder(): Promise<void> {
    if (await this.save('folder', this.folderDraft)) this.folderSheet = false;
  }

  @Builder
  private sectionHeading(key: string) {
    Text(this.text(key)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private statusRow(titleKey: string, detail: string) {
    ListItem() {
      Row({ space: 16 }) {
        Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
        Text(detail).fontSize(14).fontColor($r('sys.color.font_secondary'))
      }.padding(16).width('100%').constraintSize({ minHeight: 56 })
    }.backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private editFolderSheet() {
    Column({ space: 16 }) {
      TextInput({ text: this.folderDraft, placeholder: this.text('systemSettingsFileExportSubDirTitle') })
        .height(48).onChange((input: string): void => { this.folderDraft = input; })
      Text(this.text('systemSettingsFileExportSubDirHelper')).fontSize(14)
        .fontColor($r('sys.color.font_secondary')).width('100%')
      Button(this.text('commonSave')).width('100%').height(48).enabled(!this.isSaving)
        .onClick((): void => { this.saveFolder(); })
    }.padding(24).width('100%')
  }

  build() {
    NavDestination() {
      if (this.isLoading) {
        LoadingProgress().width(48).height(48)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }.padding(24)
      } else {
        List({ space: 16 }) {
          ListItemGroup({ header: this.sectionHeading('settingsPreviewCache') }) {
            ListItem() {
              Column({ space: 4 }) {
                Text(this.text('settingsCacheStrategy')).fontSize(16).fontColor($r('sys.color.font_primary'))
                Select(this.strategyKeys.map((key: string): SelectOption => ({ value: this.text(key) })))
                  .selected(this.strategies.indexOf(this.cacheStrategy))
                  .value(this.text(this.strategyKeys[this.strategies.indexOf(this.cacheStrategy)]))
                  .height(48).enabled(!this.isSaving)
                  .onSelect((index: number): void => { this.save('strategy', this.strategies[index]); })
              }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
            }.backgroundColor($r('sys.color.comp_background_primary'))
            if (this.cacheStrategy !== 'diskOnly') {
              ListItem() {
                Row({ space: 16 }) {
                  Text(this.text('settingsCacheMaxSize')).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
                  Select(this.sizeOptions.map((size: number): SelectOption => ({ value: `${size} MB` })))
                    .selected(this.sizeOptions.indexOf(this.maxSizeMB)).value(`${this.maxSizeMB} MB`)
                    .height(48).enabled(!this.isSaving)
                    .onSelect((index: number): void => { this.save('maxSizeMB', this.sizeOptions[index]); })
                }.padding({ left: 16, right: 16 }).constraintSize({ minHeight: 64 }).width('100%')
              }.backgroundColor($r('sys.color.comp_background_primary'))
              this.statusRow('settingsCacheStatus', `${this.currentSizeMB} MB / ${this.maxSizeMB} MB`)
              this.statusRow('settingsCacheItemCount', this.itemCount.toString())
              this.statusRow('settingsCacheExpiration', `${this.expirationMinutes} ${this.text('settingsCacheExpirationUnit')}`)
            }
            ListItem() {
              Button(this.text('settingsCacheClear')).height(56).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
                .enabled(!this.isSaving).onClick((): void => { this.clearCache(); })
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
          ListItemGroup({ header: this.sectionHeading('systemSettingsFileExportSection') }) {
            ListItem() {
              Row({ space: 16 }) {
                Column({ space: 4 }) {
                  Text(this.text('systemSettingsFileExportUsePicker')).fontSize(16).fontColor($r('sys.color.font_primary'))
                  Text(this.text('systemSettingsFileExportUsePickerDesc')).fontSize(14).fontColor($r('sys.color.font_secondary'))
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.usePicker }).enabled(!this.isSaving)
                  .accessibilityText(this.text('systemSettingsFileExportUsePicker'))
                  .onChange((checked: boolean): void => { this.save('usePicker', checked); })
              }.padding(16).width('100%')
            }.backgroundColor($r('sys.color.comp_background_primary'))
            if (!this.usePicker) {
              ListItem() {
                Row({ space: 16 }) {
                  Column({ space: 4 }) {
                    Text(this.text('systemSettingsFileExportSubDirTitle')).fontSize(16).fontColor($r('sys.color.font_primary'))
                    Text(this.folder.length > 0 ? this.folder : this.text('systemSettingsFileExportSubDirHelper'))
                      .fontSize(14).fontColor($r('sys.color.font_secondary'))
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.icon_tertiary')])
                }.padding(16).width('100%').constraintSize({ minHeight: 64 })
              }.backgroundColor($r('sys.color.comp_background_primary'))
                .onClick((): void => { this.folderDraft = this.folder; this.folderSheet = true; })
            }
          }.borderRadius(16).clip(true)
        }.padding({ left: 16, right: 16, top: 16, bottom: 24 }).width('100%').height('100%')
      }
    }
    .title(this.text('settingsCacheTitle'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .bindSheet($$this.folderSheet, this.editFolderSheet, {
      height: SheetSize.MEDIUM, showClose: true, title: { title: this.text('systemSettingsFileExportSubDirTitle') },
      systemMaterial: sheetMaterial,
    })
    .onShown((): void => { this.load(); })
  }
}
