import { LengthMetrics } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { handleSettingsActivationKey } from './HarmonySettingsInteractions';

@Component
export struct HarmonySecurityVerificationPage {
  @Prop inTab: boolean = false;
  @State private isLoading: boolean = true;
  @State private isOpening: boolean = false;
  @State private loadError: string = '';
  @State private serverUrl: string = '';
  @State private securityEntrance: string | null = null;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const result = await this.bridge.invoke<Map<string, string | null>>('getHarmonyPanelEntrance');
      this.serverUrl = result.get('serverUrl') as string;
      this.securityEntrance = result.get('securityEntrance') as string | null;
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async openEntrance(): Promise<void> {
    this.isOpening = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('serverUrl', this.serverUrl);
      args.set('securityEntrance', this.securityEntrance);
      await this.bridge.invoke<Object | null>('openHarmonyPanelEntrance', args);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({
        message: `${this.text('aboutLinkOpenFailed')} ${(error as Error).message.slice(0, 96)}`,
      });
    } finally {
      this.isOpening = false;
    }
  }

  @Builder
  private content() {
      if (this.isLoading) {
        Column() { LoadingProgress().width(48).height(48) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        List() {
          ListItemGroup() {
            ListItem() {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.person'))
                  .fontSize(24).fontColor([$r('sys.color.icon_primary')])
                Column({ space: 4 }) {
                  Text(this.text('settingsPanelAccountSecurity')).fontSize(16)
                    .fontColor($r('sys.color.font_primary'))
                  Text(this.text('settingsPanelAccountSecurityDescription')).fontSize(14)
                    .fontColor($r('sys.color.font_secondary')).maxLines(3)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                SymbolGlyph($r('sys.symbol.link'))
                  .fontSize(18).fontColor([$r('sys.color.icon_secondary')])
              }.width('100%').padding(16).constraintSize({ minHeight: 72 })
            }.backgroundColor($r('sys.color.comp_background_primary'))
              .enabled(!this.isOpening)
              .accessibilityText(this.text('settingsPanelAccountSecurity'))
              .onClick((): void => { this.openEntrance(); })
              .onKeyEvent((event?: KeyEvent): boolean => handleSettingsActivationKey(
                event,
                (): void => { this.openEntrance(); },
              ))
              .focusable(true)
              .focusOnTouch(true)
              .focusBox({ margin: LengthMetrics.vp(2) })
              .hoverEffect(HoverEffect.Highlight)
          }.borderRadius(16).clip(true)
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 16, bottom: 24 })
      }
  }

  build() {
    if (this.inTab) {
      Navigation() { this.content() }
        .title(this.text('securityPageTitle'), { barStyle: BarStyle.STANDARD })
        .titleMode(NavigationTitleMode.Mini).hideBackButton(true)
        .mode(NavigationMode.Stack).width('100%').height('100%')
        .backgroundColor($r('sys.color.background_secondary'))
    } else {
      NavDestination() { this.content() }
        .title(this.text('securityPageTitle'), { barStyle: BarStyle.STANDARD })
        .backgroundColor($r('sys.color.background_secondary'))
    }
  }

  aboutToAppear(): void { this.load(); }
}
