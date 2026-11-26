import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

@Component
export struct HarmonyDockerConfigPage {
  @State private loading: boolean = false;
  @State private saving: boolean = false;
  @State private active: boolean = false;
  @State private exists: boolean = false;
  @State private content: string = '';
  @State private errorMessage: string = '';
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;

  aboutToAppear(): void { this.load(); }
  private text(key: string): string { return this.bridge.text(key); }
  private async load(): Promise<void> {
    this.loading = true; this.errorMessage = '';
    try {
      const reply = await this.bridge.invoke<Map<string, Object | null>>('getDockerConfiguration');
      const status = reply.get('status') as Map<string, Object | null>;
      this.active = status.get('isActive') as boolean;
      this.exists = status.get('isExist') as boolean;
      this.content = reply.get('content') as string;
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.loading = false; }
  }
  private async save(): Promise<void> {
    this.saving = true; this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>(); args.set('content', this.content);
      const result = await this.bridge.invoke<Map<string, Object | null>>('saveDockerConfiguration', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      this.getUIContext().getPromptAction().showToast({ message: this.text('commonSaveSuccess') });
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.saving = false; }
  }
  private operate(operation: string, title: string): void {
    this.getUIContext().showAlertDialog({ title: title, message: 'Docker',
      primaryButton: { value: this.text('commonCancel'), action: (): void => {} },
      secondaryButton: { value: this.text('commonConfirm'), action: (): void => { this.run(operation); } },
    });
  }
  private async run(operation: string): Promise<void> {
    this.saving = true;
    try {
      const args = new Map<string, Object | null>(); args.set('operation', operation);
      const result = await this.bridge.invoke<Map<string, Object | null>>('operateDocker', args);
      if (result.get('success') !== true) throw new Error(result.get('error') as string);
      await this.load();
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.saving = false; }
  }
  private status(): string {
    if (!this.exists) return this.text('commonNone');
    return this.text(this.active ? 'containerStatusRunning' : 'containerStatusStopped');
  }
  build() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Column({ space: 2 }) {
          Text('Docker').fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
          Text(this.status()).fontSize(14).fontColor($r('sys.color.font_secondary'))
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Button() { SymbolGlyph($r('sys.symbol.arrow_clockwise')).fontSize(20) }
          .height(48).width(48).buttonStyle(ButtonStyleMode.TEXTUAL).enabled(!this.loading)
          .accessibilityText(this.text('commonRefresh')).onClick((): void => { this.load(); })
      }.width('100%')
      Row({ space: 12 }) {
        if (this.active) {
          Button(this.text('containerActionStop'), { buttonStyle: ButtonStyleMode.NORMAL }).height(48).layoutWeight(1)
            .enabled(!this.saving).onClick((): void => { this.operate('stop', this.text('containerActionStop')); })
        } else {
          Button(this.text('containerActionStart'), { buttonStyle: ButtonStyleMode.NORMAL }).height(48).layoutWeight(1)
            .enabled(!this.saving).onClick((): void => { this.operate('start', this.text('containerActionStart')); })
        }
        Button(this.text('containerActionRestart'), { buttonStyle: ButtonStyleMode.NORMAL }).height(48).layoutWeight(1)
          .enabled(!this.saving).onClick((): void => { this.operate('restart', this.text('containerActionRestart')); })
      }
      if (this.loading) { LoadingProgress().width(48).height(48) }
      if (this.errorMessage.length > 0) { Text(this.errorMessage).fontColor($r('sys.color.font_primary')) }
      Text('daemon.json').fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')
      TextArea({ text: this.content }).fontFamily('monospace').fontSize(14).layoutWeight(1)
        .onChange((content: string): void => { this.content = content; })
      Button(this.text('commonSave')).height(48).width('100%').enabled(!this.saving && !this.loading)
        .onClick((): void => { this.save(); })
    }.padding(16).width('100%').height('100%').backgroundColor($r('sys.color.background_secondary'))
  }
}
