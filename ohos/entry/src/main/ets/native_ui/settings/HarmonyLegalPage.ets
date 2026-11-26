import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { handleSettingsActivationKey } from './HarmonySettingsInteractions';

@Component
export struct HarmonyLegalPage {
  @State private currentSection: string = 'documents';
  @State private isLoading: boolean = true;
  @State private loadError: string = '';
  @State private documents: Map<string, string>[] = [];
  @State private packages: string[] = [];
  @State private selectedPackage: string = '';
  @State private licenseTexts: string[] = [];
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.loadDocuments(); }

  private text(key: string): string { return this.bridge.text(key); }

  private pageTitle(): string {
    if (this.currentSection === 'packages') return this.text('settingsLegalFlutterPackages');
    if (this.currentSection === 'license') return this.selectedPackage;
    return this.text('settingsLegalCenterTitle');
  }

  private async loadDocuments(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      this.documents = await this.bridge.invoke<Map<string, string>[]>('getHarmonyLegalDocuments');
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async loadPackages(refresh: boolean = false): Promise<void> {
    this.currentSection = 'packages';
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

  private async loadLicense(packageName: string): Promise<void> {
    this.selectedPackage = packageName;
    this.currentSection = 'license';
    this.isLoading = true;
    this.loadError = '';
    const args = new Map<string, Object | null>();
    args.set('package', packageName);
    try {
      this.licenseTexts = await this.bridge.invoke<string[]>('getHarmonyPackageLicenses', args);
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private retry(): void {
    if (this.currentSection === 'packages') {
      this.loadPackages(true);
    } else if (this.currentSection === 'license') {
      this.loadLicense(this.selectedPackage);
    } else {
      this.loadDocuments();
    }
  }

  private goBack(): boolean {
    if (this.currentSection === 'documents') return false;
    this.currentSection = this.currentSection === 'license' ? 'packages' : 'documents';
    this.loadError = '';
    this.isLoading = false;
    return true;
  }

  private async openDocument(documentId: string): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('id', documentId);
    try {
      await this.bridge.invoke<Object | null>('openHarmonyLegalDocument', args);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private async openSdkDisclosure(): Promise<void> {
    try {
      await this.bridge.openNativePage('/settings/legal-center/mainland-sdk');
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private pageMenus(): NavigationMenuItem[] {
    if (this.currentSection !== 'packages') return [];
    return [{
      value: this.text('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !this.isLoading,
      action: (): void => { this.loadPackages(true); },
    }];
  }

  @Builder
  private documentHeader() {
    Text(this.text('settingsLegalDocumentsTitle')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .width('100%').padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private documentList() {
    List({ space: 16 }) {
      ListItemGroup({ header: this.documentHeader }) {
        ForEach(this.documents, (document: Map<string, string>): void => {
          ListItem() {
            Row({ space: 12 }) {
              SymbolGlyph($r('sys.symbol.doc_text')).fontSize(24).fontColor([$r('sys.color.icon_primary')])
              Text(this.text(document.get('titleKey') as string)).fontSize(16)
                .fontColor($r('sys.color.font_primary')).layoutWeight(1)
              SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
            }.constraintSize({ minHeight: 56 }).width('100%').padding(16)
          }.backgroundColor($r('sys.color.comp_background_primary'))
            .id(`harmony.legal.${document.get('id') as string}`)
            .onClick((): void => { this.openDocument(document.get('id') as string); })
            .onKeyEvent((event?: KeyEvent): boolean => handleSettingsActivationKey(
              event,
              (): void => { this.openDocument(document.get('id') as string); },
            ))
            .focusable(true)
            .focusOnTouch(true)
            .focusBox({ margin: LengthMetrics.vp(2) })
            .hoverEffect(HoverEffect.Highlight)
        }, (document: Map<string, string>): string => document.get('id') as string)
        ListItem() {
          Row({ space: 12 }) {
            Text(this.text('settingsLegalFlutterPackages')).fontSize(16)
              .fontColor($r('sys.color.font_primary')).layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
          }.constraintSize({ minHeight: 56 }).width('100%').padding(16)
        }.backgroundColor($r('sys.color.comp_background_primary'))
          .id('harmony.legal.packages').onClick((): void => { this.loadPackages(); })
          .onKeyEvent((event?: KeyEvent): boolean => handleSettingsActivationKey(
            event,
            (): void => { this.loadPackages(); },
          ))
          .focusable(true)
          .focusOnTouch(true)
          .focusBox({ margin: LengthMetrics.vp(2) })
          .hoverEffect(HoverEffect.Highlight)
      }.borderRadius(16).clip(true)
      ListItemGroup() {
        ListItem() {
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text(this.text('settingsMainlandSdkDisclosureTitle')).fontSize(16)
                .fontColor($r('sys.color.font_primary'))
              Text(this.text('settingsMainlandSdkDisclosureSubtitle')).fontSize(14)
                .fontColor($r('sys.color.font_secondary'))
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
          }.constraintSize({ minHeight: 64 }).width('100%').padding(16)
        }.backgroundColor($r('sys.color.comp_background_primary'))
          .id('harmony.legal.sdk').onClick((): void => { this.openSdkDisclosure(); })
          .onKeyEvent((event?: KeyEvent): boolean => handleSettingsActivationKey(
            event,
            (): void => { this.openSdkDisclosure(); },
          ))
          .focusable(true)
          .focusOnTouch(true)
          .focusBox({ margin: LengthMetrics.vp(2) })
          .hoverEffect(HoverEffect.Highlight)
      }.borderRadius(16).clip(true)
    }.width('100%').height('100%').padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .scrollBar(BarState.Auto)
  }

  @Builder
  private packageList() {
    List() {
      if (this.packages.length === 0) {
        ListItem() {
          Text(this.text('settingsMainlandSdkAutoScanEmpty')).fontSize(16)
            .fontColor($r('sys.color.font_secondary')).padding(16)
        }
      }
      ForEach(this.packages, (packageName: string): void => {
        ListItem() {
          Row({ space: 12 }) {
            Text(packageName).fontSize(16).fontColor($r('sys.color.font_primary')).layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
          }.constraintSize({ minHeight: 56 }).width('100%').padding(16)
        }.backgroundColor($r('sys.color.comp_background_primary'))
          .id(`harmony.legal.package.${packageName}`)
          .onClick((): void => { this.loadLicense(packageName); })
          .onKeyEvent((event?: KeyEvent): boolean => handleSettingsActivationKey(
            event,
            (): void => { this.loadLicense(packageName); },
          ))
          .focusable(true)
          .focusOnTouch(true)
          .focusBox({ margin: LengthMetrics.vp(2) })
          .hoverEffect(HoverEffect.Highlight)
      }, (packageName: string): string => packageName)
    }.width('100%').height('100%').padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .divider({ strokeWidth: 0.5, color: $r('sys.color.comp_divider'), startMargin: 16, endMargin: 16 })
      .scrollBar(BarState.Auto)
  }

  @Builder
  private licenseContent() {
    List({ space: 16 }) {
      ForEach(this.licenseTexts, (licenseText: string): void => {
        ListItem() {
          Text(licenseText).fontSize(14).lineHeight(22).fontColor($r('sys.color.font_primary'))
            .copyOption(CopyOptions.LocalDevice).width('100%').padding(16)
        }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      }, (licenseText: string): string => licenseText)
    }.width('100%').height('100%').padding({ left: 16, right: 16, top: 8, bottom: 24 })
      .scrollBar(BarState.Auto)
  }

  build() {
    NavDestination() {
      if (this.isLoading) {
        Column() { LoadingProgress().width(48).height(48) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.retry(); })
        }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.currentSection === 'packages') {
        this.packageList()
      } else if (this.currentSection === 'license') {
        this.licenseContent()
      } else {
        this.documentList()
      }
    }.title(this.pageTitle(), { barStyle: BarStyle.STANDARD })
      .menus(this.pageMenus()).onBackPressed((): boolean => this.goBack())
      .backgroundColor($r('sys.color.background_secondary'))
  }
}
