import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';
import { HarmonyComputeField, HarmonyComputeInfo, HarmonyComputeToggle, computeArguments, computeText, computeWrite } from './HarmonyComputeControls';

@Component
export struct HarmonyVMFormPage {
  formKind: string = 'instance';
  record: Map<string, Object | null> = new Map<string, Object | null>();
  networks: Map<string, Object | null>[] = [];
  storages: Map<string, Object | null>[] = [];
  isos: Map<string, Object | null>[] = [];
  onSaved: () => void = (): void => {};
  @State private nameText: string = '';
  @State private cpuText: string = '2';
  @State private memoryText: string = '2048';
  @State private diskText: string = '20';
  @State private networkText: string = '';
  @State private poolText: string = '';
  @State private diskPathText: string = '';
  @State private imageText: string = '';
  @State private isoText: string = '';
  @State private templateText: string = '';
  @State private osText: string = 'linux';
  @State private busText: string = 'virtio';
  @State private bootText: string = 'hd';
  @State private descriptionText: string = '';
  @State private typeText: string = 'nat';
  @State private bridgeText: string = '';
  @State private sourceInterfaceText: string = '';
  @State private cidrText: string = '';
  @State private gatewayText: string = '';
  @State private dhcpStartText: string = '';
  @State private dhcpEndText: string = '';
  @State private autoStart: boolean = true;
  @State private startAfterCreate: boolean = true;
  @State private saving: boolean = false;
  @State private errorMessage: string = '';
  @State private isoSource: number = 0;
  @State private targetDirectory: string = '/opt/1panel/tmp';
  @State private isoUrl: string = '';
  @State private localIsoName: string = '';
  @State private importProgress: number = 0;
  @State private cancellingImport: boolean = false;
  @State private removing: boolean = false;
  @State private changingStatus: boolean = false;
  @State private resourceStatus: string = '';
  @State private showUsedIpAddresses: boolean = false;
  @State private deleteIsoFile: boolean = false;
  private localIsoPath: string = '';
  private importToken: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private isoTypes: string[] = [
    'Debian', 'Ubuntu', 'CentOS', 'Rocky', 'AlmaLinux', 'Fedora', 'openSUSE',
    'RHEL', 'OracleLinux', 'Arch', 'Windows', 'FreeBSD',
  ];
  private importListener: (method: string, args: Object | null) => void = (method: string, args: Object | null): void => {
    if (method === 'vmIsoProgress' && args !== null) {
      const event = args as Map<string, Object | null>;
      if (event.get('token') === this.importToken) this.importProgress = event.get('percent') as number;
    }
  };

  aboutToAppear(): void {
    if (this.record.size > 0) {
      this.nameText = this.record.get('name') as string;
      this.descriptionText = this.record.get('description') as string ?? '';
      this.autoStart = this.record.get('autoStart') as boolean ?? true;
      this.resourceStatus = this.record.get('status') as string ?? '';
      if (this.formKind === 'instance') {
        this.cpuText = `${this.record.get('cpu')}`;
        this.memoryText = `${this.record.get('memoryMiB')}`;
        this.networkText = this.record.get('network') as string;
        this.isoText = (this.record.get('isoPaths') as string[]).join('\n');
        this.bootText = this.record.get('bootOrder') as string ?? 'hd';
      } else if (this.formKind === 'iso') {
        this.typeText = this.record.get('type') as string;
        this.diskPathText = this.record.get('path') as string;
      } else if (this.formKind === 'storage') {
        this.typeText = this.record.get('type') as string;
        this.diskPathText = this.record.get('path') as string;
      }
    } else if (this.formKind === 'iso') {
      this.typeText = 'Ubuntu';
      this.nameText = `iso-${Date.now()}`;
    } else if (this.formKind === 'storage') {
      this.typeText = 'dir';
    } else if (this.formKind === 'instance') {
      if (this.networks.length > 0) this.networkText = this.networks[0].get('name') as string;
      if (this.storages.length > 0) this.poolText = this.storages[0].get('name') as string;
    }
    if (this.formKind === 'iso') this.bridge.addMethodListener(this.importListener);
  }

  aboutToDisappear(): void {
    if (this.formKind === 'iso') this.bridge.removeMethodListener(this.importListener);
  }

  private formTitle(): string {
    if (this.record.size > 0) return computeText('commonEdit');
    if (this.formKind === 'network') return computeText('vmNetworkCreateAction');
    if (this.formKind === 'storage') return computeText('vmStorageCreateAction');
    if (this.formKind === 'iso') return computeText('vmIsoCreateAction');
    return computeText('vmInstanceCreateTitle');
  }

  private lines(content: string): string[] {
    return content.split('\n').map((line: string): string => line.trim())
      .filter((line: string): boolean => line.length > 0);
  }

  private async save(): Promise<void> {
    if (this.formKind === 'iso' && (this.nameText.trim().length === 0 ||
      (this.isoSource === 0 && this.diskPathText.trim().length === 0) ||
      (this.isoSource > 0 && this.targetDirectory.trim().length === 0) ||
      (this.isoSource === 1 && this.localIsoPath.length === 0) ||
      (this.isoSource === 2 && this.isoUrl.trim().length === 0))) {
      this.errorMessage = computeText('commonErrorBadRequest');
      return;
    }
    this.saving = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('name', this.nameText.trim());
      args.set('description', this.descriptionText);
      let method: string = '';
      const editing = this.record.size > 0;
      if (!editing || this.formKind === 'instance' || this.autoStart !== this.record.get('autoStart')) {
        args.set('autoStart', this.autoStart);
      }
      if (editing && this.formKind !== 'instance') args.set('id', this.record.get('id') as number);
      if (this.formKind === 'instance') {
        args.set('cpu', Number(this.cpuText));
        args.set('memory', Number(this.memoryText));
        args.set('network', this.networkText);
        args.set('isoPaths', this.lines(this.isoText));
        args.set('bootOrder', this.bootText);
        if (!editing) {
          args.set('diskSize', Number(this.diskText));
          args.set('osType', this.osText);
          args.set('diskBus', this.busText);
          args.set('startAfterCreate', this.startAfterCreate);
          if (this.poolText.length > 0) args.set('storagePool', this.poolText);
          if (this.diskPathText.length > 0) args.set('diskPath', this.diskPathText);
          if (this.imageText.length > 0) args.set('imagePath', this.imageText);
          if (this.templateText.length > 0) args.set('templateID', Number(this.templateText));
        }
        method = editing ? 'updateNativeVm' : 'createNativeVm';
      } else if (this.formKind === 'network') {
        if (!editing) {
          args.set('type', this.typeText);
          args.set('bridgeName', this.bridgeText);
          args.set('sourceInterface', this.sourceInterfaceText);
          args.set('cidr', this.cidrText);
          args.set('gateway', this.gatewayText);
          args.set('dhcpStart', this.dhcpStartText);
          args.set('dhcpEnd', this.dhcpEndText);
        }
        method = editing ? 'updateNativeVmNetwork' : 'createNativeVmNetwork';
      } else {
        args.set('type', this.typeText);
        args.set('path', this.diskPathText);
        if (this.formKind === 'storage') {
          method = editing ? 'updateNativeVmStorage' : 'createNativeVmStorage';
        } else if (!editing && this.isoSource > 0) {
          this.importToken = `iso-${Date.now()}`;
          this.importProgress = 0;
          args.set('token', this.importToken);
          args.set('directory', this.targetDirectory.trim());
          if (this.isoSource === 1) {
            args.set('localPath', this.localIsoPath);
          } else {
            args.set('url', this.isoUrl.trim());
          }
          method = 'harmonyCompute/importVmIso';
        } else {
          method = editing ? 'updateNativeVmIso' : 'createNativeVmIso';
        }
      }
      const result = await computeWrite(method, args);
      if (result.get('cancelled') === true) {
        this.getUIContext().getPromptAction().showToast({ message: computeText('vmIsoImportCancelled') });
        this.onSaved();
        return;
      }
      const task = result.get('taskID') as string | undefined;
      this.getUIContext().getPromptAction().showToast({ message: task ?? computeText('commonSaveSuccess') });
      this.queryNavigationInfo()?.pathStack.pop();
      this.onSaved();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.saving = false;
      this.cancellingImport = false;
    }
  }

  private async chooseIso(): Promise<void> {
    try {
      const file = await this.bridge.invoke<Map<string, Object | null> | null>('harmonyCompute/selectVmIso');
      if (file !== null) {
        this.localIsoName = file.get('name') as string;
        this.localIsoPath = file.get('path') as string;
      }
    } catch (error) {
      this.errorMessage = (error as Error).message;
    }
  }

  private async cancelIsoUpload(): Promise<void> {
    this.cancellingImport = true;
    try {
      await computeWrite('harmonyCompute/cancelVmIsoUpload', computeArguments('token', this.importToken));
    } catch (error) {
      this.errorMessage = (error as Error).message;
      this.cancellingImport = false;
    }
  }

  private confirmDelete(): void {
    this.getUIContext().showAlertDialog({
      title: computeText('commonDelete'),
      message: this.record.get('name') as string,
      primaryButton: { value: computeText('commonCancel'), action: (): void => {} },
      secondaryButton: { value: computeText('commonDelete'), action: (): void => { this.deleteResource(); } },
    });
  }

  private async deleteResource(): Promise<void> {
    this.removing = true;
    this.errorMessage = '';
    try {
      const args = computeArguments('id', this.record.get('id') as number);
      if (this.formKind === 'iso') args.set('deleteFile', this.deleteIsoFile);
      const method = this.formKind === 'iso' ? 'deleteNativeVmIso' :
        this.formKind === 'network' ? 'deleteNativeVmNetwork' : 'deleteNativeVmStorage';
      await computeWrite(method, args);
      this.queryNavigationInfo()?.pathStack.pop();
      this.onSaved();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.removing = false;
    }
  }

  private async toggleResourceStatus(): Promise<void> {
    this.changingStatus = true;
    this.errorMessage = '';
    try {
      const status = this.resourceStatus === 'running' ? 'stopped' : 'running';
      const args = computeArguments('id', this.record.get('id') as number);
      args.set('status', status);
      await computeWrite(this.formKind === 'network' ? 'updateNativeVmNetwork' : 'updateNativeVmStorage', args);
      this.resourceStatus = status;
      this.onSaved();
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.changingStatus = false;
    }
  }

  @Builder
  private usedIps() {
    Column({ space: 8 }) {
      if ((this.record.get('usedIPs') as Map<string, Object | null>[]).length === 0) {
        Text(computeText('vmNetworkUsedIpEmpty')).padding(16)
      } else {
        List({ space: 8 }) {
          ForEach(this.record.get('usedIPs') as Map<string, Object | null>[], (item: Map<string, Object | null>): void => {
            ListItem() {
              Column() {
                HarmonyComputeInfo({ labelKey: 'vmNetworkIpColumn', content: item.get('ip') as string })
                HarmonyComputeInfo({ labelKey: 'vmNetworkVmColumn', content: item.get('name') as string })
                HarmonyComputeInfo({ labelKey: 'vmNetworkMacColumn', content: item.get('mac') as string })
                HarmonyComputeInfo({ labelKey: 'vmNetworkSourceColumn', content: item.get('source') as string })
              }.padding(12).width('100%').backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
            }
          }, (item: Map<string, Object | null>): string => `${item.get('ip')}/${item.get('mac')}`)
        }.padding(16).width('100%').layoutWeight(1)
      }
    }.width('100%').height('100%')
  }

  @Builder
  private isoFields() {
    Text(computeText('vmIsoTypeLabel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
    Select(this.isoTypes.map((entry: string): SelectOption => ({ value: entry })))
      .value(this.typeText).height(48).width('100%').enabled(!this.saving && this.record.size === 0)
      .onSelect((index: number): void => { this.typeText = this.isoTypes[index]; })
    if (this.record.size === 0) {
      Text(computeText('vmIsoSourceSectionTitle')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      Select([
        { value: computeText('vmIsoSourceServerFile') },
        { value: computeText('vmIsoSourceUpload') },
        { value: computeText('vmIsoSourceDownload') },
      ]).selected(this.isoSource).height(48).width('100%').enabled(!this.saving)
        .onSelect((index: number): void => { this.isoSource = index; })
    }
    if (this.isoSource === 0) {
      HarmonyComputeField({ labelKey: 'vmIsoServerPathLabel', fieldText: this.diskPathText, disabled: this.saving })
    } else {
      if (this.isoSource === 1) {
        Button(this.localIsoName.length > 0 ? this.localIsoName : computeText('vmIsoSourceUpload'))
          .height(48).width('100%').enabled(!this.saving).buttonStyle(ButtonStyleMode.NORMAL)
          .onClick((): void => { this.chooseIso(); })
      } else {
        HarmonyComputeField({ labelKey: 'vmIsoDownloadUrlLabel', fieldText: this.isoUrl, disabled: this.saving })
      }
      HarmonyComputeField({ labelKey: 'vmIsoTargetDirLabel', fieldText: this.targetDirectory, disabled: this.saving })
      if (this.saving) {
        Progress({ value: this.importProgress, total: 100 }).width('100%')
          .accessibilityText(computeText('vmIsoImportProgressLabel'))
        if (this.isoSource === 1) {
          Button(computeText('vmIsoImportCancelAction')).height(48).enabled(!this.cancellingImport)
            .buttonStyle(ButtonStyleMode.TEXTUAL).onClick((): void => { this.cancelIsoUpload(); })
        }
      }
    }
  }

  private options(list: Map<string, Object | null>[], key: string): SelectOption[] {
    return list.map((item: Map<string, Object | null>): SelectOption => ({ value: item.get(key) as string }));
  }

  private isoOptions(): Map<string, Object | null>[] {
    return this.isos.filter((item: Map<string, Object | null>): boolean => item.get('isExist') === true);
  }

  private isoOptionLabel(): string {
    const item = this.isoOptions().find((entry: Map<string, Object | null>): boolean => entry.get('path') === this.isoText);
    return item?.get('name') as string ?? (this.isoText.length === 0 ? computeText('vmInstanceIsoNone') : this.isoText);
  }

  @Builder
  private instanceFields() {
    HarmonyComputeField({ labelKey: 'vmInstanceCpuLabel', fieldText: this.cpuText, inputType: InputType.Number })
    HarmonyComputeField({ labelKey: 'vmInstanceMemoryLabel', fieldText: this.memoryText, inputType: InputType.Number })
    if (this.networks.length > 0) {
      Text(computeText('vmInstanceNetworkLabel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      Select(this.options(this.networks, 'name')).value(this.networkText).height(48).width('100%')
        .onSelect((index: number): void => { this.networkText = this.networks[index].get('name') as string; })
    } else {
      HarmonyComputeField({ labelKey: 'vmInstanceNetworkLabel', fieldText: this.networkText })
    }
    Text(computeText('vmInstanceIsoLabel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
    Select([{ value: computeText('vmInstanceIsoNone') }, ...this.options(this.isoOptions(), 'name')])
      .value(this.isoOptionLabel()).height(48).width('100%')
      .onSelect((index: number): void => { this.isoText = index === 0 ? '' : this.isoOptions()[index - 1].get('path') as string; })
    Text(computeText('vmInstanceBootOrderLabel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
    Select([{ value: computeText('vmInstanceBootDiskFirst') }, { value: computeText('vmInstanceBootCdFirst') }])
      .selected(this.bootText === 'cdrom' ? 1 : 0).height(48).width('100%')
      .onSelect((index: number): void => { this.bootText = index === 1 ? 'cdrom' : 'hd'; })
    if (this.record.size === 0) {
      HarmonyComputeField({ labelKey: 'vmInstanceDiskSizeLabel', fieldText: this.diskText, inputType: InputType.Number })
      if (this.storages.length > 0) {
        Text(computeText('vmInstanceStoragePoolLabel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
        Select(this.options(this.storages, 'name')).value(this.poolText).height(48).width('100%')
          .onSelect((index: number): void => { this.poolText = this.storages[index].get('name') as string; })
      }
      HarmonyComputeField({ labelKey: 'vmInstanceTemplateLabel', fieldText: this.templateText, inputType: InputType.Number })
      HarmonyComputeField({ labelKey: 'filesPathLabel', fieldText: this.diskPathText })
      HarmonyComputeField({ labelKey: 'vmInstanceOsTypeLabel', fieldText: this.osText })
      Text(computeText('vmInstanceDiskBusLabel')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      Select([{ value: 'VirtIO' }, { value: 'SATA (AHCI)' }]).selected(this.busText === 'sata' ? 1 : 0)
        .height(48).width('100%').onSelect((index: number): void => { this.busText = index === 1 ? 'sata' : 'virtio'; })
      HarmonyComputeField({ labelKey: 'vmIsoServerPathLabel', fieldText: this.imageText })
      HarmonyComputeToggle({ labelKey: 'vmInstanceStartAfterCreateLabel', selected: this.startAfterCreate })
    }
  }

  @Builder
  private networkFields() {
    if (this.record.size === 0) {
      Text(computeText('vmNetworkTypeLabel')).fontSize(14)
      Select([{ value: 'NAT' }, { value: 'Bridge' }, { value: 'Macvtap' }])
        .value(this.typeText).height(48).width('100%')
        .onSelect((index: number): void => { this.typeText = ['nat', 'bridge', 'macvtap'][index]; })
      if (this.typeText === 'bridge') {
        HarmonyComputeField({ labelKey: 'vmNetworkBridgeLabel', fieldText: this.bridgeText })
      } else if (this.typeText === 'macvtap') {
        HarmonyComputeField({ labelKey: 'vmNetworkSourceInterfaceLabel', fieldText: this.sourceInterfaceText })
      } else {
        HarmonyComputeField({ labelKey: 'vmNetworkCidrLabel', fieldText: this.cidrText })
        HarmonyComputeField({ labelKey: 'vmNetworkGatewayLabel', fieldText: this.gatewayText })
        HarmonyComputeField({ labelKey: 'vmNetworkDhcpStartLabel', fieldText: this.dhcpStartText })
        HarmonyComputeField({ labelKey: 'vmNetworkDhcpEndLabel', fieldText: this.dhcpEndText })
      }
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          HarmonyComputeField({ labelKey: 'vmInstanceNameLabel', fieldText: this.nameText,
            disabled: this.record.size > 0 && this.formKind !== 'iso' })
          if (this.formKind === 'instance') {
            this.instanceFields()
          } else if (this.formKind === 'network') {
            this.networkFields()
          } else if (this.formKind === 'iso') {
            this.isoFields()
          } else {
            HarmonyComputeField({ labelKey: 'vmStoragePathLabel', fieldText: this.diskPathText, disabled: this.record.size > 0 })
          }
          HarmonyComputeField({ labelKey: 'commonDescription', fieldText: this.descriptionText })
          if (this.formKind !== 'iso') {
            HarmonyComputeToggle({ labelKey: 'vmInstanceAutoStartLabel', selected: this.autoStart })
          }
          if (this.errorMessage.length > 0) Text(this.errorMessage).fontColor($r('sys.color.font_primary'))
          Button(computeText(this.formKind === 'iso' && this.record.size === 0 ? 'vmIsoImportStartAction' : 'commonSave'))
            .width('100%').height(48).enabled(!this.saving && !this.removing && !this.changingStatus)
            .onClick((): void => { this.save(); })
          if (this.record.size > 0 && this.formKind !== 'instance') {
            if (this.formKind === 'iso') {
              HarmonyComputeToggle({ labelKey: 'vmIsoDeleteFileLabel', selected: this.deleteIsoFile })
            } else if (this.resourceStatus === 'running' || this.resourceStatus === 'stopped') {
              Button(computeText(this.resourceStatus === 'running' ? 'vmStorageStatusStop' : 'vmStorageStatusStart'))
                .width('100%').height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .enabled(!this.saving && !this.removing && !this.changingStatus)
                .onClick((): void => { this.toggleResourceStatus(); })
            }
            if (this.formKind === 'network') {
              Button(computeText('vmNetworkUsedIpAction')).width('100%').height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                .onClick((): void => { this.showUsedIpAddresses = true; })
                .bindSheet($$this.showUsedIpAddresses, this.usedIps, {
                  height: SheetSize.LARGE, showClose: true, title: { title: computeText('vmNetworkUsedIpTitle') },
                  systemMaterial: sheetMaterial,
                })
            }
            Button(computeText('commonDelete'), { role: ButtonRole.ERROR, buttonStyle: ButtonStyleMode.TEXTUAL })
              .height(48).width('100%').enabled(!this.saving && !this.removing && !this.changingStatus)
              .onClick((): void => { this.confirmDelete(); })
          }
        }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
      }.width('100%').height('100%')
    }.title(this.formTitle(), { barStyle: BarStyle.STANDARD })
      .backgroundColor($r('sys.color.background_secondary'))
  }
}
