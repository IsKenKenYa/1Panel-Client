import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';

interface HarmonyRuntimeInputField {
  name: string;
  label: string;
}

@Component
export struct HarmonyRuntimeForm {
  runtimeId?: number;
  initialType: string = 'node';
  onSaved: () => void = (): void => {};

  @State private draft: Map<string, Object | null> = new Map<string, Object | null>();
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private loadError: boolean = false;
  @State private saveError: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private runtimeTypes: string[] = ['node', 'java', 'go', 'python', 'dotnet'];
  private typeLabels: string[] = ['runtimeTypeNode', 'runtimeTypeJava', 'runtimeTypeGo', 'runtimeTypePython', 'runtimeTypeDotnet'];
  private readonly configFields: HarmonyRuntimeInputField[] = [
    { name: 'image', label: 'runtimeFieldImage' },
    { name: 'codeDir', label: 'runtimeFieldCodeDir' },
    { name: 'port', label: 'runtimeFieldExternalPort' },
    { name: 'source', label: 'runtimeFieldSource' },
    { name: 'hostIp', label: 'runtimeFieldHostIp' },
    { name: 'containerName', label: 'runtimeFieldContainerName' },
  ];

  aboutToAppear(): void {
    this.load(this.initialType);
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private field(name: string): string {
    return this.draft.get(name)?.toString() ?? '';
  }

  private async load(type: string, changeType: boolean = false): Promise<void> {
    this.loading = true;
    this.loadError = false;
    this.saveError = '';
    const args = new Map<string, Object | null>();
    if (this.runtimeId !== undefined) args.set('id', this.runtimeId);
    args.set('type', this.runtimeTypes.includes(type) ? type : 'node');
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('getNativeRuntimeForm', args);
      if (changeType) {
        const next = new Map<string, Object | null>(this.draft);
        ['type', 'image', 'source', 'execScript', 'packageManager'].forEach((key: string): void => {
          next.set(key, result.get(key) ?? null);
        });
        this.draft = next;
      } else {
        this.draft = result;
      }
    } catch (error) {
      this.loadError = true;
    } finally {
      this.loading = false;
    }
  }

  private validationLabel(key: string): string {
    switch (key) {
      case 'runtime.form.nameRequired': return 'runtimeFormNameRequired';
      case 'runtime.form.imageRequired': return 'runtimeFormImageRequired';
      case 'runtime.form.codeDirRequired': return 'runtimeFormCodeDirRequired';
      case 'runtime.form.portInvalid': return 'runtimeFormPortInvalid';
      case 'runtime.form.containerRequired': return 'runtimeFormContainerNameRequired';
      case 'runtime.form.execScriptRequired': return 'runtimeFormExecScriptRequired';
      case 'runtime.form.packageManagerRequired': return 'runtimeFormPackageManagerRequired';
      default: return 'runtimeFormSaveFailed';
    }
  }

  private async save(): Promise<void> {
    const args = new Map<string, Object | null>(this.draft);
    if (this.runtimeId !== undefined) args.set('id', this.runtimeId);
    const port = Number(this.field('port'));
    if (!Number.isInteger(port) || port <= 0) {
      this.saveError = this.text('runtimeFormPortInvalid');
      return;
    }
    args.set('port', port);
    this.saving = true;
    this.saveError = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null> | null>('saveNativeRuntime', args);
      if (result !== null) {
        this.saveError = this.text(this.validationLabel(result.get('error')?.toString() ?? ''));
      } else {
        this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
        this.onSaved();
      }
    } catch (error) {
      this.saveError = this.text('runtimeFormSaveFailed');
    } finally {
      this.saving = false;
    }
  }

  private currentTypeLabel(): string {
    if (this.field('type') === 'php') return this.text('runtimeTypePhp');
    const index = this.runtimeTypes.indexOf(this.field('type'));
    return index < 0 ? this.field('type') : this.text(this.typeLabels[index]);
  }

  @Builder
  private heading(labelKey: string) {
    Text(this.text(labelKey))
      .fontSize(14)
      .fontColor($r('sys.color.font_secondary'))
      .padding({ left: 12, bottom: 4 })
      .width('100%')
  }

  @Builder
  private input(name: string, labelKey: string, inputType: InputType = InputType.Normal) {
    Column({ space: 6 }) {
      Text(this.text(labelKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      TextInput({ text: this.field(name) })
        .type(inputType)
        .constraintSize({ minHeight: 48 })
        .accessibilityText(this.text(labelKey))
        .onChange((entry: string): void => { this.draft.set(name, entry); })
    }.alignItems(HorizontalAlign.Start).width('100%')
  }

  @Builder
  private basics() {
    Column({ space: 12 }) {
      this.input('name', 'commonName')
      Row({ space: 12 }) {
        Text(this.text('runtimeFieldType')).layoutWeight(1)
        if (this.runtimeId === undefined) {
          Select(this.typeLabels.map((key: string): SelectOption => ({ value: this.text(key) })))
            .selected(this.runtimeTypes.indexOf(this.field('type')))
            .value(this.currentTypeLabel())
            .height(48)
            .accessibilityText(this.text('runtimeFieldType'))
            .onSelect((index: number): void => { this.load(this.runtimeTypes[index], true); })
        } else {
          Text(this.currentTypeLabel()).fontColor($r('sys.color.font_secondary'))
        }
      }.width('100%').constraintSize({ minHeight: 48 })
      if (this.runtimeId !== undefined && this.field('resource').length > 0) {
        Row({ space: 12 }) {
          Text(this.text('runtimeFieldResource')).layoutWeight(1)
          Text(this.text(this.field('resource') === 'appstore' ? 'runtimeResourceAppStore' : 'runtimeResourceLocal'))
            .fontColor($r('sys.color.font_secondary'))
        }.width('100%').constraintSize({ minHeight: 48 })
      }
      this.input('version', 'runtimeFieldVersion')
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private configuration() {
    Column({ space: 12 }) {
      ForEach(this.configFields, (field: HarmonyRuntimeInputField): void => {
        this.input(field.name, field.label, field.name === 'port' ? InputType.Number : InputType.Normal)
      }, (field: HarmonyRuntimeInputField): string => field.name)
      if (this.field('type') !== 'php') {
        this.input('execScript', 'runtimeFieldExecScript')
      }
      if (this.field('type') === 'node') {
        Row({ space: 12 }) {
          Text(this.text('runtimeFieldPackageManager')).layoutWeight(1)
          Select([{ value: 'npm' }, { value: 'yarn' }, { value: 'pnpm' }])
            .height(48)
            .value(this.field('packageManager'))
            .accessibilityText(this.text('runtimeFieldPackageManager'))
            .onSelect((_: number, manager: string): void => { this.draft.set('packageManager', manager); })
        }.width('100%')
      }
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private advanced() {
    Column({ space: 12 }) {
      Text(this.text('runtimeFieldRemark')).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextArea({ text: this.field('remark') })
        .constraintSize({ minHeight: 80 })
        .accessibilityText(this.text('runtimeFieldRemark'))
        .onChange((remark: string): void => { this.draft.set('remark', remark); })
      if (this.runtimeId !== undefined) {
        Row({ space: 12 }) {
          Text(this.text('runtimeFieldRebuild')).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.draft.get('rebuild') === true })
            .accessibilityText(this.text('runtimeFieldRebuild'))
            .onChange((rebuild: boolean): void => { this.draft.set('rebuild', rebuild); })
        }.width('100%')
      }
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  build() {
    Column({ space: 12 }) {
      if (this.loading) {
        LoadingProgress().height(40).width(40).accessibilityText(this.text('commonLoading'))
      } else if (this.loadError) {
        Text(this.text('runtimeFormLoadFailed')).fontColor($r('sys.color.font_secondary'))
        Button(this.text('commonRetry')).height(48)
          .onClick((): void => { this.load(this.initialType); })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            this.heading('runtimeFormBasicSectionTitle')
            this.basics()
            this.heading('runtimeFormRuntimeSectionTitle')
            this.configuration()
            this.heading('runtimeFormAdvancedSectionTitle')
            this.advanced()
            if (this.saveError.length > 0) {
              Text(this.saveError).fontColor($r('sys.color.font_primary')).width('100%')
            }
          }.padding(16).width('100%')
        }.width('100%').layoutWeight(1).scrollBar(BarState.Auto).enabled(!this.saving)
        Button(this.text('commonSave')).width('100%').height(48).enabled(!this.saving)
          .onClick((): void => { this.save(); })
      }
    }.padding({ left: 8, right: 8, top: 12, bottom: 12 }).width('100%').height('100%')
  }
}
