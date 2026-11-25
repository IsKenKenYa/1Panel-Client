import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

class HarmonyFileEntry {
  name: string;
  path: string;
  isDirectory: boolean;
  size: number;
  modifiedAt: number;

  constructor(data: Map<string, Object | null>) {
    this.name = data.get('name') as string;
    this.path = data.get('path') as string;
    this.isDirectory = data.get('isDir') as boolean;
    this.size = data.get('size') as number;
    this.modifiedAt = data.get('modTime') as number;
  }
}

@Component
export struct HarmonyFilesPage {
  @State private currentPath: string = '/';
  @State private serverName: string = '';
  @State private entries: HarmonyFileEntry[] = [];
  @State private isLoading: boolean = false;
  @State private missingServer: boolean = false;
  @State private errorMessage: string = '';
  private serverId: string = '';

  aboutToAppear(): void {
    this.loadDirectory('/');
  }

  private text(key: string): string {
    return HarmonyNativeBridge.instance.text(key);
  }

  private async loadDirectory(requestedPath: string): Promise<void> {
    if (this.isLoading) {
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
        return;
      }
      const selectedId = server.get('id') as string;
      const directory = this.serverId === selectedId ? requestedPath : '/';
      this.serverId = selectedId;
      this.serverName = server.get('name') as string;
      if (this.currentPath !== directory) {
        this.entries = [];
      }
      this.currentPath = directory;
      const argumentsMap = new Map<string, Object | null>();
      argumentsMap.set('path', directory);
      const result = await HarmonyNativeBridge.instance
        .invoke<Array<Map<string, Object | null>>>('getFiles', argumentsMap);
      this.entries = result.map((entry: Map<string, Object | null>): HarmonyFileEntry => {
        return new HarmonyFileEntry(entry);
      });
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
    if (entry.modifiedAt > 0) {
      lines.push(`${this.text('filesModifiedLabel')}: ${new Date(entry.modifiedAt).toLocaleString()}`);
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
      this.loadDirectory(entry.path);
      return;
    }
    this.showFileDetails(entry);
  }

  private async openFileManager(): Promise<void> {
    try {
      await HarmonyNativeBridge.instance.openFlutterPage('/files');
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private async selectServer(): Promise<void> {
    try {
      await HarmonyNativeBridge.instance.openFlutterPage('/server-selection');
    } catch (error) {
      this.errorMessage = (error as Error).message;
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

      Button(this.text('commonRefresh'))
        .height(48)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .enabled(!this.isLoading)
        .onClick((): void => {
          this.loadDirectory(this.currentPath);
        })
      Button(this.text('commonMore'))
        .height(48)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .enabled(!this.missingServer)
        .accessibilityText(this.text('filesPageTitle'))
        .onClick((): void => {
          this.openFileManager();
        })
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
    }
    .width('100%')
    .constraintSize({ minHeight: 64 })
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .accessibilityGroup(true)
    .accessibilityText(`${entry.name}, ${this.entryDescription(entry)}`)
    .onClick((): void => {
      this.openEntry(entry);
    })
  }

  build() {
    Column() {
      this.directoryToolbar()
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
        }
        .onRefreshing((): void => {
          this.loadDirectory(this.currentPath);
        })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
