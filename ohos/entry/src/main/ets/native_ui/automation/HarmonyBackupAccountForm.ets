import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { automationText, automationString, automationWrite } from './HarmonyAutomationUI';

@Component
export struct HarmonyBackupAccountForm {
  account: Map<string, Object | null> = new Map<string, Object | null>();
  onSaved: () => void = (): void => {};
  @State private draft: Map<string, Object | null> = new Map<string, Object | null>();
  @State private vars: Map<string, Object | null> = new Map<string, Object | null>();
  @State private buckets: string[] = [];
  @State private loading: boolean = true;
  @State private busy: boolean = false;
  @State private failure: string = '';
  @State private verification: string = '';
  private types: string[] = ['SFTP', 'WebDAV', 'S3', 'MINIO', 'OSS', 'COS', 'KODO', 'UPYUN', 'OneDrive', 'GoogleDrive', 'ALIYUN'];
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      if (this.account.size > 0) args.set('account', this.account);
      this.draft = await this.bridge.invoke<Map<string, Object | null>>('getNativeBackupAccountDraft', args);
      this.vars = this.draft.get('vars') as Map<string, Object | null>;
      if (this.account.size === 0) this.draft.set('type', 'SFTP');
    } catch (error) { this.failure = (error as Error).message; }
    finally { this.loading = false; }
  }

  private type(): string { return automationString(this.draft, 'type'); }
  private objectStorage(): boolean { return ['S3', 'MINIO', 'OSS', 'COS', 'KODO', 'UPYUN'].includes(this.type()); }

  private arguments(): Map<string, Object | null> {
    this.draft.set('vars', this.vars);
    return this.draft;
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message.slice(0, 120) });
  }

  private async changeType(index: number): Promise<void> {
    this.draft.set('type', this.types[index]);
    this.verification = '';
    try {
      this.draft = await this.bridge.invoke<Map<string, Object | null>>('prepareNativeBackupAccount', this.arguments());
      this.vars = this.draft.get('vars') as Map<string, Object | null>;
    } catch (error) { this.toast((error as Error).message); }
  }

  private async save(): Promise<void> {
    this.busy = true;
    try { await automationWrite('saveNativeBackupAccount', this.arguments()); this.onSaved(); }
    catch (error) { this.toast((error as Error).message); }
    finally { this.busy = false; }
  }

  private async verify(): Promise<void> {
    this.busy = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>('testNativeBackupAccount', this.arguments());
      this.verification = result.get('isOk') === true ? automationText('backupAccountsConnectionOk') : automationString(result, 'msg');
    } catch (error) { this.verification = (error as Error).message; }
    finally { this.busy = false; }
  }

  private async loadBuckets(): Promise<void> {
    this.busy = true;
    try {
      const values = await this.bridge.invoke<Object[]>('loadNativeBackupBuckets', this.arguments());
      this.buckets = values.map((item: Object): string => `${item}`);
    } catch (error) { this.toast((error as Error).message); }
    finally { this.busy = false; }
  }

  private async authorize(): Promise<void> {
    try { await automationWrite('authorizeNativeBackupAccount', this.arguments()); }
    catch (error) { this.toast((error as Error).message); }
  }

  private async applyToken(token: string): Promise<void> {
    try {
      const args = this.arguments(); args.set('token', token);
      this.draft = await this.bridge.invoke<Map<string, Object | null>>('applyNativeBackupAliyunToken', args);
      this.vars = this.draft.get('vars') as Map<string, Object | null>;
    } catch (error) { this.toast((error as Error).message); }
  }

  @Builder
  private field(key: string, labelKey: string, secret: boolean = false) {
    Column({ space: 8 }) {
      Text(automationText(labelKey)).fontSize(16).width('100%')
      TextInput({ text: automationString(this.draft, key) }).height(48)
        .type(secret ? InputType.Password : InputType.Normal)
        .onChange((content: string): void => { this.draft.set(key, content); this.verification = ''; })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private variableField(key: string, labelKey: string, numeric: boolean = false, secret: boolean = false) {
    Column({ space: 8 }) {
      Text(automationText(labelKey)).fontSize(16).width('100%')
      TextInput({ text: automationString(this.vars, key) }).height(48)
        .type(secret ? InputType.Password : numeric ? InputType.Number : InputType.Normal)
        .onChange((content: string): void => { this.vars.set(key, numeric ? Number(content) : content); this.verification = ''; })
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private toggle(key: string, labelKey: string) {
    Row({ space: 12 }) {
      Text(automationText(labelKey)).fontSize(16).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.draft.get(key) === true })
        .onChange((selected: boolean): void => { this.draft.set(key, selected); })
    }.constraintSize({ minHeight: 48 }).width('100%')
  }

  @Builder
  private credentials() {
    if (this.objectStorage() || this.type() === 'SFTP' || this.type() === 'WebDAV') {
      this.field('accessKey', 'backupFormUsernameAccessKeyLabel')
      this.field('credential', 'backupFormCredentialLabel', true)
      this.toggle('rememberAuth', 'backupFormRememberCredentialsLabel')
    }
    if (this.type() === 'SFTP' || this.type() === 'WebDAV') {
      this.variableField('address', 'backupFormAddressLabel')
      if (this.type() === 'SFTP') { this.variableField('port', 'backupFormPortLabel', true) }
    }
    if (this.objectStorage()) {
      if (this.type() === 'COS' || this.type() === 'S3') { this.variableField('region', 'backupFormRegionLabel') }
      if (this.type() === 'KODO') { this.variableField('domain', 'backupFormDomainLabel') }
      else { this.variableField('endpoint', 'backupFormEndpointLabel') }
      this.field('bucket', 'backupFormBucketLabel')
      Button(automationText('commonRefresh')).height(48).enabled(!this.busy).onClick((): void => { this.loadBuckets(); })
      if (this.buckets.length > 0) {
        Select(this.buckets.map((bucket: string): SelectOption => ({ value: bucket }))).height(48).width('100%')
          .onSelect((index: number): void => { this.draft.set('bucket', this.buckets[index]); })
      }
    }
    if (this.type() === 'OneDrive' || this.type() === 'GoogleDrive') {
      if (this.type() === 'OneDrive') {
        Row({ space: 12 }) {
          Text(automationText('backupFormChinaCloudLabel')).fontSize(16).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.vars.get('isCN') === true })
            .onChange((selected: boolean): void => { this.vars.set('isCN', selected); })
        }.constraintSize({ minHeight: 48 })
      }
      this.variableField('client_id', 'backupFormClientIdLabel')
      this.variableField('client_secret', 'backupFormClientSecretLabel', false, true)
      this.variableField('redirect_uri', 'backupFormRedirectUriLabel')
      this.variableField('code', 'backupFormAuthCodeLabel')
      Button(automationText('backupFormOpenAuthorizeAction')).height(48).onClick((): void => { this.authorize(); })
    }
    if (this.type() === 'ALIYUN') {
      Text(automationText('backupFormTokenJsonLabel')).fontSize(16).width('100%')
      TextArea({ text: automationString(this.vars, 'token') }).height(120)
        .onChange((content: string): void => { this.vars.set('token', content); })
      Button(automationText('commonLoad')).height(48).onClick((): void => { this.applyToken(automationString(this.vars, 'token')); })
      this.variableField('drive_id', 'backupFormDriveIdLabel')
      this.variableField('refresh_token', 'backupFormRefreshTokenLabel', false, true)
    }
    this.field('backupPath', 'backupFormBackupPathLabel')
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) { LoadingProgress().width(48).height(48) }
        else if (this.failure.length > 0) {
          Text(this.failure).fontSize(14)
          Button(automationText('commonRetry')).height(48).onClick((): void => { this.load(); })
        } else {
          this.field('name', 'commonName')
          this.toggle('isPublic', 'backupFormPublicScopeLabel')
          Text(automationText('backupFormProviderTypeLabel')).fontSize(16).width('100%')
          Select(this.types.map((type: string): SelectOption => ({ value: type })))
            .height(48).width('100%').selected(this.types.indexOf(this.type()))
            .enabled(this.type() !== 'LOCAL')
            .onSelect((index: number): void => { this.changeType(index); })
          this.credentials()
          if (this.verification.length > 0) { Text(this.verification).fontSize(14).width('100%') }
          Button(automationText('backupFormTestConnectionAction')).height(48).width('100%').enabled(!this.busy)
            .buttonStyle(ButtonStyleMode.NORMAL).onClick((): void => { this.verify(); })
          Button(automationText('commonSave')).height(48).width('100%').enabled(!this.busy)
            .onClick((): void => { this.save(); })
        }
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }
}
