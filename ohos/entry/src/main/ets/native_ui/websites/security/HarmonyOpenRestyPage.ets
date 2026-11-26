import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';

class HarmonyOpenRestyModule {
  name: string;
  enabled: boolean;
  packages: string;
  params: string;
  script: string;

  constructor(record: Map<string, Object | null>) {
    this.name = record.get('name') as string;
    this.enabled = record.get('enable') === true;
    this.packages = record.get('packages') as string | null ?? '';
    this.params = record.get('params') as string | null ?? '';
    this.script = record.get('script') as string | null ?? '';
  }
}

class HarmonyOpenRestyDiff {
  field: string;
  previous: string;
  next: string;

  constructor(record: Map<string, Object | null>) {
    this.field = record.get('field') as string;
    this.previous = record.get('currentValue') as string;
    this.next = record.get('nextValue') as string;
  }
}

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyOpenRestyPage {
  showSourceEditor: boolean = false;
  initialSource: string | null = null;
  onOpenApps: () => void = (): void => {};
  /** 由外层 NavDestination 承载标题栏时，内层导航只负责内容与二级页，避免出现两层标题栏。 */
  @Prop embedded: boolean = false;
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private errorMessage: string = '';
  @State private notInstalled: boolean = false;
  @State private running: boolean = false;
  @State private status: Map<string, Object | null> = new Map<string, Object | null>();
  @State private modules: HarmonyOpenRestyModule[] = [];
  @State private httpsEnabled: boolean = false;
  @State private rejectHandshake: boolean = false;
  @State private moduleEnabled: boolean = false;
  @State private moduleName: string = '';
  @State private modulePackages: string = '';
  @State private moduleParams: string = '';
  @State private moduleScript: string = '';
  @State private configContent: string = '';
  @State private mirror: string = '';
  @State private taskId: string = '';
  @State private buildSubmitted: boolean = false;
  @State private scopeIndex: number = 0;
  @State private scopeWebsiteId: string = '';
  @State private scopeRows: Map<string, Object | null>[] = [];
  @State private previewKind: string = 'Https';
  @State private previewDiffs: HarmonyOpenRestyDiff[] = [];
  @State private previewRisks: Map<string, Object | null>[] = [];
  @State private notices: Map<string, Object | null>[] = [];
  @State private canRestoreHttps: boolean = false;
  @State private canRestoreModules: boolean = false;
  @State private canRestoreConfig: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private paths: NavPathStack = new NavPathStack();
  private scopeNames: string[] = ['index', 'limit-conn', 'ssl', 'cache', 'http-per', 'proxy-cache'];

  aboutToAppear(): void {
    this.load(false).then((): void => {
      if (this.showSourceEditor && this.initialSource !== null) this.configContent = this.initialSource;
    });
  }

  aboutToDisappear(): void {
    this.bridge.invoke<Object | null>('releaseNativeOpenrestyState');
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private stateLabel(enabled: boolean): string {
    return this.text(enabled ? 'systemSettingsEnabled' : 'systemSettingsDisabled');
  }

  private statusSummary(): string {
    if (!this.running) return this.text('openrestyStatusNotRunningSummary');
    return this.text('openrestyStatusRunningSummary')
      .replace('{active}', String(this.status.get('active')));
  }

  private moduleSummary(): string {
    const count = this.modules.filter((module: HarmonyOpenRestyModule): boolean => module.enabled).length;
    return this.text('openrestyModulesEnabledSummary')
      .replace('{enabled}', count.toString()).replace('{total}', this.modules.length.toString());
  }

  private configSummary(): string {
    if (this.configContent.trim().length === 0) return this.text('openrestyConfigNotLoaded');
    return this.text('openrestyConfigLoadedSummary')
      .replace('{lines}', this.configContent.split('\n').length.toString());
  }

  private acceptState(reply: Map<string, Object | null>): void {
    this.errorMessage = reply.get('error') as string | null ?? '';
    this.notInstalled = reply.get('notInstalled') === true;
    this.running = reply.get('running') === true;
    const status = reply.get('status') as Map<string, Object | null> | null;
    this.status = status ?? new Map<string, Object | null>();
    const https = reply.get('https') as Map<string, Object | null> | null;
    this.httpsEnabled = https?.get('https') === true;
    this.rejectHandshake = https?.get('sslRejectHandshake') === true;
    const moduleRecords = reply.get('modules') as Map<string, Object | null>[];
    this.modules = moduleRecords.map((record: Map<string, Object | null>): HarmonyOpenRestyModule =>
      new HarmonyOpenRestyModule(record));
    this.configContent = reply.get('configContent') as string;
    this.mirror = reply.get('mirror') as string | null ?? '';
    this.buildSubmitted = reply.get('lastBuildMessage') !== null;
    this.scopeRows = reply.get('scopeParams') as Map<string, Object | null>[];
    this.canRestoreHttps = reply.get('canRestoreHttps') === true;
    this.canRestoreModules = reply.get('canRestoreModules') === true;
    this.canRestoreConfig = reply.get('canRestoreConfig') === true;
    this.notices = reply.get('risks') as Map<string, Object | null>[];
  }

  private async load(refresh: boolean): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('refresh', refresh);
      this.acceptState(await this.bridge.invoke<Map<string, Object | null>>('getNativeOpenrestyState', args));
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async perform(action: string, args?: Map<string, Object | null>): Promise<Map<string, Object | null> | null> {
    this.saving = true;
    try {
      const payload = args ?? new Map<string, Object | null>();
      payload.set('action', action);
      const reply = await this.bridge.invoke<Map<string, Object | null>>('performNativeOpenrestyAction', payload);
      this.acceptState(reply);
      return reply;
    } catch (error) {
      this.errorMessage = (error as Error).message;
      this.getUIContext().getPromptAction().showToast({ message: this.errorMessage.slice(0, 120) });
      return null;
    } finally {
      this.saving = false;
    }
  }

  private openPage(name: string): void {
    this.paths.pushPathByName(name, null);
  }

  private editModule(module: HarmonyOpenRestyModule): void {
    this.moduleName = module.name;
    this.moduleEnabled = module.enabled;
    this.modulePackages = module.packages;
    this.moduleParams = module.params;
    this.moduleScript = module.script;
    this.openPage('module');
  }

  private async stage(kind: string): Promise<void> {
    const args = new Map<string, Object | null>();
    if (kind === 'Https') {
      args.set('httpsEnabled', this.httpsEnabled);
      args.set('sslRejectHandshake', this.rejectHandshake);
    } else if (kind === 'Module') {
      args.set('name', this.moduleName);
      args.set('enable', this.moduleEnabled);
      args.set('packages', this.modulePackages);
      args.set('params', this.moduleParams);
      args.set('script', this.moduleScript);
    } else {
      args.set('content', this.configContent);
    }
    const reply = await this.perform(`stage${kind}`, args);
    if (reply === null) return;
    const draft = reply.get(`${kind.charAt(0).toLowerCase()}${kind.slice(1)}Draft`) as Map<string, Object | null>;
    this.previewKind = kind;
    this.previewDiffs = (draft.get('diffs') as Map<string, Object | null>[])
      .map((item: Map<string, Object | null>): HarmonyOpenRestyDiff => new HarmonyOpenRestyDiff(item));
    this.previewRisks = draft.get('risks') as Map<string, Object | null>[];
    this.openPage('preview');
  }

  private async applyPreview(): Promise<void> {
    const reply = await this.perform(`apply${this.previewKind}`);
    if (reply?.get('applied') !== true) return;
    this.paths.pop();
    this.paths.pop();
    this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
  }

  private async discardPreview(): Promise<void> {
    await this.perform(`discard${this.previewKind}`);
    this.paths.pop();
  }

  private confirmRestore(kind: string): void {
    this.getUIContext().showAlertDialog({
      title: this.text('openrestyRollbackAction'),
      message: this.text('openrestyPageTitle'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('commonConfirm'),
        action: (): void => { this.perform(`restore${kind}`); },
      },
    });
  }

  private confirmBuild(): void {
    this.getUIContext().showAlertDialog({
      title: this.text('openrestyDialogStartBuildTitle'),
      message: this.text('openrestyDialogBuildRiskHint'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: this.text('commonConfirm'),
        action: (): void => { this.submitBuild(); },
      },
    });
  }

  private async submitBuild(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('mirror', this.mirror.trim());
    args.set('taskId', this.taskId.trim());
    const reply = await this.perform('build', args);
    if (reply?.get('applied') === true) {
      this.getUIContext().getPromptAction().showToast({ message: this.text('openrestyBuildSubmittedMessage') });
    }
  }

  private async saveSource(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('content', this.configContent);
    const reply = await this.perform('saveSource', args);
    if (reply?.get('applied') === true) {
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    }
  }

  private loadScope(): void {
    const args = new Map<string, Object | null>();
    args.set('scope', this.scopeNames[this.scopeIndex]);
    if (this.scopeWebsiteId.trim().length > 0) args.set('websiteId', Number(this.scopeWebsiteId));
    this.perform('loadScope', args);
  }

  private draftField(field: string): string {
    switch (field) {
      case 'operate': return this.text('openrestyDiffLabelHttps');
      case 'sslRejectHandshake': return this.text('openrestyDiffLabelRejectHandshake');
      case 'enable': return this.text('openrestyDiffLabelEnabled');
      case 'packages': return this.text('openrestyDiffLabelPackages');
      case 'params': return this.text('openrestyDiffLabelParams');
      case 'script': return this.text('openrestyDiffLabelScript');
      default: return this.text('openrestyDiffLabelConfigSource');
    }
  }

  private draftValue(content: string): string {
    if (content === 'Enabled' || content === 'enable') return this.stateLabel(true);
    if (content === 'Disabled' || content === 'disable') return this.stateLabel(false);
    return content;
  }

  private riskKey(title: string): string {
    switch (title) {
      case 'Gateway inactive': return 'openrestyRiskGatewayInactive';
      case 'HTTPS disabled': return 'openrestyRiskHttpsDisabled';
      case 'No modules loaded': return 'openrestyRiskNoModules';
      case 'Build mirror missing': return 'openrestyRiskBuildMirrorMissing';
      case 'Reject handshake enabled': return 'openrestyRiskRejectHandshake';
      case 'Module disabled': return 'openrestyRiskModuleDisabled';
      case 'Dependency change': return 'openrestyRiskDependencyChange';
      case 'Empty config': return 'openrestyRiskEmptyConfig';
      case 'Brace mismatch': return 'openrestyRiskBraceMismatch';
      case 'Missing http block': return 'openrestyRiskMissingHttpBlock';
      case 'Temporary markers found': return 'openrestyRiskTemporaryMarkers';
      default: return '';
    }
  }

  private noticeTitle(notice: Map<string, Object | null>): string {
    const title = notice.get('title') as string;
    const key = this.riskKey(title);
    return key.length > 0 ? this.text(`${key}Title`) : title;
  }

  private noticeMessage(notice: Map<string, Object | null>): string {
    const key = this.riskKey(notice.get('title') as string);
    if (key.length === 0) return notice.get('message') as string;
    return this.text(`${key}Message`).replace('{module}', this.moduleName);
  }

  private scopeOptions(): SelectOption[] {
    return this.scopeNames.map((name: string): SelectOption => ({ value: name }));
  }

  private navigationMenus(): NavigationMenuItem[] {
    return [
      {
        value: this.text('commonRefresh'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(true); },
        isEnabled: !this.loading && !this.saving,
      },
      {
        value: this.text('openrestyAdvancedSourceEditorTooltip'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.code')),
        action: (): void => { this.openPage('source'); },
        isEnabled: !this.loading && !this.notInstalled,
      },
    ];
  }

  @Builder
  private metric(label: string, content: string) {
    Row({ space: 12 }) {
      Text(label).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(content).fontSize(16).layoutWeight(1).textAlign(TextAlign.End)
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }

  @Builder
  private entry(label: string, summary: string, destination: string) {
    ListItem() {
      Row({ space: 12 }) {
        Column({ space: 2 }) {
          Text(label).fontSize(16).fontWeight(FontWeight.Medium)
          Text(summary).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }
      .padding(16)
      .width('100%')
      .constraintSize({ minHeight: 72 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
      .borderRadius(16)
      .onClick((): void => { this.openPage(destination); })
      .accessibilityGroup(true)
      .accessibilityText(`${label}, ${summary}`)
    }
  }

  @Builder
  private overview() {
    Column() {
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      }
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontSize(14).padding(16).copyOption(CopyOptions.InApp)
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(true); })
      }
      if (this.notInstalled) {
        Column({ space: 12 }) {
          Text(this.text('openrestyNotInstalledTitle')).fontSize(20)
          Text(this.text('openrestyNotInstalledDescription')).fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          Button(this.text('openrestyGoStore')).height(48).onClick(this.onOpenApps)
        }
        .padding(24)
      } else if (!this.loading) {
        List({ space: 12 }) {
          if (this.notices.length > 0) {
            ListItem() {
              Column({ space: 12 }) {
                ForEach(this.notices, (notice: Map<string, Object | null>): void => {
                  Column({ space: 4 }) {
                    Text(this.noticeTitle(notice)).fontSize(16).fontWeight(FontWeight.Medium)
                    Text(this.noticeMessage(notice)).fontSize(14)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  }.width('100%').alignItems(HorizontalAlign.Start)
                }, (notice: Map<string, Object | null>): string => notice.get('title') as string)
              }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
                .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
            }
          }
          this.entry(this.text('openrestyTabStatus'), this.statusSummary(), 'status')
          this.entry(this.text('openrestyTabHttps'), this.stateLabel(this.httpsEnabled), 'https')
          this.entry(this.text('openrestyTabModules'), this.moduleSummary(), 'modules')
          this.entry(this.text('openrestyTabConfig'), this.configSummary(), 'config')
          this.entry(this.text('openrestyTabBuild'), this.mirror, 'build')
          this.entry(this.text('openrestyTabScope'), this.text('openrestyScopeResultHint'), 'scope')
        }
        .padding(16)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private httpsForm() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Text(this.text('openrestyDialogEnableHttpsLabel')).fontSize(16).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.httpsEnabled })
          .onChange((enabled: boolean): void => { this.httpsEnabled = enabled; })
          .accessibilityText(this.text('openrestyDialogEnableHttpsLabel'))
      }.height(56).width('100%')
      Row({ space: 12 }) {
        Text(this.text('openrestyDialogRejectInvalidHandshakesLabel')).fontSize(16).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.rejectHandshake })
          .onChange((enabled: boolean): void => { this.rejectHandshake = enabled; })
          .accessibilityText(this.text('openrestyDialogRejectInvalidHandshakesLabel'))
      }.constraintSize({ minHeight: 56 }).width('100%')
      Button(this.text('openrestyPreviewDiffAction')).height(48).width('100%').enabled(!this.saving)
        .onClick((): void => { this.stage('Https'); })
      Button(this.text('openrestyRollbackAction')).height(48).width('100%')
        .buttonStyle(ButtonStyleMode.TEXTUAL).enabled(this.canRestoreHttps && !this.saving)
        .onClick((): void => { this.confirmRestore('Https'); })
    }
    .width('100%').padding(16).alignItems(HorizontalAlign.Start)
  }

  @Builder
  private moduleList() {
    List({ space: 12 }) {
      if (this.modules.length === 0) {
        ListItem() { Text(this.text('openrestyNoModulesReturned')).fontSize(14).padding(16) }
      }
      ForEach(this.modules, (module: HarmonyOpenRestyModule): void => {
        ListItem() {
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text(module.name).fontSize(16).fontWeight(FontWeight.Medium)
              Text(module.packages).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text(this.stateLabel(module.enabled)).fontSize(14)
            SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
          }
          .width('100%').constraintSize({ minHeight: 72 }).padding(16)
          .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          .onClick((): void => { this.editModule(module); })
        }
      }, (module: HarmonyOpenRestyModule): string => module.name)
      ListItem() {
        Button(this.text('openrestyRollbackAction')).height(48).width('100%')
          .enabled(this.canRestoreModules && !this.saving)
          .onClick((): void => { this.confirmRestore('Modules'); })
      }
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private moduleForm() {
    Scroll() {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Text(this.text('openrestyDialogEnableModuleLabel')).fontSize(16).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.moduleEnabled })
            .onChange((enabled: boolean): void => { this.moduleEnabled = enabled; })
        }.width('100%').height(56)
        Text(this.text('openrestyDialogPackagesLabel')).fontSize(14)
        TextInput({ text: this.modulePackages }).height(48)
          .onChange((content: string): void => { this.modulePackages = content; })
        Text(this.text('openrestyDialogParamsLabel')).fontSize(14)
        TextInput({ text: this.moduleParams }).height(48)
          .onChange((content: string): void => { this.moduleParams = content; })
        Text(this.text('openrestyDialogScriptLabel')).fontSize(14)
        TextArea({ text: this.moduleScript }).height(180).fontFamily('monospace')
          .onChange((content: string): void => { this.moduleScript = content; })
        Button(this.text('openrestyPreviewDiffAction')).height(48).width('100%').enabled(!this.saving)
          .onClick((): void => { this.stage('Module'); })
      }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private configEditor(directSave: boolean) {
    Column({ space: 12 }) {
      TextArea({ text: this.configContent, placeholder: this.text('openrestyDialogConfigSourceLabel') })
        .fontFamily('monospace').fontSize(14).width('100%').layoutWeight(1)
        .enabled(!this.loading && !this.notInstalled)
        .onChange((content: string): void => { this.configContent = content; })
      if (directSave) {
        Button(this.text('commonSave')).height(48).width('100%').enabled(!this.loading && !this.saving && !this.notInstalled)
          .onClick((): void => { this.saveSource(); })
      } else {
        Button(this.text('openrestyPreviewDiffAction')).height(48).width('100%').enabled(!this.saving)
          .onClick((): void => { this.stage('Config'); })
        Button(this.text('openrestyRollbackAction')).height(48).width('100%')
          .buttonStyle(ButtonStyleMode.TEXTUAL).enabled(this.canRestoreConfig && !this.saving)
          .onClick((): void => { this.confirmRestore('Config'); })
      }
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private buildForm() {
    Column({ space: 16 }) {
      Text(this.text('openrestyDialogBuildRiskHint')).fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(this.text('openrestyBuildMirrorLabel')).fontSize(14)
      TextInput({ text: this.mirror }).height(48).type(InputType.URL)
        .onChange((content: string): void => { this.mirror = content; })
      Text(this.text('openrestyBuildTaskIdLabel')).fontSize(14)
      TextInput({ text: this.taskId }).height(48)
        .onChange((content: string): void => { this.taskId = content; })
      if (this.buildSubmitted) {
        Text(this.text('openrestyBuildSubmittedMessage')).fontSize(14)
      }
      Button(this.text('openrestyBuildAction')).height(48).width('100%').enabled(!this.saving)
        .onClick((): void => { this.confirmBuild(); })
    }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
  }

  @Builder
  private scopeForm() {
    Column({ space: 12 }) {
      Text(this.text('openrestyScopeLabel')).fontSize(14)
      Select(this.scopeOptions()).selected(this.scopeIndex).value(this.scopeNames[this.scopeIndex])
        .height(48).width('100%').onSelect((index: number): void => { this.scopeIndex = index; })
      Text(this.text('openrestyScopeWebsiteIdLabel')).fontSize(14)
      TextInput({ text: this.scopeWebsiteId }).height(48).type(InputType.Number)
        .onChange((content: string): void => { this.scopeWebsiteId = content; })
      Button(this.text('openrestyScopeLoad')).height(48).width('100%').enabled(!this.saving)
        .onClick((): void => { this.loadScope(); })
      List({ space: 8 }) {
        ForEach(this.scopeRows, (record: Map<string, Object | null>): void => {
          ListItem() {
            Column({ space: 4 }) {
              Text(record.get('name') as string).fontSize(16)
              Text((record.get('params') as string[]).join(' ')).fontSize(14).fontFamily('monospace')
            }.alignItems(HorizontalAlign.Start).width('100%').padding(16)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }
        }, (record: Map<string, Object | null>): string => record.get('name') as string)
      }.width('100%').layoutWeight(1)
    }.width('100%').height('100%').padding(16).alignItems(HorizontalAlign.Start)
  }

  @Builder
  private preview() {
    Column({ space: 16 }) {
      List({ space: 12 }) {
        ForEach(this.previewDiffs, (diff: HarmonyOpenRestyDiff): void => {
          ListItem() {
            Column({ space: 8 }) {
              Text(this.draftField(diff.field)).fontSize(16).fontWeight(FontWeight.Medium)
              Text(`${this.draftValue(diff.previous)} → ${this.draftValue(diff.next)}`).fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }
        }, (diff: HarmonyOpenRestyDiff): string => diff.field)
        ForEach(this.previewRisks, (risk: Map<string, Object | null>): void => {
          ListItem() {
            Column({ space: 4 }) {
              Text(this.noticeTitle(risk)).fontSize(16)
              Text(this.noticeMessage(risk)).fontSize(14)
            }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
          }
        }, (risk: Map<string, Object | null>): string => risk.get('title') as string)
      }.width('100%').layoutWeight(1)
      Button(this.text('commonConfirm')).height(48).width('100%')
        .enabled(!this.saving && this.previewDiffs.length > 0)
        .onClick((): void => { this.applyPreview(); })
      Button(this.text('commonCancel')).height(48).width('100%').enabled(!this.saving)
        .buttonStyle(ButtonStyleMode.TEXTUAL).onClick((): void => { this.discardPreview(); })
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private destination(name: string, parameter: Object) {
    NavDestination() {
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontSize(14).padding(16).copyOption(CopyOptions.InApp)
      }
      if (name === 'status') {
        Column() {
          this.metric(this.text('openrestyRunningStatusLabel'), this.statusSummary())
          ForEach(['active', 'accepts', 'handled', 'requests', 'reading', 'writing', 'waiting'], (field: string): void => {
            this.metric(field, String(this.status.get(field) ?? '—'))
          }, (field: string): string => field)
        }.width('100%').padding(16)
      } else if (name === 'https') {
        this.httpsForm()
      } else if (name === 'modules') {
        this.moduleList()
      } else if (name === 'module') {
        this.moduleForm()
      } else if (name === 'config') {
        this.configEditor(false)
      } else if (name === 'source') {
        this.configEditor(true)
      } else if (name === 'build') {
        this.buildForm()
      } else if (name === 'scope') {
        this.scopeForm()
      } else if (name === 'preview') {
        this.preview()
      }
    }
    .title(this.destinationTitle(name), { barStyle: BarStyle.STANDARD })
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
  }

  private destinationTitle(name: string): string {
    if (name === 'module') return this.moduleName;
    if (name === 'preview') return this.text(`openresty${this.previewKind}DiffPreviewTitle`);
    if (name === 'source') return this.text('openrestyAdvancedSourceEditorTooltip');
    return this.text(`openrestyTab${name.charAt(0).toUpperCase()}${name.slice(1)}`);
  }

  build() {
    Navigation(this.paths) {
      if (this.showSourceEditor) {
        this.configEditor(true)
      } else {
        this.overview()
      }
    }
    .title(this.text(this.showSourceEditor ? 'openrestyAdvancedSourceEditorTooltip' : 'openrestyPageTitle'),
      { barStyle: BarStyle.STANDARD })
    .titleMode(NavigationTitleMode.Mini)
    .hideTitleBar(this.embedded)
    .menus(this.showSourceEditor ? [] : this.navigationMenus())
    .navDestination(this.destination)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
  }
}
