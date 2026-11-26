import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';

@Observed
class HarmonyFileTransfer {
  id: string;
  fileName: string = '';
  status: string = '';
  progress: number = 0;
  isCompleted: boolean = false;
  canControl: boolean = false;
  error: string = '';

  constructor(id: string) {
    this.id = id;
  }

  update(data: Map<string, Object | null>): void {
    this.fileName = (data.get('name') as string | null) ?? '';
    this.status = data.get('status') as string;
    this.progress = Math.max(0, Math.min(100, data.get('progress') as number));
    this.isCompleted = data.get('isCompleted') as boolean;
    this.canControl = data.get('canControl') as boolean;
    this.error = (data.get('error') as string | null) ?? '';
  }
}

class HarmonyUploadHistoryFile {
  fileName: string;
  fileSize: string;

  constructor(data: Map<string, Object | null>) {
    this.fileName = data.get('name') as string;
    const bytes = data.get('size') as number;
    if (bytes < 1024) {
      this.fileSize = `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      this.fileSize = `${(bytes / 1024).toFixed(1)} KB`;
    } else if (bytes < 1024 * 1024 * 1024) {
      this.fileSize = `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    } else {
      this.fileSize = `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
    }
  }
}

@Component
struct HarmonyFileTransferRow {
  @ObjectLink task: HarmonyFileTransfer;
  isUpload: boolean = false;
  onAction: (action: string, id: string, isUpload: boolean) => void = (): void => {};

  private text(key: string): string {
    return HarmonyNativeBridge.instance.text(key);
  }

  private statusText(): string {
    switch (this.task.status) {
      case 'running': return this.text('transferStatusRunning');
      case 'paused': return this.text('transferStatusPaused');
      case 'completed': return this.text('transferStatusCompleted');
      case 'cancelled': return this.text('transferStatusCancelled');
      case 'pending': return this.text('transferStatusPending');
      default: return this.text('transferStatusFailed');
    }
  }

  private actions(): MenuElement[] {
    const items: MenuElement[] = [];
    if (this.task.status === 'running') {
      items.push({ value: this.text('transferPause'), action: (): void => {
        this.onAction('pause', this.task.id, this.isUpload);
      } });
    }
    if (this.task.status === 'paused' || (this.isUpload && this.task.status === 'failed')) {
      items.push({ value: this.text('transferResume'), action: (): void => {
        this.onAction('resume', this.task.id, this.isUpload);
      } });
    }
    if (this.task.status === 'running' || this.task.status === 'paused' || this.task.status === 'pending') {
      items.push({ value: this.text('transferCancel'), action: (): void => {
        this.onAction('cancel', this.task.id, this.isUpload);
      } });
    }
    if (!this.isUpload && this.task.status === 'failed') {
      items.push({ value: this.text('commonRetry'), action: (): void => {
        this.onAction('retry', this.task.id, false);
      } });
    }
    if (!this.isUpload && this.task.status === 'completed') {
      items.push({ value: this.text('transferOpenFile'), action: (): void => {
        this.onAction('open', this.task.id, false);
      } });
    }
    if (!this.isUpload && (this.task.isCompleted || this.task.status === 'failed')) {
      items.push({ value: this.text('commonDelete'), action: (): void => {
        this.onAction('delete', this.task.id, false);
      } });
    }
    return items;
  }

  build() {
    Row({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.doc'))
        .fontSize(24)
        .fontColor([$r('sys.color.icon_primary')])
      Column({ space: 6 }) {
        Text(this.task.fileName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.task.isCompleted ? this.statusText() : `${this.statusText()} · ${this.task.progress}%`)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
        if (!this.task.isCompleted) {
          Progress({ value: this.task.progress, total: 100, type: ProgressType.Linear })
            .width('100%')
        }
        if (this.task.error.length > 0) {
          Text(this.task.error)
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      if (this.task.canControl) {
        Button() {
          SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(22)
        }
        .width(48)
        .height(48)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .accessibilityText(`${this.text('commonMore')} · ${this.task.fileName}`)
        .bindMenu(this.actions(), { systemMaterial: menuMaterial })
      }
    }
    .padding({ left: 16, right: 8, top: 12, bottom: 12 })
    .width('100%')
    .constraintSize({ minHeight: 72 })
    .backgroundColor($r('sys.color.comp_background_primary'))
  }
}

@Component
export struct HarmonyFileTransfersPage {
  directory: string = '/';
  @State private activeDownloads: HarmonyFileTransfer[] = [];
  @State private completedDownloads: HarmonyFileTransfer[] = [];
  @State private uploads: HarmonyFileTransfer[] = [];
  @State private selectedTab: number = 0;
  @State private loading: boolean = true;
  @State private loadError: string = '';
  @State private historyFiles: HarmonyUploadHistoryFile[] = [];
  @State private historySearch: string = '';
  @State private historyLoading: boolean = false;
  @State private historyError: string = '';
  private historyPage: number = 1;
  private historyHasMore: boolean = true;
  private refreshTimer: number = -1;
  private refreshing: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private startRefreshing(): void {
    if (this.refreshTimer !== -1) return;
    this.load();
    this.refreshTimer = setInterval((): void => {
      if (this.selectedTab < 2) this.load();
    }, 1000);
  }

  private stopRefreshing(): void {
    if (this.refreshTimer === -1) return;
    clearInterval(this.refreshTimer);
    this.refreshTimer = -1;
  }

  private updateRows(
    incoming: Array<Map<string, Object | null>>,
    current: HarmonyFileTransfer[],
  ): HarmonyFileTransfer[] {
    const known = new Map<string, HarmonyFileTransfer>();
    current.forEach((task: HarmonyFileTransfer): void => { known.set(task.id, task); });
    return incoming.map((data: Map<string, Object | null>): HarmonyFileTransfer => {
      const id = data.get('id') as string;
      const task = known.get(id) ?? new HarmonyFileTransfer(id);
      task.update(data);
      return task;
    });
  }

  private async load(): Promise<void> {
    if (this.refreshing) return;
    this.refreshing = true;
    try {
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyFileTransfers');
      const downloads = reply.get('downloads') as Array<Map<string, Object | null>>;
      const uploads = reply.get('uploads') as Array<Map<string, Object | null>>;
      this.activeDownloads = this.updateRows(downloads.filter((task: Map<string, Object | null>): boolean =>
        task.get('isCompleted') === false), this.activeDownloads);
      this.completedDownloads = this.updateRows(downloads.filter((task: Map<string, Object | null>): boolean =>
        task.get('isCompleted') === true), this.completedDownloads);
      this.uploads = this.updateRows(uploads, this.uploads);
      this.loadError = '';
    } catch (error) {
      this.loadError = (error as Error).message;
    } finally {
      this.loading = false;
      this.refreshing = false;
    }
  }

  private async loadHistory(reset: boolean): Promise<void> {
    if (!reset && (this.historyLoading || !this.historyHasMore || this.historyError.length > 0)) return;
    if (reset) {
      this.historyPage = 1;
      this.historyFiles = [];
      this.historyHasMore = true;
    }
    const requestedPage = this.historyPage;
    this.historyLoading = true;
    this.historyError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('path', this.directory);
      args.set('page', requestedPage);
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getHarmonyFileUploadHistory', args);
      const items = reply.get('items') as Array<Map<string, Object | null>>;
      this.historyFiles = this.historyFiles.concat(items.map(
        (data: Map<string, Object | null>): HarmonyUploadHistoryFile => new HarmonyUploadHistoryFile(data)));
      this.historyHasMore = reply.get('hasMore') as boolean;
      this.historyPage++;
    } catch (error) {
      this.historyError = (error as Error).message;
    } finally {
      this.historyLoading = false;
    }
  }

  private onTaskAction(action: string, id: string, isUpload: boolean): void {
    if (action === 'delete' || action === 'clear') {
      this.getUIContext().showAlertDialog({
        title: this.text(action === 'clear' ? 'transferClearTitle' : 'deleteConfirmTitle'),
        message: this.text(action === 'clear' ? 'transferClearConfirm' : 'deleteCannotUndoMessage'),
        primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
        secondaryButton: {
          value: this.text(action === 'clear' ? 'commonConfirm' : 'commonDelete'),
          action: (): void => { this.operate(action, id, isUpload); },
        },
      });
    } else {
      this.operate(action, id, isUpload);
    }
  }

  private async operate(action: string, id: string, isUpload: boolean): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('action', action);
      args.set('id', id);
      args.set('upload', isUpload);
      const message = await this.bridge.invoke<string | null>('operateHarmonyFileTransfer', args);
      if (message !== null) {
        this.getUIContext().getPromptAction().showToast({ message: this.text(message) });
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.load();
    }
  }

  @Builder
  private stateMessage(message: string, retry: boolean, onRetry: () => void) {
    Column({ space: 12 }) {
      Text(message)
        .fontSize(16)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
      if (retry) {
        Button(this.text('commonRetry'))
          .height(48)
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick(onRetry)
      }
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private taskSection($$: HarmonyTransferSection) {
    ListItemGroup({ header: (): void => { this.sectionTitle($$.title); } }) {
      ForEach($$.tasks, (task: HarmonyFileTransfer): void => {
        ListItem() {
          HarmonyFileTransferRow({
            task: task,
            isUpload: $$.isUpload,
            onAction: (action: string, id: string, isUpload: boolean): void => {
              this.onTaskAction(action, id, isUpload);
            },
          })
        }
      }, (task: HarmonyFileTransfer): string => task.id)
    }
    .borderRadius(16)
    .clip(true)
  }

  @Builder
  private sectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_secondary'))
      .backgroundColor($r('sys.color.background_secondary'))
      .width('100%')
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private taskList(isUpload: boolean) {
    if (this.loadError.length > 0) {
      this.stateMessage(this.loadError, true, (): void => { this.load(); })
    } else if (this.loading) {
      Column() { LoadingProgress().width(40).height(40) }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else if (isUpload ? this.uploads.length === 0 :
      this.activeDownloads.length === 0 && this.completedDownloads.length === 0) {
      this.stateMessage(this.text('transferEmpty'), false, (): void => {})
    } else {
      List({ space: 8 }) {
        if (isUpload) {
          this.taskSection({ title: this.text('transferTabActive'), tasks: this.uploads, isUpload: true })
        } else {
          if (this.activeDownloads.length > 0) {
            this.taskSection({ title: this.text('transferTabActive'), tasks: this.activeDownloads, isUpload: false })
          }
          if (this.completedDownloads.length > 0) {
            this.taskSection({
              title: this.text('transferTabCompleted'), tasks: this.completedDownloads, isUpload: false,
            })
            ListItem() {
              Button(this.text('transferClearCompleted'))
                .height(48)
                .width('100%')
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick((): void => { this.onTaskAction('clear', '', false); })
            }
          }
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    }
  }

  @Builder
  private historyList() {
    Column({ space: 12 }) {
      Search({ placeholder: this.text('filesSearchHint') })
        .height(48)
        .width('100%')
        .onChange((query: string): void => { this.historySearch = query.trim().toLowerCase(); })
      if (this.historyError.length > 0) {
        this.stateMessage(this.historyError, true, (): void => { this.loadHistory(true); })
      } else if (this.historyLoading && this.historyFiles.length === 0) {
        Column() { LoadingProgress().width(40).height(40) }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.historyFiles.length === 0) {
        this.stateMessage(this.text('commonEmpty'), false, (): void => {})
      } else {
        List() {
          ForEach(this.historyFiles, (entry: HarmonyUploadHistoryFile): void => {
            if (entry.fileName.toLowerCase().includes(this.historySearch)) {
              ListItem() {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.doc')).fontSize(24).fontColor([$r('sys.color.icon_primary')])
                Column({ space: 4 }) {
                  Text(entry.fileName)
                    .fontSize(16)
                    .fontColor($r('sys.color.font_primary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text(entry.fileSize).fontSize(14).fontColor($r('sys.color.font_secondary'))
              }
              .width('100%')
              .constraintSize({ minHeight: 64 })
              .padding(12)
              }
            }
          }, (entry: HarmonyUploadHistoryFile): string => entry.fileName)
          if (this.historyLoading) {
            ListItem() { LoadingProgress().width(32).height(32).margin(12) }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(16)
        .onReachEnd((): void => { this.loadHistory(false); })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
  }

  build() {
    NavDestination() {
      Tabs({ index: this.selectedTab }) {
        TabContent() { this.taskList(false) }.tabBar(this.text('transferDownloads'))
        TabContent() { this.taskList(true) }.tabBar(this.text('transferUploads'))
        TabContent() { this.historyList() }.tabBar(this.text('filesUploadHistory'))
      }
      .barHeight(48)
      .width('100%')
      .height('100%')
      .onChange((index: number): void => {
        this.selectedTab = index;
        if (index === 2 && this.historyPage === 1 && !this.historyLoading) this.loadHistory(true);
      })
    }
    .title(this.text('transferManagerTitle'), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .onShown((): void => { this.startRefreshing(); })
    .onHidden((): void => { this.stopRefreshing(); })
  }

  aboutToDisappear(): void {
    this.stopRefreshing();
  }
}

interface HarmonyTransferSection {
  title: string;
  tasks: HarmonyFileTransfer[];
  isUpload: boolean;
}
