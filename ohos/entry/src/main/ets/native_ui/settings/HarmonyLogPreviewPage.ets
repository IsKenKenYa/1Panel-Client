import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

@Component
export struct HarmonyLogPreviewPage {
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private loadError: string = '';
  @State private humanPreview: string = '';
  @State private aiPreview: string = '';
  @State private selectedTab: number = 0;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('format', 'humanReadable');
      this.humanPreview = await this.bridge.invoke<string>('getHarmonyLogPreview', args);
      args.set('format', 'aiAgent');
      this.aiPreview = await this.bridge.invoke<string>('getHarmonyLogPreview', args);
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private confirmExport(): void {
    this.getUIContext().showAlertDialog({
      title: this.text('settingsFeedbackLogExportWarningTitle'),
      message: this.text('settingsFeedbackLogExportWarningMessage'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('settingsFeedbackLogExportConfirm'),
        action: (): void => { this.exportLogs(); },
      },
    });
  }

  private async exportLogs(): Promise<void> {
    this.isSaving = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('format', this.selectedTab === 0 ? 'humanReadable' : 'aiAgent');
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
      this.isSaving = false;
    }
  }

  @Builder
  private preview(content: string) {
    Scroll() {
      Text(content.trim().length > 0 ? content : this.text('systemSettingsAppLogsPreviewEmpty'))
        .fontSize(14).fontFamily('monospace').fontColor($r('sys.color.font_primary'))
        .copyOption(CopyOptions.LocalDevice).width('100%').padding(16)
    }.width('100%').height('100%').align(Alignment.TopStart)
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        if (this.isLoading) {
          LoadingProgress().width(48).height(48).layoutWeight(1)
        } else if (this.loadError.length > 0) {
          Column({ space: 16 }) {
            Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
            Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
          }.padding(24).layoutWeight(1)
        } else {
          Tabs({ index: this.selectedTab }) {
            TabContent() { this.preview(this.humanPreview) }
              .tabBar(this.text('systemSettingsAppLogsPreviewTabHuman'))
            TabContent() { this.preview(this.aiPreview) }
              .tabBar(this.text('systemSettingsAppLogsPreviewTabAi'))
          }.layoutWeight(1).width('100%')
            .onChange((index: number): void => { this.selectedTab = index; })
        }
        Button(this.text('systemSettingsAppLogsPreviewSave')).height(48).width('100%')
          .enabled(!this.isLoading && !this.isSaving && this.loadError.length === 0)
          .onClick((): void => { this.confirmExport(); })
      }.padding({ left: 16, right: 16, top: 8, bottom: 24 }).width('100%').height('100%')
    }
    .title(this.text('systemSettingsAppLogsPreviewButton'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .onShown((): void => { this.load(); })
  }
}
