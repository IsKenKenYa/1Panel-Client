import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyDatabaseItem, harmonyDatabaseText } from './HarmonyDatabaseModels';

@Component
export struct HarmonyDatabaseForm {
  @Prop initialScope: string = 'mysql';
  @Prop editing: Map<string, Object | null> = new Map<string, Object | null>();
  onSaved: () => void = (): void => {};
  @State private selectedScope: string = 'mysql';
  @State private targets: HarmonyDatabaseItem[] = [];
  @State private selectedTarget: number = -1;
  @State private formName: string = '';
  @State private formEngine: string = 'mysql';
  @State private formVersion: string = '';
  @State private formAddress: string = '';
  @State private formPort: string = '';
  @State private formUsername: string = '';
  @State private formPassword: string = '';
  @State private formDescription: string = '';
  @State private formFormat: string = 'utf8mb4';
  @State private formPermission: string = '%';
  @State private formPermissionIps: string = '';
  @State private mongodbPermission: string = 'dbOwner';
  @State private formTimeout: string = '30';
  @State private formSuperUser: boolean = true;
  @State private sslEnabled: boolean = false;
  @State private skipVerify: boolean = false;
  @State private clientKey: string = '';
  @State private clientCert: string = '';
  @State private rootCert: string = '';
  @State private initialDatabase: string = '';
  @State private connectionVerified: boolean = false;
  @State private loadedRemote: boolean = false;
  @State private isLoading: boolean = false;
  @State private isSaving: boolean = false;
  @State private feedback: string = '';
  private scopeIds: string[] = ['mysql', 'postgresql', 'mongodb', 'remote'];
  private mongodbPermissions: string[] = ['dbOwner', 'read', 'readWrite', 'userAdmin'];

  aboutToAppear(): void {
    this.selectedScope = this.initialScope === 'redis' ? 'mysql' : this.initialScope;
    if (this.editing.size > 0) {
      this.selectedScope = 'remote';
      this.formName = this.editing.get('name') as string;
      this.formEngine = this.optionalText('engine');
      this.formAddress = this.optionalText('address');
      this.formPort = this.optionalText('port');
      this.formUsername = this.optionalText('username');
      this.formDescription = this.optionalText('description');
      this.loadRemoteConfig();
    } else if (this.selectedScope === 'remote') {
      this.selectRemoteEngine('mysql');
    } else {
      this.loadTargets();
    }
  }

  private optionalText(field: string): string {
    const content = this.editing.get(field);
    return content === null || content === undefined ? '' : `${content}`;
  }

  private async loadRemoteConfig(): Promise<void> {
    this.isLoading = true;
    this.feedback = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('name', this.formName);
      const config = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getHarmonyRemoteDatabaseConfig', args);
      this.editing.set('id', config.get('id') as number);
      this.formEngine = config.get('type') as string;
      this.formVersion = `${config.get('version') ?? ''}`;
      this.formAddress = `${config.get('address') ?? ''}`;
      this.formPort = `${config.get('port') ?? ''}`;
      this.formUsername = `${config.get('username') ?? ''}`;
      this.formPassword = `${config.get('password') ?? ''}`;
      this.formTimeout = `${config.get('timeout') ?? '30'}`;
      this.sslEnabled = config.get('ssl') === true;
      this.skipVerify = config.get('skipVerify') === true;
      this.clientKey = `${config.get('clientKey') ?? ''}`;
      this.clientCert = `${config.get('clientCert') ?? ''}`;
      this.rootCert = `${config.get('rootCert') ?? ''}`;
      this.initialDatabase = `${config.get('initialDB') ?? ''}`;
      this.loadedRemote = true;
    } catch (error) {
      this.feedback = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private scopeOptions(): SelectOption[] {
    return this.scopeIds.map((scope: string): SelectOption => ({ value: scope }));
  }

  private targetOptions(): SelectOption[] {
    return this.targets.map((item: HarmonyDatabaseItem): SelectOption => ({ value: item.lookupName }));
  }

  private versions(): string[] {
    if (this.formEngine === 'mysql') return ['8.x', '5.7', '5.6'];
    if (this.formEngine === 'mariadb') return ['10.x', '11.x'];
    if (this.formEngine === 'postgresql') return ['18.x', '17.x', '16.x', '15.x', '14.x'];
    if (this.formEngine === 'mongodb') return ['8.x', '7.x', '6.x'];
    return ['8.x', '7.x', '6.x'];
  }

  private selectRemoteEngine(engine: string): void {
    this.formEngine = engine;
    this.formVersion = this.versions()[0];
    this.initialDatabase = engine === 'mongodb' ? 'admin' : '';
    this.formUsername = engine === 'redis' ? '-' : engine === 'postgresql' ? '' : 'root';
    this.formPort = engine === 'postgresql' ? '5432' : engine === 'mongodb' ? '27017' : engine === 'redis' ? '6379' : '3306';
    this.connectionVerified = false;
  }

  private validate(): boolean {
    const isRemote = this.selectedScope === 'remote';
    if (this.formName.trim().length === 0) {
      this.feedback = `${harmonyDatabaseText('commonName')}: ${harmonyDatabaseText('serverFormRequired')}`;
      return false;
    }
    if (!isRemote && this.selectedTarget < 0) {
      this.feedback = harmonyDatabaseText('databaseTargetInstanceRequired');
      return false;
    }
    if (isRemote) {
      const port = Number(this.formPort);
      const timeout = Number(this.formTimeout);
      if (this.formVersion.length === 0 || this.formUsername.trim().length === 0 || this.formAddress.trim().length === 0) {
        this.feedback = harmonyDatabaseText('serverFormRequired');
        return false;
      }
      if (!Number.isInteger(port) || port < 1 || port > 65535) {
        this.feedback = `${harmonyDatabaseText('databasePortLabel')}: ${harmonyDatabaseText('serverFormRequired')}`;
        return false;
      }
      if (!Number.isInteger(timeout) || timeout < 1 || timeout > 600) {
        this.feedback = `${harmonyDatabaseText('databaseRemoteTimeoutLabel')}: ${harmonyDatabaseText('serverFormRequired')}`;
        return false;
      }
    } else if ((this.selectedScope === 'postgresql' || this.selectedScope === 'mongodb') &&
      (this.formUsername.trim().length === 0 || this.formPassword.length === 0)) {
      this.feedback = `${harmonyDatabaseText('databaseUsernameLabel')}: ${harmonyDatabaseText('serverFormRequired')}`;
      return false;
    }
    return true;
  }

  private async loadTargets(): Promise<void> {
    this.isLoading = true;
    this.feedback = '';
    this.targets = [];
    this.selectedTarget = -1;
    this.formFormat = this.selectedScope === 'postgresql' ? 'UTF8' : 'utf8mb4';
    try {
      if (this.selectedScope !== 'remote') {
        const args = new Map<string, Object | null>();
        args.set('scope', this.selectedScope);
        const records = await HarmonyNativeBridge.instance
          .invoke<Array<Map<string, Object | null>>>('getHarmonyDatabaseTargets', args);
        this.targets = records.map((record: Map<string, Object | null>): HarmonyDatabaseItem =>
          new HarmonyDatabaseItem(record));
        if (this.targets.length > 0) {
          this.selectedTarget = 0;
        }
      }
    } catch (error) {
      this.feedback = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private input(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('scope', this.selectedScope);
    args.set('name', this.formName.trim());
    args.set('username', this.formUsername.trim());
    args.set('password', this.formPassword);
    args.set('description', this.formDescription);
    if (this.selectedScope === 'remote') {
      args.set('id', this.editing.get('id') ?? null);
      args.set('engine', this.formEngine);
      args.set('source', 'remote');
      args.set('address', this.formAddress.trim());
      args.set('port', Number(this.formPort));
      args.set('timeout', Number(this.formTimeout));
      const remote = new Map<string, Object | null>();
      remote.set('id', this.editing.get('id') ?? null);
      remote.set('name', this.formName.trim());
      remote.set('type', this.formEngine);
      remote.set('version', this.formVersion);
      remote.set('from', 'remote');
      remote.set('address', this.formAddress.trim());
      remote.set('port', Number(this.formPort));
      remote.set('username', this.formUsername.trim());
      remote.set('password', this.formPassword);
      remote.set('timeout', Number(this.formTimeout));
      remote.set('description', this.formDescription);
      remote.set('ssl', this.sslEnabled);
      remote.set('skipVerify', this.skipVerify);
      remote.set('clientKey', this.clientKey);
      remote.set('clientCert', this.clientCert);
      remote.set('rootCert', this.rootCert);
      remote.set('initialDB', this.initialDatabase);
      args.set('remoteConfig', remote);
    } else {
      const target = this.targets[this.selectedTarget];
      args.set('engine', target.engine);
      args.set('source', target.source);
      args.set('targetDatabase', target.lookupName);
      args.set('format', this.formFormat);
      args.set('permission', this.selectedScope === 'mongodb' ? this.mongodbPermission : this.formPermission);
      args.set('permissionIps', this.formPermissionIps);
      args.set('superUser', this.formSuperUser);
    }
    return args;
  }

  private async submit(testConnection: boolean = false): Promise<void> {
    if (!this.validate()) return;
    this.isSaving = true;
    this.feedback = '';
    try {
      if (testConnection) {
        const connected = await HarmonyNativeBridge.instance.invoke<boolean>(
          'testHarmonyDatabaseConnection', this.input());
        this.connectionVerified = connected;
        this.feedback = harmonyDatabaseText(connected ? 'backupAccountsConnectionOk' : 'backupAccountsConnectionFailed');
      } else {
        await HarmonyNativeBridge.instance.invoke<Object | null>('submitHarmonyDatabaseForm', this.input());
        this.getUIContext().getPromptAction().showToast({ message: harmonyDatabaseText('commonSaveSuccess') });
        this.onSaved();
      }
    } catch (error) {
      this.feedback = (error as Error).message;
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.editing.size === 0) {
          Row({ space: 12 }) {
            Text(harmonyDatabaseText('databaseScopeLabel')).layoutWeight(1).fontSize(16)
            Select(this.scopeOptions())
              .selected(this.scopeIds.indexOf(this.selectedScope))
              .value(this.selectedScope)
              .height(48)
              .onSelect((index: number): void => {
                this.selectedScope = this.scopeIds[index];
                if (this.selectedScope === 'remote') this.selectRemoteEngine('mysql');
                else this.loadTargets();
              })
          }
          .width('100%')
        }
        Text(harmonyDatabaseText('commonName')).width('100%').fontSize(14)
        TextInput({ text: this.formName })
          .id('harmony.database.form.name')
          .height(48)
          .enabled(this.editing.size === 0)
          .onChange((content: string): void => { this.formName = content; })
        if (this.selectedScope === 'remote') {
          Text(harmonyDatabaseText('databaseEngineLabel')).width('100%').fontSize(14)
          Select([{ value: 'mysql' }, { value: 'mariadb' }, { value: 'postgresql' }, { value: 'mongodb' }, { value: 'redis' }])
            .height(48).value(this.formEngine)
            .onSelect((index: number): void => {
              this.selectRemoteEngine(['mysql', 'mariadb', 'postgresql', 'mongodb', 'redis'][index]);
            })
          Text(harmonyDatabaseText('databaseVersionLabel')).width('100%').fontSize(14)
          Select(this.versions().map((version: string): SelectOption => ({ value: version })))
            .height(48).value(this.formVersion)
            .onSelect((index: number): void => { this.formVersion = this.versions()[index]; this.connectionVerified = false; })
          Text(harmonyDatabaseText('databaseAddressLabel')).width('100%').fontSize(14)
          TextInput({ text: this.formAddress })
            .height(48)
            .onChange((content: string): void => { this.formAddress = content; this.connectionVerified = false; })
          Text(harmonyDatabaseText('databasePortLabel')).width('100%').fontSize(14)
          TextInput({ text: this.formPort }).height(48).type(InputType.Number)
            .onChange((content: string): void => { this.formPort = content; this.connectionVerified = false; })
          Text(harmonyDatabaseText('databaseRemoteTimeoutLabel')).width('100%').fontSize(14)
          TextInput({ text: this.formTimeout }).height(48).type(InputType.Number)
            .onChange((content: string): void => { this.formTimeout = content; this.connectionVerified = false; })
          if (this.formEngine === 'postgresql' || this.formEngine === 'mongodb') {
            Text('initialDB').width('100%').fontSize(14)
            TextInput({ text: this.initialDatabase }).height(48)
              .onChange((content: string): void => { this.initialDatabase = content; this.connectionVerified = false; })
          }
          if (this.formEngine === 'mysql' || this.formEngine === 'mariadb' || this.formEngine === 'mongodb') {
            Row({ space: 12 }) {
              Text('SSL').layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.sslEnabled })
                .onChange((checked: boolean): void => { this.sslEnabled = checked; this.connectionVerified = false; })
            }.constraintSize({ minHeight: 48 })
            if (this.sslEnabled) {
              Row({ space: 12 }) {
                Text(harmonyDatabaseText('serverFormAllowInsecureTls')).layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.skipVerify })
                  .onChange((checked: boolean): void => { this.skipVerify = checked; this.connectionVerified = false; })
              }.constraintSize({ minHeight: 48 })
              Text('clientKey').width('100%').fontSize(14)
              TextArea({ text: this.clientKey }).constraintSize({ minHeight: 96 })
                .onChange((content: string): void => { this.clientKey = content; this.connectionVerified = false; })
              Text('clientCert').width('100%').fontSize(14)
              TextArea({ text: this.clientCert }).constraintSize({ minHeight: 96 })
                .onChange((content: string): void => { this.clientCert = content; this.connectionVerified = false; })
              Text('rootCert').width('100%').fontSize(14)
              TextArea({ text: this.rootCert }).constraintSize({ minHeight: 96 })
                .onChange((content: string): void => { this.rootCert = content; this.connectionVerified = false; })
            }
          }
        } else {
          Text(harmonyDatabaseText('databaseTargetInstance')).width('100%').fontSize(14)
          if (this.isLoading) {
            LoadingProgress().width(32).height(32)
          } else {
            Select(this.targetOptions())
              .selected(this.selectedTarget)
              .height(48)
              .width('100%')
              .onSelect((index: number): void => { this.selectedTarget = index; })
          }
          if (this.selectedScope !== 'mongodb') {
            Text(harmonyDatabaseText('databaseFormatLabel')).width('100%').fontSize(14)
            TextInput({ text: this.formFormat }).height(48)
              .onChange((content: string): void => { this.formFormat = content; })
          }
        }
        Text(harmonyDatabaseText('databaseUsernameLabel')).width('100%').fontSize(14)
        TextInput({ text: this.formUsername }).height(48)
          .onChange((content: string): void => { this.formUsername = content; this.connectionVerified = false; })
        Text(harmonyDatabaseText('databasePasswordLabel')).width('100%').fontSize(14)
        TextInput({ text: this.formPassword }).height(48).type(InputType.Password)
          .onChange((content: string): void => { this.formPassword = content; this.connectionVerified = false; })
        if (this.selectedScope === 'mysql') {
          Text(harmonyDatabaseText('databasePermission')).width('100%').fontSize(14)
          Select([{ value: '%' }, { value: 'localhost' }, { value: 'IP' }])
            .height(48)
            .value(this.formPermission)
            .onSelect((index: number): void => { this.formPermission = ['%', 'localhost', 'ip'][index]; })
          if (this.formPermission === 'ip') {
            TextInput({ text: this.formPermissionIps, placeholder: harmonyDatabaseText('databasePermissionIpsHint') })
              .height(48)
              .onChange((content: string): void => { this.formPermissionIps = content; })
          }
        }
        if (this.selectedScope === 'mongodb') {
          Text(harmonyDatabaseText('databasePermission')).width('100%').fontSize(14)
          Select(this.mongodbPermissions.map((role: string): SelectOption => ({ value: role })))
            .height(48).value(this.mongodbPermission)
            .onSelect((index: number): void => { this.mongodbPermission = this.mongodbPermissions[index]; })
        }
        if (this.selectedScope === 'postgresql') {
          Row({ space: 12 }) {
            Text(harmonyDatabaseText('databaseUserSuperUserLabel')).layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: this.formSuperUser })
              .onChange((checked: boolean): void => { this.formSuperUser = checked; })
          }
          .constraintSize({ minHeight: 48 })
        }
        Text(harmonyDatabaseText('commonDescription')).width('100%').fontSize(14)
        TextArea({ text: this.formDescription })
          .constraintSize({ minHeight: 96 })
          .onChange((content: string): void => { this.formDescription = content; })
        if (this.feedback.length > 0) {
          Text(this.feedback).width('100%').fontSize(14)
        }
        if (this.editing.size > 0 && !this.loadedRemote && !this.isLoading) {
          Button(harmonyDatabaseText('commonRetry')).height(48).width('100%')
            .onClick((): void => { this.loadRemoteConfig(); })
        }
        if (this.selectedScope === 'remote') {
          Button(harmonyDatabaseText('databaseTestConnectionAction'))
            .height(48).width('100%').buttonStyle(ButtonStyleMode.NORMAL)
            .enabled(!this.isSaving && !this.isLoading && (this.editing.size === 0 || this.loadedRemote))
            .onClick((): void => { this.submit(true); })
        }
        Button(harmonyDatabaseText('commonSave'))
          .id('harmony.database.form.save')
          .height(48).width('100%')
          .enabled(!this.isSaving && !this.isLoading && (this.selectedScope !== 'remote' || this.connectionVerified))
          .onClick((): void => { this.submit(); })
      }
      .width('100%').padding(16).alignItems(HorizontalAlign.Start)
    }
    .width('100%').height('100%')
  }
}
