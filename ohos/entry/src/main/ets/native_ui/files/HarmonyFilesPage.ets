import { LengthMetrics } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyFileContentPage } from './HarmonyFileContentPage';

class HarmonyFileEntry {
  name: string;
  path: string;
  isDirectory: boolean;
  size: number;
  modifiedAt: number | null;

  constructor(data: Map<string, Object | null>) {
    this.name = data.get('name') as string;
    this.path = data.get('path') as string;
    this.isDirectory = data.get('isDir') as boolean;
    this.size = data.get('size') as number;
    this.modifiedAt = (data.get('modTime') as number | null) ?? null;
  }
}

@Component
export struct HarmonyFilesPage {
  initialPath: string = '/';
  /** 窗口宽度达到 600vp 时按官方分栏规范让目录与文件详情同屏显示。 */
  @State private splitLayout: boolean = false;
  private readonly paths: NavPathStack = new NavPathStack();
  @State private currentPath: string = '/';
  @State private serverName: string = '';
  @State private entries: HarmonyFileEntry[] = [];
  @State private isLoading: boolean = false;
  @State private missingServer: boolean = false;
  @State private errorMessage: string = '';
  @State private mutationRunning: boolean = false;
  @State private formKind: string = '';
  @State private formValue: string = '';
  @State private formAuxiliary: string = '';
  @State private formError: string = '';
  @State private sorting: string = 'name';
  @State private sortOrder: string = 'ascending';
  @State private searchQuery: string = '';
  private serverId: string = '';
  private loadedPage: number = 0;
  private hasMoreFiles: boolean = false;

  aboutToAppear(): void {
    this.loadDirectory(this.initialPath);
  }

  private text(key: string): string {
    return HarmonyNativeBridge.instance.text(key);
  }

  private async loadDirectory(requestedPath: string, append: boolean = false): Promise<void> {
    if (this.isLoading || (append && !this.hasMoreFiles)) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const server = await HarmonyNativeBridge.instance
        .invoke<Map<string, Object | null> | null>('getCurrentServer');
      this.missingServer = server === null;
      if (server === null) {
        this.serverId = '';
        this.serverName = '';
        this.entries = [];
        this.currentPath = '/';
        this.hasMoreFiles = false;
        return;
      }
      const selectedId = server.get('id') as string;
      const directory = this.serverId.length === 0 || this.serverId === selectedId ? requestedPath : '/';
      const requestedPage = append && directory === this.currentPath ? this.loadedPage + 1 : 1;
      this.serverId = selectedId;
      this.serverName = server.get('name') as string;
      if (this.currentPath !== directory) {
        this.entries = [];
      }
      this.currentPath = directory;
      const argumentsMap = new Map<string, Object | null>();
      argumentsMap.set('path', directory);
      argumentsMap.set('search', this.searchQuery.length > 0 ? this.searchQuery : null);
      argumentsMap.set('sortBy', this.sorting);
      argumentsMap.set('sortOrder', this.sortOrder);
      argumentsMap.set('page', requestedPage);
      const result = await HarmonyNativeBridge.instance
        .invoke<Map<string, Object | null>>('getHarmonyFileDirectory', argumentsMap);
      const items = result.get('items') as Array<Map<string, Object | null>>;
      const loaded = items.map((entry: Map<string, Object | null>): HarmonyFileEntry => {
        return new HarmonyFileEntry(entry);
      });
      this.entries = requestedPage === 1 ? loaded : this.entries.concat(loaded);
      this.loadedPage = requestedPage;
      this.hasMoreFiles = result.get('hasMore') === true;
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private parentPath(): string {
    const directory = this.currentPath.replace(new RegExp('/+$'), '');
    const separator = directory.lastIndexOf('/');
    return separator <= 0 ? '/' : directory.substring(0, separator);
  }

  private fileSize(size: number): string {
    if (size < 1024) {
      return `${size} B`;
    }
    if (size < 1024 * 1024) {
      return `${(size / 1024).toFixed(1)} KB`;
    }
    if (size < 1024 * 1024 * 1024) {
      return `${(size / (1024 * 1024)).toFixed(1)} MB`;
    }
    return `${(size / (1024 * 1024 * 1024)).toFixed(1)} GB`;
  }

  private entryDescription(entry: HarmonyFileEntry): string {
    if (entry.isDirectory) {
      return this.text('filesTypeDirectory');
    }
    return this.fileSize(entry.size);
  }

  private showFileDetails(entry: HarmonyFileEntry): void {
    const lines: string[] = [
      `${this.text('filesPathLabel')}: ${entry.path}`,
      `${this.text('filesSizeLabel')}: ${this.fileSize(entry.size)}`,
    ];
    const modifiedAt = entry.modifiedAt;
    if (modifiedAt !== null) {
      lines.push(`${this.text('filesModifiedLabel')}: ${new Date(modifiedAt).toLocaleString()}`);
    }
    this.getUIContext().showAlertDialog({
      title: entry.name,
      message: lines.join('\n'),
      confirm: {
        value: this.text('commonClose'),
        action: (): void => {},
      },
    });
  }

  private openEntry(entry: HarmonyFileEntry): void {
    if (entry.isDirectory) {
      this.searchQuery = '';
      this.loadDirectory(entry.path);
      return;
    }
    this.previewEntry(entry, false);
  }

  private previewEntry(entry: HarmonyFileEntry, editable: boolean): void {
    this.paths.pushPath({
      name: editable ? 'editor' : 'preview',
      param: this.entryArguments(entry),
    });
  }

  private entryArguments(entry: HarmonyFileEntry): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('path', entry.path);
    args.set('name', entry.name);
    args.set('size', entry.size);
    args.set('isDir', entry.isDirectory);
    return args;
  }

  private directoryArguments(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('path', this.currentPath);
    return args;
  }

  private notify(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message.slice(0, 120) });
  }

  private async openNative(route: string, args?: Map<string, Object | null>): Promise<void> {
    try {
      await HarmonyNativeBridge.instance.openNativePage(route, args);
    } catch (error) {
      this.notify((error as Error).message);
    }
  }

  private async selectServer(): Promise<void> {
    await this.openNative('/server-selection');
  }

  private formPath(name: string): string {
    return this.currentPath === '/' ? '/' + name : this.currentPath + '/' + name;
  }

  private formEntry: HarmonyFileEntry | null = null;

  private beginForm(kind: string, entry: HarmonyFileEntry | null = null): void {
    this.formEntry = entry;
    this.formValue = kind === 'rename' ? entry?.name ?? '' :
      kind === 'copy' || kind === 'move' || kind === 'extract' ? this.currentPath :
      kind === 'compress' ? (entry?.name ?? '') + '.zip' : '';
    this.formAuxiliary = '';
    this.formError = '';
    this.formKind = kind;
  }

  private async upload(): Promise<void> {
    if (this.mutationRunning) return;
    this.mutationRunning = true;
    try {
      const count = await HarmonyNativeBridge.instance.invoke<number>(
        'uploadHarmonyFiles', this.directoryArguments(),
      );
      if (count > 0) {
        this.notify(this.text('filesUploadSuccess'));
        await this.loadDirectory(this.currentPath);
      }
    } catch (error) {
      this.notify((error as Error).message);
    } finally {
      this.mutationRunning = false;
    }
  }

  private async download(entry: HarmonyFileEntry): Promise<void> {
    try {
      const taskId = await HarmonyNativeBridge.instance.invoke<string | null>(
        'enqueueHarmonyFileDownload', this.entryArguments(entry),
      );
      if (taskId !== null) await this.openNative('/files/transfers', this.directoryArguments());
    } catch (error) {
      this.notify((error as Error).message);
    }
  }

  private async mutate(method: string, args: Map<string, Object | null>): Promise<void> {
    if (this.mutationRunning) return;
    this.mutationRunning = true;
    try {
      const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.formKind = '';
      await this.loadDirectory(this.currentPath);
    } catch (error) {
      if (this.formKind.length > 0) this.formError = (error as Error).message;
      else this.notify((error as Error).message);
    } finally {
      this.mutationRunning = false;
    }
  }

  private submitForm(): void {
    const value = this.formValue.trim();
    if (value.length === 0) return;
    if (this.formKind === 'path') {
      this.formKind = '';
      this.searchQuery = '';
      this.loadDirectory(value);
      return;
    }
    if (this.formKind === 'create-file' || this.formKind === 'create-directory' || this.formKind === 'rename') {
      if (value === '.' || value === '..' || value.includes('/')) {
        this.formError = this.text('filesNameHint');
        return;
      }
      const args = new Map<string, Object | null>();
      const entry = this.formEntry;
      if (this.formKind === 'rename' && entry !== null) {
        const separator = entry.path.lastIndexOf('/');
        args.set('oldPath', entry.path);
        args.set('newPath', entry.path.substring(0, separator + 1) + value);
        this.mutate('renameFile', args);
      } else {
        args.set('path', this.formPath(value));
        this.mutate(this.formKind === 'create-directory' ? 'createFolder' : 'createFileHandler', args);
      }
      return;
    }
    const entry = this.formEntry;
    const args = new Map<string, Object | null>();
    if (this.formKind === 'wget') {
      if (this.formAuxiliary.trim().length === 0) {
        this.formError = this.text('filesNameHint');
        return;
      }
      args.set('url', value);
      args.set('path', this.currentPath);
      args.set('name', this.formAuxiliary.trim());
      this.mutate('wgetDownloadHandler', args);
    } else if (entry !== null) {
      if (this.formKind === 'copy' || this.formKind === 'move') {
        args.set('oldPaths', [entry.path]);
        args.set('newPath', value);
        args.set('type', this.formKind === 'copy' ? 'copy' : 'cut');
        this.mutate('moveHarmonyFiles', args);
      } else if (this.formKind === 'compress') {
        args.set('files', [entry.path]);
        args.set('dst', this.currentPath);
        args.set('name', value);
        args.set('type', 'zip');
        this.mutate('compressFilesHandler', args);
      } else if (this.formKind === 'extract') {
        args.set('path', entry.path);
        args.set('dst', value);
        args.set('type', this.archiveType(entry.name));
        this.mutate('decompressFileHandler', args);
      }
    }
  }

  private confirmDelete(entry: HarmonyFileEntry): void {
    this.getUIContext().showAlertDialog({
      title: this.text('filesDeleteTitle'),
      message: this.text('filesDeleteConfirm').replace('{count}', '1') + '\n' + entry.name,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('filesActionDelete'),
        action: (): void => { this.mutate('deleteFile', this.entryArguments(entry)); },
      },
    });
  }

  private archiveType(name: string): string {
    const lower = name.toLowerCase();
    for (const extension of ['tar.gz', 'tar.bz2', 'tar.xz', 'zip', 'gz', 'bz2', 'xz', 'tar', 'rar', '7z']) {
      if (lower.endsWith('.' + extension)) return extension;
    }
    return '';
  }

  private entryActions(entry: HarmonyFileEntry): MenuElement[] {
    const items: MenuElement[] = [
      { value: this.text('filesPropertiesTitle'), action: (): void => { this.showFileDetails(entry); } },
      { value: this.text('filesActionRename'), action: (): void => { this.beginForm('rename', entry); } },
      { value: this.text('filesActionCopy'), action: (): void => { this.beginForm('copy', entry); } },
      { value: this.text('filesActionMove'), action: (): void => { this.beginForm('move', entry); } },
      { value: this.text('filesActionCompress'), action: (): void => { this.beginForm('compress', entry); } },
      { value: this.text('filesPermissionTitle'), action: (): void => {
        this.openNative('/files/permission', this.entryArguments(entry));
      } },
      { value: this.text('filesFavorites'), action: (): void => {
        this.mutate('addFavoriteHandler', this.entryArguments(entry));
      } },
      { value: this.text('filesActionDelete'), action: (): void => { this.confirmDelete(entry); } },
    ];
    if (!entry.isDirectory) {
      items.unshift(
        { value: this.text('filesEditFile'), action: (): void => {
          this.previewEntry(entry, true);
        } },
        { value: this.text('filesActionDownload'), action: (): void => { this.download(entry); } },
        { value: this.text('fileHistoryTitleWith').replace('{path}', entry.name), action: (): void => {
          this.openNative('/files/history', this.entryArguments(entry));
        } },
        { value: this.text('fileShareTitle'), action: (): void => {
          this.openNative('/files/share', this.entryArguments(entry));
        } },
      );
      if (this.archiveType(entry.name).length > 0) {
        items.push({ value: this.text('filesActionExtract'), action: (): void => { this.beginForm('extract', entry); } });
      }
    }
    return items;
  }

  private changeSort(sortBy: string): void {
    this.sortOrder = this.sorting === sortBy && this.sortOrder === 'ascending' ? 'descending' : 'ascending';
    this.sorting = sortBy;
    this.loadDirectory(this.currentPath);
  }

  private directoryActions(): MenuElement[] {
    return [
      { value: this.text('filesActionNewFile'), action: (): void => { this.beginForm('create-file'); } },
      { value: this.text('filesActionNewFolder'), action: (): void => { this.beginForm('create-directory'); } },
      { value: this.text('filesActionUpload'), action: (): void => { this.upload(); } },
      { value: this.text('transferManagerTitle'), action: (): void => {
        this.openNative('/files/transfers', this.directoryArguments());
      } },
      { value: this.text('filesActionWgetDownload'), action: (): void => { this.beginForm('wget'); } },
      { value: this.text('wgetTitle'), action: (): void => { this.openNative('/files/wget'); } },
      { value: this.text('filesFavorites'), action: (): void => { this.openNative('/files/favorites'); } },
      { value: this.text('filesMounts'), action: (): void => { this.openNative('/files/mounts'); } },
      { value: this.text('filesRecycleBin'), action: (): void => { this.openNative('/files/recycle'); } },
      { value: this.text('fileShareTitle'), action: (): void => { this.openNative('/files/share'); } },
      { value: this.text('filesSelectPath'), action: (): void => {
        this.beginForm('path');
        this.formValue = this.currentPath;
      } },
      { value: this.text('filesSortByName'), action: (): void => { this.changeSort('name'); } },
      { value: this.text('filesSortBySize'), action: (): void => { this.changeSort('size'); } },
      { value: this.text('filesSortByDate'), action: (): void => { this.changeSort('modTime'); } },
      { value: this.text('commonRefresh'), action: (): void => { this.loadDirectory(this.currentPath); } },
    ];
  }

  private formTitle(): string {
    switch (this.formKind) {
      case 'create-file': return this.text('filesActionNewFile');
      case 'create-directory': return this.text('filesActionNewFolder');
      case 'rename': return this.text('filesActionRename');
      case 'copy': return this.text('filesActionCopy');
      case 'move': return this.text('filesActionMove');
      case 'compress': return this.text('filesActionCompress');
      case 'extract': return this.text('filesActionExtract');
      case 'wget': return this.text('filesActionWgetDownload');
      default: return this.text('filesSelectPath');
    }
  }

  @Builder
  private directoryToolbar() {
    Row({ space: 8 }) {
      Button() {
        SymbolGlyph($r('sys.symbol.arrow_up'))
          .fontSize(20)
          .fontColor([$r('sys.color.ohos_id_color_primary')])
      }
      .width(48)
      .height(48)
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .enabled(this.currentPath !== '/' && !this.isLoading && !this.missingServer)
      .accessibilityText(this.text('filesNavigateUp'))
      .onClick((): void => {
        this.loadDirectory(this.parentPath());
      })

      Column({ space: 4 }) {
        Text(this.currentPath)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.serverName)
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(24) }
        .height(48)
        .width(48)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .enabled(!this.missingServer)
        .accessibilityText(this.text('commonMore'))
        .bindMenu(this.directoryActions())
    }
    .width('100%')
    .padding({ left: 8, right: 12, top: 4, bottom: 4 })
  }

  @Builder
  private fileRow(entry: HarmonyFileEntry) {
    Row({ space: 12 }) {
      if (entry.isDirectory) {
        SymbolGlyph($r('sys.symbol.folder'))
          .fontSize(24)
          .fontColor([$r('sys.color.ohos_id_color_primary')])
      } else {
        SymbolGlyph($r('sys.symbol.doc'))
          .fontSize(24)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }
      Column({ space: 4 }) {
        Text(entry.name)
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.entryDescription(entry))
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick((): void => { this.openEntry(entry); })
      Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(22) }
        .width(48)
        .height(48)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .accessibilityText(this.text('commonMore') + ' · ' + entry.name)
        .bindMenu(this.entryActions(entry))
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .padding({ left: 16, right: 8, top: 6, bottom: 6 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .accessibilityText(entry.name)
    .focusable(true)
    .focusBox({ margin: LengthMetrics.vp(2) })
    .hoverEffect(HoverEffect.Highlight)
  }

  @Builder
  private operationForm() {
    Column({ space: 12 }) {
      Text(this.formTitle()).fontSize(18).fontWeight(FontWeight.Medium)
      TextInput({ text: this.formValue, placeholder: this.formTitle() })
        .height(48)
        .onChange((value: string): void => { this.formValue = value; })
      if (this.formKind === 'wget') {
        TextInput({ text: this.formAuxiliary, placeholder: this.text('filesWgetFilename') })
          .height(48)
          .onChange((value: string): void => { this.formAuxiliary = value; })
      }
      if (this.formError.length > 0) {
        Text(this.formError).fontSize(14).fontColor($r('sys.color.font_secondary'))
      }
      Row({ space: 8 }) {
        Button(this.text('commonCancel')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.mutationRunning).onClick((): void => { this.formKind = ''; })
        Button(this.text('commonConfirm')).height(48)
          .enabled(!this.mutationRunning && this.formValue.trim().length > 0)
          .onClick((): void => { this.submitForm(); })
      }.justifyContent(FlexAlign.End).width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .padding(16)
  }

  @Builder
  private destination(name: string, parameter: Object) {
    NavDestination() {
      HarmonyFileContentPage({
        editable: name === 'editor',
        routeArguments: parameter as Map<string, Object | null>,
        onBack: (): void => { this.paths.pop(); },
      })
    }
    .hideTitleBar(true)
    .backgroundColor($r('sys.color.background_secondary'))
  }

  build() {
    Navigation(this.paths) {
      Column() {
        this.directoryToolbar()
        if (this.formKind.length > 0) {
          this.operationForm()
        } else if (!this.missingServer) {
          Search({ value: this.searchQuery, placeholder: this.text('filesSearchHint') })
          .height(48)
          .margin({ left: 16, right: 16, bottom: 8 })
          .onSubmit((query: string): void => {
            this.searchQuery = query.trim();
            this.loadDirectory(this.currentPath);
          })
          .onChange((query: string): void => {
            if (query.length === 0 && this.searchQuery.length > 0) {
              this.searchQuery = '';
              this.loadDirectory(this.currentPath);
            }
          })
      }
      if (this.errorMessage.length > 0) {
        Column({ space: 12 }) {
          Text(this.errorMessage)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .copyOption(CopyOptions.InApp)
          Button(this.text('commonRetry'))
            .height(48)
            .onClick((): void => {
              this.loadDirectory(this.currentPath);
            })
        }
        .padding(24)
        .width('100%')
      }
      if (this.missingServer) {
        Column({ space: 16 }) {
          Text(this.text('noServerSelectedDescription'))
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          Button(this.text('navServer'))
            .height(48)
            .onClick((): void => {
              this.selectServer();
            })
        }
        .padding(24)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: this.isLoading }) {
          List() {
            if (this.entries.length === 0 && !this.isLoading && this.errorMessage.length === 0) {
              ListItem() {
                Text(this.text('filesEmptyTitle'))
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .padding(24)
              }
            }
            ForEach(this.entries, (entry: HarmonyFileEntry): void => {
              ListItem() {
                this.fileRow(entry)
              }
            }, (entry: HarmonyFileEntry): string => entry.path)
          }
          .width('100%')
          .height('100%')
          .divider({ strokeWidth: 0.5, color: $r('sys.color.ohos_id_color_list_separator'), startMargin: 56 })
          .borderRadius(16)
          .clip(true)
          .onReachEnd((): void => { this.loadDirectory(this.currentPath, true); })
        }
        .onRefreshing((): void => {
          this.loadDirectory(this.currentPath);
        })
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
    }
    .hideTitleBar(true)
    .navDestination(this.destination)
    .mode(this.splitLayout ? NavigationMode.Split : NavigationMode.Stack)
    .navBarWidth(240)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .onAreaChange((_old: Area, current: Area): void => {
      const measured = current.width;
      if (typeof measured === 'number') {
        this.splitLayout = measured >= 600;
      }
    })
  }
}
