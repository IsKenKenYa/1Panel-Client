import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyDatabaseItem, harmonyDatabaseText } from './HarmonyDatabaseModels';

@Component
export struct HarmonyDatabaseUsers {
  @Prop itemData: Map<string, Object | null> = new Map<string, Object | null>();
  @State private users: Map<string, Object | null>[] = [];
  @State private grants: Map<string, Object | null>[] = [];
  @State private isLoading: boolean = true;
  @State private isSaving: boolean = false;
  @State private errorMessage: string = '';
  @State private formMode: string = '';
  @State private username: string = '';
  @State private userHost: string = '%';
  @State private newHost: string = '';
  @State private userDescription: string = '';
  @State private passwordValue: string = '';
  @State private grantDatabase: string = '';
  @State private superUser: boolean = false;
  @State private mongodbPermission: string = '';
  private readonly mongodbPermissions: string[] = ['dbOwner', 'read', 'readWrite', 'userAdmin'];

  aboutToAppear(): void {
    this.username = `${this.itemData.get('username') ?? ''}`;
    this.grantDatabase = this.itemData.get('name') as string;
    this.load();
  }

  private scope(): string {
    return this.itemData.get('scope') as string;
  }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    const item = new HarmonyDatabaseItem(this.itemData);
    try {
      if (item.scope === 'mysql') {
        this.users = await HarmonyNativeBridge.instance.invoke<Array<Map<string, Object | null>>>(
          'getHarmonyDatabaseUsers', item.request());
        this.grants = await HarmonyNativeBridge.instance.invoke<Array<Map<string, Object | null>>>(
          'getDatabaseGrants', item.instanceRequest());
      } else if (item.scope === 'mongodb') {
        this.grants = await HarmonyNativeBridge.instance.invoke<Array<Map<string, Object | null>>>(
          'getHarmonyMongodbPrivileges', item.request());
      } else if (item.scope === 'postgresql') {
        this.grants = await HarmonyNativeBridge.instance.invoke<Array<Map<string, Object | null>>>(
          'getHarmonyPostgresqlPrivileges', item.request());
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private editUser(user: Map<string, Object | null>, mode: string): void {
    this.username = user.get('username') as string;
    this.userHost = user.get('host') as string;
    this.newHost = this.userHost;
    this.userDescription = `${user.get('description') ?? ''}`;
    this.passwordValue = '';
    this.formMode = mode;
  }

  private async write(method: string, args: Map<string, Object | null>, legacy: boolean): Promise<void> {
    this.isSaving = true;
    this.errorMessage = '';
    try {
      const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null> | null>(method, args);
      if (legacy && result !== null && result.get('success') !== true) {
        throw new Error(result.get('error') as string);
      }
      this.formMode = '';
      this.passwordValue = '';
      this.getUIContext().getPromptAction().showToast({ message: harmonyDatabaseText('commonSaveSuccess') });
      await this.load();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isSaving = false;
    }
  }

  private saveUser(): void {
    const item = new HarmonyDatabaseItem(this.itemData);
    const args = item.request();
    args.set('username', this.username);
    args.set('password', this.passwordValue);
    args.set('permission', this.userHost);
    args.set('superUser', this.superUser);
    if (this.formMode === 'mongodb-privilege') {
      args.set('permission', this.mongodbPermission);
      this.write('changeHarmonyMongodbPrivileges', args, false);
      return;
    }
    if (this.formMode === 'bind') {
      this.write('bindHarmonyDatabaseUser', args, false);
      return;
    }
    if (this.formMode === 'privilege') {
      this.write('updateHarmonyDatabasePrivileges', args, false);
      return;
    }
    const legacyArgs = item.instanceRequest();
    legacyArgs.set('username', this.username);
    legacyArgs.set('host', this.userHost);
    legacyArgs.set('password', this.passwordValue);
    legacyArgs.set('newHost', this.newHost);
    legacyArgs.set('description', this.userDescription);
    legacyArgs.set('db', this.grantDatabase);
    const method = this.formMode === 'password' ? 'updateDatabaseUserPassword' :
      this.formMode === 'edit' ? 'updateDatabaseUser' : 'grantDatabaseUser';
    this.write(method, legacyArgs, true);
  }

  private confirmRemove(user: Map<string, Object | null>, grant: boolean): void {
    const item = new HarmonyDatabaseItem(this.itemData);
    const args = item.instanceRequest();
    args.set('username', user.get('username') as string);
    args.set('host', user.get('host') as string);
    if (grant) {
      args.set('db', user.get('database') as string);
    }
    this.getUIContext().showAlertDialog({
      title: harmonyDatabaseText('commonDelete'),
      message: `${user.get('username')}@${user.get('host')}`,
      primaryButton: { value: harmonyDatabaseText('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: harmonyDatabaseText('commonDelete'),
        fontColor: $r('sys.color.ohos_id_color_alert'),
        action: (): void => { this.write(grant ? 'revokeDatabaseGrant' : 'deleteDatabaseUser', args, true); },
      },
    });
  }

  @Builder
  private userMenu(user: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: harmonyDatabaseText('commonEdit') })
        .onClick((): void => { this.editUser(user, 'edit'); })
      MenuItem({ content: harmonyDatabaseText('databaseUserChangePassword') })
        .onClick((): void => { this.editUser(user, 'password'); })
      MenuItem({ content: harmonyDatabaseText('databasePermission') })
        .onClick((): void => { this.editUser(user, 'grant'); })
      MenuItem({ content: harmonyDatabaseText('commonDelete') })
        .onClick((): void => { this.confirmRemove(user, false); })
    }
  }

  @Builder
  private userForm() {
    Column({ space: 12 }) {
      Text(harmonyDatabaseText('databaseUsernameLabel')).width('100%').fontSize(14)
      TextInput({ text: this.username }).height(48)
        .enabled(this.formMode === 'bind' || this.formMode === 'privilege')
        .onChange((content: string): void => { this.username = content; })
      if (this.formMode === 'bind' || this.formMode === 'password') {
        Text(harmonyDatabaseText('databasePasswordLabel')).width('100%').fontSize(14)
        TextInput({ text: this.passwordValue }).height(48).type(InputType.Password)
          .onChange((content: string): void => { this.passwordValue = content; })
      }
      if (this.scope() === 'mysql') {
        Text(harmonyDatabaseText('databaseUserHostLabel')).width('100%').fontSize(14)
        TextInput({ text: this.userHost }).height(48).enabled(this.formMode === 'bind')
          .onChange((content: string): void => { this.userHost = content; })
      }
      if (this.formMode === 'edit') {
        TextInput({ text: this.newHost, placeholder: harmonyDatabaseText('databaseUserHostLabel') }).height(48)
          .onChange((content: string): void => { this.newHost = content; })
        TextInput({ text: this.userDescription, placeholder: harmonyDatabaseText('commonDescription') }).height(48)
          .onChange((content: string): void => { this.userDescription = content; })
      }
      if (this.formMode === 'grant') {
        Text(harmonyDatabaseText('databaseDbLabel')).width('100%').fontSize(14)
        TextInput({ text: this.grantDatabase }).height(48)
          .onChange((content: string): void => { this.grantDatabase = content; })
      }
      if (this.scope() === 'postgresql') {
        Row({ space: 12 }) {
          Text(harmonyDatabaseText('databaseUserSuperUserLabel')).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.superUser })
            .onChange((checked: boolean): void => { this.superUser = checked; })
        }
        .constraintSize({ minHeight: 48 })
      }
      if (this.formMode === 'mongodb-privilege') {
        Text(harmonyDatabaseText('databasePermission')).width('100%').fontSize(14)
        Select(this.mongodbPermissions.map((permission: string): SelectOption => ({ value: permission })))
          .height(48).value(this.mongodbPermission)
          .onSelect((index: number): void => { this.mongodbPermission = this.mongodbPermissions[index]; })
      }
      Row({ space: 12 }) {
        Button(harmonyDatabaseText('commonCancel')).height(48).layoutWeight(1)
          .buttonStyle(ButtonStyleMode.NORMAL)
          .onClick((): void => { this.formMode = ''; })
        Button(harmonyDatabaseText('commonSave')).height(48).layoutWeight(1).enabled(!this.isSaving)
          .onClick((): void => { this.saveUser(); })
      }
    }
    .padding(16).borderRadius(16).backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
  }

  build() {
    List({ space: 12 }) {
      if (this.isLoading) {
        ListItem() { LoadingProgress().width(48).height(48) }
      }
      if (this.errorMessage.length > 0) {
        ListItem() { Text(this.errorMessage).fontSize(14).padding(16) }
      }
      if (this.formMode.length > 0) {
        ListItem() { this.userForm() }
      } else if (this.scope() === 'mysql' || this.scope() === 'postgresql' || this.scope() === 'mongodb') {
        ListItem() {
          Button(harmonyDatabaseText('databaseUserBindAction')).height(48).width('100%')
            .onClick((): void => { this.formMode = 'bind'; this.passwordValue = ''; })
        }
        if (this.scope() === 'postgresql') {
          ListItem() {
            Button(harmonyDatabaseText('databaseUserPrivilegesAction')).height(48).width('100%')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .onClick((): void => { this.formMode = 'privilege'; })
          }
        }
      }
      ForEach(this.users, (user: Map<string, Object | null>): void => {
        ListItem() {
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text(`${user.get('username')}`).fontSize(16).fontWeight(FontWeight.Medium)
              Text(`${user.get('host')}`).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Button() { SymbolGlyph($r('sys.symbol.more')).fontSize(22) }
              .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
              .accessibilityText(harmonyDatabaseText('commonMore'))
              .bindMenu(this.userMenu(user))
          }
          .width('100%').padding(16).borderRadius(16)
          .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
        }
      }, (user: Map<string, Object | null>): string => `${user.get('username')}@${user.get('host')}`)
      ForEach(this.grants, (grant: Map<string, Object | null>, index: number): void => {
        ListItem() {
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text(`${grant.get('username') ?? grant.get('role') ?? grant.get('name') ?? ''}`).fontSize(16)
              if (this.scope() === 'postgresql' && grant.get('superUser') === true) {
                Text(harmonyDatabaseText('databaseUserSuperUserLabel')).fontSize(14)
              } else if (this.scope() !== 'postgresql') {
                Text(`${grant.get('privileges') ?? grant.get('database') ?? ''}`).fontSize(14)
              }
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            if (this.scope() === 'mysql') {
              Button(harmonyDatabaseText('commonDelete')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick((): void => { this.confirmRemove(grant, true); })
            } else if (this.scope() === 'mongodb') {
              Button(harmonyDatabaseText('commonEdit')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick((): void => {
                  this.mongodbPermission = grant.get('privileges') as string;
                  this.formMode = 'mongodb-privilege';
                })
            }
          }
          .width('100%').padding(16).borderRadius(16)
          .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
        }
      }, (grant: Map<string, Object | null>, index: number): string => `${grant.get('username')}@${grant.get('host')}:${grant.get('database')}:${index}`)
      ListItem() {
        Button(harmonyDatabaseText('commonRefresh')).height(48).width('100%')
          .buttonStyle(ButtonStyleMode.TEXTUAL)
          .onClick((): void => { this.load(); })
      }
    }
    .padding(16).width('100%').height('100%')
  }
}
