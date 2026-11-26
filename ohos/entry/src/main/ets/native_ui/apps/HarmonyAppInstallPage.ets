import { common } from '@kit.AbilityKit';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

class HarmonyInstallOption {
  label: string;
  optionValue: string;
  configuration: Map<string, Object | null> | null;
  constructor(data: Map<string, Object | null>) {
    this.label = data.get('label') as string;
    this.optionValue = data.get('value') as string;
    this.configuration = data.get('config') as Map<string, Object | null> | null ?? null;
  }
}

class HarmonyInstallField {
  envKey: string;
  labelZh: string;
  labelEn: string;
  fieldType: string;
  required: boolean;
  initialValue: string;
  appKey: string;
  options: HarmonyInstallOption[];
  childKey: string;
  childRequired: boolean;
  multiple: boolean;
  allowCreate: boolean;
  disabled: boolean;
  random: boolean;
  initialValues: string[];
  descriptions: Map<string, string> | null;
  dependentParams: Array<Map<string, Object | null>>;
  constructor(data: Map<string, Object | null>) {
    this.envKey = data.get('envKey') as string;
    this.labelZh = data.get('labelZh') as string;
    this.labelEn = data.get('labelEn') as string;
    this.fieldType = data.get('type') as string;
    this.required = data.get('required') as boolean;
    this.initialValue = data.get('defaultValue') as string | null ?? '';
    this.appKey = data.get('key') as string | null ?? '';
    this.options = (data.get('values') as Array<Map<string, Object | null>>)
      .map((option: Map<string, Object | null>): HarmonyInstallOption => new HarmonyInstallOption(option));
    const child = data.get('child') as Map<string, Object | null> | null;
    this.childKey = child === null ? '' : child.get('envKey') as string;
    this.childRequired = child !== null && (child.get('required') === true || this.required);
    this.multiple = data.get('multiple') === true;
    this.allowCreate = data.get('allowCreate') === true;
    this.disabled = data.get('disabled') === true;
    this.random = data.get('random') === true;
    const rawDefault = data.get('defaultValueRaw');
    this.initialValues = Array.isArray(rawDefault) ? rawDefault as string[] : [];
    this.descriptions = data.get('description') as Map<string, string> | null ?? null;
    this.dependentParams = data.get('params') as Array<Map<string, Object | null>> | null ?? [];
  }
}

class HarmonyInstallPair {
  pairId: number;
  pairKey: string = '';
  pairValue: string = '';
  constructor(pairId: number) {
    this.pairId = pairId;
  }
}

class HarmonyInstallDatabaseFormat {
  format: string;
  collations: string[];
  constructor(data: Map<string, Object | null>) {
    this.format = data.get('format') as string;
    this.collations = data.get('collations') as string[] | null ?? [];
  }
}

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyAppInstallPage {
  @Require @Prop appId: number;
  @Require @Prop appKey: string;
  @Require @Prop appName: string;
  @Require @Prop appType: string;
  @Require @Prop versions: string[];
  @State private installName: string = '';
  @State private selectedVersion: string = '';
  @State private fields: HarmonyInstallField[] = [];
  @State private parameters: Map<string, string> = new Map<string, string>();
  @State private multipleValues: Map<string, string[]> = new Map<string, string[]>();
  @State private customValues: Map<string, string> = new Map<string, string>();
  @State private additionalOptions: Map<string, HarmonyInstallOption[]> = new Map<string, HarmonyInstallOption[]>();
  @State private serviceOptions: Map<string, HarmonyInstallOption[]> = new Map<string, HarmonyInstallOption[]>();
  @State private databaseFormats: HarmonyInstallDatabaseFormat[] = [];
  @State private selectedFormat: string = 'utf8mb4';
  @State private selectedCollation: string = '';
  @State private advanced: boolean = false;
  @State private containerName: string = '';
  @State private cpuQuota: string = '';
  @State private memoryLimit: string = '';
  @State private memoryUnit: string = 'MB';
  @State private allowPort: boolean = false;
  @State private hostMode: boolean = false;
  @State private pullImage: boolean = true;
  @State private editCompose: boolean = false;
  @State private dockerCompose: string = '';
  @State private environment: HarmonyInstallPair[] = [];
  @State private loading: boolean = false;
  @State private saving: boolean = false;
  @State private errorMessage: string = '';
  @State private language: string = 'en';
  private detailId: number | null = null;
  private nextPairId: number = 0;
  private active: boolean = false;
  private serviceKinds: Map<string, string> = new Map<string, string>();
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.active = true;
    this.installName = this.appName;
    this.containerName = this.appName;
    this.selectedVersion = this.versions.length > 0 ? this.versions[0] : '';
    this.loadForm();
  }

  aboutToDisappear(): void {
    this.active = false;
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private fieldLabel(field: HarmonyInstallField): string {
    const label = this.language.startsWith('zh') ? field.labelZh : field.labelEn;
    return field.required ? `${label} *` : label;
  }

  private inputType(field: HarmonyInstallField): InputType {
    if (field.fieldType === 'password') return InputType.Password;
    if (field.fieldType === 'number') return InputType.NUMBER_DECIMAL;
    return InputType.Normal;
  }

  private async loadForm(): Promise<void> {
    if (this.selectedVersion.length === 0) return;
    this.loading = true;
    this.errorMessage = '';
    this.detailId = null;
    this.fields = [];
    try {
      const settings = await this.bridge.invoke<Map<string, Object | null>>('getSettings');
      const language = settings.get('language') as string;
      if (language === 'system') {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        this.language = context.resourceManager.getConfigurationSync().locale;
      } else {
        this.language = language;
      }
      const args = new Map<string, Object | null>();
      args.set('appId', this.appId);
      args.set('version', this.selectedVersion);
      args.set('type', this.appType);
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getAppInstallForm', args);
      this.detailId = reply.get('appDetailId') as number;
      this.hostMode = reply.get('hostMode') === true;
      this.dockerCompose = reply.get('dockerCompose') as string | null ?? '';
      this.fields = (reply.get('fields') as Array<Map<string, Object | null>>)
        .map((field: Map<string, Object | null>): HarmonyInstallField => new HarmonyInstallField(field));
      this.parameters = new Map<string, string>();
      this.multipleValues = new Map<string, string[]>();
      this.additionalOptions = new Map<string, HarmonyInstallOption[]>();
      this.serviceOptions = new Map<string, HarmonyInstallOption[]>();
      this.serviceKinds = new Map<string, string>();
      this.databaseFormats = [];
      this.selectedFormat = 'utf8mb4';
      this.selectedCollation = '';
      for (const field of this.fields) {
        this.parameters.set(field.envKey, field.random
          ? `${field.initialValue}_${Math.random().toString(36).slice(2, 8)}` : field.initialValue);
        this.multipleValues.set(field.envKey, field.initialValues.slice());
        if (field.fieldType === 'text' && field.envKey === 'WEBSITE_DIR') {
          this.parameters.set(field.envKey, await this.bridge.invoke<string>('loadAppWebsiteDir'));
        }
      }
      for (const field of this.fields) {
        if (field.fieldType === 'service') {
          await this.loadServices(field.envKey, field.appKey);
        } else if (field.fieldType === 'apps' && field.childKey.length > 0) {
          this.applyDependencyParams(field, field.initialValue);
          await this.loadServices(field.childKey, field.initialValue);
        }
      }
    } catch (error) {
      this.detailId = null;
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async loadServices(envKey: string, key: string): Promise<void> {
    this.parameters.set(envKey, '');
    this.serviceKinds.set(envKey, key);
    if (key.length === 0) {
      this.serviceOptions.set(envKey, []);
      return;
    }
    const args = new Map<string, Object | null>();
    args.set('key', key);
    const services = await this.bridge.invoke<Array<Map<string, Object | null>>>('getAppServices', args);
    const options = services
      .filter((service: Map<string, Object | null>): boolean => service.get('status') === 'Running')
      .map((service: Map<string, Object | null>): HarmonyInstallOption => new HarmonyInstallOption(service));
    this.serviceOptions.set(envKey, options);
    if (options.length > 0) await this.chooseService(envKey, 0);
  }

  private async chooseService(envKey: string, index: number): Promise<void> {
    const option = (this.serviceOptions.get(envKey) ?? [])[index];
    this.parameters.set(envKey, option.optionValue);
    option.configuration?.forEach((content: Object | null, key: string): void => {
      if (this.parameters.has(key)) this.parameters.set(key, content === null ? '' : `${content}`);
    });
    const key = this.serviceKinds.get(envKey);
    if ((key === 'mysql' || key === 'mariadb') && this.parameters.has('PANEL_DB_HOST')) {
      const args = new Map<string, Object | null>();
      args.set('database', option.optionValue);
      const reply = await this.bridge.invoke<Array<Map<string, Object | null>>>('loadAppDatabaseFormats', args);
      this.databaseFormats = reply.map((format: Map<string, Object | null>): HarmonyInstallDatabaseFormat =>
        new HarmonyInstallDatabaseFormat(format));
      this.selectedCollation = '';
    }
  }

  private async changeService(envKey: string, index: number): Promise<void> {
    try {
      await this.chooseService(envKey, index);
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private hasDatabaseFormat(field: HarmonyInstallField): boolean {
    const selected = this.parameters.get(field.envKey);
    return this.parameters.has('PANEL_DB_HOST') && (selected === 'mysql' || selected === 'mariadb');
  }

  private collationOptions(): string[] {
    return this.databaseFormats.find((entry: HarmonyInstallDatabaseFormat): boolean =>
      entry.format === this.selectedFormat)?.collations ?? [];
  }

  private changeMultiple(field: HarmonyInstallField, option: HarmonyInstallOption, selected: boolean): void {
    const values = this.multipleValues.get(field.envKey) ?? [];
    this.multipleValues.set(field.envKey, selected ? values.concat([option.optionValue])
      : values.filter((entry: string): boolean => entry !== option.optionValue));
  }

  private addCustom(field: HarmonyInstallField): void {
    const content = (this.customValues.get(field.envKey) ?? '').trim();
    if (content.length === 0) return;
    if (this.optionsFor(field).some((option: HarmonyInstallOption): boolean => option.optionValue === content)) return;
    const data = new Map<string, Object | null>();
    data.set('label', content);
    data.set('value', content);
    const options = this.additionalOptions.get(field.envKey) ?? [];
    this.additionalOptions.set(field.envKey, options.concat([new HarmonyInstallOption(data)]));
    this.customValues.set(field.envKey, '');
    if (field.multiple) this.multipleValues.set(field.envKey, (this.multipleValues.get(field.envKey) ?? []).concat([content]));
    else this.parameters.set(field.envKey, content);
  }

  private fieldDescription(field: HarmonyInstallField): string {
    const language = this.language.startsWith('zh') ? 'zh' : 'en';
    return field.descriptions?.get(language) ?? '';
  }

  private optionsFor(field: HarmonyInstallField): HarmonyInstallOption[] {
    if (field.fieldType === 'service') return this.serviceOptions.get(field.envKey) ?? [];
    return field.options.concat(this.additionalOptions.get(field.envKey) ?? []);
  }

  private selectOptions(options: HarmonyInstallOption[]): SelectOption[] {
    return options.map((option: HarmonyInstallOption): SelectOption => ({ value: option.label }));
  }

  private selectedIndex(envKey: string, options: HarmonyInstallOption[]): number {
    return options.findIndex((option: HarmonyInstallOption): boolean => option.optionValue === this.parameters.get(envKey));
  }

  private selectedLabel(envKey: string, options: HarmonyInstallOption[]): string {
    return options.find((option: HarmonyInstallOption): boolean => option.optionValue === this.parameters.get(envKey))?.label ?? '';
  }

  private async chooseField(field: HarmonyInstallField, index: number): Promise<void> {
    const selected = this.optionsFor(field)[index];
    this.parameters.set(field.envKey, selected.optionValue);
    if (field.fieldType === 'service') await this.changeService(field.envKey, index);
    if (field.fieldType === 'apps' && field.childKey.length > 0) {
      try {
        this.applyDependencyParams(field, selected.optionValue);
        await this.loadServices(field.childKey, selected.optionValue);
      } catch (error) {
        this.errorMessage = (error as Error).message;
      }
    }
  }

  private applyDependencyParams(field: HarmonyInstallField, appKey: string): void {
    for (const param of field.dependentParams) {
      if (param.get('key') === appKey) {
        this.parameters.set(param.get('envKey') as string, `${param.get('value')}`);
      }
    }
  }

  private changePair(pairId: number, key: string, content: string): void {
    const pair = this.environment.find((entry: HarmonyInstallPair): boolean => entry.pairId === pairId);
    if (pair === undefined) return;
    if (key === 'key') pair.pairKey = content;
    else pair.pairValue = content;
    this.environment = this.environment.slice();
  }

  private addPair(): void {
    const pair = new HarmonyInstallPair(this.nextPairId++);
    this.environment = this.environment.concat([pair]);
  }

  private removePair(pairId: number): void {
    this.environment = this.environment.filter((pair: HarmonyInstallPair): boolean => pair.pairId !== pairId);
  }

  private async install(): Promise<void> {
    if (this.detailId === null || this.saving) return;
    this.errorMessage = '';
    if (this.installName.trim().length === 0) {
      this.errorMessage = this.text('serverFormRequired');
      return;
    }
    const params = new Map<string, Object | null>();
    const requiredMessage: string = this.text('serverFormRequired');
    for (const field of this.fields) {
      const content = this.parameters.get(field.envKey) ?? '';
      const selectedValues = this.multipleValues.get(field.envKey) ?? [];
      if (field.required && (field.multiple ? selectedValues.length === 0 : content.trim().length === 0)) {
        this.errorMessage = `${this.fieldLabel(field)}: ${requiredMessage}`;
        return;
      }
      if (field.multiple) params.set(field.envKey, selectedValues);
      else params.set(field.envKey, field.fieldType === 'number' && content.length > 0 ? Number(content) : content);
      if (field.childKey.length > 0) {
        const childValue = this.parameters.get(field.childKey) ?? '';
        if (field.childRequired && childValue.length === 0) {
          this.errorMessage = `${this.fieldLabel(field)}: ${requiredMessage}`;
          return;
        }
        params.set(field.childKey, childValue);
      }
    }
    for (const pair of this.environment) {
      if (pair.pairKey.trim().length > 0) params.set(pair.pairKey.trim(), pair.pairValue);
    }
    if (this.fields.some((field: HarmonyInstallField): boolean => this.hasDatabaseFormat(field))) {
      params.set('format', this.selectedFormat);
      params.set('collation', this.selectedCollation);
    }
    const args = new Map<string, Object | null>();
    args.set('appDetailId', this.detailId);
    args.set('name', this.installName.trim());
    args.set('type', this.appType);
    args.set('params', params);
    args.set('advanced', this.advanced);
    args.set('hostMode', this.hostMode);
    args.set('pullImage', this.pullImage);
    if (this.advanced) {
      args.set('containerName', this.containerName);
      if (this.cpuQuota.length > 0) args.set('cpuQuota', Number(this.cpuQuota));
      if (this.memoryLimit.length > 0) args.set('memoryLimit', Number(this.memoryLimit));
      args.set('memoryUnit', this.memoryUnit === 'GB' ? 'G' : 'M');
      args.set('allowPort', this.allowPort);
      args.set('editCompose', this.editCompose);
      if (this.editCompose) {
        args.set('dockerCompose', this.dockerCompose);
      }
    }
    this.saving = true;
    try {
      const reply = await this.bridge.invoke<Map<string, Object | null>>('installHarmonyApp', args);
      if (reply.get('success') !== true) throw new Error(reply.get('error') as string);
      if (!this.active) return;
      this.getUIContext().getPromptAction().showToast({ message: this.text('appOperateSuccess') });
      this.paths.pop();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.saving = false;
    }
  }

  @Builder
  private textField(label: string, content: string, action: (content: string) => void, inputType: InputType) {
    Column({ space: 8 }) {
      Text(label).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextInput({ text: content, placeholder: label })
        .height(48).type(inputType).fontSize(16).accessibilityText(label)
        .enabled(!this.saving).onChange(action)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private dynamicField(field: HarmonyInstallField) {
    Column({ space: 8 }) {
      Text(this.fieldLabel(field)).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      if (field.multiple) {
        ForEach(this.optionsFor(field), (option: HarmonyInstallOption): void => {
          Row({ space: 12 }) {
            Checkbox({ name: option.optionValue, group: field.envKey })
              .select((this.multipleValues.get(field.envKey) ?? []).includes(option.optionValue))
              .enabled(!this.saving && !field.disabled)
              .onChange((selected: boolean): void => { this.changeMultiple(field, option, selected); })
            Text(option.label).fontSize(16).layoutWeight(1)
          }.width('100%').constraintSize({ minHeight: 48 })
        }, (option: HarmonyInstallOption): string => option.optionValue)
      } else if (field.fieldType === 'select' || field.fieldType === 'apps' || field.fieldType === 'service') {
        Select(this.selectOptions(this.optionsFor(field)))
          .value(this.selectedLabel(field.envKey, this.optionsFor(field)))
          .selected(this.selectedIndex(field.envKey, this.optionsFor(field)))
          .width('100%').height(48).enabled(!this.saving && !field.disabled)
          .accessibilityText(this.fieldLabel(field))
          .onSelect((index: number): void => { this.chooseField(field, index); })
      } else {
        TextInput({ text: this.parameters.get(field.envKey) ?? '' })
          .height(48).type(this.inputType(field)).enabled(!this.saving && !field.disabled)
          .accessibilityText(this.fieldLabel(field))
          .onChange((content: string): void => { this.parameters.set(field.envKey, content); })
      }
      if (field.allowCreate) {
        Row({ space: 8 }) {
          TextInput({ text: this.customValues.get(field.envKey) ?? '', placeholder: this.fieldLabel(field) })
            .height(48).layoutWeight(1).enabled(!this.saving && !field.disabled)
            .onChange((content: string): void => { this.customValues.set(field.envKey, content); })
          Button(this.text('serverAdd'), { buttonStyle: ButtonStyleMode.TEXTUAL })
            .height(48).enabled(!this.saving && !field.disabled)
            .onClick((): void => { this.addCustom(field); })
        }
      }
      if (field.childKey.length > 0) {
        Select(this.selectOptions(this.serviceOptions.get(field.childKey) ?? []))
          .value(this.selectedLabel(field.childKey, this.serviceOptions.get(field.childKey) ?? []))
          .selected(this.selectedIndex(field.childKey, this.serviceOptions.get(field.childKey) ?? []))
          .width('100%').height(48).enabled(!this.saving)
          .accessibilityText(this.text('appServiceList'))
          .onSelect((index: number): void => {
            this.changeService(field.childKey, index);
          })
      }
      if (this.hasDatabaseFormat(field)) {
        Text(this.text('databaseFormatLabel')).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
        Select(this.databaseFormats.map((entry: HarmonyInstallDatabaseFormat): SelectOption => ({ value: entry.format })))
          .value(this.selectedFormat).width('100%').height(48).enabled(!this.saving)
          .onSelect((index: number): void => {
            this.selectedFormat = this.databaseFormats[index].format;
            this.selectedCollation = '';
          })
        Text('Collation').fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
        Select(this.collationOptions().map((collation: string): SelectOption => ({ value: collation })))
          .value(this.selectedCollation).width('100%').height(48).enabled(!this.saving)
          .onSelect((index: number): void => { this.selectedCollation = this.collationOptions()[index]; })
      }
      if (this.fieldDescription(field).length > 0) {
        Text(this.fieldDescription(field)).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      }
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private environmentEditor() {
    Column({ space: 12 }) {
      Row() {
        Text(this.text('appInstallEnv')).fontSize(16).layoutWeight(1)
        Button(this.text('serverAdd'), { buttonStyle: ButtonStyleMode.TEXTUAL })
          .height(48).onClick((): void => { this.addPair(); })
      }
      ForEach(this.environment, (pair: HarmonyInstallPair): void => {
        Row({ space: 8 }) {
          TextInput({ text: pair.pairKey, placeholder: this.text('appInstallEnvKey') })
            .height(48).layoutWeight(1).type(InputType.Normal)
            .accessibilityText(this.text('appInstallEnvKey')).enabled(!this.saving)
            .onChange((content: string): void => {
              this.changePair(pair.pairId, 'key', content);
            })
          TextInput({ text: pair.pairValue, placeholder: this.text('appInstallEnvValue') })
            .height(48).layoutWeight(1)
            .accessibilityText(this.text('appInstallEnvValue')).enabled(!this.saving)
            .onChange((content: string): void => {
              this.changePair(pair.pairId, 'value', content);
            })
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.TEXTUAL }) {
            SymbolGlyph($r('sys.symbol.minus')).fontSize(20)
          }
          .width(48).height(48).accessibilityText(this.text('commonDelete')).enabled(!this.saving)
          .onClick((): void => { this.removePair(pair.pairId); })
        }
      }, (pair: HarmonyInstallPair): string => `${pair.pairId}`)
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          this.textField(this.text('appInfoName'), this.installName,
            (content: string): void => { this.installName = content; }, InputType.Normal)
          Column({ space: 8 }) {
            Text(this.text('appInfoVersion')).fontSize(14).width('100%').fontColor($r('sys.color.font_secondary'))
            Select(this.versions.map((version: string): SelectOption => ({ value: version })))
              .value(this.selectedVersion).selected(this.versions.indexOf(this.selectedVersion))
              .height(48).width('100%').enabled(!this.loading && !this.saving)
              .onSelect((index: number): void => { this.selectedVersion = this.versions[index]; this.loadForm(); })
          }
          if (this.loading) { LoadingProgress().width(48).height(48) }
          ForEach(this.fields, (field: HarmonyInstallField): void => { this.dynamicField(field) },
            (field: HarmonyInstallField): string => field.envKey)
          Row() {
            Text(this.text('panelSettingsAdvanced')).fontSize(16).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.advanced })
              .accessibilityText(this.text('panelSettingsAdvanced'))
              .onChange((enabled: boolean): void => { this.advanced = enabled; })
          }.constraintSize({ minHeight: 48 })
          if (this.advanced) {
            this.textField(this.text('appInstallContainerName'), this.containerName,
              (content: string): void => { this.containerName = content; }, InputType.Normal)
            this.textField(this.text('appInstallCpuLimit'), this.cpuQuota,
              (content: string): void => { this.cpuQuota = content; }, InputType.NUMBER_DECIMAL)
            this.textField(this.text('appInstallMemoryLimit'), this.memoryLimit,
              (content: string): void => { this.memoryLimit = content; }, InputType.NUMBER_DECIMAL)
            Select([{ value: 'MB' }, { value: 'GB' }])
              .value(this.memoryUnit).height(48).width('100%')
              .onSelect((index: number): void => { this.memoryUnit = ['MB', 'GB'][index]; })
            Row() {
              Text(this.text('appInstallAllowPort')).fontSize(16).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.allowPort })
                .accessibilityText(this.text('appInstallAllowPort'))
                .onChange((enabled: boolean): void => { this.allowPort = enabled; })
            }.constraintSize({ minHeight: 48 })
            Row() {
              Text(this.text('orchestrationPullImage')).fontSize(16).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.pullImage })
                .accessibilityText(this.text('orchestrationPullImage'))
                .onChange((enabled: boolean): void => { this.pullImage = enabled; })
            }.constraintSize({ minHeight: 48 })
            if (this.dockerCompose.length > 0 || this.editCompose) {
              Row() {
                Text(this.text('containerComposeFileTitle')).fontSize(16).layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.editCompose })
                  .accessibilityText(this.text('containerComposeFileTitle'))
                  .onChange((enabled: boolean): void => { this.editCompose = enabled; })
              }.constraintSize({ minHeight: 48 })
            }
            if (this.editCompose) {
              TextArea({ text: this.dockerCompose }).fontFamily('monospace').height(240)
                .accessibilityText(this.text('containerComposeFileTitle'))
                .onChange((content: string): void => { this.dockerCompose = content; })
            }
            this.environmentEditor()
          }
          if (this.errorMessage.length > 0) {
            Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary')).width('100%')
            if (this.detailId === null) {
              Button(this.text('commonRetry'), { buttonStyle: ButtonStyleMode.TEXTUAL })
                .height(48).onClick((): void => { this.loadForm(); })
            }
          }
          Button(this.text('appStoreInstall'))
            .width('100%').height(48).enabled(!this.loading && !this.saving && this.detailId !== null)
            .onClick((): void => { this.install(); })
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 32 }).width('100%')
        .alignItems(HorizontalAlign.Start)
      }.width('100%').height('100%')
    }
    .title(this.text('appStoreInstall'), { barStyle: BarStyle.STANDARD })
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .backgroundColor($r('sys.color.background_secondary'))
    .onReady((context: NavDestinationContext): void => { this.paths = context.pathStack; })
  }
}
