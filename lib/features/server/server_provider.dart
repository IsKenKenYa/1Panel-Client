import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'server_models.dart';
import 'server_repository.dart';

class ServerProvider extends ChangeNotifier with SafeChangeNotifier {
  ServerProvider({ServerRepository? repository})
      : _repository = repository ?? const ServerRepository();

  final ServerRepository _repository;
  bool _isLoading = false;
  List<ServerCardViewModel> _servers = const [];
  final Map<String, ServerMetricsSnapshot> _metrics = {};
  bool _isLoadingMetrics = false;
  Timer? _metricsRefreshTimer;
  static const Duration _metricsRefreshInterval = Duration(seconds: 10);

  bool get isLoading => _isLoading;
  bool get isLoadingMetrics => _isLoadingMetrics;
  List<ServerCardViewModel> get servers => _servers;

  Future<void> load() async {
    if (isDisposed) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      _servers = await _repository.loadServerCards();
      if (_servers.isNotEmpty && !isDisposed) {
        startMetricsAutoRefresh();
      }
    } finally {
      if (!isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void startMetricsAutoRefresh() {
    _metricsRefreshTimer?.cancel();
    _metricsRefreshTimer = Timer.periodic(_metricsRefreshInterval, (_) {
      if (_servers.isNotEmpty) {
        loadMetrics();
      }
    });
  }

  void stopMetricsAutoRefresh() {
    _metricsRefreshTimer?.cancel();
    _metricsRefreshTimer = null;
  }

  @override
  void dispose() {
    stopMetricsAutoRefresh();
    super.dispose();
  }

  Future<void> loadMetrics() async {
    if (_isLoadingMetrics || isDisposed) return;

    _isLoadingMetrics = true;
    notifyListeners();

    try {
      final targets = List<ServerCardViewModel>.of(_servers);
      final snapshots = await Future.wait(
        targets.map((server) => _repository.loadServerMetrics(server.config.id)),
      );
      if (isDisposed) return;
      for (var index = 0; index < targets.length; index++) {
        _metrics[targets[index].config.id] = snapshots[index];
      }
      _servers = targets
          .map((s) => ServerCardViewModel(
                config: s.config,
                isCurrent: s.isCurrent,
                metrics: _metrics[s.config.id] ?? const ServerMetricsSnapshot(),
              ))
          .toList();
    } finally {
      if (!isDisposed) {
        _isLoadingMetrics = false;
        notifyListeners();
      }
    }
  }

  Future<void> setCurrent(String id) async {
    await _repository.setCurrent(id);
    await load();
  }

  Future<void> delete(String id) async {
    // Stop metrics refresh before deleting to avoid a race where the timer
    // fires mid-delete and tries to fetch metrics for the now-removed server.
    stopMetricsAutoRefresh();

    try {
      await _repository.removeConfig(id);
      await load();
    } finally {
      if (_servers.isNotEmpty) {
        startMetricsAutoRefresh();
      }
    }
  }

  Future<void> save(ApiConfig config) async {
    await _repository.saveConfig(config);
    await load();
  }
}
