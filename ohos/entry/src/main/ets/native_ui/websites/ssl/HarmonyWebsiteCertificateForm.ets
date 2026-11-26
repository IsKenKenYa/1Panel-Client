import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';
import { HarmonySslSelectField, HarmonySslTextField, HarmonySslToggleField } from './HarmonyWebsiteSslFields';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyWebsiteCertificateForm {
  @Prop operation: string = 'create';
  @Prop certificate: Map<string, Object | null> = new Map<string, Object | null>();
  onSaved: () => void = (): void => {};
  @State private draft: Map<string, Object | null> = new Map<string, Object | null>();
  @State private acmeAccounts: Map<string, Object | null>[] = [];
  @State private dnsAccounts: Map<string, Object | null>[] = [];
  @State private dnsRecords: Map<string, Object | null>[] = [];
  @State private saving: boolean = false;
  @State private errorMessage: string = '';
  @State private fileLoading: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private keyTypes: string[] = ['EC256', 'EC384', 'RSA2048', 'RSA3072', 'RSA4096'];
  private providers: string[] = ['dnsAccount', 'dnsManual', 'http'];
  private uploadTypes: string[] = ['paste', 'local', 'device'];

  aboutToAppear(): void {
    if (this.operation === 'upload') {
      this.draft = new Map<string, Object | null>();
      this.draft.set('type', 'paste');
      this.draft.set('id', this.certificate.get('id') ?? null);
      this.draft.set('description', this.certificate.get('description') ?? null);
      return;
    }
    this.draft = new Map<string, Object | null>(this.certificate);
    if (this.operation === 'create') {
      this.draft.set('provider', 'dnsAccount');
      this.draft.set('keyType', 'EC256');
    }
    this.draft.set('isIp', this.certificate.get('isIP') === true);
    const domains = this.certificate.get('domains') as string[] | null;
    if (domains !== null && domains !== undefined) this.draft.set('otherDomains', domains.join('\n'));
    if (this.operation === 'create' || this.operation === 'update' || this.operation === 'resolve') this.loadAccounts();
  }

  private text(key: string): string { return this.bridge.text(key); }
  private content(key: string): string { return this.draft.get(key) as string | null ?? ''; }
  private checked(key: string): boolean { return this.draft.get(key) === true; }

  private async loadAccounts(): Promise<void> {
    try {
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteSslAccounts');
      this.acmeAccounts = reply.get('acme') as Map<string, Object | null>[];
      this.dnsAccounts = reply.get('dns') as Map<string, Object | null>[];
      const accountError = reply.get('error') as string | null;
      if (accountError !== null) this.errorMessage = accountError;
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private options(entries: string[]): SelectOption[] {
    return entries.map((entry: string): SelectOption => ({ value: entry }));
  }

  private providerLabel(provider: string): string {
    if (provider === 'dnsAccount') return this.text('websiteDnsAccount');
    if (provider === 'dnsManual') return this.text('websiteDnsManual');
    return provider === 'http' ? 'HTTP' : provider;
  }

  private uploadTypeLabel(type: string): string {
    if (type === 'local') return this.text('websitesSslUploadTypeServerFiles');
    if (type === 'device') return this.text('websitesSslUploadTypeDeviceFiles');
    return this.text('websitesSslUploadTypePaste');
  }

  private accountOptions(accounts: Map<string, Object | null>[], labelKey: string): SelectOption[] {
    return accounts.map((account: Map<string, Object | null>): SelectOption => ({
      value: `${account.get(labelKey) as string} · ${account.get('type') as string}`,
    }));
  }

  private selectedAccount(accounts: Map<string, Object | null>[], key: string, labelKey: string): string {
    const selected = accounts.find((account: Map<string, Object | null>): boolean =>
      account.get('id') === this.draft.get(key));
    return selected?.get(labelKey) as string | null ?? this.text('websiteSslSelectAccount');
  }

  private availableAcmeAccounts(): Map<string, Object | null>[] {
    if (!this.checked('isIp')) return this.acmeAccounts;
    return this.acmeAccounts.filter((account: Map<string, Object | null>): boolean =>
      account.get('type') === 'letsencrypt');
  }

  private chooseAcmeAccount(index: number): void {
    const account = this.availableAcmeAccounts()[index];
    this.draft.set('acmeAccountId', account.get('id') as number);
    if (this.operation === 'create') {
      const keyType = account.get('keyType') as string | null;
      if (keyType && this.keyTypes.includes(keyType)) this.draft.set('keyType', keyType);
    }
  }

  private async submit(): Promise<void> {
    if (this.saving || this.fileLoading) return;
    if ((this.operation === 'create' || this.operation === 'update') &&
      (this.content('primaryDomain').trim().length === 0 || this.content('provider').length === 0)) {
      this.errorMessage = this.text('websitesSslAccountsValidationRequiredFields');
      return;
    }
    if ((this.operation === 'create' || this.operation === 'resolve') &&
      !(Number(this.draft.get('acmeAccountId')) > 0)) {
      this.errorMessage = this.text('websitesSslAccountsValidationRequiredFields');
      return;
    }
    if ((this.operation === 'create' || this.operation === 'update') &&
      this.content('provider') === 'dnsAccount' && !(Number(this.draft.get('dnsAccountId')) > 0)) {
      this.errorMessage = this.text('websitesSslAccountsValidationRequiredFields');
      return;
    }
    if (this.operation === 'upload' && this.content('type') === 'device' &&
      (this.content('certificatePem').length === 0 || this.content('privateKeyPem').length === 0)) {
      this.errorMessage = this.text('websitesSslAccountsValidationRequiredFields');
      return;
    }
    this.saving = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>(this.draft);
      args.set('action', this.operation);
      if (this.operation === 'create' || this.operation === 'update') {
        args.set('primaryDomain', this.content('primaryDomain').trim());
        args.set('otherDomains', this.content('otherDomains').split(/[\n,]+/)
          .map((domain: string): string => domain.trim()).filter((domain: string): boolean => domain.length > 0)
          .join('\n'));
      }
      if (this.operation === 'upload') {
        const type = this.content('type');
        args.set('type', type === 'device' ? 'paste' : type);
        if (type === 'local') {
          args.delete('certificate');
          args.delete('privateKey');
        } else {
          args.delete('certificatePath');
          args.delete('privateKeyPath');
          const certificateKey = type === 'device' ? 'certificatePem' : 'certificate';
          const privateKey = type === 'device' ? 'privateKeyPem' : 'privateKey';
          args.set('certificate', this.content(certificateKey).trim());
          args.set('privateKey', this.content(privateKey).trim());
        }
        args.delete('certificatePem');
        args.delete('privateKeyPem');
        args.delete('certificateFileName');
        args.delete('privateKeyFileName');
      }
      if (this.operation === 'apply') {
        args.set('nameservers', this.content('nameservers').split(/[\n,]+/)
          .map((server: string): string => server.trim()).filter((server: string): boolean => server.length > 0));
      }
      const reply = await this.bridge.invoke<Map<string, Object | null>>('performNativeWebsiteSslAction', args);
      if (this.operation === 'resolve') {
        this.dnsRecords = reply.get('dnsRecords') as Map<string, Object | null>[];
        return;
      }
      this.errorMessage = reply.get('error') as string | null ?? '';
      if (this.errorMessage.length === 0) {
        this.getUIContext().getPromptAction().showToast({ message: this.text('commonOperationSuccess') });
        this.onSaved();
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.saving = false;
    }
  }

  @Builder
  private issueFields() {
    HarmonySslTextField({ label: this.text('websitesSslPrimaryDomain'), currentText: this.content('primaryDomain'),
      onTextChanged: (content: string): void => { this.draft.set('primaryDomain', content); } })
    if (!this.checked('isIp')) {
      HarmonySslTextField({ label: this.text('websitesSslOtherDomainsLabel'), currentText: this.content('otherDomains'), multiline: true,
        onTextChanged: (content: string): void => { this.draft.set('otherDomains', content); } })
    }
    HarmonySslSelectField({ label: this.text('websitesSslAcmeAccountIdLabel'),
      choices: this.accountOptions(this.availableAcmeAccounts(), 'email'),
      selectedText: this.selectedAccount(this.availableAcmeAccounts(), 'acmeAccountId', 'email'),
      onSelected: (index: number): void => { this.chooseAcmeAccount(index); } })
    HarmonySslSelectField({ label: this.text('websitesSslProviderLabel'), choices: this.options(
      this.providers.map((provider: string): string => this.providerLabel(provider))),
      selectedText: this.providerLabel(this.content('provider')), editable: !this.checked('isIp'),
      onSelected: (index: number): void => { this.draft.set('provider', this.providers[index]); } })
    if (this.content('provider') === 'dnsAccount') {
      HarmonySslSelectField({ label: this.text('websiteDnsAccount'), choices: this.accountOptions(this.dnsAccounts, 'name'),
        selectedText: this.selectedAccount(this.dnsAccounts, 'dnsAccountId', 'name'),
        onSelected: (index: number): void => { this.draft.set('dnsAccountId', this.dnsAccounts[index].get('id') as number); } })
    }
    HarmonySslSelectField({ label: this.text('websitesSslAccountsKeyTypeLabel'), choices: this.options(this.keyTypes),
      selectedText: this.content('keyType'), editable: this.operation === 'create',
      onSelected: (index: number): void => { this.draft.set('keyType', this.keyTypes[index]); } })
    HarmonySslTextField({ label: this.text('websitesSslDescriptionLabel'), currentText: this.content('description'),
      onTextChanged: (content: string): void => { this.draft.set('description', content); } })
    if (this.content('provider') !== 'dnsManual') {
      HarmonySslToggleField({ label: this.text('websitesSslAutoRenew'), checked: this.checked('autoRenew'),
        onCheckedChanged: (checked: boolean): void => { this.draft.set('autoRenew', checked); } })
    }
    if (this.operation === 'create') {
      HarmonySslToggleField({ label: this.text('websitesSslApplyAction'), checked: this.checked('apply'),
        onCheckedChanged: (checked: boolean): void => { this.draft.set('apply', checked); } })
      HarmonySslToggleField({ label: this.text('websitesSslIsIp'), checked: this.checked('isIp'),
        onCheckedChanged: (checked: boolean): void => {
          this.draft.set('isIp', checked);
          if (checked) {
            this.draft.set('provider', 'http');
            this.draft.delete('otherDomains');
            const account = this.acmeAccounts.find((item: Map<string, Object | null>): boolean =>
              item.get('type') === 'letsencrypt');
            this.draft.set('acmeAccountId', account?.get('id') ?? null);
          } else if (this.content('provider') === 'http') {
            this.draft.set('provider', 'dnsAccount');
          }
        } })
    }
  }

  @Builder
  private deploymentFields() {
    HarmonySslTextField({ label: 'Nameserver 1', currentText: this.content('nameserver1'),
      onTextChanged: (content: string): void => { this.draft.set('nameserver1', content); } })
    HarmonySslTextField({ label: 'Nameserver 2', currentText: this.content('nameserver2'),
      onTextChanged: (content: string): void => { this.draft.set('nameserver2', content); } })
    HarmonySslToggleField({ label: this.text('websiteSslDisableCname'), checked: this.checked('disableCNAME'),
      onCheckedChanged: (checked: boolean): void => { this.draft.set('disableCNAME', checked); } })
    HarmonySslToggleField({ label: this.text('websitesSslSkipDnsCheckLabel'), checked: this.checked('skipDNS'),
      onCheckedChanged: (checked: boolean): void => { this.draft.set('skipDNS', checked); } })
    HarmonySslToggleField({ label: this.text('websiteSslPushDirectory'), checked: this.checked('pushDir'),
      onCheckedChanged: (checked: boolean): void => { this.draft.set('pushDir', checked); } })
    if (this.checked('pushDir')) {
      HarmonySslTextField({ label: this.text('filesPath'), currentText: this.content('dir'), multiline: true,
        onTextChanged: (content: string): void => { this.draft.set('dir', content); } })
    }
    HarmonySslToggleField({ label: this.text('websiteSslRunScript'), checked: this.checked('execShell'),
      onCheckedChanged: (checked: boolean): void => { this.draft.set('execShell', checked); } })
    if (this.checked('execShell')) {
      HarmonySslTextField({ label: 'Shell', currentText: this.content('shell'), multiline: true,
        onTextChanged: (content: string): void => { this.draft.set('shell', content); } })
    }
    HarmonySslToggleField({ label: this.text('websiteSslPushNodes'), checked: this.checked('pushNode'),
      onCheckedChanged: (checked: boolean): void => { this.draft.set('pushNode', checked); } })
    if (this.checked('pushNode')) {
      HarmonySslTextField({ label: this.text('websiteSslNodeIds'), currentText: this.content('nodes'),
        onTextChanged: (content: string): void => { this.draft.set('nodes', content); } })
    }
  }

  @Builder
  private uploadFields() {
    HarmonySslSelectField({ label: this.text('websitesSslUploadTypeLabel'),
      choices: this.options(this.uploadTypes.map((type: string): string => this.uploadTypeLabel(type))),
      selectedText: this.uploadTypeLabel(this.content('type')),
      onSelected: (index: number): void => { this.draft.set('type', this.uploadTypes[index]); } })
    if (this.content('type') === 'paste') {
      HarmonySslTextField({ label: this.text('websitesSslCertificateLabel'), currentText: this.content('certificate'), multiline: true,
        onTextChanged: (content: string): void => { this.draft.set('certificate', content); } })
      HarmonySslTextField({ label: this.text('websitesSslPrivateKeyLabel'), currentText: this.content('privateKey'), multiline: true,
        onTextChanged: (content: string): void => { this.draft.set('privateKey', content); } })
    } else if (this.content('type') === 'local') {
      HarmonySslTextField({ label: this.text('websitesSslCertificatePathLabel'), currentText: this.content('certificatePath'),
        onTextChanged: (content: string): void => { this.draft.set('certificatePath', content); } })
      HarmonySslTextField({ label: this.text('websitesSslPrivateKeyPathLabel'), currentText: this.content('privateKeyPath'),
        onTextChanged: (content: string): void => { this.draft.set('privateKeyPath', content); } })
    } else {
      Row({ space: 12 }) {
        Text(this.text('websitesSslCertificatePathLabel')).layoutWeight(1).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button(this.text('filesSelectPath')).height(48).enabled(!this.saving && !this.fileLoading)
          .onClick((): void => { this.pickFile('certificate'); })
      }.width('100%')
      Text(this.content('certificateFileName')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(2).width('100%')
      Row({ space: 12 }) {
        Text(this.text('websitesSslPrivateKeyPathLabel')).layoutWeight(1).maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button(this.text('filesSelectPath')).height(48).enabled(!this.saving && !this.fileLoading)
          .onClick((): void => { this.pickFile('privateKey'); })
      }.width('100%')
      Text(this.content('privateKeyFileName')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .maxLines(2).width('100%')
    }
    HarmonySslTextField({ label: this.text('websitesSslDescriptionLabel'), currentText: this.content('description'),
      onTextChanged: (content: string): void => { this.draft.set('description', content); } })
  }

  private async pickFile(kind: string): Promise<void> {
    this.fileLoading = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('kind', kind);
      const selected = await this.bridge.invoke<Map<string, Object | null> | null>('pickNativeWebsiteSslFile', args);
      if (selected !== null) {
        this.draft.set(kind === 'certificate' ? 'certificateFileName' : 'privateKeyFileName', selected.get('name') as string);
        this.draft.set(kind === 'certificate' ? 'certificatePem' : 'privateKeyPem', selected.get('pem') as string);
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.fileLoading = false;
    }
  }

  @Builder
  private records() {
    ForEach(this.dnsRecords, (record: Map<string, Object | null>) => {
      Column({ space: 6 }) {
        Text(record.get('domain') as string).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
        if ((record.get('err') as string).length > 0) {
          Text(record.get('err') as string).fontSize(14).width('100%')
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        } else {
          Text(record.get('resolve') as string).fontSize(14).width('100%').copyOption(CopyOptions.LocalDevice)
          Text(record.get('value') as string).fontSize(14).width('100%').copyOption(CopyOptions.LocalDevice)
        }
      }.width('100%').padding({ top: 8, bottom: 8 })
    }, (record: Map<string, Object | null>): string => record.get('domain') as string)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.operation === 'upload') {
          this.uploadFields()
        } else if (this.operation === 'apply') {
          Text(this.content('primaryDomain')).fontSize(20).fontWeight(FontWeight.Medium).width('100%')
          HarmonySslToggleField({ label: this.text('websitesSslDisableLogLabel'), checked: this.checked('disableLog'),
            onCheckedChanged: (checked: boolean): void => { this.draft.set('disableLog', checked); } })
          HarmonySslToggleField({ label: this.text('websitesSslSkipDnsCheckLabel'), checked: this.checked('skipDNSCheck'),
            onCheckedChanged: (checked: boolean): void => { this.draft.set('skipDNSCheck', checked); } })
          HarmonySslTextField({ label: this.text('websitesSslNameserversLabel'), currentText: this.content('nameservers'), multiline: true,
            onTextChanged: (content: string): void => { this.draft.set('nameservers', content); } })
        } else if (this.operation === 'resolve') {
          HarmonySslSelectField({ label: this.text('websitesSslAcmeAccountIdLabel'),
            choices: this.accountOptions(this.acmeAccounts, 'email'),
            selectedText: this.selectedAccount(this.acmeAccounts, 'acmeAccountId', 'email'),
            onSelected: (index: number): void => { this.draft.set('acmeAccountId', this.acmeAccounts[index].get('id') as number); } })
          this.records()
        } else {
          this.issueFields()
          this.deploymentFields()
        }
        if (this.fileLoading) {
          LoadingProgress().width(32).height(32)
        }
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontSize(14).fontColor('#D94838').width('100%')
        }
        Button(this.text(this.operation === 'resolve' ? 'websitesSslResolveAction' : 'commonSave'))
          .width('100%').height(48).enabled(!this.saving && !this.fileLoading)
          .onClick((): void => { this.submit(); })
      }.padding(16).margin({ left: 16, right: 16, top: 16, bottom: 24 })
      .backgroundColor($r('sys.color.ohos_id_color_foreground_contrary')).borderRadius(16)
    }.width('100%').height('100%').align(Alignment.TopStart)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
