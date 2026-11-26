import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { HarmonyHostFailure, HarmonyHostLinkRow, hostString, hostText } from './HarmonyHostWidgets';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyHostTerminalPage {
  onBack: () => void = (): void => {};
  @State private hosts: Array<Map<string, Object | null>> = [];
  @State private connecting: boolean = false;
  @State private connected: boolean = false;
  @State private output: string = '';
  @State private input: string = '';
  @State private status: string = '';
  @State private loadError: string = '';
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly paths: NavPathStack = new NavPathStack();
  private sessionId: string = '';
  private pollTimer: number = -1;
  private active: boolean = false;
  private readonly scroll: Scroller = new Scroller();

  aboutToAppear(): void {
    this.active = true;
    this.loadHosts();
  }

  aboutToDisappear(): void {
    this.active = false;
    this.disconnect();
  }

  private async loadHosts(): Promise<void> {
    this.loadError = '';
    try {
      const data = await this.bridge.invoke<Map<string, Object | null>>('getNativeHostAssets');
      this.hosts = data.get('items') as Array<Map<string, Object | null>>;
    } catch (error) {
      this.loadError = (error as Error).message;
    }
  }

  private async connect(hostId?: number): Promise<void> {
    if (this.connecting || this.sessionId.length > 0) return;
    this.connecting = true;
    this.status = '';
    this.output = '';
    try {
      const args = new Map<string, Object | null>();
      if (hostId !== undefined) args.set('hostId', hostId);
      this.sessionId = await this.bridge.invoke<string>('openNativeHostTerminal', args);
      if (!this.active) {
        await this.disconnect();
        return;
      }
      this.paths.pushPath({ name: 'terminal' });
      this.poll();
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: (error as Error).message });
    } finally {
      this.connecting = false;
    }
  }

  private async disconnect(): Promise<void> {
    clearTimeout(this.pollTimer);
    if (this.sessionId.length === 0) return;
    const args = new Map<string, Object | null>();
    args.set('sessionId', this.sessionId);
    this.sessionId = '';
    this.connected = false;
    try {
      await this.bridge.invoke<boolean>('closeNativeHostTerminal', args);
    } catch (error) {
      if (this.active) this.status = (error as Error).message;
    }
  }

  private async poll(): Promise<void> {
    const id = this.sessionId;
    if (id.length === 0) return;
    const args = new Map<string, Object | null>();
    args.set('sessionId', id);
    try {
      const data = await this.bridge.invoke<Map<string, Object | null>>('readNativeHostTerminal', args);
      if (id !== this.sessionId) return;
      const output = data.get('text') as string;
      if (output !== this.output) {
        this.output = output;
        this.scroll.scrollEdge(Edge.Bottom);
      }
      this.connected = data.get('closed') !== true;
      this.status = data.get('status') as string;
      if (this.connected) this.pollTimer = setTimeout((): void => { this.poll(); }, 500);
    } catch (error) {
      if (id !== this.sessionId) return;
      this.status = (error as Error).message;
      this.connected = false;
    }
  }

  private async send(content: string, clear: boolean = false): Promise<void> {
    if (!this.connected) return;
    try {
      const args = new Map<string, Object | null>();
      args.set('sessionId', this.sessionId);
      args.set('data', content);
      await this.bridge.invoke<boolean>('writeNativeHostTerminal', args);
      if (clear) this.input = '';
    } catch (error) {
      this.status = (error as Error).message;
    }
  }

  @Builder
  private targetList() {
    List({ space: 8 }) {
      ListItem() {
        HarmonyHostLinkRow({
          label: hostText('terminalWorkbenchLocalLabel'), symbol: $r('sys.symbol.doc_plaintext'),
          onOpen: (): void => { this.connect(); },
        })
      }
      if (this.loadError.length > 0) {
        ListItem() { HarmonyHostFailure({ message: this.loadError, onRetry: (): void => { this.loadHosts(); } }) }
      }
      ForEach(this.hosts, (item: Map<string, Object | null>): void => {
        ListItem() {
          HarmonyHostLinkRow({
            label: hostString(item, 'name'),
            detail: hostString(item, 'user') + '@' + hostString(item, 'addr') + ':' + hostString(item, 'port'),
            onOpen: (): void => { this.connect(item.get('id') as number); },
          })
        }
      }, (item: Map<string, Object | null>): string => hostString(item, 'id'))
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private session() {
    Column({ space: 8 }) {
      if (this.status.length > 0 && this.status !== 'connected') {
        Text(this.status).fontSize(14).fontColor($r('sys.color.font_secondary'))
      }
      Scroll(this.scroll) {
        Text(this.output).fontSize(13).fontFamily('monospace')
          .fontColor($r('sys.color.font_primary')).copyOption(CopyOptions.InApp).width('100%').padding(12)
      }.layoutWeight(1).width('100%').backgroundColor($r('sys.color.comp_background_primary')).borderRadius(12)
      Row({ space: 8 }) {
        Button('Ctrl+C', { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).enabled(this.connected)
          .onClick((): void => { this.send('\u0003'); })
        Button('Tab', { buttonStyle: ButtonStyleMode.TEXTUAL }).height(48).enabled(this.connected)
          .onClick((): void => { this.send('\t'); })
      }.width('100%')
      TextInput({ text: this.input, placeholder: hostText('terminalWorkbenchCommand') })
        .width('100%').height(48).enabled(this.connected)
        .onChange((value: string): void => { this.input = value; })
        .onSubmit((): void => { this.send(this.input + '\r', true); })
    }.width('100%').height('100%').padding(16)
  }

  @Builder
  private destination(name: string, parameter: Object) {
    NavDestination() { this.session() }
      .title(hostText('terminalWorkbenchSessionsTitle'), { barStyle: BarStyle.STANDARD })
      .onWillDisappear((): void => { this.disconnect(); })
      .backgroundColor($r('sys.color.background_secondary'))
  }

  build() {
    Navigation(this.paths) { this.targetList() }
      .title(hostText('serverModuleTerminal'), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini)
      .navDestination(this.destination)
      .mode(NavigationMode.Stack)
      .width('100%').height('100%')
  }
}
