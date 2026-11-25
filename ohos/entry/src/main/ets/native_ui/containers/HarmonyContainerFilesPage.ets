import { HarmonyNativeBridge, menuMaterial, sheetMaterial } from '../HarmonyNativeBridge';

class HarmonyContainerFileEntry {
  name: string;
  path: string;
  isDirectory: boolean;
  size: number | null;
  constructor(record: Map<string, Object | null>) {
    this.name = record.get('name') as string;
    this.path = record.get('path') as string;
    this.isDirectory = record.get('isDir') as boolean;
    this.size = record.get('size') as number | null;
  }
}

@Component
export struct HarmonyContainerFilesPage {
  @Prop containerId: string = '';
  @State private currentPath: string = '/';
  @State private entries: HarmonyContainerFileEntry[] = [];
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private fileContent: string = '';
  @State private previewTitle: string = '';
  @State private previewVisible: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.load('/'); }
  private label(key: string): string { return this.bridge.text(key); }
  private args(path: string): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('containerId', this.containerId);
    args.set('path', path);
    return args;
  }

  private async load(path: string): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const records = await this.bridge.invoke<Array<Map<string, Object | null>>>('getContainerFiles', this.args(path));
      this.currentPath = path;
      this.entries = records.map((record: Map<string, Object | null>): HarmonyContainerFileEntry =>
        new HarmonyContainerFileEntry(record));
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private parent(): string {
    const normalized = this.currentPath.replace(new RegExp('/+$'), '');
    const index = normalized.lastIndexOf('/');
    return index <= 0 ? '/' : normalized.substring(0, index + 1);
  }

  private async open(entry: HarmonyContainerFileEntry): Promise<void> {
    if (entry.isDirectory) { await this.load(entry.path); return; }
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getContainerFileContent', this.args(entry.path));
      this.previewTitle = entry.name;
      if (result.get('isBinary') === true) this.fileContent = this.label('containerFileBinaryHint');
      else this.fileContent = result.get('content') as string;
      this.previewVisible = true;
    } catch (error) { this.showError(error as Error); }
  }

  private showError(error: Error): void {
    this.getUIContext().getPromptAction().showToast({ message: error.message.slice(0, 120) });
  }

  private async upload(): Promise<void> {
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('uploadFilesToContainer', this.args(this.currentPath));
      if (result.get('cancelled') === true) return;
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      await this.load(this.currentPath);
    } catch (error) { this.showError(error as Error); }
  }

  private deleteEntry(entry: HarmonyContainerFileEntry): void {
    this.getUIContext().showAlertDialog({
      title: this.label('containerFileDeleteAction'), message: entry.name,
      primaryButton: { value: this.label('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.label('commonDelete'), action: (): void => { this.remove(entry); } },
    });
  }

  private async remove(entry: HarmonyContainerFileEntry): Promise<void> {
    try {
      const args = this.args(this.currentPath);
      args.set('paths', [entry.path]);
      const result = await this.bridge.invoke<Map<string, Object | null>>('deleteContainerFiles', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      await this.load(this.currentPath);
    } catch (error) { this.showError(error as Error); }
  }

  private description(entry: HarmonyContainerFileEntry): string {
    if (entry.isDirectory) return this.label('containerFilesDirectory');
    return entry.size === null ? '—' : `${entry.size} B`;
  }

  @Builder
  private entryMenu(entry: HarmonyContainerFileEntry) {
    Menu() {
      MenuItem({ content: this.label('containerFileDeleteAction') })
        .onClick((): void => { this.deleteEntry(entry); })
    }
  }

  @Builder
  private preview() {
    Column({ space: 12 }) {
      Text(this.previewTitle).fontSize(20).fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary')).width('100%')
      Scroll() {
        Text(this.fileContent).fontFamily('monospace').fontSize(13)
          .copyOption(CopyOptions.LocalDevice).fontColor($r('sys.color.font_primary')).width('100%')
      }.layoutWeight(1).width('100%')
    }.padding(16).height('100%').width('100%')
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Button() {
          SymbolGlyph($r('sys.symbol.arrow_up')).fontSize(20)
        }.width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(this.currentPath !== '/').accessibilityText(this.label('filesNavigateUp'))
          .onClick((): void => { this.load(this.parent()); })
        Text(this.currentPath).fontSize(14).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor($r('sys.color.font_secondary')).layoutWeight(1)
        Button() { SymbolGlyph($r('sys.symbol.arrow_clockwise')).fontSize(20) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .accessibilityText(this.label('commonRefresh')).enabled(!this.loading)
          .onClick((): void => { this.load(this.currentPath); })
        Button() { SymbolGlyph($r('sys.symbol.arrow_up')).fontSize(20) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .accessibilityText(this.label('containerFileUploadAction')).enabled(!this.loading)
          .onClick((): void => { this.upload(); })
      }.width('100%')
      if (this.errorMessage.length > 0) { Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary')) }
      Refresh({ refreshing: this.loading }) {
        List() {
          if (this.entries.length === 0 && !this.loading) {
            ListItem() { Text(this.label('containerFilesEmpty')).padding(16) }
          }
          ForEach(this.entries, (entry: HarmonyContainerFileEntry): void => {
            ListItem() {
              Row({ space: 12 }) {
                if (entry.isDirectory) { SymbolGlyph($r('sys.symbol.folder')).fontSize(24) }
                else { SymbolGlyph($r('sys.symbol.doc')).fontSize(24) }
                Column({ space: 2 }) {
                  Text(entry.name).fontSize(16).fontColor($r('sys.color.font_primary')).maxLines(2)
                  Text(this.description(entry)).fontSize(14).fontColor($r('sys.color.font_secondary'))
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.font_secondary')])
              }.width('100%').constraintSize({ minHeight: 72 }).padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .onClick((): void => { this.open(entry); })
                .bindContextMenu(this.entryMenu(entry), ResponseType.LongPress, { systemMaterial: menuMaterial })
            }
          }, (entry: HarmonyContainerFileEntry): string => entry.path)
        }.width('100%').height('100%')
          .divider({ strokeWidth: 0.5, color: $r('sys.color.ohos_id_color_list_separator'), startMargin: 52 })
      }.layoutWeight(1).onRefreshing((): void => { this.load(this.currentPath); })
    }.padding({ left: 16, right: 16, top: 12, bottom: 16 }).width('100%').height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
      .bindSheet($$this.previewVisible, this.preview, { height: SheetSize.LARGE, showClose: true, dragBar: true, systemMaterial: sheetMaterial })
  }
}
