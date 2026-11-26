import { LengthMetrics, SymbolGlyphModifier, uiMaterial, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Available, deviceInfo } from '@kit.BasicServicesKit';
import { KeyCode } from '@kit.InputKit';
import { HarmonyNativeBridge } from './HarmonyNativeBridge';
import { HarmonyNativeDestination } from './HarmonyNativeDestination';
import { HarmonyServersPage } from './servers/HarmonyServersPage';
import { HarmonySettingsPage } from './settings/HarmonySettingsPage';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyNativeShell {
  @StorageLink('harmonySelectedTab') private selectedTab: number = 0;
  @State private translationsReady: boolean = false;
  @State private loadError: string = '';
  @State private windowPadding: Padding = { top: 0, left: 0, right: 0 };
  @State private bottomInset: number = 0;
  @State private showingDestination: boolean = false;
  /** 平板和 2in1 窗口在 md 断点、其余设备在 lg 断点切换为侧边导航。 */
  @State private wideLayout: boolean = false;
  /** 侧栏当前选中模块；宽屏列出全部模块，与底部页签的两槽位模型相互独立。 */
  @State private selectedModule: string = 'servers';
  @StorageLink('harmonyNativeRefresh') @Watch('refreshPresentation') private presentationRevision: number = 0;
  @StorageLink('harmonyThemeMode') private themeMode: string = 'system';
  @StorageLink('harmonyRootRoute') private rootRoute: string = '';
  @StorageLink('harmonyPinnedModules') @Watch('pinnedModulesChanged') private pinnedModules: string[] =
    ['files', 'containers'];
  private navigationMaterial: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    interactive: true,
    lightEffect: {},
  });
  private mainWindow: window.Window | null = null;
  private active: boolean = false;
  private readonly pages: NavPathStack = new NavPathStack();
  private readonly bridge: HarmonyNativeBridge = HarmonyNativeBridge.instance;
  private serverSymbol: TabBarSymbol = {
    normal: new SymbolGlyphModifier($r('sys.symbol.externaldrive')),
  };
  private filesSymbol: TabBarSymbol = {
    normal: new SymbolGlyphModifier($r('sys.symbol.folder')),
  };
  private containersSymbol: TabBarSymbol = {
    normal: new SymbolGlyphModifier($r('sys.symbol.square_stack_3d')),
  };
  private settingsSymbol: TabBarSymbol = {
    normal: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
  };
  private avoidAreaChanged: (event: window.AvoidAreaOptions) => void =
    (event: window.AvoidAreaOptions): void => {
      const mainWindow = this.mainWindow;
      if (mainWindow !== null && (event.type === window.AvoidAreaType.TYPE_SYSTEM ||
        event.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR ||
        event.type === window.AvoidAreaType.TYPE_FLOAT_NAVIGATION ||
        event.type === window.AvoidAreaType.TYPE_CUTOUT)) {
        this.updateWindowPadding(mainWindow);
      }
    };
  private windowSizeChanged: (size: window.Size) => void = (_size: window.Size): void => {
    const mainWindow = this.mainWindow;
    if (mainWindow !== null) {
      this.updateWindowPadding(mainWindow);
    }
  };

  aboutToAppear(): void {
    this.active = true;
    this.bridge.setNativePageHandler(async (
      route: string, args: Map<string, Object | null>,
    ): Promise<void> => {
      await this.bridge.setActiveRoute(route);
      this.pages.pushPath({ name: route, param: args });
    });
    this.pages.setInterception({
      willShow: (_from: NavDestinationContext | NavBar, to: NavDestinationContext | NavBar,
        operation: NavigationOperation): void => {
        this.showingDestination = to !== 'navBar';
        if (operation === NavigationOperation.POP) {
          this.bridge.setActiveRoute(to === 'navBar' ? null : to.pathInfo.name);
        }
      },
    });
    this.prepareWindow();
  }

  aboutToDisappear(): void {
    this.active = false;
    HarmonyNativeBridge.instance.setNativePageHandler(null);
    this.mainWindow?.off('avoidAreaChange', this.avoidAreaChanged);
    this.mainWindow?.off('windowSizeChange', this.windowSizeChanged);
    this.mainWindow = null;
  }

  private async prepareWindow(): Promise<void> {
    this.loadError = '';
    try {
      if (this.mainWindow === null) {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const mainWindow = await window.getLastWindow(context);
        if (!this.active) {
          return;
        }
        await mainWindow.setFloatNavigationAvoidAreaEnabled(true);
        this.updateWindowPadding(mainWindow);
        mainWindow.on('avoidAreaChange', this.avoidAreaChanged);
        mainWindow.on('windowSizeChange', this.windowSizeChanged);
        this.mainWindow = mainWindow;
      }
      await this.refreshPresentation();
    } catch (error) {
      this.loadError = (error as Error).message;
    }
  }

  private updateWindowPadding(mainWindow: window.Window): void {
    const systemArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const navigationArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    const floatNavigationArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_FLOAT_NAVIGATION);
    const cutoutArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
    const context = this.getUIContext();
    this.windowPadding = {
      top: context.px2vp(Math.max(systemArea.topRect.height, navigationArea.topRect.height,
        floatNavigationArea.topRect.height, cutoutArea.topRect.height)),
      left: context.px2vp(Math.max(systemArea.leftRect.width, navigationArea.leftRect.width,
        floatNavigationArea.leftRect.width, cutoutArea.leftRect.width)),
      right: context.px2vp(Math.max(systemArea.rightRect.width, navigationArea.rightRect.width,
        floatNavigationArea.rightRect.width, cutoutArea.rightRect.width)),
    };
    this.bottomInset = context.px2vp(Math.max(systemArea.bottomRect.height, navigationArea.bottomRect.height,
      floatNavigationArea.bottomRect.height, cutoutArea.bottomRect.height));
    const widthBreakpoint = context.getWindowWidthBreakpoint();
    const tabletOrDesktop = deviceInfo.deviceType === 'tablet' || deviceInfo.deviceType === '2in1';
    this.wideLayout = widthBreakpoint === WidthBreakpoint.WIDTH_LG ||
      widthBreakpoint === WidthBreakpoint.WIDTH_XL ||
      (tabletOrDesktop && widthBreakpoint === WidthBreakpoint.WIDTH_MD);
  }

  private colorMode(): ThemeColorMode {
    if (this.themeMode === 'light') {
      return ThemeColorMode.LIGHT;
    }
    if (this.themeMode === 'dark') {
      return ThemeColorMode.DARK;
    }
    return ThemeColorMode.SYSTEM;
  }

  private async selectTab(index: number): Promise<void> {
    const module = ['servers', ...this.pinnedModules, 'settings'][index];
    this.selectedModule = module;
    await this.bridge.setActiveModule(module);
    this.selectedTab = index;
  }

  /** 宽屏侧栏切换模块；底部页签的置顶槽位对应关系保持不变。 */
  private async selectModule(module: string): Promise<void> {
    this.selectedModule = module;
    await this.bridge.setActiveModule(module);
  }

  /**
   * 宽屏内容区按模块一分支构造页面。每个模块各自持有独立分支，
   * 切换时旧分支销毁、新分支重建，页面实例与它的 route 参数一起更新。
   */
  @Builder
  private sidebarPage() {
    if (this.selectedModule === 'servers') {
      HarmonyServersPage({ initialRoute: this.rootRoute === '/server-config' ? this.rootRoute : '/server' })
    } else if (this.selectedModule === 'files') {
      HarmonyNativeDestination({ route: '/files', tab: true })
    } else if (this.selectedModule === 'containers') {
      HarmonyNativeDestination({ route: '/containers', tab: true })
    } else if (this.selectedModule === 'apps') {
      HarmonyNativeDestination({ route: '/apps', tab: true })
    } else if (this.selectedModule === 'websites') {
      HarmonyNativeDestination({ route: '/websites', tab: true })
    } else if (this.selectedModule === 'ai') {
      HarmonyNativeDestination({ route: '/ai', tab: true })
    } else if (this.selectedModule === 'vm') {
      HarmonyNativeDestination({ route: '/vm', tab: true })
    } else if (this.selectedModule === 'verification') {
      HarmonyNativeDestination({ route: '/security-verification', tab: true })
    } else {
      HarmonySettingsPage()
    }
  }

  private pinnedModulesChanged(): void {
    this.selectTab(this.selectedTab);
  }

  private async refreshPresentation(): Promise<void> {
    if (this.mainWindow === null) {
      return;
    }
    try {
      await this.bridge.loadTranslations();
      if (!this.translationsReady) await this.bridge.getPinnedModules();
      this.loadError = '';
      this.translationsReady = true;
    } catch (error) {
      this.loadError = (error as Error).message;
    }
  }

  private titleKey(module: string): string {
    switch (module) {
      case 'files': return 'filesPageTitle';
      case 'containers': return 'containerTitle';
      case 'apps': return 'appsPageTitle';
      case 'websites': return 'websitesPageTitle';
      case 'ai': return 'serverModuleAi';
      case 'vm': return 'serverModuleVm';
      case 'verification': return 'serverActionSecurity';
      default: return 'settingsPageTitle';
    }
  }

  private tabSymbol(module: string): TabBarSymbol {
    switch (module) {
      case 'files': return this.filesSymbol;
      case 'containers': return this.containersSymbol;
      case 'apps': return { normal: new SymbolGlyphModifier($r('sys.symbol.square_grid_2x2')) };
      case 'websites': return { normal: new SymbolGlyphModifier($r('sys.symbol.worldclock')) };
      case 'ai': return { normal: new SymbolGlyphModifier($r('sys.symbol.rays')) };
      case 'vm': return { normal: new SymbolGlyphModifier($r('sys.symbol.rectangle_split_3x1')) };
      default: return { normal: new SymbolGlyphModifier($r('sys.symbol.key_shield')) };
    }
  }

  @Builder
  private pinnedPage(module: string) {
    HarmonyNativeDestination({ route: module === 'verification' ? '/security-verification' : `/${module}`, tab: true })
      .padding({ bottom: 72 + this.bottomInset })
  }

  /** 宽屏侧栏按官方多设备规范列出全部模块，与底部页签的两槽位置顶模型相互独立。 */
  private sidebarModules(): string[] {
    return ['servers', 'files', 'containers', 'apps', 'websites', 'ai', 'vm', 'verification', 'settings'];
  }

  private sidebarSymbol(module: string): Resource {
    if (module === 'servers') return $r('sys.symbol.externaldrive');
    if (module === 'settings') return $r('sys.symbol.gearshape');
    return this.tabSymbolResource(module);
  }

  private tabSymbolResource(module: string): Resource {
    switch (module) {
      case 'files': return $r('sys.symbol.folder');
      case 'containers': return $r('sys.symbol.square_stack_3d');
      case 'apps': return $r('sys.symbol.square_grid_2x2');
      case 'websites': return $r('sys.symbol.worldclock');
      case 'ai': return $r('sys.symbol.rays');
      case 'vm': return $r('sys.symbol.rectangle_split_3x1');
      default: return $r('sys.symbol.key_shield');
    }
  }

  private sidebarLabel(module: string): string {
    if (module === 'servers') return HarmonyNativeBridge.instance.text('serverPageTitle');
    if (module === 'settings') return HarmonyNativeBridge.instance.text('settingsPageTitle');
    return this.bridge.text(this.titleKey(module));
  }

  @Builder
  private sidebarRow(module: string) {
    Row({ space: 12 }) {
      SymbolGlyph(this.sidebarSymbol(module))
        .fontSize(24)
        .fontColor([this.selectedModule === module ? $r('sys.color.font_emphasize') : $r('sys.color.icon_primary')])
      Text(this.sidebarLabel(module)).fontSize(16).layoutWeight(1).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor(this.selectedModule === module ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
        .accessibilityLevel('no')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .borderRadius(16)
    .backgroundColor(this.selectedModule === module ? $r('sys.color.comp_background_primary') : Color.Transparent)
    .focusable(true)
    .focusOnTouch(true)
    .focusBox({ margin: LengthMetrics.vp(2) })
    .hoverEffect(HoverEffect.Highlight)
    .onClick((): void => { this.selectModule(module); })
    .onKeyEvent((event?: KeyEvent): boolean => {
      if (event !== undefined && event.type === KeyType.Down &&
        (event.keyCode === KeyCode.KEYCODE_ENTER || event.keyCode === KeyCode.KEYCODE_SPACE)) {
        this.selectModule(module);
        return true;
      }
      return false;
    })
    .accessibilityRole(AccessibilityRoleType.NAVIGATION_BAR)
    .accessibilityText(this.sidebarLabel(module))
  }

  @Builder
  private sidebarContent() {
    List({ space: 4 }) {
      ForEach(this.sidebarModules(), (module: string): void => {
        ListItem() { this.sidebarRow(module) }
      }, (module: string): string => module)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 8, right: 8, top: 8, bottom: 16 })
    .scrollBar(BarState.Auto)
  }

  @Builder
  private shellContent() {
    Column() {
      if (this.loadError.length > 0) {
        Column({ space: 16 }) {
          Text(this.loadError)
            .fontColor($r('sys.color.font_primary'))
          Button(HarmonyNativeBridge.instance.text('commonRetry'))
            .height(48)
            .onClick((): void => { this.prepareWindow(); })
        }
        .padding(24)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.translationsReady) {
        LoadingProgress()
          .width(48)
          .height(48)
      } else if (this.wideLayout) {
        Row() {
          Column() {
            this.sidebarContent()
          }
          .width(240)
          .height('100%')
          .backgroundColor($r('sys.color.background_secondary'))
          .border({ width: { right: 0.5 }, color: $r('sys.color.comp_divider') })
          Column() {
            this.sidebarPage()
          }
          .layoutWeight(1)
          .height('100%')
        }
        .width('100%')
        .height('100%')
      } else {
        Tabs({ barPosition: BarPosition.End, index: this.selectedTab }) {
          TabContent() {
            if (this.selectedTab === 0) {
              HarmonyServersPage({ initialRoute: this.rootRoute === '/server-config' ? this.rootRoute : '/server' })
                .padding({ bottom: 72 + this.bottomInset })
            }
          }
          .tabBar(BottomTabBarStyle.of(this.serverSymbol,
            HarmonyNativeBridge.instance.text('serverPageTitle')))
          TabContent() {
            if (this.selectedTab === 1) {
              this.pinnedPage(this.pinnedModules[0])
            }
          }
          .tabBar(BottomTabBarStyle.of(this.tabSymbol(this.pinnedModules[0]),
            this.bridge.text(this.titleKey(this.pinnedModules[0]))))
          TabContent() {
            if (this.selectedTab === 2) {
              this.pinnedPage(this.pinnedModules[1])
            }
          }
          .tabBar(BottomTabBarStyle.of(this.tabSymbol(this.pinnedModules[1]),
            this.bridge.text(this.titleKey(this.pinnedModules[1]))))
          TabContent() {
            if (this.selectedTab === 3) {
              HarmonySettingsPage()
                .padding({ bottom: 72 + this.bottomInset })
            }
          }
          .tabBar(BottomTabBarStyle.of(this.settingsSymbol,
            HarmonyNativeBridge.instance.text('settingsPageTitle')))
        }
        .vertical(false)
        .barOverlap(true)
        .barFloatingStyle({
          barBottomMargin: this.bottomInset,
          maskHeight: 0,
          systemMaterial: this.navigationMaterial,
        })
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
        .height(LayoutPolicy.matchParent)
        .scrollable(false)
        .barHeight(48)
        .onChange((index: number): void => { this.selectTab(index); })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  private destination(route: string, args: Map<string, Object | null>) {
    HarmonyNativeDestination({
      route: route,
      routeArguments: args,
      onBack: (): void => { this.pages.pop(); },
    })
  }

  build() {
    WithTheme({ colorMode: this.colorMode() }) {
      Column() {
        Navigation(this.pages) {
          this.shellContent()
        }
        .hideTitleBar(true)
        .mode(NavigationMode.Stack)
        .navDestination(this.destination)
        .width('100%')
        .height(LayoutPolicy.matchParent)
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .padding({
        top: this.windowPadding.top,
        left: this.windowPadding.left,
        right: this.windowPadding.right,
        bottom: this.wideLayout || this.showingDestination ? this.bottomInset : 0,
      })
      .backgroundColor($r('sys.color.background_secondary'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
  }
}
