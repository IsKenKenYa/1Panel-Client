import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

class HarmonyContainerAsset {
  assetId: string;
  title: string;
  subtitle: string;
  record: Map<string, Object | null>;
  constructor(section: string, record: Map<string, Object | null>) {
    this.record = record;
    if (section === 'images') {
      this.assetId = record.get('id') as string;
      const tags = record.get('tags') as string[];
      this.title = tags.length > 0 ? tags.join(', ') : this.assetId;
      this.subtitle = `${record.get('size')} B`;
    } else if (section === 'repositories') {
      this.assetId = `${record.get('id')}`;
      this.title = record.get('name') as string;
      this.subtitle = record.get('downloadUrl') as string;
    } else {
      this.assetId = record.get('name') as string;
      this.title = this.assetId;
      this.subtitle = record.get('driver') as string;
    }
  }
}

@Component
export struct HarmonyContainerAssetsPage {
  @Prop initialSection: string = 'images';
  /** 由外层 NavDestination 承载标题栏时，内层导航只负责内容与二级页，避免出现两层标题栏。 */
  @Prop embedded: boolean = false;
  @State private items: HarmonyContainerAsset[] = [];
  @State private selected: HarmonyContainerAsset[] = [];
  @State private loading: boolean = false;
  @State private saving: boolean = false;
  @State private errorMessage: string = '';
  @State private formKind: string = '';
  @State private formName: string = '';
  @State private formDriver: string = '';
  @State private formSubnet: string = '';
  @State private formGateway: string = '';
  @State private formUrl: string = '';
  @State private formUser: string = '';
  @State private formPassword: string = '';
  @State private imageTag: string = '';
  @State private dockerfile: string = '';
  @State private buildTags: string = '';
  @State private buildArgs: string = '';
  @State private repositoryName: string = '';
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.load(); }
  private text(key: string): string { return this.bridge.text(key); }
  private title(): string {
    if (this.initialSection === 'images') return this.text('containerTabImages');
    if (this.initialSection === 'networks') return this.text('containerTabNetworks');
    if (this.initialSection === 'volumes') return this.text('containerTabVolumes');
    return this.text('containerTabRepositories');
  }
  private readMethod(): string {
    if (this.initialSection === 'images') return 'getContainerImages';
    if (this.initialSection === 'networks') return 'getContainerNetworks';
    if (this.initialSection === 'volumes') return 'getContainerVolumes';
    return 'getContainerRepos';
  }
  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const records = await this.bridge.invoke<Array<Map<string, Object | null>>>(this.readMethod());
      this.items = records.map((record: Map<string, Object | null>): HarmonyContainerAsset =>
        new HarmonyContainerAsset(this.initialSection, record));
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }
  private push(name: string): void {
    const path: NavPathInfo = { name: name };
    this.paths.pushPath(path);
  }
  private openForm(kind: string): void {
    this.formKind = kind;
    this.formName = '';
    this.formDriver = this.initialSection === 'networks' ? 'bridge' : 'local';
    this.formSubnet = ''; this.formGateway = ''; this.formUrl = '';
    this.formUser = ''; this.formPassword = ''; this.imageTag = '';
    this.dockerfile = ''; this.buildTags = ''; this.buildArgs = '';
    this.errorMessage = '';
    this.push('form');
  }
  private async mutate(method: string, args: Map<string, Object | null>): Promise<void> {
    this.saving = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.getUIContext().getPromptAction().showToast({ message: this.text('containerOperateSuccess') });
      this.paths.clear();
      await this.load();
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.saving = false; }
  }
  private async save(): Promise<void> {
    const args = new Map<string, Object | null>();
    if (this.formKind === 'pull') {
      args.set('image', this.formName); args.set('tag', this.imageTag);
      await this.mutate('pullContainerImage', args);
    } else if (this.formKind === 'build') {
      args.set('name', this.formName); args.set('from', 'edit'); args.set('dockerfile', this.dockerfile);
      args.set('tags', this.buildTags.split('\n').filter((tag: string): boolean => tag.trim().length > 0));
      args.set('args', this.buildArgs.split('\n').filter((arg: string): boolean => arg.trim().length > 0));
      await this.mutate('buildContainerImage', args);
    } else if (this.formKind === 'push') {
      args.set('image', this.formName); args.set('name', this.imageTag); args.set('repository', this.repositoryName);
      await this.mutate('pushContainerImage', args);
    } else if (this.formKind === 'tag') {
      args.set('sourceImage', this.formName); args.set('targetImage', this.imageTag);
      await this.mutate('tagContainerImage', args);
    } else if (this.formKind === 'save') {
      args.set('images', [this.formName]); args.set('filePath', this.formUrl);
      await this.mutate('saveContainerImage', args);
    } else if (this.formKind === 'load') {
      args.set('filePath', this.formUrl);
      await this.mutate('loadContainerImage', args);
    } else if (this.initialSection === 'networks') {
      args.set('name', this.formName); args.set('driver', this.formDriver);
      if (this.formSubnet.length > 0) args.set('subnet', this.formSubnet);
      if (this.formGateway.length > 0) args.set('gateway', this.formGateway);
      await this.mutate('createContainerNetwork', args);
    } else if (this.initialSection === 'volumes') {
      args.set('name', this.formName); args.set('driver', this.formDriver);
      await this.mutate('createContainerVolume', args);
    } else {
      args.set('name', this.formName); args.set('downloadUrl', this.formUrl);
      args.set('username', this.formUser); args.set('password', this.formPassword);
      await this.mutate('createContainerRepo', args);
    }
  }
  private deleteAsset(asset: HarmonyContainerAsset): void {
    this.getUIContext().showAlertDialog({
      title: this.text('commonDelete'), message: asset.title,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonDelete'), action: (): void => { this.remove(asset); } },
    });
  }
  private async remove(asset: HarmonyContainerAsset): Promise<void> {
    const args = new Map<string, Object | null>();
    let method: string;
    if (this.initialSection === 'images') { method = 'deleteContainerImage'; args.set('id', asset.assetId); }
    else if (this.initialSection === 'networks') { method = 'deleteContainerNetwork'; args.set('name', asset.assetId); }
    else if (this.initialSection === 'volumes') { method = 'deleteContainerVolume'; args.set('name', asset.assetId); }
    else { method = 'deleteContainerRepo'; args.set('id', Number(asset.assetId)); }
    await this.mutate(method, args);
  }
  private menus(): NavigationMenuItem[] {
    const menus: NavigationMenuItem[] = [
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); }, isEnabled: !this.loading },
      { value: this.text('commonCreate'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.openForm(this.initialSection === 'images' ? 'pull' : 'create'); } },
    ];
    if (this.initialSection === 'images') {
      menus.push({ value: this.text('orchestrationImageBuild'), action: (): void => { this.openForm('build'); } });
      menus.push({ value: this.text('orchestrationImageLoad'), action: (): void => { this.openForm('load'); } });
    }
    return menus;
  }
  private detailMenus(asset: HarmonyContainerAsset): NavigationMenuItem[] {
    const menus: NavigationMenuItem[] = [
      { value: this.text('commonDelete'), action: (): void => { this.deleteAsset(asset); } },
    ];
    if (this.initialSection === 'images') menus.unshift({ value: this.text('containerActionPush'), action: (): void => {
      this.openForm('push'); this.formName = asset.title;
    } });
    if (this.initialSection === 'images') {
      menus.push({ value: this.text('containerActionTag'), action: (): void => {
        this.openForm('tag'); this.formName = asset.title;
      } });
      menus.push({ value: this.text('commonSave'), action: (): void => {
        this.openForm('save'); this.formName = asset.title;
      } });
    }
    return menus;
  }
  @Builder
  private listContent() {
    Column({ space: 12 }) {
      if (this.errorMessage.length > 0) { Text(this.errorMessage).fontColor($r('sys.color.font_primary')).padding(16) }
      if (this.loading) { LoadingProgress().width(48).height(48) }
      List({ space: 12 }) {
        ForEach(this.items, (asset: HarmonyContainerAsset): void => {
          ListItem() {
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text(asset.title).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
                Text(asset.subtitle).fontSize(14).fontColor($r('sys.color.font_secondary'))
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.font_secondary')])
            }.width('100%').constraintSize({ minHeight: 72 }).padding(16)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16)
              .onClick((): void => { this.selected = [asset]; this.push('detail'); })
          }
        }, (asset: HarmonyContainerAsset): string => asset.assetId)
        if (this.items.length === 0 && !this.loading) { ListItem() { Text(this.text('commonEmpty')).padding(16) } }
      }.layoutWeight(1).width('100%')
    }.padding(16).width('100%').height('100%')
  }
  private detailFields(asset: HarmonyContainerAsset): string[] {
    if (this.initialSection === 'images') return ['id', 'size', 'createdAt', 'description'];
    if (this.initialSection === 'networks') return ['id', 'driver', 'subnet', 'gateway', 'createdAt'];
    if (this.initialSection === 'volumes') return ['driver', 'mountpoint', 'createdAt'];
    return ['name', 'downloadUrl', 'username'];
  }
  private fieldLabel(key: string): string {
    if (key === 'id') return this.text('containerNetworkIdLabel');
    if (key === 'size') return this.text('commonSize');
    if (key === 'driver') return this.text('containerNetworkDriverLabel');
    if (key === 'subnet') return this.text('containerNetworkSubnetLabel');
    if (key === 'gateway') return this.text('containerNetworkGatewayLabel');
    if (key === 'createdAt') return this.text('containerResourceCreatedAtLabel');
    if (key === 'mountpoint') return this.text('containerVolumeMountpointLabel');
    if (key === 'username') return this.text('commonUsername');
    if (key === 'downloadUrl') return this.text('commonUrl');
    if (key === 'description') return this.text('commonDescription');
    return this.text('commonName');
  }
  private fieldValue(asset: HarmonyContainerAsset, key: string): string {
    const content = asset.record.get(key);
    return content === null || content === undefined ? '—' : `${content}`;
  }
  @Builder
  private detail(asset: HarmonyContainerAsset) {
    List() {
      ForEach(this.detailFields(asset), (key: string): void => {
        ListItem() {
          Column({ space: 4 }) {
            Text(this.fieldLabel(key)).fontSize(14).fontColor($r('sys.color.font_secondary'))
            Text(this.fieldValue(asset, key)).fontSize(16).fontColor($r('sys.color.font_primary'))
              .copyOption(CopyOptions.LocalDevice)
          }.padding(16).alignItems(HorizontalAlign.Start).width('100%')
        }
      }, (key: string): string => key)
    }.width('100%').height('100%')
  }
  @Builder
  private form() {
    Scroll() {
      Column({ space: 12 }) {
        TextInput({ text: this.formName, placeholder: this.text('commonName') }).height(48)
          .onChange((content: string): void => { this.formName = content; })
        if (this.initialSection === 'images') {
          if (this.formKind === 'build') {
            TextArea({ text: this.dockerfile, placeholder: 'Dockerfile' }).height(240).fontFamily('monospace')
              .onChange((content: string): void => { this.dockerfile = content; })
            TextArea({ text: this.buildTags, placeholder: this.text('containerBuildTags') }).height(96)
              .onChange((content: string): void => { this.buildTags = content; })
            TextArea({ text: this.buildArgs, placeholder: this.text('containerBuildArgs') }).height(96)
              .onChange((content: string): void => { this.buildArgs = content; })
          } else if (this.formKind === 'save' || this.formKind === 'load') {
            TextInput({ text: this.formUrl, placeholder: this.text('containerSavePath') }).height(48)
              .onChange((content: string): void => { this.formUrl = content; })
          } else {
            TextInput({ text: this.imageTag, placeholder: this.text('containerTagLabel') }).height(48)
              .onChange((content: string): void => { this.imageTag = content; })
            if (this.formKind === 'push') {
              TextInput({ text: this.repositoryName, placeholder: this.text('containerRepoLabel') }).height(48)
                .onChange((content: string): void => { this.repositoryName = content; })
            }
          }
        } else if (this.initialSection === 'networks' || this.initialSection === 'volumes') {
          TextInput({ text: this.formDriver, placeholder: this.text('commonDriver') }).height(48)
            .onChange((content: string): void => { this.formDriver = content; })
          if (this.initialSection === 'networks') {
            TextInput({ text: this.formSubnet, placeholder: this.text('containerNetworkSubnetLabel') }).height(48)
              .onChange((content: string): void => { this.formSubnet = content; })
            TextInput({ text: this.formGateway, placeholder: this.text('containerNetworkGatewayLabel') }).height(48)
              .onChange((content: string): void => { this.formGateway = content; })
          }
        } else {
          TextInput({ text: this.formUrl, placeholder: this.text('commonUrl') }).height(48)
            .onChange((content: string): void => { this.formUrl = content; })
          TextInput({ text: this.formUser, placeholder: this.text('commonUsername') }).height(48)
            .onChange((content: string): void => { this.formUser = content; })
          TextInput({ text: this.formPassword, placeholder: this.text('commonPassword') }).height(48).type(InputType.Password)
            .onChange((content: string): void => { this.formPassword = content; })
        }
        if (this.errorMessage.length > 0) { Text(this.errorMessage).fontColor($r('sys.color.font_primary')) }
        Button(this.text('commonSave')).height(48).width('100%').enabled(!this.saving)
          .onClick((): void => { this.save(); })
      }.padding(16).width('100%')
    }.width('100%').height('100%')
  }
  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'form') {
      NavDestination() { this.form() }.title(this.text('commonCreate'),
        { barStyle: BarStyle.STANDARD })
    } else {
      ForEach(this.selected, (asset: HarmonyContainerAsset): void => {
        NavDestination() { this.detail(asset) }.title(asset.title,
          { barStyle: BarStyle.STANDARD }).menus(this.detailMenus(asset))
      }, (asset: HarmonyContainerAsset): string => asset.assetId)
    }
  }
  build() {
    Navigation(this.paths) { this.listContent() }.title(this.title(),
      { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini).menus(this.menus()).navDestination(this.destination)
      .hideTitleBar(this.embedded)
      .mode(NavigationMode.Stack).expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary')).width('100%').height('100%')
  }
}
