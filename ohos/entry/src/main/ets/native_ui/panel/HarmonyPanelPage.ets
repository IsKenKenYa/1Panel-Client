import { SymbolGlyphModifier } from '@kit.ArkUI';
import { HarmonyNativeBridge } from '../HarmonyNativeBridge';
import { moduleTitleOptions } from '../HarmonyModuleTitle';
import { HarmonyPanelEntry, HarmonyPanelValue } from './HarmonyPanelControls';
import { HarmonyPanelConfigurationPage } from './HarmonyPanelConfigurationPage';
import { HarmonyPanelTerminalPage } from './HarmonyPanelTerminalPage';
import { HarmonyPanelMaintenancePage } from './HarmonyPanelMaintenancePage';
import { HarmonyPanelSslPage } from './HarmonyPanelSslPage';
import { HarmonyPanelMonitorPage } from './HarmonyPanelMonitorPage';

interface HarmonyPanelDestination {
  section: string;
  titleKey: string;
  icon: Resource;
}

@Component
export struct HarmonyPanelPage {
  @Prop initialRoute: string = '/system-settings';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};
  @State private loading: boolean = true;
  @State private errorMessage: string = '';
  @State private settings: Map<string, Object | null> = new Map<string, Object | null>();
  private paths: NavPathStack = new NavPathStack();
  private bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private panelEntries: HarmonyPanelDestination[] = [
    { section: 'basic', titleKey: 'systemSettingsPanelConfig', icon: $r('sys.symbol.externaldrive') },
    { section: 'store', titleKey: 'appStoreTitle', icon: $r('sys.symbol.bag') },
    { section: 'menu', titleKey: 'menuSettingsTitle', icon: $r('sys.symbol.list_bullet') },
    { section: 'memo', titleKey: 'systemSettingsDashboardMemo', icon: $r('sys.symbol.doc_text') },
  ];
  private connectionEntries: HarmonyPanelDestination[] = [
    { section: 'terminal', titleKey: 'systemSettingsTerminal', icon: $r('sys.symbol.square_stack_3d') },
    { section: 'proxy', titleKey: 'proxySettingsTitle', icon: $r('sys.symbol.link') },
    { section: 'connection', titleKey: 'operationsSshTitle', icon: $r('sys.symbol.link') },
    { section: 'interfaces', titleKey: 'sshSettingsNetworkSectionTitle', icon: $r('sys.symbol.list_bullet') },
  ];
  private securityEntries: HarmonyPanelDestination[] = [
    { section: 'security', titleKey: 'systemSettingsSecurityConfig', icon: $r('sys.symbol.lock') },
    { section: 'ssl', titleKey: 'sslSettingsTitle', icon: $r('sys.symbol.lock') },
  ];
  private maintenanceEntries: HarmonyPanelDestination[] = [
    { section: 'upgrade', titleKey: 'systemSettingsUpgrade', icon: $r('sys.symbol.arrow_up_circle') },
    { section: 'monitor', titleKey: 'monitorSettingsTitle', icon: $r('sys.symbol.slider_horizontal_2') },
    { section: 'snapshot', titleKey: 'systemSettingsSnapshot', icon: $r('sys.symbol.clock') },
  ];

  aboutToAppear(): void {
    this.load();
    const section = this.initialSection();
    if (section.length > 0) {
      const path: NavPathInfo = { name: section };
      this.paths.pushPath(path);
    }
  }

  private initialSection(): string {
    if (this.initialRoute === '/panel-ssl') return 'ssl';
    if (this.initialRoute === '/system-settings/menu') return 'menu';
    const prefix = '/system-settings/';
    if (this.initialRoute.startsWith(prefix)) return this.initialRoute.substring(prefix.length);
    return '';
  }

  private text(key: string): string { return this.bridge.text(key); }

  private value(key: string): string {
    const content = this.settings.get(key);
    return content === undefined || content === null ? '—' : content.toString();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const result = await this.bridge.invoke<Map<string, Object | null> | null>('getHarmonyPanelSettings');
      if (result === null) throw new Error(this.text('systemSettingsLoadFailed'));
      this.settings = result;
    } catch (error) {
      this.errorMessage = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private open(section: string): void {
    const path: NavPathInfo = { name: section };
    this.paths.pushPath(path);
  }

  private menus(): NavigationMenuItem[] {
    return [{
      value: this.text('commonRefresh'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      action: (): void => { this.load(); },
    }];
  }

  @Builder
  private sectionHeader(key: string) {
    Text(this.text(key))
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_secondary'))
      .padding({ top: 16, bottom: 8, left: 8 })
  }

  @Builder
  private entriesGroup(entries: HarmonyPanelDestination[], label: string) {
    ListItemGroup({ header: (): void => { this.sectionHeader(label); } }) {
      ForEach(entries, (entry: HarmonyPanelDestination): void => {
        ListItem() {
          HarmonyPanelEntry({
            titleKey: entry.titleKey,
            icon: entry.icon,
            action: (): void => { this.open(entry.section); },
          })
        }
      }, (entry: HarmonyPanelDestination): string => entry.section)
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
  }

  @Builder
  private content() {
    if (this.loading) {
      Column() { LoadingProgress().width(48).height(48) }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else if (this.errorMessage.length > 0) {
      Column({ space: 16 }) {
        Text(this.errorMessage).fontSize(16)
        Button(this.text('commonRetry')).height(48).onClick((): void => { this.load(); })
      }
      .padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else {
      List({ space: 12 }) {
        ListItemGroup() {
          ListItem() { HarmonyPanelValue({ titleKey: 'panelSettingsPanelName', content: this.value('panelName') }) }
          ListItem() { HarmonyPanelValue({ titleKey: 'panelSettingsVersion', content: this.value('systemVersion') }) }
        }
        .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
        this.entriesGroup(this.panelEntries, 'systemSettingsPanelSection')
        this.entriesGroup(this.connectionEntries, 'systemSettingsConnectionsSection')
        this.entriesGroup(this.securityEntries, 'systemSettingsSecuritySection')
        this.entriesGroup(this.maintenanceEntries, 'systemSettingsSystemSection')
        ListItem() {
          HarmonyPanelEntry({
            titleKey: 'systemSettingsBackupAccountTitle',
            icon: $r('sys.symbol.cloud'),
            action: (): void => { this.bridge.openNativePage('/backups'); },
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
        ListItem() {
          HarmonyPanelEntry({
            titleKey: 'serverActionSecurity',
            icon: $r('sys.symbol.lock'),
            action: (): void => { this.bridge.openNativePage('/security-verification'); },
          })
        }
        .backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 24 })
      .width('100%').height('100%')
    }
  }

  @Builder
  private destination(section: string, parameter: Object) {
    if (section === 'terminal' || section === 'connection') {
      HarmonyPanelTerminalPage({ connectionOnly: section === 'connection' })
    } else if (section === 'snapshot' || section === 'upgrade') {
      HarmonyPanelMaintenancePage({ section: section })
    } else if (section === 'ssl') {
      HarmonyPanelSslPage()
    } else if (section === 'monitor') {
      HarmonyPanelMonitorPage()
    } else {
      HarmonyPanelConfigurationPage({ section: section })
    }
  }

  build() {
    Navigation(this.paths) {
      this.content()
    }
    .title(this.text('systemSettingsTitle'), moduleTitleOptions)
    .menus(this.menus())
    .titleMode(NavigationTitleMode.Mini)
    .navDestination(this.destination)
    .mode(NavigationMode.Stack)
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
    .width('100%').height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
