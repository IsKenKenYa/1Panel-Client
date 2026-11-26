import { common } from '@kit.AbilityKit';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

class HarmonyConfigOption {
  optionLabel: string;
  optionValue: string;
  constructor(label: string, optionValue: string) {
    this.optionLabel = label;
    this.optionValue = optionValue;
  }
}

class HarmonyConfigField {
  fieldKey: string;
  labelZh: string;
  labelEn: string;
  fieldType: string;
  editable: boolean;
  required: boolean;
  initialValue: string;
  initialValues: string[];
  multiple: boolean;
  rule: string;
  options: HarmonyConfigOption[] = [];
  constructor(data: Map<string, Object | null>) {
    this.fieldKey = data.get('key') as string;
    this.labelZh = data.get('labelZh') as string;
    this.labelEn = data.get('labelEn') as string;
    this.fieldType = data.get('type') as string;
    this.editable = data.get('edit') as boolean;
    this.required = data.get('required') as boolean;
    this.initialValue = data.get('value') as string;
    const rawValue = data.get('valueRaw');
    this.initialValues = Array.isArray(rawValue) ? rawValue as string[] : [];
    this.multiple = data.get('multiple') === true;
    this.rule = data.get('rule') as string | null ?? '';
    const values = data.get('values') as Array<Object> | null;
    if (values !== null && values !== undefined) {
      this.options = values.map((option: Object): HarmonyConfigOption => {
        if (typeof option === 'string') return new HarmonyConfigOption(option, option);
        const record = option as Map<string, Object | null>;
        return new HarmonyConfigOption(record.get('label') as string, `${record.get('value')}`);
      });
    }
  }
}

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyAppConfigPage {
  @Require @Prop installId: number;
  @State private containerName: string = '';
  @State private cpuQuota: string = '';
  @State private memoryLimit: string = '';
  @State private memoryUnit: string = '';
  @State private webUI: string = '';
  @State private httpPort: string = '';
  @State private httpsPort: string = '';
  @State private allowPort: boolean = false;
  @State private fields: HarmonyConfigField[] = [];
  @State private parameters: Map<string, string> = new Map<string, string>();
  @State private multipleValues: Map<string, string[]> = new Map<string, string[]>();
  @State private loading: boolean = true;
  @State private loaded: boolean = false;
  @State private saving: boolean = false;
  @State private errorMessage: string = '';
  @State private language: string = 'en';
  private originalHttpPort: string = '';
  private originalHttpsPort: string = '';
  private originalWebUI: string = '';
  private active: boolean = false;
  private config: Map<string, Object | null> = new Map<string, Object | null>();
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.active = true;
    this.load();
  }

  aboutToDisappear(): void {
    this.active = false;
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private fieldLabel(field: HarmonyConfigField): string {
    const label = this.language.startsWith('zh') ? field.labelZh : field.labelEn;
    return field.required ? `${label} *` : label;
  }

  private inputType(field: HarmonyConfigField): InputType {
    if (field.fieldType === 'password') return InputType.Password;
    if (field.fieldType === 'number') return InputType.NUMBER_DECIMAL;
    return InputType.Normal;
  }

  private args(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('installId', this.installId);
    return args;
  }

  private optionalNumber(value: Object | null | undefined): string {
    return value === null || value === undefined ? '' : `${value}`;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const settings = await this.bridge.invoke<Map<string, Object | null>>('getSettings');
      const language = settings.get('language') as string;
      if (language === 'system') {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        this.language = context.resourceManager.getConfigurationSync().locale;
      } else {
        this.language = language;
      }
      const config = await this.bridge.invoke<Map<string, Object | null>>('getAppInstallParams', this.args());
      const info = await this.bridge.invoke<Map<string, Object | null>>('getAppInstallInfo', this.args());
      this.config = config;
      this.containerName = config.get('containerName') as string;
      this.cpuQuota = `${config.get('cpuQuota')}`;
      this.memoryLimit = `${config.get('memoryLimit')}`;
      this.memoryUnit = config.get('memoryUnit') as string;
      this.webUI = config.get('webUI') as string;
      this.originalWebUI = this.webUI;
      this.allowPort = config.get('allowPort') as boolean;
      this.httpPort = this.optionalNumber(info.get('httpPort'));
      const fields = config.get('params') as Array<Map<string, Object | null>>;
      const https = fields.find((field: Map<string, Object | null>): boolean =>
        field.get('key') === 'PANEL_APP_PORT_HTTPS');
      this.httpsPort = this.optionalNumber(https?.get('valueRaw') ?? info.get('httpsPort'));
      this.originalHttpPort = this.httpPort;
      this.originalHttpsPort = this.httpsPort;
      this.fields = fields
        .filter((field: Map<string, Object | null>): boolean =>
          !this.allowPort || (field.get('key') !== 'PANEL_APP_PORT_HTTP' && field.get('key') !== 'PANEL_APP_PORT_HTTPS'))
        .map((field: Map<string, Object | null>): HarmonyConfigField => new HarmonyConfigField(field));
      const params = new Map<string, string>();
      this.multipleValues = new Map<string, string[]>();
      for (const field of this.fields) {
        params.set(field.fieldKey, field.initialValue);
        this.multipleValues.set(field.fieldKey, field.initialValues.slice());
      }
      this.parameters = params;
      this.loaded = true;
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async mutate(method: string, args: Map<string, Object | null>): Promise<void> {
    const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
    if (result.get('success') !== true) throw new Error(result.get('error') as string);
  }

  private async save(): Promise<void> {
    if (this.saving) return;
    this.errorMessage = '';
    const params = new Map<string, Object | null>();
    const requiredMessage: string = this.text('serverFormRequired');
    for (const field of this.fields) {
      if (!field.editable) continue;
      const content = this.parameters.get(field.fieldKey) ?? '';
      const selectedValues = this.multipleValues.get(field.fieldKey) ?? [];
      if (field.required && (field.multiple ? selectedValues.length === 0 : content.trim().length === 0)) {
        this.errorMessage = `${this.fieldLabel(field)}: ${requiredMessage}`;
        return;
      }
      if (field.multiple) params.set(field.fieldKey, selectedValues);
      else params.set(field.fieldKey, field.fieldType === 'number' && content.length > 0 ? Number(content) : content);
    }
    if (this.allowPort) {
      if (this.httpPort.length > 0 && this.httpPort !== this.originalHttpPort) {
        params.set('PANEL_APP_PORT_HTTP', Number(this.httpPort));
      }
      if (this.httpsPort.length > 0 && this.httpsPort !== this.originalHttpsPort) {
        params.set('PANEL_APP_PORT_HTTPS', Number(this.httpsPort));
      }
    }
    const args = this.args();
    args.set('params', params);
    args.set('advanced', true);
    args.set('containerName', this.containerName);
    if (this.cpuQuota.length > 0) args.set('cpuQuota', Number(this.cpuQuota));
    if (this.memoryLimit.length > 0) args.set('memoryLimit', Number(this.memoryLimit));
    args.set('memoryUnit', this.memoryUnit === 'GB' ? 'G' : this.memoryUnit === 'MB' ? 'M' : this.memoryUnit);
    args.set('allowPort', this.allowPort);
    args.set('dockerCompose', this.config.get('dockerCompose') as string);
    args.set('hostMode', this.config.get('hostMode') as boolean);
    args.set('type', this.config.get('type') as string);
    args.set('webUI', this.webUI);
    args.set('specifyIP', this.config.get('specifyIP') as string);
    args.set('restartPolicy', this.config.get('restartPolicy') as string);
    this.saving = true;
    try {
      await this.mutate('updateAppParams', args);
      if (this.webUI !== this.originalWebUI) {
        const webArgs = this.args();
        webArgs.set('webUI', this.webUI);
        await this.mutate('updateAppInstallConfig', webArgs);
      }
      if (!this.active) return;
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
      this.paths.pop();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.saving = false;
    }
  }

  private options(field: HarmonyConfigField): SelectOption[] {
    return field.options.map((option: HarmonyConfigOption): SelectOption => ({ value: option.optionLabel }));
  }

  private selectedIndex(field: HarmonyConfigField): number {
    return field.options.findIndex((option: HarmonyConfigOption): boolean =>
      option.optionValue === this.parameters.get(field.fieldKey));
  }

  private selectedLabel(field: HarmonyConfigField): string {
    return field.options.find((option: HarmonyConfigOption): boolean =>
      option.optionValue === this.parameters.get(field.fieldKey))?.optionLabel ?? '';
  }

  private changeMultiple(field: HarmonyConfigField, option: HarmonyConfigOption, selected: boolean): void {
    const values = this.multipleValues.get(field.fieldKey) ?? [];
    this.multipleValues.set(field.fieldKey, selected ? values.concat([option.optionValue])
      : values.filter((entry: string): boolean => entry !== option.optionValue));
  }

  @Builder
  private textField(label: string, content: string, inputType: InputType, action: (content: string) => void) {
    Column({ space: 8 }) {
      Text(label).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextInput({ text: content, placeholder: label }).height(48).type(inputType)
        .enabled(!this.saving).accessibilityText(label).onChange(action)
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private parameterField(field: HarmonyConfigField) {
    Column({ space: 8 }) {
      Text(this.fieldLabel(field)).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      if (field.editable && field.multiple) {
        ForEach(field.options, (option: HarmonyConfigOption): void => {
          Row({ space: 12 }) {
            Checkbox({ name: option.optionValue, group: field.fieldKey })
              .select((this.multipleValues.get(field.fieldKey) ?? []).includes(option.optionValue))
              .enabled(!this.saving)
              .onChange((selected: boolean): void => { this.changeMultiple(field, option, selected); })
            Text(option.optionLabel).fontSize(16).layoutWeight(1)
          }.width('100%').constraintSize({ minHeight: 48 })
        }, (option: HarmonyConfigOption): string => option.optionValue)
      } else if (field.editable && field.fieldType === 'select' && field.options.length > 0) {
        Select(this.options(field)).height(48).width('100%').value(this.selectedLabel(field))
          .selected(this.selectedIndex(field)).enabled(!this.saving)
          .accessibilityText(this.fieldLabel(field))
          .onSelect((index: number): void => {
            this.parameters.set(field.fieldKey, field.options[index].optionValue);
          })
      } else if (field.editable) {
        TextInput({ text: this.parameters.get(field.fieldKey) ?? '' }).height(48)
          .type(this.inputType(field)).enabled(!this.saving).accessibilityText(this.fieldLabel(field))
          .onChange((content: string): void => { this.parameters.set(field.fieldKey, content); })
      } else if (field.fieldType === 'password') {
        TextInput({ text: field.initialValue }).type(InputType.Password).height(48).enabled(false)
          .accessibilityText(this.fieldLabel(field))
      } else {
        Text(field.initialValue).fontSize(16).width('100%').constraintSize({ minHeight: 48 })
          .fontColor($r('sys.color.font_primary')).copyOption(CopyOptions.LocalDevice)
      }
      if (field.rule.length > 0) {
        Text(field.rule).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      }
    }
    .width('100%').alignItems(HorizontalAlign.Start)
  }

  build() {
    NavDestination() {
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else if (!this.loaded) {
        Column({ space: 16 }) {
          Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary'))
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }.padding(24).width('100%')
      } else {
        Scroll() {
          Column({ space: 16 }) {
            if (this.allowPort) {
              Row({ space: 12 }) {
                Column() {
                  this.textField(this.text('commonHttp'), this.httpPort, InputType.Number,
                    (content: string): void => { this.httpPort = content; })
                }.layoutWeight(1)
                Column() {
                  this.textField(this.text('commonHttps'), this.httpsPort, InputType.Number,
                    (content: string): void => { this.httpsPort = content; })
                }.layoutWeight(1)
              }
            }
            this.textField(this.text('appInstallContainerName'), this.containerName, InputType.Normal,
              (content: string): void => { this.containerName = content; })
            this.textField(this.text('appInstallCpuLimit'), this.cpuQuota, InputType.NUMBER_DECIMAL,
              (content: string): void => { this.cpuQuota = content; })
            this.textField(this.text('appInstallMemoryLimit'), this.memoryLimit, InputType.NUMBER_DECIMAL,
              (content: string): void => { this.memoryLimit = content; })
            Select([{ value: 'MB' }, { value: 'GB' }]).value(this.memoryUnit === 'G' ? 'GB' : 'MB')
              .width('100%').height(48).enabled(!this.saving)
              .onSelect((index: number): void => { this.memoryUnit = ['M', 'G'][index]; })
            this.textField('WebUI', this.webUI, InputType.URL,
              (content: string): void => { this.webUI = content; })
            ForEach(this.fields, (field: HarmonyConfigField): void => { this.parameterField(field) },
              (field: HarmonyConfigField): string => field.fieldKey)
            if (this.errorMessage.length > 0) {
              Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary')).width('100%')
            }
            Button(this.text('commonSave')).width('100%').height(48).enabled(!this.saving)
              .onClick((): void => { this.save(); })
          }
          .padding({ left: 16, right: 16, top: 16, bottom: 32 }).width('100%')
          .alignItems(HorizontalAlign.Start)
        }.width('100%').height('100%')
      }
    }
    .title(this.text('appTabConfig'), { barStyle: BarStyle.STANDARD })
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .backgroundColor($r('sys.color.background_secondary'))
    .onReady((context: NavDestinationContext): void => { this.paths = context.pathStack; })
  }
}
