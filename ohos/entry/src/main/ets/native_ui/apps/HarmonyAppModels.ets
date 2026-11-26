import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

/**
 * 应用图标地址缓存。
 *
 * 面板 `/apps/icon/:key` 对远程图标返回 302 跳转到图标 CDN，逐行单独请求时
 * 先渲染的行只能先显示默认图标。这里在列表加载后批量预取，同一 appKey
 * 在列表、详情与目录页之间复用同一份结果。
 */
const appIconCache: Map<string, string> = new Map<string, string>();

/** 上游 `isRemoteAppIcon` 的判定：http(s) 且没有空白字符。 */
function isRemoteIcon(icon: string): boolean {
  if (!(icon.startsWith('https://') || icon.startsWith('http://'))) {
    return false;
  }
  for (let index = 0; index < icon.length; index++) {
    const code = icon.charCodeAt(index);
    if (code <= 32 || code === 92) {
      return false;
    }
  }
  return true;
}

/**
 * 批量预取图标，写入内存缓存。
 *
 * 列表进入时调用一次，让所有行在渲染时就能取到结果；未取回的键保持
 * 默认图标，不影响后续单独重试。
 */
export async function prefetchAppIcons(appKeys: string[]): Promise<void> {
  const missing: string[] = appKeys.filter((key: string): boolean =>
    key.length > 0 && !appIconCache.has(key));
  if (missing.length === 0) {
    return;
  }
  const args = new Map<string, Object | null>();
  args.set('appKeys', missing);
  try {
    const icons = await HarmonyNativeBridge.instance
      .invoke<Map<string, string> | null>('getHarmonyAppIcons', args);
    if (icons === null) {
      return;
    }
    icons.forEach((source: string, key: string): void => { appIconCache.set(key, source); });
  } catch (error) {
    // 预取失败时保持默认图标。
  }
}

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

  private apply(source: string): void {
    this.resolvedKey = `${this.appKey}|${source}`;
    this.imageSource = source;
  }

  private async resolve(): Promise<void> {
    const identity = `${this.appKey}|${this.source}`;
    if (identity === this.resolvedKey) {
      return;
    }
    const cached = appIconCache.get(this.appKey);
    if (cached !== undefined) {
      this.resolvedKey = identity;
      this.imageSource = cached;
      return;
    }
    if (this.appKey.length > 0) {
      const args = new Map<string, Object | null>();
      args.set('appKey', this.appKey);
      try {
        const source = await HarmonyNativeBridge.instance.invoke<string | null>('getHarmonyAppIcon', args);
        if (source !== null && source.length > 0) {
          appIconCache.set(this.appKey, source);
          this.apply(source);
          return;
        }
      } catch (error) {
        // 面板取图失败时退回上游地址。
      }
    }
    if (isRemoteIcon(this.source)) {
      this.apply(this.source);
    }
  }

  build() {
    if (this.imageSource.length > 0) {
      Image(this.imageSource).width(this.iconSize).height(this.iconSize).objectFit(ImageFit.Contain)
        .borderRadius(12).syncLoad(false).onError((): void => { this.imageSource = ''; })
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
