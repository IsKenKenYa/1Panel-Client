import { HarmonyNativeBridge, sheetMaterial } from '../../HarmonyNativeBridge';
import { HarmonySslSelectField, HarmonySslTextField, HarmonySslToggleField } from './HarmonyWebsiteSslFields';

@Component
export struct HarmonyWebsiteSslAccountsPage {
  @State private category: number = 0;
  @State private accounts: Map<string, Object | null> = new Map<string, Object | null>();
  @State private dnsTemplates: Map<string, Object | null>[] = [];
  @State private fields: Map<string, Object | null> = new Map<string, Object | null>();
  @State private authorization: Map<string, Object | null> = new Map<string, Object | null>();
  @State private formOpen: boolean = false;
  @State private operation: string = '';
  @State private loading: boolean = true;
  @State private working: boolean = false;
  @State private errorMessage: string = '';
  @State private formError: string = '';
  @State private caDetail: Map<string, Object | null> = new Map<string, Object | null>();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private categories: string[] = ['ca', 'acme', 'dns'];
  private createActions: string[] = ['createCa', 'createAcme', 'createDns'];
  private acmeTypes: string[] = ['letsencrypt', 'zerossl', 'buypass', 'google', 'custom'];
  private keyTypes: string[] = ['RSA2048', 'RSA3072', 'RSA4096', 'RSA8192', 'EC256', 'EC384'];
  private units: string[] = ['day', 'month', 'year'];

  aboutToAppear(): void {
    this.load(false);
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private value(key: string): string {
    return this.fields.get(key) as string | null ?? '';
  }

  private setField(key: string, content: Object | null): void {
    const draft = new Map<string, Object | null>(this.fields);
    draft.set(key, content);
    this.fields = draft;
  }

  private items(): Map<string, Object | null>[] {
    return this.accounts.get(this.categories[this.category]) as Map<string, Object | null>[] | null ?? [];
  }

  private options(values: string[]): SelectOption[] {
    return values.map((item: string): SelectOption => ({ value: item }));
  }

  private sync(reply: Map<string, Object | null>): void {
    this.accounts = reply;
    this.dnsTemplates = reply.get('dnsTemplates') as Map<string, Object | null>[];
    this.errorMessage = reply.get('error') as string | null ?? '';
  }

  private async load(refresh: boolean): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('refresh', refresh);
      this.sync(await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteSslAccounts', args));
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private actionTitle(action: string): string {
    switch (action) {
      case 'createCa': return this.text('websitesSslAccountsCreateCaAction');
      case 'createAcme': return this.text('websitesSslAccountsCreateAcmeAction');
      case 'updateAcme': return this.text('websitesSslAccountsEditAcmeAction');
      case 'createDns': return this.text('websitesSslAccountsCreateDnsAction');
      case 'updateDns': return this.text('websitesSslAccountsEditDnsAction');
      case 'obtainCa': return this.text('websitesSslAccountsObtainAction');
      case 'renewCa': return this.text('websitesSslAccountsRenewAction');
      case 'downloadCa': return this.text('websitesSslAccountsDownloadAction');
      case 'detailCa': return this.text('websitesSslAccountsCaTab');
      default: return this.text('commonDelete');
    }
  }

  private openForm(action: string, item?: Map<string, Object | null>): void {
    this.operation = action;
    this.formError = '';
    const draft = new Map<string, Object | null>();
    if (item !== undefined) {
      draft.set('id', item.get('id') as number);
      if (action === 'updateDns') {
        draft.set('name', item.get('name') as string);
        draft.set('type', item.get('type') as string);
      } else if (action === 'updateAcme') {
        draft.set('useProxy', item.get('useProxy') === true);
      }
    }
    if (action === 'createDns' && this.dnsTemplates.length > 0) {
      draft.set('type', this.dnsTemplates[0].get('type') as string);
    }
    if (action === 'createAcme') {
      draft.set('type', this.acmeTypes[0]);
      draft.set('useProxy', false);
      draft.set('useEAB', false);
    }
    if (action === 'createCa' || action === 'obtainCa' || action === 'createAcme') {
      draft.set('keyType', this.keyTypes[0]);
    }
    if (action === 'obtainCa') {
      draft.set('time', '1');
      draft.set('unit', 'year');
    }
    this.fields = draft;
    this.authorization = new Map<string, Object | null>(
      item?.get('authorization') as Map<string, Object | null> | null ?? new Map<string, Object | null>()
    );
    this.formOpen = true;
  }

  private formTitle(): string {
    return this.actionTitle(this.operation);
  }

  private dnsTypes(): string[] {
    return this.dnsTemplates.map((item: Map<string, Object | null>): string => item.get('type') as string);
  }

  private dnsFields(): Map<string, Object | null>[] {
    const template = this.dnsTemplates.find((item: Map<string, Object | null>): boolean =>
      item.get('type') === this.value('type'));
    return template?.get('fields') as Map<string, Object | null>[] | null ?? [];
  }

  private validation(args: Map<string, Object | null>): string {
    if (this.operation === 'createDns' || this.operation === 'updateDns') {
      if (this.value('name').trim().length === 0) return this.text('websitesSslAccountsValidationNameRequired');
      if (this.value('type').length === 0) return this.text('websitesSslAccountsValidationTypeRequired');
      args.set('authorization', this.authorization);
    }
    if (this.operation === 'createAcme' && this.value('email').trim().length === 0) {
      return this.text('websitesSslAccountsValidationEmailRequired');
    }
    if (this.operation === 'createCa' && (this.value('name').trim().length === 0 ||
      this.value('commonName').trim().length === 0 || this.value('country').trim().length === 0 ||
      this.value('organization').trim().length === 0)) {
      return this.text('websitesSslAccountsValidationRequiredFields');
    }
    if (this.operation === 'obtainCa') {
      if (this.value('domains').trim().length === 0) return this.text('websitesSslAccountsValidationDomainsRequired');
      const time = Number(this.value('time'));
      if (!Number.isInteger(time) || time < 1) return this.text('websitesSslAccountsValidationTimeInvalid');
      args.set('time', time);
    }
    return '';
  }

  private async action(operation: string, args: Map<string, Object | null>, fromForm: boolean = false): Promise<void> {
    if (this.working) return;
    this.working = true;
    this.formError = '';
    try {
      args.set('action', operation);
      const reply = await this.bridge.invoke<Map<string, Object | null>>('performNativeWebsiteSslAccountAction', args);
      this.sync(reply);
      if (this.errorMessage.length !== 0) {
        this.formError = this.errorMessage;
        return;
      }
      if (operation === 'detailCa') {
        this.operation = operation;
        this.caDetail = reply.get('detail') as Map<string, Object | null>;
        this.formOpen = true;
      } else {
        if (fromForm) this.formOpen = false;
        const download = reply.get('download') as Map<string, Object | null> | null;
        if (download?.get('cancelled') !== true) {
          this.getUIContext().getPromptAction().showToast({ message: this.text('websitesOperateSuccess') });
        }
      }
    } catch (error) {
      this.formError = (error as Error).message;
      if (!fromForm) this.errorMessage = this.formError;
    } finally {
      this.working = false;
    }
  }

  private submit(): void {
    const args = new Map<string, Object | null>(this.fields);
    this.formError = this.validation(args);
    if (this.formError.length === 0) this.action(this.operation, args, true);
  }

  private accountName(item: Map<string, Object | null>): string {
    return item.get(this.category === 1 ? 'email' : 'name') as string | null ?? '—';
  }

  private accountAction(operation: string, item: Map<string, Object | null>): void {
    const args = new Map<string, Object | null>();
    args.set('id', item.get('id') as number);
    if (operation === 'renewCa') args.set('sslId', item.get('renewSslId') as number);
    if (operation === 'downloadCa') args.set('fileName', `${this.accountName(item)}.zip`);
    if (operation.startsWith('delete') || operation === 'renewCa') {
      let message = this.text('websitesSslAccountsRenewConfirmMessage');
      if (operation === 'deleteCa') message = this.text('websitesSslAccountsDeleteCaMessage');
      if (operation === 'deleteAcme') message = this.text('websitesSslAccountsDeleteAcmeMessage');
      if (operation === 'deleteDns') message = this.text('websitesSslAccountsDeleteDnsMessage');
      this.getUIContext().showAlertDialog({
        title: this.actionTitle(operation),
        message: message.replace('{name}', this.accountName(item)).replace('{email}', this.accountName(item)),
        primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
        secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.action(operation, args); } },
      });
    } else {
      this.action(operation, args);
    }
  }

  private menu(item: Map<string, Object | null>): MenuElement[] {
    if (this.category === 0) {
      const actions: MenuElement[] = [
        { value: this.actionTitle('detailCa'), action: (): void => { this.accountAction('detailCa', item); } },
        { value: this.actionTitle('obtainCa'), action: (): void => { this.openForm('obtainCa', item); } },
        { value: this.actionTitle('downloadCa'), action: (): void => { this.accountAction('downloadCa', item); } },
        { value: this.actionTitle('deleteCa'), action: (): void => { this.accountAction('deleteCa', item); } },
      ];
      if (item.get('renewSslId') !== null && item.get('renewSslId') !== undefined) {
        actions.unshift({
          value: this.actionTitle('renewCa'),
          action: (): void => { this.accountAction('renewCa', item); },
        });
      }
      return actions;
    }
    const edit = this.category === 1 ? 'updateAcme' : 'updateDns';
    const remove = this.category === 1 ? 'deleteAcme' : 'deleteDns';
    return [
      { value: this.actionTitle(edit), action: (): void => { this.openForm(edit, item); } },
      { value: this.actionTitle(remove), action: (): void => { this.accountAction(remove, item); } },
    ];
  }

  @Builder
  private input(label: string, key: string, sensitive: boolean = false) {
    HarmonySslTextField({ label: label, currentText: this.value(key), sensitive: sensitive,
      onTextChanged: (content: string): void => { this.setField(key, content); } })
  }

  @Builder
  private select(label: string, key: string, values: string[]) {
    HarmonySslSelectField({ label: label, selectedText: this.value(key), choices: this.options(values),
      onSelected: (index: number): void => { this.setField(key, values[index]); } })
  }

  @Builder
  private dnsForm() {
    this.input(this.text('commonName'), 'name')
    HarmonySslSelectField({ label: this.text('websitesSslAccountsTypeLabel'), selectedText: this.value('type'),
      choices: this.options(this.dnsTypes()), onSelected: (index: number): void => {
        this.setField('type', this.dnsTypes()[index]);
        this.authorization = new Map<string, Object | null>();
      } })
    ForEach(this.dnsFields(), (field: Map<string, Object | null>) => {
      HarmonySslTextField({ label: field.get('label') as string, sensitive: field.get('sensitive') === true,
        currentText: this.authorization.get(field.get('key') as string) as string | null ?? '',
        onTextChanged: (content: string): void => {
          const draft = new Map<string, Object | null>(this.authorization);
          draft.set(field.get('key') as string, content);
          this.authorization = draft;
        } })
    }, (field: Map<string, Object | null>): string => field.get('key') as string)
  }

  @Builder
  private acmeForm() {
    if (this.operation === 'createAcme') {
      this.input(this.text('websitesSslAccountsEmailLabel'), 'email')
      this.select(this.text('websitesSslAccountsTypeLabel'), 'type', this.acmeTypes)
      this.select(this.text('websitesSslAccountsKeyTypeLabel'), 'keyType', this.keyTypes)
      if (this.value('type') === 'custom') this.input('ACME Directory URL', 'caDirURL')
      HarmonySslToggleField({ label: 'EAB', checked: this.fields.get('useEAB') === true,
        onCheckedChanged: (checked: boolean): void => { this.setField('useEAB', checked); } })
      if (this.fields.get('useEAB') === true) {
        this.input('EAB KID', 'eabKid')
        this.input('EAB HMAC Key', 'eabHmacKey', true)
      }
    }
    HarmonySslToggleField({ label: this.text('websitesSslAccountsUseProxyLabel'),
      checked: this.fields.get('useProxy') === true,
      onCheckedChanged: (checked: boolean): void => { this.setField('useProxy', checked); } })
  }

  @Builder
  private caForm() {
    if (this.operation === 'createCa') {
      this.input(this.text('commonName'), 'name')
      this.input(this.text('websitesSslAccountsCommonNameLabel'), 'commonName')
      this.input(this.text('websitesSslAccountsCountryLabel'), 'country')
      this.input(this.text('websitesSslAccountsOrganizationLabel'), 'organization')
      this.input(this.text('websitesSslAccountsOrganizationUnitLabel'), 'organizationUint')
      this.input(this.text('websitesSslAccountsProvinceLabel'), 'province')
      this.input(this.text('websitesSslAccountsCityLabel'), 'city')
    } else {
      this.input(this.text('websitesSslAccountsDomainsLabel'), 'domains')
      this.input(this.text('websitesSslAccountsTimeLabel'), 'time')
      this.select(this.text('websitesSslAccountsUnitLabel'), 'unit', this.units)
    }
    this.select(this.text('websitesSslAccountsKeyTypeLabel'), 'keyType', this.keyTypes)
  }

  @Builder
  private detailRow(label: string, key: string) {
    Row({ space: 12 }) {
      Text(label).layoutWeight(1).fontSize(16)
      Text(this.caDetail.get(key) as string | null ?? '—').fontSize(14)
        .fontColor($r('sys.color.font_secondary')).copyOption(CopyOptions.InApp)
    }.width('100%').constraintSize({ minHeight: 48 })
  }

  @Builder
  private form() {
    Scroll() {
      Column({ space: 12 }) {
        Text(this.formTitle()).fontSize(20).fontWeight(FontWeight.Medium).width('100%')
        if (this.operation === 'detailCa') {
          this.detailRow(this.text('commonName'), 'name')
          this.detailRow(this.text('websitesSslAccountsCommonNameLabel'), 'commonName')
          this.detailRow(this.text('websitesSslAccountsCountryLabel'), 'country')
          this.detailRow(this.text('websitesSslAccountsOrganizationLabel'), 'organization')
          this.detailRow(this.text('websitesSslAccountsOrganizationUnitLabel'), 'organizationUint')
          this.detailRow(this.text('websitesSslAccountsProvinceLabel'), 'province')
          this.detailRow(this.text('websitesSslAccountsCityLabel'), 'city')
          this.detailRow(this.text('websitesSslAccountsKeyTypeLabel'), 'keyType')
        } else {
          if (this.operation === 'createDns' || this.operation === 'updateDns') {
            this.dnsForm()
          } else if (this.operation === 'createAcme' || this.operation === 'updateAcme') {
            this.acmeForm()
          } else {
            this.caForm()
          }
          if (this.formError.length > 0) {
            Text(this.formError).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
          }
          Button(this.text('commonSave')).width('100%').height(48).enabled(!this.working)
            .onClick((): void => { this.submit(); })
        }
      }.padding(16).width('100%')
    }.height('100%').width('100%').align(Alignment.TopStart)
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Select(this.options([
          this.text('websitesSslAccountsCaTab'),
          this.text('websitesSslAccountsAcmeTab'),
          this.text('websitesSslAccountsDnsTab'),
        ])).selected(this.category).height(48).layoutWeight(1)
          .onSelect((index: number): void => { this.category = index; })
        Button() { SymbolGlyph($r('sys.symbol.plus')).fontSize(22) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .accessibilityText(this.actionTitle(this.createActions[this.category])).enabled(!this.loading)
          .onClick((): void => { this.openForm(this.createActions[this.category]); })
        Button() { SymbolGlyph($r('sys.symbol.arrow_clockwise')).fontSize(22) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .accessibilityText(this.text('commonRefresh')).enabled(!this.loading && !this.working)
          .onClick((): void => { this.load(true); })
      }.width('100%')
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else {
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontSize(14).width('100%')
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(true); })
        }
        if (this.items().length === 0 && this.errorMessage.length === 0) {
          Text(this.text('websitesSslAccountsEmpty')).padding(16).fontSize(16)
        }
        List() {
          ListItemGroup() {
            ForEach(this.items(), (item: Map<string, Object | null>) => {
              ListItem() {
                Row({ space: 12 }) {
                  Text(this.accountName(item)).fontSize(16).layoutWeight(1)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(20) }
                    .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                    .accessibilityText(this.text('commonMore')).bindMenu(this.menu(item))
                }.padding({ left: 16, right: 8 }).width('100%').constraintSize({ minHeight: 56 })
              }
            }, (item: Map<string, Object | null>): string => String(item.get('id')))
          }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
        }.width('100%').layoutWeight(1)
      }
    }.padding(16).height('100%').width('100%')
    .bindSheet($$this.formOpen, this.form, { height: SheetSize.LARGE, showClose: true, dragBar: true, systemMaterial: sheetMaterial })
  }
}
