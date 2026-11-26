import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { handleActivationKey } from '../HarmonyInteractionUtils';
import { HarmonyCronjobForm } from './HarmonyCronjobForm';
import { automationText, automationString, automationWrite, automationMoreSymbol, automationEditSymbol } from './HarmonyAutomationUI';

@Component
export struct HarmonyCronjobsPage {
  @Prop initialRoute: string = '/cronjobs';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @State private jobs: Map<string, Object | null>[] = [];
  @State private records: Map<string, Object | null>[] = [];
  @State private selectedJob: Map<string, Object | null> = new Map<string, Object | null>();
  @State private selectedIds: number[] = [];
  @State private keyword: string = '';
  @State private currentPage: number = 1;
  @State private recordPage: number = 1;
  @State private total: number = 0;
  @State private recordTotal: number = 0;
  @State private loading: boolean = false;
  @State private failure: string = '';
  @State private editingId: number = -1;
  @State private logContent: string = '';
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.load();
    if (this.initialRoute === '/cronjobs/form') {
      this.editingId = this.routeArguments.get('id') as number ?? -1;
      this.push('cronjob-form');
    } else if (this.initialRoute === '/cronjobs/records') {
      this.selectedJob.set('id', this.routeArguments.get('cronjobId') ?? this.routeArguments.get('id') as number);
      this.showRecords();
    }
  }

  private push(name: string): void { const path: NavPathInfo = { name: name }; this.paths.pushPath(path); }

  private argsForJob(): Map<string, Object | null> {
    const args = new Map<string, Object | null>(); args.set('id', this.selectedJob.get('id') as number); return args;
  }

  private async load(): Promise<void> {
    this.loading = true; this.failure = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('page', this.currentPage); args.set('pageSize', 50); args.set('info', this.keyword);
      const result = await this.bridge.invoke<Map<string, Object | null>>('searchNativeCronjobs', args);
      this.jobs = result.get('items') as Map<string, Object | null>[]; this.total = result.get('total') as number;
      this.selectedIds = [];
    } catch (error) { this.failure = (error as Error).message; }
    finally { this.loading = false; }
  }

  private edit(job?: Map<string, Object | null>): void {
    this.editingId = job === undefined ? -1 : job.get('id') as number;
    this.push('cronjob-form');
  }

  private detail(job: Map<string, Object | null>): void { this.selectedJob = job; this.push('cronjob-detail'); }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message.slice(0, 120) });
  }

  private confirmAction(method: string, titleKey: string, job: Map<string, Object | null>): void {
    this.getUIContext().showAlertDialog({
      title: automationText(titleKey), message: automationString(job, 'name'),
      primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
      secondaryButton: { value: automationText('commonConfirm'), action: (): void => { this.operate(method, job); } },
    });
  }

  private async operate(method: string, job: Map<string, Object | null>): Promise<void> {
    try {
      const args = new Map<string, Object | null>(); args.set('id', job.get('id') as number);
      args.set('currentStatus', job.get('status') as string);
      await automationWrite(method, args); await this.load();
      this.toast(automationText('commonOperationSuccess'));
    } catch (error) { this.toast((error as Error).message); }
  }

  private async loadRecords(): Promise<void> {
    this.loading = true; this.failure = '';
    try {
      const args = this.argsForJob(); args.set('page', this.recordPage); args.set('pageSize', 50);
      const result = await this.bridge.invoke<Map<string, Object | null>>('getCronJobRecords', args);
      this.records = result.get('items') as Map<string, Object | null>[]; this.recordTotal = result.get('total') as number;
    } catch (error) { this.failure = (error as Error).message; }
    finally { this.loading = false; }
  }

  private showRecords(): void { this.recordPage = 1; this.loadRecords(); this.push('cronjob-records'); }

  private async openLog(record: Map<string, Object | null>): Promise<void> {
    try {
      const args = new Map<string, Object | null>(); args.set('id', record.get('id') as number);
      this.logContent = await this.bridge.invoke<string>('getNativeCronjobRecordLog', args);
      this.push('cronjob-log');
    } catch (error) { this.toast((error as Error).message); }
  }

  private cleanRecords(): void {
    this.getUIContext().showAlertDialog({
      title: automationText('cronjobRecordsCleanAction'), message: automationText('cronjobRecordsCleanConfirm'),
      primaryButton: { value: automationText('commonCancel'), action: (): void => {} },
      secondaryButton: { value: automationText('commonConfirm'), action: (): void => { this.applyCleanRecords(); } },
    });
  }

  private async applyCleanRecords(): Promise<void> {
    try {
      const args = this.argsForJob();
      args.set('cleanData', true);
      args.set('cleanRemoteData', false);
      await automationWrite('cleanNativeCronjobRecords', args); await this.loadRecords();
    } catch (error) { this.toast((error as Error).message); }
  }

  private async importJobs(): Promise<void> {
    try { await automationWrite('importNativeCronjobs'); await this.load(); }
    catch (error) { this.toast((error as Error).message); }
  }

  private async exportJobs(): Promise<void> {
    try {
      const args = new Map<string, Object | null>(); args.set('ids', this.selectedIds);
      await automationWrite('exportNativeCronjobs', args);
    } catch (error) { this.toast((error as Error).message); }
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: automationText('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')), action: (): void => { this.load(); } },
      { value: automationText('commonAdd'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')), action: (): void => { this.edit(); } },
      { value: automationText('commonImport'), action: (): void => { this.importJobs(); } },
      { value: automationText('commonExport'), isEnabled: this.selectedIds.length > 0,
        action: (): void => { this.exportJobs(); } },
    ];
  }

  @Builder
  private jobMenu(job: Map<string, Object | null>) {
    Menu() {
      MenuItem({ content: automationText('commonEdit'), symbolStartIcon: new SymbolGlyphModifier(automationEditSymbol) })
        .onClick((): void => { this.edit(job); })
      MenuItem({ content: automationText('cronjobsHandleOnceAction'), symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.play')) })
        .onClick((): void => { this.confirmAction('handleCronJobOnce', 'cronjobsHandleOnceConfirm', job); })
      MenuItem({ content: automationText('cronjobsStopAction') })
        .onClick((): void => { this.confirmAction('stopNativeCronjob', 'cronjobsStopConfirm', job); })
      MenuItem({ content: automationText(job.get('status') === 'Enable' ? 'cronjobsDisableAction' : 'cronjobsEnableAction') })
        .onClick((): void => { this.confirmAction('toggleCronJobStatus', 'cronjobsUpdateStatusConfirm', job); })
      MenuItem({ content: automationText('commonDelete'), symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash')) })
        .onClick((): void => { this.confirmAction('deleteNativeCronjob', 'hostCronJobsDeleteTaskTitle', job); })
    }
  }

  @Builder
  private body() {
    Column({ space: 12 }) {
      Search({ value: this.keyword, placeholder: automationText('cronjobsSearchHint') })
        .onChange((content: string): void => { this.keyword = content; })
        .onSubmit((): void => { this.currentPage = 1; this.load(); })
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else if (this.failure.length > 0) {
        Text(this.failure).fontSize(14)
        Button(automationText('commonRetry')).height(48).onClick((): void => { this.load(); })
      } else {
        List({ space: 12 }) {
          if (this.jobs.length === 0) { ListItem() { Text(automationText('cronjobsEmptyTitle')).padding(24) } }
          ForEach(this.jobs, (job: Map<string, Object | null>): void => {
            ListItem() {
              Row({ space: 12 }) {
                Checkbox().select(this.selectedIds.includes(job.get('id') as number)).padding(12)
                  .onChange((selected: boolean): void => {
                    const id = job.get('id') as number;
                    this.selectedIds = selected ? this.selectedIds.concat([id]) : this.selectedIds.filter((entry: number): boolean => entry !== id);
                  })
                Column({ space: 2 }) {
                  Text(automationString(job, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
                  Text(automationString(job, 'spec')).fontSize(14).fontFamily('monospace')
                  Text(`${automationString(job, 'status')} · ${automationString(job, 'lastRecordStatus')}`).fontSize(14)
                    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                }.alignItems(HorizontalAlign.Start).layoutWeight(1).onClick((): void => { this.detail(job); })
                Button() { SymbolGlyph(automationMoreSymbol).fontSize(24) }
                  .height(48).width(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                  .accessibilityText(automationText('commonMore'))
                  .bindMenu(this.jobMenu(job), { systemMaterial: menuMaterial })
              }.padding({ top: 8, bottom: 8, right: 8 }).constraintSize({ minHeight: 80 })
              .width('100%').borderRadius(16).backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
              .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
                event,
                (): void => { this.detail(job); },
              ))
              .focusable(true)
              .focusOnTouch(true)
              .focusBox({ margin: LengthMetrics.vp(2) })
              .hoverEffect(HoverEffect.Highlight)
            }
          }, (job: Map<string, Object | null>): string => `${job.get('id')}`)
        }.layoutWeight(1).width('100%')
        Row({ space: 16 }) {
          Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
            .height(48).width(48).enabled(this.currentPage > 1)
            .accessibilityText(automationText('commonPreviousPage'))
            .onClick((): void => { this.currentPage--; this.load(); })
          Text(`${this.currentPage}`).fontSize(14)
          Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }
            .height(48).width(48).enabled(this.currentPage * 50 < this.total)
            .accessibilityText(automationText('commonNextPage'))
            .onClick((): void => { this.currentPage++; this.load(); })
        }
      }
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private recordBody() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button(automationText('commonRefresh')).height(48).onClick((): void => { this.loadRecords(); })
        Button(automationText('cronjobRecordsCleanAction')).height(48).onClick((): void => { this.cleanRecords(); })
      }
      if (this.failure.length > 0) { Text(this.failure).fontSize(14) }
      if (this.loading) { LoadingProgress().width(48).height(48) }
      List({ space: 12 }) {
        ForEach(this.records, (record: Map<string, Object | null>): void => {
          ListItem() {
            Column({ space: 2 }) {
              Text(automationString(record, 'startTime')).fontSize(16).fontWeight(FontWeight.Medium)
              Text(automationString(record, 'status')).fontSize(14)
              Text(automationString(record, 'message')).fontSize(14).maxLines(2)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }.padding(16).constraintSize({ minHeight: 72 }).width('100%').alignItems(HorizontalAlign.Start)
            .borderRadius(16).backgroundColor($r('sys.color.ohos_id_color_list_card_bg'))
            .onClick((): void => { this.openLog(record); })
            .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
              event,
              (): void => { this.openLog(record); },
            ))
            .focusable(true)
            .focusOnTouch(true)
            .focusBox({ margin: LengthMetrics.vp(2) })
            .hoverEffect(HoverEffect.Highlight)
          }
        }, (record: Map<string, Object | null>): string => `${record.get('id')}`)
      }.layoutWeight(1).width('100%')
      Row({ space: 16 }) {
        Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }.width(48).height(48).enabled(this.recordPage > 1)
          .accessibilityText(automationText('commonPreviousPage'))
          .onClick((): void => { this.recordPage--; this.loadRecords(); })
        Text(`${this.recordPage}`).fontSize(14)
        Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }.width(48).height(48).enabled(this.recordPage * 50 < this.recordTotal)
          .accessibilityText(automationText('commonNextPage'))
          .onClick((): void => { this.recordPage++; this.loadRecords(); })
      }
    }.padding(16).height('100%').width('100%')
  }

  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'cronjob-form') {
      NavDestination() {
        HarmonyCronjobForm({ jobId: this.editingId, onSaved: (): void => { this.paths.pop(); this.load(); } })
      }.title(automationText(this.editingId < 0 ? 'cronjobFormCreateTitle' : 'cronjobFormEditTitle'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'cronjob-detail') {
      NavDestination() {
        Scroll() {
          Column({ space: 16 }) {
            Text(automationString(this.selectedJob, 'name')).fontSize(20).fontWeight(FontWeight.Bold)
            Text(automationString(this.selectedJob, 'spec')).fontFamily('monospace').fontSize(16)
            Text(`${automationText('cronjobsNextRunLabel')}: ${automationString(this.selectedJob, 'nextHandle')}`).fontSize(14)
            Text(`${automationText('cronjobsLastRecordLabel')}: ${automationString(this.selectedJob, 'lastRecordTime')}`).fontSize(14)
            Button(automationText('cronjobsRecordsAction')).height(48).width('100%').onClick((): void => { this.showRecords(); })
            Button(automationText('commonEdit')).height(48).width('100%').onClick((): void => { this.edit(this.selectedJob); })
            Button(automationText('cronjobsHandleOnceAction')).height(48).width('100%')
              .onClick((): void => { this.confirmAction('handleCronJobOnce', 'cronjobsHandleOnceConfirm', this.selectedJob); })
          }.padding(16).alignItems(HorizontalAlign.Start).width('100%')
        }
      }.title(automationText('cronjobsDetailTitle'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'cronjob-records') {
      NavDestination() { this.recordBody() }.title(automationText('cronjobRecordsTitle'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'cronjob-log') {
      NavDestination() {
        Scroll() { Text(this.logContent).fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp).padding(16).width('100%') }
      }.title(automationText('cronjobRecordsViewLogTitle'), { barStyle: BarStyle.STANDARD })
    }
  }

  build() {
    Navigation(this.paths) { this.body() }
      .title(automationText('operationsCronjobsTitle'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true).menus(this.menus())
      .navDestination(this.destination).mode(NavigationMode.Stack)
      .width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
  }
}
