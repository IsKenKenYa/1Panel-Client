import 'package:flutter/services.dart';

import 'native_channel_port.dart';
import 'native_channel_read_handlers.dart';
import 'native_channel_write_handlers.dart';

/// Native Channel dispatcher.
///
/// Routes MethodChannel calls to [NativeChannelReadHandlers] or
/// [NativeChannelWriteHandlers]. Implements [NativeChannelPort] so tests
/// can substitute a mock (architecture review candidate ⑬/㉑).
///
/// The static API is preserved for backward compatibility with
/// `main.dart`'s single `init()` call; the instance API enables future
/// constructor-injection refactoring.
class NativeChannelManager implements NativeChannelPort {
  NativeChannelManager._();

  static final NativeChannelManager _instance = NativeChannelManager._();

  /// The singleton instance (for future DI refactoring).
  static NativeChannelPort get instance => _instance;

  static const MethodChannel _methodChannel =
      MethodChannel('com.onepanel.client/method');

  /// Static entry point called from `main.dart`.
  static void init() {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void initInstance() {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  Future<dynamic> handleMethodCall(String method, dynamic arguments) async {
    return _dispatch(method, arguments);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    return _dispatch(call.method, call.arguments);
  }

  static Future<dynamic> _dispatch(String method, dynamic arguments) async {
    switch (method) {
      // ── Read: 已有 ─────────────────────────────────────────────────────
      case 'getServers':
        return NativeChannelReadHandlers.getServers(arguments);
      case 'getFiles':
        return NativeChannelReadHandlers.getFiles(arguments);
      case 'getApps':
        return NativeChannelReadHandlers.getApps(arguments);
      case 'getWebsites':
        return NativeChannelReadHandlers.getWebsites(arguments);
      case 'getMonitoring':
        return NativeChannelReadHandlers.getMonitoring(arguments);
      case 'getContainers':
        return NativeChannelReadHandlers.getContainers(arguments);
      case 'getSettings':
        return NativeChannelReadHandlers.getSettings(arguments);
      case 'getTranslations':
        return NativeChannelReadHandlers.getTranslations();
      case 'getUIRenderMode':
        return NativeChannelReadHandlers.getUIRenderMode();

      // ── Read: 新增 ─────────────────────────────────────────────────────
      case 'getCommands':
        return NativeChannelWriteHandlers.getCommands(arguments);
      case 'createCommand':
        return NativeChannelWriteHandlers.createCommand(arguments);
      case 'deleteCommand':
        return NativeChannelWriteHandlers.deleteCommand(arguments);
      case 'getGroups':
        return NativeChannelWriteHandlers.getGroups(arguments);
      case 'bindAIDomain':
        return NativeChannelWriteHandlers.bindAIDomain(arguments);
      case 'getOllamaContext':
        return NativeChannelWriteHandlers.getOllamaContext(arguments);
      case 'getComposes':
        return NativeChannelReadHandlers.getComposes(arguments);
      case 'getPanelSslInfo':
        return NativeChannelReadHandlers.getPanelSslInfo(arguments);
      case 'getWebsiteCertificates':
        return NativeChannelReadHandlers.getWebsiteCertificates(arguments);
      case 'getScripts':
        return NativeChannelReadHandlers.getScripts(arguments);
      case 'getOperationLogs':
        return NativeChannelReadHandlers.getOperationLogs(arguments);
      case 'getLoginLogs':
        return NativeChannelReadHandlers.getLoginLogs(arguments);
      case 'getSystemLogContent':
        return NativeChannelReadHandlers.getSystemLogContent(arguments);
      case 'getOpenrestySnapshot':
        return NativeChannelReadHandlers.getOpenrestySnapshot(arguments);
      case 'getSshInfo':
        return NativeChannelReadHandlers.getSshInfo(arguments);
      case 'getSshConfig':
        return NativeChannelReadHandlers.getSshConfig(arguments);
      case 'getDeviceSnapshot':
        return NativeChannelReadHandlers.getDeviceSnapshot(arguments);
      case 'getDashboard':
        return NativeChannelReadHandlers.getDashboard(arguments);
      case 'getDatabases':
        return NativeChannelReadHandlers.getDatabases(arguments);
      case 'getFirewallRules':
        return NativeChannelReadHandlers.getFirewallRules(arguments);
      case 'getCronJobs':
        return NativeChannelReadHandlers.getCronJobs(arguments);
      case 'getBackups':
        return NativeChannelReadHandlers.getBackups(arguments);
      case 'getAIModels':
        return NativeChannelReadHandlers.getAIModels(arguments);
      case 'getWebsiteHttpsConfig':
        return NativeChannelReadHandlers.getWebsiteHttpsConfig(arguments);
      case 'getWebsiteProxies':
        return NativeChannelReadHandlers.getWebsiteProxies(arguments);
      case 'getWebsiteRedirects':
        return NativeChannelReadHandlers.getWebsiteRedirects(arguments);
      case 'getWebsiteRewrite':
        return NativeChannelReadHandlers.getWebsiteRewrite(arguments);
      case 'getWebsiteCors':
        return NativeChannelReadHandlers.getWebsiteCors(arguments);
      case 'getWebsiteLeech':
        return NativeChannelReadHandlers.getWebsiteLeech(arguments);
      case 'getWebsiteAuths':
        return NativeChannelReadHandlers.getWebsiteAuths(arguments);
      case 'getWebsitePathAuths':
        return NativeChannelReadHandlers.getWebsitePathAuths(arguments);
      case 'getWebsiteDomains':
        return NativeChannelReadHandlers.getWebsiteDomains(arguments);
      case 'getWebsiteLogs':
        return NativeChannelReadHandlers.getWebsiteLogs(arguments);
      case 'getFileContentHandler':
        return NativeChannelReadHandlers.getFileContentHandler(arguments);
      case 'getFavoritesHandler':
        return NativeChannelReadHandlers.getFavoritesHandler(arguments);

      // ── Write: 服务器 ───────────────────────────────────────────────────
      // ── Write: 服务器 ───────────────────────────────────────────────────
      case 'addServer':
        return NativeChannelWriteHandlers.addServer(arguments);

      case 'connectServer':
        return NativeChannelWriteHandlers.connectServer(arguments);
      case 'deleteServer':
        return NativeChannelWriteHandlers.deleteServer(arguments);

      // ── Write: 网站 ─────────────────────────────────────────────────────
      case 'createWebsite':
        return NativeChannelWriteHandlers.createWebsite(arguments);
      case 'toggleWebsiteStatus':
        return NativeChannelWriteHandlers.toggleWebsiteStatus(arguments);
      case 'deleteWebsite':
        return NativeChannelWriteHandlers.deleteWebsite(arguments);
      case 'updateWebsiteHttpsConfig':
        return NativeChannelWriteHandlers.updateWebsiteHttpsConfig(arguments);
      case 'updateWebsiteProxy':
        return NativeChannelWriteHandlers.updateWebsiteProxy(arguments);
      case 'deleteWebsiteProxy':
        return NativeChannelWriteHandlers.deleteWebsiteProxy(arguments);
      case 'updateWebsiteProxyStatus':
        return NativeChannelWriteHandlers.updateWebsiteProxyStatus(arguments);
      case 'updateWebsiteRedirect':
        return NativeChannelWriteHandlers.updateWebsiteRedirect(arguments);
      case 'updateWebsiteRewrite':
        return NativeChannelWriteHandlers.updateWebsiteRewrite(arguments);
      case 'updateWebsiteCors':
        return NativeChannelWriteHandlers.updateWebsiteCors(arguments);
      case 'updateWebsiteLeech':
        return NativeChannelWriteHandlers.updateWebsiteLeech(arguments);
      case 'updateWebsiteAuth':
        return NativeChannelWriteHandlers.updateWebsiteAuth(arguments);
      case 'updateWebsitePathAuth':
        return NativeChannelWriteHandlers.updateWebsitePathAuth(arguments);
      case 'addWebsiteDomains':
        return NativeChannelWriteHandlers.addWebsiteDomains(arguments);
      case 'deleteWebsiteDomain':
        return NativeChannelWriteHandlers.deleteWebsiteDomain(arguments);

      // ── Write: 容器 ─────────────────────────────────────────────────────
      case 'toggleContainerState':
        return NativeChannelWriteHandlers.toggleContainerState(arguments);
      case 'restartContainer':
        return NativeChannelWriteHandlers.restartContainer(arguments);
      case 'deleteContainer':
        return NativeChannelWriteHandlers.deleteContainer(arguments);

      // ── Write: 应用 ─────────────────────────────────────────────────────
      case 'startApp':
        return NativeChannelWriteHandlers.startApp(arguments);
      case 'stopApp':
        return NativeChannelWriteHandlers.stopApp(arguments);
      case 'uninstallApp':
        return NativeChannelWriteHandlers.uninstallApp(arguments);
      case 'installApp':
        return NativeChannelWriteHandlers.installApp(arguments);

      // ── Write: 文件 ─────────────────────────────────────────────────────
      case 'deleteFile':
        return NativeChannelWriteHandlers.deleteFile(arguments);
      case 'createFolder':
        return NativeChannelWriteHandlers.createFolder(arguments);
      case 'createFileHandler':
        return NativeChannelWriteHandlers.createFileHandler(arguments);
      case 'renameFileHandler':
        return NativeChannelWriteHandlers.renameFileHandler(arguments);
      case 'moveFilesHandler':
        return NativeChannelWriteHandlers.moveFilesHandler(arguments);
      case 'compressFilesHandler':
        return NativeChannelWriteHandlers.compressFilesHandler(arguments);
      case 'decompressFileHandler':
        return NativeChannelWriteHandlers.decompressFileHandler(arguments);
      case 'changeFileModeHandler':
        return NativeChannelWriteHandlers.changeFileModeHandler(arguments);
      case 'changeFileOwnerHandler':
        return NativeChannelWriteHandlers.changeFileOwnerHandler(arguments);
      case 'saveFileContentHandler':
        return NativeChannelWriteHandlers.saveFileContentHandler(arguments);
      case 'addFavoriteHandler':
        return NativeChannelWriteHandlers.addFavoriteHandler(arguments);
      case 'removeFavoriteHandler':
        return NativeChannelWriteHandlers.removeFavoriteHandler(arguments);
      case 'wgetDownloadHandler':
        return NativeChannelWriteHandlers.wgetDownloadHandler(arguments);

      // ── Write: 主机/工具箱 ──────────────────────────────────────────────
      case 'createCompose':
        return NativeChannelWriteHandlers.createCompose(arguments);
      case 'updateCompose':
        return NativeChannelWriteHandlers.updateCompose(arguments);
      case 'updateOpenrestyHttps':
        return NativeChannelWriteHandlers.updateOpenrestyHttps(arguments);
      case 'updateOpenrestyConfig':
        return NativeChannelWriteHandlers.updateOpenrestyConfig(arguments);
      case 'uploadCertificate':
        return NativeChannelWriteHandlers.uploadCertificate(arguments);
      case 'applyCertificate':
        return NativeChannelWriteHandlers.applyCertificate(arguments);
      case 'deleteScripts':
        return NativeChannelWriteHandlers.deleteScripts(arguments);
      case 'composeOperate':
        return NativeChannelWriteHandlers.composeOperate(arguments);
      case 'operateSsh':
        return NativeChannelWriteHandlers.operateSsh(arguments);
      case 'saveSshConfig':
        return NativeChannelWriteHandlers.saveSshConfig(arguments);
      case 'verifyToolboxDns':
        return NativeChannelWriteHandlers.verifyToolboxDns(arguments);

      // ── Write: 数据库 ───────────────────────────────────────────────────
      case 'createDatabase':
        return NativeChannelWriteHandlers.createDatabase(arguments);
      case 'deleteDatabase':
        return NativeChannelWriteHandlers.deleteDatabase(arguments);
      case 'updateDatabaseDescription':
        return NativeChannelWriteHandlers.updateDatabaseDescription(arguments);
      case 'changeDatabasePassword':
        return NativeChannelWriteHandlers.changeDatabasePassword(arguments);

      // ── Write: 定时任务 ─────────────────────────────────────────────────
      case 'toggleCronJobStatus':
        return NativeChannelWriteHandlers.toggleCronJobStatus(arguments);
      case 'createCronJob':
        return NativeChannelWriteHandlers.createCronJob(arguments);
      case 'updateCronJob':
        return NativeChannelWriteHandlers.updateCronJob(arguments);
      case 'handleCronJobOnce':
        return NativeChannelWriteHandlers.handleCronJobOnce(arguments);
      case 'deleteCronJob':
        return NativeChannelWriteHandlers.deleteCronJob(arguments);

      // ── Write: 备份 ─────────────────────────────────────────────────────
      case 'restoreBackup':
        return NativeChannelWriteHandlers.restoreBackup(arguments);
      case 'deleteBackup':
        return NativeChannelWriteHandlers.deleteBackup(arguments);

      // ── Write: AI ───────────────────────────────────────────────────────
      case 'createAIModel':
        return NativeChannelWriteHandlers.createAIModel(arguments);
      case 'recreateAIModel':
        return NativeChannelWriteHandlers.recreateAIModel(arguments);
      case 'deleteAIModel':
        return NativeChannelWriteHandlers.deleteAIModel(arguments);

      // ── Write: 防火墙 ───────────────────────────────────────────────────
      case 'addFirewallRule':
        return NativeChannelWriteHandlers.addFirewallRule(arguments);

      case 'deleteFirewallRule':
        return NativeChannelWriteHandlers.deleteFirewallRule(arguments);

      // ── Write: 设置 ─────────────────────────────────────────────────────
      case 'updateSetting':
        return NativeChannelWriteHandlers.updateSetting(arguments);

      // ── Write: 缓存 ─────────────────────────────────────────────────────
      case 'clearCache':
        return NativeChannelWriteHandlers.clearCache(arguments);

      default:
        throw MissingPluginException();
    }
  }
}
