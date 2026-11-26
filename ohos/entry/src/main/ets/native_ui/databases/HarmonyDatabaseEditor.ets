import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyDatabaseItem, HarmonyDatabaseMetric, harmonyDatabaseMetrics, harmonyDatabaseText } from './HarmonyDatabaseModels';

@Component
export struct HarmonyDatabaseEditor {
  @Prop itemData: Map<string, Object | null> = new Map<string, Object | null>();
  @Prop editorMode: string = 'description';
  onSaved: () => void = (): void => {};
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';
  @State private textContent: string = '';
  @State private timeoutValue: string = '';
  @State private maxClients: string = '';
  @State private maxMemory: string = '';
  @State private appendOnly: string = 'no';
  @State private appendFsync: string = 'everysec';
  @State private savePolicy: string = '';
  @State private persistenceType: string = 'aof';
  @State private remoteValue: string = '%';
  @State private variables: HarmonyDatabaseMetric[] = [];
  private changedVariables: Map<string, string> = new Map<string, string>();

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    const item = new HarmonyDatabaseItem(this.itemData);
    try {
      if (this.editorMode === 'description') {
        this.textContent = item.text('description');
      } else if (this.editorMode === 'config') {
        const args = item.instanceRequest();
        args.set('type', `${item.engine}-conf`);
        const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getDatabaseConfFile', args);
        this.textContent = result.get('content') as string;
      } else if (this.editorMode === 'variables') {
        const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getMysqlVariables', item.instanceRequest());
        this.variables = harmonyDatabaseMetrics(result);
        this.changedVariables.clear();
      } else if (this.editorMode === 'redis') {
        const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getRedisConf', item.instanceRequest());
        this.timeoutValue = `${result.get('timeout') ?? ''}`;
        this.maxClients = `${result.get('maxclients') ?? ''}`;
        this.maxMemory = `${result.get('maxmemory') ?? ''}`;
      } else if (this.editorMode === 'persistence') {
        const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getRedisPersistence', item.instanceRequest());
        this.appendOnly = `${result.get('appendonly') ?? 'no'}`;
        this.appendFsync = `${result.get('appendfsync') ?? 'everysec'}`;
        this.savePolicy = `${result.get('save') ?? ''}`;
      } else if (this.editorMode === 'access') {
        const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getDatabaseRemoteAccess', item.instanceRequest());
        this.remoteValue = result.get('remoteAccess') === true ? '%' : 'localhost';
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async save(): Promise<void> {
    this.isSaving = true;
    this.errorMessage = '';
    const item = new HarmonyDatabaseItem(this.itemData);
    let method = '';
    let args = item.request();
    let legacyResult = false;
    if (this.editorMode === 'description') {
      method = 'updateHarmonyDatabaseDescription';
      args.set('description', this.textContent);
    } else if (this.editorMode === 'password' || this.editorMode === 'root-password') {
      method = this.editorMode === 'root-password' ? 'changeHarmonyMongodbRootPassword' : 'changeHarmonyDatabasePassword';
      args.set('password', this.textContent);
    } else {
      legacyResult = true;
      args = item.instanceRequest();
      args.set('database', item.lookupName);
      if (this.editorMode === 'config') {
        method = 'updateDatabaseConfFile';
        args.set('file', this.textContent);
      } else if (this.editorMode === 'variables') {
        method = 'updateMysqlVariables';
        const changes: Map<string, Object | null>[] = [];
        this.changedVariables.forEach((content: string, name: string): void => {
          const entry = new Map<string, Object | null>();
          entry.set('param', name);
          entry.set('value', content);
          changes.push(entry);
        });
        args.set('variables', changes);
      } else if (this.editorMode === 'redis') {
        method = 'updateRedisConf';
        args.set('dbType', item.engine);
        args.set('timeout', this.timeoutValue);
        args.set('maxclients', this.maxClients);
        args.set('maxmemory', this.maxMemory);
      } else if (this.editorMode === 'persistence') {
        method = 'updateRedisPersistence';
        args.set('dbType', item.engine);
        args.set('type', this.persistenceType);
        args.set('appendonly', this.appendOnly);
        args.set('appendfsync', this.appendFsync);
        args.set('save', this.savePolicy);
      } else if (this.editorMode === 'access') {
        method = 'updateDatabaseAccess';
        args.set('from', item.source);
        args.set('value', this.remoteValue);
      }
    }
    try {
      const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null> | null>(method, args);
      if (legacyResult && result !== null && result.get('success') !== true) {
        throw new Error(result.get('error') as string);
      }
      this.getUIContext().getPromptAction().showToast({ message: harmonyDatabaseText('commonSaveSuccess') });
      this.onSaved();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.isLoading) {
          LoadingProgress().width(48).height(48)
        } else {
          if (this.editorMode === 'description' || this.editorMode === 'config') {
            TextArea({ text: this.textContent })
              .constraintSize({ minHeight: 240 })
              .fontFamily(this.editorMode === 'config' ? 'monospace' : 'HarmonyOS Sans')
              .onChange((content: string): void => { this.textContent = content; })
          } else if (this.editorMode === 'password' || this.editorMode === 'root-password') {
            Text(harmonyDatabaseText('databasePasswordLabel')).width('100%').fontSize(14)
            TextInput({ text: this.textContent }).type(InputType.Password).height(48)
              .onChange((content: string): void => { this.textContent = content; })
          } else if (this.editorMode === 'variables') {
            ForEach(this.variables, (variable: HarmonyDatabaseMetric): void => {
              Column({ space: 8 }) {
                Text(variable.name).width('100%').fontSize(14)
                TextInput({ text: variable.content }).height(48)
                  .onChange((content: string): void => { this.changedVariables.set(variable.name, content); })
              }
              .width('100%')
            }, (variable: HarmonyDatabaseMetric): string => variable.name)
          } else if (this.editorMode === 'redis') {
            Text(harmonyDatabaseText('databaseRedisTimeoutLabel')).width('100%').fontSize(14)
            TextInput({ text: this.timeoutValue }).height(48).type(InputType.Number)
              .onChange((content: string): void => { this.timeoutValue = content; })
            Text(harmonyDatabaseText('databaseRedisMaxClientsLabel')).width('100%').fontSize(14)
            TextInput({ text: this.maxClients }).height(48).type(InputType.Number)
              .onChange((content: string): void => { this.maxClients = content; })
            Text('maxmemory').width('100%').fontSize(14)
            TextInput({ text: this.maxMemory }).height(48)
              .onChange((content: string): void => { this.maxMemory = content; })
          } else if (this.editorMode === 'persistence') {
            Select([{ value: 'AOF' }, { value: 'RDB' }])
              .selected(this.persistenceType === 'aof' ? 0 : 1)
              .height(48).width('100%')
              .onSelect((index: number): void => { this.persistenceType = ['aof', 'rbd'][index]; })
            Text(harmonyDatabaseText('databaseRedisAppendOnlyLabel')).width('100%').fontSize(14)
            Select([{ value: 'yes' }, { value: 'no' }])
              .value(this.appendOnly).height(48)
              .onSelect((index: number): void => { this.appendOnly = ['yes', 'no'][index]; })
            Text('appendfsync').width('100%').fontSize(14)
            Select([{ value: 'always' }, { value: 'everysec' }, { value: 'no' }])
              .value(this.appendFsync).height(48)
              .onSelect((index: number): void => { this.appendFsync = ['always', 'everysec', 'no'][index]; })
            Text(harmonyDatabaseText('databaseRedisSaveLabel')).width('100%').fontSize(14)
            TextInput({ text: this.savePolicy }).height(48)
              .onChange((content: string): void => { this.savePolicy = content; })
          } else if (this.editorMode === 'access') {
            Select([{ value: '%' }, { value: 'localhost' }])
              .value(this.remoteValue).height(48).width('100%')
              .onSelect((index: number): void => { this.remoteValue = ['%', 'localhost'][index]; })
          }
          Button(harmonyDatabaseText('commonSave')).height(48).width('100%')
            .enabled(!this.isSaving)
            .onClick((): void => { this.save(); })
        }
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).width('100%').fontSize(14)
          Button(harmonyDatabaseText('commonRetry')).height(48)
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => { this.load(); })
        }
      }
      .padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }
    .width('100%').height('100%')
  }
}
