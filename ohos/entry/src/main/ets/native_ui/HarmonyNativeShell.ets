import { uiMaterial, window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from './HarmonyNativeBridge';
import { HarmonyServersPage } from './servers/HarmonyServersPage';
import { HarmonyFilesPage } from './files/HarmonyFilesPage';
import { HarmonyContainersPage } from './containers/HarmonyContainersPage';
import { HarmonySettingsPage } from './settings/HarmonySettingsPage';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyNativeShell {
  @StorageLink('harmonySelectedTab') private selectedTab: number = 0;
  @State private translationsReady: boolean = false;
  @State private loadError: string = '';
  @State private windowPadding: Padding = { top: 0, bottom: 0, left: 0, right: 0 };
  @StorageLink('harmonyNativeRefresh') @Watch('refreshPresentation') private presentationRevision: number = 0;
  @StorageLink('harmonyThemeMode') private themeMode: string = 'system';
  private navigationMaterial: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    interactive: true,
    lightEffect: {},
  });
  private mainWindow: window.Window | null = null;
  private active: boolean = false;
  private avoidAreaChanged: (event: window.AvoidAreaOptions) => void =
    (event: window.AvoidAreaOptions): void => {
      const mainWindow = this.mainWindow;
      if (mainWindow !== null && (event.type === window.AvoidAreaType.TYPE_SYSTEM ||
        event.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)) {
        this.updateWindowPadding(mainWindow);
      }
    };

  aboutToAppear(): void {
    this.active = true;
    this.prepareWindow();
  }

  aboutToDisappear(): void {
    this.active = false;
    this.mainWindow?.off('avoidAreaChange', this.avoidAreaChanged);
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
        this.updateWindowPadding(mainWindow);
        mainWindow.on('avoidAreaChange', this.avoidAreaChanged);
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
    const context = this.getUIContext();
    this.windowPadding = {
      top: context.px2vp(Math.max(systemArea.topRect.height, navigationArea.topRect.height)),
      bottom: context.px2vp(Math.max(systemArea.bottomRect.height, navigationArea.bottomRect.height)),
      left: context.px2vp(Math.max(systemArea.leftRect.width, navigationArea.leftRect.width)),
      right: context.px2vp(Math.max(systemArea.rightRect.width, navigationArea.rightRect.width)),
    };
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
    const module = ['servers', 'files', 'containers', 'settings'][index];
    await HarmonyNativeBridge.instance.setActiveModule(module);
    this.selectedTab = index;
  }

  private async refreshPresentation(): Promise<void> {
    if (this.mainWindow === null) {
      return;
    }
    this.translationsReady = false;
    try {
      await HarmonyNativeBridge.instance.loadTranslations();
      this.loadError = '';
      this.translationsReady = true;
    } catch (error) {
      this.loadError = (error as Error).message;
    }
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
      } else {
        Tabs({ barPosition: BarPosition.End, index: this.selectedTab }) {
          TabContent() {
            if (this.selectedTab === 0) {
              HarmonyServersPage()
                .padding({ bottom: 80 })
            }
          }
          .tabBar(HarmonyNativeBridge.instance.text('serverPageTitle'))
          TabContent() {
            if (this.selectedTab === 1) {
              HarmonyFilesPage()
                .padding({ bottom: 80 })
            }
          }
          .tabBar(HarmonyNativeBridge.instance.text('filesPageTitle'))
          TabContent() {
            if (this.selectedTab === 2) {
              HarmonyContainersPage()
                .padding({ bottom: 80 })
            }
          }
          .tabBar(HarmonyNativeBridge.instance.text('containerTitle'))
          TabContent() {
            if (this.selectedTab === 3) {
              HarmonySettingsPage()
                .padding({ bottom: 80 })
            }
          }
          .tabBar(HarmonyNativeBridge.instance.text('settingsPageTitle'))
        }
        .vertical(false)
        .barOverlap(true)
        .barFloatingStyle({ systemMaterial: this.navigationMaterial })
        .scrollable(false)
        .barHeight(64)
        .onChange((index: number): void => { this.selectTab(index); })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding(this.windowPadding)
    .backgroundColor($r('sys.color.background_primary'))
  }

  build() {
    WithTheme({ colorMode: this.colorMode() }) {
      this.shellContent()
    }
  }
}
