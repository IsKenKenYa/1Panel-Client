import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

interface HarmonySettingsDestination {
  titleKey: string;
  route: string;
}

@Component
export struct HarmonySettingsPage {
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private loadError: string = '';
  @State private selectedLanguage: string = 'system';
  @State private selectedTheme: string = 'system';
  @State private selectedRenderMode: string = 'native';

  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly languageIds: string[] = ['system', 'zh', 'en'];
  private readonly themeIds: string[] = ['system', 'light', 'dark'];
  private readonly renderModeIds: string[] = ['native', 'md3', 'liquidGlass'];
  private readonly appDestinations: HarmonySettingsDestination[] = [
    { titleKey: 'settingsAppearance', route: '/settings/theme' },
    { titleKey: 'settingsAppLock', route: '/settings/app-lock' },
    { titleKey: 'settingsCacheTitle', route: '/settings/storage' },
    { titleKey: 'settingsServerManagement', route: '/server' },
  ];
  private readonly supportDestinations: HarmonySettingsDestination[] = [
    { titleKey: 'settingsFeedbackCenterTitle', route: '/settings/feedback-center' },
    { titleKey: 'settingsLegalCenterTitle', route: '/settings/legal-center' },
    { titleKey: 'settingsMainlandSdkDisclosureTitle', route: '/settings/legal-center/mainland-sdk' },
    { titleKey: 'settingsAbout', route: '/settings/about' },
  ];

  aboutToAppear(): void {
    this.loadSettings();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private async loadSettings(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const settings = await this.bridge.invoke<Map<string, Object | null>>('getSettings');
      this.selectedLanguage = settings.get('language') as string;
      this.selectedTheme = settings.get('themeMode') as string;
      this.selectedRenderMode = settings.get('renderMode') as string;
    } catch (error) {
      this.loadError = `${error}`;
    } finally {
      this.isLoading = false;
    }
  }

  private async saveSetting(key: string, settingValue: string): Promise<void> {
    this.isSaving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('key', key);
      args.set('value', settingValue);
      const result = await this.bridge.invoke<Map<string, Object | null>>('updateSetting', args);
      if (result.get('success') !== true) {
        throw new Error(result.get('error') as string);
      }
      await this.bridge.refreshSettings();
      if (key === 'renderMode') {
        return;
      }
      if (key === 'language' || key === 'themeMode') {
        await this.bridge.loadTranslations();
      }
      await this.loadSettings();
      this.getUIContext().getPromptAction().showToast({
        message: this.text('commonSaveSuccess'),
      });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    } finally {
      this.isSaving = false;
    }
  }

  private async openDestination(route: string): Promise<void> {
    try {
      await this.bridge.openFlutterPage(route);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private languageOptions(): SelectOption[] {
    return [
      { value: this.text('languageSystem') },
      { value: this.text('languageZh') },
      { value: this.text('languageEn') },
    ];
  }

  private themeOptions(): SelectOption[] {
    return [
      { value: this.text('themeSystem') },
      { value: this.text('themeLight') },
      { value: this.text('themeDark') },
    ];
  }

  private renderModeOptions(): SelectOption[] {
    return [
      { value: this.text('settingsUIRenderModeNative') },
      { value: this.text('settingsUIRenderModeMD3') },
      { value: this.text('settingsUIRenderModeLiquidGlass') },
    ];
  }

  @Builder
  private destinationRow(destination: HarmonySettingsDestination) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Text(this.text(destination.titleKey))
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
          .maxLines(2)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .buttonStyle(ButtonStyleMode.TEXTUAL)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .borderRadius(16)
    .id(`harmony.settings.${destination.titleKey}`)
    .accessibilityText(this.text(destination.titleKey))
    .onClick((): void => {
      this.openDestination(destination.route);
    })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.isLoading) {
          LoadingProgress()
            .width(40)
            .height(40)
            .accessibilityText(this.text('commonLoading'))
        } else if (this.loadError.length > 0) {
          Text(this.loadError)
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
          Button(this.text('commonRetry'))
            .constraintSize({ minWidth: 48, minHeight: 48 })
            .onClick((): void => {
              this.loadSettings();
            })
        } else {
          Column({ space: 8 }) {
            Text(this.text('settingsLanguage'))
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width('100%')
            Select(this.languageOptions())
              .selected(this.languageIds.indexOf(this.selectedLanguage))
              .value(this.languageOptions()[this.languageIds.indexOf(this.selectedLanguage)].value)
              .width('100%')
              .height(48)
              .enabled(!this.isSaving)
              .id('harmony.settings.language')
              .accessibilityText(this.text('settingsLanguage'))
              .onSelect((index: number): void => {
                this.saveSetting('language', this.languageIds[index]);
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Text(this.text('settingsTheme'))
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width('100%')
            Select(this.themeOptions())
              .selected(this.themeIds.indexOf(this.selectedTheme))
              .value(this.themeOptions()[this.themeIds.indexOf(this.selectedTheme)].value)
              .width('100%')
              .height(48)
              .enabled(!this.isSaving)
              .id('harmony.settings.theme')
              .accessibilityText(this.text('settingsTheme'))
              .onSelect((index: number): void => {
                this.saveSetting('themeMode', this.themeIds[index]);
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Text(this.text('settingsUIRenderMode'))
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width('100%')
            Select(this.renderModeOptions())
              .selected(this.renderModeIds.indexOf(this.selectedRenderMode))
              .value(this.renderModeOptions()[this.renderModeIds.indexOf(this.selectedRenderMode)].value)
              .width('100%')
              .height(48)
              .enabled(!this.isSaving)
              .id('harmony.settings.renderMode')
              .accessibilityText(this.text('settingsUIRenderMode'))
              .onSelect((index: number): void => {
                this.saveSetting('renderMode', this.renderModeIds[index]);
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          ForEach(this.appDestinations, (destination: HarmonySettingsDestination) => {
            this.destinationRow(destination)
          }, (destination: HarmonySettingsDestination): string => destination.route)

          Text(this.text('settingsHelpAbout'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .width('100%')
            .margin({ top: 8 })
          ForEach(this.supportDestinations, (destination: HarmonySettingsDestination) => {
            this.destinationRow(destination)
          }, (destination: HarmonySettingsDestination): string => destination.route)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
