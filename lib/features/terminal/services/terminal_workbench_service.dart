import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_tree_models.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

import '../models/terminal_runtime_models.dart';
import 'terminal_transport.dart';
import 'ws_terminal_transport.dart';

class TerminalWorkbenchService {
  TerminalWorkbenchService({
    ApiClientManager? clientManager,
    SSHService? sshService,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _sshService = sshService ?? SSHService();

  final ApiClientManager _clientManager;
  final SSHService _sshService;

  Future<TerminalInfo?> loadTerminalSettings() async {
    final api = await _clientManager.getSettingApi();
    final response = await api.getTerminalSettings();
    return response.data;
  }

  Future<SshLocalConnectionInfo> loadLocalConnection() {
    return _sshService.loadLocalConnection();
  }

  Future<bool> checkLocalConnection([SshLocalConnectionInfo? request]) {
    return _sshService.checkLocalConnection(request);
  }

  Future<void> updateLocalConnectionVisibility({
    required bool visible,
    bool withReset = false,
  }) {
    return _sshService.updateLocalConnectionVisibility(
      visible: visible,
      withReset: withReset,
    );
  }

  Future<List<HostTreeNode>> loadHostTree() async {
    final api = await _clientManager.getHostApi();
    final response = await api.getHostAssetTree();
    return response.data ?? const <HostTreeNode>[];
  }

  Future<List<CommandTree>> loadQuickCommands() async {
    final api = await _clientManager.getCommandApi();
    final response = await api.getCommandTree();
    return response.data ?? const <CommandTree>[];
  }

  Stream<List<SshSessionInfo>> watchActiveSshSessions() {
    return _sshService.watchSessions();
  }

  Future<void> connectActiveSshSessions(SshSessionQuery query) {
    return _sshService.connectSessions(query);
  }

  Future<void> disconnectActiveSshSession(int pid) {
    return _sshService.disconnectSession(pid);
  }

  Future<void> closeActiveSshSessions() {
    return _sshService.closeSessions();
  }

  Future<TerminalTransport> createTransport({
    required TerminalLaunchIntent intent,
    required int columns,
    required int rows,
  }) async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No API config available');
    }
    return WebSocketTerminalTransport(
      config: config,
      intent: intent,
      columns: columns,
      rows: rows,
    );
  }
}
