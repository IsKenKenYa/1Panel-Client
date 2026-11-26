import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

export class HarmonyDatabaseItem {
  readonly data: Map<string, Object | null>;
  readonly scope: string;
  readonly databaseId: number | null;
  readonly name: string;
  readonly engine: string;
  readonly source: string;
  readonly lookupName: string;

  constructor(data: Map<string, Object | null>) {
    this.data = data;
    this.scope = data.get('scope') as string;
    this.databaseId = data.get('id') as number | null;
    this.name = data.get('name') as string;
    this.engine = data.get('engine') as string;
    this.source = data.get('source') as string;
    this.lookupName = data.get('lookupName') as string;
  }

  text(field: string): string {
    const content = this.data.get(field);
    return content === null || content === undefined ? '' : `${content}`;
  }

  request(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('item', this.data);
    return args;
  }

  instanceRequest(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('type', this.engine);
    args.set('name', this.lookupName);
    args.set('database', this.lookupName);
    return args;
  }
}

export class HarmonyDatabaseMetric {
  readonly name: string;
  readonly content: string;

  constructor(name: string, content: string) {
    this.name = name;
    this.content = content;
  }
}

export function harmonyDatabaseMetrics(data: Map<string, Object | null>): HarmonyDatabaseMetric[] {
  const rows: HarmonyDatabaseMetric[] = [];
  data.forEach((content: Object | null, name: string): void => {
    if (content !== null && content !== undefined && typeof content !== 'object') {
      rows.push(new HarmonyDatabaseMetric(name, `${content}`));
    }
  });
  return rows;
}

export function harmonyDatabaseText(key: string): string {
  return HarmonyNativeBridge.instance.text(key);
}

@Component
export struct HarmonyDatabaseMetricRows {
  @Prop rows: HarmonyDatabaseMetric[] = [];

  build() {
    Column() {
      ForEach(this.rows, (metric: HarmonyDatabaseMetric): void => {
        Row({ space: 12 }) {
          Text(metric.name)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .layoutWeight(1)
          Text(metric.content)
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .textAlign(TextAlign.End)
            .layoutWeight(1)
            .copyOption(CopyOptions.InApp)
        }
        .width('100%')
        .constraintSize({ minHeight: 48 })
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      }, (metric: HarmonyDatabaseMetric): string => metric.name)
    }
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
    .borderRadius(16)
  }
}
