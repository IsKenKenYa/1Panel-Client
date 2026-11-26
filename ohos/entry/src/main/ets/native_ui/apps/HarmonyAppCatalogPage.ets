import { common } from '@kit.AbilityKit';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyAppDestinationArgs, HarmonyAppIcon, HarmonyCatalogApp } from './HarmonyAppModels';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyAppCatalogPage {
  @Require @Prop app: HarmonyCatalogApp;
  @State private detail: Map<string, Object | null> = new Map<string, Object | null>();
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  private paths: NavPathStack = new NavPathStack();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private content(key: string): string {
    const content = this.detail.get(key);
    return content === null || content === undefined ? '' : content.toString();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('key', this.app.appKey);
      this.detail = await this.bridge.invoke<Map<string, Object | null>>('getAppDetailByKey', args);
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private installApp(): void {
    const app = this.detail.size > 0 ? new HarmonyCatalogApp(this.detail) : this.app;
    this.paths.pushPath({ name: 'install', param: new HarmonyAppDestinationArgs(undefined, app) });
  }

  private versions(): string[] {
    return this.detail.get('versions') as string[] | null ?? this.app.versions;
  }

  private async openWebsite(field: string): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        uri: this.content(field),
        entities: ['entity.system.browsable'],
      });
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    }
  }

  @Builder
  private infoRow(titleKey: string, content: string) {
    Row({ space: 12 }) {
      Text(this.text(titleKey)).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
      Text(content).fontSize(16).layoutWeight(1).textAlign(TextAlign.End)
    }.width('100%').constraintSize({ minHeight: 48 })
  }

  @Builder
  private pageContent() {
    Scroll() {
      Column({ space: 16 }) {
        if (this.loading) { LoadingProgress().width(40).height(40) }
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontSize(14)
          Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
        }
        Row({ space: 16 }) {
          HarmonyAppIcon({ source: this.app.icon, appKey: this.app.appKey, iconSize: 64 })
          Column({ space: 4 }) {
            Text(this.app.name).fontSize(20).fontWeight(FontWeight.Medium)
            Text(this.app.appKey).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
            if (this.app.installed) {
              Text(this.text('appStoreInstalled')).fontSize(14).fontColor($r('sys.color.ohos_id_color_primary'))
            }
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        }.width('100%')
        Text(this.app.description).fontSize(16).lineHeight(24).width('100%')
        Column() {
          this.infoRow('appCatalogArchLabel', this.content('architectures'))
          Divider()
          this.infoRow('appCatalogMemoryLabel', `${this.content('memoryRequired')} MB`)
          Divider()
          this.infoRow('appCatalogGpuLabel', this.detail.get('gpuSupport') === true ? this.text('commonYes') : this.text('commonNo'))
        }.padding({ left: 16, right: 16 }).width('100%').borderRadius(16)
          .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
        if (this.versions().length > 0) {
          Button(this.text('appStoreInstall')).height(48).width('100%')
            .id('harmony.apps.install').onClick((): void => { this.installApp(); })
          Text(this.text('appCatalogVersionsLabel')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
          Text(this.versions().join(' · ')).fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary')).width('100%')
        }
        if (this.content('website').length > 0) {
          Button(this.text('appCatalogHomepageLabel'), { buttonStyle: ButtonStyleMode.NORMAL })
            .height(48).width('100%').onClick((): void => { this.openWebsite('website'); })
        }
        if (this.content('github').length > 0) {
          Button(this.text('appCatalogSourceLabel'), { buttonStyle: ButtonStyleMode.NORMAL })
            .height(48).width('100%').onClick((): void => { this.openWebsite('github'); })
        }
        Text(this.text('appCatalogReadmeTitle')).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
        if (this.content('readMe').length > 0) {
          Text(this.content('readMe')).fontSize(14).lineHeight(22)
            .copyOption(CopyOptions.LocalDevice).width('100%')
        } else if (!this.loading) {
          Text(this.text('appCatalogReadmeEmpty')).fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        }
      }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  build() {
    NavDestination() { this.pageContent() }
      .title(this.text('appDetailTitle'), { barStyle: BarStyle.STANDARD })
      .onReady((context: NavDestinationContext): void => { this.paths = context.pathStack; this.load(); })
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
  }
}
