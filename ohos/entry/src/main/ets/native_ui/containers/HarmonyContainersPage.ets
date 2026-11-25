import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

class HarmonyContainerItem {
  id: string;
  name: string;
  image: string;
  status: string;
  state: string;

  constructor(data: Map<string, Object | null>) {
    this.id = data.get('id') as string;
    this.name = data.get('name') as string;
    this.image = data.get('image') as string;
    this.status = data.get('status') as string;
    this.state = data.get('state') as string;
  }
}

@Component
export struct HarmonyContainersPage {
  @State private containers: HarmonyContainerItem[] = [];
  @State private loading: boolean = false;
  @State private hasServer: boolean = false;
  @State private errorMessage: string = '';
  @State private detailItems: HarmonyContainerItem[] = [];
  @State private detailVisible: boolean = false;
  @State private operationPending: boolean = false;
  @State private logsLoading: boolean = false;
  @State private logsLoaded: boolean = false;
  @State private logText: string = '';
  @State private logError: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.load();
  }

  private label(key: string): string {
    return this.bridge.text(key);
  }

  private async load(): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    this.errorMessage = '';
    try {
      const server = await this.bridge.invoke<Map<string, Object | null> | null>('getCurrentServer');
      this.hasServer = server !== null;
      if (server === null) {
        this.containers = [];
        this.detailVisible = false;
        return;
      }
      const reply = await this.bridge.invoke<Array<Map<string, Object | null>>>('getContainers');
      this.containers = reply.map((entry: Map<string, Object | null>): HarmonyContainerItem =>
        new HarmonyContainerItem(entry));
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private select(entry: HarmonyContainerItem): void {
    this.detailItems = [entry];
    this.logText = '';
    this.logError = '';
    this.logsLoaded = false;
    this.detailVisible = true;
  }

  private confirmOperation(entry: HarmonyContainerItem, method: string, title: string): void {
    this.getUIContext().showAlertDialog({
      title: title,
      message: `${title} ${entry.name}?`,
      primaryButton: { value: this.label('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.label('commonConfirm'),
        action: (): void => { this.operate(entry, method); },
      },
    });
  }

  private async operate(entry: HarmonyContainerItem, method: string): Promise<void> {
    this.operationPending = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('id', entry.id);
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.getUIContext().getPromptAction().showToast({
        message: this.label('containerOperateSuccess'),
      });
      this.detailVisible = false;
      await this.load();
    } catch (error) {
      this.getUIContext().showAlertDialog({
        title: this.label('commonOperationFailed'),
        message: (error as Error).message,
        confirm: { value: this.label('commonClose'), action: (): void => {} },
      });
    } finally {
      this.operationPending = false;
    }
  }

  private async loadLogs(entry: HarmonyContainerItem): Promise<void> {
    if (this.logsLoading) return;
    this.logsLoading = true;
    this.logError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('name', entry.name);
      args.set('tail', '200');
      this.logText = await this.bridge.invoke<string>('getContainerLogs', args);
      this.logsLoaded = true;
    } catch (error) {
      this.logError = (error as Error).message;
    } finally {
      this.logsLoading = false;
    }
  }

  private async openManagement(): Promise<void> {
    try {
      await this.bridge.openFlutterPage('/containers');
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private displayedLogs(): string {
    return this.logText.length === 0 ? this.label('containerLogsEmpty') : this.logText;
  }

  @Builder
  private detailRow(key: string, content: string) {
    Column({ space: 4 }) {
      Text(this.label(key)).fontSize(13).fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(content)
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private operationButtons(entry: HarmonyContainerItem) {
    Row({ space: 12 }) {
      if (entry.state === 'running') {
        Button(this.label('containerActionStop'))
          .layoutWeight(1)
          .height(48)
          .enabled(!this.operationPending)
          .onClick((): void => {
            this.confirmOperation(entry, 'stopContainer', this.label('containerActionStop'));
          })
      } else {
        Button(this.label('containerActionStart'))
          .layoutWeight(1)
          .height(48)
          .enabled(!this.operationPending)
          .onClick((): void => {
            this.confirmOperation(entry, 'startContainer', this.label('containerActionStart'));
          })
      }
      Button(this.label('containerActionRestart'))
        .layoutWeight(1)
        .height(48)
        .enabled(!this.operationPending)
        .onClick((): void => {
          this.confirmOperation(entry, 'restartContainer', this.label('containerActionRestart'));
        })
    }
    .width('100%')
  }

  @Builder
  private containerDetails() {
    Scroll() {
      Column({ space: 20 }) {
        ForEach(this.detailItems, (entry: HarmonyContainerItem): void => {
          Text(entry.name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
          this.detailRow('containerInfoId', entry.id)
          this.detailRow('containerInfoImage', entry.image)
          this.detailRow('containerInfoStatus', entry.status)
          this.operationButtons(entry)
          Button(this.label('containerActionLogs'))
            .width('100%')
            .height(48)
            .enabled(!this.logsLoading)
            .onClick((): void => { this.loadLogs(entry); })
        }, (entry: HarmonyContainerItem): string => entry.id)
        if (this.logsLoading) {
          LoadingProgress().width(32).height(32)
        } else if (this.logError.length > 0) {
          Text(this.logError).fontColor($r('sys.color.ohos_id_color_text_primary'))
        } else if (this.logsLoaded) {
          Text(this.displayedLogs())
            .fontFamily('monospace')
            .fontSize(13)
            .copyOption(CopyOptions.LocalDevice)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .width('100%')
        }
        Button(this.label('commonMore'))
          .width('100%')
          .height(48)
          .onClick((): void => {
            this.detailVisible = false;
            this.openManagement();
          })
      }
      .padding({ left: 24, right: 24, top: 24, bottom: 32 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text(this.label('containerTitle'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .layoutWeight(1)
        Button(this.label('commonRefresh'))
          .height(48)
          .enabled(!this.loading)
          .onClick((): void => { this.load(); })
        Button(this.label('commonMore'))
          .height(48)
          .margin({ left: 8 })
          .enabled(this.hasServer)
          .onClick((): void => { this.openManagement(); })
      }
      .width('100%')
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .width('100%')
      }
      Refresh({ refreshing: this.loading }) {
        List({ space: 12 }) {
          if (!this.hasServer && !this.loading) {
            ListItem() {
              Text(this.label('noServerSelectedDescription'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .padding(24)
            }
          } else if (this.containers.length === 0 && !this.loading && this.errorMessage.length === 0) {
            ListItem() {
              Text(this.label('containerEmptyTitle'))
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .padding(24)
            }
          }
          ForEach(this.containers, (entry: HarmonyContainerItem): void => {
            ListItem() {
              Column({ space: 8 }) {
                Text(entry.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.ohos_id_color_text_primary'))
                Text(entry.image).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
                Text(entry.status).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
              }
              .padding(20)
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .borderRadius(16)
              .constraintSize({ minHeight: 72 })
              .accessibilityText(`${entry.name}, ${entry.status}`)
              .onClick((): void => { this.select(entry); })
            }
          }, (entry: HarmonyContainerItem): string => entry.id)
        }
        .width('100%')
        .height('100%')
      }
      .layoutWeight(1)
      .onRefreshing((): void => { this.load(); })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .bindSheet($$this.detailVisible, this.containerDetails, {
      height: SheetSize.LARGE,
      showClose: true,
      dragBar: true,
    })
  }
}
