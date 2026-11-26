import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyHostFailure, hostText } from './HarmonyHostWidgets';

interface MonitoringMetric {
  key: string;
  label: string;
}

@Component
export struct HarmonyHostMonitoringHistory {
  @State private hoursIndex: number = 0;
  @State private loading: boolean = true;
  @State private error: string = '';
  @State private history: Map<string, Object | null> = new Map<string, Object | null>();
  @State private chartWidth: number = 0;
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly periods: number[] = [1, 6, 24, 168];
  private readonly labels: string[] = [
    'monitorHistoryHour1', 'monitorHistoryHour6', 'monitorHistoryHour24', 'monitorHistoryHour168',
  ];
  private readonly metrics: MonitoringMetric[] = [
    { key: 'cpu', label: 'dashboardCpuUsage' }, { key: 'memory', label: 'dashboardMemoryUsage' },
    { key: 'load', label: 'monitorLoadAverageTitle' }, { key: 'io', label: 'monitorIoDeviceLabel' },
    { key: 'network', label: 'monitorNetworkLabel' },
  ];

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('hours', this.periods[this.hoursIndex]);
      this.history = await this.bridge.invoke<Map<string, Object | null>>('getMonitoringHistory', args);
    } catch (error) {
      this.error = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private points(metric: string): Array<Map<string, Object | null>> {
    const series = this.history.get(metric) as Map<string, Object | null> | undefined;
    return series?.get('points') as Array<Map<string, Object | null>> ?? [];
  }

  private chartCoordinates(metric: string): number[][] {
    const points = this.points(metric);
    if (points.length === 0) return [];
    const series = this.history.get(metric) as Map<string, Object | null>;
    const min = series.get('min') as number;
    const max = series.get('max') as number;
    const timeStart = points[0].get('time') as number;
    const timeEnd = points[points.length - 1].get('time') as number;
    const width = Math.max(this.chartWidth - 8, 1);
    return points.map((point: Map<string, Object | null>): number[] => {
      const time = point.get('time') as number;
      const value = point.get('value') as number;
      return [
        4 + (timeEnd > timeStart ? (time - timeStart) / (timeEnd - timeStart) * width : width / 2),
        max > min ? 110 - (value - min) / (max - min) * 100 : 60,
      ];
    });
  }

  private statistic(metric: string, name: string): string {
    const series = this.history.get(metric) as Map<string, Object | null>;
    const value = series.get(name) as number | undefined;
    return value === undefined ? '—' : value.toFixed(2);
  }

  @Builder
  private series(metric: MonitoringMetric) {
    Column({ space: 8 }) {
      Text(hostText(metric.label)).fontSize(16).fontWeight(FontWeight.Medium)
      if (this.points(metric.key).length < 2) {
        Text(hostText('monitorHistoryEmpty')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      } else {
        Shape() {
          Polyline().points(this.chartCoordinates(metric.key)).fillOpacity(0)
            .stroke($r('sys.color.icon_primary')).strokeWidth(2)
        }
        .width('100%').height(120)
        .onAreaChange((previous: Area, current: Area): void => {
          this.chartWidth = Number(current.width);
        })
        Row({ space: 12 }) {
          Text(hostText('monitorHistoryMinLabel') + ' ' + this.statistic(metric.key, 'min'))
          Text(hostText('monitorHistoryAvgLabel') + ' ' + this.statistic(metric.key, 'avg'))
          Text(hostText('monitorHistoryMaxLabel') + ' ' + this.statistic(metric.key, 'max'))
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)
      }
    }.width('100%').alignItems(HorizontalAlign.Start)
      .padding(16).backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text(hostText('monitorHistoryTitle')).fontSize(16).fontWeight(FontWeight.Medium).layoutWeight(1)
        Select(this.labels.map((key: string): SelectOption => ({ value: hostText(key) })))
          .selected(this.hoursIndex).value(hostText(this.labels[this.hoursIndex])).height(48)
          .enabled(!this.loading).onSelect((index: number): void => {
            this.hoursIndex = index;
            this.load();
          })
      }.width('100%')
      if (this.loading) {
        LoadingProgress().width(36).height(36)
      } else if (this.error.length > 0) {
        HarmonyHostFailure({ message: this.error, onRetry: (): void => { this.load(); } })
      } else {
        ForEach(this.metrics, (metric: MonitoringMetric): void => {
          this.series(metric)
        }, (metric: MonitoringMetric): string => metric.key)
      }
    }.width('100%')
  }
}
