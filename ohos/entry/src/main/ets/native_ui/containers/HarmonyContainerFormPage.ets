import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

class HarmonyContainerPortDraft {
  rowId: number;
  containerPort: string = '';
  hostPort: string = '';
  hostIP: string = '';
  protocol: string = 'tcp';
  constructor(rowId: number) { this.rowId = rowId; }
}

class HarmonyContainerMountDraft {
  rowId: number;
  sourceDir: string = '';
  containerDir: string = '';
  mode: string = 'rw';
  mountType: string = 'bind';
  constructor(rowId: number) { this.rowId = rowId; }
}

@Component
export struct HarmonyContainerFormPage {
  @Prop containerId: string = '';
  @Prop containerName: string = '';
  @Prop containerImage: string = '';
  onSaved: () => void = (): void => {};
  @State private formName: string = '';
  @State private formImage: string = '';
  @State private hostname: string = '';
  @State private envText: string = '';
  @State private commandText: string = '';
  @State private networkName: string = 'bridge';
  @State private restartPolicy: string = 'unless-stopped';
  @State private autoRemove: boolean = false;
  @State private privileged: boolean = false;
  @State private publishAllPorts: boolean = false;
  @State private ttyEnabled: boolean = false;
  @State private stdinEnabled: boolean = false;
  @State private forcePull: boolean = false;
  @State private ports: HarmonyContainerPortDraft[] = [];
  @State private mounts: HarmonyContainerMountDraft[] = [];
  @State private saving: boolean = false;
  @State private formError: string = '';
  @State private loading: boolean = false;
  private originalFields: Map<string, Object | null> = new Map<string, Object | null>();
  private nextRowId: number = 0;
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.formName = this.containerName;
    this.formImage = this.containerImage;
    if (this.containerId.length > 0) this.loadExisting();
  }

  private label(key: string): string { return this.bridge.text(key); }

  private async loadExisting(): Promise<void> {
    this.loading = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('name', this.containerName);
      const data = await this.bridge.invoke<Map<string, Object | null>>('getContainerForm', args);
      this.originalFields = data;
      this.formName = data.get('name') as string;
      this.formImage = data.get('image') as string;
      this.hostname = data.get('hostname') as string ?? '';
      this.envText = (data.get('env') as string[] ?? []).join('\n');
      this.commandText = (data.get('cmd') as string[] ?? []).join('\n');
      this.restartPolicy = data.get('restartPolicy') as string ?? 'no';
      this.networkName = data.get('network') as string ?? 'bridge';
      this.autoRemove = data.get('autoRemove') === true;
      this.privileged = data.get('privileged') === true;
      this.publishAllPorts = data.get('publishAllPorts') === true;
      this.ttyEnabled = data.get('tty') === true;
      this.stdinEnabled = data.get('openStdin') === true;
      this.forcePull = data.get('forcePull') === true;
      this.ports = (data.get('exposedPorts') as Array<Map<string, Object | null>> ?? [])
        .map((fields: Map<string, Object | null>): HarmonyContainerPortDraft => {
          const port = new HarmonyContainerPortDraft(this.nextRowId++);
          port.containerPort = fields.get('containerPort') as string;
          port.hostPort = fields.get('hostPort') as string ?? '';
          port.hostIP = fields.get('hostIP') as string ?? '';
          port.protocol = fields.get('protocol') as string;
          return port;
        });
      this.mounts = (data.get('volumes') as Array<Map<string, Object | null>> ?? [])
        .map((fields: Map<string, Object | null>): HarmonyContainerMountDraft => {
          const mount = new HarmonyContainerMountDraft(this.nextRowId++);
          mount.sourceDir = fields.get('sourceDir') as string;
          mount.containerDir = fields.get('containerDir') as string;
          mount.mode = fields.get('mode') as string;
          mount.mountType = fields.get('type') as string;
          return mount;
        });
    } catch (error) { this.formError = (error as Error).message; }
    finally { this.loading = false; }
  }

  private lines(content: string): string[] {
    return content.split('\n').map((line: string): string => line.trim())
      .filter((line: string): boolean => line.length > 0);
  }

  private updatePort(index: number, field: string, content: string): void {
    const updated = this.ports.slice();
    if (field === 'containerPort') updated[index].containerPort = content;
    else if (field === 'hostPort') updated[index].hostPort = content;
    else if (field === 'hostIP') updated[index].hostIP = content;
    else updated[index].protocol = content;
    this.ports = updated;
  }

  private updateMount(index: number, field: string, content: string): void {
    const updated = this.mounts.slice();
    if (field === 'sourceDir') updated[index].sourceDir = content;
    else if (field === 'containerDir') updated[index].containerDir = content;
    else updated[index].mode = content;
    this.mounts = updated;
  }

  private async save(): Promise<void> {
    this.saving = true;
    this.formError = '';
    try {
      const args = new Map<string, Object | null>();
      this.originalFields.forEach((value: Object | null, key: string): void => { args.set(key, value); });
      args.set('name', this.formName.trim());
      args.set('image', this.formImage.trim());
      args.set('hostname', this.hostname);
      args.set('env', this.lines(this.envText));
      args.set('cmd', this.lines(this.commandText));
      args.set('network', this.networkName);
      args.set('networks', [this.networkName]);
      args.set('restartPolicy', this.restartPolicy);
      args.set('autoRemove', this.autoRemove);
      args.set('privileged', this.privileged);
      args.set('publishAllPorts', this.publishAllPorts);
      args.set('tty', this.ttyEnabled);
      args.set('openStdin', this.stdinEnabled);
      args.set('forcePull', this.forcePull);
      args.set('exposedPorts', this.ports.map((port: HarmonyContainerPortDraft): Map<string, Object | null> => {
        const fields = new Map<string, Object | null>();
        fields.set('containerPort', port.containerPort);
        if (port.hostPort.length > 0) fields.set('hostPort', port.hostPort);
        if (port.hostIP.length > 0) fields.set('hostIP', port.hostIP);
        fields.set('protocol', port.protocol);
        return fields;
      }));
      args.set('volumes', this.mounts.map((mount: HarmonyContainerMountDraft): Map<string, Object | null> => {
        const fields = new Map<string, Object | null>();
        fields.set('sourceDir', mount.sourceDir);
        fields.set('containerDir', mount.containerDir);
        fields.set('mode', mount.mode);
        fields.set('type', mount.mountType);
        return fields;
      }));
      if (this.containerId.length > 0) args.set('containerID', this.containerId);
      const method = this.containerId.length > 0 ? 'updateContainer' : 'createContainer';
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.onSaved();
    } catch (error) { this.formError = (error as Error).message; }
    finally { this.saving = false; }
  }

  @Builder
  private sectionTitle(key: string) {
    Text(this.label(key)).fontSize(16).fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary')).width('100%').margin({ top: 8 })
  }

  @Builder
  private toggleRow(title: string, enabled: boolean, changed: (selected: boolean) => void) {
    Row({ space: 12 }) {
      Text(title).fontSize(16).layoutWeight(1).fontColor($r('sys.color.font_primary'))
      Toggle({ type: ToggleType.Switch, isOn: enabled }).onChange(changed)
    }.constraintSize({ minHeight: 48 }).width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        this.sectionTitle('containerCreateBasicSectionTitle')
        if (this.loading) { LoadingProgress().width(48).height(48) }
        TextInput({ text: this.formName, placeholder: this.label('containerInfoName') })
          .height(48).accessibilityText(this.label('containerInfoName'))
          .onChange((content: string): void => { this.formName = content; })
        TextInput({ text: this.formImage, placeholder: this.label('containerInfoImage') })
          .height(48).accessibilityText(this.label('containerInfoImage'))
          .onChange((content: string): void => { this.formImage = content; })
        TextInput({ text: this.hostname, placeholder: this.label('dashboardHostNameLabel') })
          .height(48).onChange((content: string): void => { this.hostname = content; })
        Select([{ value: 'no' }, { value: 'always' }, { value: 'on-failure' }, { value: 'unless-stopped' }])
          .value(this.restartPolicy).height(48).accessibilityText(this.label('containerCreateRestartLabel'))
          .onSelect((index: number, content: string): void => { this.restartPolicy = content; })
        TextInput({ text: this.networkName, placeholder: this.label('containerTabNetworks') })
          .height(48).onChange((content: string): void => { this.networkName = content; })
        this.sectionTitle('containerInfoEnv')
        TextArea({ text: this.envText, placeholder: this.label('containerCreateEnvHint') })
          .height(120).fontFamily('monospace').onChange((content: string): void => { this.envText = content; })
        this.sectionTitle('containerInfoCommand')
        TextArea({ text: this.commandText, placeholder: this.label('containerInfoCommand') })
          .height(96).fontFamily('monospace').onChange((content: string): void => { this.commandText = content; })
        this.sectionTitle('containerInfoPorts')
        ForEach(this.ports, (port: HarmonyContainerPortDraft, index: number): void => {
          Column({ space: 8 }) {
            Row({ space: 8 }) {
              TextInput({ text: port.hostPort, placeholder: this.label('commonPort') }).type(InputType.Number)
                .layoutWeight(1).height(48)
                .onChange((content: string): void => { this.updatePort(index, 'hostPort', content); })
              Text('→').fontColor($r('sys.color.font_secondary'))
              TextInput({ text: port.containerPort, placeholder: this.label('containerInfoPorts') })
                .type(InputType.Number).layoutWeight(1).height(48)
                .onChange((content: string): void => { this.updatePort(index, 'containerPort', content); })
            }
            Row({ space: 8 }) {
              TextInput({ text: port.hostIP, placeholder: 'Host IP' }).layoutWeight(1).height(48)
                .onChange((content: string): void => { this.updatePort(index, 'hostIP', content); })
              Select([{ value: 'tcp' }, { value: 'udp' }]).value(port.protocol).height(48)
                .onSelect((selected: number, content: string): void => { this.updatePort(index, 'protocol', content); })
              Button(this.label('commonDelete'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48)
                .onClick((): void => { this.ports = this.ports.filter((item: HarmonyContainerPortDraft): boolean => item.rowId !== port.rowId); })
            }
          }.padding(12).backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
        }, (port: HarmonyContainerPortDraft): string => `${port.rowId}`)
        Button(this.label('commonAdd'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48)
          .onClick((): void => { this.ports = this.ports.concat([new HarmonyContainerPortDraft(this.nextRowId++)]); })
        this.sectionTitle('containerTabVolumes')
        ForEach(this.mounts, (mount: HarmonyContainerMountDraft, index: number): void => {
          Column({ space: 8 }) {
            TextInput({ text: mount.sourceDir, placeholder: this.label('filesPathLabel') }).height(48)
              .onChange((content: string): void => { this.updateMount(index, 'sourceDir', content); })
            TextInput({ text: mount.containerDir, placeholder: this.label('containerTabFiles') }).height(48)
              .onChange((content: string): void => { this.updateMount(index, 'containerDir', content); })
            Row({ space: 8 }) {
              Select([{ value: 'rw' }, { value: 'ro' }]).value(mount.mode).height(48).layoutWeight(1)
                .onSelect((selected: number, content: string): void => { this.updateMount(index, 'mode', content); })
              Button(this.label('commonDelete'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48)
                .onClick((): void => { this.mounts = this.mounts.filter((item: HarmonyContainerMountDraft): boolean => item.rowId !== mount.rowId); })
            }
          }.padding(12).backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
        }, (mount: HarmonyContainerMountDraft): string => `${mount.rowId}`)
        Button(this.label('commonAdd'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48)
          .onClick((): void => { this.mounts = this.mounts.concat([new HarmonyContainerMountDraft(this.nextRowId++)]); })
        this.sectionTitle('containerCreateAdvancedSectionTitle')
        this.toggleRow(this.label('containerCreateAutoRemove'), this.autoRemove, (enabled: boolean): void => { this.autoRemove = enabled; })
        this.toggleRow(this.label('containerCreatePrivileged'), this.privileged, (enabled: boolean): void => { this.privileged = enabled; })
        this.toggleRow(this.label('containerCreatePublishAllPorts'), this.publishAllPorts, (enabled: boolean): void => { this.publishAllPorts = enabled; })
        this.toggleRow('TTY', this.ttyEnabled, (enabled: boolean): void => { this.ttyEnabled = enabled; })
        this.toggleRow('STDIN', this.stdinEnabled, (enabled: boolean): void => { this.stdinEnabled = enabled; })
        this.toggleRow(this.label('containerUpgradeForcePull'), this.forcePull, (enabled: boolean): void => { this.forcePull = enabled; })
        if (this.formError.length > 0) { Text(this.formError).fontColor($r('sys.color.font_primary')).width('100%') }
        Button(this.label('commonSave')).height(48).width('100%').enabled(!this.saving && !this.loading)
          .onClick((): void => { this.save(); })
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
  }
}
