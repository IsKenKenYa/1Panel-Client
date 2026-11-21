import 'dart:async';
import 'package:onepanel_client/core/network/session_poller.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ssh_session_models.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class SshSessionsProvider extends ChangeNotifier
    with SafeChangeNotifier, AsyncStateNotifier {
  SshSessionsProvider({
    SSHService? service,
  }) : _service = service ?? SSHService();

  final SSHService _service;

  List<SshSessionInfo> _items = const <SshSessionInfo>[];
  SshSessionQuery _query = const SshSessionQuery();
  bool _isMutating = false;
  StreamSubscription<List<SshSessionInfo>>? _subscription;
  final _poller = SessionPoller();
  bool _visible = true;
  int _generation = 0;

  List<SshSessionInfo> get items => _items;
  SshSessionQuery get query => _query;
  bool get isMutating => _isMutating;

  void setPageVisible(bool visible) {
    if (isDisposed) return;
    _visible = visible;
    if (visible) {
      unawaited(load());
    } else {
      _generation++;
      _poller.cancel();
      unawaited(_service.closeSessions());
    }
  }

  Future<void> load() async {
    if (isDisposed || !_visible) return;
    final generation = ++_generation;
    _poller.cancel();
    setLoading();
    await _bindStreamIfNeeded();
    try {
      if (isDisposed || generation != _generation) return;
      await _service.connectSessions(_query);
      if (isDisposed || generation != _generation) return;
      _startPolling();
    } catch (error, stackTrace) {
      if (isDisposed || generation != _generation) return;
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
    _poller.start(() => _service.connectSessions(_query), (error, trace) {
      appLogger.eWithPackage('features.ssh.providers.sessions', 'poll failed',
          error: error, stackTrace: trace);
      setError(error);
    });
  }

  @override
  void dispose() {
    _poller.cancel();
    _subscription?.cancel();
    _service.closeSessions();
    super.dispose();
  }
}
