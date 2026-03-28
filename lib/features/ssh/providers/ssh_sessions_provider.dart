import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class SshSessionsProvider extends ChangeNotifier with AsyncStateNotifier {
  SshSessionsProvider({
    SSHService? service,
  }) : _service = service ?? SSHService();

  final SSHService _service;

  List<SshSessionInfo> _items = const <SshSessionInfo>[];
  SshSessionQuery _query = const SshSessionQuery();
  bool _isMutating = false;
  StreamSubscription<List<SshSessionInfo>>? _subscription;
  Timer? _pollTimer;

  List<SshSessionInfo> get items => _items;
  SshSessionQuery get query => _query;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    setLoading();
    await _bindStreamIfNeeded();
    try {
      await _service.connectSessions(_query);
      _startPolling();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.sessions',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <SshSessionInfo>[];
      setError(error);
    }
  }

  Future<void> applyFilters(SshSessionQuery query) async {
    _query = query;
    await load();
  }

  Future<void> refresh() => load();

  Future<bool> disconnectSession(SshSessionInfo item) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.disconnectSession(item.pid);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.sessions',
        'disconnect failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> _bindStreamIfNeeded() async {
    _subscription ??=
        _service.watchSessions().listen((List<SshSessionInfo> items) {
      _items = items;
      setSuccess(isEmpty: items.isEmpty, notify: false);
      notifyListeners();
    }, onError: (Object error, StackTrace stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.sessions',
        'stream failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <SshSessionInfo>[];
      setError(error);
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _service.connectSessions(_query);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _subscription?.cancel();
    _service.closeSessions();
    super.dispose();
  }
}
