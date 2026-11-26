import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

class HarmonyIgnoredAppItem {
  readonly installId: number;
  readonly name: string;
  readonly version: string;

  constructor(data: Map<string, Object | null>) {
    this.installId = data.get('id') as number;
    this.name = data.get('name') as string;
    this.version = data.get('version') as string;
  }
}

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyIgnoredAppsPage {
  @State private apps: HarmonyIgnoredAppItem[] = [];
  @State private loading: boolean = false;
  @State private operating: boolean = false;
  @State private errorMessage: string = '';
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  private text(key: string): string { return this.bridge.text(key); }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const reply = await this.bridge.invoke<Array<Map<string, Object | null>>>('getIgnoredAppDetails');
      this.apps = reply.map((data: Map<string, Object | null>): HarmonyIgnoredAppItem => new HarmonyIgnoredAppItem(data));
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async cancelIgnore(app: HarmonyIgnoredAppItem): Promise<void> {
    this.operating = true;
    try {
      const args = new Map<string, Object | null>();
      args.set('appInstallId', app.installId);
      args.set('reason', '');
      args.set('scope', 'version');
      const reply = await this.bridge.invoke<Map<string, Object | null>>('cancelIgnoreAppUpdate', args);
      if (reply.get('success') !== true) throw new Error(reply.get('error') as string);
      await this.load();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message.slice(0, 120) });
    } finally {
      this.operating = false;
    }
  }

  @Builder
  private pageContent() {
    Column({ space: 12 }) {
      if (this.loading) { LoadingProgress().width(40).height(40) }
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontSize(14)
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      }
      List({ space: 8 }) {
        if (this.apps.length === 0 && !this.loading) {
          ListItem() { Text(this.text('appIgnoredUpdatesEmpty')).padding(24).fontSize(14) }
        }
        ForEach(this.apps, (app: HarmonyIgnoredAppItem): void => {
          ListItem() {
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text(app.name).fontSize(16).fontWeight(FontWeight.Medium)
                Text(app.version).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Button(this.text('appIgnoreUpdateCancel'), { buttonStyle: ButtonStyleMode.TEXTUAL })
                .height(48).enabled(!this.operating).onClick((): void => { this.cancelIgnore(app); })
            }.width('100%').padding(16).constraintSize({ minHeight: 72 }).borderRadius(16)
              .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
          }
        }, (app: HarmonyIgnoredAppItem): string => `${app.installId}`)
      }.width('100%').layoutWeight(1)
    }.width('100%').height('100%').padding(16)
  }

  build() {
    NavDestination() { this.pageContent() }
      .title(this.text('appIgnoredUpdatesTitle'), { barStyle: BarStyle.STANDARD })
      .onShown((): void => { this.load(); })
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary'))
  }
}
