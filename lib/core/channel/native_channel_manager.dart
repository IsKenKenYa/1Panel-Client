import 'package:flutter/services.dart';

import 'native_channel_database_deep_handlers.dart';
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
      case 'getCurrentServer':
        return NativeChannelReadHandlers.getCurrentServer();
      case 'getFiles':
        return NativeChannelReadHandlers.getFiles(arguments);
      case 'getApps':
        return NativeChannelReadHandlers.getApps(arguments);
      case 'getAppStore':
        return NativeChannelReadHandlers.getAppStore(arguments);
      case 'getAppVersions':
        return NativeChannelReadHandlers.getAppVersions(arguments);
      case 'getAppInstallForm':
        return NativeChannelReadHandlers.getAppInstallForm(arguments);
      case 'getAppInstallInfo':
        return NativeChannelReadHandlers.getAppInstallInfo(arguments);
      case 'getAppInstallParams':
        return NativeChannelReadHandlers.getAppInstallParams(arguments);
      case 'getAppDetailByKey':
        return NativeChannelReadHandlers.getAppDetailByKey(arguments);
      case 'getWebsites':
        return NativeChannelReadHandlers.getWebsites(arguments);
      case 'getWebsiteDetail':
        return NativeChannelReadHandlers.getWebsiteDetail(arguments);
      case 'getMonitoring':
        return NativeChannelReadHandlers.getMonitoring(arguments);
      case 'getContainers':
        return NativeChannelReadHandlers.getContainers(arguments);
      case 'getContainerLogs':
        return NativeChannelReadHandlers.getContainerLogs(arguments);
      case 'getContainerInspect':
        return NativeChannelReadHandlers.getContainerInspect(arguments);
      case 'getContainerImages':
        return NativeChannelReadHandlers.getContainerImages(arguments);
      case 'getContainerNetworks':
        return NativeChannelReadHandlers.getContainerNetworks(arguments);
      case 'getContainerVolumes':
        return NativeChannelReadHandlers.getContainerVolumes(arguments);
      case 'getContainerRepos':
        return NativeChannelReadHandlers.getContainerRepos(arguments);
      case 'getContainerTemplates':
        return NativeChannelReadHandlers.getContainerTemplates(arguments);
      case 'getContainerFiles':
        return NativeChannelReadHandlers.getContainerFiles(arguments);
      case 'getContainerFileContent':
        return NativeChannelReadHandlers.getContainerFileContent(arguments);
      case 'getSystemLogFiles':
        return NativeChannelReadHandlers.getSystemLogFiles(arguments);
      case 'getListeningProcesses':
        return NativeChannelReadHandlers.getListeningProcesses(arguments);
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
      case 'getTaskLogs':
        return NativeChannelReadHandlers.getTaskLogs(arguments);
      case 'getTaskLogContent':
        return NativeChannelReadHandlers.getTaskLogContent(arguments);
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
      case 'getCronJobInfo':
        return NativeChannelReadHandlers.getCronJobInfo(arguments);
      case 'getCronJobRecords':
        return NativeChannelReadHandlers.getCronJobRecords(arguments);
      case 'getBackups':
        return NativeChannelReadHandlers.getBackups(arguments);
      case 'getAIModels':
        return NativeChannelReadHandlers.getAIModels(arguments);

      // ── Read: 虚拟机 ────────────────────────────────────────────────────
      case 'getVmEnvironment':
        return NativeChannelReadHandlers.getVmEnvironment(arguments);
      case 'getVms':
        return NativeChannelReadHandlers.getVms(arguments);
      case 'getVmInfo':
        return NativeChannelReadHandlers.getVmInfo(arguments);
      case 'getVmSnapshots':
        return NativeChannelReadHandlers.getVmSnapshots(arguments);
      case 'getVmHealth':
        return NativeChannelReadHandlers.getVmHealth(arguments);
      case 'getVmStats':
        return NativeChannelReadHandlers.getVmStats(arguments);
      case 'getVmIsos':
        return NativeChannelReadHandlers.getVmIsos(arguments);
      case 'getVmTemplates':
        return NativeChannelReadHandlers.getVmTemplates(arguments);
      case 'getVmNetworks':
        return NativeChannelReadHandlers.getVmNetworks(arguments);
      case 'getVmNetworkOptions':
        return NativeChannelReadHandlers.getVmNetworkOptions(arguments);
      case 'getVmStorages':
        return NativeChannelReadHandlers.getVmStorages(arguments);

      // ── Read: 告警中心 ──────────────────────────────────────────────────
      case 'getAlertRules':
        return NativeChannelReadHandlers.getAlertRules(arguments);
      case 'getAlertLogs':
        return NativeChannelReadHandlers.getAlertLogs(arguments);
      case 'getAlertChannels':
        return NativeChannelReadHandlers.getAlertChannels(arguments);
      case 'getAlertOptions':
        return NativeChannelReadHandlers.getAlertOptions(arguments);

      // ── Read: 模型下载器 ────────────────────────────────────────────────
      case 'getModelDownloaderFeatured':
        return NativeChannelReadHandlers.getModelDownloaderFeatured(arguments);
      case 'getModelDownloaderSearch':
        return NativeChannelReadHandlers.getModelDownloaderSearch(arguments);
      case 'getModelDownloaderTasks':
        return NativeChannelReadHandlers.getModelDownloaderTasks(arguments);
      case 'getModelDownloaderLocal':
        return NativeChannelReadHandlers.getModelDownloaderLocal(arguments);
      case 'getModelDownloaderSettings':
        return NativeChannelReadHandlers.getModelDownloaderSettings(arguments);
      case 'getModelDownloaderOptions':
        return NativeChannelReadHandlers.getModelDownloaderOptions(arguments);
      case 'getWebsiteCreateOptions':
        return NativeChannelReadHandlers.getWebsiteCreateOptions(arguments);
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

      // ── Read: AI 管理深度（B3）─────────────────────────────────────────
      case 'getGpuLoad':
        return NativeChannelReadHandlers.getGpuLoad(arguments);
      case 'getGpuOptions':
        return NativeChannelReadHandlers.getGpuOptions(arguments);
      case 'searchGpuHistory':
        return NativeChannelReadHandlers.searchGpuHistory(arguments);
      case 'getAgentAccounts':
        return NativeChannelReadHandlers.getAgentAccounts(arguments);
      case 'getAgentProviders':
        return NativeChannelReadHandlers.getAgentProviders(arguments);
      case 'getAgentAccountModels':
        return NativeChannelReadHandlers.getAgentAccountModels(arguments);
      case 'getMcpServers':
        return NativeChannelReadHandlers.getMcpServers(arguments);
      case 'getMcpServerDetail':
        return NativeChannelReadHandlers.getMcpServerDetail(arguments);
      case 'pageAgentsNative':
        return NativeChannelReadHandlers.pageAgentsNative(arguments);
      case 'getAgentOverviewNative':
        return NativeChannelReadHandlers.getAgentOverviewNative(arguments);
      case 'getAIBindDomain':
        return NativeChannelReadHandlers.getAIBindDomain(arguments);

      // ── Write: 服务器 ───────────────────────────────────────────────────
      case 'seedDebugConfig':
        return NativeChannelWriteHandlers.seedDebugConfig(arguments);
      case 'addServer':
        return NativeChannelWriteHandlers.addServer(arguments);

      case 'connectServer':
        return NativeChannelWriteHandlers.connectServer(arguments);
      case 'deleteServer':
        return NativeChannelWriteHandlers.deleteServer(arguments);
      case 'updateServer':
        return NativeChannelWriteHandlers.updateServer(arguments);

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

      // ── 数据库 ────────────────────────────────────────────────────────────
      case 'checkRemoteDatabaseUnbind':
        return NativeChannelWriteHandlers.remoteDatabaseUnbind(arguments,
            confirm: false);
      case 'unbindRemoteDatabase':
        return NativeChannelWriteHandlers.remoteDatabaseUnbind(arguments,
            confirm: true);

      // ── Write: 容器 ─────────────────────────────────────────────────────
      case 'toggleContainerState':
        return NativeChannelWriteHandlers.toggleContainerState(arguments);
      case 'restartContainer':
        return NativeChannelWriteHandlers.restartContainer(arguments);
      case 'startContainer':
        return NativeChannelWriteHandlers.startContainer(arguments);
      case 'stopContainer':
        return NativeChannelWriteHandlers.stopContainer(arguments);
      case 'deleteContainer':
        return NativeChannelWriteHandlers.deleteContainer(arguments);
      case 'stopListeningProcess':
        return NativeChannelWriteHandlers.stopListeningProcess(arguments);
      case 'createContainer':
        return NativeChannelWriteHandlers.createContainer(arguments);
      case 'deleteContainerImage':
        return NativeChannelWriteHandlers.deleteContainerImage(arguments);
      case 'deleteContainerNetwork':
        return NativeChannelWriteHandlers.deleteContainerNetwork(arguments);
      case 'createContainerNetwork':
        return NativeChannelWriteHandlers.createContainerNetwork(arguments);
      case 'deleteContainerVolume':
        return NativeChannelWriteHandlers.deleteContainerVolume(arguments);
      case 'createContainerVolume':
        return NativeChannelWriteHandlers.createContainerVolume(arguments);
      case 'pullContainerImage':
        return NativeChannelWriteHandlers.pullContainerImage(arguments);
      case 'buildContainerImage':
        return NativeChannelWriteHandlers.buildContainerImage(arguments);
      case 'pushContainerImage':
        return NativeChannelWriteHandlers.pushContainerImage(arguments);
      case 'createContainerRepo':
        return NativeChannelWriteHandlers.createContainerRepo(arguments);
      case 'deleteContainerRepo':
        return NativeChannelWriteHandlers.deleteContainerRepo(arguments);
      case 'createContainerTemplate':
        return NativeChannelWriteHandlers.createContainerTemplate(arguments);
      case 'deleteContainerTemplate':
        return NativeChannelWriteHandlers.deleteContainerTemplate(arguments);

      // ── Write: 应用 ─────────────────────────────────────────────────────
      case 'startApp':
        return NativeChannelWriteHandlers.startApp(arguments);
      case 'stopApp':
        return NativeChannelWriteHandlers.stopApp(arguments);
      case 'restartApp':
        return NativeChannelWriteHandlers.restartApp(arguments);
      case 'uninstallApp':
        return NativeChannelWriteHandlers.uninstallApp(arguments);
      case 'updateApp':
        return NativeChannelWriteHandlers.updateApp(arguments);
      case 'installApp':
        return NativeChannelWriteHandlers.installApp(arguments);

      // ── Write: 文件 ─────────────────────────────────────────────────────
      case 'deleteFile':
        return NativeChannelWriteHandlers.deleteFile(arguments);
      case 'createFolder':
        return NativeChannelWriteHandlers.createFolder(arguments);
      case 'renameFile':
        return NativeChannelWriteHandlers.renameFile(arguments);
      case 'createFileHandler':
        return NativeChannelWriteHandlers.createFileHandler(arguments);
      case 'renameFileHandler':
        return NativeChannelWriteHandlers.renameFileHandler(arguments);
      case 'moveFilesHandler':
        return NativeChannelWriteHandlers.moveFilesHandler(arguments);
      case 'uploadFilesFromDevice':
        return NativeChannelWriteHandlers.uploadFilesFromDevice(arguments);
      case 'downloadFileToDevice':
        return NativeChannelWriteHandlers.downloadFileToDevice(arguments);
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
      case 'deleteWebsiteCertificate':
        return NativeChannelWriteHandlers.deleteWebsiteCertificate(arguments);
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

      // ── Write: AI 管理深度（B3）────────────────────────────────────────
      case 'createAgentAccountNative':
        return NativeChannelWriteHandlers.createAgentAccountNative(arguments);
      case 'updateAgentAccountNative':
        return NativeChannelWriteHandlers.updateAgentAccountNative(arguments);
      case 'deleteAgentAccountNative':
        return NativeChannelWriteHandlers.deleteAgentAccountNative(arguments);
      case 'discoverAgentModels':
        return NativeChannelWriteHandlers.discoverAgentModels(arguments);
      case 'createMcpServerNative':
        return NativeChannelWriteHandlers.createMcpServerNative(arguments);
      case 'deleteMcpServerNative':
        return NativeChannelWriteHandlers.deleteMcpServerNative(arguments);
      case 'operateMcpServerNative':
        return NativeChannelWriteHandlers.operateMcpServerNative(arguments);
      case 'testMcpConnection':
        return NativeChannelWriteHandlers.testMcpConnection(arguments);
      case 'syncMcpStatus':
        return NativeChannelWriteHandlers.syncMcpStatus(arguments);
      case 'createAgentNative':
        return NativeChannelWriteHandlers.createAgentNative(arguments);
      case 'deleteAgentNative':
        return NativeChannelWriteHandlers.deleteAgentNative(arguments);
      case 'loadOllamaModelNative':
        return NativeChannelWriteHandlers.loadOllamaModelNative(arguments);
      case 'closeOllamaModelNative':
        return NativeChannelWriteHandlers.closeOllamaModelNative(arguments);
      case 'syncOllamaModelsNative':
        return NativeChannelWriteHandlers.syncOllamaModelsNative(arguments);

      // ── Write: 虚拟机 ──────────────────────────────────────────────────
      case 'enableVmEnvironment':
        return NativeChannelWriteHandlers.enableVmEnvironment(arguments);
      case 'syncVms':
        return NativeChannelWriteHandlers.syncVms(arguments);
      case 'operateVm':
        return NativeChannelWriteHandlers.operateVm(arguments);
      case 'createVmSnapshot':
        return NativeChannelWriteHandlers.createVmSnapshot(arguments);
      case 'recoverVmSnapshot':
        return NativeChannelWriteHandlers.recoverVmSnapshot(arguments);
      case 'deleteVmSnapshot':
        return NativeChannelWriteHandlers.deleteVmSnapshot(arguments);

      // ── Write: 告警中心 ─────────────────────────────────────────────────
      case 'createAlertRule':
        return NativeChannelWriteHandlers.createAlertRule(arguments);
      case 'updateAlertRule':
        return NativeChannelWriteHandlers.updateAlertRule(arguments);
      case 'deleteAlertRule':
        return NativeChannelWriteHandlers.deleteAlertRule(arguments);
      case 'toggleAlertRule':
        return NativeChannelWriteHandlers.toggleAlertRule(arguments);
      case 'cleanAlertLogs':
        return NativeChannelWriteHandlers.cleanAlertLogs(arguments);
      case 'saveAlertChannel':
        return NativeChannelWriteHandlers.saveAlertChannel(arguments);
      case 'deleteAlertChannel':
        return NativeChannelWriteHandlers.deleteAlertChannel(arguments);
      case 'toggleAlertChannel':
        return NativeChannelWriteHandlers.toggleAlertChannel(arguments);
      case 'testAlertChannel':
        return NativeChannelWriteHandlers.testAlertChannel(arguments);

      // ── Write: 模型下载器 ───────────────────────────────────────────────
      case 'syncModelDownloaderFeatured':
        return NativeChannelWriteHandlers.syncModelDownloaderFeatured(arguments);
      case 'setModelDownloaderFeaturedSync':
        return NativeChannelWriteHandlers.setModelDownloaderFeaturedSync(arguments);
      case 'downloadModel':
        return NativeChannelWriteHandlers.downloadModel(arguments);
      case 'cancelModelTask':
        return NativeChannelWriteHandlers.cancelModelTask(arguments);
      case 'retryModelTask':
        return NativeChannelWriteHandlers.retryModelTask(arguments);
      case 'removeModelTask':
        return NativeChannelWriteHandlers.removeModelTask(arguments);
      case 'deleteLocalModel':
        return NativeChannelWriteHandlers.deleteLocalModel(arguments);
      case 'updateModelDownloaderSettings':
        return NativeChannelWriteHandlers.updateModelDownloaderSettings(arguments);

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

      // ── Read: 数据库深度（B4）─────────────────────────────────────────
      case 'getDatabaseBaseInfo':
        return NativeChannelDatabaseDeepHandlers.getDatabaseBaseInfo(arguments);
      case 'getDatabaseConfFile':
        return NativeChannelDatabaseDeepHandlers.getDatabaseConfFile(arguments);
      case 'getMysqlVariables':
        return NativeChannelDatabaseDeepHandlers.getMysqlVariables(arguments);
      case 'getMysqlStatus':
        return NativeChannelDatabaseDeepHandlers.getMysqlStatus(arguments);
      case 'getRedisConf':
        return NativeChannelDatabaseDeepHandlers.getRedisConf(arguments);
      case 'getRedisStatus':
        return NativeChannelDatabaseDeepHandlers.getRedisStatus(arguments);
      case 'getRedisPersistence':
        return NativeChannelDatabaseDeepHandlers.getRedisPersistence(arguments);
      case 'getDatabaseRemoteAccess':
        return NativeChannelDatabaseDeepHandlers.getDatabaseRemoteAccess(
            arguments);
      case 'getDatabaseUsers':
        return NativeChannelDatabaseDeepHandlers.getDatabaseUsers(arguments);
      case 'getDatabaseGrants':
        return NativeChannelDatabaseDeepHandlers.getDatabaseGrants(arguments);
      case 'getDatabaseBackups':
        return NativeChannelDatabaseDeepHandlers.getDatabaseBackups(arguments);

      // ── Write: 数据库深度（B4）────────────────────────────────────────
      case 'updateDatabaseConfFile':
        return NativeChannelDatabaseDeepHandlers.updateDatabaseConfFile(
            arguments);
      case 'updateMysqlVariables':
        return NativeChannelDatabaseDeepHandlers.updateMysqlVariables(arguments);
      case 'updateRedisConf':
        return NativeChannelDatabaseDeepHandlers.updateRedisConf(arguments);
      case 'updateRedisPersistence':
        return NativeChannelDatabaseDeepHandlers.updateRedisPersistence(
            arguments);
      case 'changeRedisPassword':
        return NativeChannelDatabaseDeepHandlers.changeRedisPassword(arguments);
      case 'updateDatabaseAccess':
        return NativeChannelDatabaseDeepHandlers.updateDatabaseAccess(arguments);
      case 'updateDatabaseUserPassword':
        return NativeChannelDatabaseDeepHandlers.updateDatabaseUserPassword(
            arguments);
      case 'createDatabaseUser':
        return NativeChannelDatabaseDeepHandlers.createDatabaseUser(arguments);
      case 'deleteDatabaseUser':
        return NativeChannelDatabaseDeepHandlers.deleteDatabaseUser(arguments);
      case 'updateDatabaseUser':
        return NativeChannelDatabaseDeepHandlers.updateDatabaseUser(arguments);
      case 'grantDatabaseUser':
        return NativeChannelDatabaseDeepHandlers.grantDatabaseUser(arguments);
      case 'revokeDatabaseGrant':
        return NativeChannelDatabaseDeepHandlers.revokeDatabaseGrant(arguments);

      default:
        throw MissingPluginException();
    }
  }
}
