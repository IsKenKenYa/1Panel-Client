import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge, menuMaterial } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';

class HarmonyComposeProject {
  projectId: string;
  name: string;
  path: string;
  status: string;
  containers: number;
  constructor(data: Map<string, Object | null>) {
    this.projectId = data.get('id') as string;
    this.name = data.get('name') as string;
    this.path = data.get('path') as string;
    this.status = data.get('status') as string;
    this.containers = data.get('containerCount') as number;
  }
}

class HarmonyComposeTemplate {
  templateId: number;
  name: string;
  description: string;
  content: string;
  constructor(data: Map<string, Object | null>) {
    this.templateId = data.get('id') as number;
    this.name = data.get('name') as string;
    this.description = data.get('description') as string;
    this.content = data.get('content') as string;
  }
}

@Component
export struct HarmonyOrchestrationPage {
  @Prop initialRoute: string = '/orchestration';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @State private projects: HarmonyComposeProject[] = [];
  @State private templates: HarmonyComposeTemplate[] = [];
  @State private selected: HarmonyComposeProject[] = [];
  @State private currentTab: number = 0;
  @State private loading: boolean = false;
  @State private processing: boolean = false;
  @State private errorMessage: string = '';
  @State private formName: string = '';
  @State private formPath: string = '';
  @State private formContent: string = '';
  @State private source: string = 'edit';
  @State private templateId: number = -1;
  @State private templateDescription: string = '';
  @State private editingTemplateId: number = -1;
  @State private details: Array<Map<string, Object | null>> = [];
  @State private logText: string = '';
  @State private deleteForce: boolean = false;
  @State private deleteFile: boolean = false;
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void {
    this.currentTab = this.initialRoute === '/compose-templates' ? 1 : 0;
    this.load();
  }
  private text(key: string): string { return this.bridge.text(key); }
  private push(name: string): void {
    const path: NavPathInfo = { name: name };
    this.paths.pushPath(path);
  }
  private async load(): Promise<void> {
    this.loading = true; this.errorMessage = '';
    try {
      const projectData = await this.bridge.invoke<Array<Map<string, Object | null>>>('getComposes');
      this.projects = projectData.map((data: Map<string, Object | null>): HarmonyComposeProject => new HarmonyComposeProject(data));
      const templateData = await this.bridge.invoke<Array<Map<string, Object | null>>>('getContainerTemplates');
      this.templates = templateData.map((data: Map<string, Object | null>): HarmonyComposeTemplate => new HarmonyComposeTemplate(data));
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }
  private args(project: HarmonyComposeProject): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('name', project.name); args.set('path', project.path);
    return args;
  }
  private async mutate(method: string, args: Map<string, Object | null>, close: boolean = true): Promise<void> {
    this.processing = true; this.errorMessage = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null>>(method, args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.getUIContext().getPromptAction().showToast({ message: this.text('containerOperateSuccess') });
      if (close) this.paths.pop();
      await this.load();
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.processing = false; }
  }
  private async select(project: HarmonyComposeProject): Promise<void> {
    this.selected = [project];
    this.push('detail');
    this.loading = true;
    try { this.details = await this.bridge.invoke<Array<Map<string, Object | null>>>('getComposeContainers', this.args(project)); }
    catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }
  private async edit(project: HarmonyComposeProject): Promise<void> {
    this.formName = project.name; this.formPath = project.path; this.formContent = ''; this.source = 'edit';
    this.push('edit'); this.loading = true;
    try { this.formContent = await this.bridge.invoke<string>('getComposeContent', this.args(project)); }
    catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }
  private newProject(): void {
    this.formName = ''; this.formPath = ''; this.formContent = ''; this.source = 'edit'; this.templateId = -1;
    this.push('create');
  }
  private newTemplate(template?: HarmonyComposeTemplate): void {
    this.editingTemplateId = template?.templateId ?? -1;
    this.formName = template?.name ?? '';
    this.formContent = template?.content ?? '';
    this.templateDescription = template?.description ?? '';
    this.push('template');
  }
  private async saveProject(editing: boolean): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('name', this.formName); args.set('path', this.formPath);
    if (editing) args.set('content', this.formContent);
    else { args.set('from', this.source); args.set('file', this.formContent); if (this.templateId >= 0) args.set('template', this.templateId); }
    await this.mutate(editing ? 'updateCompose' : 'createCompose', args);
  }
  private async testProject(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('name', this.formName); args.set('content', this.formContent);
    await this.mutate('testCompose', args, false);
  }
  private async saveTemplate(): Promise<void> {
    const args = new Map<string, Object | null>();
    args.set('name', this.formName); args.set('content', this.formContent); args.set('description', this.templateDescription);
    if (this.editingTemplateId >= 0) args.set('id', this.editingTemplateId);
    await this.mutate(this.editingTemplateId >= 0 ? 'updateContainerTemplate' : 'createContainerTemplate', args);
  }
  private deleteTemplate(template: HarmonyComposeTemplate): void {
    this.getUIContext().showAlertDialog({ title: this.text('commonDelete'), message: template.name,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonDelete'), action: (): void => {
        const args = new Map<string, Object | null>(); args.set('id', template.templateId);
        this.mutate('deleteContainerTemplate', args, false);
      } },
    });
  }
  private cleanLog(project: HarmonyComposeProject): void {
    this.getUIContext().showAlertDialog({ title: this.text('containerActionCleanLog'), message: project.name,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => {
        this.mutate('cleanComposeLog', this.args(project), false);
      } },
    });
  }
  private confirmOperation(project: HarmonyComposeProject, operation: string, label: string): void {
    this.getUIContext().showAlertDialog({ title: label, message: project.name,
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => {
        const args = this.args(project); args.set('operation', operation);
        this.mutate('composeOperate', args, false);
      } },
    });
  }
  private async logs(project: HarmonyComposeProject): Promise<void> {
    this.push('logs'); this.loading = true;
    try {
      const args = this.args(project); args.set('tail', '200');
      this.logText = await this.bridge.invoke<string>('getComposeLogs', args);
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }
  private rootMenus(): NavigationMenuItem[] {
    return [
      { value: this.text('commonRefresh'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: (): void => { this.load(); }, isEnabled: !this.loading },
      { value: this.text('commonCreate'), symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
        action: (): void => { if (this.currentTab === 0) this.newProject(); else this.newTemplate(); } },
    ];
  }
  private detailMenus(project: HarmonyComposeProject): NavigationMenuItem[] {
    return [
      { value: this.text('containerActionStart'), action: (): void => { this.confirmOperation(project, 'up', this.text('containerActionStart')); } },
      { value: this.text('hostOrchestrationDown'), action: (): void => { this.confirmOperation(project, 'down', this.text('hostOrchestrationDownTitle')); } },
      { value: this.text('containerActionStop'), action: (): void => { this.confirmOperation(project, 'stop', this.text('containerActionStop')); } },
      { value: this.text('containerActionRestart'), action: (): void => { this.confirmOperation(project, 'restart', this.text('containerActionRestart')); } },
      { value: this.text('containerActionCleanLog'), action: (): void => { this.cleanLog(project); } },
      { value: this.text('orchestrationComposeDelete'), action: (): void => { this.push('delete'); } },
    ];
  }
  @Builder
  private row(title: string, subtitle: string, action: () => void) {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
        if (subtitle.length > 0) { Text(subtitle).fontSize(14).fontColor($r('sys.color.font_secondary')) }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(16).fontColor([$r('sys.color.font_secondary')])
    }.padding(16).constraintSize({ minHeight: 72 }).width('100%')
      .backgroundColor($r('sys.color.ohos_id_color_list_card_bg')).borderRadius(16).onClick(action)
  }
  @Builder
  private templateMenu(template: HarmonyComposeTemplate) {
    Menu() {
      MenuItem({ content: this.text('commonEdit') }).onClick((): void => { this.newTemplate(template); })
      MenuItem({ content: this.text('commonDelete') }).onClick((): void => { this.deleteTemplate(template); })
    }
  }

  @Builder
  private listContent() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button(this.text('orchestrationCompose'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).layoutWeight(1)
          .onClick((): void => { this.currentTab = 0; })
        Button(this.text('orchestrationTemplates'), { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).layoutWeight(1)
          .onClick((): void => { this.currentTab = 1; })
      }
      if (this.loading) { LoadingProgress().width(48).height(48) }
      if (this.errorMessage.length > 0) { Text(this.errorMessage).fontColor($r('sys.color.font_primary')) }
      List({ space: 12 }) {
        if (this.currentTab === 0) {
          ForEach(this.projects, (project: HarmonyComposeProject): void => {
            ListItem() { this.row(project.name, `${project.status} · ${project.containers}`, (): void => { this.select(project); }) }
          }, (project: HarmonyComposeProject): string => project.projectId)
        } else {
          ForEach(this.templates, (template: HarmonyComposeTemplate): void => {
            ListItem() { this.row(template.name, template.description, (): void => { this.newTemplate(template); }) }
              .bindContextMenu(this.templateMenu(template), ResponseType.LongPress, { systemMaterial: menuMaterial })
          }, (template: HarmonyComposeTemplate): string => `${template.templateId}`)
        }
      }.layoutWeight(1).width('100%')
    }.padding(16).width('100%').height('100%')
  }
  @Builder
  private projectDetail(project: HarmonyComposeProject) {
    List({ space: 12 }) {
      ListItem() { this.row(this.text('containerComposeFileTitle'), project.path, (): void => { this.edit(project); }) }
      ListItem() { this.row(this.text('containerActionLogs'), '', (): void => { this.logs(project); }) }
      ForEach(this.details, (container: Map<string, Object | null>): void => {
        ListItem() { this.row(container.get('name') as string, container.get('state') as string, (): void => {
          const args = new Map<string, Object | null>(); args.set('id', container.get('id') as string);
          args.set('name', container.get('name') as string); this.bridge.openNativePage('/container-detail', args);
        }) }
      }, (container: Map<string, Object | null>): string => container.get('id') as string)
    }.padding(16).width('100%').height('100%')
  }
  @Builder
  private projectForm(editing: boolean) {
    Column({ space: 12 }) {
      TextInput({ text: this.formName, placeholder: this.text('commonName') }).height(48).enabled(!editing)
        .onChange((content: string): void => { this.formName = content; })
      if (!editing) {
        Select([{ value: this.text('containerComposeFileTitle') }, { value: this.text('orchestrationComposeSourcePath') },
          { value: this.text('orchestrationTemplates') }]).value(this.sourceTitle()).height(48)
          .onSelect((index: number): void => { this.source = ['edit', 'path', 'template'][index]; })
      }
      if (this.source === 'path' || editing) {
        TextInput({ text: this.formPath, placeholder: this.text('orchestrationComposePathHint') }).height(48)
          .onChange((content: string): void => { this.formPath = content; })
      }
      if (this.source === 'template' && !editing) {
        Select(this.templates.map((template: HarmonyComposeTemplate): SelectOption => { return { value: template.name }; }))
          .height(48).value(this.text('orchestrationTemplates'))
          .onSelect((index: number): void => { this.templateId = this.templates[index].templateId; })
      } else if (this.source !== 'path' || editing) {
        TextArea({ text: this.formContent, placeholder: this.text('orchestrationComposeContentHint') })
          .layoutWeight(1).fontFamily('monospace').fontSize(14)
          .onChange((content: string): void => { this.formContent = content; })
      }
      if (this.errorMessage.length > 0) { Text(this.errorMessage).fontColor($r('sys.color.font_primary')) }
      Row({ space: 12 }) {
        if (editing || this.source === 'edit') {
          Button(this.text('orchestrationComposeTest'), { buttonStyle: ButtonStyleMode.NORMAL }).height(48).layoutWeight(1)
            .enabled(!this.processing).onClick((): void => { this.testProject(); })
        }
        Button(this.text('commonSave')).height(48).layoutWeight(1).enabled(!this.processing && !this.loading)
          .onClick((): void => { this.saveProject(editing); })
      }
    }.padding(16).width('100%').height('100%')
  }
  private sourceTitle(): string {
    if (this.source === 'path') return this.text('orchestrationComposeSourcePath');
    if (this.source === 'template') return this.text('orchestrationTemplates');
    return this.text('containerComposeFileTitle');
  }
  @Builder
  private templateForm() {
    Column({ space: 12 }) {
      TextInput({ text: this.formName, placeholder: this.text('commonName') }).height(48)
        .onChange((content: string): void => { this.formName = content; })
      TextInput({ text: this.templateDescription, placeholder: this.text('commonDescription') }).height(48)
        .onChange((content: string): void => { this.templateDescription = content; })
      TextArea({ text: this.formContent, placeholder: this.text('containerTemplateContentHint') })
        .layoutWeight(1).fontFamily('monospace').fontSize(14).onChange((content: string): void => { this.formContent = content; })
      if (this.errorMessage.length > 0) { Text(this.errorMessage).fontColor($r('sys.color.font_primary')) }
      Button(this.text('commonSave')).height(48).width('100%').enabled(!this.processing)
        .onClick((): void => { this.saveTemplate(); })
    }.padding(16).width('100%').height('100%')
  }
  @Builder
  private deleteForm(project: HarmonyComposeProject) {
    Column({ space: 16 }) {
      Text(project.name).fontSize(20).fontWeight(FontWeight.Medium)
      Row() {
        Text(this.text('orchestrationComposeForceDelete')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.deleteForce }).onChange((enabled: boolean): void => { this.deleteForce = enabled; })
      }.height(48)
      Row() {
        Text(this.text('orchestrationComposeDeleteFile')).layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.deleteFile }).onChange((enabled: boolean): void => { this.deleteFile = enabled; })
      }.height(48)
      Button(this.text('commonDelete')).height(48).width('100%').enabled(!this.processing)
        .onClick((): void => { const args = this.args(project); args.set('operation', 'delete');
          args.set('force', this.deleteForce); args.set('withFile', this.deleteFile); this.mutate('composeOperate', args); })
    }.padding(16).width('100%')
  }
  @Builder
  private destination(name: string, parameter: Object) {
    if (name === 'create' || name === 'edit') {
      NavDestination() { this.projectForm(name === 'edit') }.title(this.text('orchestrationComposeCreateTitle'),
        { barStyle: BarStyle.STANDARD })
    } else if (name === 'template') {
      NavDestination() { this.templateForm() }.title(this.text('containerTemplateCreateTitle'),
        { barStyle: BarStyle.STANDARD })
    } else {
      ForEach(this.selected, (project: HarmonyComposeProject): void => {
        if (name === 'detail') {
          NavDestination() { this.projectDetail(project) }.title(project.name,
            { barStyle: BarStyle.STANDARD }).menus(this.detailMenus(project))
        } else if (name === 'logs') {
          NavDestination() {
            Scroll() { Text(this.logText).fontFamily('monospace').fontSize(13).copyOption(CopyOptions.LocalDevice).padding(16) }
          }.title(this.text('containerActionLogs'), { barStyle: BarStyle.STANDARD })
        } else if (name === 'delete') {
          NavDestination() { this.deleteForm(project) }.title(this.text('orchestrationComposeDelete'),
            { barStyle: BarStyle.STANDARD })
        }
      }, (project: HarmonyComposeProject): string => project.projectId)
    }
  }
  build() {
    Navigation(this.paths) { this.listContent() }
      .title(this.text('orchestrationTitle'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini).hideBackButton(true).menus(this.rootMenus()).navDestination(this.destination)
      .mode(NavigationMode.Stack).expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
      .backgroundColor($r('sys.color.background_secondary')).width('100%').height('100%')
  }
}
