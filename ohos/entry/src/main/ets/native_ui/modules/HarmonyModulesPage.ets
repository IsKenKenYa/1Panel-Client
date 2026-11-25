import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

interface HarmonyModuleDestination {
  titleKey: string;
  route: string;
}

@Component
export struct HarmonyModulesPage {
  @State private isLoading: boolean = true;
  @State private loadError: string = '';
  @State private currentServerName: string = '';
  @State private currentServerId: string = '';
  @State private isOnePanel: boolean = false;

  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly destinations: HarmonyModuleDestination[] = [
    { titleKey: 'serverModuleDashboard', route: '/dashboard' },
    { titleKey: 'serverModuleFiles', route: '/files' },
    { titleKey: 'serverModuleContainers', route: '/containers' },
    { titleKey: 'serverModuleRuntime', route: '/runtimes' },
    { titleKey: 'serverModuleApps', route: '/apps' },
    { titleKey: 'serverModuleWebsites', route: '/websites' },
    { titleKey: 'serverModuleDatabases', route: '/databases' },
    { titleKey: 'serverModuleAi', route: '/ai' },
    { titleKey: 'serverModuleVm', route: '/vm' },
    { titleKey: 'alertPageTitle', route: '/alert' },
    { titleKey: 'serverModuleFirewall', route: '/firewall' },
    { titleKey: 'serverModuleTerminal', route: '/terminal' },
    { titleKey: 'serverModuleMonitoring', route: '/monitoring' },
    { titleKey: 'serverActionSecurity', route: '/security-verification' },
    { titleKey: 'openrestyPageTitle', route: '/openresty' },
    { titleKey: 'operationsCenterServerEntryTitle', route: '/operations' },
    { titleKey: 'serverModuleSystemSettings', route: '/system-settings' },
  ];

  aboutToAppear(): void {
    this.loadCurrentServer();
  }

  private text(key: string): string {
    return this.bridge.text(key);
  }

  private async loadCurrentServer(): Promise<void> {
    this.isLoading = true;
    this.loadError = '';
    try {
      const server = await this.bridge.invoke<Map<string, Object | null> | null>('getCurrentServer');
      if (server === null) {
        this.currentServerId = '';
        this.currentServerName = '';
        this.isOnePanel = false;
      } else {
        this.currentServerId = server.get('id') as string;
        this.currentServerName = server.get('name') as string;
        this.isOnePanel = server.get('panelType') === '1panel';
      }
    } catch (error) {
      this.loadError = `${error}`;
    } finally {
      this.isLoading = false;
    }
  }

  private async openDestination(route: string): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      if (this.currentServerId.length > 0) {
        args.set('serverId', this.currentServerId);
      }
      await this.bridge.openFlutterPage(route, args);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  @Builder
  private moduleRow(destination: HarmonyModuleDestination) {
    ListItem() {
      Button({ type: ButtonType.Normal }) {
        Row({ space: 12 }) {
          Text(this.text(destination.titleKey))
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .layoutWeight(1)
            .maxLines(2)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
      .borderRadius(16)
      .id(`harmony.modules.${destination.titleKey}`)
      .accessibilityText(this.text(destination.titleKey))
      .onClick((): void => {
        this.openDestination(destination.route);
      })
    }
  }

  build() {
    Column({ space: 16 }) {
      if (this.isLoading) {
        LoadingProgress()
          .width(40)
          .height(40)
          .accessibilityText(this.text('commonLoading'))
      } else if (this.loadError.length > 0) {
        Text(this.loadError)
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
        Button(this.text('commonRetry'))
          .constraintSize({ minWidth: 48, minHeight: 48 })
          .onClick((): void => {
            this.loadCurrentServer();
          })
      } else {
        Row({ space: 12 }) {
          Text(this.currentServerName)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .layoutWeight(1)
            .maxLines(2)
          Button(this.text('commonRefresh'))
            .constraintSize({ minWidth: 48, minHeight: 48 })
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .onClick((): void => {
              this.loadCurrentServer();
            })
        }
        .width('100%')
        if (this.currentServerId.length === 0) {
          Text(this.text('noServerSelectedDescription'))
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .width('100%')
        }
        Button(this.text('settingsServerManagement'))
          .width('100%')
          .constraintSize({ minHeight: 48 })
          .onClick((): void => {
            this.openDestination('/server');
          })
        if (this.isOnePanel) {
          List({ space: 8 }) {
            ForEach(this.destinations, (destination: HarmonyModuleDestination) => {
              this.moduleRow(destination)
            }, (destination: HarmonyModuleDestination): string => destination.route)
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
        }
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 16, bottom: 24 })
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
