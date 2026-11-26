import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';

interface HarmonyPhpField {
  fieldKey: string;
  labelKey: string;
  numeric?: boolean;
}

interface HarmonyPhpContainerGroup {
  groupKey: string;
  labelKey: string;
  fields: HarmonyPhpField[];
}

class HarmonyPhpContainerRow {
  rowId: number;
  entries: Map<string, Object | null>;

  constructor(id: number, entries: Map<string, Object | null>) {
    this.rowId = id;
    this.entries = entries;
  }
}

@Component
export struct HarmonyPhpRuntimeConfig {
  runtimeId?: number;

  @State private selectedSection: number = 0;
  @State private config: Map<string, Object | null> = new Map<string, Object | null>();
  @State private fpmParams: Map<string, string> = new Map<string, string>();
  @State private fpmStatus: Array<Map<string, Object | null>> = [];
  @State private containerRows: Map<string, HarmonyPhpContainerRow[]> = new Map<string, HarmonyPhpContainerRow[]>();
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private errorText: string = '';
  private nextRowId: number = 0;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private sections: string[] = ['php/basic', 'php/fpm', 'php/container', 'php/file', 'php/file'];
  private sectionLabels: string[] = ['runtimePhpTabBasic', 'runtimePhpTabFpm', 'runtimePhpTabContainer',
    'runtimePhpTabPhpFile', 'runtimePhpTabFpmFile'];
  private fpmFields: HarmonyPhpField[] = [
    { fieldKey: 'pm', labelKey: 'runtimePhpFpmMode' },
    { fieldKey: 'pm.max_children', labelKey: 'runtimePhpFpmMaxChildren', numeric: true },
    { fieldKey: 'pm.start_servers', labelKey: 'runtimePhpFpmStartServers', numeric: true },
    { fieldKey: 'pm.min_spare_servers', labelKey: 'runtimePhpFpmMinSpareServers', numeric: true },
    { fieldKey: 'pm.max_spare_servers', labelKey: 'runtimePhpFpmMaxSpareServers', numeric: true },
  ];
  private containerGroups: HarmonyPhpContainerGroup[] = [
    { groupKey: 'environments', labelKey: 'containerInfoEnv', fields: [
      { fieldKey: 'key', labelKey: 'appInstallEnvKey' }, { fieldKey: 'value', labelKey: 'appInstallEnvValue' },
    ] },
    { groupKey: 'exposedPorts', labelKey: 'containerInfoPorts', fields: [
      { fieldKey: 'containerPort', labelKey: 'runtimePhpContainerPort', numeric: true },
      { fieldKey: 'hostPort', labelKey: 'runtimePhpHostPort', numeric: true },
      { fieldKey: 'hostIP', labelKey: 'runtimePhpHostIp' },
    ] },
    { groupKey: 'extraHosts', labelKey: 'runtimePhpContainerExtraHosts', fields: [
      { fieldKey: 'hostname', labelKey: 'dashboardHostNameLabel' }, { fieldKey: 'ip', labelKey: 'runtimePhpHostIp' },
    ] },
    { groupKey: 'volumes', labelKey: 'volumes', fields: [
      { fieldKey: 'source', labelKey: 'runtimeFieldSource' }, { fieldKey: 'target', labelKey: 'runtimePhpVolumeTarget' },
    ] },
  ];

  aboutToAppear(): void { this.load(); }

  private text(key: string): string { return this.bridge.text(key); }

  private configValue(key: string): string { return this.config.get(key)?.toString() ?? ''; }

  private args(): Map<string, Object | null> {
    if (this.runtimeId === undefined || this.runtimeId === null) throw new Error(this.text('runtimeDetailLoadFailed'));
    const args = new Map<string, Object | null>();
    args.set('id', this.runtimeId);
    args.set('section', this.sections[this.selectedSection]);
    if (this.selectedSection >= 3) args.set('type', this.selectedSection === 3 ? 'php' : 'fpm');
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getNativeRuntimeManagement', this.args());
      this.config = result;
      if (this.selectedSection === 0) {
        const disabled = result.get('disableFunctions') as string[] | undefined;
        this.config.set('disableFunctions', disabled?.join(', ') ?? '');
      } else if (this.selectedSection === 1) {
        this.fpmParams = result.get('params') as Map<string, string>;
        this.fpmStatus = result.get('status') as Array<Map<string, Object | null>>;
      } else if (this.selectedSection === 2) {
        const rows = new Map<string, HarmonyPhpContainerRow[]>();
        this.containerGroups.forEach((group: HarmonyPhpContainerGroup): void => {
          const entries = result.get(group.groupKey) as Array<Map<string, Object | null>> | undefined;
          rows.set(group.groupKey, (entries ?? []).map((entry: Map<string, Object | null>): HarmonyPhpContainerRow =>
            new HarmonyPhpContainerRow(++this.nextRowId, entry)));
        });
        this.containerRows = rows;
      }
    } catch (error) {
      this.errorText = this.text('runtimeDetailLoadFailed');
    } finally {
      this.loading = false;
    }
  }

  private updateRow(row: HarmonyPhpContainerRow, field: HarmonyPhpField, content: string): void {
    if (content.trim().length === 0) {
      row.entries.delete(field.fieldKey);
    } else {
      row.entries.set(field.fieldKey, field.numeric === true ? Number(content) : content);
    }
  }

  private addRow(groupKey: string): void {
    const rows = (this.containerRows.get(groupKey) ?? []).slice();
    rows.push(new HarmonyPhpContainerRow(++this.nextRowId, new Map<string, Object | null>()));
    this.containerRows.set(groupKey, rows);
  }

  private removeRow(groupKey: string, rowId: number): void {
    this.containerRows.set(groupKey, (this.containerRows.get(groupKey) ?? []).filter((row: HarmonyPhpContainerRow): boolean =>
      row.rowId !== rowId));
  }

  private containerConfig(): Map<string, Object | null> {
    const config = new Map<string, Object | null>();
    config.set('containerName', this.configValue('containerName').trim());
    this.containerGroups.forEach((group: HarmonyPhpContainerGroup): void => {
      const rows = this.containerRows.get(group.groupKey);
      if (rows === undefined) return;
      config.set(group.groupKey, rows.filter((row: HarmonyPhpContainerRow): boolean => row.entries.size > 0)
        .map((row: HarmonyPhpContainerRow): Map<string, Object | null> => row.entries));
    });
    return config;
  }

  private async save(): Promise<void> {
    if (this.saving) return;
    this.saving = true;
    try {
      const args = this.args();
      args.set('action', 'update');
      if (this.selectedSection === 0) {
        args.set('uploadMaxSize', this.configValue('uploadMaxSize'));
        args.set('maxExecutionTime', this.configValue('maxExecutionTime'));
        args.set('disableFunctions', this.configValue('disableFunctions'));
      } else if (this.selectedSection === 1) {
        args.set('params', this.fpmParams);
      } else if (this.selectedSection === 2) {
        args.set('config', this.containerConfig());
      } else {
        args.set('content', this.configValue('content'));
      }
      await this.bridge.invoke<Object | null>('performNativeRuntimeManagement', args);
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveFailed') });
    } finally {
      this.saving = false;
    }
  }

  @Builder
  private input(labelKey: string, currentText: string, onChange: (entry: string) => void, numeric: boolean = false) {
    Column({ space: 4 }) {
      Text(this.text(labelKey)).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextInput({ text: currentText }).height(48).width('100%').type(numeric ? InputType.Number : InputType.Normal)
        .accessibilityText(this.text(labelKey)).onChange(onChange)
    }.width('100%')
  }

  @Builder
  private basicBody() {
    Column({ space: 12 }) {
      this.input('upload_max_filesize', this.configValue('uploadMaxSize'), (entry: string): void => {
        this.config.set('uploadMaxSize', entry);
      })
      this.input('max_execution_time', this.configValue('maxExecutionTime'), (entry: string): void => {
        this.config.set('maxExecutionTime', entry);
      }, true)
      this.input('disable_functions', this.configValue('disableFunctions'), (entry: string): void => {
        this.config.set('disableFunctions', entry);
      })
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private fpmBody() {
    Column({ space: 12 }) {
      ForEach(this.fpmFields, (field: HarmonyPhpField): void => {
        this.input(field.labelKey, this.fpmParams.get(field.fieldKey) ?? '', (entry: string): void => {
          this.fpmParams.set(field.fieldKey, entry);
        }, field.numeric === true)
      }, (field: HarmonyPhpField): string => field.fieldKey)
      if (this.fpmStatus.length > 0) {
        Divider()
        ForEach(this.fpmStatus, (item: Map<string, Object | null>): void => {
          Row({ space: 8 }) {
            Text(item.get('key')?.toString() ?? '').fontSize(14).fontColor($r('sys.color.font_secondary'))
              .layoutWeight(1)
            Text(item.get('value')?.toString() ?? '').fontSize(16).copyOption(CopyOptions.InApp)
          }.width('100%').constraintSize({ minHeight: 48 })
        }, (item: Map<string, Object | null>): string => item.get('key')?.toString() ?? '')
      }
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private groupEditor(group: HarmonyPhpContainerGroup) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(this.text(group.labelKey)).fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1)
        Button(this.text('commonAdd')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick((): void => { this.addRow(group.groupKey); })
      }.width('100%')
      ForEach(this.containerRows.get(group.groupKey) ?? [], (row: HarmonyPhpContainerRow): void => {
        Column({ space: 8 }) {
          Divider()
          ForEach(group.fields, (field: HarmonyPhpField): void => {
            this.input(field.labelKey, row.entries.get(field.fieldKey)?.toString() ?? '', (entry: string): void => {
              this.updateRow(row, field, entry);
            }, field.numeric === true)
          }, (field: HarmonyPhpField): string => field.fieldKey)
          Button(this.text('commonDelete')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.removeRow(group.groupKey, row.rowId); })
        }.width('100%')
      }, (row: HarmonyPhpContainerRow): string => row.rowId.toString())
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private containerBody() {
    this.input('appInstallContainerName', this.configValue('containerName'), (entry: string): void => {
      this.config.set('containerName', entry);
    })
    ForEach(this.containerGroups, (group: HarmonyPhpContainerGroup): void => {
      this.groupEditor(group)
    }, (group: HarmonyPhpContainerGroup): string => group.groupKey)
  }

  @Builder
  private fileBody() {
    if (this.configValue('path').length > 0) {
      Text(this.configValue('path')).fontSize(14).fontColor($r('sys.color.font_secondary'))
        .width('100%').copyOption(CopyOptions.InApp)
    }
    TextArea({ text: this.configValue('content') }).width('100%').constraintSize({ minHeight: 320 })
      .fontFamily('monospace').accessibilityText(this.text(this.sectionLabels[this.selectedSection]))
      .onChange((entry: string): void => { this.config.set('content', entry); })
  }

  build() {
    Column({ space: 12 }) {
      Select(this.sectionLabels.map((key: string): SelectOption => ({ value: this.text(key) })))
        .height(48).selected(this.selectedSection).value(this.text(this.sectionLabels[this.selectedSection]))
        .enabled(!this.loading && !this.saving).onSelect((index: number): void => { this.selectedSection = index; this.load(); })
      if (this.loading) {
        LoadingProgress().height(40).width(40).accessibilityText(this.text('commonLoading'))
      } else if (this.errorText.length > 0) {
        Text(this.errorText).fontColor($r('sys.color.font_secondary'))
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.selectedSection === 0) {
              this.basicBody()
            } else if (this.selectedSection === 1) {
              this.fpmBody()
            } else if (this.selectedSection === 2) {
              this.containerBody()
            } else {
              this.fileBody()
            }
          }.width('100%')
        }.layoutWeight(1).width('100%').scrollBar(BarState.Auto).enabled(!this.saving)
        Button(this.text('commonSave')).width('100%').height(48).enabled(!this.saving)
          .onClick((): void => { this.save(); })
      }
    }.width('100%').height('100%').padding(16)
  }
}
