import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { automationText, automationString, automationWrite } from './HarmonyAutomationUI';

@Component
export struct HarmonyCronjobForm {
  jobId: number = -1;
  onSaved: () => void = (): void => {};
  @State private draft: Map<string, Object | null> = new Map<string, Object | null>();
  @State private options: Map<string, Object | null> = new Map<string, Object | null>();
  @State private databaseOptions: Map<string, Object | null>[] = [];
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private failure: string = '';
  @State private previews: string[] = [];
  @State private scheduleMode: string = 'daily';
  @State private hour: string = '0';
  @State private minute: string = '0';
  @State private weekday: string = '1';
  @State private monthDay: string = '1';
  @State private interval: string = '1';
  @State private rawSchedule: boolean = true;
  @State private includeImages: boolean = false;
  @State private ignoredApps: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private types: string[] = ['shell', 'curl', 'website', 'database', 'directory', 'app', 'snapshot', 'log'];
  private scheduleModes: string[] = ['daily', 'weekly', 'monthly', 'every_hours', 'every_minutes'];

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      this.options = await this.bridge.invoke<Map<string, Object | null>>('getNativeCronjobOptions');
      if (this.jobId >= 0) {
        const args = new Map<string, Object | null>(); args.set('id', this.jobId);
        this.draft = await this.bridge.invoke<Map<string, Object | null>>('getCronJobInfo', args);
        const snapshot = this.draft.get('snapshotRule') as Map<string, Object | null>;
        this.includeImages = snapshot.get('withImage') === true;
        this.ignoredApps = (snapshot.get('ignoreAppIDs') as number[]).join(',');
      } else {
        const draft = new Map<string, Object | null>();
        draft.set('name', ''); draft.set('type', 'shell'); draft.set('spec', '0 0 * * *');
        draft.set('specCustom', true); draft.set('executor', 'bash'); draft.set('user', 'root');
        draft.set('scriptMode', 'input'); draft.set('script', ''); draft.set('groupID', 0);
        draft.set('retainCopies', 1); draft.set('retryTimes', 0); draft.set('timeout', 3600);
        draft.set('ignoreErr', false); draft.set('isDir', true); draft.set('dbType', 'mysql');
        this.draft = draft;
      }
      if (this.type() === 'database') await this.loadDatabaseOptions();
    } catch (error) { this.failure = (error as Error).message; }
    finally { this.loading = false; }
  }

  private type(): string { return automationString(this.draft, 'type'); }

  private records(key: string): Map<string, Object | null>[] {
    return this.options.get(key) as Map<string, Object | null>[] ?? [];
  }

  private optionList(key: string): SelectOption[] {
    return this.records(key).map((record: Map<string, Object | null>): SelectOption => ({ value: automationString(record, 'name') }));
  }

  private typeOptions(): SelectOption[] {
    const keys: string[] = ['cronjobsTypeShell', 'cronjobFormUrlTypeLabel', 'cronjobsTypeWebsite', 'cronjobsTypeDatabase',
      'cronjobsTypeDirectory', 'backupTypeApp', 'cronjobsTypeSnapshot', 'cronjobsTypeLog'];
    return keys.map((key: string): SelectOption => ({ value: automationText(key) }));
  }

  private async loadDatabaseOptions(): Promise<void> {
    const args = new Map<string, Object | null>(); args.set('type', this.draft.get('dbType') as string);
    this.databaseOptions = await this.bridge.invoke<Map<string, Object | null>[]>('getNativeCronjobDatabaseOptions', args);
  }

  private async preview(): Promise<void> {
    try {
      const args = new Map<string, Object | null>(); args.set('spec', await this.prepareSpec());
      this.previews = await this.bridge.invoke<string[]>('previewNativeCronjobSpec', args);
    } catch (error) { this.toast((error as Error).message); }
  }

  private async prepareSpec(): Promise<string> {
    if (this.rawSchedule) return automationString(this.draft, 'spec');
    const args = new Map<string, Object | null>();
    args.set('mode', this.scheduleMode);
    args.set('hour', Number(this.hour));
    args.set('minute', Number(this.minute));
    args.set('dayOfWeek', Number(this.weekday));
    args.set('dayOfMonth', Number(this.monthDay));
    args.set('interval', Number(this.interval));
    return this.bridge.invoke<string>('buildNativeCronjobSpec', args);
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message.slice(0, 120) });
  }

  private async save(): Promise<void> {
    this.saving = true;
    try {
      this.draft.set('spec', await this.prepareSpec());
      this.draft.set('specCustom', this.rawSchedule);
      if (this.type() === 'snapshot') {
        const snapshot = new Map<string, Object | null>();
        snapshot.set('withImage', this.includeImages);
        const ids = this.ignoredApps.split(',').map((item: string): string => item.trim())
          .filter((item: string): boolean => item.length > 0);
        snapshot.set('ignoreAppIDs', ids.map((item: string): number => Number(item)));
        this.draft.set('snapshotRule', snapshot);
      }
      await automationWrite(this.jobId < 0 ? 'createCronJob' : 'updateCronJob', this.draft);
      this.onSaved();
    } catch (error) { this.toast((error as Error).message); }
    finally { this.saving = false; }
  }

  @Builder
  private field(key: string, labelKey: string, numeric: boolean = false) {
    Column({ space: 8 }) {
      Text(automationText(labelKey)).fontSize(16).width('100%')
      TextInput({ text: automationString(this.draft, key) }).height(48)
        .type(numeric ? InputType.Number : InputType.Normal)
        .onChange((content: string): void => { this.draft.set(key, numeric ? Number(content) : content); })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private textArea(key: string, labelKey: string) {
    Column({ space: 8 }) {
      Text(automationText(labelKey)).fontSize(16).width('100%')
      TextArea({ text: automationString(this.draft, key) }).height(144).fontFamily('monospace')
        .onChange((content: string): void => { this.draft.set(key, content); })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private toggle(key: string, labelKey: string) {
    Row({ space: 12 }) {
      Text(automationText(labelKey)).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.draft.get(key) === true })
        .onChange((selected: boolean): void => { this.draft.set(key, selected); })
    }.width('100%').constraintSize({ minHeight: 48 })
  }

  @Builder
  private schedule() {
    Text(automationText('cronjobFormScheduleSectionTitle')).fontSize(18).fontWeight(FontWeight.Medium).width('100%')
    Row({ space: 12 }) {
      Text(automationText('cronjobFormRawModeLabel')).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.rawSchedule }).onChange((selected: boolean): void => { this.rawSchedule = selected; })
    }.constraintSize({ minHeight: 48 }).width('100%')
    if (this.rawSchedule) {
      this.textArea('spec', 'cronjobsSpecLabel')
    } else {
      Select([
        { value: automationText('cronjobFormScheduleDaily') }, { value: automationText('cronjobFormScheduleWeekly') },
        { value: automationText('cronjobFormScheduleMonthly') }, { value: automationText('cronjobFormScheduleEveryHours') },
        { value: automationText('cronjobFormScheduleEveryMinutes') },
      ]).selected(this.scheduleModes.indexOf(this.scheduleMode)).height(48).width('100%')
        .onSelect((index: number): void => { this.scheduleMode = this.scheduleModes[index]; })
      Row({ space: 12 }) {
        TextInput({ text: this.hour, placeholder: automationText('cronjobFormScheduleHourLabel') }).height(48).type(InputType.Number)
          .layoutWeight(1).onChange((content: string): void => { this.hour = content; })
        TextInput({ text: this.minute, placeholder: automationText('cronjobFormScheduleMinuteLabel') }).height(48).type(InputType.Number)
          .layoutWeight(1).onChange((content: string): void => { this.minute = content; })
      }
      if (this.scheduleMode === 'weekly') {
        TextInput({ text: this.weekday, placeholder: automationText('cronjobFormScheduleWeekdayLabel') }).height(48).type(InputType.Number)
          .onChange((content: string): void => { this.weekday = content; })
      } else if (this.scheduleMode === 'monthly') {
        TextInput({ text: this.monthDay, placeholder: automationText('cronjobFormScheduleDayLabel') }).height(48).type(InputType.Number)
          .onChange((content: string): void => { this.monthDay = content; })
      } else if (this.scheduleMode === 'every_hours' || this.scheduleMode === 'every_minutes') {
        TextInput({ text: this.interval, placeholder: automationText('cronjobFormScheduleIntervalLabel') }).height(48).type(InputType.Number)
          .onChange((content: string): void => { this.interval = content; })
      }
    }
    Button(automationText('cronjobFormPreviewAction')).height(48).onClick((): void => { this.preview(); })
    ForEach(this.previews, (preview: string): void => { Text(preview).fontSize(14).width('100%') }, (preview: string): string => preview)
  }

  @Builder
  private shellTarget() {
    Select([{ value: 'bash' }, { value: 'sh' }, { value: 'python3' }, { value: 'python' }, { value: 'node' }])
      .value(automationString(this.draft, 'executor')).height(48).width('100%')
      .onSelect((index: number, selected: string): void => { this.draft.set('executor', selected); })
    Select([{ value: automationText('cronjobFormShellModeInline') }, { value: automationText('cronjobFormShellModePath') },
      { value: automationText('cronjobFormShellModeLibrary') }]).height(48).width('100%')
      .selected(['input', 'path', 'library'].indexOf(automationString(this.draft, 'scriptMode')))
      .onSelect((index: number): void => { this.draft.set('scriptMode', ['input', 'path', 'library'][index]); })
    if (this.draft.get('scriptMode') === 'library') {
      Select(this.optionList('scripts')).height(48).width('100%')
        .onSelect((index: number): void => { this.draft.set('scriptID', this.records('scripts')[index].get('id') as number); })
    } else {
      this.textArea('script', 'cronjobFormScriptLabel')
    }
    this.field('user', 'cronjobFormUserLabel')
    this.field('args', 'cronjobFormArgumentsLabel')
  }

  @Builder
  private targets() {
    Text(automationText('cronjobFormTargetSectionTitle')).fontSize(18).fontWeight(FontWeight.Medium).width('100%')
    if (this.type() === 'shell') {
      this.shellTarget()
    } else if (this.type() === 'curl') {
      this.textArea('url', 'cronjobFormUrlItemLabel')
    } else {
      if (this.type() === 'website') {
        this.field('website', 'cronjobFormWebsitesLabel')
        ForEach(this.records('websites'), (record: Map<string, Object | null>): void => {
          Button(automationString(record, 'primaryDomain')).height(48).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.draft.set('website', automationString(record, 'id')); })
        }, (record: Map<string, Object | null>): string => `${record.get('id')}`)
      } else if (this.type() === 'app') {
        this.field('appID', 'cronjobFormAppsLabel')
        Select(this.optionList('apps')).height(48).width('100%')
          .onSelect((index: number): void => { this.draft.set('appID', automationString(this.records('apps')[index], 'id')); })
      } else if (this.type() === 'database') {
        Select([{ value: 'mysql' }, { value: 'mariadb' }, { value: 'postgresql' }, { value: 'redis' }])
          .height(48).width('100%').value(automationString(this.draft, 'dbType'))
          .onSelect((index: number, selected: string): void => { this.draft.set('dbType', selected); this.loadDatabaseOptions(); })
        this.field('dbName', 'cronjobFormDatabasesLabel')
        ForEach(this.databaseOptions, (record: Map<string, Object | null>): void => {
          Button(automationString(record, 'name')).height(48).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.draft.set('dbName', automationString(record, 'name')); })
        }, (record: Map<string, Object | null>): string => `${record.get('id')}:${record.get('name')}`)
      } else if (this.type() === 'directory') {
        this.toggle('isDir', 'cronjobFormBackupDirectoryLabel')
        this.textArea('sourceDir', 'cronjobFormDirectoryPathLabel')
      } else if (this.type() === 'snapshot') {
        Row({ space: 12 }) {
          Text(automationText('cronjobFormIncludeImagesLabel')).fontSize(16).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.includeImages }).onChange((selected: boolean): void => { this.includeImages = selected; })
        }.constraintSize({ minHeight: 48 })
        TextInput({ text: this.ignoredApps, placeholder: automationText('cronjobFormIgnoreAppsLabel') }).height(48)
          .onChange((content: string): void => { this.ignoredApps = content; })
      }
      this.field('sourceAccountIDs', 'cronjobFormSourceAccountsLabel')
      Text(automationText('cronjobFormDownloadAccountLabel')).fontSize(16).width('100%')
      Select(this.optionList('accounts')).height(48).width('100%')
        .onSelect((index: number): void => { this.draft.set('downloadAccountID', this.records('accounts')[index].get('id') as number); })
      this.field('exclusionRules', 'cronjobFormExcludePatternsLabel')
      this.field('secret', 'cronjobFormSecretLabel')
      this.field('retainCopies', 'cronjobFormRetainCopiesLabel', true)
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) {
          LoadingProgress().width(48).height(48)
        } else if (this.failure.length > 0) {
          Text(this.failure).fontSize(14)
          Button(automationText('commonRetry')).height(48).onClick((): void => { this.load(); })
        } else {
          this.field('name', 'cronjobNameLabel')
          Select(this.typeOptions()).selected(this.types.indexOf(this.type())).height(48).width('100%')
            .onSelect((index: number): void => { this.draft.set('type', this.types[index]); if (this.type() === 'database') this.loadDatabaseOptions(); })
          Text(automationText('cronjobsGroupLabel')).fontSize(16).width('100%')
          Select(this.optionList('groups')).height(48).width('100%')
            .onSelect((index: number): void => { this.draft.set('groupID', this.records('groups')[index].get('id') as number); })
          this.schedule()
          this.targets()
          Text(automationText('cronjobFormPolicySectionTitle')).fontSize(18).fontWeight(FontWeight.Medium).width('100%')
          this.field('retryTimes', 'cronjobFormRetryTimesLabel', true)
          this.field('timeout', 'commonTimeoutSeconds', true)
          this.toggle('ignoreErr', 'cronjobFormIgnoreErrorsLabel')
          this.field('alertCount', 'cronjobFormAlertCountLabel', true)
          this.field('alertMethod', 'cronjobFormEnableAlertsLabel')
          Button(automationText('commonSave')).height(48).width('100%').enabled(!this.saving)
            .onClick((): void => { this.save(); })
        }
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }
}
