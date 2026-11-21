import 'dart:async';
import 'package:onepanel_client/core/network/session_poller.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_tree_models.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/terminal/models/terminal_runtime_models.dart';
import 'package:onepanel_client/features/terminal/services/terminal_runtime_session.dart';
import 'package:onepanel_client/features/terminal/services/terminal_workbench_service.dart';

class TerminalWorkbenchProvider extends ChangeNotifier
    with SafeChangeNotifier, AsyncStateNotifier {
  TerminalWorkbenchProvider({
    TerminalWorkbenchService? service,
  }) : _service = service ?? TerminalWorkbenchService();

  final TerminalWorkbenchService _service;

  TerminalInfo? _terminalSettings;
  SshLocalConnectionInfo _localConnection = const SshLocalConnectionInfo();
  List<HostTreeNode> _hostTree = const <HostTreeNode>[];
  List<CommandTree> _commandTree = const <CommandTree>[];
  List<SshSessionInfo> _activeSshSessions = const <SshSessionInfo>[];
  List<TerminalRuntimeSession> _sessions = const <TerminalRuntimeSession>[];
  String? _activeSessionKey;
  bool _isLaunchingSession = false;
  bool _isDisconnectingSshSession = false;
  bool _didAutoStartDefaultLocal = false;

  StreamSubscription<List<SshSessionInfo>>? _activeSshSessionsSubscription;
  final _activeSshSessionsPoller = SessionPoller();
  bool _sessionListVisible = true;
  bool _sessionListReady = false;

  TerminalInfo? get terminalSettings => _terminalSettings;
  SshLocalConnectionInfo get localConnection => _localConnection;
  List<HostTreeNode> get hostTree => _hostTree;
  List<CommandTree> get commandTree => _commandTree;
  List<SshSessionInfo> get activeSshSessions => _activeSshSessions;
  List<TerminalRuntimeSession> get sessions => _sessions;
  bool get isLaunchingSession => _isLaunchingSession;
  bool get isDisconnectingSshSession => _isDisconnectingSshSession;

  TerminalRuntimeSession? get activeSession {
    final key = _activeSessionKey;
    if (key == null) {
      return _sessions.isEmpty ? null : _sessions.first;
    }
    for (final session in _sessions) {
      if (session.descriptor.sessionKey == key) {
        return session;
      }
    }
    return _sessions.isEmpty ? null : _sessions.first;
  }

  TerminalRuntimeSession? sessionByKey(String sessionKey) {
    for (final session in _sessions) {
      if (session.descriptor.sessionKey == sessionKey) {
        return session;
      }
    }
    return null;
  }

  Future<void> initialize(TerminalLaunchIntent initialIntent) async {
    if (isDisposed) return;
    setLoading();
    await _bindActiveSshSessions();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.loadTerminalSettings(),
        _service.loadLocalConnection(),
        _service.loadHostTree(),
        _service.loadQuickCommands(),
      ]);

      if (isDisposed) return;
      _terminalSettings = results[0] as TerminalInfo?;
      _localConnection = results[1] as SshLocalConnectionInfo;
      _hostTree = results[2] as List<HostTreeNode>;
      _commandTree = results[3] as List<CommandTree>;

      if (_sessionListVisible) {
        await _service.connectActiveSshSessions(const SshSessionQuery());
      }
      if (isDisposed) return;
      _sessionListReady = true;
      if (_sessionListVisible) _startActiveSshSessionPolling();

      if (initialIntent.isExplicitSession) {
        await openSession(initialIntent);
      } else {
        await _maybeAutoStartDefaultLocalSession();
      }

      setSuccess(isEmpty: false, notify: false);
      notifyListeners();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.terminal.providers.workbench',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      notifyListeners();
    }
  }

  Future<void> refreshCatalogs() async {
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.loadTerminalSettings(),
        _service.loadLocalConnection(),
        _service.loadHostTree(),
        _service.loadQuickCommands(),
      ]);
      _terminalSettings = results[0] as TerminalInfo?;
      _localConnection = results[1] as SshLocalConnectionInfo;
      _hostTree = results[2] as List<HostTreeNode>;
      _commandTree = results[3] as List<CommandTree>;
      notifyListeners();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.terminal.providers.workbench',
        'refreshCatalogs failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      notifyListeners();
    }
  }

  Future<TerminalRuntimeSession?> openSession(
      TerminalLaunchIntent intent) async {
    if (isDisposed) return null;
    final existing =
        _sessions.where((item) => item.descriptor.intent == intent);
    if (existing.isNotEmpty) {
      final session = existing.first;
      _activeSessionKey = session.descriptor.sessionKey;
      notifyListeners();
      if (!session.isConnected &&
          session.connectionState !=
              TerminalSessionConnectionState.connecting) {
        await reconnectSession(session.descriptor.sessionKey);
        return sessionByKey(session.descriptor.sessionKey);
      }
      return session;
    }

    _isLaunchingSession = true;
    clearError(notify: false);
    notifyListeners();

    try {
      final settings =
          _terminalSettings ?? await _service.loadTerminalSettings();
      if (isDisposed) return null;
      final opening =
          _sessions.where((item) => item.descriptor.intent == intent).firstOrNull;
      if (opening != null) return opening;
      _terminalSettings = settings;

      // Use microseconds for the session key to avoid collisions when
      // multiple sessions are opened in rapid succession (e.g. from a script).
      final descriptor = TerminalSessionDescriptor(
        sessionKey: DateTime.now().microsecondsSinceEpoch.toString(),
        intent: intent,
        title: intent.resolvedTargetTitle(),
      );
      final session = TerminalRuntimeSession(
        descriptor: descriptor,
        settings: settings,
        onChanged: notifyListeners,
      );
      final updated = List<TerminalRuntimeSession>.from(_sessions)
        ..add(session);
      _sessions = updated;
      _activeSessionKey = descriptor.sessionKey;
      notifyListeners();

      final transport = await _service.createTransport(
        intent: intent,
        columns: 120,
        rows: 36,
      );
      await session.attachTransport(transport);
      return session;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.terminal.providers.workbench',
        'openSession failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      notifyListeners();
      return null;
    } finally {
      _isLaunchingSession = false;
      notifyListeners();
    }
  }

  Future<TerminalRuntimeSession?> openSavedHostSession({
    required int hostId,
    required String hostLabel,
  }) {
    return openSession(
      TerminalLaunchIntent.savedHost(
        hostId: hostId,
        hostLabel: hostLabel,
      ),
    );
  }

  Future<TerminalRuntimeSession?> openLocalSession() {
    return openSession(const TerminalLaunchIntent.localHost());
  }

  Future<TerminalRuntimeSession?> openContainerSession({
    required String containerId,
    required String containerName,
    String command = '/bin/sh',
    String user = 'root',
  }) {
    return openSession(
      TerminalLaunchIntent.containerExec(
        containerId: containerId,
        containerName: containerName,
        command: command,
        user: user,
      ),
    );
  }

  void selectSession(String sessionKey) {
    _activeSessionKey = sessionKey;
    notifyListeners();
  }

  Future<void> closeSession(String sessionKey) async {
    final index = _sessions
        .indexWhere((item) => item.descriptor.sessionKey == sessionKey);
    if (index < 0) {
      return;
    }
    final session = _sessions[index];
    await session.dispose();
    final updated = List<TerminalRuntimeSession>.from(_sessions)
      ..removeAt(index);
    _sessions = updated;
    if (_activeSessionKey == sessionKey) {
      _activeSessionKey =
          updated.isEmpty ? null : updated.last.descriptor.sessionKey;
    }
    notifyListeners();
  }

  Future<void> reconnectSession(String sessionKey) async {
    final index = _sessions
        .indexWhere((item) => item.descriptor.sessionKey == sessionKey);
    if (index < 0) {
      return;
    }

    final current = _sessions[index];
    // Create a fresh session with the same descriptor to get a clean transport,
    // then dispose the old one — avoids reusing a half-open WebSocket.
    final replacement = TerminalRuntimeSession(
      descriptor: current.descriptor,
      settings: _terminalSettings,
      onChanged: notifyListeners,
    );
    final updated = List<TerminalRuntimeSession>.from(_sessions);
    updated[index] = replacement;
    _sessions = updated;
    _activeSessionKey = replacement.descriptor.sessionKey;
    notifyListeners();

    await current.dispose();
    final transport = await _service.createTransport(
      intent: replacement.descriptor.intent,
      columns: 120,
      rows: 36,
    );
    await replacement.attachTransport(transport);
  }

  Future<void> sendQuickCommand(
    TerminalRuntimeSession session,
    String command,
  ) async {
    await session.sendCommand(command);
  }

  Future<void> disconnectActiveSshSession(int pid) async {
    _isDisconnectingSshSession = true;
    notifyListeners();
    try {
      await _service.disconnectActiveSshSession(pid);
      if (!isDisposed && _sessionListVisible) {
        await _service.connectActiveSshSessions(const SshSessionQuery());
      }
    } finally {
      _isDisconnectingSshSession = false;
      notifyListeners();
    }
  }

  Future<void> _maybeAutoStartDefaultLocalSession() async {
    // Only auto-start once per provider lifetime to avoid opening duplicate
    // sessions if the user navigates back to the terminal page.
    if (_didAutoStartDefaultLocal) {
      return;
    }
    _didAutoStartDefaultLocal = true;
    if (!_localConnection.isVisibleByDefault ||
        !_localConnection.isConfigured) {
      return;
    }
    await openLocalSession();
  }

  Future<void> _bindActiveSshSessions() async {
    _activeSshSessionsSubscription ??=
        _service.watchActiveSshSessions().listen((List<SshSessionInfo> items) {
      _activeSshSessions = items;
      notifyListeners();
    }, onError: (Object error, StackTrace stackTrace) {
      appLogger.eWithPackage(
        'features.terminal.providers.workbench',
        'watchActiveSshSessions failed',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  void _startActiveSshSessionPolling() {
    _activeSshSessionsPoller.start(
      () => _service.connectActiveSshSessions(const SshSessionQuery()),
      (error, trace) => appLogger.eWithPackage(
        'features.terminal.providers.workbench',
        'poll SSH sessions failed',
        error: error,
        stackTrace: trace,
      ),
    );
  }

  void setSessionListVisible(bool visible) {
    if (isDisposed || visible == _sessionListVisible) return;
    _sessionListVisible = visible;
    if (visible) {
      if (_sessionListReady) _startActiveSshSessionPolling();
    } else {
      _activeSshSessionsPoller.cancel();
      unawaited(_service.closeActiveSshSessions());
    }
  }

  @override
  void dispose() {
    _activeSshSessionsPoller.cancel();
    _activeSshSessionsSubscription?.cancel();
    for (final session in _sessions) {
      unawaited(session.dispose());
    }
    _service.closeActiveSshSessions();
    super.dispose();
  }
}
