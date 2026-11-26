import { HarmonyNativeBridge, menuMaterial } from '../../HarmonyNativeBridge';

interface HarmonyRuntimeDetailField {
  key: string;
  label: string;
}

@Component
export struct HarmonyRuntimeDetail {
  runtimeId?: number;
  @Prop @Watch('refresh') refreshVersion: number = 0;
  onEdit: (id: number) => void = (_: number): void => {};
  onChanged: () => void = (): void => {};
  onDeleted: () => void = (): void => {};
  onAdvanced: (section: string, id: number) => void = (_: string, __: number): void => {};

  @State private runtime: Map<string, Object | null> = new Map<string, Object | null>();
  @State private parameters: string[] = [];
  @State private loading: boolean = true;
  @State private loadError: boolean = false;
  @State private operating: boolean = false;
  @State private remark: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private configFields: HarmonyRuntimeDetailField[] = [
    { key: 'image', label: 'runtimeFieldImage' },
    { key: 'codeDir', label: 'runtimeFieldCodeDir' },
    { key: 'path', label: 'runtimeFieldPath' },
    { key: 'source', label: 'runtimeFieldSource' },
    { key: 'port', label: 'runtimeFieldExternalPort' },
    { key: 'container', label: 'runtimeFieldContainerName' },
    { key: 'containerStatus', label: 'runtimeFieldContainerStatus' },
  ];

  aboutToAppear(): void {
    this.load();
  }

  private refresh(): void {
    this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private field(name: string): string {
    return this.runtime.get(name)?.toString() ?? '';
  }

  private args(): Map<string, Object | null> {
    const id = this.runtimeId;
    if (id === undefined || id === null) throw new Error(this.text('runtimeDetailLoadFailed'));
    const args = new Map<string, Object | null>();
    args.set('id', id);
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.loadError = false;
    try {
      this.runtime = await this.bridge.invoke<Map<string, Object | null>>('getNativeRuntimeDetail', this.args());
      this.remark = this.field('remark');
      const params = this.runtime.get('params') as Map<string, Object | null> | null | undefined;
      const pairs: string[] = [];
      params?.forEach((entry: Object | null, key: string): void => {
        pairs.push(`${key}: ${entry?.toString() ?? ''}`);
      });
      this.parameters = pairs;
    } catch (error) {
      this.loadError = true;
    } finally {
      this.loading = false;
    }
  }

  private confirm(title: string, message: string, action: () => void): void {
    this.getUIContext().showAlertDialog({
      title: title,
      message: message,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: title, action: action },
    });
  }

  private async change(method: string, errorLabel: string, argument?: string, content?: string): Promise<void> {
    if (this.operating) return;
    this.operating = true;
    try {
      const args = this.args();
      if (argument !== undefined) args.set(argument, content ?? null);
      await this.bridge.invoke<Object | null>(method, args);
      if (method === 'deleteNativeRuntime') {
        this.getUIContext().getPromptAction().showToast({ message: this.text('commonDeleted') });
        this.onDeleted();
      } else {
        if (method === 'updateNativeRuntimeRemark') {
          this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
        }
        await this.load();
        this.onChanged();
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: this.text(errorLabel) });
    } finally {
      this.operating = false;
    }
  }

  private confirmOperation(operation: string, titleKey: string): void {
    const title = this.text(titleKey);
    const message = this.text('runtimeOperateConfirm').replace('{action}', title).replace('{name}', this.field('name'));
    this.confirm(title, message, (): void => { this.change('operateNativeRuntime', 'runtimeOperateFailed', 'operation', operation); });
  }

  private async confirmDelete(): Promise<void> {
    if (this.operating) return;
    this.operating = true;
    try {
      const dependencies = await this.bridge.invoke<string[]>('checkNativeRuntimeDelete', this.args());
      let message = this.text('runtimeDeleteConfirm').replace('{name}', this.field('name'));
      if (dependencies.length > 0) {
        message += `\n\n${this.text('openrestyRiskDependencyChangeTitle')}\n${dependencies.join('\n')}`;
      }
      this.confirm(this.text('commonDelete'), message, (): void => { this.change('deleteNativeRuntime', 'runtimeDeleteFailed'); });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: this.text('runtimeDeleteFailed') });
    } finally {
      this.operating = false;
    }
  }

  private saveRemark(): void {
    if (this.remark.trim().length > 128) {
      this.getUIContext().getPromptAction().showToast({ message: this.text('runtimeRemarkTooLong') });
      return;
    }
    this.change('updateNativeRuntimeRemark', 'runtimeRemarkSaveFailed', 'remark', this.remark);
  }

  private menu(): MenuElement[] {
    const items: MenuElement[] = [
      { value: this.text('runtimeActionSync'), action: (): void => { this.change('syncNativeRuntimes', 'runtimeSyncFailed'); } },
    ];
    const id = this.runtimeId;
    if (id !== undefined && id !== null && this.runtime.get('canEdit') === true) {
      items.push({ value: this.text('commonEdit'), action: (): void => { this.onEdit(id); } });
    }
    if (this.runtime.get('canStart') === true) {
      items.push({ value: this.text('runtimeActionStart'), action: (): void => { this.confirmOperation('up', 'runtimeActionStart'); } });
    }
    if (this.runtime.get('canStop') === true) {
      items.push({ value: this.text('runtimeActionStop'), action: (): void => { this.confirmOperation('down', 'runtimeActionStop'); } });
    }
    if (this.runtime.get('canRestart') === true) {
      items.push({ value: this.text('runtimeActionRestart'), action: (): void => { this.confirmOperation('restart', 'runtimeActionRestart'); } });
    }
    items.push({ value: this.text('commonDelete'), action: (): void => { this.confirmDelete(); } });
    return items;
  }

  private typeLabel(): string {
    const kind = this.field('type');
    switch (kind) {
      case 'php': return this.text('runtimeTypePhp');
      case 'node': return this.text('runtimeTypeNode');
      case 'java': return this.text('runtimeTypeJava');
      case 'go': return this.text('runtimeTypeGo');
      case 'python': return this.text('runtimeTypePython');
      case 'dotnet': return this.text('runtimeTypeDotnet');
      default: return kind;
    }
  }

  private statusLabel(status: string): string {
    switch (status) {
      case 'Running': return this.text('runtimeStatusRunning');
      case 'Stopped': return this.text('runtimeStatusStopped');
      case 'Error': return this.text('runtimeStatusError');
      case 'Starting': return this.text('runtimeStatusStarting');
      case 'Building': return this.text('runtimeStatusBuilding');
      case 'Recreating': return this.text('runtimeStatusRecreating');
      case 'SystemRestart': return this.text('runtimeStatusSystemRestart');
      default: return status;
    }
  }

  @Builder
  private propertyRow(labelKey: string, itemText: string) {
    if (itemText.length > 0) {
      Row({ space: 12 }) {
        Text(this.text(labelKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
        Text(itemText).fontSize(16).layoutWeight(1).textAlign(TextAlign.End).copyOption(CopyOptions.InApp)
      }.width('100%').constraintSize({ minHeight: 48 })
    }
  }

  @Builder
  private advancedLink(section: string, titleKey: string) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Text(this.text(titleKey)).fontColor($r('sys.color.font_primary')).fontSize(16).layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.icon_tertiary')])
      }.width('100%').padding(12)
    }.width('100%').constraintSize({ minHeight: 48 }).buttonStyle(ButtonStyleMode.TEXTUAL)
      .onClick((): void => {
        const id = this.runtimeId;
        if (id !== undefined && id !== null) this.onAdvanced(section, id);
      })
  }

  @Builder
  private overview() {
    Column() {
      this.propertyRow('runtimeFieldType', this.typeLabel())
      this.propertyRow('runtimeFieldStatus', this.statusLabel(this.field('status')))
      this.propertyRow('runtimeFieldVersion', this.field('version'))
      this.propertyRow('runtimeFieldResource', this.field('resource') === 'appstore' ?
        this.text('runtimeResourceAppStore') : (this.field('resource') === 'local' ? this.text('runtimeResourceLocal') : this.field('resource')))
      this.propertyRow('runtimeFieldCreatedAt', this.field('createdAt'))
      if (this.field('message').length > 0) {
        Text(this.field('message')).width('100%').padding({ top: 8, bottom: 8 }).copyOption(CopyOptions.InApp)
      }
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private configuration() {
    Column() {
      ForEach(this.configFields, (field: HarmonyRuntimeDetailField): void => {
        this.propertyRow(field.label, this.field(field.key))
      }, (field: HarmonyRuntimeDetailField): string => field.key)
      if (this.parameters.length > 0) {
        Text(this.text('runtimeFieldParams')).fontSize(14).fontColor($r('sys.color.font_secondary'))
          .width('100%').padding({ top: 8, bottom: 8 })
        ForEach(this.parameters, (pair: string): void => {
          Text(pair).width('100%').padding({ bottom: 8 }).copyOption(CopyOptions.InApp)
        }, (pair: string): string => pair)
      }
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private remarks() {
    Column({ space: 8 }) {
      Text(this.text('runtimeFieldRemark')).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextArea({ text: this.remark }).constraintSize({ minHeight: 80 }).maxLength(128)
        .accessibilityText(this.text('runtimeFieldRemark'))
        .onChange((content: string): void => { this.remark = content; })
      Button(this.text('commonSave')).height(48).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
        .enabled(!this.operating && this.remark !== this.field('remark'))
        .onClick((): void => { this.saveRemark(); })
    }.padding(16).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
  }

  @Builder
  private advanced() {
    if (this.field('type') === 'php' || this.field('type') === 'node') {
      Column() {
        if (this.runtime.get('canOpenAdvanced') !== true) {
          Text(this.text('runtimeAdvancedRequiresRunning')).fontSize(14).fontColor($r('sys.color.font_secondary')).padding(12)
        } else if (this.field('type') === 'php') {
          this.advancedLink('php/extensions', 'operationsPhpExtensionsTitle')
          this.advancedLink('php/config', 'operationsPhpConfigTitle')
          this.advancedLink('php/supervisor', 'operationsSupervisorTitle')
        } else {
          this.advancedLink('node/modules', 'operationsNodeModulesTitle')
          this.advancedLink('node/scripts', 'operationsNodeScriptsTitle')
        }
      }.padding(4).width('100%').borderRadius(16).backgroundColor($r('sys.color.comp_background_primary'))
    }
  }

  build() {
    Column({ space: 12 }) {
      if (this.loading) {
        LoadingProgress().width(40).height(40).accessibilityText(this.text('commonLoading'))
      } else if (this.loadError) {
        Text(this.text('runtimeDetailLoadFailed')).fontColor($r('sys.color.font_secondary'))
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Text(this.field('name')).fontSize(24).fontWeight(FontWeight.Medium).layoutWeight(1)
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(21) }
                .height(48).width(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.operating)
                .accessibilityText(this.text('commonMore'))
                .bindMenu(this.menu(), { systemMaterial: menuMaterial })
            }.width('100%')
            this.overview()
            this.configuration()
            this.advanced()
            this.remarks()
          }.width('100%').padding(16)
        }.width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      }
    }.width('100%').height('100%')
  }
}
