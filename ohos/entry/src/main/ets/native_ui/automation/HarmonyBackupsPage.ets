import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { handleActivationKey } from '../HarmonyInteractionUtils';
import { HarmonyBackupAccountForm } from './HarmonyBackupAccountForm';
import { HarmonyAutomationTitle, automationText, automationString, automationWrite } from './HarmonyAutomationUI';

@Component
export struct HarmonyBackupsPage {
  @Prop initialRoute: string = '/backups';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @Prop showBack: boolean = true;
  onBack: () => void = (): void => {};
  @State private accounts: Map<string, Object | null>[] = [];
  @State private records: Map<string, Object | null>[] = [];
  @State private selectedAccount: Map<string, Object | null> = new Map<string, Object | null>();
  @State private selectedRecord: Map<string, Object | null> = new Map<string, Object | null>();
  @State private files: string[] = [];
  @State private recoveryOptions: Map<string, Object | null>[] = [];
  @State private candidates: Map<string, Object | null>[] = [];
  @State private recoveryType: string = 'app';
  @State private recoveryName: string = '';
  @State private recoveryDetailName: string = '';
  @State private pickRecoverySource: boolean = false;
  @State private searchText: string = '';
  @State private recordType: string = 'app';
  @State private recordName: string = '';
  @State private recordDetailName: string = '';
  @State private secret: string = '';
  @State private timeoutText: string = '3600';
  @State private loading: boolean = false;
  @State private failure: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private paths: NavPathStack = new NavPathStack();
  private recordTypes: string[] = ['app', 'website', 'mysql', 'mysql-cluster', 'mariadb', 'postgresql',
    'postgresql-cluster', 'redis', 'redis-cluster', 'directory', 'snapshot', 'log'];
  private recoveryTypes: string[] = this.recordTypes.slice(0, 9);

  aboutToAppear(): void {
    this.recordType = this.routeArguments.get('type') as string ?? 'app';
    this.recordName = this.routeArguments.get('name') as string ?? '';
    this.recordDetailName = this.routeArguments.get('detailName') as string ?? '';
    this.loadAccounts();
    if (this.initialRoute === '/backups/accounts/form') {
      this.openAccount(this.routeArguments.get('initialValue') as Map<string, Object | null> | undefined);
    } else if (this.initialRoute === '/backups/recover' && this.routeArguments.has('initialRecord')) {
      this.selectedRecord = this.routeArguments.get('initialRecord') as Map<string, Object | null>;
      this.openRecovery();
    } else if (this.initialRoute === '/backups/recover') {
      this.openRecovery(true);
    } else if (this.initialRoute === '/backups/records') {
      this.openRecords();
    }
  }

  private push(name: string): void {
    const path: NavPathInfo = { name: name };
    this.paths.pushPath(path);
  }

  private async loadAccounts(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      if (this.searchText.trim().length > 0) args.set('keyword', this.searchText.trim());
      this.accounts = await this.bridge.invoke<Map<string, Object | null>[]>('getNativeBackupAccounts', args);
    } catch (error) {
      this.failure = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async loadRecords(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('type', this.recordType);
      args.set('name', this.recordName.trim());
      args.set('detailName', this.recordDetailName.trim());
      const cronjobId = this.routeArguments.get('cronjobId');
      if (cronjobId !== undefined && cronjobId !== null) args.set('cronjobId', cronjobId);
      this.records = await this.bridge.invoke<Map<string, Object | null>[]>('searchNativeBackupRecords', args);
    } catch (error) {
      this.failure = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private openRecords(): void {
    this.push('backup-records');
    this.loadRecords();
  }

  private openAccount(account?: Map<string, Object | null>): void {
    this.selectedAccount = account ?? new Map<string, Object | null>();
    this.push('backup-account');
  }

  private openRecord(record: Map<string, Object | null>): void {
    this.selectedRecord = record;
    this.push('backup-record');
  }

  private async openFiles(account: Map<string, Object | null>): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('id', account.get('id') as number);
      this.files = await this.bridge.invoke<string[]>('getNativeBackupFiles', args);
      this.push('backup-files');
    } catch (error) {
      this.failure = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async write(method: string, args: Map<string, Object | null>): Promise<boolean> {
    this.loading = true;
    this.failure = '';
    try {
      await automationWrite(method, args);
      return true;
    } catch (error) {
      this.failure = (error as Error).message;
      this.getUIContext().getPromptAction().showToast({ message: this.failure.slice(0, 120) });
      return false;
    } finally {
      this.loading = false;
    }
  }

  private confirmDelete(record: Map<string, Object | null>, account: boolean): void {
    this.getUIContext().showAlertDialog({
      title: automationText('commonDelete'), message: automationString(record, account ? 'name' : 'fileName'),
      primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
      secondaryButton: { value: automationText('commonDelete'), action: (): void => { this.delete(record, account); } },
    });
  }

  private async delete(record: Map<string, Object | null>, account: boolean): Promise<void> {
    if (await this.write(account ? 'deleteBackupAccount' : 'deleteBackup', record)) {
      if (account) this.loadAccounts();
      else { this.paths.pop(); this.loadRecords(); }
    }
  }

  private async refreshToken(account: Map<string, Object | null>): Promise<void> {
    if (await this.write('refreshNativeBackupAccountToken', account)) this.loadAccounts();
  }

  private async recover(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('record', this.selectedRecord);
    args.set('type', this.recoveryType);
    args.set('name', this.recoveryName);
    args.set('detailName', this.recoveryDetailName);
    args.set('secret', this.secret);
    args.set('timeout', Number(this.timeoutText));
    if (await this.write('recoverNativeBackup', args)) {
      this.paths.pop();
      this.getUIContext().getPromptAction().showToast({ message: automationText('commonOperationSuccess') });
    }
  }

  private openRecovery(selectSource: boolean = false): void {
    this.secret = '';
    this.timeoutText = '3600';
    this.pickRecoverySource = selectSource;
    if (selectSource) {
      this.selectedRecord = new Map<string, Object | null>();
      this.recoveryType = this.recordType === 'database' ? 'mysql' : this.recordType;
      this.recoveryName = this.recordName;
      this.recoveryDetailName = this.recordDetailName;
      this.loadRecoveryOptions();
      if (this.recoveryName.length > 0 && this.recoveryDetailName.length > 0) this.loadCandidates();
    } else {
      this.recoveryType = automationString(this.selectedRecord, 'type');
      this.recoveryName = automationString(this.selectedRecord, 'name');
      this.recoveryDetailName = automationString(this.selectedRecord, 'detailName');
    }
    this.push('backup-recover');
  }

  private async loadRecoveryOptions(): Promise<void> {
    const type = this.recoveryType;
    this.recoveryOptions = [];
    this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('type', type);
      const options = await this.bridge.invoke<Map<string, Object | null>[]>('getNativeBackupRecoveryOptions', args);
      if (type === this.recoveryType) this.recoveryOptions = options;
    } catch (error) {
      this.failure = (error as Error).message;
    }
  }

  private async loadCandidates(): Promise<void> {
    this.loading = true;
    this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('type', this.recoveryType);
      args.set('name', this.recoveryName);
      args.set('detailName', this.recoveryDetailName);
      this.candidates = await this.bridge.invoke<Map<string, Object | null>[]>(
        'harmonyAutomation/getNativeBackupRecoveryRecords', args);
    } catch (error) {
      this.failure = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private recoverable(): boolean {
    const type = automationString(this.selectedRecord, 'type');
    return this.recordTypes.indexOf(type) >= 0 && !['directory', 'snapshot', 'log'].includes(type);
  }

  @Builder
  private accountMenu(account: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: automationText('commonEdit') }).onClick((): void => { this.openAccount(account); })
      MenuItem({ content: automationText('backupAccountCardBrowseFilesAction') })
        .onClick((): void => { this.openFiles(account); })
      if (['OneDrive', 'GoogleDrive', 'ALIYUN'].includes(automationString(account, 'type'))) {
        MenuItem({ content: automationText('backupAccountCardRefreshTokenAction') })
          .onClick((): void => { this.refreshToken(account); })
      }
      if (automationString(account, 'type') !== 'LOCAL') {
        MenuItem({ content: automationText('commonDelete') }).onClick((): void => { this.confirmDelete(account, true); })
      }
    }
  }

  @Builder
  private accountRows() {
    Column({ space: 12 }) {
      Search({ value: this.searchText, placeholder: automationText('backupAccountsSearchHint') })
        .height(48).onChange((content: string): void => { this.searchText = content; })
        .onSubmit((): void => { this.loadAccounts(); })
      if (this.loading) LoadingProgress().width(48).height(48)
      if (this.failure.length > 0) Text(this.failure).fontSize(14)
      List({ space: 10 }) {
        if (!this.loading && this.failure.length === 0 && this.accounts.length === 0) {
          ListItem() { Text(automationText('backupAccountsEmptyTitle')).padding(16).width('100%') }
        }
        ForEach(this.accounts, (account: Map<string, Object | null>): void => {
          ListItem() {
            Row({ space: 12 }) {
              SymbolGlyph($r('sys.symbol.externaldrive')).fontSize(22)
              Column({ space: 4 }) {
                Text(automationString(account, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
                Text(`${automationString(account, 'type')} · ${automationText(account.get('isPublic') === true ? 'backupAccountsScopePublic' : 'backupAccountsScopePrivate')}`)
                  .fontSize(14).fontColor($r('sys.color.font_secondary'))
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Button() { SymbolGlyph($r('sys.symbol.more')).fontSize(22) }
                .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .accessibilityText(automationText('commonMore')).bindMenu(this.accountMenu(account))
            }.padding({ left: 16, right: 8, top: 8, bottom: 8 }).constraintSize({ minHeight: 64 })
              .width('100%').borderRadius(16).backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .onClick((): void => { this.openAccount(account); })
              .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
                event,
                (): void => { this.openAccount(account); },
              ))
              .focusable(true)
              .focusOnTouch(true)
              .focusBox({ margin: LengthMetrics.vp(2) })
              .hoverEffect(HoverEffect.Highlight)
          }
        }, (account: Map<string, Object | null>): string => `${account.get('id')}`)
      }.layoutWeight(1).width('100%')
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private recordRows() {
    Column({ space: 12 }) {
      Select(this.recordTypes.map((type: string): SelectOption => ({ value: type })))
        .value(this.recordType).height(48).width('100%')
        .onSelect((index: number): void => { this.recordType = this.recordTypes[index]; this.loadRecords(); })
      TextInput({ text: this.recordName, placeholder: automationText('backupRecordsNameLabel') })
        .height(48).onChange((content: string): void => { this.recordName = content; })
        .onSubmit((): void => { this.loadRecords(); })
      TextInput({ text: this.recordDetailName, placeholder: automationText('backupRecordsDetailNameLabel') })
        .height(48).onChange((content: string): void => { this.recordDetailName = content; })
        .onSubmit((): void => { this.loadRecords(); })
      if (this.loading) LoadingProgress().width(48).height(48)
      if (this.failure.length > 0) Text(this.failure).fontSize(14)
      List({ space: 10 }) {
        if (!this.loading && this.failure.length === 0 && this.records.length === 0) {
          ListItem() { Text(automationText('backupRecordsEmptyTitle')).padding(16).width('100%') }
        }
        ForEach(this.records, (record: Map<string, Object | null>): void => {
          ListItem() {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text(automationString(record, 'fileName')).fontSize(16).fontWeight(FontWeight.Medium)
                Text(`${automationString(record, 'name')} · ${automationString(record, 'status')}`)
                  .fontSize(14).fontColor($r('sys.color.font_secondary'))
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16)
            }.padding(16).constraintSize({ minHeight: 64 }).width('100%')
              .borderRadius(16).backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .onClick((): void => { this.openRecord(record); })
              .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
                event,
                (): void => { this.openRecord(record); },
              ))
              .focusable(true)
              .focusOnTouch(true)
              .focusBox({ margin: LengthMetrics.vp(2) })
              .hoverEffect(HoverEffect.Highlight)
          }
        }, (record: Map<string, Object | null>): string => `${record.get('id')}`)
      }.layoutWeight(1).width('100%')
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private recordDetail() {
    Scroll() {
      Column({ space: 12 }) {
        Text(automationString(this.selectedRecord, 'fileName')).fontSize(20).fontWeight(FontWeight.Medium)
        Text(automationString(this.selectedRecord, 'fileDir')).fontSize(14).copyOption(CopyOptions.InApp)
        Text(automationString(this.selectedRecord, 'status')).fontSize(14)
        Button(automationText('backupRecordsDownloadAction')).width('100%').height(48)
          .enabled(!this.loading).onClick((): void => { this.write('downloadBackupRecord', this.selectedRecord); })
        if (this.recoverable()) {
          Button(automationText('backupRecordsRecoverAction')).width('100%').height(48)
            .enabled(!this.loading).onClick((): void => { this.openRecovery(); })
        }
        Button(automationText('commonDelete'), { role: ButtonRole.ERROR, buttonStyle: ButtonStyleMode.TEXTUAL })
          .width('100%').height(48).enabled(!this.loading)
          .onClick((): void => { this.confirmDelete(this.selectedRecord, false); })
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private recoverySelection() {
    Select(this.recoveryTypes.map((entry: string): SelectOption => ({
      value: entry === 'app' ? automationText('backupRecoverAppLabel') :
        entry === 'website' ? automationText('backupRecoverWebsiteLabel') : entry,
    }))).selected(this.recoveryTypes.indexOf(this.recoveryType)).width('100%').height(48)
      .enabled(!this.loading).accessibilityText(automationText('backupRecoverTypeLabel'))
      .onSelect((index: number): void => {
        this.recoveryType = this.recoveryTypes[index];
        this.recoveryName = '';
        this.recoveryDetailName = '';
        this.candidates = [];
        this.selectedRecord = new Map<string, Object | null>();
        this.loadRecoveryOptions();
      })
    if (this.recoveryOptions.length > 0) {
      Select(this.recoveryOptions.map((entry: Map<string, Object | null>): SelectOption => ({
        value: automationString(entry, 'detailName'),
      }))).value(this.recoveryDetailName.length > 0 ? this.recoveryDetailName : automationText('backupRecoverResourceStepTitle'))
        .height(48).width('100%').enabled(!this.loading)
        .onSelect((index: number): void => {
          const entry = this.recoveryOptions[index];
          this.recoveryName = automationString(entry, 'name');
          this.recoveryDetailName = automationString(entry, 'detailName');
          this.candidates = [];
          this.selectedRecord = new Map<string, Object | null>();
          this.loadCandidates();
        })
    }
    if (this.candidates.length > 0) {
      Select(this.candidates.map((entry: Map<string, Object | null>): SelectOption => ({
        value: automationString(entry, 'fileName'),
      }))).value(this.selectedRecord.size > 0 ? automationString(this.selectedRecord, 'fileName') : automationText('backupRecoverRecordLabel'))
        .width('100%').height(48).enabled(!this.loading)
        .onSelect((index: number): void => { this.selectedRecord = this.candidates[index]; })
    } else if (this.recoveryDetailName.length > 0 && !this.loading && this.failure.length === 0) {
      Text(automationText('backupRecoverNoCandidateRecords')).fontColor($r('sys.color.font_secondary'))
    }
  }

  @Builder
  private recoveryForm() {
    Column({ space: 12 }) {
      if (this.pickRecoverySource) {
        this.recoverySelection()
      } else {
        Text(automationString(this.selectedRecord, 'fileName')).fontSize(16).width('100%')
      }
      if (this.loading) LoadingProgress().width(48).height(48)
      if (this.failure.length > 0) Text(this.failure).fontSize(14)
      TextInput({ text: this.secret, placeholder: automationText('backupRecoverSecretLabel') })
        .type(InputType.Password).height(48).onChange((content: string): void => { this.secret = content; })
      TextInput({ text: this.timeoutText, placeholder: automationText('backupRecoverTimeoutLabel') })
        .type(InputType.Number).height(48).onChange((content: string): void => { this.timeoutText = content; })
      Button(automationText('backupRecoverStartAction')).width('100%').height(48)
        .enabled(!this.loading && this.selectedRecord.size > 0 && Number(this.timeoutText) > 0)
        .onClick((): void => {
          this.getUIContext().showAlertDialog({
            title: automationText('backupRecoverStartAction'), message: automationText('backupRecoverConfirmMessage'),
            primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
            secondaryButton: { value: automationText('commonConfirm'), action: (): void => { this.recover(); } },
          });
        })
    }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'backup-account') {
      NavDestination() {
        HarmonyBackupAccountForm({ account: this.selectedAccount, onSaved: (): void => { this.paths.pop(); this.loadAccounts(); } })
      }.title(automationText(this.selectedAccount.size === 0 ? 'backupAccountsCreateTitle' : 'commonEdit'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'backup-records') {
      NavDestination() { this.recordRows() }
        .title(automationText('operationsBackupRecordsTitle'), { barStyle: BarStyle.STANDARD })
        .menus([{ value: automationText('commonRefresh'), action: (): void => { this.loadRecords(); } }])
    } else if (name === 'backup-record') {
      NavDestination() { this.recordDetail() }
        .title(automationText('backupRecordsDetailTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'backup-recover') {
      NavDestination() { this.recoveryForm() }
        .title(automationText('backupRecordsRecoverAction'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'backup-files') {
      NavDestination() {
        List() {
          ForEach(this.files, (file: string): void => {
            ListItem() { Text(file).fontSize(16).copyOption(CopyOptions.InApp).padding(16).width('100%') }
          }, (file: string): string => file)
        }.width('100%').height('100%')
      }.title(automationText('backupFilesSheetTitle'), { barStyle: BarStyle.STANDARD })
    }
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: automationText('operationsBackupRecordsTitle'), action: (): void => { this.openRecords(); } },
      { value: automationText('backupRecordsRecoverAction'), action: (): void => { this.openRecovery(true); } },
      { value: automationText('backupAccountsCreateTitle'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.openAccount(); } },
    ];
  }

  @Builder
  private rootTitle() {
    HarmonyAutomationTitle({ label: automationText('backupAccountsSectionTitle'), showBack: this.showBack, onBack: this.onBack })
  }

  build() {
    Navigation(this.paths) { this.accountRows() }
      .title(this.rootTitle, { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true).menus(this.menus())
      .navDestination(this.destination).mode(NavigationMode.Stack)
      .width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
  }
}
