import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { HarmonyHostFailure, HarmonyHostLinkRow, HarmonyHostValueRow, hostString, hostText } from './HarmonyHostWidgets';

interface FirewallSection {
  route: string;
  key: string;
  method: string;
  symbol: Resource;
}

@Component
export struct HarmonyHostFirewallV2Page {
  @Prop initialRoute: string = '/firewall-v2';
  @State private data: Map<string, Object | null> = new Map<string, Object | null>();
  @State private error: string = '';
  @State private loading: boolean = false;
  @State private query: string = '';
  private readonly paths: NavPathStack = new NavPathStack();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly sections: FirewallSection[] = [
    { route: '/firewall-v2-rules', key: 'firewallV2SystemRules', method: 'getNativeHostFirewallInventory',
      symbol: $r('sys.symbol.checkmark_shield') },
    { route: '/firewall-v2-forward', key: 'firewallV2Forward', method: 'getFirewallV2Forward',
      symbol: $r('sys.symbol.link') },
    { route: '/firewall-v2-docker', key: 'firewallV2Docker', method: 'getFirewallV2Docker',
      symbol: $r('sys.symbol.externaldrive') },
    { route: '/firewall-v2-settings', key: 'firewallV2Settings', method: 'getFirewallV2Settings',
      symbol: $r('sys.symbol.gearshape') },
  ];

  aboutToAppear(): void { this.load(); }

  private section(): FirewallSection | undefined {
    return this.sections.find((item: FirewallSection): boolean => item.route === this.initialRoute);
  }

  private async load(): Promise<void> {
    const section = this.section();
    if (section === undefined || this.loading) return;
    this.loading = true;
    this.error = '';
    try {
      const args = new Map<string, Object | null>();
      if (this.query.length > 0) args.set('info', this.query);
      this.data = await this.bridge.invoke<Map<string, Object | null>>(section.method, args);
    } catch (error) {
      this.error = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private title(): string {
    return hostText(this.section()?.key ?? 'firewallV2Title');
  }

  private menus(): NavigationMenuItem[] {
    if (this.section() === undefined) return [];
    return [{
      value: hostText('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.load(); },
    }];
  }

  private rootMenus(): NavigationMenuItem[] {
    return this.menus();
  }

  private scalarKeys(): string[] {
    const keys: string[] = [];
    this.data.forEach((value: Object | null, key: string): void => {
      if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') keys.push(key);
    });
    return keys;
  }

  private items(key: string): Array<Map<string, Object | null>> {
    return this.data.get(key) as Array<Map<string, Object | null>> ?? [];
  }

  @Builder
  private itemsSection(key: string, title: string, field: string, secondary: string) {
    if (this.items(key).length > 0) {
      ListItemGroup({ header: (): void => {
        Text(hostText(title)).fontSize(14).fontColor($r('sys.color.font_secondary')).padding(12);
      } }) {
        ForEach(this.items(key), (item: Map<string, Object | null>): void => {
          ListItem() {
            HarmonyHostValueRow({ label: hostString(item, field), content: hostString(item, secondary) })
          }
        }, (item: Map<string, Object | null>, index: number): string => hostString(item, 'id') + ':' + index)
      }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
    }
  }

  @Builder
  private body() {
    if (this.initialRoute === '/firewall-v2') {
      List() {
        ForEach(this.sections, (section: FirewallSection): void => {
          ListItem() {
            HarmonyHostLinkRow({ label: hostText(section.key), symbol: section.symbol,
              onOpen: (): void => { this.bridge.openNativePage(section.route); } })
          }
        }, (section: FirewallSection): string => section.route)
      }.width('100%').height('100%').padding(16)
    } else if (this.loading) {
      Column() { LoadingProgress().width(48).height(48) }.width('100%').padding(24)
    } else if (this.error.length > 0) {
      HarmonyHostFailure({ message: this.error, onRetry: (): void => { this.load(); } })
    } else {
      List({ space: 12 }) {
        if (this.initialRoute === '/firewall-v2-rules') {
          ListItem() {
            TextInput({ text: this.query, placeholder: hostText('firewallSearchHint') }).height(48)
              .onChange((value: string): void => { this.query = value; })
              .onSubmit((): void => { this.load(); })
          }
          this.itemsSection('items', 'firewallV2SystemRules', 'address', 'port')
        } else if (this.initialRoute === '/firewall-v2-forward') {
          this.itemsSection('rules', 'firewallV2ForwardRules', 'port', 'targetPort')
        } else if (this.initialRoute === '/firewall-v2-docker') {
          this.itemsSection('publishedPorts', 'firewallV2PublishedPorts', 'containerName', 'hostPort')
          this.itemsSection('policies', 'firewallV2DockerPolicies', 'hostIP', 'mode')
        } else {
          this.itemsSection('whitelist', 'firewallV2Whitelist', 'port', 'protocol')
          this.itemsSection('backends', 'firewallV2Settings', 'subsystem', 'selected')
        }
        ForEach(this.scalarKeys(), (key: string): void => {
          ListItem() { HarmonyHostValueRow({ label: key, content: hostString(this.data, key) }) }
        }, (key: string): string => key)
      }.width('100%').height('100%').padding(16)
    }
  }

  build() {
    Navigation(this.paths) { this.body() }
      .title(this.title(), moduleTitleOptions)
      .titleMode(NavigationTitleMode.Mini)
      .menus(this.rootMenus())
      .mode(NavigationMode.Stack)
      .width('100%').height('100%')
  }
}
