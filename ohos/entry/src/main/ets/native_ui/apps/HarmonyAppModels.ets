import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

/**
 * 应用图标向面板取回的 data URL 缓存。
 *
 * 面板 `/apps/icon/:key` 直接返回 PNG 字节，比访问上游 CDN 稳定，
 * 同一 appKey 在列表、详情与目录页之间复用同一份结果。
 */
const appIconCache: Map<string, string> = new Map<string, string>();

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
  @State private resolvedKey: string = '';

  aboutToAppear(): void {
    this.resolve();
  }

  aboutToReuse(params: Record<string, Object>): void {
    this.source = params.source as string ?? '';
    this.appKey = params.appKey as string ?? '';
    this.iconSize = params.iconSize as number ?? 44;
    this.resolve();
  }

  private async resolve(): Promise<void> {
    const key = this.appKey;
    if (key.length === 0 || key === this.resolvedKey) {
      return;
    }
    const cached = appIconCache.get(key);
    if (cached !== undefined) {
      this.resolvedKey = key;
      this.imageSource = cached;
      return;
    }
    const args = new Map<string, Object | null>();
    args.set('appKey', key);
    try {
      const source = await HarmonyNativeBridge.instance.invoke<string | null>('getHarmonyAppIcon', args);
      if (source !== null && source.length > 0) {
        appIconCache.set(key, source);
        this.resolvedKey = key;
        this.imageSource = source;
        return;
      }
    } catch (error) {
      // 面板取图失败时退回上游地址。
    }
    if (this.source.startsWith('https://') || this.source.startsWith('http://')) {
      this.resolvedKey = key;
      this.imageSource = this.source;
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
