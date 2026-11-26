import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

interface HarmonyOnboardingSlide {
  titleKey: string;
  descriptionKey: string;
  symbol: Resource;
}

@Component
export struct HarmonyEntryPage {
  @Prop @Watch('entryChanged') entryPage: string = '';
  @StorageLink('harmonyEntryTitle') private entryTitle: string = '';
  @StorageLink('harmonyEntryMessage') private entryMessage: string = '';
  @StorageLink('harmonyEntryRequireConsent') private requireConsent: boolean = false;
  @StorageLink('harmonyAppLockBusy') private appLockBusy: boolean = false;
  @StorageLink('harmonyAppLockError') private appLockError: string = '';
  @StorageLink('harmonyThemeMode') private themeMode: string = 'system';
  @StorageLink('harmonyNativeRefresh') @Watch('loadTranslations') private revision: number = 0;
  @State private translationsReady: boolean = false;
  @State private translationError: string = '';
  @State private actionError: string = '';
  @State private pendingAction: boolean = false;
  @State private consentAccepted: boolean = false;
  @State private currentSlide: number = 0;
  private readonly swiper: SwiperController = new SwiperController();
  private readonly slides: HarmonyOnboardingSlide[] = [
    { titleKey: 'onboardingTitle1', descriptionKey: 'onboardingDesc1', symbol: $r('sys.symbol.externaldrive') },
    { titleKey: 'onboardingTitle2', descriptionKey: 'onboardingDesc2', symbol: $r('sys.symbol.square_stack_3d') },
    { titleKey: 'onboardingTitle3', descriptionKey: 'onboardingDesc3',
      symbol: $r('sys.symbol.gauge_with_dots_needle_33percent') },
    { titleKey: 'onboardingTitle4', descriptionKey: 'onboardingDesc4', symbol: $r('sys.symbol.key') },
  ];

  aboutToAppear(): void {
    this.loadTranslations();
  }

  private async loadTranslations(): Promise<void> {
    this.translationsReady = false;
    try {
      await HarmonyNativeBridge.instance.loadTranslations();
      this.translationError = '';
      this.translationsReady = true;
    } catch (error) {
      this.translationError = (error as Error).message;
    }
  }

  private entryChanged(): void {
    this.actionError = '';
    this.consentAccepted = false;
    this.currentSlide = 0;
  }

  private text(key: string): string {
    return HarmonyNativeBridge.instance.text(key);
  }

  private colorMode(): ThemeColorMode {
    if (this.themeMode === 'dark') return ThemeColorMode.DARK;
    if (this.themeMode === 'light') return ThemeColorMode.LIGHT;
    return ThemeColorMode.SYSTEM;
  }

  private async runAction(action: string): Promise<void> {
    if (this.pendingAction) return;
    this.pendingAction = true;
    this.actionError = '';
    try {
      await HarmonyNativeBridge.instance.entryAction(this.entryPage, action);
    } catch (error) {
      this.actionError = (error as Error).message;
    } finally {
      this.pendingAction = false;
    }
  }

  @Builder
  private loadingView() {
    Column({ space: 16 }) {
      Image($r('app.media.icon'))
        .width(80)
        .height(80)
        .borderRadius(20)
        .accessibilityLevel('no')
      if (this.translationsReady) {
        Text(this.text('appName'))
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      LoadingProgress()
        .width(28)
        .height(28)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  private slideView(slide: HarmonyOnboardingSlide) {
    Scroll() {
      Column({ space: 18 }) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph(slide.symbol)
            .fontSize(48)
            .fontColor([$r('sys.color.font_primary')])
            .accessibilityLevel('no')
        }
        .width(88)
        .height(88)
        .borderRadius(24)
        .backgroundColor($r('sys.color.comp_background_primary'))
        Text(this.text(slide.titleKey))
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)
        Text(this.text(slide.descriptionKey))
          .fontSize(16)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 16, bottom: 48 })
    }
    .align(Alignment.Center)
    .scrollBar(BarState.Off)
  }

  @Builder
  private onboardingView() {
    Column({ space: 16 }) {
      Row() {
        Button(this.text('onboardingSkip'), { buttonStyle: ButtonStyleMode.TEXTUAL })
          .constraintSize({ minHeight: 48 })
          .enabled(!this.pendingAction)
          .onClick((): void => { this.runAction('skip'); })
      }
      .justifyContent(FlexAlign.End)
      .width('100%')
      Swiper(this.swiper) {
        ForEach(this.slides, (slide: HarmonyOnboardingSlide): void => {
          this.slideView(slide)
        }, (slide: HarmonyOnboardingSlide): string => slide.titleKey)
      }
      .loop(false)
      .index(this.currentSlide)
      .onChange((index: number): void => { this.currentSlide = index; })
      .layoutWeight(1)
      .width('100%')
      if (this.actionError.length > 0) {
        Text(this.actionError)
          .fontColor($r('sys.color.font_primary'))
      }
      Button(this.text(this.currentSlide === this.slides.length - 1 ? 'onboardingStart' : 'onboardingNext'))
        .constraintSize({ minHeight: 48 })
        .width('100%')
        .enabled(!this.pendingAction)
        .onClick((): void => {
          if (this.currentSlide === this.slides.length - 1) {
            this.runAction('start');
          } else {
            this.swiper.showNext();
          }
        })
    }
    .width('100%')
    .constraintSize({ maxWidth: 480 })
    .layoutWeight(1)
  }

  @Builder
  private warningView() {
    Scroll() {
      Column({ space: 16 }) {
        SymbolGlyph($r('sys.symbol.warning'))
          .fontSize(38)
          .fontColor([$r('sys.color.font_primary')])
          .accessibilityLevel('no')
        Text(this.entryTitle)
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Text(this.text('testingWarningDialogBody'))
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
        ForEach(['testingWarningRiskUnstable', 'testingWarningRiskDataLoss', 'testingWarningRiskNoProd'],
          (key: string): void => {
            Text(this.text(key))
              .fontSize(16)
              .fontColor($r('sys.color.font_secondary'))
          }, (key: string): string => key)
        if (this.requireConsent) {
          Row({ space: 12 }) {
            Checkbox({ name: 'testingWarningConsent' })
              .select(this.consentAccepted)
              .responseRegion({ x: -12, y: -12, width: 48, height: 48 })
              .accessibilityText(this.text('testingWarningConsentText'))
              .onChange((checked: boolean): void => { this.consentAccepted = checked; })
            Text(this.text('testingWarningConsentText'))
              .fontSize(16)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
              .accessibilityLevel('no')
              .onClick((): void => { this.consentAccepted = !this.consentAccepted; })
          }
          .constraintSize({ minHeight: 48 })
          .padding({ left: 12 })
        }
        if (this.actionError.length > 0) {
          Text(this.actionError)
            .fontColor($r('sys.color.font_primary'))
        }
        Button(this.text(this.requireConsent ? 'testingWarningAgreeAndContinue' : 'testingWarningContinue'))
          .constraintSize({ minHeight: 48 })
          .width('100%')
          .enabled((!this.requireConsent || this.consentAccepted) && !this.pendingAction)
          .onClick((): void => { this.runAction('continue'); })
        Button(this.text('testingWarningExit'), { buttonStyle: ButtonStyleMode.TEXTUAL })
          .constraintSize({ minHeight: 48 })
          .width('100%')
          .enabled(!this.pendingAction)
          .onClick((): void => { this.runAction('exit'); })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 20, bottom: 20 })
    }
    .align(Alignment.Center)
    .width('100%')
    .constraintSize({ maxWidth: 480 })
    .layoutWeight(1)
  }

  @Builder
  private lockView() {
    Scroll() {
      Column({ space: 16 }) {
        SymbolGlyph($r('sys.symbol.lock'))
          .fontSize(48)
          .fontColor([$r('sys.color.font_primary')])
          .accessibilityLevel('no')
        Text(this.entryPage === 'appLock' ? this.text('appLockTitle') : this.entryTitle)
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)
        if (this.entryPage === 'appLock' && this.appLockError.length > 0) {
          Text(this.appLockError)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
        } else if (this.entryPage !== 'appLock' && this.entryMessage.length > 0) {
          Text(this.entryMessage)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
        }
        if (this.actionError.length > 0) {
          Text(this.actionError)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Center)
        }
        Button(this.text(this.entryPage === 'appLock' ? 'appLockUnlockAction' : 'commonRetry'))
          .constraintSize({ minHeight: 48 })
          .width('100%')
          .enabled(!this.pendingAction && !this.appLockBusy)
          .onClick((): void => {
            this.runAction(this.entryPage === 'appLock' ? 'unlock' : 'retry');
          })
        if (this.entryPage === 'authRetry') {
          Button(this.text('commonCancel'), { buttonStyle: ButtonStyleMode.TEXTUAL })
            .constraintSize({ minHeight: 48 })
            .enabled(!this.pendingAction)
            .onClick((): void => { this.runAction('cancel'); })
        }
      }
      .width('100%')
      .padding({ top: 20, bottom: 20 })
    }
    .align(Alignment.Center)
    .width('100%')
    .constraintSize({ maxWidth: 400 })
    .layoutWeight(1)
  }

  build() {
    WithTheme({ colorMode: this.colorMode() }) {
      Column({ space: 16 }) {
        if (this.translationError.length > 0) {
          Text(this.translationError)
            .fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry'))
            .constraintSize({ minHeight: 48 })
            .onClick((): void => { this.loadTranslations(); })
        } else if (this.entryPage === 'loading' || !this.translationsReady) {
          this.loadingView()
        } else if (this.entryPage === 'onboarding') {
          this.onboardingView()
        } else if (this.entryPage === 'warning') {
          this.warningView()
        } else {
          this.lockView()
        }
      }
      .padding(24)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
  }
}
