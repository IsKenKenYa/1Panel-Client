import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../../HarmonyNativeBridge';
import { handleActivationKey } from '../../HarmonyInteractionUtils';

interface HarmonyWebsiteTemplateVariable {
  variableKey: string;
  variableValue: string;
}

@Component
export struct HarmonyWebsiteTemplatesPage {
  initialRoute: string = '/website-templates';
  routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  /** 由外层 NavDestination 承载标题栏时，内层导航只负责内容与二级页，避免出现两层标题栏。 */
  @Prop embedded: boolean = false;
  @State private templates: Array<Map<string, Object | null>> = [];
  @State private outputs: Array<Map<string, Object | null>> = [];
  @State private loading: boolean = true;
  @State private saving: boolean = false;
  @State private loadError: string = '';
  @State private formError: string = '';
  @State private nameFilter: string = '';
  @State private pageNumber: number = 1;
  @State private templateTotal: number = 0;
  @State private outputPage: number = 1;
  @State private outputTotal: number = 0;
  @State private templateName: string = '';
  @State private templateType: string = 'single';
  @State private templateContent: string = '';
  @State private templateRemark: string = '';
  @State private templateVariables: string = '';
  @State private templatePath: string = '';
  @State private outputName: string = '';
  @State private preview: string = '';
  @State private variables: HarmonyWebsiteTemplateVariable[] = [];
  @State private outputDetail: Map<string, Object | null> = new Map<string, Object | null>();
  private editingId: number | null = null;
  private generatingId: number | null = null;
  private outputTemplateId: number | null = null;
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private started: boolean = false;

  aboutToAppear(): void {
    this.loadTemplates();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private recordString(item: Map<string, Object | null>, key: string): string {
    return item.get(key) as string;
  }

  private recordId(item: Map<string, Object | null>): number {
    return item.get('id') as number;
  }

  private async loadTemplates(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('page', this.pageNumber);
      args.set('pageSize', 20);
      if (this.nameFilter.trim().length > 0) args.set('name', this.nameFilter.trim());
      const result = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteTemplates', args);
      this.templates = result.get('items') as Array<Map<string, Object | null>>;
      this.templateTotal = result.get('total') as number;
    } catch (error) {
      this.loadError = `${error}`;
    } finally {
      this.loading = false;
    }
  }

  private async loadOutputs(): Promise<void> {
    this.loading = true;
    this.loadError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('page', this.outputPage);
      args.set('pageSize', 20);
      if (this.outputTemplateId !== null) args.set('templateID', this.outputTemplateId);
      const result = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteTemplateOutputs', args);
      this.outputs = result.get('items') as Array<Map<string, Object | null>>;
      this.outputTotal = result.get('total') as number;
    } catch (error) {
      this.loadError = `${error}`;
    } finally {
      this.loading = false;
    }
  }

  private async edit(templateId: number | null): Promise<void> {
    this.editingId = templateId;
    this.formError = '';
    this.templateName = '';
    this.templateType = 'single';
    this.templateContent = '';
    this.templateRemark = '';
    this.templateVariables = '';
    this.templatePath = '';
    try {
      if (templateId !== null) {
        const args = new Map<string, Object | null>();
        args.set('id', templateId);
        const item = await this.bridge.invoke<Map<string, Object | null>>('getNativeWebsiteTemplate', args);
        this.templateName = this.recordString(item, 'name');
        this.templateType = this.recordString(item, 'type');
        this.templateContent = this.recordString(item, 'content');
        this.templateRemark = this.recordString(item, 'remark');
        this.templateVariables = this.recordString(item, 'variables');
        this.templatePath = this.recordString(item, 'filePath');
      }
      const location: NavPathInfo = { name: 'template-form' };
      this.paths.pushPath(location);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private async saveTemplate(): Promise<void> {
    if (this.templateName.trim().length === 0) {
      this.formError = this.text('websitesTemplateRequired');
      return;
    }
    this.saving = true;
    this.formError = '';
    try {
      const args = new Map<string, Object | null>();
      if (this.editingId !== null) args.set('id', this.editingId);
      args.set('name', this.templateName.trim());
      args.set('type', this.templateType);
      args.set('content', this.templateContent);
      args.set('remark', this.templateRemark);
      args.set('variables', this.templateVariables);
      args.set('filePath', this.templatePath);
      await this.bridge.invoke<Object | null>('saveNativeWebsiteTemplate', args);
      this.paths.pop();
      await this.loadTemplates();
    } catch (error) {
      this.formError = `${error}`;
    } finally {
      this.saving = false;
    }
  }

  private generate(templateId: number): void {
    this.generatingId = templateId;
    this.outputName = '';
    this.preview = '';
    this.variables = [];
    this.formError = '';
    const location: NavPathInfo = { name: 'generate' };
    this.paths.pushPath(location);
  }

  private variableValues(): Map<string, Object | null> {
    const values = new Map<string, Object | null>();
    this.variables.forEach((entry: HarmonyWebsiteTemplateVariable): void => {
      if (entry.variableKey.trim().length > 0) values.set(entry.variableKey.trim(), entry.variableValue);
    });
    return values;
  }

  private async createOutput(previewOnly: boolean): Promise<void> {
    if (!previewOnly && this.outputName.trim().length === 0) {
      this.formError = this.text('websitesTemplateRequired');
      return;
    }
    this.saving = true;
    this.formError = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('templateID', this.generatingId);
      args.set('name', this.outputName.trim());
      args.set('variableValues', this.variableValues());
      if (previewOnly) {
        this.preview = await this.bridge.invoke<string>('previewNativeWebsiteTemplate', args);
      } else {
        await this.bridge.invoke<Object | null>('createNativeWebsiteTemplateOutput', args);
        this.paths.pop();
        this.openOutputs(this.generatingId);
      }
    } catch (error) {
      this.formError = `${error}`;
    } finally {
      this.saving = false;
    }
  }

  private openOutputs(templateId: number | null = null): void {
    this.outputTemplateId = templateId;
    this.outputPage = 1;
    const location: NavPathInfo = { name: 'outputs' };
    this.paths.pushPath(location);
  }

  private confirmDelete(item: Map<string, Object | null>, output: boolean): void {
    this.getUIContext().showAlertDialog({
      title: this.text('commonDelete'),
      message: this.text(output ? 'websitesTemplateOutputDeleteConfirm' : 'websitesTemplateDeleteConfirm'),
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonDelete'), action: (): void => { this.performDelete(this.recordId(item), output); } },
    });
  }

  private async performDelete(itemId: number, output: boolean): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      args.set('id', itemId);
      await this.bridge.invoke<Object | null>(output ? 'deleteNativeWebsiteTemplateOutput' : 'deleteNativeWebsiteTemplate', args);
      if (output) await this.loadOutputs();
      else await this.loadTemplates();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  private templateMenu(item: Map<string, Object | null>): MenuElement[] {
    return [
      { value: this.text('websitesTemplateGenerate'), action: (): void => { this.generate(this.recordId(item)); } },
      { value: this.text('websitesTemplateOutputsTitle'), action: (): void => { this.openOutputs(this.recordId(item)); } },
      { value: this.text('commonEdit'), action: (): void => { this.edit(this.recordId(item)); } },
      { value: this.text('commonDelete'), action: (): void => { this.confirmDelete(item, false); } },
    ];
  }

  private menus(): NavigationMenuItem[] {
    return [
      { value: this.text('websitesTemplateOutputsTitle'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.folder')),
        action: (): void => { this.openOutputs(); } },
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.loadTemplates(); } },
      { value: this.text('commonAdd'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { this.edit(null); } },
    ];
  }

  private updateVariable(index: number, content: string, key: boolean): void {
    this.variables = this.variables.map((entry: HarmonyWebsiteTemplateVariable, itemIndex: number): HarmonyWebsiteTemplateVariable => {
      if (itemIndex !== index) return entry;
      return { variableKey: key ? content : entry.variableKey, variableValue: key ? entry.variableValue : content };
    });
  }

  private begin(): void {
    if (this.started) return;
    this.started = true;
    const templateId = this.routeArguments.get('templateId') as number | undefined;
    if (this.initialRoute === '/website-template-form') this.edit(templateId ?? null);
    if (this.initialRoute === '/website-template-outputs') this.openOutputs(templateId ?? null);
    if (this.initialRoute === '/website-template-output-create' && templateId !== undefined) this.generate(templateId);
  }

  @Builder
  private templateForm() {
    Scroll() {
      Column({ space: 16 }) {
        Text(this.text('websitesTemplateName')).fontSize(14).width('100%')
        TextInput({ text: this.templateName }).height(48)
          .onChange((content: string): void => { this.templateName = content; })
        Select([{ value: this.text('websitesTemplateTypeSingle') }, { value: this.text('websitesTemplateTypeMulti') }])
          .selected(this.templateType === 'single' ? 0 : 1).height(48).width('100%')
          .onSelect((index: number): void => { this.templateType = index === 0 ? 'single' : 'multi'; })
        Text(this.text('websitesTemplateContent')).fontSize(14).width('100%')
        TextArea({ text: this.templateContent }).height(260).fontFamily('monospace')
          .onChange((content: string): void => { this.templateContent = content; })
        if (this.templateType === 'multi') {
          Text(this.text('filesPathLabel')).fontSize(14).width('100%')
          TextInput({ text: this.templatePath }).height(48)
            .onChange((content: string): void => { this.templatePath = content; })
        }
        Text(this.text('websitesTemplateVariables')).fontSize(14).width('100%')
        TextArea({ text: this.templateVariables }).height(120)
          .onChange((content: string): void => { this.templateVariables = content; })
        Text(this.text('websitesTemplateRemark')).fontSize(14).width('100%')
        TextInput({ text: this.templateRemark }).height(48)
          .onChange((content: string): void => { this.templateRemark = content; })
        if (this.formError.length > 0) { Text(this.formError).fontSize(14).width('100%') }
        Button(this.text('commonSave')).height(48).width('100%').enabled(!this.saving)
          .onClick((): void => { this.saveTemplate(); })
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private generateForm() {
    Scroll() {
      Column({ space: 16 }) {
        Text(this.text('websitesTemplateOutputName')).fontSize(14).width('100%')
        TextInput({ text: this.outputName }).height(48)
          .onChange((content: string): void => { this.outputName = content; })
        Text(this.text('websitesTemplateVariables')).fontSize(14).width('100%')
        ForEach(this.variables, (entry: HarmonyWebsiteTemplateVariable, index: number): void => {
          Row({ space: 8 }) {
            TextInput({ text: entry.variableKey, placeholder: this.text('commonName') }).height(48).layoutWeight(1)
              .onChange((content: string): void => { this.updateVariable(index, content, true); })
            TextInput({ text: entry.variableValue, placeholder: this.text('commonContent') }).height(48).layoutWeight(1)
              .onChange((content: string): void => { this.updateVariable(index, content, false); })
            Button() { SymbolGlyph($r('sys.symbol.minus')).fontSize(20) }
              .height(48).width(48).buttonStyle(ButtonStyleMode.TEXTUAL)
              .accessibilityText(this.text('commonDelete'))
              .onClick((): void => { this.variables = this.variables.filter((variable: HarmonyWebsiteTemplateVariable, itemIndex: number): boolean => itemIndex !== index); })
          }.width('100%')
        }, (entry: HarmonyWebsiteTemplateVariable, index: number): string => `${index}`)
        Button(this.text('commonAdd')).height(48).width('100%').buttonStyle(ButtonStyleMode.NORMAL)
          .onClick((): void => { this.variables = this.variables.concat([{ variableKey: '', variableValue: '' }]); })
        Button(this.text('websitesTemplatePreview')).height(48).width('100%').buttonStyle(ButtonStyleMode.NORMAL)
          .enabled(!this.saving).onClick((): void => { this.createOutput(true); })
        if (this.preview.length > 0) {
          Text(this.preview).fontSize(14).fontFamily('monospace').copyOption(CopyOptions.InApp).width('100%')
        }
        if (this.formError.length > 0) { Text(this.formError).fontSize(14).width('100%') }
        Button(this.text('websitesTemplateGenerate')).height(48).width('100%').enabled(!this.saving)
          .onClick((): void => { this.createOutput(false); })
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private pageButtons(output: boolean) {
    Row({ space: 16 }) {
      Button() { SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20) }
        .height(48).width(48).enabled(output ? this.outputPage > 1 : this.pageNumber > 1)
        .accessibilityText(this.text('commonPreviousPage'))
        .onClick((): void => {
          if (output) { this.outputPage--; this.loadOutputs(); }
          else { this.pageNumber--; this.loadTemplates(); }
        })
      Text(`${output ? this.outputPage : this.pageNumber}`).fontSize(16)
      Button() { SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(20) }
        .height(48).width(48).enabled(output ? this.outputPage * 20 < this.outputTotal : this.pageNumber * 20 < this.templateTotal)
        .accessibilityText(this.text('commonNextPage'))
        .onClick((): void => {
          if (output) { this.outputPage++; this.loadOutputs(); }
          else { this.pageNumber++; this.loadTemplates(); }
        })
    }.width('100%').justifyContent(FlexAlign.Center)
  }

  private openListItem(item: Map<string, Object | null>, output: boolean): void {
    if (output) {
      this.outputDetail = item;
      const route: NavPathInfo = { name: 'output-detail' };
      this.paths.pushPath(route);
    } else {
      this.edit(this.recordId(item));
    }
  }

  @Builder
  private listBody(output: boolean) {
    Column({ space: 12 }) {
      if (!output) {
        Search({ value: this.nameFilter, placeholder: this.text('websitesTemplateSearchHint') }).height(48)
          .onChange((content: string): void => { this.nameFilter = content; })
          .onSubmit((): void => { this.pageNumber = 1; this.loadTemplates(); })
      }
      if (this.loadError.length > 0) { Text(this.loadError).fontSize(14).width('100%') }
      if (this.loading) {
        LoadingProgress().width(48).height(48)
      } else {
        List({ space: 12 }) {
          ForEach(output ? this.outputs : this.templates, (item: Map<string, Object | null>): void => {
            ListItem() {
              Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.doc')).fontSize(24).fontColor([$r('sys.color.icon_primary')])
                Column({ space: 2 }) {
                  Text(this.recordString(item, 'name')).fontSize(16).fontWeight(FontWeight.Medium)
                  if (output) {
                    Text(this.recordString(item, 'outputPath')).fontSize(14).fontColor($r('sys.color.font_secondary')).maxLines(2)
                  } else {
                    Text(this.recordString(item, 'remark')).fontSize(14).fontColor($r('sys.color.font_secondary')).maxLines(2)
                  }
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                if (output) {
                  Button() { SymbolGlyph($r('sys.symbol.trash')).fontSize(20) }
                    .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                    .accessibilityText(this.text('commonDelete')).onClick((): void => { this.confirmDelete(item, true); })
                } else {
                  Button() { SymbolGlyph($r('sys.symbol.ellipsis_circle')).fontSize(22) }
                    .width(48).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
                    .accessibilityText(this.text('commonMore')).bindMenu(this.templateMenu(item))
                }
              }.padding(16).width('100%').constraintSize({ minHeight: 72 })
                .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
                .onClick((): void => { this.openListItem(item, output); })
                .onKeyEvent((event?: KeyEvent): boolean => handleActivationKey(
                  event,
                  (): void => { this.openListItem(item, output); },
                ))
                .focusable(true)
                .focusOnTouch(true)
                .focusBox({ margin: LengthMetrics.vp(2) })
                .hoverEffect(HoverEffect.Highlight)
            }
          }, (item: Map<string, Object | null>): string => `${this.recordId(item)}`)
          ListItem() { this.pageButtons(output) }
        }.layoutWeight(1).width('100%')
      }
    }.padding(16).width('100%').height('100%')
  }

  @Builder
  private outputInformation() {
    Scroll() {
      Column({ space: 16 }) {
        Text(this.recordString(this.outputDetail, 'name')).fontSize(20).fontWeight(FontWeight.Medium).width('100%')
        Text(this.text('websitesTemplateOutputPath')).fontSize(14).width('100%')
        Text(this.recordString(this.outputDetail, 'outputPath')).fontSize(16).width('100%').copyOption(CopyOptions.InApp)
        Text(this.text('websitesTemplateVariables')).fontSize(14).width('100%')
        Text(this.recordString(this.outputDetail, 'variableValues')).fontSize(14).width('100%').copyOption(CopyOptions.InApp)
      }.padding(16).width('100%').alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%')
  }

  @Builder
  private destination(name: string) {
    if (name === 'template-form') {
      NavDestination() { this.templateForm() }
        .title(this.text(this.editingId === null ? 'websitesTemplateCreate' : 'websitesTemplateEdit'),
          { barStyle: BarStyle.STANDARD })
    } else if (name === 'generate') {
      NavDestination() { this.generateForm() }
        .title(this.text('websitesTemplateGenerate'), { barStyle: BarStyle.STANDARD })
    } else if (name === 'outputs') {
      NavDestination() { this.listBody(true) }
        .title(this.text('websitesTemplateOutputsTitle'), { barStyle: BarStyle.STANDARD })
        .onShown((): void => { this.loadOutputs(); })
    } else if (name === 'output-detail') {
      NavDestination() { this.outputInformation() }
        .title(this.text('websitesTemplateOutputsTitle'), { barStyle: BarStyle.STANDARD })
    }
  }

  build() {
    Navigation(this.paths) { this.listBody(false) }
      .title(this.text('websitesTemplateTitle'), { barStyle: BarStyle.STANDARD })
      .titleMode(NavigationTitleMode.Mini)
      .hideTitleBar(this.embedded)
      .menus(this.menus())
      .navDestination(this.destination)
      .mode(NavigationMode.Stack)
      .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .width('100%')
      .height('100%')
      .backgroundColor($r('sys.color.background_secondary'))
      .onAppear((): void => { this.begin(); })
  }
}
