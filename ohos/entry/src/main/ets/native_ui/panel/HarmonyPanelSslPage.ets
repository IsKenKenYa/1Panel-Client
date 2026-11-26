import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';
import { HarmonyPanelField } from './HarmonyPanelControls';

@Component
export struct HarmonyPanelSslPage {
  @State private loading: boolean = true;
  @State private busy: boolean = false;
  @State private loadError: string = '';
  @State private info: Map<string, Object | null> = new Map<string, Object | null>();
  @State private certificate: string = '';
  @State private privateKey: string = '';
  @State private showUpload: boolean = false;
  @State private history: string[] = [];
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.load(); }

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      this.info = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyPanelSsl');
      if (this.history.length === 0 && this.info.get('present') === true) {
        this.addHistory(this.text('panelTlsHistoryLoaded').replace('{domain}', this.domain()));
      }
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private field(key: string, labelKey: string): string {
    const value = this.info.get(key);
    return `${this.text(labelKey)}: ${value === null || value === undefined ? '—' : value.toString()}`;
  }

  private domain(): string {
    return (this.info.get('domain') as string | null) ?? '—';
  }

  private addHistory(message: string): void {
    this.history = [`${new Date().toLocaleTimeString()}  ${message}`].concat(this.history.slice(0, 4));
  }

  private notice(): string {
    switch (this.info.get('health')) {
      case 'expired':
        return this.text('panelTlsRiskExpiredMessage');
      case 'expiringSoon':
        return this.text('panelTlsRiskExpiringSoonMessage').replace('{days}', `${this.info.get('daysRemaining')}`);
      case 'unknown':
        return this.text('panelTlsRiskUnknownMessage');
      default:
        return '';
    }
  }

  private async upload(): Promise<void> {
    const cert = this.certificate.trim();
    const key = this.privateKey.trim();
    this.busy = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('cert', cert);
      args.set('key', key);
      await this.bridge.invoke<Object | null>('uploadHarmonyPanelSsl', args);
      this.showUpload = false;
      this.certificate = '';
      this.privateKey = '';
      await this.load();
      this.addHistory(this.text('panelTlsHistoryUploaded').replace('{domain}', this.domain()));
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  private async pasteKey(): Promise<void> {
    try {
      const clipboard = await this.bridge.invoke<string | null>('pasteHarmonyPanelSslKey');
      this.privateKey = clipboard?.trim() ?? '';
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private async copySummary(): Promise<void> {
    const summary = [
      this.field('domain', 'sslSettingsDomain'),
      this.field('timeout', 'sslSettingsExpiration'),
      this.field('rootPath', 'panelTlsCertificatePathLabel'),
    ].join('\n');
    const args = new Map<string, Object | null>();
    args.set('summary', summary);
    try {
      await this.bridge.invoke<Object | null>('copyHarmonyPanelSslSummary', args);
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonCopied') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  private async download(): Promise<void> {
    this.getUIContext().showAlertDialog({
      title: this.text('panelTlsDownloadDialogTitle'),
      message: this.text('panelTlsDownloadDialogMessage'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('sslSettingsDownload'),
        action: (): void => { this.saveCertificate(); },
      },
    });
  }

  private async saveCertificate(): Promise<void> {
    this.busy = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('downloadHarmonyPanelSsl');
      if (result.get('cancelled') === true) return;
      const displayName = result.get('displayName') as string;
      const message = result.get('privateFallbackUsed') === true ?
        this.text('fileSavePrivateFallback') :
        this.text('fileSaveSuccessPicker').replace('{displayName}', displayName);
      this.addHistory(this.text('panelTlsHistoryDownloaded').replace('{bytes}', `${result.get('size')}`));
      this.getUIContext().getPromptAction().showToast({ message: message });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.busy = false;
    }
  }

  @Builder
  private uploadSheet() {
    Column({ space: 16 }) {
      HarmonyPanelField({ titleKey: 'panelTlsCertificatePemLabel', fieldValue: this.certificate,
        multiline: true, changed: (value: string): void => { this.certificate = value; } })
      Button(this.text('panelTlsPrivateKeyPemLabel')).height(48).width('100%')
        .buttonStyle(ButtonStyleMode.TEXTUAL).onClick((): void => { this.pasteKey(); })
      if (this.privateKey.length > 0) {
        SymbolGlyph($r('sys.symbol.checkmark')).fontSize(20)
          .accessibilityText(this.text('panelTlsPrivateKeyPemLabel'))
      }
      Text(this.text('panelTlsApplyUpdateMessage')).fontSize(14).fontColor($r('sys.color.font_secondary'))
        .width('100%')
      Button(this.text('commonSave')).height(48).width('100%')
        .enabled(!this.busy && this.certificate.trim().length > 0 && this.privateKey.length > 0)
        .onClick((): void => { this.upload(); })
    }.width('100%').padding(24)
  }

  build() {
    NavDestination() {
      if (this.loading) {
        Column() { LoadingProgress().width(48).height(48) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError).fontSize(16).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ListItemGroup({ header: (): void => {
            Text(this.text('panelTlsCertificateTitle')).fontSize(14)
              .fontColor($r('sys.color.font_secondary')).padding({ left: 16, top: 8, bottom: 8 });
          } }) {
            ListItem() {
              Column({ space: 8 }) {
                if (this.info.get('present') === true) {
                  Text(this.field('domain', 'sslSettingsDomain')).fontSize(16)
                    .fontColor($r('sys.color.font_primary')).width('100%')
                  Text(this.field('timeout', 'sslSettingsExpiration')).fontSize(14)
                    .fontColor($r('sys.color.font_secondary')).width('100%')
                  Text(this.field('rootPath', 'panelTlsCertificatePathLabel')).fontSize(14)
                    .fontColor($r('sys.color.font_secondary')).width('100%').copyOption(CopyOptions.InApp)
                  if (this.notice().length > 0) {
                    Text(this.notice()).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
                  }
                } else {
                  Text(this.text('systemSettingsNotSet')).fontSize(16).width('100%')
                }
              }.padding(16).width('100%')
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
          if (this.history.length > 0) {
            ListItemGroup({ header: (): void => {
              Text(this.text('panelTlsHistoryTitle')).fontSize(14)
                .fontColor($r('sys.color.font_secondary')).padding({ left: 16, top: 8, bottom: 8 });
            } }) {
              ForEach(this.history, (entry: string, index: number): void => {
                ListItem() {
                  Text(entry).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%').padding(16)
                }.backgroundColor($r('sys.color.comp_background_primary'))
              }, (entry: string, index: number): string => `${index}:${entry}`)
            }.borderRadius(16).clip(true)
          }
          ListItemGroup() {
            ListItem() {
              Row({ space: 12 }) {
                Button(this.text('commonUpload')).height(48).layoutWeight(1).enabled(!this.busy)
                  .onClick((): void => { this.showUpload = true; })
                if (this.info.get('present') === true) {
                  Button(this.text('sslSettingsDownload')).height(48).layoutWeight(1).enabled(!this.busy)
                    .onClick((): void => { this.download(); })
                  Button(this.text('commonCopy')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                    .onClick((): void => { this.copySummary(); })
                }
              }.padding(16).width('100%')
            }.backgroundColor($r('sys.color.comp_background_primary'))
          }.borderRadius(16).clip(true)
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 })
      }
    }
    .title(this.text('panelTlsTitle'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .bindSheet($$this.showUpload, this.uploadSheet, {
      height: SheetSize.LARGE, showClose: true, title: { title: this.text('panelTlsUploadDialogTitle') },
      systemMaterial: sheetMaterial,
    })
    .onShown((): void => { this.load(); })
  }
}
