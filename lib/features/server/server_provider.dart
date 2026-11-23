import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pool/pool.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/data/panels/panel_adapter.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'server_models.dart';
import 'server_repository.dart';

class ServerProvider extends ChangeNotifier with SafeChangeNotifier {
  ServerProvider(
      {ServerRepository? repository, CurrentServerController? directory})
      : _repository = repository ?? const ServerRepository(),
        _directory = directory {
    directory?.addListener(_onDirectoryChanged);
    _onDirectoryChanged();
  }

  final ServerRepository _repository;
  final CurrentServerController? _directory;
  Future<void>? _directoryRead;
  bool _hasDirectory = false;
  String? _directoryError;
  List<ApiConfig> _configs = const [];
  Map<String, ServerCardViewModel> _cards = {};
  String? _currentId;

  static const _refreshInterval = Duration(seconds: 10);
  final _pool = Pool(4);
  final _visiblePages = <Object, String?>{};
  final _metricReads = <ApiConfig, Future<void>>{};
  ({
    List<ApiConfig> configs,
    Set<ApiConfig> remaining,
    Future<void> done
  })? _listRead;
  final _explicitReads = <ApiConfig>{};
  final _lastMetricRead = <ApiConfig, DateTime>{};
  final _capabilityReads = <ApiConfig, Future<Map<String, PanelAccess>>>{};
  Timer? _timer;

  bool get isLoading => _directoryRead != null;
  bool get hasDirectory => _hasDirectory;
  String? get directoryError => _directoryError;
  bool get isLoadingMetrics => _metricReads.isNotEmpty;
  List<ApiConfig> get configs => _configs;
  List<ServerCardViewModel> get servers => List.unmodifiable(_cards.values);
  ServerCardViewModel? cardFor(String id) => _cards[id];

  Future<Map<String, PanelAccess>> capabilitiesFor(String serverId) {
    if (!_hasDirectory) {
      return _loadDirectory(initial: true).then((_) {
        if (!_hasDirectory) throw StateError('服务器目录不可用');
        return capabilitiesFor(serverId);
      });
    }
    final config = cardFor(serverId)?.config;
    if (config == null) return Future.error(StateError('Server not found'));
    return _capabilityReads.putIfAbsent(
      config,
      () => _repository.capabilitiesFor(config).then((access) {
        if (isDisposed || _cards[serverId]?.config != config) {
          throw StateError('Server configuration changed');
        }
        return access;
      }).whenComplete(() {
        _capabilityReads.remove(config);
      }),
    );
  }

  Future<ApiConfig> readConfig(String serverId) =>
      _repository.readConfig(serverId);

  void _onDirectoryChanged() {
    final directory = _directory;
    if (directory != null && directory.hasLoaded && !directory.isLoading) {
      syncDirectory(directory.servers, directory.currentServerId);
    }
  }

  /// 配置版本相同时沿用已有对象，目录选择和单台指标可以分别订阅。
  void syncDirectory(List<ApiConfig> servers, String? currentId) {
    if (isDisposed) return;
    if (_hasDirectory && listEquals(servers, _configs)) {
      if (_currentId == currentId && _directoryError == null) return;
      for (final id in [_currentId, currentId].whereType<String>()) {
        final card = _cards[id];
        final selected = id == currentId;
        if (card != null && card.isCurrent != selected) {
          _cards[id] = card.copyWith(isCurrent: selected);
        }
      }
      _currentId = currentId;
      _directoryError = null;
      notifyListeners();
      return;
    }
    final next = <String, ServerCardViewModel>{};
    final configs = <ApiConfig>[];
    for (final server in servers) {
      final old = _cards[server.id];
      final same = old != null &&
          (identical(old.config, server) ||
              (server.revision.isNotEmpty &&
                  old.config.revision == server.revision));
      final current = server.id == currentId;
      final card = same && old.isCurrent == current
          ? old
          : ServerCardViewModel(
              config: same ? old.config : server,
              isCurrent: current,
              metrics: same ? old.metrics : const ServerMetricsSnapshot(),
            );
      next[server.id] = card;
      configs.add(card.config);
    }
    final changed = !listEquals(configs, _configs);
    if (!changed &&
        _hasDirectory &&
        _currentId == currentId &&
        _directoryError == null) {
      return;
    }
    if (changed) {
      _configs = identical(servers, _directory?.servers) &&
              listEquals(servers, configs)
          ? servers
          : List.unmodifiable(configs);
    }
    _cards = next;
    _currentId = currentId;
    _hasDirectory = true;
    _directoryError = null;
    _lastMetricRead
        .removeWhere((config, _) => _cards[config.id]?.config != config);
    notifyListeners();
    _refreshVisible();
  }

  Future<void> load() => _loadDirectory();

  Future<void> _loadDirectory({bool initial = false}) {
    if (isDisposed) return Future.value();
    final pending = _directoryRead;
    if (pending != null) return pending;
    final operation = Future<void>.microtask(() async {
      try {
        final directory = _directory;
        if (directory != null) {
          await (initial ? directory.ensureLoaded() : directory.refresh());
          _onDirectoryChanged();
        } else {
          final cards = await _repository.loadServerCards();
          syncDirectory(
            [for (final card in cards) card.config],
            cards.where((card) => card.isCurrent).firstOrNull?.config.id,
          );
        }
      } catch (error, trace) {
        if (!isDisposed) {
          _directoryError = ErrorMessageUtils.normalize(error);
          appLogger.eWithPackage('features.server.provider', '读取服务器目录失败',
              error: error, stackTrace: trace);
        }
        rethrow;
      } finally {
        _directoryRead = null;
        notifyListeners();
      }
    });
    _directoryRead = operation;
    notifyListeners();
    return operation;
  }

  void setPageVisible(Object owner, bool visible, {String? serverId}) {
    if (isDisposed) return;
    if (visible) {
      if (_visiblePages.containsKey(owner) &&
          _visiblePages[owner] == serverId) {
        return;
      }
      _visiblePages[owner] = serverId;
    } else {
      if (!_visiblePages.containsKey(owner)) return;
      _visiblePages.remove(owner);
    }
    if (!_hasDirectory && visible) {
      _loadDirectory(initial: true).ignore();
    }
    _refreshVisible();
  }

  bool _wants(String id) =>
      _visiblePages.containsValue(null) || _visiblePages.containsValue(id);

  void _refreshVisible() {
    if (_visiblePages.isEmpty || _configs.isEmpty || isDisposed) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_visiblePages.containsValue(null)) {
      _readList(explicit: false).ignore();
    } else {
      for (final id in _visiblePages.values.whereType<String>().toSet()) {
        final config = _cards[id]?.config;
        if (config != null && _isDue(config)) _requestMetrics(config).ignore();
      }
    }
    _timer ??= Timer.periodic(_refreshInterval, (_) => _refreshVisible());
  }

  bool _isDue(ApiConfig config) {
    final last = _lastMetricRead[config];
    return last == null || DateTime.now().difference(last) >= _refreshInterval;
  }

  Future<void> loadMetrics() {
    final directoryRead = _directoryRead;
    return directoryRead == null
        ? _readList(explicit: true)
        : directoryRead.then((_) => _readList(explicit: true));
  }

  Future<void> _readList({required bool explicit}) {
    final configs = _configs;
    final active = identical(_listRead?.configs, configs) ? _listRead : null;
    if (active != null && (!explicit || active.remaining.isEmpty)) {
      return active.done;
    }
    final Iterable<ApiConfig> targets = active?.remaining ??
        (explicit ? configs : configs.where(_isDue).toList());
    if (isDisposed || targets.isEmpty) return Future.value();
    final remaining = targets.length == configs.length || explicit
        ? const <ApiConfig>{}
        : (configs.toSet()..removeAll(targets));
    final completion = Completer<void>();
    _listRead =
        (configs: configs, remaining: remaining, done: completion.future);
    final reads = [
      if (active != null) active.done,
      for (final config in targets) _requestMetrics(config, explicit: explicit),
    ];
    completion.complete(Future.wait(reads).then<void>((_) {}).whenComplete(() {
      if (_listRead?.done == completion.future) _listRead = null;
    }));
    return completion.future;
  }

  Future<void> loadMetricsFor(String id) {
    final config = _cards[id]?.config;
    return config == null
        ? Future.value()
        : _requestMetrics(config, explicit: true);
  }

  Future<void> _requestMetrics(ApiConfig config, {bool explicit = false}) {
    if (isDisposed) return Future.value();
    if (explicit && !_wants(config.id)) _explicitReads.add(config);
    final active = _metricReads[config];
    if (active != null) return active;
    final wasIdle = _metricReads.isEmpty;
    final operation = _pool.withResource(() async {
      if (isDisposed ||
          cardFor(config.id)?.config != config ||
          (!_wants(config.id) && !_explicitReads.contains(config))) {
        return;
      }
      _lastMetricRead[config] = DateTime.now();
      final metrics = await _repository.loadMetricsForConfig(config);
      final card = cardFor(config.id);
      if (isDisposed ||
          card == null ||
          card.config != config ||
          card.metrics == metrics) {
        return;
      }
      _cards[config.id] = card.copyWith(metrics: metrics);
      notifyListeners();
    }).whenComplete(() {
      _metricReads.remove(config);
      _explicitReads.remove(config);
      if (_metricReads.isEmpty) notifyListeners();
    });
    _metricReads[config] = operation;
    if (wasIdle) notifyListeners();
    return operation;
  }

  Future<void> _reloadAfterWrite() async {
    if (isDisposed) return;
    // 写入完成后的目录读取必须晚于正在进行的旧读取。
    final pending = _directoryRead;
    if (pending != null) {
      await pending.then<void>((_) {}, onError: (Object _) {});
    }
    await load();
  }

  Future<void> _writeConfig(Future<void> operation) async {
    try {
      await operation;
    } on ConfigStorageException catch (error, trace) {
      if (error.changeCommitted != false) {
        // 目录刷新会记录自己的错误，调用方仍收到原始写入结果。
        try {
          await _reloadAfterWrite();
        } catch (_) {
          Error.throwWithStackTrace(error, trace);
        }
      }
      rethrow;
    }
    await _reloadAfterWrite();
  }

  Future<void> updateConfig(ApiConfig config, {required ApiConfig expected}) =>
      _writeConfig(_repository.updateConfig(config, expected: expected));

  Future<void> setCurrent(String id) {
    final directory = _directory;
    if (directory != null) return directory.selectServer(id);
    return _writeConfig(_repository.setCurrent(id));
  }

  Future<void> delete(String id) => _writeConfig(_repository.removeConfig(id));

  Future<void> save(ApiConfig config) =>
      _writeConfig(_repository.saveConfig(config));

  @override
  void dispose() {
    _directory?.removeListener(_onDirectoryChanged);
    _timer?.cancel();
    _pool.close().ignore();
    super.dispose();
  }
}
