import { LengthMetrics } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { handleSettingsActivationKey } from './HarmonySettingsInteractions';

@Component
export struct HarmonyThemePage {
  @State private selectedTheme: string = 'system';
  @State private seedColor: number = 0xFF757575;
  @State private dynamicColor: boolean = false;
  @State private dynamicColorAvailable: boolean = false;
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private loadError: string = '';
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly themeIds: string[] = ['system', 'light', 'dark'];
  private readonly themeKeys: string[] = ['themeSystem', 'themeLight', 'themeDark'];
  private readonly colors: number[] = [
    0xFF757575, 0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4, 0xFF009688,
    0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39, 0xFFFFEB3B, 0xFFFFC107,
    0xFFFF9800, 0xFFFF5722, 0xFFF44336, 0xFFE91E63, 0xFF9C27B0,
    0xFF673AB7, 0xFF3F51B5, 0xFF795548, 0xFF607D8B, 0xFF9E9E9E,
  ];

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyAppearance');
      this.selectedTheme = result.get('themeMode') as string;
      this.seedColor = result.get('seedColor') as number;
      this.dynamicColor = result.get('useDynamicColor') as boolean;
      this.dynamicColorAvailable = result.get('dynamicColorAvailable') as boolean;
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async save(key: string, settingValue: string | boolean | number): Promise<void> {
    if (this.isSaving) return;
    this.isSaving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set(key, settingValue);
      await this.bridge.invoke<Object | null>('updateHarmonyAppearance', args);
      await this.bridge.refreshSettings();
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.isSaving = false;
    }
  }

  private colorLabel(color: number): string {
    return `#${(color & 0xFFFFFF).toString(16).padStart(6, '0').toUpperCase()}`;
  }

  @Builder
  private colorHeader() {
    Text(this.text('themeSeedColor')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .padding({ left: 16, top: 8, bottom: 8 })
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
          ListItemGroup() {
            ForEach(this.themeIds, (mode: string, index: number): void => {
              ListItem() {
                Row({ space: 16 }) {
                  Text(this.text(this.themeKeys[index])).fontSize(16)
                    .fontColor($r('sys.color.font_primary')).layoutWeight(1)
                  Radio({ value: mode, group: 'harmony-theme' })
                    .checked(this.selectedTheme === mode)
                    .enabled(!this.isSaving)
                    .accessibilityText(this.text(this.themeKeys[index]))
                    .onChange((checked: boolean): void => { if (checked) this.save('themeMode', mode); })
                }.constraintSize({ minHeight: 56 }).width('100%')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              }.backgroundColor($r('sys.color.comp_background_primary'))
                .onClick((): void => { if (!this.isSaving) this.save('themeMode', mode); })
                .onKeyEvent((event?: KeyEvent): boolean => handleSettingsActivationKey(
                  event,
                  (): void => { if (!this.isSaving) this.save('themeMode', mode); },
                ))
                .focusable(true)
                .focusOnTouch(true)
                .focusBox({ margin: LengthMetrics.vp(2) })
                .hoverEffect(HoverEffect.Highlight)
            }, (mode: string): string => mode)
          }.borderRadius(16).clip(true)
          if (this.dynamicColorAvailable) {
            ListItemGroup() {
              ListItem() {
                Row({ space: 16 }) {
                  Column({ space: 2 }) {
                    Text(this.text('themeDynamicColor')).fontSize(16).fontColor($r('sys.color.font_primary'))
                    Text(this.text('themeDynamicColorDesc')).fontSize(14).fontColor($r('sys.color.font_secondary'))
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Toggle({ type: ToggleType.Switch, isOn: this.dynamicColor })
                    .enabled(!this.isSaving)
                    .accessibilityText(this.text('themeDynamicColor'))
                    .onChange((checked: boolean): void => { this.save('useDynamicColor', checked); })
                }.constraintSize({ minHeight: 64 }).padding(16).width('100%')
              }.backgroundColor($r('sys.color.comp_background_primary'))
            }.borderRadius(16).clip(true)
          }
          if (!this.dynamicColorAvailable || !this.dynamicColor) {
            ListItemGroup({ header: this.colorHeader }) {
              ListItem() {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.colors, (color: number): void => {
                    Button() {
                      if (this.seedColor === color) {
                        SymbolGlyph($r('sys.symbol.checkmark')).fontSize(24).fontColor([Color.White])
                      }
                    }.width(48).height(48).borderRadius(24).margin(4)
                      .backgroundColor(color).enabled(!this.isSaving)
                      .accessibilityText(this.colorLabel(color))
                      .onClick((): void => { this.save('seedColor', color); })
                  }, (color: number): string => color.toString())
                }.padding(12).width('100%')
              }.backgroundColor($r('sys.color.comp_background_primary'))
            }.borderRadius(16).clip(true)
          }
        }.padding({ left: 16, right: 16, top: 16, bottom: 24 }).width('100%').height('100%')
      }
    }
    .title(this.text('settingsTheme'), { barStyle: BarStyle.STANDARD })
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .backgroundColor($r('sys.color.background_secondary'))
    .onShown((): void => { this.load(); })
  }
}
