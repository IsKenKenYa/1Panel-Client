import { LengthMetrics } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { handleActivationKey } from '../HarmonyInteractionUtils';

@Component
export struct HarmonyLanguagePage {
  @State private selectedLanguage: string = 'system';
  @State private isSaving: boolean = false;
  @State private loadError: string = '';
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly languageIds: string[] = ['system', 'zh', 'en'];
  private readonly languageKeys: string[] = ['languageSystem', 'languageZh', 'languageEn'];

  private async load(): Promise<void> {
    try {
      const settings = await this.bridge.invoke<Map<string, Object | null>>('getSettings');
      this.selectedLanguage = settings.get('language') as string;
      this.loadError = '';
    } catch (error) {
      this.loadError = (error as Error).message;
    }
  }

  private async save(language: string): Promise<void> {
    if (this.isSaving || this.selectedLanguage === language) return;
    this.isSaving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('key', 'language');
      args.set('value', language);
      const result = await this.bridge.invoke<Map<string, Object | null>>('updateSetting', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.selectedLanguage = language;
      await this.bridge.refreshSettings();
      await this.bridge.loadTranslations();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    NavDestination() {
      List() {
        if (this.loadError.length > 0) {
          ListItem() {
            Column({ space: 12 }) {
              Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
              Button(this.bridge.text('commonRetry')).height(48)
                .onClick((): void => { this.load(); })
            }.width('100%').padding(16)
          }
        }
        ListItemGroup() {
          ForEach(this.languageIds, (language: string, index: number): void => {
            ListItem() {
              Row({ space: 16 }) {
                Text(this.bridge.text(this.languageKeys[index])).fontSize(16)
                  .fontColor($r('sys.color.font_primary')).layoutWeight(1)
                Radio({ value: language, group: 'harmony-language' })
                  .checked(this.selectedLanguage === language)
                  .enabled(!this.isSaving)
                  .accessibilityText(this.bridge.text(this.languageKeys[index]))
                  .onChange((checked: boolean): void => { if (checked) this.save(language); })
              }.constraintSize({ minHeight: 56 }).width('100%').padding(16)
            }.backgroundColor($r('sys.color.comp_background_primary'))
              .onClick((): void => { if (!this.isSaving) this.save(language); })
              .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
                event,
                (): void => { if (!this.isSaving) this.save(language); },
              ))
              .focusable(true)
              .focusOnTouch(true)
              .focusBox({ margin: LengthMetrics.vp(2) })
              .hoverEffect(HoverEffect.Highlight)
          }, (language: string): string => language)
        }.borderRadius(16).clip(true)
      }.padding(16).width('100%').height('100%')
    }
    .title(this.bridge.text('settingsLanguage'), { barStyle: BarStyle.STANDARD })
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .backgroundColor($r('sys.color.background_secondary'))
    .onShown((): void => { this.load(); })
  }
}
