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
      case 'getAppStore':
        return NativeChannelReadHandlers.getAppStore(arguments);
      case 'getAppVersions':
        return NativeChannelReadHandlers.getAppVersions(arguments);
      case 'getAppInstallForm':
        return NativeChannelReadHandlers.getAppInstallForm(arguments);
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
      case 'getSettings':
        return NativeChannelReadHandlers.getSettings(arguments);
      case 'getTranslations':
        return NativeChannelReadHandlers.getTranslations();
      case 'getUIRenderMode':
        return NativeChannelReadHandlers.getUIRenderMode();

      // ── Read: 新增 ─────────────────────────────────────────────────────
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
      case 'getWebsiteCreateOptions':
        return NativeChannelReadHandlers.getWebsiteCreateOptions(arguments);

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
      case 'deleteContainer':
        return NativeChannelWriteHandlers.deleteContainer(arguments);

      // ── Write: 应用 ─────────────────────────────────────────────────────
      case 'startApp':
        return NativeChannelWriteHandlers.startApp(arguments);
      case 'stopApp':
        return NativeChannelWriteHandlers.stopApp(arguments);
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

      // ── Write: 定时任务 ─────────────────────────────────────────────────
      case 'toggleCronJobStatus':
        return NativeChannelWriteHandlers.toggleCronJobStatus(arguments);
      case 'deleteCronJob':
        return NativeChannelWriteHandlers.deleteCronJob(arguments);

      // ── Write: 备份 ─────────────────────────────────────────────────────
      case 'deleteBackup':
        return NativeChannelWriteHandlers.deleteBackup(arguments);

      // ── Write: AI ───────────────────────────────────────────────────────
      case 'deleteAIModel':
        return NativeChannelWriteHandlers.deleteAIModel(arguments);

      // ── Write: 防火墙 ───────────────────────────────────────────────────
      case 'addFirewallRule':
        return NativeChannelWriteHandlers.addFirewallRule(arguments);

      case 'deleteFirewallRule':
        return NativeChannelWriteHandlers.deleteFirewallRule(arguments);

      // ── Write: 缓存 ─────────────────────────────────────────────────────
      case 'clearCache':
        return NativeChannelWriteHandlers.clearCache(arguments);

      default:
        throw MissingPluginException();
    }
  }
}
