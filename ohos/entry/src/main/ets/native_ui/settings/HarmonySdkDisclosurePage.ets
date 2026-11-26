import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

@Component
export struct HarmonySdkDisclosurePage {
  @State private isLoading: boolean = true;
  @State private loadError: string = '';
  @State private packages: string[] = [];
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.loadPackages(); }

  private text(key: string): string { return this.bridge.text(key); }

  private async loadPackages(refresh: boolean = false): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    const args = new Map<string, Object | null>();
    args.set('refresh', refresh);
    try {
      this.packages = await this.bridge.invoke<string[]>('getHarmonyLicensePackages', args);
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private pageMenus(): NavigationMenuItem[] {
    return [{
      value: this.text('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !this.isLoading,
      action: (): void => { this.loadPackages(true); },
    }];
  }

  @Builder
  private packageHeader() {
    Text(this.text('settingsMainlandSdkAutoScanTitle')).fontSize(14)
      .fontColor($r('sys.color.font_secondary')).width('100%')
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  build() {
    NavDestination() {
      if (this.isLoading) {
        Column() { LoadingProgress().width(48).height(48) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.loadPackages(true); })
        }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        List({ space: 16 }) {
          ListItemGroup() {
            ListItem() {
              Text(this.text('settingsMainlandSdkNone')).fontSize(16)
                .fontColor($r('sys.color.font_primary')).width('100%').padding(16)
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
          ListItemGroup({ header: this.packageHeader }) {
            if (this.packages.length === 0) {
              ListItem() {
                Text(this.text('settingsMainlandSdkAutoScanEmpty')).fontSize(16)
                  .fontColor($r('sys.color.font_secondary')).padding(16)
              }.backgroundColor($r('sys.color.comp_background_primary'))
            }
            ForEach(this.packages, (packageName: string): void => {
              ListItem() {
                Text(packageName).fontSize(16).fontColor($r('sys.color.font_primary'))
                  .constraintSize({ minHeight: 48 }).width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                  .copyOption(CopyOptions.LocalDevice)
              }.backgroundColor($r('sys.color.comp_background_primary'))
                .id(`harmony.sdk.${packageName}`)
            }, (packageName: string): string => packageName)
          }.borderRadius(16).clip(true)
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 8, bottom: 24 })
          .scrollBar(BarState.Auto)
      }
    }.title(this.text('settingsMainlandSdkDisclosureTitle'), { barStyle: BarStyle.STANDARD })
      .menus(this.pageMenus()).backgroundColor($r('sys.color.background_secondary'))
  }
}
