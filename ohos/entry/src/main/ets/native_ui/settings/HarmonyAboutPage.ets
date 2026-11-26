import { LengthMetrics } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { handleActivationKey } from '../HarmonyInteractionUtils';

interface HarmonyAboutField {
  labelKey: string;
  dataKey: string;
  copyField: string;
}

@Component
export struct HarmonyAboutPage {
  @State private isLoading: boolean = true;
  @State private loadError: string = '';
  @State private aboutInfo: Map<string, string> = new Map<string, string>();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly buildFields: HarmonyAboutField[] = [
    { labelKey: 'aboutVersionLabel', dataKey: 'version', copyField: '' },
    { labelKey: 'aboutBuildLabel', dataKey: 'buildNumber', copyField: '' },
    { labelKey: 'aboutPackageNameLabel', dataKey: 'packageName', copyField: '' },
    { labelKey: 'aboutChannelLabel', dataKey: 'channelKey', copyField: '' },
    { labelKey: 'aboutBranchLabel', dataKey: 'branch', copyField: 'branch' },
    { labelKey: 'aboutCommitLabel', dataKey: 'shortCommit', copyField: 'commit' },
    { labelKey: 'aboutBuildDateLabel', dataKey: 'buildDate', copyField: 'buildDate' },
    { labelKey: 'aboutOfficialDomainLabel', dataKey: 'officialDomainName', copyField: 'domain' },
  ];

  aboutToAppear(): void { this.loadAbout(); }

  private text(key: string): string { return this.bridge.text(key); }

  private info(key: string): string { return this.aboutInfo.get(key) ?? ''; }

  private displayField(field: HarmonyAboutField): string {
    const content = this.info(field.dataKey);
    return field.dataKey === 'channelKey' ? this.text(content) : content.length > 0 ? content : '—';
  }

  private async loadAbout(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      this.aboutInfo = await this.bridge.invoke<Map<string, string>>('getHarmonyAboutInfo');
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async openLink(linkId: string): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('id', linkId);
    try {
      await this.bridge.invoke<Object | null>('openHarmonyAboutLink', args);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private async copyField(fieldName: string): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('field', fieldName);
    try {
      await this.bridge.invoke<Object | null>('copyHarmonyAboutField', args);
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonCopySuccess') });
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
  private buildHeader() { this.sectionHeader('aboutBuildSectionTitle') }

  @Builder
  private projectHeader() { this.sectionHeader('aboutProjectSectionTitle') }

  @Builder
  private releaseHeader() { this.sectionHeader('aboutReleaseNotesSectionTitle') }

  @Builder
  private repositoryHeader() { this.sectionHeader('aboutRepositorySectionTitle') }

  @Builder
  private infoRow(field: HarmonyAboutField) {
    ListItem() {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(this.text(field.labelKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
          Text(this.displayField(field)).fontSize(16).fontColor($r('sys.color.font_primary'))
            .copyOption(CopyOptions.LocalDevice)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        if (field.copyField.length > 0 && this.info(field.dataKey).length > 0) {
          Button(this.text('commonCopy'), { buttonStyle: ButtonStyleMode.TEXTUAL })
            .height(48).constraintSize({ minWidth: 48 })
            .accessibilityText(`${this.text('commonCopy')} ${this.text(field.labelKey)}`)
            .onClick((): void => { this.copyField(field.copyField); })
        }
      }.width('100%').constraintSize({ minHeight: 64 }).padding({ left: 16, right: 8, top: 8, bottom: 8 })
    }.backgroundColor($r('sys.color.comp_background_primary'))
      .id(`harmony.about.${field.dataKey}`)
  }

  @Builder
  private linkRow(titleKey: string, linkId: string, subtitle: string = '') {
    ListItem() {
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary'))
          if (subtitle.length > 0) {
            Text(subtitle).fontSize(14).fontColor($r('sys.color.font_secondary'))
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([$r('sys.color.icon_tertiary')])
      }.width('100%').constraintSize({ minHeight: 56 }).padding(16)
    }.backgroundColor($r('sys.color.comp_background_primary'))
      .id(`harmony.about.link.${linkId}`)
      .accessibilityText(`${this.text(titleKey)} ${subtitle}`)
      .onClick((): void => { this.openLink(linkId); })
      .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
        event,
        (): void => { this.openLink(linkId); },
      ))
      .focusable(true)
      .focusOnTouch(true)
      .focusBox({ margin: LengthMetrics.vp(2) })
      .hoverEffect(HoverEffect.Highlight)
  }

  build() {
    NavDestination() {
      if (this.isLoading) {
        Column() { LoadingProgress().width(48).height(48) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.loadAbout(); })
        }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        List({ space: 16 }) {
          ListItem() {
            Column({ space: 12 }) {
              Image($r('app.media.icon')).width(80).height(80).borderRadius(20)
                .accessibilityLevel('no')
              Text(this.text('appName')).fontSize(24).fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.font_primary'))
              Text(`${this.info('version')} (${this.info('buildNumber')})`).fontSize(14)
                .fontColor($r('sys.color.font_secondary'))
              Button(this.info('officialDomainName'), { buttonStyle: ButtonStyleMode.TEXTUAL })
                .height(48).onClick((): void => { this.openLink('official'); })
            }.width('100%').padding({ top: 24, bottom: 8 })
          }
          ListItemGroup({ header: this.buildHeader }) {
            ForEach(this.buildFields, (field: HarmonyAboutField): void => {
              this.infoRow(field)
            }, (field: HarmonyAboutField): string => field.dataKey)
          }.borderRadius(16).clip(true)
          ListItemGroup({ header: this.projectHeader }) {
            ListItem() {
              Column({ space: 12 }) {
                Text(this.text('aboutProjectSummary')).fontSize(16).fontColor($r('sys.color.font_primary'))
                Text(this.text('aboutProjectFeatureList')).fontSize(14).fontColor($r('sys.color.font_secondary'))
              }.alignItems(HorizontalAlign.Start).width('100%').padding(16)
            }.backgroundColor($r('sys.color.comp_background_primary'))
            this.linkRow('aboutFeedbackAction', 'issues', this.text('aboutFeedbackHint'))
          }.borderRadius(16).clip(true)
          ListItemGroup({ header: this.releaseHeader }) {
            this.linkRow('aboutReleaseAction', 'releases', this.text('aboutReleaseNotesBody'))
          }.borderRadius(16).clip(true)
          ListItemGroup({ header: this.repositoryHeader }) {
            this.linkRow('aboutRepositoryHttpsLabel', 'repository', this.info('repoHttps'))
            ListItem() {
              Row({ space: 12 }) {
                Column({ space: 4 }) {
                  Text(this.text('aboutRepositorySshLabel')).fontSize(16).fontColor($r('sys.color.font_primary'))
                  Text(this.info('repoSsh')).fontSize(14).fontColor($r('sys.color.font_secondary'))
                    .copyOption(CopyOptions.LocalDevice)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Button(this.text('commonCopy'), { buttonStyle: ButtonStyleMode.TEXTUAL })
                  .height(48).constraintSize({ minWidth: 48 })
                  .onClick((): void => { this.copyField('repoSsh'); })
              }.width('100%').constraintSize({ minHeight: 64 }).padding({ left: 16, right: 8, top: 8, bottom: 8 })
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
        }.width('100%').height('100%').padding({ left: 16, right: 16, bottom: 24 })
          .scrollBar(BarState.Auto)
      }
    }.title(this.text('aboutPageTitle'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
