import { HarmonyNativeBridge, menuMaterial } from '../../HarmonyNativeBridge';

interface HarmonyPhpSupervisorField {
  fieldKey: string;
  labelKey: string;
}

@Component
export struct HarmonyPhpSupervisor {
  runtimeId?: number;

  @State private items: Array<Map<string, Object | null>> = [];
  @State private form: Map<string, string> = new Map<string, string>();
  @State private editor: string = '';
  @State private editingProcess: string = '';
  @State private fileContent: string = '';
  @State private loading: boolean = true;
  @State private operating: boolean = false;
  @State private errorText: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private definitionFields: HarmonyPhpSupervisorField[] = [
    { fieldKey: 'name', labelKey: 'commonName' },
    { fieldKey: 'command', labelKey: 'containerInfoCommand' },
    { fieldKey: 'user', labelKey: 'commonUsername' },
    { fieldKey: 'dir', labelKey: 'commonPath' },
    { fieldKey: 'numprocs', labelKey: 'numprocs' },
    { fieldKey: 'environment', labelKey: 'processDetailEnvironmentSectionTitle' },
  ];

  aboutToAppear(): void { this.load(); }

  private text(key: string): string { return this.bridge.text(key); }

  private args(): Map<string, Object | null> {
    if (this.runtimeId === undefined || this.runtimeId === null) throw new Error(this.text('runtimeDetailLoadFailed'));
    const args = new Map<string, Object | null>();
    args.set('id', this.runtimeId);
    args.set('section', 'php/supervisor');
    return args;
  }

  private fileArgs(): Map<string, Object | null> {
    const args = this.args();
    args.set('section', 'php/supervisor-file');
    args.set('name', this.editingProcess);
    args.set('file', this.editor);
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getNativeRuntimeManagement', this.args());
      this.items = reply.get('items') as Array<Map<string, Object | null>>;
    } catch (error) {
      this.errorText = this.text('runtimeDetailLoadFailed');
    } finally {
      this.loading = false;
    }
  }

  private stateLabel(state: string): string {
    switch (state) {
      case 'RUNNING': return this.text('runtimeStatusRunning');
      case 'STARTING': return this.text('runtimeStatusStarting');
      case 'WARNING': return this.text('runtimeSupervisorStatusWarning');
      case 'STOPPED': return this.text('runtimeStatusStopped');
      default: return state;
    }
  }

  private beginDefinition(item?: Map<string, Object | null>): void {
    const fields = new Map<string, string>();
    this.definitionFields.forEach((field: HarmonyPhpSupervisorField): void => {
      fields.set(field.fieldKey, item?.get(field.fieldKey)?.toString() ?? '');
    });
    if (!fields.get('numprocs')) fields.set('numprocs', '1');
    this.form = fields;
    this.editingProcess = item?.get('name')?.toString() ?? '';
    this.editor = 'definition';
  }

  private async openFile(name: string, file: string): Promise<void> {
    this.editingProcess = name;
    this.editor = file;
    this.loading = true;
    this.errorText = '';
    try {
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getNativeRuntimeManagement', this.fileArgs());
      this.fileContent = reply.get('content') as string;
    } catch (error) {
      this.errorText = this.text('runtimeDetailLoadFailed');
    } finally {
      this.loading = false;
    }
  }

  private confirm(title: string, name: string, action: () => void): void {
    this.getUIContext().showAlertDialog({
      title: title,
      message: name,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: title, action: action },
    });
  }

  private async change(args: Map<string, Object | null>, refreshFile: boolean = false): Promise<void> {
    if (this.operating) return;
    this.operating = true;
    try {
      await this.bridge.invoke<Object | null>('performNativeRuntimeManagement', args);
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
      if (refreshFile) {
        await this.openFile(this.editingProcess, this.editor);
      } else {
        this.editor = '';
        await this.load();
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: this.text('runtimeOperateFailed') });
    } finally {
      this.operating = false;
    }
  }

  private perform(name: string, action: string, titleKey: string): void {
    this.confirm(this.text(titleKey), name, (): void => {
      const args = this.args();
      args.set('name', name);
      args.set('action', action);
      this.change(args);
    });
  }

  private saveDefinition(): void {
    const args = this.args();
    this.form.forEach((entry: string, key: string): void => { args.set(key, entry); });
    args.set('action', this.editingProcess.length > 0 ? 'update' : 'create');
    this.change(args);
  }

  private updateFile(): void {
    const args = this.fileArgs();
    args.set('action', 'update');
    args.set('content', this.fileContent);
    this.change(args, true);
  }

  private clearLog(): void {
    this.confirm(this.text('commonDelete'), this.editor, (): void => {
      const args = this.fileArgs();
      args.set('action', 'clear');
      this.change(args, true);
    });
  }

  private processMenu(item: Map<string, Object | null>): MenuElement[] {
    const name = item.get('name') as string;
    const state = item.get('state') as string;
    const actions: MenuElement[] = [];
    if (state === 'RUNNING' || state === 'STARTING') {
      actions.push({ value: this.text('commonStop'), action: (): void => { this.perform(name, 'stop', 'commonStop'); } });
    } else if (state === 'STOPPED') {
      actions.push({ value: this.text('commonStart'), action: (): void => { this.perform(name, 'start', 'commonStart'); } });
    }
    if (name !== 'php-fpm') {
      actions.push({ value: this.text('commonRestart'), action: (): void => { this.perform(name, 'restart', 'commonRestart'); } });
      actions.push({ value: this.text('runtimeFieldSource'), action: (): void => { this.openFile(name, 'config'); } });
      actions.push({ value: 'out.log', action: (): void => { this.openFile(name, 'out.log'); } });
      actions.push({ value: 'err.log', action: (): void => { this.openFile(name, 'err.log'); } });
      actions.push({ value: this.text('commonEdit'), action: (): void => { this.beginDefinition(item); } });
      actions.push({ value: this.text('commonDelete'), action: (): void => { this.perform(name, 'delete', 'commonDelete'); } });
    }
    return actions;
  }

  private workerStatus(item: Map<string, Object | null>): string {
    const workers = item.get('status') as Array<Map<string, Object | null>> | undefined;
    return (workers ?? []).map((worker: Map<string, Object | null>): string => {
      const status = this.stateLabel(worker.get('status')?.toString() ?? '');
      return [worker.get('name')?.toString() ?? '', worker.get('pid')?.toString() ?? '', status,
        worker.get('uptime')?.toString() ?? ''].filter((part: string): boolean => part.length > 0).join(' · ');
    }).join('\n');
  }

  @Builder
  private processRow(item: Map<string, Object | null>) {
    Row({ space: 8 }) {
      Column({ space: 6 }) {
        Text(item.get('name')?.toString() ?? '').fontSize(16).fontWeight(FontWeight.Medium)
        Text(this.stateLabel(item.get('state')?.toString() ?? '')).fontSize(14).fontColor($r('sys.color.font_secondary'))
        if (item.get('command')) {
          Text(item.get('command')?.toString() ?? '').fontSize(14).fontColor($r('sys.color.font_secondary'))
        }
        if (this.workerStatus(item).length > 0) {
          Text(this.workerStatus(item)).fontSize(14).fontColor($r('sys.color.font_secondary')).copyOption(CopyOptions.InApp)
        }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      if (this.processMenu(item).length > 0) {
        Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(21) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.operating)
          .accessibilityText(this.text('commonMore'))
          .bindMenu(this.processMenu(item), { systemMaterial: menuMaterial })
      }
    }.width('100%').padding(16).backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
  }

  @Builder
  private definitionEditor() {
    Scroll() {
      Column({ space: 12 }) {
        ForEach(this.definitionFields, (field: HarmonyPhpSupervisorField): void => {
          Column({ space: 4 }) {
            Text(this.text(field.labelKey)).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
            TextInput({ text: this.form.get(field.fieldKey) ?? '' }).height(48)
              .type(field.fieldKey === 'numprocs' ? InputType.Number : InputType.Normal)
              .enabled(!this.operating && (field.fieldKey !== 'name' || this.editingProcess.length === 0))
              .accessibilityText(this.text(field.labelKey))
              .onChange((entry: string): void => { this.form.set(field.fieldKey, entry); })
          }.width('100%')
        }, (field: HarmonyPhpSupervisorField): string => field.fieldKey)
        Button(this.text('commonSave')).height(48).width('100%')
          .enabled(!this.operating && (this.form.get('name') ?? '').trim().length > 0 &&
            (this.form.get('command') ?? '').trim().length > 0)
          .onClick((): void => { this.saveDefinition(); })
      }.width('100%')
    }.layoutWeight(1).width('100%')
  }

  @Builder
  private fileEditor() {
    Row({ space: 8 }) {
      Text(`${this.editingProcess} · ${this.editor === 'config' ? this.text('runtimeFieldSource') : this.editor}`)
        .fontSize(16).layoutWeight(1)
      Button(this.text('commonRefresh')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.operating)
        .onClick((): void => { this.openFile(this.editingProcess, this.editor); })
    }.width('100%')
    if (this.editor === 'config') {
      TextArea({ text: this.fileContent }).fontFamily('monospace').width('100%').layoutWeight(1)
        .accessibilityText(this.text('runtimeFieldSource')).enabled(!this.operating)
        .onChange((content: string): void => { this.fileContent = content; })
      Button(this.text('commonSave')).height(48).width('100%').enabled(!this.operating)
        .onClick((): void => { this.updateFile(); })
    } else {
      Scroll() { Text(this.fileContent).fontFamily('monospace').width('100%').copyOption(CopyOptions.InApp) }
        .width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      Button(this.text('commonDelete')).height(48).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
        .enabled(!this.operating).onClick((): void => { this.clearLog(); })
    }
  }

  build() {
    Column({ space: 12 }) {
      if (this.editor.length > 0) {
        Button(this.text('commonBack')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.operating)
          .onClick((): void => { this.editor = ''; this.load(); })
      }
      if (this.loading) {
        LoadingProgress().width(40).height(40).accessibilityText(this.text('commonLoading'))
      } else if (this.errorText.length > 0) {
        Text(this.errorText).fontColor($r('sys.color.font_secondary'))
        Button(this.text('commonRetry')).height(48).onClick((): void => {
          if (this.editor.length > 0) { this.openFile(this.editingProcess, this.editor); } else { this.load(); }
        })
      } else if (this.editor === 'definition') {
        this.definitionEditor()
      } else if (this.editor.length > 0) {
        this.fileEditor()
      } else {
        Row({ space: 8 }) {
          Button(this.text('commonRefresh')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.operating)
            .onClick((): void => { this.load(); })
          Button(this.text('commonAdd')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.operating)
            .onClick((): void => { this.beginDefinition(); })
        }.width('100%').justifyContent(FlexAlign.End)
        List({ space: 12 }) {
          ForEach(this.items, (item: Map<string, Object | null>): void => {
            ListItem() { this.processRow(item) }
          }, (item: Map<string, Object | null>): string => item.get('name')?.toString() ?? '')
          if (this.items.length === 0) {
            ListItem() { Text(this.text('runtimeEmptyTitle')).fontColor($r('sys.color.font_secondary')).padding(16) }
          }
        }.layoutWeight(1).width('100%').scrollBar(BarState.Auto)
      }
    }.width('100%').height('100%').padding(16)
  }
}
