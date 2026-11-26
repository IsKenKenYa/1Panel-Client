import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { HarmonyComputeField, HarmonyComputeToggle, computeWrite } from './HarmonyComputeControls';

@Observed
class HarmonyAlertWebhookPair {
  rowId: number;
  key: string = '';
  content: string = '';
  uid: string = '';
  secret: boolean = false;
  configured: boolean = false;
  masked: string = '';
  action: string = 'replace';

  constructor(rowId: number) { this.rowId = rowId; }
}

@Component
struct HarmonyAlertWebhookPairEditor {
  @ObjectLink pair: HarmonyAlertWebhookPair;
  header: boolean = false;
  onChanged: () => void = (): void => {};
  onRemove: () => void = (): void => {};
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        TextInput({ text: this.pair.key, placeholder: this.bridge.text(this.header ? 'alertChannelCustomHeaderKeyLabel' : 'commonName') })
          .height(48).layoutWeight(1)
          .onChange((content: string): void => { this.pair.key = content; this.onChanged(); })
        Button() { SymbolGlyph($r('sys.symbol.trash')).fontSize(20) }
          .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .accessibilityText(this.bridge.text('commonDelete')).onClick(this.onRemove)
      }.width('100%')
      if (this.header) {
        Row({ space: 8 }) {
          Text(this.bridge.text('alertChannelPasswordLabel')).layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.pair.secret })
            .accessibilityText(this.bridge.text('alertChannelPasswordLabel'))
            .onChange((enabled: boolean): void => {
              this.pair.secret = enabled;
              this.pair.action = enabled && this.pair.configured ? 'keep' : 'replace';
              this.pair.content = '';
              this.onChanged();
            })
        }.width('100%').constraintSize({ minHeight: 48 })
        if (this.pair.secret && (this.pair.configured || this.pair.action === 'clear')) {
          Select([{ value: this.bridge.text('alertChannelPasswordKeep') },
            { value: this.bridge.text('alertChannelPasswordReplace') },
            { value: this.bridge.text('alertChannelPasswordClear') }])
            .selected(['keep', 'replace', 'clear'].indexOf(this.pair.action))
            .onSelect((index: number): void => {
              this.pair.action = ['keep', 'replace', 'clear'][index];
              this.pair.content = '';
              this.onChanged();
            }).height(48).width('100%')
        }
      }
      if (this.pair.action === 'replace') {
        TextInput({ text: this.pair.content, placeholder: this.bridge.text('alertChannelCustomHeaderValueLabel') })
          .type(this.pair.secret ? InputType.Password : InputType.Normal).height(48).width('100%')
          .onChange((content: string): void => { this.pair.content = content; this.onChanged(); })
      } else if (this.pair.action === 'keep' && this.pair.masked.length > 0) {
        Text(this.pair.masked).fontColor($r('sys.color.font_secondary'))
      }
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}

@Component
export struct HarmonyAlertPage {
  @State private selectedTab: number = 0;
  @State private rules: Map<string, Object | null>[] = [];
  @State private logs: Map<string, Object | null>[] = [];
  @State private channels: Map<string, Object | null>[] = [];
  @State private selected: Map<string, Object | null> = new Map<string, Object | null>();
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private editing: boolean = false;
  @State private ruleEnabled: boolean = true;
  @State private titleText: string = '';
  @State private typeText: string = 'cpu';
  @State private cycleText: string = '30';
  @State private countText: string = '1';
  @State private intervalText: string = '1';
  @State private sendCountText: string = '1';
  @State private methods: string[] = [];
  @State private ruleTarget: string = '';
  @State private triggerMode: string = 'failed';
  @State private advancedParamsText: string = '';
  @State private targets: Map<string, Object | null>[] = [];
  @State private targetsLoading: boolean = false;
  @State private targetsError: string = '';
  @State @Watch('invalidateChannelTest') private channelName: string = '';
  @State private channelType: string = 'email';
  @State private senderText: string = '';
  @State private usernameText: string = '';
  @State private passwordText: string = '';
  @State private hostText: string = '';
  @State private portText: string = '465';
  @State private recipientText: string = '';
  @State private encryptionText: string = 'NONE';
  @State @Watch('invalidateChannelTest') private webhookText: string = '';
  @State @Watch('invalidateChannelTest') private webhookBodyText: string = '';
  @State private webhookPreset: string = 'genericJson';
  @State private webhookBodyType: string = 'json';
  @State private webhookUrlAction: string = 'replace';
  @State private webhookUrlConfigured: boolean = false;
  @State private webhookUrlMasked: string = '';
  @State private webhookHeaders: HarmonyAlertWebhookPair[] = [];
  @State private webhookFields: HarmonyAlertWebhookPair[] = [];
  private channelRevision: string = '';
  private webhookTemplates: Map<string, string> = new Map<string, string>();
  private webhookPairId: number = 0;
  @State private channelTestPassed: boolean = false;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private pathStack: NavPathStack = new NavPathStack();
  private tabs: string[] = ['alertTabRules', 'alertTabLogs', 'alertTabChannels'];
  private channelTypes: string[] = ['email', 'bark', 'weCom', 'dingTalk', 'feiShu', 'custom'];
  private channelLabels: string[] = ['alertChannelTypeEmail', 'alertChannelTypeBark', 'alertChannelTypeWeCom',
    'alertChannelTypeDingTalk', 'alertChannelTypeFeiShu', 'alertChannelTypeCustom'];
  private ruleTypes: string[] = ['panelPwdEndTime', 'panelLogin', 'sshLogin', 'ssl', 'siteEndTime', 'cpu',
    'memory', 'disk', 'load', 'clams', 'cronJob', 'panelUpdate', 'licenseException', 'nodeException'];
  private ruleLabels: string[] = ['alertRuleTypePasswordExpiry', 'alertRuleTypePanelLogin', 'alertRuleTypeSshLogin',
    'alertRuleTypeSsl', 'alertRuleTypeSiteExpiry', 'alertRuleTypeCpu', 'alertRuleTypeMemory', 'alertRuleTypeDisk',
    'alertRuleTypeLoad', 'alertRuleTypeClams', 'alertRuleTypeCronJob', 'alertRuleTypePanelUpdate',
    'alertRuleTypeLicenseException', 'alertRuleTypeNodeException'];
  private cronTypes: string[] = ['shell', 'app', 'website', 'database', 'directory', 'log', 'snapshot', 'curl',
    'cutWebsiteLog', 'clean', 'ntp', 'syncIpGroup', 'cleanLog'];
  private webhookPresets: string[] = ['genericJson', 'slack', 'discord', 'teamsWorkflows', 'custom'];
  private webhookPresetLabels: string[] = ['alertChannelCustomPresetGeneric', 'alertChannelCustomPresetSlack',
    'alertChannelCustomPresetDiscord', 'alertChannelCustomPresetTeams', 'alertChannelCustomPresetCustom'];
  private webhookBodyTypes: string[] = ['json', 'form', 'text'];
  private webhookBodyLabels: string[] = ['alertChannelCustomBodyJson', 'alertChannelCustomBodyForm', 'alertChannelCustomBodyText'];

  aboutToAppear(): void { this.load(); }
  private text(key: string): string { return this.bridge.text(key); }
  private value(item: Map<string, Object | null>, key: string): string {
    const value = item.get(key);
    return value === undefined || value === null ? '' : `${value}`;
  }

  private async load(): Promise<void> {
    this.loading = true; this.errorMessage = '';
    try {
      const results = await Promise.all([
        this.bridge.invoke<Map<string, Object | null>>('getAlertRules', new Map<string, Object | null>([['page', 1], ['pageSize', 50]])),
        this.bridge.invoke<Map<string, Object | null>>('getAlertLogs', new Map<string, Object | null>([['page', 1], ['pageSize', 50]])),
        this.bridge.invoke<Map<string, Object | null>[]>('getAlertChannels'),
      ]);
      this.rules = (results[0] as Map<string, Object | null>).get('items') as Map<string, Object | null>[];
      this.logs = (results[1] as Map<string, Object | null>).get('items') as Map<string, Object | null>[];
      this.channels = results[2] as Map<string, Object | null>[];
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private async mutate(method: string, args: Map<string, Object | null>, closeForm: boolean = false): Promise<void> {
    this.loading = true; this.errorMessage = '';
    try {
      await computeWrite(method, args);
      if (closeForm) this.pathStack.pop();
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonOperationSuccess') });
      await this.load();
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }

  private createRule(): void {
    this.selected = new Map<string, Object | null>();
    this.editing = false;
    this.titleText = '';
    this.sendCountText = '1';
    this.ruleEnabled = true;
    const enabled = this.channels.find((channel: Map<string, Object | null>): boolean => channel.get('status') === 'Enable');
    this.methods = enabled === undefined ? [] : [this.value(enabled, 'id')];
    this.changeType('cpu');
    this.pathStack.pushPath({ name: 'form' });
  }

  private editRule(rule: Map<string, Object | null>): void {
    this.selected = rule;
    this.editing = true;
    const ruleType = this.value(rule, 'type');
    this.typeText = this.cronTypes.includes(ruleType) ? 'cronJob' : ruleType;
    this.titleText = this.value(rule, 'title');
    this.cycleText = this.value(rule, 'cycle');
    this.countText = this.value(rule, 'count');
    this.intervalText = this.cycleText;
    this.sendCountText = this.value(rule, 'sendCount');
    this.advancedParamsText = this.value(rule, 'advancedParams');
    this.triggerMode = this.value(rule, 'alertTriggerMode') || 'failed';
    if (this.typeText === 'cronJob' && this.advancedParamsText.length > 0) {
      try {
        const params = JSON.parse(this.advancedParamsText) as Record<string, string>;
        this.triggerMode = params['alertTriggerMode'] ?? this.triggerMode;
      } catch (error) {
        this.triggerMode = 'failed';
      }
    }
    const legacyMethods: Map<string, string> = new Map<string, string>([['mail', 'email'], ['webhook', 'custom']]);
    this.methods = this.value(rule, 'method').split(',').filter((method: string): boolean => method.length > 0)
      .map((method: string): string => {
        const channel = this.channels.find((item: Map<string, Object | null>): boolean =>
          this.value(item, 'type') === (legacyMethods.get(method) ?? method));
        return channel === undefined ? method : this.value(channel, 'id');
      });
    this.ruleEnabled = this.value(rule, 'status') === 'Enable';
    this.ruleTarget = this.value(rule, 'project');
    this.loadTargets();
    this.pathStack.pushPath({ name: 'form' });
  }

  private changeType(type: string): void {
    this.typeText = type;
    this.ruleTarget = this.allTargetsLabel().length > 0 ? 'all' : '';
    this.triggerMode = 'failed';
    this.advancedParamsText = '';
    this.cycleText = type === 'disk' ? '2' : (this.isLoginRule() ? '30' : '15');
    this.countText = this.isLoginRule() ? '3' : '80';
    this.intervalText = '5';
    this.loadTargets();
  }

  private needsCycleDays(): boolean { return ['panelPwdEndTime', 'ssl', 'siteEndTime'].includes(this.typeText); }
  private needsInterval(): boolean { return ['cpu', 'memory', 'load'].includes(this.typeText); }
  private isLoginRule(): boolean { return ['panelLogin', 'sshLogin'].includes(this.typeText); }

  private targetLabel(): string {
    switch (this.typeText) {
      case 'disk': return 'alertRuleDiskTargetsLabel';
      case 'ssl': return 'alertRuleCertificateTargetsLabel';
      case 'siteEndTime': return 'alertRuleWebsiteTargetsLabel';
      case 'clams': return 'alertRuleClamTargetLabel';
      case 'cronJob': return 'alertRuleCronjobTaskLabel';
      default: return '';
    }
  }

  private allTargetsLabel(): string {
    switch (this.typeText) {
      case 'disk': return 'alertRuleDiskAll';
      case 'ssl': return 'alertRuleCertificateAll';
      case 'siteEndTime': return 'alertRuleWebsiteAll';
      default: return '';
    }
  }

  private async loadTargets(): Promise<void> {
    const type = this.typeText;
    this.targets = [];
    this.targetsError = '';
    this.targetsLoading = this.targetLabel().length > 0;
    if (!this.targetsLoading) return;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>[]>('harmonyCompute/getAlertRuleTargets',
        new Map<string, Object | null>([['type', type]]));
      if (this.typeText !== type) return;
      const rows = type === 'cronJob'
        ? result.filter((item: Map<string, Object | null>): boolean => this.cronTypes.includes(this.value(item, 'type')))
        : result;
      const allLabel = this.allTargetsLabel();
      if (allLabel.length > 0) rows.unshift(new Map<string, Object | null>([['id', 'all'], ['label', this.text(allLabel)]]));
      if (this.ruleTarget.length > 0 && !rows.some((item: Map<string, Object | null>): boolean => item.get('id') === this.ruleTarget)) {
        rows.unshift(new Map<string, Object | null>([['id', this.ruleTarget],
          ['label', this.value(this.selected, 'taskName') || this.ruleTarget], ['type', this.value(this.selected, 'type')]]));
      }
      this.targets = rows;
      if (this.ruleTarget.length === 0 && rows.length > 0) this.ruleTarget = this.value(rows[0], 'id');
    } catch (error) {
      if (this.typeText === type) this.targetsError = (error as Error).message;
    } finally {
      if (this.typeText === type) this.targetsLoading = false;
    }
  }

  private selectedTarget(): Map<string, Object | null> | undefined {
    return this.targets.find((target: Map<string, Object | null>): boolean => target.get('id') === this.ruleTarget);
  }

  private async saveRule(): Promise<void> {
    const args = new Map<string, Object | null>();
    if (this.editing) args.set('id', this.selected.get('id') as number);
    args.set('title', this.titleText.trim());
    args.set('type', this.typeText);
    args.set('project', this.ruleTarget || 'all');
    if (this.sendCountText.length > 0) args.set('sendCount', Number(this.sendCountText));
    args.set('methods', this.methods);
    args.set('status', this.ruleEnabled ? 'Enable' : 'Disable');
    if (this.typeText === 'cronJob') {
      args.set('type', this.selectedTarget()?.get('type') as string);
      args.set('alertTriggerMode', this.triggerMode);
    }
    if (this.needsInterval()) args.set('cycle', Number(this.intervalText));
    if (this.cycleText.length > 0 && (this.needsCycleDays() || this.isLoginRule() || this.typeText === 'disk')) {
      args.set('cycle', Number(this.cycleText));
    }
    if (this.countText.length > 0 && (this.needsInterval() || this.isLoginRule() || this.typeText === 'disk')) {
      args.set('count', Number(this.countText));
    }
    args.set('advancedParams', this.advancedParamsText.trim());
    await this.mutate('harmonyCompute/saveAlertRule', args, true);
  }

  private removeRule(rule: Map<string, Object | null>): void {
    this.getUIContext().showAlertDialog({ title: this.text('commonDelete'), message: this.value(rule, 'title'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => {
        const args = new Map<string, Object | null>(); args.set('id', rule.get('id') as number); this.mutate('deleteAlertRule', args);
      } },
    });
  }

  private channelArguments(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    if (this.selected.has('id')) {
      args.set('id', this.selected.get('id') as number);
      if (this.channelRevision.length > 0) args.set('revision', this.channelRevision);
    }
    args.set('title', this.channelName);
    args.set('type', this.channelType);
    if (this.selected.has('status')) args.set('status', this.selected.get('status') as string);
    if (this.channelType === 'email') {
      args.set('sender', this.senderText);
      args.set('userName', this.usernameText);
      args.set('host', this.hostText);
      args.set('port', Number(this.portText));
      args.set('encryption', this.encryptionText);
      args.set('recipient', this.recipientText);
      if (this.passwordText.length > 0) {
        args.set('passwordAction', 'replace');
        args.set('password', this.passwordText);
      } else if (this.selected.has('id')) {
        args.set('passwordAction', 'keep');
      }
    } else {
      args.set('webhookUrl', this.webhookText);
      if (this.channelType === 'custom') {
        args.set('urlAction', this.webhookUrlAction);
        args.set('preset', this.webhookPreset);
        args.set('bodyType', this.webhookBodyType);
        args.set('template', this.webhookBodyText);
        args.set('formPairs', this.webhookFields.map((pair: HarmonyAlertWebhookPair): Map<string, Object | null> =>
          new Map<string, Object | null>([['key', pair.key.trim()], ['value', pair.content]])));
        args.set('headers', this.webhookHeaders.map((pair: HarmonyAlertWebhookPair): Map<string, Object | null> => {
          const header = new Map<string, Object | null>([['key', pair.key.trim()], ['secret', pair.secret], ['action', pair.action]]);
          if (pair.uid.length > 0) header.set('uid', pair.uid);
          if (pair.action === 'replace') header.set('value', pair.content);
          return header;
        }));
      }
    }
    return args;
  }

  private async saveChannel(): Promise<void> {
    await this.mutate(this.channelType === 'custom' ? 'harmonyCompute/saveAlertWebhook' : 'saveAlertChannel',
      this.channelArguments(), true);
  }

  private invalidateChannelTest(): void {
    if (this.channelTestPassed) this.errorMessage = '';
    this.channelTestPassed = false;
  }

  private replaceWebhookPreset(preset: string): void {
    this.webhookPreset = preset;
    const template = this.webhookTemplates.get(preset);
    if (template !== undefined) {
      this.webhookBodyType = 'json';
      this.webhookBodyText = template;
      this.webhookFields = [];
    }
    this.invalidateChannelTest();
  }

  private addWebhookPair(header: boolean): void {
    const pair = new HarmonyAlertWebhookPair(++this.webhookPairId);
    if (header) this.webhookHeaders.push(pair);
    else this.webhookFields.push(pair);
    this.invalidateChannelTest();
  }

  private removeWebhookPair(header: boolean, rowId: number): void {
    if (header) this.webhookHeaders = this.webhookHeaders.filter((pair: HarmonyAlertWebhookPair): boolean => pair.rowId !== rowId);
    else this.webhookFields = this.webhookFields.filter((pair: HarmonyAlertWebhookPair): boolean => pair.rowId !== rowId);
    this.invalidateChannelTest();
  }

  private readWebhookPair(row: Map<string, Object | null>): HarmonyAlertWebhookPair {
    const pair = new HarmonyAlertWebhookPair(++this.webhookPairId);
    pair.key = this.value(row, 'key');
    pair.uid = this.value(row, 'uid');
    pair.secret = row.get('secret') === true;
    pair.configured = row.get('configured') === true;
    pair.masked = this.value(row, 'masked');
    pair.content = pair.secret ? '' : this.value(row, 'value');
    pair.action = pair.secret ? (pair.configured ? 'keep' : 'clear') : 'replace';
    return pair;
  }

  private async testChannel(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const method = this.channelType === 'custom' ? 'harmonyCompute/testAlertWebhook' : 'testAlertChannel';
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, this.channelArguments());
      this.channelTestPassed = result.get('success') === true;
      this.errorMessage = this.value(result, 'message') || this.value(result, 'error') ||
        this.text(this.channelTestPassed ? 'alertChannelTestSuccess' : 'alertChannelTestFailed');
    } catch (error) {
      this.channelTestPassed = false;
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async openChannel(channel?: Map<string, Object | null>): Promise<void> {
    this.selected = channel ?? new Map<string, Object | null>();
    this.channelName = this.value(this.selected, 'title');
    this.channelType = this.value(this.selected, 'type') || 'email';
    this.passwordText = '';
    this.channelRevision = '';
    this.errorMessage = '';
    this.channelTestPassed = false;
    try {
      let fields = new Map<string, Object | null>();
      if (channel !== undefined) {
        const args = new Map<string, Object | null>();
        args.set('id', channel.get('id') as number);
        const result = await this.bridge.invoke<Map<string, Object | null>>('getNativeAlertChannelForm', args);
        fields = result.get('fields') as Map<string, Object | null>;
        this.channelRevision = this.value(result, 'updatedAt');
        this.channelName = this.value(fields, 'displayName') || this.channelName;
      }
      this.senderText = this.value(fields, 'sender');
      this.usernameText = this.value(fields, 'userName');
      this.hostText = this.value(fields, 'host');
      this.portText = this.value(fields, 'port') || '465';
      this.recipientText = this.value(fields, 'recipient');
      this.encryptionText = this.value(fields, 'encryption') || 'NONE';
      if (channel === undefined || this.channelType === 'custom') {
        this.webhookTemplates = await this.bridge.invoke<Map<string, string>>('harmonyCompute/getAlertWebhookPresets');
        const url = fields.get('url');
        this.webhookUrlConfigured = url instanceof Map && url.get('configured') === true;
        this.webhookUrlMasked = url instanceof Map ? `${url.get('masked') ?? ''}` : '';
        this.webhookUrlAction = this.webhookUrlConfigured ? 'keep' : 'replace';
        this.webhookPreset = this.value(fields, 'preset') || 'genericJson';
        const body = fields.get('body') as Map<string, Object | null> | undefined;
        this.webhookBodyType = body === undefined ? 'json' : this.value(body, 'type');
        this.webhookBodyText = body === undefined ? this.webhookTemplates.get(this.webhookPreset) ?? '' : this.value(body, 'template');
        const headers = (fields.get('headers') as Map<string, Object | null>[] | undefined) ?? [];
        const formFields = (body?.get('fields') as Map<string, Object | null>[] | undefined) ?? [];
        this.webhookHeaders = headers.map((entry: Map<string, Object | null>): HarmonyAlertWebhookPair => this.readWebhookPair(entry));
        this.webhookFields = formFields.map((entry: Map<string, Object | null>): HarmonyAlertWebhookPair => this.readWebhookPair(entry));
      }
      this.webhookText = typeof fields.get('url') === 'string' ? this.value(fields, 'url') : '';
      this.pathStack.pushPath({ name: 'form' });
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private menus(): NavigationMenuItem[] {
    const items: NavigationMenuItem[] = [
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')), action: (): void => { this.load(); } },
    ];
    if (this.selectedTab === 0) items.push({ value: this.text('commonCreate'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')), action: (): void => { this.createRule(); } });
    if (this.selectedTab === 1) items.push({ value: this.text('commonClear'), action: (): void => { this.clearLogs(); } });
    if (this.selectedTab === 2) items.push({ value: this.text('alertChannelCreateAction'), action: (): void => { this.openChannel(); } });
    return items;
  }

  private clearLogs(): void {
    this.getUIContext().showAlertDialog({ title: this.text('alertLogCleanAction'), message: this.text('alertLogCleanConfirm'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.mutate('cleanAlertLogs', new Map<string, Object | null>()); } },
    });
  }

  @Builder
  private ruleRow(rule: Map<string, Object | null>) {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text(this.value(rule, 'title')).fontSize(16).fontWeight(FontWeight.Medium)
        Text(`${this.value(rule, 'type')} · ${this.value(rule, 'status')} · ${this.value(rule, 'cycle')}`).fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Button() { SymbolGlyph($r('sys.symbol.square_and_pencil')).fontSize(20) }.width(48).height(48)
        .accessibilityText(this.text('commonEdit')).onClick((): void => { this.editRule(rule); })
      Button() { SymbolGlyph($r('sys.symbol.trash')).fontSize(20) }.width(48).height(48)
        .accessibilityText(this.text('commonDelete')).onClick((): void => { this.removeRule(rule); })
    }.padding(12).width('100%').constraintSize({ minHeight: 68 })
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
  }

  @Builder
  private body() {
    Column({ space: 12 }) {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.tabs, (key: string, index: number): void => {
            Button(this.text(key), { buttonStyle: this.selectedTab === index ? ButtonStyleMode.EMPHASIZED : ButtonStyleMode.TEXTUAL })
              .height(48).padding({ left: 16, right: 16 }).onClick((): void => { this.selectedTab = index; })
          }, (key: string): string => key)
        }
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      if (this.loading) LoadingProgress().width(40).height(40)
      if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14)
      List({ space: 10 }) {
        if (this.selectedTab === 0) ForEach(this.rules, (rule: Map<string, Object | null>): void => {
          ListItem() { this.ruleRow(rule) }
        }, (rule: Map<string, Object | null>): string => `${rule.get('id')}`)
        else if (this.selectedTab === 1) ForEach(this.logs, (log: Map<string, Object | null>): void => {
          ListItem() {
            Column({ space: 4 }) {
              Text(this.value(log, 'title')).fontSize(16).fontWeight(FontWeight.Medium)
              Text(`${this.value(log, 'status')} · ${this.value(log, 'createdAt')}`).fontSize(14)
              Text(this.value(log, 'message')).fontSize(14).fontColor($r('sys.color.font_secondary'))
            }.padding(14).width('100%').alignItems(HorizontalAlign.Start)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }
        }, (log: Map<string, Object | null>): string => `${log.get('id')}`)
        else ForEach(this.channels, (channel: Map<string, Object | null>): void => {
          ListItem() {
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text(this.value(channel, 'title')).fontSize(16).fontWeight(FontWeight.Medium)
                Text(`${this.value(channel, 'type')} · ${this.value(channel, 'status')}`).fontSize(14).fontColor($r('sys.color.font_secondary'))
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Toggle({ type: ToggleType.Switch, isOn: channel.get('status') === 'Enable' })
                .onChange((enable: boolean): void => {
                  const args = new Map<string, Object | null>(); args.set('id', channel.get('id') as number); args.set('enable', enable); this.mutate('toggleAlertChannel', args);
                })
              Button() { SymbolGlyph($r('sys.symbol.square_and_pencil')).fontSize(20) }.width(48).height(48)
                .accessibilityText(this.text('commonEdit')).onClick((): void => { this.openChannel(channel); })
            }.padding(12).width('100%').constraintSize({ minHeight: 68 })
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
          }
        }, (channel: Map<string, Object | null>): string => `${channel.get('id')}`)
      }.layoutWeight(1).width('100%')
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private ruleTargets() {
    if (this.targetLabel().length > 0) {
      Text(this.text(this.targetLabel())).fontSize(14).width('100%')
      if (this.targetsLoading) {
        LoadingProgress().width(32).height(32)
      } else if (this.targetsError.length > 0) {
        Text(this.targetsError).fontSize(14)
        Button(this.text('commonRetry'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48)
          .onClick((): void => { this.loadTargets(); })
      } else if (this.targets.length > 0) {
        Select(this.targets.map((target: Map<string, Object | null>): SelectOption => ({ value: this.value(target, 'label') })))
          .selected(this.targets.findIndex((target: Map<string, Object | null>): boolean => target.get('id') === this.ruleTarget))
          .height(48).width('100%').accessibilityText(this.text(this.targetLabel()))
          .onSelect((index: number): void => { this.ruleTarget = this.value(this.targets[index], 'id'); })
      } else {
        Text(this.text('commonEmpty')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      }
    }
  }

  @Builder
  private webhookPairs(header: boolean) {
    Text(this.text(header ? 'alertChannelCustomHeadersLabel' : 'alertChannelCustomFormPairLabel')).fontSize(16)
    ForEach(header ? this.webhookHeaders : this.webhookFields, (pair: HarmonyAlertWebhookPair): void => {
      HarmonyAlertWebhookPairEditor({ pair: pair, header: header,
        onRemove: (): void => { this.removeWebhookPair(header, pair.rowId); },
        onChanged: (): void => { this.invalidateChannelTest(); } })
    }, (pair: HarmonyAlertWebhookPair): string => `${pair.rowId}`)
    Button(this.text(header ? 'alertChannelCustomAddHeaderAction' : 'alertChannelCustomAddPairAction'),
      { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).onClick((): void => { this.addWebhookPair(header); })
  }

  @Builder
  private customWebhook() {
    if (this.webhookUrlConfigured) {
      Text(this.text('alertChannelWebhookUrlLabel')).fontSize(14)
      Select([{ value: this.text('alertChannelPasswordKeep') }, { value: this.text('alertChannelPasswordReplace') },
        { value: this.text('alertChannelPasswordClear') }])
        .selected(['keep', 'replace', 'clear'].indexOf(this.webhookUrlAction)).height(48).width('100%')
        .onSelect((index: number): void => {
          this.webhookUrlAction = ['keep', 'replace', 'clear'][index];
          this.webhookText = '';
          this.invalidateChannelTest();
        })
      if (this.webhookUrlAction === 'keep' && this.webhookUrlMasked.length > 0) {
        Text(this.webhookUrlMasked).fontColor($r('sys.color.font_secondary'))
      }
    }
    if (this.webhookUrlAction === 'replace') {
      HarmonyComputeField({ labelKey: 'alertChannelWebhookUrlLabel', fieldText: this.webhookText, inputType: InputType.Password })
    }
    Text(this.text('alertChannelCustomPresetLabel')).fontSize(14)
    Select(this.webhookPresetLabels.map((key: string): SelectOption => ({ value: this.text(key) })))
      .selected(this.webhookPresets.indexOf(this.webhookPreset)).height(48).width('100%')
      .onSelect((index: number): void => { this.replaceWebhookPreset(this.webhookPresets[index]); })
    Text(this.text('alertChannelCustomBodyTypeLabel')).fontSize(14)
    Select(this.webhookBodyLabels.map((key: string): SelectOption => ({ value: this.text(key) })))
      .selected(this.webhookBodyTypes.indexOf(this.webhookBodyType)).height(48).width('100%')
      .onSelect((index: number): void => {
        this.webhookBodyType = this.webhookBodyTypes[index];
        this.invalidateChannelTest();
      })
    if (this.webhookBodyType === 'form') {
      this.webhookPairs(false)
    } else {
      Text(this.text('alertChannelCustomTemplateLabel')).fontSize(14)
      TextArea({ text: this.webhookBodyText }).height(144).width('100%')
        .accessibilityText(this.text('alertChannelCustomTemplateLabel'))
        .onChange((content: string): void => { this.webhookBodyText = content; })
    }
    this.webhookPairs(true)
  }

  @Builder
  private form() {
    Column({ space: 14 }) {
      if (this.selectedTab === 0) {
        Select(this.ruleLabels.map((key: string): SelectOption => ({ value: this.text(key) })))
          .selected(this.ruleTypes.indexOf(this.typeText)).height(48).width('100%')
          .onSelect((index: number): void => { this.changeType(this.ruleTypes[index]); })
        HarmonyComputeField({ labelKey: 'alertRuleTitleLabel', fieldText: this.titleText })
        this.ruleTargets()
        if (this.needsCycleDays()) {
          HarmonyComputeField({ labelKey: 'alertRuleCycleDaysLabel', fieldText: this.cycleText, inputType: InputType.Number })
        }
        if (this.isLoginRule()) {
          HarmonyComputeField({ labelKey: 'cronjobFormMinutesLabel', fieldText: this.cycleText, inputType: InputType.Number })
          TextArea({ text: this.advancedParamsText, placeholder: this.text('alertRuleAdvancedParamsLabel') })
            .height(96).width('100%').onChange((content: string): void => { this.advancedParamsText = content; })
        }
        if (this.needsInterval() || this.isLoginRule() || this.typeText === 'disk') {
          HarmonyComputeField({ labelKey: 'alertRuleThresholdLabel', fieldText: this.countText, inputType: InputType.Number })
        }
        if (this.typeText === 'disk') {
          Select([{ value: this.text('alertRuleThresholdUnitGb') }, { value: this.text('alertRuleThresholdUnitPercent') }])
            .selected(this.cycleText === '1' ? 0 : 1).height(48).width('100%')
            .onSelect((index: number): void => { this.cycleText = `${index + 1}`; })
        }
        if (this.needsInterval()) {
          Select([{ value: this.text('alertRuleIntervalMinute1') }, { value: this.text('alertRuleIntervalMinute5') },
            { value: this.text('alertRuleIntervalMinute15') }])
            .selected(['1', '5', '15'].indexOf(this.intervalText)).height(48).width('100%')
            .onSelect((index: number): void => { this.intervalText = ['1', '5', '15'][index]; })
        }
        if (this.typeText === 'cronJob') {
          Text(this.text('alertRuleCronjobTriggerModeLabel')).fontSize(14)
          Select([{ value: this.text('alertRuleCronjobTriggerFailed') }, { value: this.text('alertRuleCronjobTriggerSuccess') },
            { value: this.text('alertRuleCronjobTriggerBoth') }])
            .selected(['failed', 'success', 'both'].indexOf(this.triggerMode)).height(48).width('100%')
            .onSelect((index: number): void => { this.triggerMode = ['failed', 'success', 'both'][index]; })
        }
        HarmonyComputeField({ labelKey: 'alertRuleSendCountLabel', fieldText: this.sendCountText, inputType: InputType.Number })
        Text(this.text('alertRuleMethodsLabel')).fontSize(14).width('100%')
        if (this.channels.length === 0) Text(this.text('alertRuleMethodsEmpty')).fontSize(14).width('100%')
        ForEach(this.channels, (channel: Map<string, Object | null>): void => {
          Row({ space: 8 }) {
            Checkbox({ name: this.value(channel, 'id'), group: 'alert-channels' })
              .select(this.methods.includes(this.value(channel, 'id')))
              .enabled(channel.get('status') === 'Enable' || this.methods.includes(this.value(channel, 'id')))
              .accessibilityText(this.value(channel, 'title'))
              .onChange((checked: boolean): void => { this.selectMethod(this.value(channel, 'id'), checked); })
            Text(this.value(channel, 'title')).fontSize(16)
          }.constraintSize({ minHeight: 48 }).width('100%')
        }, (channel: Map<string, Object | null>): string => this.value(channel, 'id'))
        if (this.editing) HarmonyComputeToggle({ labelKey: 'commonStatus', selected: this.ruleEnabled })
        if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14).width('100%')
        Button(this.text('commonSave')).width('100%').height(48)
          .enabled(!this.loading && this.titleText.trim().length > 0 && this.methods.length > 0 &&
            (this.targetLabel().length === 0 || this.selectedTarget() !== undefined))
          .onClick((): void => { this.saveRule(); })
      } else {
        if (!this.selected.has('id')) {
          Select(this.channelLabels.map((key: string): SelectOption => ({ value: this.text(key) })))
            .selected(this.channelTypes.indexOf(this.channelType)).height(48).width('100%')
            .onSelect((index: number): void => { this.channelType = this.channelTypes[index]; this.channelTestPassed = false; })
        }
        HarmonyComputeField({ labelKey: 'alertChannelDisplayNameLabel', fieldText: this.channelName })
        if (this.channelType === 'email') {
          HarmonyComputeField({ labelKey: 'alertChannelSenderLabel', fieldText: this.senderText })
          HarmonyComputeField({ labelKey: 'alertChannelUsernameLabel', fieldText: this.usernameText })
          HarmonyComputeField({ labelKey: 'alertChannelPasswordLabel', fieldText: this.passwordText, inputType: InputType.Password })
          HarmonyComputeField({ labelKey: 'alertChannelHostLabel', fieldText: this.hostText })
          HarmonyComputeField({ labelKey: 'alertChannelPortLabel', fieldText: this.portText, inputType: InputType.Number })
          Select([{ value: this.text('alertChannelEncryptionNone') }, { value: 'SSL' }, { value: 'TLS' }])
            .selected(['NONE', 'SSL', 'TLS'].indexOf(this.encryptionText)).height(48).width('100%')
            .onSelect((index: number): void => { this.encryptionText = ['NONE', 'SSL', 'TLS'][index]; })
          HarmonyComputeField({ labelKey: 'alertChannelRecipientLabel', fieldText: this.recipientText })
        } else if (this.channelType === 'custom') {
          this.customWebhook()
        } else {
          HarmonyComputeField({ labelKey: 'alertChannelWebhookUrlLabel', fieldText: this.webhookText })
        }
        if (this.errorMessage.length > 0) Text(this.errorMessage).fontSize(14).width('100%')
        if (this.channelType === 'email' || this.channelType === 'custom') {
          Button(this.text('alertChannelTestAction'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48)
            .enabled(!this.loading && this.webhookUrlAction !== 'clear').onClick((): void => { this.testChannel(); })
        }
        Button(this.text('commonSave')).width('100%').height(48)
          .enabled(!this.loading && this.channelName.trim().length > 0 &&
            (this.channelType !== 'custom' || this.channelTestPassed ||
              (this.webhookUrlAction === 'clear' && this.selected.get('status') === 'Disable')))
          .onClick((): void => { this.saveChannel(); })
      }
    }.padding(16).width('100%').alignItems(HorizontalAlign.Start).enabled(!this.loading)
  }

  private selectMethod(method: string, checked: boolean): void {
    this.methods = this.methods.filter((value: string): boolean => value !== method);
    if (checked) this.methods.push(method);
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'form') {
      NavDestination() { Scroll() { this.form() }.width('100%').height('100%') }
        .title(this.text(this.selectedTab === 0 ? 'alertRuleCreateAction' : 'alertChannelCreateAction'),
          { barStyle: BarStyle.STANDARD })
    }
  }

  build() {
    Navigation(this.pathStack) { this.body() }
      .title(this.text('alertPageTitle'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini)
      .hideBackButton(true).menus(this.menus()).navDestination(this.destination)
      .mode(NavigationMode.Stack)
      .width('100%').height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
  }
}
