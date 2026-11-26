import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Available } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';
import { HarmonyAppDestinationArgs, HarmonyAppIcon } from './HarmonyAppModels';

class HarmonyAppServiceItem {
  readonly label: string;
  readonly status: string;
  readonly serviceValue: string;

  constructor(data: Map<string, Object | null>) {
    this.label = data.get('label') as string;
    this.status = data.get('status') as string;
    this.serviceValue = data.get('value') as string;
  }
}

class HarmonyAppConnectionItem {
  readonly itemKey: string;
  readonly content: string;

  constructor(itemKey: string, content: Object | null) {
    this.itemKey = itemKey;
    this.content = content === null ? '—' : content.toString();
  }
}

class HarmonyAppUpdateVersion {
  readonly detailId: number;
  readonly version: string;

  constructor(data: Map<string, Object | null>) {
    this.detailId = data.get('detailId') as number;
    this.version = data.get('version') as string;
  }
}

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyInstalledAppPage {
  @Require @Prop installId: number;
  @State private detail: Map<string, Object | null> = new Map<string, Object | null>();
  @State private services: HarmonyAppServiceItem[] = [];
  @State private updateVersions: HarmonyAppUpdateVersion[] = [];
  @State private updateIndex: number = 0;
  @State private loading: boolean = false;
  @State private operating: boolean = false;
  @State private errorMessage: string = '';
  @State private servicesError: string = '';
  @State private versionsError: string = '';
  @State private sheetVisible: boolean = false;
  @State private sheetType: string = 'connection';
  @State private connections: HarmonyAppConnectionItem[] = [];
  private paths: NavPathStack = new NavPathStack();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private info(key: string): string {
    const content = this.detail.get(key);
    return content === null || content === undefined || content === '' ? '—' : content.toString();
  }

  private args(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('installId', this.installId);
    return args;
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      this.detail = await this.bridge.invoke<Map<string, Object | null>>('getAppInstallInfo', this.args());
      await Promise.all([this.loadServices(), this.loadVersions()]);
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async loadServices(): Promise<void> {
    this.servicesError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('key', this.detail.get('appKey') as string);
      const reply = await this.bridge.invoke<Array<Map<string, Object | null>>>('getAppServices', args);
      this.services = reply.map((entry: Map<string, Object | null>): HarmonyAppServiceItem =>
        new HarmonyAppServiceItem(entry));
    } catch (error) {
      this.servicesError = (error as Error).message;
    }
  }

  private async loadVersions(): Promise<void> {
    this.versionsError = '';
    try {
      const reply = await this.bridge.invoke<Array<Map<string, Object | null>>>('getAppUpdateVersions', this.args());
      this.updateVersions = reply.map((entry: Map<string, Object | null>): HarmonyAppUpdateVersion =>
        new HarmonyAppUpdateVersion(entry));
      this.updateIndex = 0;
    } catch (error) {
      this.versionsError = (error as Error).message;
    }
  }

  private async operate(method: string, args: Map<string, Object | null> = this.args()): Promise<void> {
    this.operating = true;
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.getUIContext().getPromptAction().showToast({ message: this.text('appOperateSuccess') });
      if (method === 'uninstallHarmonyApp') {
        this.paths.pop();
      } else {
        await this.load();
      }
    } catch (error) {
      this.showError((error as Error).message);
    } finally {
      this.operating = false;
    }
  }

  private confirmUpgrade(): void {
    const update = this.updateVersions[this.updateIndex];
    this.getUIContext().showAlertDialog({
      title: this.text('appUpdateTitle'),
      message: this.text('appUpdateConfirm').replace('{app}', this.info('name')).replace('{version}', update.version),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('appUpdate'), action: (): void => {
        const args = this.args();
        args.set('detailId', update.detailId);
        args.set('pullImage', true);
        this.operate('upgradeHarmonyApp', args);
      } },
    });
  }

  private showError(message: string): void {
    this.getUIContext().showAlertDialog({
      title: this.text('commonOperationFailed'),
      message: message,
      confirm: { value: this.text('commonClose'), action: (): void => {} },
    });
  }

  private confirmOperation(method: string, titleKey: string): void {
    this.getUIContext().showAlertDialog({
      title: this.text(titleKey),
      message: this.info('name'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.operate(method); } },
    });
  }

  private async confirmUninstall(): Promise<void> {
    this.operating = true;
    try {
      const check = await this.bridge.invoke<Map<string, Object | null>>('checkAppUninstall', this.args());
      const details: string[] = [];
      const resources = check.get('items') as Map<string, Object | null>[] | undefined;
      resources?.forEach((resource: Map<string, Object | null>): void => {
        details.push(`${resource.get('type')} · ${resource.get('name')}`);
      });
      this.getUIContext().showAlertDialog({
        title: this.text('appActionUninstall'),
        message: details.length > 0 ? details.join('\n') : this.text('appUninstallConfirm'),
        primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
        secondaryButton: details.length > 0 ? undefined :
          { value: this.text('commonConfirm'), action: (): void => { this.operate('uninstallHarmonyApp'); } },
      });
    } catch (error) {
      this.showError((error as Error).message);
    } finally {
      this.operating = false;
    }
  }

  private async loadConnection(): Promise<void> {
    this.operating = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('name', this.detail.get('name') as string);
      args.set('key', this.detail.get('appKey') as string);
      const result = await this.bridge.invoke<Map<string, Object | null>>('getAppConnInfo', args);
      const entries: HarmonyAppConnectionItem[] = [];
      result.forEach((content: Object | null, itemKey: string): void => {
        entries.push(new HarmonyAppConnectionItem(itemKey, content));
      });
      this.connections = entries;
      this.sheetType = 'connection';
      this.sheetVisible = true;
    } catch (error) {
      this.showError((error as Error).message);
    } finally {
      this.operating = false;
    }
  }

  private async openContainer(): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('name', this.detail.get('container') as string);
      await this.bridge.openNativePage('/container-detail', args);
    } catch (error) {
      this.showError((error as Error).message);
    }
  }

  private async openWeb(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({ action: 'ohos.want.action.viewData', uri: this.detail.get('webUI') as string,
        entities: ['entity.system.browsable'] });
    } catch (error) {
      this.showError((error as Error).message);
    }
  }

  private async saveIgnore(): Promise<void> {
    this.operating = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('appId', this.detail.get('appId') as number);
      args.set('detailId', this.updateVersions[this.updateIndex].detailId);
      args.set('scope', 'version');
      const result = await this.bridge.invoke<Map<string, Object | null>>('ignoreAppUpdate', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.sheetVisible = false;
      await this.load();
    } catch (error) {
      this.showError((error as Error).message);
    } finally {
      this.operating = false;
    }
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: this.text('commonRefresh'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); } },
      { value: this.text('appActionStart'), isEnabled: !this.operating,
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.play_video')),
        action: (): void => { this.confirmOperation('startApp', 'appActionStart'); } },
      { value: this.text('appActionStop'), isEnabled: !this.operating,
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.pause')),
        action: (): void => { this.confirmOperation('stopApp', 'appActionStop'); } },
      { value: this.text('appActionRestart'), isEnabled: !this.operating,
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.confirmOperation('restartApp', 'appActionRestart'); } },
      { value: this.text('appActionUninstall'), isEnabled: !this.operating,
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.trash')),
        action: (): void => { this.confirmUninstall(); } },
    ];
  }

  @Builder
  private infoRow(titleKey: string, content: string) {
    Row({ space: 12 }) {
      Text(this.text(titleKey)).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(content).fontSize(16).textAlign(TextAlign.End).layoutWeight(1).copyOption(CopyOptions.LocalDevice)
    }
    .width('100%').constraintSize({ minHeight: 48 })
  }

  @Builder
  private connectionSheet() {
    Scroll() {
      Column({ space: 12 }) {
        Text(this.text('appConnInfo')).fontSize(20).fontWeight(FontWeight.Medium)
        ForEach(this.connections, (entry: HarmonyAppConnectionItem): void => {
          Column({ space: 4 }) {
            Text(entry.itemKey).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
            Text(entry.content).fontSize(16).copyOption(CopyOptions.LocalDevice)
          }.width('100%').alignItems(HorizontalAlign.Start)
        }, (entry: HarmonyAppConnectionItem): string => entry.itemKey)
      }.padding(24).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private ignoreSheet() {
    Column({ space: 16 }) {
      Text(this.text('appIgnoreUpdate')).fontSize(20).fontWeight(FontWeight.Medium)
      Text(this.updateVersions[this.updateIndex]?.version ?? '').fontSize(16).width('100%')
      Button(this.text('commonConfirm')).width('100%').height(48).enabled(!this.operating)
        .onClick((): void => { this.saveIgnore(); })
    }.padding(24).width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder
  private activeSheet() {
    if (this.sheetType === 'connection') {
      this.connectionSheet()
    } else {
      this.ignoreSheet()
    }
  }

  @Builder
  private bodyContent() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) { LoadingProgress().width(40).height(40) }
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontSize(14)
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }
        if (this.detail.size > 0) {
          HarmonyAppIcon({ source: this.info('icon'), appKey: this.info('appKey'), iconSize: 64 })
          Column() {
            this.infoRow('appInfoName', this.info('name'))
            Divider()
            this.infoRow('appInfoVersion', this.info('version'))
            Divider()
            this.infoRow('appInfoStatus', this.info('status'))
            Divider()
            this.infoRow('appInstallContainerName', this.info('container'))
            Divider()
            this.infoRow('appInfoCreated', this.info('createdAt'))
            Divider()
            this.infoRow('appInstallPortHost', this.info('httpPort'))
          }.padding({ left: 16, right: 16 }).borderRadius(16)
            .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).width('100%')
          Button(this.text('appConnInfo'), { buttonStyle: ButtonStyleMode.NORMAL })
            .height(48).width('100%').enabled(!this.operating)
            .onClick((): void => { this.loadConnection(); })
          Button(this.text('appTabConfig'), { buttonStyle: ButtonStyleMode.NORMAL })
            .height(48).width('100%')
            .onClick((): void => { this.paths.pushPath({ name: 'config', param: new HarmonyAppDestinationArgs(this.installId) }); })
          if (this.info('container') !== '—') {
            Button(this.text('containerDetailTitle'), { buttonStyle: ButtonStyleMode.NORMAL })
              .height(48).width('100%').onClick((): void => { this.openContainer(); })
          }
          if (this.info('webUI') !== '—') {
            Button(this.text('appActionWeb'), { buttonStyle: ButtonStyleMode.NORMAL })
              .height(48).width('100%').onClick((): void => { this.openWeb(); })
          }
          Text(this.text('appServiceList')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
          if (this.servicesError.length > 0) {
            Text(this.servicesError).fontSize(14)
            Button(this.text('commonRetry')).height(48).onClick((): void => { this.loadServices(); })
          }
          ForEach(this.services, (service: HarmonyAppServiceItem): void => {
            Column({ space: 4 }) {
              Text(service.label).fontSize(16).fontWeight(FontWeight.Medium)
              Text(`${service.serviceValue} · ${service.status}`).fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }.width('100%').padding(16).alignItems(HorizontalAlign.Start).borderRadius(16)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
          }, (service: HarmonyAppServiceItem): string => `${service.label}:${service.serviceValue}`)
          if (this.versionsError.length > 0) { Text(this.versionsError).fontSize(14) }
          if (this.updateVersions.length > 0) {
            Text(this.text('appCatalogVersionsLabel')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
            Select(this.updateVersions.map((entry: HarmonyAppUpdateVersion): SelectOption => ({ value: entry.version })))
              .selected(this.updateIndex).value(this.updateVersions[this.updateIndex].version)
              .height(48).width('100%')
              .onSelect((index: number): void => { this.updateIndex = index; })
            Button(this.text('appUpdate')).height(48).width('100%').enabled(!this.operating)
              .onClick((): void => { this.confirmUpgrade(); })
            Button(this.text('appIgnoreUpdate'), { buttonStyle: ButtonStyleMode.TEXTUAL })
              .height(48).width('100%').enabled(this.detail.get('appId') !== null && this.detail.get('appId') !== undefined)
              .onClick((): void => {
                this.sheetType = 'ignore'; this.sheetVisible = true;
              })
          }
        }
      }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  build() {
    NavDestination() { this.bodyContent() }
      .title(this.text('appDetailTitle'), { barStyle: BarStyle.STANDARD })
      .menus(this.menus())
      .onReady((context: NavDestinationContext): void => { this.paths = context.pathStack; })
      .onShown((): void => { this.load(); })
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
      .bindSheet($$this.sheetVisible, this.activeSheet, { height: SheetSize.MEDIUM, showClose: true, systemMaterial: sheetMaterial })
  }
}
