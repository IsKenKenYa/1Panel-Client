import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyWebsiteOption } from './HarmonyWebsiteModels';

@Component
export struct HarmonyWebsiteForm {
  websiteId: number | null = null;
  onSaved: () => void = (): void => {};
  @State private loading: boolean = true;
  @State private ready: boolean = false;
  @State private saving: boolean = false;
  @State private formError: string = '';
  @State private websiteType: string = 'runtime';
  @State private alias: string = '';
  @State private primaryDomain: string = '';
  @State private remark: string = '';
  @State private siteDir: string = '';
  @State private proxyType: string = 'tcp';
  @State private proxyAddress: string = '';
  @State private portText: string = '';
  @State private ipv6: boolean = false;
  @State private favorite: boolean = false;
  @State private groups: HarmonyWebsiteOption[] = [];
  @State private runtimes: HarmonyWebsiteOption[] = [];
  @State private parents: HarmonyWebsiteOption[] = [];
  @State private groupIndex: number = -1;
  @State private runtimeIndex: number = -1;
  @State private parentIndex: number = -1;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private types: string[] = ['runtime', 'proxy', 'subsite', 'static'];

  aboutToAppear(): void {
    this.load();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.ready = false;
    this.formError = '';
    try {
      const options = await this.bridge.invoke<Map<string, Object | null>>('getWebsiteCreateOptions');
      this.groups = (options.get('groups') as Array<Map<string, Object | null>>)
        .map((item: Map<string, Object | null>): HarmonyWebsiteOption => new HarmonyWebsiteOption(item));
      this.runtimes = (options.get('runtimes') as Array<Map<string, Object | null>>)
        .map((item: Map<string, Object | null>): HarmonyWebsiteOption => new HarmonyWebsiteOption(item));
      this.parents = (options.get('parentWebsites') as Array<Map<string, Object | null>>)
        .map((item: Map<string, Object | null>): HarmonyWebsiteOption => new HarmonyWebsiteOption(item, 'primaryDomain'));
      if (this.groups.length > 0) this.groupIndex = 0;
      if (this.runtimes.length > 0) this.runtimeIndex = 0;
      if (this.websiteId !== null) {
        const args = new Map<string, Object | null>();
        args.set('id', this.websiteId);
        const website = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteDetail', args);
        this.primaryDomain = website.get('primaryDomain') as string;
        this.alias = website.get('alias') as string | null ?? '';
        this.remark = website.get('remark') as string ?? '';
        this.websiteType = website.get('type') as string;
        this.ipv6 = website.get('IPV6') as boolean ?? false;
        this.favorite = website.get('favorite') as boolean ?? false;
        this.groupIndex = this.groups.findIndex((item: HarmonyWebsiteOption): boolean =>
          item.optionId === website.get('webSiteGroupId'));
      }
      this.ready = true;
    } catch (error) {
      this.formError = `${error}`;
    } finally {
      this.loading = false;
    }
  }

  private async save(): Promise<void> {
    if (!this.ready || this.saving) return;
    if (this.groupIndex < 0) {
      this.formError = this.text('websitesValidationGroupRequired');
      return;
    }
    if (this.primaryDomain.trim().length === 0) {
      this.formError = this.text('websitesValidationPrimaryDomainRequired');
      return;
    }
    if (this.websiteId === null && this.alias.trim().length === 0) {
      this.formError = this.text('websitesValidationAliasRequired');
      return;
    }
    if (this.websiteId === null && this.websiteType === 'runtime' && this.runtimeIndex < 0) {
      this.formError = this.text('websitesValidationRuntimeRequired');
      return;
    }
    if (this.websiteId === null && this.websiteType === 'subsite' && this.parentIndex < 0) {
      this.formError = this.text('websitesValidationParentRequired');
      return;
    }
    if (this.websiteId === null && this.websiteType === 'proxy' && this.proxyAddress.trim().length === 0) {
      this.formError = this.text('websitesValidationProxyRequired');
      return;
    }
    const hasPort = this.websiteId === null && this.portText.trim().length > 0;
    const port = Number(this.portText);
    if (hasPort && (!Number.isInteger(port) || port < 1 || port > 65535)) {
      this.formError = this.text('websitesDomainValidationPort');
      return;
    }
    this.saving = true;
    this.formError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('primaryDomain', this.primaryDomain.trim());
      args.set('remark', this.remark.trim());
      args.set('groupId', this.groups[this.groupIndex].optionId);
      args.set('ipv6', this.ipv6);
      args.set('favorite', this.favorite);
      if (this.websiteId !== null) {
        args.set('id', this.websiteId);
        await this.bridge.invoke<Object | null>('updateNativeWebsite', args);
      } else {
        args.set('alias', this.alias.trim());
        args.set('type', this.websiteType);
        if (hasPort) args.set('port', port);
        if (this.siteDir.trim().length > 0) args.set('siteDir', this.siteDir.trim());
        if (this.websiteType === 'runtime') args.set('runtimeId', this.runtimes[this.runtimeIndex].optionId);
        if (this.websiteType === 'subsite') args.set('parentWebsiteId', this.parents[this.parentIndex].optionId);
        if (this.websiteType === 'proxy') {
          args.set('proxyType', this.proxyType);
          args.set('proxy', this.proxyAddress.trim());
        }
        await this.bridge.invoke<Object | null>('createNativeWebsite', args);
      }
      this.onSaved();
    } catch (error) {
      this.formError = `${error}`;
    } finally {
      this.saving = false;
    }
  }

  private options(items: HarmonyWebsiteOption[]): SelectOption[] {
    return items.map((item: HarmonyWebsiteOption): SelectOption => ({ value: item.label }));
  }

  private typeOptions(): SelectOption[] {
    return [
      { value: this.text('websitesLifecycleTypeRuntime') },
      { value: this.text('websitesLifecycleTypeProxy') },
      { value: this.text('websitesLifecycleTypeSubsite') },
      { value: this.text('websitesLifecycleTypeStatic') },
    ];
  }

  @Builder
  private input(labelKey: string, inputValue: string, changed: (content: string) => void) {
    Column({ space: 8 }) {
      Text(this.text(labelKey)).fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextInput({ text: inputValue })
        .height(48)
        .fontSize(16)
        .accessibilityText(this.text(labelKey))
        .onChange(changed)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) {
          LoadingProgress().width(48).height(48)
        } else if (!this.ready) {
          Text(this.formError).fontSize(14).width('100%')
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        } else {
          if (this.websiteId === null) {
            Text(this.text('websitesLifecycleTypeLabel')).width('100%').fontSize(14)
            Select(this.typeOptions())
              .selected(this.types.indexOf(this.websiteType))
              .height(48)
              .width('100%')
              .onSelect((index: number): void => { this.websiteType = this.types[index]; })
            this.input('websitesAliasLabel', this.alias, (content: string): void => { this.alias = content; })
          }
          this.input('websitesPrimaryDomainLabel', this.primaryDomain,
            (content: string): void => { this.primaryDomain = content; })
          Text(this.text('websitesGroupLabel')).width('100%').fontSize(14)
          Select(this.options(this.groups))
            .selected(this.groupIndex)
            .height(48)
            .width('100%')
            .onSelect((index: number): void => { this.groupIndex = index; })
          if (this.websiteId === null) {
            if (this.websiteType === 'runtime') {
              Text(this.text('websitesRuntimeLabel')).width('100%').fontSize(14)
              Select(this.options(this.runtimes))
                .selected(this.runtimeIndex)
                .height(48)
                .width('100%')
                .onSelect((index: number): void => { this.runtimeIndex = index; })
            }
            if (this.websiteType === 'subsite') {
              Text(this.text('websitesParentWebsiteLabel')).width('100%').fontSize(14)
              Select(this.options(this.parents))
                .selected(this.parentIndex)
                .height(48)
                .width('100%')
                .onSelect((index: number): void => { this.parentIndex = index; })
            }
            if (this.websiteType === 'proxy') {
              this.input('websitesProxyAddressLabel', this.proxyAddress,
                (content: string): void => { this.proxyAddress = content; })
              this.input('websitesProxyTypeLabel', this.proxyType,
                (content: string): void => { this.proxyType = content; })
            }
            this.input('websitesSiteDirLabel', this.siteDir, (content: string): void => { this.siteDir = content; })
            this.input('websitesDomainPortLabel', this.portText, (content: string): void => { this.portText = content; })
          }
          this.input('websitesRemarkLabel', this.remark, (content: string): void => { this.remark = content; })
          Row() {
            Text('IPv6').layoutWeight(1).fontSize(16)
            Toggle({ type: ToggleType.Switch, isOn: this.ipv6 })
              .accessibilityText('IPv6')
              .onChange((selected: boolean): void => { this.ipv6 = selected; })
          }.height(48).width('100%')
          if (this.formError.length > 0) {
            Text(this.formError).fontSize(14).fontColor($r('sys.color.font_primary')).width('100%')
          }
          Button(this.text('commonSave'))
            .width('100%')
            .height(48)
            .enabled(!this.saving)
            .onClick((): void => { this.save(); })
        }
      }
      .padding(16)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
