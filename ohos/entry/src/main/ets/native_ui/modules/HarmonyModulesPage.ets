import { HarmonyNativeBridge, sheetMaterial } from '../HarmonyNativeBridge';

interface HarmonyModuleDestination {
  titleKey: string;
  route: string;
  icon: Resource;
  group: string;
  pin?: string;
}

@Component
export struct HarmonyModulesPage {
  @State private isLoading: boolean = true;
  @State private loadError: string = '';
  @State private currentServerName: string = '';
  @State private currentServerId: string = '';
  @State private isOnePanel: boolean = false;
  @State private pins: string[] = [];
  @State private primaryPin: string = '';
  @State private secondaryPin: string = '';
  @State private pinSheetVisible: boolean = false;
  @State private savingPins: boolean = false;
  @State private pinError: string = '';

  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private readonly destinations: HarmonyModuleDestination[] = [
    { titleKey: 'serverModuleDashboard', route: '/dashboard', icon: $r('sys.symbol.dial'), group: 'system' },
    { titleKey: 'operationsHostAssetsTitle', route: '/hosts-assets', icon: $r('sys.symbol.externaldrive'), group: 'system' },
    { titleKey: 'operationsSshTitle', route: '/ssh', icon: $r('sys.symbol.lock'), group: 'system' },
    { titleKey: 'operationsProcessesTitle', route: '/processes', icon: $r('sys.symbol.list_bullet'), group: 'system' },
    { titleKey: 'operationsSystemLogViewerTitle', route: '/logs/system', icon: $r('sys.symbol.doc_text'), group: 'system' },
    { titleKey: 'hostDiagnosticsTitle', route: '/hosts/diagnostics', icon: $r('sys.symbol.gearshape'), group: 'system' },
    { titleKey: 'serverModuleFiles', route: '/files', icon: $r('sys.symbol.folder'), group: 'system', pin: 'files' },
    { titleKey: 'serverModuleContainers', route: '/containers', icon: $r('sys.symbol.rectangle_on_rectangle'),
      group: 'system', pin: 'containers' },
    { titleKey: 'serverModuleRuntime', route: '/runtimes', icon: $r('sys.symbol.puzzle'), group: 'apps' },
    { titleKey: 'serverModuleApps', route: '/apps', icon: $r('sys.symbol.square_grid_2x2'), group: 'apps', pin: 'apps' },
    { titleKey: 'serverModuleWebsites', route: '/websites', icon: $r('sys.symbol.worldclock'),
      group: 'apps', pin: 'websites' },
    { titleKey: 'serverModuleDatabases', route: '/databases', icon: $r('sys.symbol.externaldrive'), group: 'apps' },
    { titleKey: 'serverModuleAi', route: '/ai', icon: $r('sys.symbol.rays'), group: 'apps', pin: 'ai' },
    { titleKey: 'serverModuleVm', route: '/vm', icon: $r('sys.symbol.rectangle_split_3x1'), group: 'apps', pin: 'vm' },
    { titleKey: 'alertPageTitle', route: '/alert', icon: $r('sys.symbol.bell_fill'), group: 'system' },
    { titleKey: 'serverModuleFirewall', route: '/firewall', icon: $r('sys.symbol.checkmark_shield'), group: 'system' },
    { titleKey: 'serverModuleTerminal', route: '/terminal', icon: $r('sys.symbol.doc_plaintext'), group: 'system' },
    { titleKey: 'serverModuleMonitoring', route: '/monitoring', icon: $r('sys.symbol.clock'), group: 'system' },
    { titleKey: 'serverActionSecurity', route: '/security-verification', icon: $r('sys.symbol.key_shield'),
      group: 'system', pin: 'verification' },
    { titleKey: 'openrestyPageTitle', route: '/openresty', icon: $r('sys.symbol.worldclock_fill'), group: 'apps' },
    { titleKey: 'operationsCenterServerEntryTitle', route: '/operations', icon: $r('sys.symbol.slider_horizontal_2'), group: 'system' },
    { titleKey: 'serverModuleSystemSettings', route: '/system-settings', icon: $r('sys.symbol.gearshape'), group: 'settings' },
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
      this.pins = await this.bridge.getPinnedModules();
    } catch (error) {
      this.loadError = `${error}`;
    } finally {
      this.isLoading = false;
    }
  }

  private pinOptions(): HarmonyModuleDestination[] {
    return this.destinations.filter((entry: HarmonyModuleDestination): boolean => entry.pin !== undefined);
  }

  private pinnedDestinations(): HarmonyModuleDestination[] {
    return this.destinations.filter((entry: HarmonyModuleDestination): boolean =>
      entry.pin === this.pins[0] || entry.pin === this.pins[1])
      .sort((left: HarmonyModuleDestination, right: HarmonyModuleDestination): number =>
        left.pin === this.pins[0] ? -1 : right.pin === this.pins[0] ? 1 : 0);
  }

  private groupDestinations(group: string): HarmonyModuleDestination[] {
    return this.destinations.filter((entry: HarmonyModuleDestination): boolean =>
      entry.group === group && (entry.pin === undefined || !this.pins.includes(entry.pin)));
  }

  private openPinSheet(): void {
    this.primaryPin = this.pins[0];
    this.secondaryPin = this.pins[1];
    this.pinError = '';
    this.pinSheetVisible = true;
  }

  private async savePins(reset: boolean): Promise<void> {
    if (this.savingPins) return;
    this.savingPins = true;
    this.pinError = '';
    try {
      this.pins = reset ? await this.bridge.setPinnedModules() :
        await this.bridge.setPinnedModules(this.primaryPin, this.secondaryPin);
      this.pinSheetVisible = false;
    } catch (error) {
      this.pinError = (error as Error).message;
    } finally {
      this.savingPins = false;
    }
  }

  private pinChoices(): SelectOption[] {
    return this.pinOptions().map((entry: HarmonyModuleDestination): SelectOption => ({
      value: this.text(entry.titleKey),
    }));
  }

  private pinIndex(pin: string): number {
    return this.pinOptions().findIndex((entry: HarmonyModuleDestination): boolean => entry.pin === pin);
  }

  @Builder
  private pinControl(titleKey: string, selectedPin: string, primary: boolean) {
    Row({ space: 12 }) {
      Text(this.text(titleKey)).fontSize(16).layoutWeight(1)
      Select(this.pinChoices())
        .selected(this.pinIndex(selectedPin))
        .value(this.text(this.pinOptions()[this.pinIndex(selectedPin)].titleKey))
        .height(48).accessibilityText(this.text(titleKey)).enabled(!this.savingPins)
        .onSelect((index: number): void => {
          const pin = this.pinOptions()[index].pin as string;
          if (primary) {
            this.primaryPin = pin;
          } else {
            this.secondaryPin = pin;
          }
        })
    }.width('100%')
  }

  @Builder
  private pinSheet() {
    Column({ space: 16 }) {
      Text(this.text('shellPinnedModulesTitle')).fontSize(20).fontWeight(FontWeight.Medium)
      Text(this.text('shellPinnedModulesDescription')).fontSize(14).fontColor($r('sys.color.font_secondary'))
      this.pinControl('shellPinnedModulesPrimary', this.primaryPin, true)
      this.pinControl('shellPinnedModulesSecondary', this.secondaryPin, false)
      if (this.pinError.length > 0) {
        Text(this.pinError).fontColor($r('sys.color.ohos_id_color_alert'))
      }
      Row({ space: 12 }) {
        Button(this.text('commonReset')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
          .enabled(!this.savingPins).onClick((): void => { this.savePins(true); })
        Button(this.text('commonSave')).height(48)
          .enabled(!this.savingPins && this.primaryPin !== this.secondaryPin)
          .onClick((): void => { this.savePins(false); })
      }.width('100%').justifyContent(FlexAlign.End)
    }.width('100%').padding(24).alignItems(HorizontalAlign.Start)
  }

  @Builder
  private pinnedHeader() {
    Row({ space: 12 }) {
      Text(this.text('shellPinnedModulesTitle')).fontSize(14).fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)
      Button(this.text('shellPinnedModulesCustomize')).height(48).buttonStyle(ButtonStyleMode.TEXTUAL)
        .onClick((): void => { this.openPinSheet(); })
    }.width('100%').padding({ left: 16, right: 8 })
  }

  private async openDestination(route: string): Promise<void> {
    try {
      const args = new Map<string, Object | null>();
      if (this.currentServerId.length > 0) {
        args.set('serverId', this.currentServerId);
      }
      await this.bridge.openNativePage(route, args);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: `${error}`.slice(0, 120) });
    }
  }

  @Builder
  private moduleHeader(titleKey: string) {
    Text(this.text(titleKey)).fontSize(14).fontColor($r('sys.color.font_secondary'))
      .padding({ left: 16, top: 8, bottom: 8 })
  }

  @Builder
  private moduleRow(destination: HarmonyModuleDestination) {
    ListItem() {
      Button({ type: ButtonType.Normal }) {
        Row({ space: 12 }) {
          SymbolGlyph(destination.icon).fontSize(24).fontColor([$r('sys.color.icon_primary')])
          Text(this.text(destination.titleKey))
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
            .layoutWeight(1)
            .maxLines(2)
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([$r('sys.color.icon_tertiary')])
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
      .buttonStyle(ButtonStyleMode.TEXTUAL)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(0)
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
          .fontColor($r('sys.color.font_primary'))
        Button(this.text('commonRetry'))
          .constraintSize({ minWidth: 48, minHeight: 48 })
          .onClick((): void => {
            this.loadCurrentServer();
          })
      } else {
        Row({ space: 12 }) {
          Text(this.currentServerName)
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
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
            .fontColor($r('sys.color.font_secondary'))
            .width('100%')
        }
        if (this.currentServerId.length === 0) {
          Button(this.text('settingsServerManagement'))
            .width('100%').constraintSize({ minHeight: 48 })
            .onClick((): void => { this.openDestination('/server'); })
        }
        if (this.isOnePanel) {
          List({ space: 16 }) {
            ListItemGroup({ header: this.pinnedHeader }) {
              ForEach(this.pinnedDestinations(), (destination: HarmonyModuleDestination): void => {
                this.moduleRow(destination)
              }, (destination: HarmonyModuleDestination): string => destination.route)
            }.borderRadius(16).clip(true)
            ListItemGroup({ header: this.moduleHeader('operationsCenterSystemSectionTitle') }) {
              ForEach(this.groupDestinations('system'),
                (destination: HarmonyModuleDestination): void => { this.moduleRow(destination) },
                (destination: HarmonyModuleDestination): string => destination.route)
            }.borderRadius(16).clip(true)
            ListItemGroup({ header: this.moduleHeader('operationsCenterRuntimeSectionTitle') }) {
              ForEach(this.groupDestinations('apps'),
                (destination: HarmonyModuleDestination): void => { this.moduleRow(destination) },
                (destination: HarmonyModuleDestination): string => destination.route)
            }.borderRadius(16).clip(true)
            ListItemGroup() {
              ForEach(this.destinations.filter((entry: HarmonyModuleDestination): boolean => entry.group === 'settings'),
                (destination: HarmonyModuleDestination): void => { this.moduleRow(destination) },
                (destination: HarmonyModuleDestination): string => destination.route)
            }.borderRadius(16).clip(true)
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
    .backgroundColor($r('sys.color.background_secondary'))
    .bindSheet($$this.pinSheetVisible, this.pinSheet, { height: SheetSize.FIT_CONTENT, dragBar: true, systemMaterial: sheetMaterial })
  }
}
