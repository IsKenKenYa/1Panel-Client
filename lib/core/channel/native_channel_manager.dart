import 'package:flutter/services.dart';

import 'native_channel_read_handlers.dart';
import 'native_channel_write_handlers.dart';

/// macOS Native Channel 主路由器。
/// 仅负责初始化 MethodChannel 并将各 method 分发到
/// [NativeChannelReadHandlers] 或 [NativeChannelWriteHandlers]。
class NativeChannelManager {
  static const MethodChannel _methodChannel =
      MethodChannel('com.onepanel.client/method');

  static void init() {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    final args = call.arguments;
    switch (call.method) {
      // ── Read: 已有 ─────────────────────────────────────────────────────
      case 'getServers':
        return NativeChannelReadHandlers.getServers(args);
      case 'getFiles':
        return NativeChannelReadHandlers.getFiles(args);
      case 'getApps':
        return NativeChannelReadHandlers.getApps(args);
      case 'getWebsites':
        return NativeChannelReadHandlers.getWebsites(args);
      case 'getMonitoring':
        return NativeChannelReadHandlers.getMonitoring(args);
      case 'getContainers':
        return NativeChannelReadHandlers.getContainers(args);
      case 'getSettings':
        return NativeChannelReadHandlers.getSettings(args);
      case 'getTranslations':
        return NativeChannelReadHandlers.getTranslations();
      case 'getUIRenderMode':
        return NativeChannelReadHandlers.getUIRenderMode();

      // ── Read: 新增 ─────────────────────────────────────────────────────
      case 'getDashboard':
        return NativeChannelReadHandlers.getDashboard(args);
      case 'getDatabases':
        return NativeChannelReadHandlers.getDatabases(args);
      case 'getFirewallRules':
        return NativeChannelReadHandlers.getFirewallRules(args);
      case 'getCronJobs':
        return NativeChannelReadHandlers.getCronJobs(args);
      case 'getBackups':
        return NativeChannelReadHandlers.getBackups(args);
      case 'getAIModels':
        return NativeChannelReadHandlers.getAIModels(args);

      // ── Write: 服务器 ───────────────────────────────────────────────────
      // ── Write: 服务器 ───────────────────────────────────────────────────
      case 'addServer':
        return NativeChannelWriteHandlers.addServer(args);

      case 'connectServer':
        return NativeChannelWriteHandlers.connectServer(args);
      case 'deleteServer':
        return NativeChannelWriteHandlers.deleteServer(args);

      // ── Write: 网站 ─────────────────────────────────────────────────────
      case 'toggleWebsiteStatus':
        return NativeChannelWriteHandlers.toggleWebsiteStatus(args);
      case 'deleteWebsite':
        return NativeChannelWriteHandlers.deleteWebsite(args);

      // ── Write: 容器 ─────────────────────────────────────────────────────
      case 'toggleContainerState':
        return NativeChannelWriteHandlers.toggleContainerState(args);
      case 'restartContainer':
        return NativeChannelWriteHandlers.restartContainer(args);
      case 'deleteContainer':
        return NativeChannelWriteHandlers.deleteContainer(args);

      // ── Write: 应用 ─────────────────────────────────────────────────────
      case 'startApp':
        return NativeChannelWriteHandlers.startApp(args);
      case 'stopApp':
        return NativeChannelWriteHandlers.stopApp(args);
      case 'uninstallApp':
        return NativeChannelWriteHandlers.uninstallApp(args);

      // ── Write: 文件 ─────────────────────────────────────────────────────
      case 'deleteFile':
        return NativeChannelWriteHandlers.deleteFile(args);
      case 'createFolder':
        return NativeChannelWriteHandlers.createFolder(args);

      // ── Write: 定时任务 ─────────────────────────────────────────────────
      case 'toggleCronJobStatus':
        return NativeChannelWriteHandlers.toggleCronJobStatus(args);
      case 'deleteCronJob':
        return NativeChannelWriteHandlers.deleteCronJob(args);

      // ── Write: 备份 ─────────────────────────────────────────────────────
      case 'deleteBackup':
        return NativeChannelWriteHandlers.deleteBackup(args);

      // ── Write: AI ───────────────────────────────────────────────────────
      case 'deleteAIModel':
        return NativeChannelWriteHandlers.deleteAIModel(args);

      // ── Write: 防火墙 ───────────────────────────────────────────────────
      case 'addFirewallRule':
        return NativeChannelWriteHandlers.addFirewallRule(args);

      case 'deleteFirewallRule':
        return NativeChannelWriteHandlers.deleteFirewallRule(args);

      // ── Write: 缓存 ─────────────────────────────────────────────────────
      case 'clearCache':
        return NativeChannelWriteHandlers.clearCache(args);

      default:
        throw MissingPluginException();
    }
  }
}
