import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { HarmonyContainerTerminalBridge } from './HarmonyContainerTerminalBridge';

@Component
export struct HarmonyContainerTerminalPage {
  @Prop containerName: string = '';
  @State private sessionId: string = '';
  @State private output: string = '';
  @State private inputText: string = '';
  @State private connected: boolean = false;
  @State private connecting: boolean = false;
  @State private errorMessage: string = '';
  private terminal: HarmonyContainerTerminalBridge = HarmonyContainerTerminalBridge.instance;
  private visible: boolean = false;
  private eventListener: (payload: Map<string, Object | null>) => void =
    (payload: Map<string, Object | null>): void => {
      if (!this.visible) return;
      const session = payload.get('sessionId') as string;
      if (this.sessionId.length > 0 && session !== this.sessionId) return;
      const event = payload.get('event') as string;
      if (event === 'output') this.output += payload.get('data') as string;
      else if (event === 'error') this.errorMessage = payload.get('message') as string;
      else if (event === 'closed') this.connected = false;
      else if (event === 'status') this.connected = payload.get('status') === 'connected';
    };

  aboutToAppear(): void { this.visible = true; this.terminal.addListener(this.eventListener); }
  aboutToDisappear(): void {
    this.visible = false;
    this.terminal.removeListener(this.eventListener);
    this.disconnect();
  }
  private text(key: string): string { return HarmonyNativeBridge.instance.text(key); }
  private args(): Map<string, Object | null> {
    const args = new Map<string, Object | null>();
    args.set('sessionId', this.sessionId);
    return args;
  }
  private async connect(): Promise<void> {
    this.connecting = true;
    this.errorMessage = '';
    try {
      const args = new Map<string, Object | null>();
      args.set('containerName', this.containerName); args.set('cols', 80); args.set('rows', 24);
      this.sessionId = await this.terminal.invoke<string>('openTerminal', args);
      this.connected = true;
    } catch (error) { this.errorMessage = (error as Error).message; }
    finally { this.connecting = false; }
  }
  private async disconnect(): Promise<void> {
    if (this.sessionId.length === 0) return;
    try { await this.terminal.invoke<boolean>('closeTerminal', this.args()); }
    finally { this.sessionId = ''; this.connected = false; }
  }
  private async send(content: string): Promise<void> {
    try {
      const args = this.args(); args.set('data', content);
      await this.terminal.invoke<boolean>('sendTerminalInput', args);
      this.inputText = '';
    } catch (error) { this.errorMessage = (error as Error).message; }
  }
  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        if (this.connected) {
          Button(this.text('containerTerminalDisconnect'), { buttonStyle: ButtonStyleMode.NORMAL })
            .height(48).onClick((): void => { this.disconnect(); })
        } else {
          Button(this.text('containerTerminalConnect')).height(48).enabled(!this.connecting)
            .onClick((): void => { this.connect(); })
        }
        Button('Ctrl+C', { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).enabled(this.connected)
          .onClick((): void => { this.send('\u0003'); })
        Button('Tab', { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).enabled(this.connected)
          .onClick((): void => { this.send('\t'); })
      }.width('100%')
      if (this.errorMessage.length > 0) { Text(this.errorMessage).fontSize(14).fontColor($r('sys.color.font_primary')) }
      Scroll() {
        Text(this.output).fontFamily('monospace').fontSize(13).fontColor($r('sys.color.font_primary'))
          .copyOption(CopyOptions.LocalDevice).width('100%')
      }.layoutWeight(1).width('100%').backgroundColor($r('sys.color.ohos_id_color_sub_background')).borderRadius(16)
      TextInput({ text: this.inputText, placeholder: this.text('containerInfoCommand') })
        .height(48).fontFamily('monospace').enabled(this.connected)
        .onChange((content: string): void => { this.inputText = content; })
        .onSubmit((): void => { this.send(`${this.inputText}\r`); })
    }.padding(16).height('100%').width('100%').backgroundColor($r('sys.color.background_secondary'))
  }
}
