import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

@Component
export struct HarmonyFeedbackPage {
  @State private isLoading: boolean = true;
  @State private isBusy: boolean = false;
  @State private loadError: string = '';
  @State private logLevel: string = '';
  @State private levelLocked: boolean = true;
  @State private levels: string[] = [];
  @State private channelTitleKey: string = '';
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string { return this.bridge.text(key); }

  private levelLabel(level: string): string {
    return this.text(`systemSettingsLogLevel${level.charAt(0).toUpperCase()}${level.slice(1)}`);
  }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyFeedback');
      this.logLevel = result.get('logLevel') as string;
      this.levelLocked = result.get('levelLocked') as boolean;
      this.levels = result.get('levels') as string[];
      this.channelTitleKey = result.get('channelTitleKey') as string;
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async perform(method: string, args?: Map<string, Object | null>, successKey?: string): Promise<void> {
    this.isBusy = true;
    try {
      await this.bridge.invoke<Object | null>(method, args);
      if (successKey !== undefined) this.getUIContext().getPromptAction().showToast({ message: this.text(successKey) });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.isBusy = false;
    }
  }

  private openIssues(): void {
    const args = new Map<string, Object | null>();
    args.set('id', 'issues');
    this.perform('openHarmonyAboutLink', args);
  }

  private copyTemplate(): void {
    const template = `${this.text('settingsFeedbackTemplateTitle')}\n\n` +
      `${this.text('settingsFeedbackTemplateSummary')}\n- \n\n` +
      `${this.text('settingsFeedbackTemplateRepro')}\n1. \n2. \n3. \n\n` +
      `${this.text('settingsFeedbackTemplateExpected')}\n- \n\n` +
      `${this.text('settingsFeedbackTemplateActual')}\n- \n\n` +
      `${this.text('settingsFeedbackTemplateLogs')}\n- \n\n` +
      `${this.text('settingsFeedbackTemplateEnvironment')}\n- channel: ${this.text(this.channelTitleKey)}\n- app: KenPanel`;
    const args = new Map<string, Object | null>();
    args.set('template', template);
    this.perform('copyHarmonyFeedbackTemplate', args, 'commonCopied');
  }

  private async setLevel(index: number): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('level', this.levels[index]);
    await this.perform('updateHarmonyLogLevel', args, 'commonSaveSuccess');
    await this.load();
  }

  private clearLogs(): void {
    this.getUIContext().showAlertDialog({
      title: this.text('systemSettingsAppLogsClearTitle'),
      message: this.text('systemSettingsAppLogsClearConfirm'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('commonConfirm'),
        action: (): void => { this.perform('clearHarmonyLogs', undefined, 'systemSettingsAppLogsCleared'); },
      },
    });
  }

  private async openPreview(): Promise<void> {
    try {
      await this.bridge.openNativePage('/settings/feedback-center/logs');
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private async exportLogs(): Promise<void> {
    this.getUIContext().showAlertDialog({
      title: this.text('settingsFeedbackLogExportWarningTitle'),
      message: this.text('settingsFeedbackLogExportWarningMessage'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('settingsFeedbackLogExportConfirm'),
        action: (): void => { this.saveLogs(); },
      },
    });
  }

  private async saveLogs(): Promise<void> {
    this.isBusy = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('format', 'humanReadable');
      const result = await this.bridge.invoke<Map<string, Object | null>>('exportHarmonyLogs', args);
      if (result.get('wasCancelled') === true) return;
      if (result.get('success') !== true) throw new Error(result.get('errorMessage') as string);
      const displayName = result.get('displayName') as string | null;
      const message = result.get('privateFallbackUsed') === true ? this.text('fileSavePrivateFallback') :
        displayName === null || displayName.length === 0 ? this.text('fileSaveSuccessDownloads') :
          this.text('fileSaveSuccessPicker').replace('{displayName}', displayName);
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.isBusy = false;
    }
  }

  @Builder
  private heading(key: string) {
    Text(this.text(key)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private actionRow(titleKey: string, descriptionKey: string, icon: Resource, action: () => void) {
    ListItem() {
      Button({ type: ButtonType.Normal }) {
        Row({ space: 16 }) {
          SymbolGlyph(icon).fontSize(24).fontColor([$r('sys.color.icon_primary')])
          Column({ space: 4 }) {
            Text(this.text(titleKey)).fontSize(16).fontColor($r('sys.color.font_primary'))
            Text(this.text(descriptionKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.icon_tertiary')])
        }.padding(16).width('100%').constraintSize({ minHeight: 72 })
      }.width('100%').borderRadius(0).backgroundColor($r('sys.color.comp_background_primary'))
        .enabled(!this.isBusy).onClick(action).accessibilityText(this.text(titleKey))
    }
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
          ListItemGroup({ header: this.heading('settingsFeedback') }) {
            this.actionRow('aboutFeedbackAction', 'settingsFeedbackIssueSubtitle', $r('sys.symbol.message'), (): void => { this.openIssues(); })
            this.actionRow('settingsFeedbackCopyTemplate', 'settingsFeedbackTemplateHint', $r('sys.symbol.text_clipboard'), (): void => { this.copyTemplate(); })
          }.borderRadius(16).clip(true)
          ListItemGroup({ header: this.heading('settingsFeedbackLogsTitle') }) {
            this.actionRow('systemSettingsAppLogsPreviewButton', 'systemSettingsAppLogsPreviewSubtitle', $r('sys.symbol.doc_text_badge_magnifyingglass'), (): void => { this.openPreview(); })
            ListItem() {
              Row({ space: 16 }) {
                SymbolGlyph($r('sys.symbol.slider_horizontal_2')).fontSize(24).fontColor([$r('sys.color.icon_primary')])
                Column({ space: 4 }) {
                  Text(this.text('systemSettingsAppLogsLevelTitle')).fontSize(16).fontColor($r('sys.color.font_primary'))
                  if (this.levelLocked) {
                    Text(this.text('systemSettingsAppLogsLevelLocked')).fontSize(14).fontColor($r('sys.color.font_secondary'))
                  }
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Select(this.levels.map((level: string): SelectOption => ({ value: this.levelLabel(level) })))
                  .selected(this.levels.indexOf(this.logLevel)).value(this.levelLabel(this.logLevel)).height(48)
                  .enabled(!this.levelLocked && !this.isBusy)
                  .onSelect((index: number): void => { this.setLevel(index); })
              }.padding(16).width('100%').constraintSize({ minHeight: 72 })
            }.backgroundColor($r('sys.color.comp_background_primary'))
            this.actionRow('commonExport', 'systemSettingsAppLogsExportSubtitle', $r('sys.symbol.arrow_down_circle'), (): void => { this.exportLogs(); })
            this.actionRow('commonClear', 'systemSettingsAppLogsClearSubtitle', $r('sys.symbol.trash'), (): void => { this.clearLogs(); })
          }.borderRadius(16).clip(true)
        }.padding({ left: 16, right: 16, top: 16, bottom: 24 }).width('100%').height('100%')
      }
    }
    .title(this.text('settingsFeedbackCenterTitle'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .onShown((): void => { this.load(); })
  }
}
