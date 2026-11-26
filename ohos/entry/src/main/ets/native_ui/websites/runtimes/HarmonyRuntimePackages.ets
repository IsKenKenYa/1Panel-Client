import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';

@Component
export struct HarmonyRuntimePackages {
  runtimeId?: number;
  section: string = 'node/modules';

  @State private records: Array<Map<string, Object | null>> = [];
  @State private items: Array<Map<string, Object | null>> = [];
  @State private installed: string[] = [];
  @State private packageManager: string = '';
  @State private query: string = '';
  @State private moduleName: string = '';
  @State private recordName: string = '';
  @State private recordContent: string = '';
  @State private editingRecord: boolean = false;
  @State private loading: boolean = true;
  @State private operating: boolean = false;
  @State private errorText: string = '';
  @State private scriptFeedback: string = '';
  private recordId?: number;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private packageManagers: string[] = ['npm', 'yarn'];

  aboutToAppear(): void { this.load(); }

  private text(key: string): string { return this.bridge.text(key); }

  private args(section: string = this.section): Map<string, Object | null> {
    if (this.runtimeId === undefined || this.runtimeId === null) throw new Error(this.text('runtimeDetailLoadFailed'));
    const args = new Map<string, Object | null>();
    args.set('id', this.runtimeId);
    args.set('section', section);
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeRuntimeManagement', this.args());
      if (this.section === 'php/extensions') {
        this.items = data.get('supportExtensions') as Array<Map<string, Object | null>>;
        this.installed = data.get('extensions') as string[];
        this.records = data.get('records') as Array<Map<string, Object | null>>;
      } else {
        this.items = data.get('items') as Array<Map<string, Object | null>>;
        if (this.packageManager.length === 0) this.packageManager = data.get('packageManager')?.toString() ?? '';
      }
    } catch (error) {
      this.errorText = this.text('runtimeDetailLoadFailed');
    } finally {
      this.loading = false;
    }
  }

  private beginRecord(record?: Map<string, Object | null>): void {
    this.recordId = record === undefined ? undefined : this.storedRecordId(record);
    this.recordName = record?.get('name')?.toString() ?? '';
    this.recordContent = record?.get('extensions')?.toString() ?? '';
    this.editingRecord = true;
  }

  private storedRecordId(record: Map<string, Object | null>): number | undefined {
    const id = record.get('id');
    return typeof id === 'number' && id > 0 ? id : undefined;
  }

  private confirm(title: string, name: string, action: () => void): void {
    this.getUIContext().showAlertDialog({
      title: title,
      message: name,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: title, action: action },
    });
  }

  private async perform(action: string, name: string, record: boolean = false): Promise<void> {
    if (this.operating) return;
    this.operating = true;
    try {
      const args = this.args(record ? 'php/extension-record' : this.section);
      args.set('action', action);
      args.set('name', name);
      if (this.section === 'node/modules') args.set('packageManager', this.packageManager);
      if (record) {
        if (this.recordId !== undefined) args.set('recordId', this.recordId);
        args.set('extensions', this.recordContent);
      }
      if (this.section === 'node/scripts') {
        this.scriptFeedback = this.text('runtimeNodeScriptExecuting').replace('{name}', name);
      }
      const reply = await this.bridge.invoke<Map<string, Object | null> | null>('performNativeRuntimeManagement', args);
      if (reply !== null && this.section === 'node/scripts') {
        const status = reply.get('status')?.toString();
        const message = reply.get('message')?.toString();
        const outcome = reply.get('timedOut') === true ? 'runtimeNodeScriptWaitTimeout' :
          (reply.get('success') === true ? 'runtimeNodeScriptCompleted' : 'runtimeNodeScriptFailed');
        this.scriptFeedback = this.text(outcome);
        if (status) this.scriptFeedback += `\n${this.text('runtimeNodeScriptRuntimeStatus').replace('{status}', status)}`;
        if (message) this.scriptFeedback += `\n${message}`;
      } else {
        this.moduleName = '';
        if (record) this.editingRecord = false;
        this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
        await this.load();
      }
    } catch (error) {
      if (this.section === 'node/scripts') this.scriptFeedback = this.text('runtimeNodeScriptFailed');
      this.getUIContext().getPromptAction().showToast({ message: this.text('runtimeOperateFailed') });
    } finally {
      this.operating = false;
    }
  }

  private removeRecord(record: Map<string, Object | null>): void {
    const id = this.storedRecordId(record);
    if (id === undefined) return;
    const name = record.get('name')?.toString() ?? '';
    this.confirm(this.text('commonDelete'), name, (): void => {
      this.recordId = id;
      this.perform('delete', name, true);
    });
  }

  private filteredItems(): Array<Map<string, Object | null>> {
    const filter = this.query.trim().toLowerCase();
    return this.items.filter((item: Map<string, Object | null>): boolean =>
      (item.get('name')?.toString() ?? '').toLowerCase().includes(filter) ||
      (item.get('description')?.toString() ?? '').toLowerCase().includes(filter));
  }

  @Builder
  private packagesRow(item: Map<string, Object | null>) {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text(item.get('name')?.toString() ?? '').fontSize(16).fontWeight(FontWeight.Medium)
        if (item.get('version')) {
          Text(item.get('version')?.toString() ?? '').fontSize(14).fontColor($r('sys.color.font_secondary'))
        }
        if (item.get('description') || item.get('script')) {
          Text((item.get('description') ?? item.get('script'))?.toString() ?? '')
            .fontSize(14).fontColor($r('sys.color.font_secondary')).copyOption(CopyOptions.InApp)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      if (this.section === 'node/scripts') {
        Button(this.text('scriptLibraryRunAction')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.operating).onClick((): void => {
            const name = item.get('name') as string;
            this.confirm(this.text('scriptLibraryRunAction'), name, (): void => { this.perform('run', name); });
          })
      } else if (this.section === 'node/modules' || item.get('installed') === true) {
        Button(this.text('appActionUninstall')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.operating && (this.section !== 'node/modules' || this.packageManagers.includes(this.packageManager)))
          .onClick((): void => {
            const name = item.get('name') as string;
            this.confirm(this.text('appActionUninstall'), name, (): void => { this.perform('uninstall', name); });
          })
      } else {
        Button(this.text('appStoreInstall')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.operating).onClick((): void => {
            const name = item.get('name') as string;
            this.confirm(this.text('appStoreInstall'), name, (): void => { this.perform('install', name); });
          })
      }
    }.width('100%').constraintSize({ minHeight: 56 }).padding(12)
  }

  @Builder
  private extensionRecords() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        Text(this.text('phpExtensionsRecordsTitle').replace('{title}', this.text('operationsPhpExtensionsTitle')))
          .fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1)
        Button(this.text('commonAdd')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.operating).onClick((): void => { this.beginRecord(); })
      }.width('100%')
      ForEach(this.records, (record: Map<string, Object | null>): void => {
        Row({ space: 8 }) {
          Column({ space: 4 }) {
            Text(record.get('name')?.toString() ?? '').fontSize(16)
            Text(record.get('extensions')?.toString() ?? '').fontSize(14).fontColor($r('sys.color.font_secondary'))
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          Button(this.text('commonEdit')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .enabled(!this.operating && this.storedRecordId(record) !== undefined).onClick((): void => { this.beginRecord(record); })
          Button(this.text('commonDelete')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .enabled(!this.operating && this.storedRecordId(record) !== undefined).onClick((): void => { this.removeRecord(record); })
        }.width('100%').constraintSize({ minHeight: 56 })
      }, (record: Map<string, Object | null>): string => record.get('id')?.toString() ?? record.get('name')?.toString() ?? '')
    }.width('100%').padding(12).borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private extensionRecordForm() {
    Column({ space: 12 }) {
      Text(this.text('commonName')).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextInput({ text: this.recordName }).height(48).enabled(this.recordId === undefined && !this.operating)
        .accessibilityText(this.text('commonName')).onChange((name: string): void => { this.recordName = name; })
      Text(this.text('phpExtensionsLabel')).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextArea({ text: this.recordContent }).constraintSize({ minHeight: 80 }).enabled(!this.operating)
        .accessibilityText(this.text('phpExtensionsLabel'))
        .onChange((content: string): void => { this.recordContent = content; })
      Row({ space: 8 }) {
        Button(this.text('commonCancel')).height(48).layoutWeight(1).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.operating).onClick((): void => { this.editingRecord = false; })
        Button(this.text('commonSave')).height(48).layoutWeight(1)
          .enabled(!this.operating && this.recordName.trim().length > 0 && this.recordContent.trim().length > 0)
          .onClick((): void => { this.perform(this.recordId === undefined ? 'create' : 'update', this.recordName, true); })
      }.width('100%')
    }.width('100%').padding(16)
  }

  build() {
    Column({ space: 12 }) {
      if (this.loading) {
        LoadingProgress().width(40).height(40).accessibilityText(this.text('commonLoading'))
      } else if (this.errorText.length > 0) {
        Text(this.errorText).fontColor($r('sys.color.font_secondary'))
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else if (this.editingRecord) {
        this.extensionRecordForm()
      } else {
        if (this.section !== 'node/scripts') {
          Search({ value: this.query, placeholder: this.text('commonSearch') }).height(48)
            .onChange((term: string): void => { this.query = term; })
        }
        if (this.section === 'node/modules') {
          Select(this.packageManagers.map((manager: string): SelectOption => ({ value: manager })))
            .height(48).value(this.packageManager).selected(this.packageManagers.indexOf(this.packageManager))
            .enabled(!this.operating).accessibilityText(this.text('runtimeFieldPackageManager'))
            .onSelect((index: number): void => { this.packageManager = this.packageManagers[index]; })
          Row({ space: 8 }) {
            TextInput({ text: this.moduleName, placeholder: this.text('commonName') }).height(48).layoutWeight(1)
              .onChange((name: string): void => { this.moduleName = name; })
            Button(this.text('appStoreInstall')).height(48)
              .enabled(!this.operating && this.packageManagers.includes(this.packageManager) && this.moduleName.trim().length > 0)
              .onClick((): void => { this.perform('install', this.moduleName); })
          }.width('100%')
        }
        if (this.scriptFeedback.length > 0) {
          Text(this.scriptFeedback).fontSize(14).width('100%').copyOption(CopyOptions.InApp)
        }
        List({ space: 10 }) {
          if (this.section === 'php/extensions') {
            ListItem() { this.extensionRecords() }
            if (this.installed.length > 0) {
              ListItem() {
                Text(this.installed.join(', ')).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
              }
            }
          }
          ForEach(this.filteredItems(), (item: Map<string, Object | null>): void => {
            ListItem() { this.packagesRow(item) }
              .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(12)
          }, (item: Map<string, Object | null>): string => item.get('name')?.toString() ?? '')
          if (this.filteredItems().length === 0 && this.section !== 'php/extensions') {
            ListItem() {
              Text(this.text('runtimeEmptyTitle')).fontSize(14).fontColor($r('sys.color.font_secondary')).padding(16)
            }
          }
        }.width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      }
    }.width('100%').height('100%').padding(16)
  }
}
