import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyDatabaseItem, HarmonyDatabaseMetric, HarmonyDatabaseMetricRows, harmonyDatabaseMetrics, harmonyDatabaseText } from './HarmonyDatabaseModels';

@Component
export struct HarmonyDatabaseDetail {
  @Prop itemData: Map<string, Object | null> = new Map<string, Object | null>();
  onNavigate: (route: string) => void = (route: string): void => {};
  onDeleted: () => void = (): void => {};
  @State private isLoading: boolean = true;
  @State private errorMessage: string = '';
  @State private baseRows: HarmonyDatabaseMetric[] = [];
  @State private statusRows: HarmonyDatabaseMetric[] = [];
  @State private variableRows: HarmonyDatabaseMetric[] = [];

  aboutToAppear(): void {
    this.load();
  }

  private scope(): string {
    return this.itemData.get('scope') as string;
  }

  private async load(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const item = new HarmonyDatabaseItem(this.itemData);
      const detail = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null>>('getHarmonyDatabaseDetail', item.request());
      const base = detail.get('baseInfo') as Map<string, Object | null> | null | undefined;
      const status = detail.get('status') as Map<string, Object | null> | null | undefined;
      const variables = detail.get('variables') as Map<string, Object | null> | null | undefined;
      this.baseRows = base ? harmonyDatabaseMetrics(base) : [];
      this.statusRows = status ? harmonyDatabaseMetrics(status) : [];
      this.variableRows = variables ? harmonyDatabaseMetrics(variables) : [];
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  private async reloadRemote(): Promise<void> {
    try {
      await HarmonyNativeBridge.instance.invoke<Object | null>(
        'loadHarmonyDatabaseFromRemote', new HarmonyDatabaseItem(this.itemData).request());
      await this.load();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private confirmLoadFromRemote(): void {
    const item = new HarmonyDatabaseItem(this.itemData);
    this.getUIContext().showAlertDialog({
      title: harmonyDatabaseText('commonLoad'),
      message: item.lookupName,
      primaryButton: { value: harmonyDatabaseText('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: harmonyDatabaseText('commonConfirm'),
        action: (): void => { this.reloadRemote(); },
      },
    });
  }

  private confirmDelete(): void {
    const item = new HarmonyDatabaseItem(this.itemData);
    this.getUIContext().showAlertDialog({
      title: harmonyDatabaseText(item.scope === 'remote' ? 'databaseRemoteUnbindAction' : 'commonDelete'),
      message: harmonyDatabaseText(item.scope === 'remote' ? 'databaseRemoteUnbindMessage' : 'commonDeleteConfirm'),
      primaryButton: { value: harmonyDatabaseText('commonCancel'), action: (): void => {} },
      secondaryButton: {
        value: harmonyDatabaseText('commonConfirm'),
        action: (): void => { this.deleteItem(); },
      },
    });
  }

  private async deleteItem(): Promise<void> {
    const item = new HarmonyDatabaseItem(this.itemData);
    try {
      const dependencies = await HarmonyNativeBridge.instance.invoke<string[]>('deleteHarmonyDatabase', item.request());
      if (dependencies.length > 0) {
        this.errorMessage = `${harmonyDatabaseText('databaseRemoteUnbindInUse')}\n${dependencies.join('\n')}`;
        return;
      }
      this.onDeleted();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  @Builder
  private action(titleKey: string, route: string) {
    ListItem() {
      Row({ space: 12 }) {
        Text(harmonyDatabaseText(titleKey)).fontSize(16).layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }
      .width('100%').constraintSize({ minHeight: 56 }).padding({ left: 16, right: 16 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
      .onClick((): void => { this.onNavigate(route); })
      .accessibilityText(harmonyDatabaseText(titleKey))
    }
  }

  build() {
    List({ space: 12 }) {
      if (this.isLoading) {
        ListItem() { LoadingProgress().width(48).height(48) }
      }
      if (this.errorMessage.length > 0) {
        ListItem() {
          Column({ space: 12 }) {
            Text(this.errorMessage).fontSize(14)
            Button(harmonyDatabaseText('commonRetry')).height(48)
              .onClick((): void => { this.load(); })
          }.padding(16).width('100%')
        }
      }
      ListItem() {
        Column({ space: 4 }) {
          Text(this.itemData.get('name') as string).fontSize(20).fontWeight(FontWeight.Medium)
          Text(`${this.itemData.get('engine')} · ${this.itemData.get('lookupName')}`).fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }.alignItems(HorizontalAlign.Start).width('100%').padding(16)
      }
      if (this.baseRows.length > 0) {
        ListItem() { HarmonyDatabaseMetricRows({ rows: this.baseRows }) }
      }
      if (this.statusRows.length > 0) {
        ListItem() {
          Column({ space: 8 }) {
            Text(harmonyDatabaseText('databaseStatusTitle')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
            HarmonyDatabaseMetricRows({ rows: this.statusRows })
          }
        }
      }
      if (this.scope() === 'mysql' || this.scope() === 'postgresql') {
        this.action('databaseConfigTitle', 'config')
        this.action('commonDescription', 'description')
        this.action('databaseUsersPageTitle', 'users')
        if (this.scope() === 'postgresql') {
          this.action('databaseChangePasswordAction', 'password')
        }
      }
      if (this.scope() === 'mysql') {
        this.action('databaseMysqlVariablesTitle', 'variables')
        this.action('databaseSlowLogTitle', 'slow-log')
        this.action('databaseRemoteAccessLabel', 'access')
      }
      if (this.scope() === 'mysql' || this.scope() === 'postgresql' || this.scope() === 'redis') {
        this.action('databaseBackupsPageTitle', 'backups')
      }
      if (this.scope() === 'redis') {
        this.action('databaseRedisConfigTitle', 'redis')
        this.action('databaseRedisPersistenceTitle', 'persistence')
        this.action('databaseChangePasswordAction', 'password')
      }
      if (this.scope() === 'mongodb') {
        this.action('databasePermission', 'users')
        this.action('databaseChangePasswordAction', 'password')
        if (this.itemData.get('source') === 'local') {
          this.action('databaseUserSuperUserLabel', 'root-password')
        }
        this.action('commonDescription', 'description')
      }
      if (this.scope() === 'remote') {
        this.action('databaseRemoteTitle', 'remote-form')
      } else if (this.scope() !== 'redis') {
        ListItem() {
          Button(harmonyDatabaseText('commonLoad')).height(48).width('100%').buttonStyle(ButtonStyleMode.NORMAL)
            .onClick((): void => { this.confirmLoadFromRemote(); })
        }
      }
      if (this.scope() !== 'redis' && this.itemData.get('id') !== null && this.itemData.get('id') !== undefined) {
        ListItem() {
          Button(harmonyDatabaseText(this.scope() === 'remote' ? 'databaseRemoteUnbindAction' : 'commonDelete'))
            .height(48).width('100%').buttonStyle(ButtonStyleMode.TEXTUAL)
            .fontColor($r('sys.color.ohos_id_color_alert'))
            .onClick((): void => { this.confirmDelete(); })
        }
      }
      if (this.variableRows.length > 0) {
        ListItem() {
          Column({ space: 8 }) {
            Text(harmonyDatabaseText('databaseVariablesTitle')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
            HarmonyDatabaseMetricRows({ rows: this.variableRows })
          }
        }
      }
    }
    .padding(16).width('100%').height('100%')
  }
}

@Component
export struct HarmonyDatabaseSlowLog {
  @Prop itemData: Map<string, Object | null> = new Map<string, Object | null>();
  @State private logs: string[] = [];
  @State private errorMessage: string = '';
  @State private isLoading: boolean = true;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.isLoading = true;
    try {
      const item = new HarmonyDatabaseItem(this.itemData);
      this.logs = await HarmonyNativeBridge.instance.invoke<string[]>('getHarmonyDatabaseSlowLog', item.request());
      this.errorMessage = '';
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    List({ space: 12 }) {
      if (this.isLoading) {
        ListItem() { LoadingProgress().width(48).height(48) }
      } else if (this.logs.length === 0) {
        ListItem() { Text(harmonyDatabaseText('databaseSlowLogEmpty')).padding(24) }
      }
      if (this.errorMessage.length > 0) {
        ListItem() { Text(this.errorMessage).fontSize(14).padding(16) }
      }
      ForEach(this.logs, (entry: string): void => {
        ListItem() {
          Text(entry).fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp).width('100%')
        }
      }, (entry: string, index: number): string => `${index}:${entry}`)
      ListItem() {
        Button(harmonyDatabaseText('commonRefresh')).height(48).width('100%')
          .onClick((): void => { this.load(); })
      }
    }
    .padding(16).width('100%').height('100%')
  }
}
