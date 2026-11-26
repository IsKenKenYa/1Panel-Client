import { Available } from '@kit.BasicServicesKit';
import { HarmonyNativeBridge } from './HarmonyNativeBridge';
import { HarmonyAppsPage } from './apps/HarmonyAppsPage';
import { HarmonyBackupsPage } from './automation/HarmonyBackupsPage';
import { HarmonyCommandsPage } from './automation/HarmonyCommandsPage';
import { HarmonyCronjobsPage } from './automation/HarmonyCronjobsPage';
import { HarmonyGroupsPage } from './automation/HarmonyGroupsPage';
import { HarmonyScriptsPage } from './automation/HarmonyScriptsPage';
import { HarmonyContainersPage } from './containers/HarmonyContainersPage';
import { HarmonyComputePage } from './compute/HarmonyComputePage';
import { HarmonyDatabasesPage } from './databases/HarmonyDatabasesPage';
import { HarmonyFilesPage } from './files/HarmonyFilesPage';
import { HarmonyFileTransfersPage } from './files/HarmonyFileTransfersPage';
import { HarmonyFileContentPage } from './files/HarmonyFileContentPage';
import { HarmonyFileSecondaryPage } from './files/HarmonyFileSecondaryPage';
import { HarmonyHostOperationsPage } from './host/HarmonyHostOperationsPage';
import { HarmonyHostActivityPage } from './host/HarmonyHostActivityPage';
import { HarmonyHostFirewallV2Page } from './host/HarmonyHostFirewallV2Page';
import { HarmonyHostToolboxPage } from './host/HarmonyHostToolboxPage';
import { HarmonyOrchestrationPage } from './orchestration/HarmonyOrchestrationPage';
import { HarmonyPanelPage } from './panel/HarmonyPanelPage';
import { HarmonyServersPage } from './servers/HarmonyServersPage';
import { HarmonyAboutPage } from './settings/HarmonyAboutPage';
import { HarmonyAppLockPage } from './settings/HarmonyAppLockPage';
import { HarmonyFeedbackPage } from './settings/HarmonyFeedbackPage';
import { HarmonyLanguagePage } from './settings/HarmonyLanguagePage';
import { HarmonyLegalPage } from './settings/HarmonyLegalPage';
import { HarmonyLogPreviewPage } from './settings/HarmonyLogPreviewPage';
import { HarmonySdkDisclosurePage } from './settings/HarmonySdkDisclosurePage';
import { HarmonySecurityVerificationPage } from './settings/HarmonySecurityVerificationPage';
import { HarmonyStoragePage } from './settings/HarmonyStoragePage';
import { HarmonyThemePage } from './settings/HarmonyThemePage';
import { HarmonyWebsitesPage } from './websites/HarmonyWebsitesPage';
import { HarmonyWebsiteSslCenterPage } from './websites/ssl/HarmonyWebsiteSslCenterPage';
import { HarmonyRuntimesPage } from './websites/runtimes/HarmonyRuntimesPage';

@Available({ minApiVersion: '26.0.0' })
@Component
export struct HarmonyNativeDestination {
  route: string = '';
  tab: boolean = false;
  routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  onBack: () => void = (): void => {};

  @Builder
  private module() {
    if (this.route === '/server' || this.route === '/server-selection' ||
      this.route === '/server-config' || this.route === '/server-detail') {
      HarmonyServersPage({ initialRoute: this.route, routeArguments: this.routeArguments, onBack: this.onBack })
    } else if (this.route === '/files') {
      HarmonyFilesPage({ initialPath: this.routeArguments.get('path') as string ?? '/' })
    } else if (this.route.startsWith('/container')) {
      HarmonyContainersPage({ initialRoute: this.route, routeArguments: this.routeArguments })
    } else if (this.route === '/orchestration' || this.route === '/compose-templates') {
      HarmonyOrchestrationPage({
        initialRoute: this.route, routeArguments: this.routeArguments,
      })
    } else if (this.route === '/apps' || this.route === '/app-store' ||
      this.route === '/app-detail' || this.route === '/installed-app-detail') {
      HarmonyAppsPage({ initialRoute: this.route, routeArguments: this.routeArguments })
    } else if (this.route.startsWith('/database')) {
      HarmonyDatabasesPage({ initialRoute: this.route, routeArguments: this.routeArguments })
    } else if (this.route === '/website-ssl-center' || this.route === '/website-certificate-detail' ||
      this.route === '/website-site-ssl' || this.route === '/website/https') {
      HarmonyWebsiteSslCenterPage({
        initialRoute: this.route, routeArguments: this.routeArguments,
      })
    } else if (this.route.startsWith('/website') || this.route.startsWith('/openresty') ||
      this.route === '/security-gateway') {
      HarmonyWebsitesPage({ initialRoute: this.route, routeArguments: this.routeArguments })
    } else if (this.route.startsWith('/runtimes')) {
      HarmonyRuntimesPage({ initialRoute: this.route, routeArguments: this.routeArguments })
    } else if (this.route.startsWith('/ai') || this.route === '/vm' || this.route === '/alert') {
      HarmonyComputePage({
        initialRoute: this.route, routeArguments: this.routeArguments,
      })
    } else if (this.route.startsWith('/system-settings') || this.route === '/panel-ssl') {
      HarmonyPanelPage({ initialRoute: this.route, routeArguments: this.routeArguments })
    } else if (this.route.startsWith('/commands')) {
      HarmonyCommandsPage({ routeArguments: this.routeArguments })
    } else if (this.route.startsWith('/cronjobs')) {
      HarmonyCronjobsPage({
        initialRoute: this.route, routeArguments: this.routeArguments,
      })
    } else if (this.route.startsWith('/backups')) {
      HarmonyBackupsPage({
        initialRoute: this.route, routeArguments: this.routeArguments,
      })
    } else if (this.route === '/scripts') {
      HarmonyScriptsPage()
    } else if (this.route === '/operations/groups') {
      HarmonyGroupsPage({ routeArguments: this.routeArguments })
    } else if (this.route === '/operations' || this.route === '/logs' || this.route === '/logs/task/detail') {
      HarmonyHostActivityPage({ initialRoute: this.route, routeArguments: this.routeArguments })
    } else if (this.route.startsWith('/toolbox')) {
      HarmonyHostToolboxPage({ initialRoute: this.route })
    } else if (this.route.startsWith('/firewall-v2')) {
      HarmonyHostFirewallV2Page({ initialRoute: this.route })
    } else if (this.route === '/dashboard' || this.route === '/monitoring' || this.route === '/terminal' ||
      this.route === '/hosts/diagnostics' || this.route.startsWith('/hosts-assets') ||
      this.route.startsWith('/ssh') || this.route.startsWith('/processes') ||
      this.route.startsWith('/firewall') || this.route === '/logs/system') {
      HarmonyHostOperationsPage({ initialRoute: this.route, routeArguments: this.routeArguments, onBack: this.onBack })
    } else {
      Column({ space: 16 }) {
        Text(HarmonyNativeBridge.instance.text('commonEmpty'))
          .fontColor($r('sys.color.font_secondary'))
        Button(HarmonyNativeBridge.instance.text('commonBack'))
          .height(48)
          .onClick((): void => { this.onBack(); })
      }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    }
  }

  build() {
    if (this.tab && this.route !== '/security-verification') {
      this.module()
    } else if (this.route === '/settings/theme') {
      HarmonyThemePage()
    } else if (this.route === '/settings/language') {
      HarmonyLanguagePage()
    } else if (this.route === '/settings/app-lock') {
      HarmonyAppLockPage()
    } else if (this.route === '/settings/storage') {
      HarmonyStoragePage()
    } else if (this.route === '/settings/about') {
      HarmonyAboutPage()
    } else if (this.route === '/settings/feedback-center') {
      HarmonyFeedbackPage()
    } else if (this.route === '/settings/feedback-center/logs') {
      HarmonyLogPreviewPage()
    } else if (this.route === '/settings/legal-center') {
      HarmonyLegalPage()
    } else if (this.route === '/settings/legal-center/mainland-sdk') {
      HarmonySdkDisclosurePage()
    } else if (this.route === '/security-verification') {
      HarmonySecurityVerificationPage({ inTab: this.tab })
    } else if (this.route === '/files/transfers') {
      HarmonyFileTransfersPage({ directory: this.routeArguments.get('path') as string })
    } else if (this.route === '/files/preview' || this.route === '/files/editor') {
      HarmonyFileContentPage({
        editable: this.route === '/files/editor', routeArguments: this.routeArguments, onBack: this.onBack,
      })
    } else if (this.route.startsWith('/files/')) {
      HarmonyFileSecondaryPage({ route: this.route, routeArguments: this.routeArguments })
    } else {
      NavDestination() {
        this.module()
      }
      .hideTitleBar(true)
      .backgroundColor($r('sys.color.background_secondary'))
    }
  }
}
