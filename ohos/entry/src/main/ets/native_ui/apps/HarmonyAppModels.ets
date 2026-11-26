import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

export class HarmonyInstalledApp {
  readonly installId: number;
  readonly name: string;
  readonly version: string;
  readonly status: string;
  readonly icon: string;
  readonly appKey: string;

  constructor(data: Map<string, Object | null>) {
    this.installId = data.get('installId') as number;
    this.name = data.get('name') as string;
    this.version = data.get('version') as string;
    this.status = data.get('status') as string;
    this.icon = data.get('icon') as string;
    this.appKey = data.get('appKey') as string | null ?? '';
  }
}

@Component
export struct HarmonyAppIcon {
  @Prop source: string = '';
  @Prop appKey: string = '';
  @Prop iconSize: number = 44;
  @State private imageSource: string = '';

  aboutToAppear(): void {
    if (this.source.startsWith('https://') || this.source.startsWith('http://')) {
      this.imageSource = this.source;
    } else if (this.appKey.length > 0) {
      const args = new Map<string, Object | null>();
      args.set('appKey', this.appKey);
      HarmonyNativeBridge.instance.invoke<string | null>('getHarmonyAppIcon', args)
        .then((source: string | null): void => { this.imageSource = source ?? ''; })
        .catch((): void => {});
    }
  }

  build() {
    if (this.imageSource.length > 0) {
      Image(this.imageSource).width(this.iconSize).height(this.iconSize).objectFit(ImageFit.Contain)
        .borderRadius(12).onError((): void => { this.imageSource = ''; })
    } else {
      Stack() {
        SymbolGlyph($r('sys.symbol.square_grid_2x2'))
          .fontSize(this.iconSize / 2).fontColor([$r('sys.color.ohos_id_color_text_secondary')])
      }.width(this.iconSize).height(this.iconSize).borderRadius(12)
        .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    }
  }
}

export class HarmonyCatalogApp {
  readonly appId: number;
  readonly appKey: string;
  readonly name: string;
  readonly appType: string;
  readonly versions: string[];
  readonly installed: boolean;
  readonly description: string;
  readonly icon: string;

  constructor(data: Map<string, Object | null>) {
    this.appId = data.get('id') as number;
    this.appKey = data.get('key') as string;
    this.name = data.get('name') as string;
    this.appType = data.get('type') as string;
    this.versions = data.get('versions') as string[] | null ?? [];
    this.installed = data.get('installed') === true;
    this.description = data.get('description') as string | null ?? '';
    this.icon = data.get('icon') as string;
  }
}

export class HarmonyAppDestinationArgs {
  installId?: number;
  catalog?: HarmonyCatalogApp;

  constructor(installId?: number, catalog?: HarmonyCatalogApp) {
    this.installId = installId;
    this.catalog = catalog;
  }
}
