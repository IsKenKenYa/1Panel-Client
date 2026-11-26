import { LengthMetrics } from '@kit.ArkUI';
import { KeyCode } from '@kit.InputKit';
import { HarmonyNativeBridge, titleBarMaterial } from '../HarmonyNativeBridge';

interface HarmonySettingsEntry {
  titleKey: string;
  route: string;
  icon: Resource;
}

@Component
export struct HarmonySettingsPage {
  @StorageLink('harmonyNativeRefresh') @Watch('loadSettings') private presentationRevision: number = 0;
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private loadError: string = '';
  @State private selectedLanguage: string = 'system';
  @State private selectedTheme: string = 'system';
  @State private selectedRenderMode: string = 'native';
  @State private currentServerName: string = '';
  @State private hasPanelSettings: boolean = false;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly renderModeIds: string[] = ['native', 'md3', 'liquidGlass'];
  private readonly securityEntries: HarmonySettingsEntry[] = [
    { titleKey: 'settingsAppLock', route: '/settings/app-lock', icon: $r('sys.symbol.lock') },
    { titleKey: 'settingsCacheTitle', route: '/settings/storage', icon: $r('sys.symbol.folder') },
  ];
  private readonly helpEntries: HarmonySettingsEntry[] = [
    { titleKey: 'settingsFeedbackCenterTitle', route: '/settings/feedback-center', icon: $r('sys.symbol.message') },
    { titleKey: 'settingsLegalCenterTitle', route: '/settings/legal-center', icon: $r('sys.symbol.doc_text') },
    { titleKey: 'settingsAbout', route: '/settings/about', icon: $r('sys.symbol.info_circle') },
  ];

  aboutToAppear(): void { this.loadSettings(); }

  private text(key: string): string { return this.bridge.text(key); }

  private async loadSettings(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const settings = await this.bridge.invoke<Map<string, Object | null>>('getSettings');
      this.selectedLanguage = settings.get('language') as string;
      this.selectedTheme = settings.get('themeMode') as string;
      this.selectedRenderMode = settings.get('renderMode') as string;
      const server = await this.bridge.invoke<Map<string, Object | null> | null>('getCurrentServer');
      this.hasPanelSettings = server !== null && server.get('panelType') === '1panel';
      this.currentServerName = server === null ? '' : server.get('name') as string;
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private languageLabel(): string {
    if (this.selectedLanguage === 'zh') return this.text('languageZh');
    if (this.selectedLanguage === 'en') return this.text('languageEn');
    return this.text('languageSystem');
  }

  private themeLabel(): string {
    if (this.selectedTheme === 'light') return this.text('themeLight');
    if (this.selectedTheme === 'dark') return this.text('themeDark');
    return this.text('themeSystem');
  }

  private renderModeOptions(): SelectOption[] {
    return [
      { value: this.text('settingsUIRenderModeNative') },
      { value: this.text('settingsUIRenderModeMD3') },
      { value: this.text('settingsUIRenderModeLiquidGlass') },
    ];
  }

  private async saveRenderMode(index: number): Promise<void> {
    if (this.isSaving || this.selectedRenderMode === this.renderModeIds[index]) return;
    this.isSaving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('key', 'renderMode');
      args.set('value', this.renderModeIds[index]);
      const result = await this.bridge.invoke<Map<string, Object | null>>('updateSetting', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.selectedRenderMode = this.renderModeIds[index];
      await this.bridge.refreshSettings();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.isSaving = false;
    }
  }

  private async openDestination(route: string): Promise<void> {
    try {
      await this.bridge.openNativePage(route);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private async resetOnboarding(): Promise<void> {
    try {
      await this.bridge.invoke<Object | null>('resetHarmonyOnboarding');
      this.getUIContext().getPromptAction().showToast({ message: this.text('settingsResetOnboardingDone') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  @Builder
  private sectionHeader(titleKey: string) {
    Text(this.text(titleKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .width('100%').padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private appearanceHeader() { this.sectionHeader('settingsAppearanceLanguage') }

  @Builder
  private securityHeader() { this.sectionHeader('settingsSecurityStorage') }

  @Builder
  private connectionsHeader() { this.sectionHeader('settingsConnections') }

  @Builder
  private helpHeader() { this.sectionHeader('settingsHelpAbout') }

  @Builder
  private destinationRow(titleKey: string, route: string, icon: Resource, detail: string = '') {
    ListItem() {
      Row({ space: 12 }) {
        SymbolGlyph(icon).fontSize(24).fontColor([$r('sys.color.icon_primary')])
        Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
        if (detail.length > 0) {
          Text(detail).fontSize(14).fontColor($r('sys.color.font_secondary'))
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: '40%' })
        }
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14)
          .fontColor([$r('sys.color.icon_tertiary')])
      }.constraintSize({ minHeight: 56 }).width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    }
    .id(`harmony.settings.${titleKey}`)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .accessibilityText(`${this.text(titleKey)} ${detail}`)
    .onClick((): void => { this.openDestination(route); })
    .onKeyEvent((event?: KeyEvent): boolean => {
      if (event !== undefined && event.type === KeyType.Down &&
        (event.keyCode === KeyCode.KEYCODE_ENTER || event.keyCode === KeyCode.KEYCODE_SPACE)) {
        this.openDestination(route);
        return true;
      }
      return false;
    })
    .focusable(true)
    .focusOnTouch(true)
    .focusBox({ margin: LengthMetrics.vp(2) })
    .hoverEffect(HoverEffect.Highlight)
  }

  build() {
    Navigation() {
      if (this.isLoading) {
        LoadingProgress().width(48).height(48)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.loadSettings(); })
        }.padding(24)
      } else {
        Row() {
          List({ space: 16 }) {
            ListItemGroup({ header: this.appearanceHeader }) {
              this.destinationRow('settingsTheme', '/settings/theme', $r('sys.symbol.paintbrush'), this.themeLabel())
              ListItem() {
                Row({ space: 12 }) {
                  SymbolGlyph($r('sys.symbol.slider_horizontal_2')).fontSize(24)
                    .fontColor([$r('sys.color.icon_primary')])
                  Text(this.text('settingsUIRenderMode')).fontSize(16)
                    .fontColor($r('sys.color.font_primary')).layoutWeight(1)
                  Select(this.renderModeOptions())
                    .selected(this.renderModeIds.indexOf(this.selectedRenderMode))
                    .value(this.renderModeOptions()[this.renderModeIds.indexOf(this.selectedRenderMode)].value)
                    .font({ size: 14 }).fontColor($r('sys.color.font_secondary')).height(48)
                    .backgroundColor(Color.Transparent)
                    .enabled(!this.isSaving).id('harmony.settings.renderMode')
                    .accessibilityText(this.text('settingsUIRenderMode'))
                    .onSelect((index: number): void => { this.saveRenderMode(index); })
                }.width('100%').constraintSize({ minHeight: 56 })
                  .padding({ left: 16, right: 12, top: 4, bottom: 4 })
              }.backgroundColor($r('sys.color.comp_background_primary'))
              this.destinationRow('settingsLanguage', '/settings/language', $r('sys.symbol.translate'), this.languageLabel())
            }.borderRadius(16).clip(true)
            ListItemGroup({ header: this.securityHeader }) {
              ForEach(this.securityEntries, (entry: HarmonySettingsEntry): void => {
                this.destinationRow(entry.titleKey, entry.route, entry.icon)
              }, (entry: HarmonySettingsEntry): string => entry.route)
            }.borderRadius(16).clip(true)
            ListItemGroup({ header: this.connectionsHeader }) {
              this.destinationRow('settingsServerManagement', '/server', $r('sys.symbol.externaldrive'))
              if (this.hasPanelSettings) {
                this.destinationRow('systemSettingsPanelSection', '/system-settings',
                  $r('sys.symbol.gearshape'), this.currentServerName)
              }
            }.borderRadius(16).clip(true)
            ListItemGroup({ header: this.helpHeader }) {
              ForEach(this.helpEntries, (entry: HarmonySettingsEntry): void => {
                this.destinationRow(entry.titleKey, entry.route, entry.icon)
              }, (entry: HarmonySettingsEntry): string => entry.route)
              ListItem() {
                Row({ space: 12 }) {
                  SymbolGlyph($r('sys.symbol.questionmark_circle')).fontSize(24)
                    .fontColor([$r('sys.color.icon_primary')])
                  Text(this.text('settingsResetOnboarding')).fontSize(16)
                    .fontColor($r('sys.color.font_primary')).layoutWeight(1)
                }.width('100%').constraintSize({ minHeight: 56 }).padding(16)
              }.backgroundColor($r('sys.color.comp_background_primary'))
                .onClick((): void => { this.resetOnboarding(); })
                .onKeyEvent((event?: KeyEvent): boolean => {
                  if (event !== undefined && event.type === KeyType.Down &&
                    (event.keyCode === KeyCode.KEYCODE_ENTER || event.keyCode === KeyCode.KEYCODE_SPACE)) {
                    this.resetOnboarding();
                    return true;
                  }
                  return false;
                })
                .focusable(true)
                .focusOnTouch(true)
                .focusBox({ margin: LengthMetrics.vp(2) })
                .hoverEffect(HoverEffect.Highlight)
            }.borderRadius(16).clip(true)
          }.width('100%').height('100%')
            .constraintSize({ maxWidth: 840 })
            .padding({ left: 16, right: 16, bottom: 24 }).contentStartOffset(72)
            .scrollBar(BarState.Auto)
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      }
    }
    .title(this.text('settingsPageTitle'), {
      barStyle: BarStyle.STACK,
      systemMaterial: titleBarMaterial,
      scrollEffectOptions: { scrollEffectType: ScrollEffectType.COMMON_BLUR },
    })
    .titleMode(NavigationTitleMode.Mini).hideBackButton(true)
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .mode(NavigationMode.Stack).width('100%').height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
