import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';

let nextFilePreviewSession: number = 0;

@Component
export struct HarmonyFileContentPage {
  editable: boolean = false;
  routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private content: string = '';
  @State private originalContent: string = '';
  @State private errorMessage: string = '';
  @State private previewKind: string = '';
  @State private localPath: string = '';
  @State private canLoadMore: boolean = false;
  @State private encoding: string = 'utf-8';
  private session: string = (++nextFilePreviewSession).toString();

  aboutToAppear(): void {
    this.load(false);
  }

  aboutToDisappear(): void {
    if (this.editable) return;
    const args = new Map<string, Object | null>();
    args.set('session', this.session);
    HarmonyNativeBridge.instance.invoke<Object | null>('releaseHarmonyFilePreview', args);
  }

  private text(key: string): string {
    return HarmonyNativeBridge.instance.text(key);
  }

  private argumentsForFile(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('path', this.routeArguments.get('path') as string);
    args.set('name', this.routeArguments.get('name') as string);
    args.set('size', (this.routeArguments.get('size') as number | null) ?? null);
    args.set('session', this.session);
    return args;
  }

  private async load(append: boolean): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const args = this.argumentsForFile();
      if (this.editable) {
        args.set('encoding', this.encoding);
        this.originalContent = await HarmonyNativeBridge.instance.invoke<string>('getHarmonyFileEditor', args);
        this.content = this.originalContent;
      } else {
        args.set('next', append);
        const preview = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>(
          'getHarmonyFilePreview', args,
        );
        const content = (preview.get('content') as string | null) ?? '';
        if (append) {
          if (content.length > 0) this.content += '\n' + content;
        } else {
          this.content = content;
          this.previewKind = preview.get('kind') as string;
          this.localPath = (preview.get('localPath') as string | null) ?? '';
        }
        this.canLoadMore = preview.get('hasMore') === true;
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async save(): Promise<void> {
    if (this.saving || this.loading) return;
    this.saving = true;
    try {
      const content = this.content;
      const args = this.argumentsForFile();
      args.set('content', content);
      args.set('encoding', this.encoding);
      await HarmonyNativeBridge.instance.invoke<Object | null>('saveHarmonyFileEditor', args);
      this.originalContent = content;
      this.getUIContext().getPromptAction().showToast({ message: this.text('filesEditorSaved') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.saving = false;
    }
  }

  private confirmDiscard(message: string, action: () => void): void {
    this.getUIContext().showAlertDialog({
      title: this.text('filesEditorUnsaved'),
      message: message,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('filesEditorDiscardChanges'), action: action },
    });
  }

  private requestBack(): boolean {
    if (this.saving) return true;
    if (!this.editable || this.content === this.originalContent) return false;
    this.confirmDiscard(this.text('filesEditorDiscardChanges'), this.onBack);
    return true;
  }

  private selectEncoding(encoding: string): void {
    if (encoding === this.encoding) return;
    const reload = (): void => {
      this.encoding = encoding;
      this.load(false);
    };
    if (this.content === this.originalContent) {
      reload();
    } else {
      this.confirmDiscard(this.text('filesEditorReloadConfirm'), reload);
    }
  }

  private encodingMenu(): MenuElement[] {
    const encodings = ['utf-8', 'gbk', 'gb2312', 'big5', 'iso-8859-1', 'ascii'];
    return encodings.map((encoding: string): MenuElement => {
      return { value: encoding.toUpperCase(), action: (): void => { this.selectEncoding(encoding); } };
    });
  }

  private async openLocalPreview(): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('localPath', this.localPath);
      if (await HarmonyNativeBridge.instance.invoke<boolean>('openHarmonyFilePreview', args)) return;
      this.getUIContext().getPromptAction().showToast({ message: this.text('transferOpenFileError') });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  @Builder
  private fileText() {
    Scroll() {
      Column({ space: 12 }) {
        Text(this.content)
          .fontSize(14)
          .fontFamily('monospace')
          .copyOption(CopyOptions.LocalDevice)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')
        if (this.canLoadMore) {
          Button(this.text('commonLoad'))
            .height(48)
            .enabled(!this.loading)
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.load(true); })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(16)
    }
    .align(Alignment.TopStart)
    .width('100%')
    .layoutWeight(1)
  }

  build() {
    NavDestination() {
      Column({ space: 8 }) {
        if (this.errorMessage.length > 0) {
          Column({ space: 12 }) {
            Text(this.errorMessage).fontSize(16).textAlign(TextAlign.Center)
              .fontColor($r('sys.color.font_secondary'))
            Button(this.text('commonRetry')).height(48)
              .onClick((): void => { this.load(false); })
          }
          .padding(24).width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (this.loading && this.content.length === 0) {
          Column() { LoadingProgress().width(40).height(40) }
            .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else if (this.editable) {
          Row({ space: 8 }) {
            Button(this.encoding.toUpperCase())
              .height(48)
              .enabled(!this.saving)
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .accessibilityText(this.text('filesEditorEncoding'))
              .bindMenu(this.encodingMenu(), { systemMaterial: menuMaterial })
            Blank()
            Button(this.text('filesEditorSave'))
              .height(48)
              .enabled(!this.saving && this.content !== this.originalContent)
              .onClick((): void => { this.save(); })
          }
          .width('100%')
          TextArea({ text: this.content })
            .width('100%')
            .layoutWeight(1)
            .fontFamily('monospace')
            .fontSize(14)
            .backgroundColor($r('sys.color.comp_background_primary'))
            .accessibilityText(this.text('filesEditorTitle'))
            .onChange((content: string): void => { this.content = content; })
        } else if (this.previewKind === 'image' && this.localPath.length > 0) {
          Image('file://' + this.localPath)
            .width('100%')
            .layoutWeight(1)
            .alt(this.routeArguments.get('name') as string)
            .objectFit(ImageFit.Contain)
            .onError((): void => { this.errorMessage = this.text('filesPreviewError'); })
        } else if (this.previewKind === 'video' && this.localPath.length > 0) {
          Video({ src: 'file://' + this.localPath })
            .width('100%')
            .layoutWeight(1)
            .controls(true)
            .objectFit(ImageFit.Contain)
            .onError((): void => { this.errorMessage = this.text('filesPreviewError'); })
        } else if (this.previewKind === 'text' || this.previewKind === 'markdown') {
          this.fileText()
        } else if (this.localPath.length > 0) {
          Column() {
            Button(this.text('transferOpenFile')).height(48)
              .onClick((): void => { this.openLocalPreview(); })
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          Column() {
            Text(this.text('filesPreviewUnsupported')).fontColor($r('sys.color.font_secondary'))
          }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        }
      }
      .padding({ left: 16, right: 16, bottom: 16 })
      .width('100%')
      .height('100%')
    }
    .title(this.routeArguments.get('name') as string, { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .onBackPressed((): boolean => this.requestBack())
  }
}
