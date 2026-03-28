import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'server_models.dart';
import 'server_repository.dart';

class ServerProvider extends ChangeNotifier {
  ServerProvider({ServerRepository? repository})
      : _repository = repository ?? const ServerRepository();

  final ServerRepository _repository;
  bool _isLoading = false;
  List<ServerCardViewModel> _servers = const [];
  final Map<String, ServerMetricsSnapshot> _metrics = {};
  bool _isLoadingMetrics = false;

  bool get isLoading => _isLoading;
  bool get isLoadingMetrics => _isLoadingMetrics;
  List<ServerCardViewModel> get servers => _servers;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _servers = await _repository.loadServerCards();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMetrics() async {
    if (_isLoadingMetrics) return;

    _isLoadingMetrics = true;
    notifyListeners();

    try {
      for (final server in _servers) {
        final metrics = await _repository.loadServerMetrics(server.config.id);
        _metrics[server.config.id] = metrics;
      }

      _servers = _servers
          .map((s) => ServerCardViewModel(
                config: s.config,
                isCurrent: s.isCurrent,
                metrics: _metrics[s.config.id] ?? const ServerMetricsSnapshot(),
              ))
          .toList();
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }

  Future<void> setCurrent(String id) async {
    await _repository.setCurrent(id);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.removeConfig(id);
    await load();
  }

  Future<void> save(ApiConfig config) async {
    await _repository.saveConfig(config);
    await load();
  }
}
